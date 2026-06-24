# MobiusDesk Flutter - 项目设计文档

> 版本：v1.0  
> 更新日期：2026-06-24  

---

## 1. 系统架构设计

### 1.1 整体架构

移动端采用 Flutter Clean Architecture，分为四层：表现层、应用层、领域层、基础设施层。

```
┌─────────────────────────────────────────────────────┐
│                   Presentation                       │
│   Pages / Widgets / Router                          │
│   ConnectPage / RemotePage / SettingPage /          │
│   DevicePage (扩展)                                  │
├─────────────────────────────────────────────────────┤
│                   Application                        │
│   Riverpod Providers / Notifiers                     │
│   deviceProvider / connectionProvider /              │
│   settingProvider                                    │
├─────────────────────────────────────────────────────┤
│                   Domain                             │
│   Models / Repositories (abstract)                  │
│   Device / User / AppVersion / RemoteParams          │
├─────────────────────────────────────────────────────┤
│                   Infrastructure                     │
│   API Client (Dio) / WebSocket (Socket.IO) /        │
│   WebRTC (flutter_webrtc) / Local Storage /          │
│   Platform Channel (Accessibility)                   │
└─────────────────────────────────────────────────────┘
```

### 1.2 依赖注入

使用 Riverpod 进行依赖注入和状态管理：

```
ProviderScope
├── infrastructureProviders
│   ├── apiClientProvider        → Dio 实例
│   ├── wsClientProvider         → WsClient 实例
│   ├── rtcManagerProvider       → RtcManager 实例
│   └── localStorageProvider     → LocalStorage 实例
│
├── deviceProvider               → 设备状态 + 操作
├── connectionProvider           → 连接状态 + 操作
└── settingProvider              → 设置状态 + 操作
```

---

## 2. 核心模块设计

### 2.1 API 客户端

**类**：`ApiClient`（`infrastructure/api/api_client.dart`）

基于 Dio 封装，统一处理请求拦截、Token 注入、错误处理：

```
ApiClient
├── _dio: Dio                       # Dio 实例
├── setBaseUrl(url)                  # 设置基础URL
├── setToken(token)                  # 设置认证Token
├── post<T>(path, data) → T         # POST 请求
├── get<T>(path, params) → T        # GET 请求
└── put<T>(path, data) → T          # PUT 请求
```

**接口合并**：所有 API 接口定义在 `apis.dart` 中，按模块分区注释。

### 2.2 WebSocket 客户端

**类**：`WsClient`（`infrastructure/websocket/ws_client.dart`）

```
WsClient
├── connect(url, uuid, password)     # 建立连接
├── disconnect()                      # 断开连接
├── emit(event, data)                # 发送事件
├── on(event, callback)              # 监听事件
├── off(event, callback)             # 取消监听
└── isConnected: bool                # 连接状态
```

### 2.3 WebRTC 管理器

**类**：`RtcManager`（`infrastructure/webrtc/rtc_manager.dart`）

```
RtcManager
├── createOffer() → RTCSessionDescription
├── createAnswer(offer) → RTCSessionDescription
├── addCandidate(candidate)
├── getStats() → StatsReport
├── changeParams(params)
├── close()
└── onTrack: callback
```

### 2.4 触摸操作映射设计

将触屏手势映射为鼠标/键盘操作，通过 WebSocket `desk:behavior` 发送：

```
GestureDetector
├── onTap → leftClick(x, y)
├── onLongPress → rightClick(x, y)
├── onPanUpdate → mouseMove(dx, dy)
├── onDoubleTap → doubleClick(x, y)
├── onVerticalDragEnd(velocity) → scrollUp/scrollDown(amount)
└── onScaleUpdate → 本地画面缩放（不发送）
```

**坐标转换**：触摸坐标 → 远程桌面坐标

```
remoteX = touchX / viewWidth * remoteWidth
remoteY = touchY / viewHeight * remoteHeight
```

