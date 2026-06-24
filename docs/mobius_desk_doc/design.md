# MobiusDesk - 项目设计文档

> 版本：v1.0  
> 更新日期：2026-06-24  

---

## 1. 系统架构设计

### 1.1 整体架构

桌面端采用 Electron + React 双进程架构，渲染进程负责 UI 展示与交互，主进程负责系统级操作（屏幕捕获、键鼠仿真、窗口管理）。

```
┌─────────────────────────────────────────────────────────┐
│                    Electron 主进程                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐  │
│  │ 窗口管理  │  │ 屏幕捕获  │  │ 键鼠仿真  │  │ 系统托盘│  │
│  │ window.ts│  │ screen.ts│  │mouse/keyboard│ │ (待实现)│  │
│  └──────────┘  └──────────┘  └──────────┘  └────────┘  │
│                      ↕ IPC                               │
├─────────────────────────────────────────────────────────┤
│                    渲染进程 (React)                       │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  Presentation Layer                                 │  │
│  │  Pages: RemotePage / WebRtcPage / DevicesPage /    │  │
│  │         SettingsPage                                │  │
│  │  Components: Layout / Sidebar / TitleBar /          │  │
│  │              ControlToolbar / ConnectionDetail      │  │
│  └──────────────────────┬─────────────────────────────┘  │
│                         │                                │
│  ┌──────────────────────┴─────────────────────────────┐  │
│  │  State Layer (Zustand)                              │  │
│  │  appStore / deviceStore / connectionStore /         │  │
│  │  settingStore                                       │  │
│  └──────────────────────┬─────────────────────────────┘  │
│                         │                                │
│  ┌──────────────────────┴─────────────────────────────┐  │
│  │  Infrastructure Layer                               │  │
│  │  API Client / WebSocket Client / WebRTC Manager /   │  │
│  │  IPC Bridge / File Transfer (待实现)                │  │
│  └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 1.2 进程通信设计

渲染进程与主进程通过 Electron IPC 通信，使用 `contextBridge` + `ipcRenderer.invoke` 模式：

```
渲染进程                          主进程
   │                                │
   │──ipcRenderer.invoke()─────────>│
   │<──ipcMain.handle()返回结果─────│
```

**IPC 事件分类**：

| 类别 | 事件前缀 | 方向 | 说明 |
|------|----------|------|------|
| 鼠标操作 | `mouse:*` | 渲染→主 | 鼠标移动/点击/拖拽/滚轮 |
| 键盘操作 | `keyboard:*` | 渲染→主 | 键盘输入/按键 |
| 屏幕捕获 | `screen:*` | 双向 | 获取屏幕流 |
| 窗口管理 | `window:*` | 渲染→主 | 关闭/最小化/置顶 |
| 系统事件 | `system:*` | 主→渲染 | 休眠/唤醒 |

---

## 2. 核心模块设计

### 2.1 WebSocket 客户端

**类**：`WsClient`（`lib/websocket/ws-client.ts`）

**设计**：单例模式（`ws-singleton.ts`），确保全局只有一个 WebSocket 连接。

```
WsClient
├── connect(url, uuid, password)    # 建立连接
├── disconnect()                     # 断开连接
├── emit(event, data)               # 发送事件
├── on(event, callback)             # 监听事件
├── off(event, callback)            # 取消监听
└── isConnected: boolean            # 连接状态
```

**心跳机制**：每 10 秒发送 `desk:update-status`，服务端刷新 Redis TTL。

### 2.2 WebRTC 管理器

**类**：`RtcManager`（`lib/webrtc/rtc-manager.ts`）

```
RtcManager
├── createOffer()                    # 创建 Offer
├── createAnswer(offer)              # 创建 Answer
├── addCandidate(candidate)          # 添加 ICE Candidate
├── getStats()                       # 获取连接统计
├── changeParams(params)             # 动态调整参数
├── close()                          # 关闭连接
└── onTrack: callback                # 视频流回调
```

**ICE 配置**：从服务端 COTURN 配置接口获取 TURN 服务器地址。

**参数调整**：通过 `desk:change-params` 信令通知被控端调整编码参数。

### 2.3 远程控制流程

```
主控端                          服务端                          被控端
   │                              │                              │
   │──1.输入设备码+密码───────────│                              │
   │──2.POST /devices/verify─────>│                              │
   │<──3.验证结果─────────────────│                              │
   │                              │                              │
   │──4.desk:start-remote────────>│──5.验证+转发────────────────>│
   │<──6.desk:start-remote-result│<──7.确认/拒绝────────────────│
   │                              │                              │
   │──8.desk:offer───────────────>│──9.转发────────────────────>│
   │<──10.desk:answer────────────│<──11.应答────────────────────│
   │<──12.desk:candidate────────>│<──13.候选────────────────────│
   │                              │                              │
   │         ═══ WebRTC P2P 连接建立 ═══                        │
   │                              │                              │
   │──14.desk:behavior(操控)─────>│──15.转发────────────────────>│
   │                              │                              │
   │<──16.视频流(WebRTC)────────────────────────────────────────│
```

### 2.4 来电请求设计（扩展功能）

被控端收到远程连接请求时，弹出确认对话框：

```
IncomingRequestDialog
├── 显示主控端设备码
├── [接受] → 发送确认，开始 WebRTC 协商
└── [拒绝] → 发送拒绝，主控端收到错误码
```

---

## 3. 页面路由设计

```
/ (redirect) → /remote
/remote       → RemotePage     远程控制首页
/devices      → DevicesPage    设备管理
/settings     → SettingsPage   设置
/webrtc       → WebRtcPage     WebRTC控制（全屏，无侧边栏）
```

**路由守卫**：
- WebRtcPage 进入前检查是否有活跃的 WebRTC 连接
- 无连接时重定向到 /remote

---

## 4. 状态管理设计

### 4.1 Store 依赖关系

```
appStore (全局)
   │
   ├── deviceStore (设备信息)
   │      └── 依赖 appStore.isElectron
   │
   ├── connectionStore (连接状态)
   │      └── 依赖 deviceStore.uuid
   │
   └── settingStore (设置)
          └── 持久化到 localStorage
```

### 4.2 持久化策略

| Store | Key | 存储方式 |
|-------|-----|----------|
| deviceStore | `mobius_device` | localStorage |
| settingStore | `mobius_settings` | localStorage |
| connectionStore | - | 不持久化（运行时状态） |
| appStore | - | 不持久化（运行时状态） |

---

## 5. 关键技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 状态管理 | Zustand | 轻量、无模板代码、TypeScript 友好 |
| WebSocket | Socket.IO | 自动重连、房间机制、与后端一致 |
| 视频传输 | WebRTC | P2P 低延迟、标准协议 |
| 键鼠仿真 | nut-js | Node.js 原生、跨平台支持 |
| CSS 方案 | TailwindCSS | 原子化、快速开发 |
| 包管理器 | pnpm | 快速、磁盘高效 |

---

## 6. 待实现功能（升级版）

| 功能 | 优先级 | 设计方案 |
|------|--------|----------|
| 系统托盘 | P2 | Electron `Tray` API，最小化到托盘，右键菜单（显示窗口/退出） |
| 锁屏保活 | P2 | Electron `powerSaveBlocker`，远程连接期间阻止休眠 |
| 文件传输 | P2 | WebRTC DataChannel，分片传输 + spark-md5 校验，支持断点续传 |