# MobiusDesk Flutter - 产品需求文档

> 版本：v1.0  
> 更新日期：2026-06-22  
> 项目定位：远程桌面控制系统 - 移动端

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [项目目录结构](#3-项目目录结构)
4. [功能需求](#4-功能需求)
5. [页面设计](#5-页面设计)
6. [通信协议](#6-通信协议)
7. [平台适配](#7-平台适配)
8. [配置与构建](#8-配置与构建)

---

## 1. 项目概述

### 1.1 项目名称

**MobiusDesk Flutter** - 远程桌面控制系统移动端

### 1.2 项目定位

基于 Flutter 构建的跨平台移动端远程桌面控制客户端，支持 Android/iOS 平台，提供远程桌面查看与操控能力。

### 1.3 核心目标

实现远程桌面控制的最小闭环：**设备注册 → 连接被控端 → 查看远程画面 → 发送操控指令**

### 1.4 设计原则

- **极简闭环**：只实现远程桌面控制的核心功能
- **品牌独立**：所有命名、资源、标识均使用项目自身体系
- **移动优先**：UI 交互针对移动端触屏优化

---

## 2. 技术架构

### 2.1 技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 框架 | Flutter | 3.27+ | 跨平台移动端 |
| 语言 | Dart | ^3.7.2 | 主要开发语言 |
| 状态管理 | Riverpod | ^2.x | 响应式状态管理 |
| HTTP | Dio | ^5.x | 网络请求 |
| WebSocket | socket_io_client | ^3.x | 信令通道 |
| WebRTC | flutter_webrtc | ^0.13.x | 实时音视频 |
| 权限 | permission_handler | ^12.x | 运行时权限 |
| 后台保活 | flutter_background | ^1.x | Android 前台服务 |
| 本地存储 | shared_preferences | ^2.x | KV 存储 |
| 路由 | go_router | ^14.x | 声明式路由 |

### 2.2 架构分层

```
┌─────────────────────────────────────────┐
│              Presentation               │
│   Pages / Widgets / Consumers           │
├─────────────────────────────────────────┤
│              Application                │
│   Providers / Notifiers / UseCases      │
├─────────────────────────────────────────┤
│              Domain                     │
│   Models / Repositories (abstract)      │
├─────────────────────────────────────────┤
│              Infrastructure             │
│   API Client / WebSocket / WebRTC       │
│   Local Storage / Platform Channel      │
└─────────────────────────────────────────┘
```

---

## 3. 项目目录结构

```
mobius-desk-flutter/
├── android/                              # Android 平台代码
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── res/xml/
│           └── accessibility_service_config.xml
├── ios/                                  # iOS 平台代码
├── assets/                               # 静态资源
│   └── images/
│       ├── tab_connect.png
│       ├── tab_connect_active.png
│       ├── tab_setting.png
│       └── tab_setting_active.png
├── lib/
│   ├── main.dart                         # 应用入口
│   │
│   ├── core/                             # 核心层
│   │   ├── constants.dart                # 常量定义
│   │   ├── enums.dart                    # 枚举定义
│   │   ├── theme.dart                    # 主题配置
│   │   └── extensions/                   # 扩展方法
│   │
│   ├── domain/                           # 领域层
│   │   ├── models/                       # 数据模型
│   │   │   ├── device.dart               # 设备模型
│   │   │   ├── user.dart                 # 用户模型
│   │   │   ├── version.dart              # 版本模型
│   │   │   └── remote_params.dart        # 远程连接参数
│   │   └── repositories/                 # 仓库抽象
│   │       ├── auth_repository.dart
│   │       ├── device_repository.dart
│   │       └── version_repository.dart
│   │
│   ├── infrastructure/                   # 基础设施层
│   │   ├── api/                          # HTTP API
│   │   │   ├── api_client.dart           # Dio 封装
│   │   │   ├── auth_api.dart             # 认证接口
│   │   │   ├── device_api.dart           # 设备接口
│   │   │   └── version_api.dart          # 版本接口
│   │   ├── websocket/                    # WebSocket
│   │   │   ├── ws_client.dart            # Socket.IO 封装
│   │   │   └── ws_events.dart            # 事件定义
│   │   ├── webrtc/                       # WebRTC
│   │   │   ├── rtc_manager.dart          # WebRTC 管理
│   │   │   └── rtc_config.dart           # WebRTC 配置
│   │   ├── storage/                      # 本地存储
│   │   │   └── local_storage.dart        # SharedPreferences 封装
│   │   └── platform/                     # 平台通道
│   │       └── accessibility_channel.dart # 无障碍服务通道
│   │
│   ├── application/                      # 应用层
│   │   ├── providers/                    # Riverpod Providers
│   │   │   ├── auth_provider.dart        # 认证状态
│   │   │   ├── device_provider.dart      # 设备状态
│   │   │   ├── connection_provider.dart  # 连接状态
│   │   │   └── setting_provider.dart     # 设置状态
│   │   └── usecases/                     # 用例
│   │       ├── connect_remote.dart       # 连接远程设备
│   │       └── control_remote.dart       # 控制远程设备
│   │
│   └── presentation/                     # 表现层
│       ├── router/                       # 路由
│       │   └── app_router.dart           # GoRouter 配置
│       ├── pages/                        # 页面
│       │   ├── connect/                  # 连接页面
│       │   │   └── connect_page.dart
│       │   ├── remote/                   # 远程控制页面
│       │   │   └── remote_page.dart
│       │   └── setting/                  # 设置页面
│       │       └── setting_page.dart
│       ├── widgets/                      # 公共组件
│       │   ├── device_code_card.dart     # 设备码卡片
│       │   ├── password_input_dialog.dart # 密码输入弹窗
│       │   ├── connection_params_sheet.dart # 连接参数面板
│       │   └── remote_video_view.dart    # 远程视频视图
│       └── shell/                        # 布局壳
│           └── main_shell.dart           # 底部导航壳
│
├── test/                                 # 测试
├── pubspec.yaml                          # Flutter 依赖配置
├── analysis_options.yaml                 # Dart 分析配置
└── README.md
```

---

## 4. 功能需求

### 4.1 功能清单

| 功能 | 优先级 | 说明 |
|------|:------:|------|
| 设备注册 | P0 | 启动时自动注册设备，获取设备码+密码 |
| 远程连接 | P0 | 输入目标设备码+密码发起连接 |
| 远程画面查看 | P0 | WebRTC 接收并显示远程桌面画面 |
| 鼠标操作发送 | P0 | 触摸屏模拟鼠标操作（点击/拖拽/滚轮） |
| 键盘操作发送 | P0 | 虚拟键盘输入 |
| 控制模式/观看模式 | P0 | 切换控制与只读模式 |
| 连接参数配置 | P1 | 码率/帧率/分辨率/内容提示 |
| 实时参数调整 | P1 | 连接中动态调整参数 |
| 连接详情面板 | P1 | 显示延迟/丢包率/分辨率/帧率 |
| 自定义服务器地址 | P1 | WSS/API/COTURN 地址 |
| Android 被控 | P2 | ⬆️升级版 | 通过无障碍服务实现被控 |
| Android 后台保活 | P2 | ⬆️升级版 | 前台服务保活 |
| 版本更新检查 | P2 | ⬆️升级版 | 检查新版本 |
| 设备管理页面 | P1 | ✅ | 设备列表与管理（文档外扩展实现） |

### 4.2 功能详细说明

#### 4.2.1 设备注册

**触发时机**：应用首次启动或本地无设备信息时

**流程**：
1. 调用 `POST /api/v1/devices` 注册设备
2. 服务端返回 UUID + 密码
3. 本地持久化存储设备信息
4. 后续启动自动使用本地设备信息

**本地存储 Key**：
- `mobius_device_uuid` — 设备码
- `mobius_device_password` — 设备密码

#### 4.2.2 远程连接

**流程**：
1. 用户输入目标设备码
2. 点击「连接」按钮
3. 弹出密码输入弹窗，输入被控端密码
4. 建立 WebSocket 连接（如未连接）
5. 发送 `desk:start-remote` 信令
6. 收到 `desk:start-remote-result`（code=0）后进入远程控制页面
7. WebRTC 信令交换建立 P2P 连接

#### 4.2.3 远程画面查看

**实现**：
- 使用 `flutter_webrtc` 的 `RTCVideoRenderer` 渲染远程视频流
- 视频流通过 WebRTC MediaStream Track 接收
- 支持双指缩放画面
- 自适应屏幕方向

#### 4.2.4 触摸操作映射

| 触摸操作 | 映射行为 | 发送信令 |
|----------|----------|----------|
| 单指点击 | 左键单击 | `desk:behavior` type=leftClick |
| 单指长按 | 右键单击 | `desk:behavior` type=rightClick |
| 单指移动 | 鼠标移动 | `desk:behavior` type=mouseMove |
| 双指拖拽 | 鼠标拖拽 | `desk:behavior` type=mouseDrag |
| 双指捏合/展开 | 画面缩放 | 本地处理，不发送 |
| 单指快速滑动 | 滚轮滚动 | `desk:behavior` type=scrollUp/Down |

#### 4.2.5 Android 被控功能

**前提条件**：
- 用户开启无障碍服务
- 用户授予 MediaProjection 权限

**实现方式**：
- 通过 AccessibilityService 的 `dispatchGesture()` API 模拟触摸操作
- 通过 MediaProjection + VirtualDisplay 捕获屏幕画面
- 通过 WebRTC 将屏幕画面推流给主控端

**无障碍服务配置**：
```xml
<accessibility-service
    android:canPerformGestures="true"
    android:canRetrieveWindowContent="true"
    android:accessibilityEventTypes="typeAllMask"
    android:accessibilityFlags="flagDefault"
    android:accessibilityFeedbackType="feedbackAllMask"
    android:notificationTimeout="500" />
```

---

## 5. 页面设计

### 5.1 页面结构

```
App
├── MainShell (底部导航)
│   ├── ConnectPage (连接) — Tab 0
│   └── SettingPage (设置) — Tab 1
└── RemotePage (远程控制) — 全屏页面
```

### 5.2 ConnectPage（连接页面）

**布局**：

```
┌─────────────────────────────┐
│        MobiusDesk            │
│                              │
│  ┌─────────────────────────┐│
│  │  本机设备码              ││
│  │  XXXX-XXXX-XXXX         ││
│  │  密码: ******   [刷新]  ││
│  └─────────────────────────┘│
│                              │
│  ┌─────────────────────────┐│
│  │  远程设备码              ││
│  │  [________________]     ││
│  │                         ││
│  │  [连接远程设备]          ││
│  └─────────────────────────┘│
│                              │
│  连接参数:                   │
│  码率: 2000kbps  帧率: 60fps│
│  分辨率: 1080P              │
│  [修改参数]                  │
│                              │
├──────────────────────────────┤
│  📡连接      ⚙️设置          │
└─────────────────────────────┘
```

**功能要素**：
- 本机设备码展示（可复制）
- 临时密码展示（可刷新、可复制）
- 远程设备码输入框
- 连接按钮
- 连接参数配置入口

### 5.3 RemotePage（远程控制页面）

**布局**：

```
┌─────────────────────────────┐
│                    ┌───────┐ │
│                    │ 详情  │ │
│                    │ RTT:  │ │
│  远程桌面画面       │ 丢包: │ │
│  (全屏显示)        │ 分辨: │ │
│                    │ 帧率: │ │
│                    └───────┘ │
│                              │
│                              │
│                              │
│  [控制/观看]  [参数]  [断开] │
└─────────────────────────────┘
```

**功能要素**：
- 远程桌面视频渲染（全屏）
- 控制模式/观看模式切换
- 连接详情浮动面板
- 参数调整入口
- 断开连接按钮
- 触摸事件捕获与转发

### 5.4 SettingPage（设置页面）

**布局**：

```
┌─────────────────────────────┐
│        设置                  │
│                              │
│  服务器配置                   │
│  ├─ WSS 地址: [________]    │
│  ├─ API 地址: [________]    │
│  └─ COTURN 地址: [______]  │
│                              │
│  应用信息                    │
│  ├─ 版本号: 1.0.0           │
│  └─ 检查更新                 │
│                              │
├──────────────────────────────┤
│  📡连接      ⚙️设置          │
└─────────────────────────────┘
```

**功能要素**：
- 自定义 WSS/API/COTURN 地址
- 版本号展示
- 检查更新

---

## 6. 通信协议

### 6.1 HTTP API

**基础配置**：
- 生产环境 API：`https://{your-domain}/api/v1`
- 开发环境 API：`http://{local-ip}:4200/api/v1`
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

### 6.2 WebSocket 信令

**连接地址**：
- 生产环境：`wss://{your-domain}/desk`
- 开发环境：`ws://{local-ip}:4200/desk`

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
| `desk:behavior` | 发送 | 远程操作行为 |
| `desk:change-params` | 发送 | 动态调整参数 |

### 6.3 WebRTC

**配置**：
- ICE Servers：从服务端 COTURN 配置获取
- DataChannel：`maxRetransmits: 3`, `ordered: false`
- 视频编码：VP8 / H264

**流程**：
1. 被控端获取屏幕流（MediaProjection）
2. 创建 RTCPeerConnection，添加视频 Track
3. 通过 WebSocket 交换 Offer/Answer/Candidate
4. P2P 连接建立，视频流开始传输

---

## 7. 平台适配

### 7.1 Android

**必需权限**：

| 权限 | 说明 | 必需场景 |
|------|------|----------|
| INTERNET | 网络访问 | 始终 |
| CAMERA | 摄像头 | 被控时 |
| RECORD_AUDIO | 录音 | 被控时 |
| FOREGROUND_SERVICE | 前台服务 | 被控时 |
| FOREGROUND_SERVICE_MEDIA_PROJECTION | 媒体投影 | 被控时 |
| WAKE_LOCK | 唤醒锁 | 被控时 |

**无障碍服务**：
- 类名：`MobiusAccessibilityService`
- 能力：`canPerformGestures=true`, `canRetrieveWindowContent=true`
- 用途：被控端接收操作指令后模拟触摸/滑动

**前台服务**：
- 类名：继承 `IsolateHolderService`
- 通知渠道：`MobiusDesk Service`
- 用途：保持 WebSocket/WebRTC 连接在后台不被杀死

### 7.2 iOS

**Info.plist 权限声明**：

| Key | 说明 |
|-----|------|
| NSCameraUsageDescription | 需要摄像头权限用于远程桌面 |
| NSMicrophoneUsageDescription | 需要麦克风权限用于远程桌面音频 |

**限制**：
- iOS 不支持无障碍服务，无法实现被控端操作模拟
- 屏幕共享需通过 ReplayKit 实现
- 后台运行受系统严格限制

---

## 8. 配置与构建

### 8.1 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `MOBIUS_API_URL` | `http://localhost:4200/api/v1` | API 地址 |
| `MOBIUS_WSS_URL` | `ws://localhost:4200/desk` | WSS 地址 |
| `MOBIUS_COTURN_URL` | 空 | COTURN 地址 |

### 8.2 构建命令

```bash
# 安装依赖
flutter pub get

# 运行调试
flutter run

# 构建 Android APK
flutter build apk --release

# 构建 iOS IPA
flutter build ipa --release
```

### 8.3 输出

- Android APK：`build/app/outputs/flutter-apk/app-release.apk`
- iOS IPA：`build/ios/ipa/mobius_desk.ipa`