# MobiusDesk - 产品需求文档

> 版本：v1.0  
> 更新日期：2026-06-22  
> 项目定位：远程桌面控制系统 - 桌面端/Web端

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [项目目录结构](#3-项目目录结构)
4. [功能需求](#4-功能需求)
5. [页面设计](#5-页面设计)
6. [状态管理设计](#6-状态管理设计)
7. [通信协议](#7-通信协议)
8. [Electron 主进程设计](#8-electron-主进程设计)
9. [配置与构建](#9-配置与构建)

---

## 1. 项目概述

### 1.1 项目名称

**MobiusDesk** - 远程桌面控制系统桌面端

### 1.2 项目定位

基于 React + Electron 构建的跨平台远程桌面控制客户端，支持 Windows/macOS/Linux 桌面端和 Web 浏览器，提供远程桌面查看、操控、设备管理能力。

### 1.3 核心目标

实现远程桌面控制的最小闭环：**设备注册 → 连接被控端 → 查看远程画面 → 发送操控指令 → 被控端执行操作**

### 1.4 设计原则

- **极简闭环**：只实现远程桌面控制的核心功能
- **品牌独立**：所有命名、资源、标识均使用项目自身体系
- **React 生态**：全面使用 React + Zustand + TypeScript 技术栈
- **Electron 集成**：桌面端通过 Electron 主进程实现屏幕捕获和键鼠仿真

---

## 2. 技术架构

### 2.1 技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 框架 | React | ^19.x | UI 框架 |
| 语言 | TypeScript | ^5.x | 类型安全 |
| 状态管理 | Zustand | ^5.x | 轻量级全局状态 |
| 路由 | React Router | ^7.x | 客户端路由 |
| CSS | TailwindCSS | ^4.x | 原子化样式 |
| 构建 | Vite | ^6.x | 前端构建 |
| 桌面框架 | Electron | ^33.x | 桌面应用 |
| 集成 | vite-plugin-electron | - | Vite + Electron |
| WebSocket | socket.io-client | ^4.x | 信令通道 |
| HTTP | Axios | ^1.x | API 请求 |
| 键鼠仿真 | @nut-tree-fork/nut-js | ^4.x | Electron 端操控 |
| 文件哈希 | spark-md5 | ^3.x | 文件传输校验 |
| 图标 | Lucide React | - | 图标库 |

### 2.2 架构分层

```
┌──────────────────────────────────────────────────────┐
│                    Electron Layer                     │
│   Main Process (窗口管理/屏幕捕获/键鼠仿真/IPC)       │
├──────────────────────────────────────────────────────┤
│                    Presentation                       │
│   Pages / Components / Hooks                         │
├──────────────────────────────────────────────────────┤
│                    State (Zustand)                    │
│   appStore / deviceStore / connectionStore / settingStore │
├──────────────────────────────────────────────────────┤
│                    Infrastructure                     │
│   API Client / WebSocket Client / WebRTC Manager     │
│   IPC Bridge / File Transfer                         │
└──────────────────────────────────────────────────────┘
```

---

## 3. 项目目录结构

```
mobius-desk/
├── electron-main/                       # Electron 主进程
│   ├── index.ts                         # 主进程入口（窗口管理/IPC/nut-js）
│   ├── preload.ts                       # 预加载脚本
│   └── ipc/                             # IPC 处理
│       ├── mouse.ts                     # 鼠标操作 IPC
│       ├── keyboard.ts                  # 键盘操作 IPC
│       ├── screen.ts                    # 屏幕捕获 IPC
│       └── window.ts                    # 窗口管理 IPC
│
├── src/
│   ├── main.tsx                         # React 入口
│   ├── App.tsx                          # 根组件
│   │
│   ├── api/                             # API 接口层
│   │   ├── client.ts                    # Axios 实例封装
│   │   ├── auth.ts                      # 认证接口
│   │   ├── devices.ts                   # 设备接口
│   │   └── versions.ts                  # 版本接口
│   │
│   ├── stores/                          # Zustand 状态
│   │   ├── app-store.ts                 # 应用全局状态
│   │   ├── device-store.ts              # 设备状态（本机设备码/密码）
│   │   ├── connection-store.ts          # 连接状态（WebSocket/WebRTC）
│   │   └── setting-store.ts             # 设置状态（服务器地址等）
│   │
│   ├── hooks/                           # 自定义 Hooks
│   │   ├── use-websocket.ts             # WebSocket 连接管理
│   │   ├── use-webrtc.ts                # WebRTC 连接管理
│   │   ├── use-remote-params.ts         # 远程参数配置
│   │   ├── use-ipc-bridge.ts            # Electron IPC 桥接
│   │   └── use-clipboard.ts             # 剪贴板
│   │
│   ├── lib/                             # 核心库
│   │   ├── websocket/
│   │   │   └── ws-client.ts             # Socket.IO 封装类
│   │   ├── webrtc/
│   │   │   ├── rtc-manager.ts           # WebRTC 管理类
│   │   │   └── rtc-config.ts            # WebRTC 配置
│   │   └── ipc/
│   │       └── ipc-renderer.ts          # IPC 渲染进程封装
│   │
│   ├── pages/                           # 页面
│   │   ├── remote/                      # 远程控制首页
│   │   │   ├── RemotePage.tsx           # 页面组件
│   │   │   ├── DeviceCodeCard.tsx       # 设备码卡片
│   │   │   ├── ConnectForm.tsx          # 连接表单
│   │   │   ├── PasswordDialog.tsx       # 密码弹窗
│   │   │   └── ParamsConfig.tsx         # 参数配置
│   │   ├── webrtc/                      # WebRTC 控制页面
│   │   │   ├── WebRtcPage.tsx           # 页面组件
│   │   │   ├── RemoteVideo.tsx          # 远程视频视图
│   │   │   ├── ControlToolbar.tsx       # 控制工具栏
│   │   │   └── ConnectionDetail.tsx     # 连接详情面板
│   │   ├── devices/                     # 设备管理
│   │   │   └── DevicesPage.tsx
│   │   └── settings/                    # 设置
│   │       ├── SettingsPage.tsx
│   │       └── ServerUrlDialog.tsx      # 服务器地址弹窗
│   │
│   ├── components/                      # 公共组件
│   │   ├── Layout.tsx                   # 主布局（侧边栏+系统栏）
│   │   ├── Sidebar.tsx                  # 侧边栏
│   │   ├── TitleBar.tsx                 # 系统栏（macOS风格）
│   │   ├── UpdateDialog.tsx             # 更新弹窗
│   │   └── Toast.tsx                    # 消息提示
│   │
│   ├── types/                           # TypeScript 类型
│   │   ├── api.ts                       # API 响应类型
│   │   ├── device.ts                    # 设备类型
│   │   ├── websocket.ts                 # WebSocket 消息类型
│   │   └── webrtc.ts                    # WebRTC 类型
│   │
│   ├── constants/                       # 常量
│   │   ├── index.ts                     # 通用常量
│   │   ├── events.ts                    # IPC 事件名
│   │   └── enums.ts                     # 枚举
│   │
│   └── utils/                           # 工具函数
│       ├── uuid.ts                      # UUID 生成
│       └── format.ts                    # 格式化工具
│
├── build/                               # Electron 构建资源
├── public/                              # 静态资源
├── electron-builder.json5               # Electron Builder 配置
├── vite.config.ts                       # Vite 配置
├── tsconfig.json                        # TypeScript 配置
├── tailwind.config.ts                   # TailwindCSS 配置
├── package.json
└── README.md
```

---

## 4. 功能需求

### 4.1 功能清单

| 功能 | 优先级 | 桌面端(Electron) | Web端 | 说明 |
|------|:------:|:-:|:-:|------|
| 设备注册 | P0 | ✅ | ✅ | 启动时自动注册，获取设备码+密码 |
| 远程连接 | P0 | ✅ | ✅ | 输入目标设备码+密码发起连接 |
| 远程画面查看 | P0 | ✅ | ✅ | WebRTC 接收并显示远程桌面画面 |
| 鼠标操作 | P0 | ✅ | ✅ | 移动/点击/拖拽/滚轮 |
| 键盘操作 | P0 | ✅ | ✅ | 字符输入/按键/组合键 |
| 控制模式/观看模式 | P0 | ✅ | ✅ | 切换控制与只读模式 |
| 屏幕捕获（被控） | P0 | ✅ | - | Electron desktopCapturer |
| 键鼠仿真（被控） | P0 | ✅ | - | nut-js 执行操作 |
| 连接参数配置 | P1 | ✅ | ✅ | 码率/帧率/分辨率/内容提示 |
| 实时参数调整 | P1 | ✅ | ✅ | 连接中动态调整 |
| 连接详情面板 | P1 | ✅ | ✅ | 延迟/丢包率/分辨率/帧率 |
| 自定义服务器地址 | P1 | ✅ | ✅ | WSS/API/COTURN |
| 窗口置顶 | P1 | ✅ | - | 远程窗口始终置顶 |
| 系统托盘 | P2 | ⬆️升级版 | - | 最小化到托盘 |
| 锁屏保活 | P2 | ⬆️升级版 | - | 阻止系统休眠 |
| 文件传输 | P2 | ⬆️升级版 | ⬆️升级版 | WebRTC DataChannel |
| 版本更新检查 | P2 | ✅ | - | 自动检查更新 |
| 来电请求弹窗 | P1 | ✅ | - | 被控端收到连接请求时弹窗确认（文档外扩展实现） |

### 4.2 功能详细说明

#### 4.2.1 设备注册

**触发时机**：应用首次启动或本地无设备信息时

**流程**：
1. 调用 `POST /api/v1/devices` 注册设备
2. 服务端返回 UUID + 密码
3. 通过 Zustand `deviceStore` 持久化存储
4. 后续启动自动使用本地设备信息

#### 4.2.2 远程连接

**流程**：
1. 用户在「远程控制」页面输入目标设备码
2. 点击「连接」按钮
3. 弹出密码输入弹窗，输入被控端密码
4. 建立 WebSocket 连接（如未连接）
5. 发送 `desk:start-remote` 信令
6. 收到 `desk:start-remote-result`（code=0）后跳转 WebRTC 页面
7. WebRTC 信令交换建立 P2P 连接

#### 4.2.3 远程画面查看

**实现**：
- Web 端：`<video>` 元素 + `RTCVideoRenderer`
- Electron 端：同 Web 端实现
- 视频流通过 WebRTC MediaStream Track 接收
- 自适应缩放，保持画面比例

#### 4.2.4 鼠标操作

**Web/Electron 主控端**：

| 操作 | 事件 | 发送信令 |
|------|------|----------|
| 移动 | mousemove | `desk:behavior` type=mouseMove |
| 左键单击 | click | `desk:behavior` type=leftClick |
| 右键单击 | contextmenu | `desk:behavior` type=rightClick |
| 双击 | dblclick | `desk:behavior` type=doubleClick |
| 拖拽 | mousedown+mousemove+mouseup | `desk:behavior` type=mouseDrag |
| 滚轮 | wheel | `desk:behavior` type=scrollUp/Down |

**Electron 被控端**：
- 收到 `desk:behavior` 后通过 IPC 发送给主进程
- 主进程调用 nut-js 执行对应操作
- nut-js 操作：`mouse.move()`, `mouse.leftClick()`, `mouse.rightClick()`, `mouse.doubleClick()`, `mouse.scroll()`

#### 4.2.5 键盘操作

**主控端**：

| 操作 | 事件 | 发送信令 |
|------|------|----------|
| 字符输入 | keydown | `desk:behavior` type=keyboardType |
| 按键按下 | keydown | `desk:behavior` type=keyboardPressKey |
| 按键释放 | keyup | `desk:behavior` type=keyboardReleaseKey |

**Electron 被控端**：
- nut-js 操作：`keyboard.type()`, `keyboard.pressKey()`, `keyboard.releaseKey()`

#### 4.2.6 屏幕捕获（被控端）

**Electron 实现**：
1. 主进程通过 `desktopCapturer.getSources()` 获取屏幕源
2. 渲染进程通过 `navigator.mediaDevices.getUserMedia()` 获取屏幕流
3. 将视频流添加到 WebRTC RTCPeerConnection 的 Track
4. 通过 WebRTC 推流给主控端

#### 4.2.7 控制模式与观看模式

| 模式 | 行为 |
|------|------|
| **控制模式** | 捕获鼠标/键盘事件，通过 DataChannel 或 WebSocket 发送到被控端 |
| **观看模式** | 仅显示远程画面，不捕获和发送任何操作事件 |

---

## 5. 页面设计

### 5.1 页面结构

```
App
├── Layout (侧边栏+系统栏)
│   ├── RemotePage (远程控制) — /remote
│   ├── DevicesPage (设备管理) — /devices
│   └── SettingsPage (设置) — /settings
├── WebRtcPage (WebRTC控制) — /webrtc (全屏，无侧边栏)
└── 404 Page
```

### 5.2 Layout（主布局）

```
┌─────────────────────────────────────────────┐
│  ┌───┐  ┌───┐  ┌───┐         ─  □  ✕      │  ← TitleBar
│  │远 │  │设 │  │设 │                        │
│  │程 │  │备 │  │置 │         v1.0.0         │  ← Sidebar
│  │控 │  │备 │  │   │                        │
│  │制 │  │   │  │   │                        │
│  └─┬─┘  └───┘  └───┘                        │
│    │                                         │
│    ▼                                         │
│  ┌───────────────────────────────────────┐  │
│  │                                       │  │
│  │          页面内容区域                  │  │
│  │                                       │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**Sidebar 导航项**：
- 远程控制（Remote icon）
- 设备管理（Monitor icon）
- 设置（Settings icon）

**TitleBar**：
- macOS 风格窗口控制按钮（关闭/最小化）
- 版本号显示
- 仅 Electron 端显示

### 5.3 RemotePage（远程控制首页）

```
┌───────────────────────────────────────┐
│                                       │
│  ┌─────────────────────────────────┐  │
│  │  本机设备码                      │  │
│  │  a1b2c3d4-e5f6-7890-abcd-ef12  │  │
│  │  临时密码: ******    [刷新]     │  │
│  └─────────────────────────────────┘  │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │  远程设备码                      │  │
│  │  [________________________]     │  │
│  │                                 │  │
│  │  [连接远程设备]                  │  │
│  └─────────────────────────────────┘  │
│                                       │
│  连接参数                             │
│  ┌─────────────────────────────────┐  │
│  │  码率: 2000kbps  帧率: 60fps   │  │
│  │  分辨率: 1080P                  │  │
│  │  视频提示: 细节  音频提示: 语音 │  │
│  │  [修改参数]                     │  │
│  └─────────────────────────────────┘  │
│                                       │
│  正在控制的设备                        │
│  ┌─────────────────────────────────┐  │
│  │  - device-xxx (在线) [断开]    │  │
│  └─────────────────────────────────┘  │
│                                       │
└───────────────────────────────────────┘
```

**功能要素**：
- 本机设备码展示（可复制）
- 临时密码展示（可刷新、可复制）
- 远程设备码输入框
- 连接按钮
- 连接参数配置
- 正在控制的设备列表

### 5.4 WebRtcPage（WebRTC 控制页面）

```
┌──────────────────────────────────────────────┐
│                                    ┌───────┐ │
│                                    │ 详情  │ │
│                                    │ RTT:  │ │
│      远程桌面画面                  │ 丢包: │ │
│      (全屏显示)                    │ 分辨: │ │
│                                    │ 帧率: │ │
│                                    └───────┘ │
│                                              │
│                                              │
│                                              │
│  [控制/观看]  [码率/帧率/分辨率]  [断开]     │
└──────────────────────────────────────────────┘
```

**功能要素**：
- 远程桌面视频渲染（全屏）
- 控制模式/观看模式切换
- 连接详情浮动面板（RTT/丢包率/分辨率/帧率）
- 实时参数调整
- 断开连接按钮
- 鼠标/键盘事件捕获与转发

### 5.5 DevicesPage（设备管理）

```
┌───────────────────────────────────────┐
│  设备管理                             │
│                                       │
│  ┌─────────────────────────────────┐  │
│  │  设备码        状态     操作    │  │
│  │  device-xxx    在线     [连接]  │  │
│  │  device-yyy    离线     [-]     │  │
│  └─────────────────────────────────┘  │
│                                       │
└───────────────────────────────────────┘
```

### 5.6 SettingsPage（设置页面）

```
┌───────────────────────────────────────┐
│  设置                                 │
│                                       │
│  服务器配置                           │
│  ├─ WSS 地址: [________] [保存]      │
│  ├─ API 地址: [________] [保存]      │
│  └─ COTURN 地址: [______] [保存]    │
│                                       │
│  窗口设置                             │
│  └─ 远程窗口置顶: [开关]             │
│                                       │
│  应用信息                             │
│  ├─ 版本号: 1.0.0                    │
│  └─ 检查更新                          │
│                                       │
└───────────────────────────────────────┘
```

---

## 6. 状态管理设计

### 6.1 app-store（应用全局状态）

```typescript
interface AppState {
  isElectron: boolean;
  platform: string;
  debugMode: boolean;
}

// Actions
setIsElectron: (value: boolean) => void;
setPlatform: (value: string) => void;
toggleDebugMode: () => void;
```

### 6.2 device-store（设备状态）

```typescript
interface DeviceState {
  uuid: string;
  password: string;
  isLoggedIn: boolean;
}

// Actions
setDevice: (uuid: string, password: string) => void;
updatePassword: (password: string) => void;
clearDevice: () => void;
```

**持久化**：`localStorage` key: `mobius_device`

### 6.3 connection-store（连接状态）

```typescript
interface ConnectionState {
  wsConnected: boolean;
  wsClient: WsClient | null;
  rtcManager: RtcManager | null;
  remoteDeviceUuid: string | null;
  isControlling: boolean;    // true=控制模式, false=观看模式
  connectionParams: {
    maxBitrate: number;      // 1-4000 kbps
    maxFramerate: number;    // 1-120 fps
    resolution: string;      // 360p/480p/720p/1080p/2k/4k
    videoHint: string;       // fluid/detailed/text
    audioHint: string;       // speech/music
  };
  connectionDetail: {
    rtt: number;
    packetLoss: number;
    resolution: string;
    framerate: number;
  };
}

// Actions
setWsConnected: (value: boolean) => void;
setWsClient: (client: WsClient) => void;
setRtcManager: (manager: RtcManager) => void;
setRemoteDevice: (uuid: string) => void;
setControlling: (value: boolean) => void;
updateParams: (params: Partial<ConnectionParams>) => void;
updateDetail: (detail: Partial<ConnectionDetail>) => void;
disconnect: () => void;
```

### 6.4 setting-store（设置状态）

```typescript
interface SettingState {
  wssUrl: string;
  apiUrl: string;
  coturnUrl: string;
  alwaysOnTop: boolean;
}

// Actions
setWssUrl: (url: string) => void;
setApiUrl: (url: string) => void;
setCoturnUrl: (url: string) => void;
setAlwaysOnTop: (value: boolean) => void;
```

**持久化**：`localStorage` key: `mobius_settings`

---

## 7. 通信协议

### 7.1 HTTP API

**基础配置**：
- 生产环境 API：`https://{your-domain}/api/v1`
- 开发环境 API：`/api/v1`（代理到 `http://localhost:4200`）
- 超时时间：8秒
- 认证头：`Authorization: Bearer <token>`

**使用的接口**：

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/v1/auth/register` | 用户注册 |
| POST | `/api/v1/auth/login` | 用户登录 |
| POST | `/api/v1/devices` | 注册设备 |
| POST | `/api/v1/devices/login` | 设备登录 |
| POST | `/api/v1/devices/verify` | 连接验证 |
| PUT | `/api/v1/devices/{uuid}/password` | 更新设备密码 |
| GET | `/api/v1/devices/{uuid}/online` | 查询设备在线 |
| GET | `/api/v1/versions/check` | 检查版本更新 |

### 7.2 WebSocket 信令

**连接地址**：
- 生产环境：`wss://{your-domain}/desk`
- 开发环境：`ws://localhost:4200/desk`

**使用的事件**：

| 事件 | 方向 | 说明 |
|------|------|------|
| `desk:join` | 发送 | 加入房间 |
| `desk:joined` | 接收 | 加入成功 |
| `desk:update-status` | 发送 | 心跳（每10秒） |
| `desk:start-remote` | 发送 | 发起远程控制 |
| `desk:start-remote-result` | 接收 | 远程控制结果 |
| `desk:offer` | 双向 | WebRTC Offer |
| `desk:answer` | 双向 | WebRTC Answer |
| `desk:candidate` | 双向 | ICE Candidate |
| `desk:behavior` | 发送/接收 | 远程操作行为 |
| `desk:change-params` | 发送 | 动态调整参数 |

### 7.3 Electron IPC

**渲染进程 → 主进程**：

| 事件 | 说明 |
|------|------|
| `mouse:move` | 鼠标移动 |
| `mouse:drag` | 鼠标拖拽 |
| `mouse:left-click` | 左键点击 |
| `mouse:right-click` | 右键点击 |
| `mouse:double-click` | 双击 |
| `mouse:scroll-up/down/left/right` | 滚轮 |
| `mouse:press-button-left` | 按下左键 |
| `mouse:release-button-left` | 释放左键 |
| `mouse:set-position` | 设置位置 |
| `keyboard:type` | 键盘输入 |
| `keyboard:press-key` | 按键按下 |
| `keyboard:release-key` | 按键释放 |
| `screen:get-stream` | 获取屏幕流 |
| `window:close` | 关闭窗口 |
| `window:minimize` | 最小化 |
| `window:set-always-on-top` | 窗口置顶 |
| `system:power-save-blocker-start` | 阻止休眠 |

**主进程 → 渲染进程**：

| 事件 | 说明 |
|------|------|
| `screen:stream-result` | 屏幕流结果 |
| `system:suspend` | 系统休眠 |
| `system:resume` | 系统唤醒 |

---

## 8. Electron 主进程设计

### 8.1 窗口管理

| 窗口 | 宽×高 | 说明 |
|------|-------|------|
| 主窗口 | 900×600 | 远程控制/设备管理/设置 |
| WebRTC 窗口 | 全屏 | 远程桌面控制 |

**窗口行为**：
- 主窗口关闭时关闭所有子窗口
- 单实例锁（防止多开）
- WebRTC 窗口可设置置顶

### 8.2 IPC 处理

**鼠标操作**（nut-js）：

```typescript
// mouse.ts
ipcMain.handle('mouse:move', (_, x, y) => mouse.move({ x, y }));
ipcMain.handle('mouse:left-click', (_, x, y) => { mouse.setPosition({ x, y }); mouse.leftClick(); });
ipcMain.handle('mouse:right-click', (_, x, y) => { mouse.setPosition({ x, y }); mouse.rightClick(); });
ipcMain.handle('mouse:double-click', (_, x, y) => { mouse.setPosition({ x, y }); mouse.doubleClick(); });
ipcMain.handle('mouse:scroll-up', (_, amount) => mouse.scrollUp(amount));
ipcMain.handle('mouse:scroll-down', (_, amount) => mouse.scrollDown(amount));
```

**键盘操作**（nut-js）：

```typescript
// keyboard.ts
ipcMain.handle('keyboard:type', (_, text) => keyboard.type(text));
ipcMain.handle('keyboard:press-key', (_, key) => keyboard.pressKey(key));
ipcMain.handle('keyboard:release-key', (_, key) => keyboard.releaseKey(key));
```

**屏幕捕获**：

```typescript
// screen.ts
ipcMain.handle('screen:get-stream', async () => {
  const sources = await desktopCapturer.getSources({ types: ['screen'] });
  return sources[0]; // 返回主屏幕源
});
```

### 8.3 行为指令处理流程

```
WebRTC DataChannel 收到 desk:behavior
  → 渲染进程解析行为类型
  → 通过 IPC 发送到主进程
  → 主进程调用 nut-js 执行操作
```

---

## 9. 配置与构建

### 9.1 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VITE_API_URL` | `/api/v1` | API 基础路径 |
| `VITE_WSS_URL` | `ws://localhost:4200/desk` | WSS 地址 |
| `VITE_COTURN_URL` | 空 | COTURN 地址 |

### 9.2 Vite 代理配置

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:4200',
        changeOrigin: true,
      },
    },
  },
});
```

### 9.3 构建命令

```bash
# 安装依赖
npm install

# 开发模式（Web）
npm run dev

# 开发模式（Electron）
npm run dev  # 自动启动 Electron

# 生产构建（Web）
npm run build

# 构建 Windows 安装包
npm run build:win

# 构建 macOS 安装包
npm run build:mac

# 构建 Linux 安装包
npm run build:linux
```

### 9.4 Electron Builder 配置

```json5
// electron-builder.json5
{
  appId: 'com.mobius-desk.app',
  productName: 'MobiusDesk',
  directories: {
    output: 'dist-electron',
  },
  win: {
    target: 'nsis',
    icon: 'build/icon.ico',
  },
  mac: {
    target: 'dmg',
    icon: 'build/icon.icns',
  },
  linux: {
    target: 'deb',
    icon: 'build/icon.png',
  },
  nsis: {
    oneClick: false,
    allowToChangeInstallationDirectory: true,
  },
}
```