### 2.5 Android 被控端设计

```
┌──────────────────────────────────────┐
│           Flutter (Dart)              │
│  accessibility_channel.dart           │
│  ├── MethodChannel 调用原生方法       │
│  └── EventChannel 接收原生事件        │
├──────────────────────────────────────┤
│           Android (Kotlin/Java)       │
│  MobiusAccessibilityService           │
│  ├── dispatchGesture() 模拟触摸       │
│  └── onAccessibilityEvent() 监听事件  │
│                                       │
│  MediaProjection + VirtualDisplay     │
│  └── 捕获屏幕 → WebRTC 推流           │
└──────────────────────────────────────┘
```

---

## 3. 页面路由设计

```
/ (redirect) → /connect
/connect      → ConnectPage     连接页面（Tab 0）
/setting      → SettingPage     设置页面（Tab 1）
/device       → DevicePage      设备管理（扩展，Tab 2）
/remote       → RemotePage      远程控制（全屏页面）
```

**路由配置**：使用 GoRouter，MainShell 作为底部导航壳：

```
ShellRoute(
  builder: MainShell,
  routes: [
    /connect → ConnectPage,
    /setting → SettingPage,
    /device  → DevicePage,
  ],
)
/remote → RemotePage (无 Shell)
```

---

## 4. 状态管理设计

### 4.1 Provider 依赖关系

```
infrastructureProviders
   │
   ├── deviceProvider
   │      └── 依赖 apiClientProvider, localStorageProvider
   │
   ├── connectionProvider
   │      └── 依赖 wsClientProvider, rtcManagerProvider, deviceProvider
   │
   └── settingProvider
          └── 依赖 localStorageProvider
```

### 4.2 本地存储 Key

| Key | 类型 | 说明 |
|-----|------|------|
| `mobius_device_uuid` | String | 设备码 |
| `mobius_device_password` | String | 设备密码 |
| `mobius_settings_wss_url` | String | WSS 地址 |
| `mobius_settings_api_url` | String | API 地址 |
| `mobius_settings_coturn_url` | String | COTURN 地址 |

---

## 5. 关键技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 状态管理 | Riverpod | 编译时安全、支持异步、依赖注入 |
| 路由 | go_router | 声明式、深链接支持 |
| HTTP | Dio | 拦截器、取消请求、FormData |
| WebSocket | socket_io_client | 与后端 Socket.IO 兼容 |
| WebRTC | flutter_webrtc | Flutter 生态最成熟的 WebRTC 库 |
| 本地存储 | shared_preferences | 轻量 KV 存储 |
| 后台保活 | flutter_background | Android 前台服务 |

---

## 6. 平台差异设计

### 6.1 Android vs iOS

| 能力 | Android | iOS |
|------|---------|-----|
| 远程控制（主控端） | ✅ | ✅ |
| 被控端操作模拟 | ✅（AccessibilityService） | ❌ |
| 屏幕捕获（被控端） | ✅（MediaProjection） | ⚠️（ReplayKit，受限） |
| 后台保活 | ✅（前台服务） | ❌（系统限制） |
| 文件传输 | ⬆️升级版 | ⬆️升级版 |

### 6.2 iOS 限制应对

- iOS 不支持无障碍服务，无法作为被控端
- 屏幕共享通过 ReplayKit Broadcast Extension 实现，需额外配置
- 后台运行受限，连接在切换应用后可能断开

---

## 7. 待实现功能（升级版）

| 功能 | 优先级 | 设计方案 |
|------|--------|----------|
| Android 被控 | P2 | AccessibilityService + MediaProjection + WebRTC 推流 |
| Android 后台保活 | P2 | flutter_background 前台服务 + 通知栏常驻 |
| 版本更新检查 | P2 | 调用 `/api/v1/versions/check`，弹窗提示下载 |
| 用例层 | P1 | `application/usecases/` 目录，封装业务逻辑 |