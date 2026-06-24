# MobiusDesk Flutter - 开发者使用说明

> 版本：v1.0  
> 更新日期：2026-06-24  

---

## 1. 环境准备

### 1.1 必需软件

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| Flutter | 3.27+ | 跨平台框架 |
| Dart | ^3.12.2 | 开发语言 |
| Android Studio | 最新版 | Android 开发 |
| Xcode | 15+ | iOS 开发（仅 macOS） |
| Git | 最新版 | 版本控制 |

### 1.2 安装 Flutter

```bash
# 官方安装方式
# https://docs.flutter.dev/get-started/install

# 验证安装
flutter doctor
```

### 1.3 配置 Android 环境

1. 安装 Android Studio
2. 配置 Android SDK（API 33+）
3. 创建 Android 模拟器或连接真机

### 1.4 配置 iOS 环境（仅 macOS）

1. 安装 Xcode
2. 安装 CocoaPods：`sudo gem install cocoapods`
3. 运行 `flutter doctor` 检查 iOS 工具链

---

## 2. 项目启动

### 2.1 克隆项目

```bash
git clone <repository-url>
cd remote-control/mobius_desk_flutter
```

### 2.2 安装依赖

```bash
flutter pub get
```

### 2.3 配置环境

默认连接开发环境服务：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| API 地址 | `http://localhost:4200/api/v1` | 后端 API |
| WSS 地址 | `ws://localhost:4200/desk` | WebSocket |
| COTURN 地址 | 空 | TURN 服务器 |

可在设置页面中修改服务器地址。

### 2.4 运行调试

```bash
# 运行到连接的设备
flutter run

# 指定设备运行
flutter run -d <device_id>

# 查看可用设备
flutter devices
```

### 2.5 前置依赖

确保以下服务已启动：

- **MobiusDesk Service**：`http://localhost:4200`
- **MongoDB**：`localhost:27017`
- **Redis**：`localhost:6379`

---

## 3. 项目结构

```
mobius_desk_flutter/
├── lib/
│   ├── main.dart                # 应用入口
│   ├── core/                    # 核心层
│   │   ├── constants.dart       # 常量定义
│   │   ├── enums.dart           # 枚举定义
│   │   ├── theme.dart           # 主题配置
│   │   └── extensions/          # 扩展方法
│   ├── domain/                  # 领域层
│   │   ├── models/              # 数据模型
│   │   └── repositories/        # 仓库抽象
│   ├── infrastructure/          # 基础设施层
│   │   ├── api/                 # HTTP API
│   │   ├── websocket/           # WebSocket
│   │   ├── webrtc/              # WebRTC
│   │   ├── storage/             # 本地存储
│   │   └── platform/            # 平台通道
│   ├── application/             # 应用层
│   │   └── providers/           # Riverpod Providers
│   └── presentation/            # 表现层
│       ├── router/              # 路由配置
│       ├── shell/               # 布局壳
│       ├── pages/               # 页面
│       └── widgets/             # 公共组件
├── android/                     # Android 平台代码
├── ios/                         # iOS 平台代码
├── pubspec.yaml                 # 依赖配置
└── analysis_options.yaml        # Dart 分析配置
```

---

## 4. 开发指南

### 4.1 新增页面

1. 在 `lib/presentation/pages/` 下创建页面目录和组件
2. 在 `lib/presentation/router/app_router.dart` 中添加路由
3. 如需底部导航 Tab，在 `lib/presentation/shell/main_shell.dart` 中添加

### 4.2 新增 API 接口

1. 在 `lib/infrastructure/api/apis.dart` 中添加接口方法
2. 在 `lib/domain/models/` 中定义数据模型
3. 在对应的 Provider 中调用

### 4.3 新增 Provider

```dart
// lib/application/providers/xxx_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final xxxProvider = StateNotifierProvider<XxxNotifier, XxxState>((ref) {
  return XxxNotifier();
});

class XxxState {
  final String data;
  XxxState({this.data = ''});
}

class XxxNotifier extends StateNotifier<XxxState> {
  XxxNotifier() : super(XxxState());

  void setData(String data) {
    state = XxxState(data: data);
  }
}
```

### 4.4 平台通道（Android 原生交互）

1. 在 `lib/infrastructure/platform/` 下定义 MethodChannel
2. 在 `android/app/src/main/kotlin/` 下实现原生代码
3. 在 AndroidManifest.xml 中声明权限和服务

---

## 5. 构建与打包

### 5.1 构建命令

```bash
# 构建 Android APK
flutter build apk --release

# 构建 Android App Bundle
flutter build appbundle --release

# 构建 iOS IPA
flutter build ipa --release
```

### 5.2 输出路径

| 平台 | 输出路径 |
|------|----------|
| Android APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Android AAB | `build/app/outputs/bundle/release/app-release.aab` |
| iOS IPA | `build/ios/ipa/mobius_desk.ipa` |

### 5.3 签名配置

**Android**：编辑 `android/app/build.gradle` 配置签名信息。

**iOS**：在 Xcode 中配置 Signing & Capabilities。

---

## 6. Android 特殊配置

### 6.1 无障碍服务

1. 在 `AndroidManifest.xml` 中声明服务
2. 在 `res/xml/accessibility_service_config.xml` 中配置能力
3. 用户需在系统设置中手动开启无障碍服务

### 6.2 前台服务

Android 14+ 需声明前台服务类型：

```xml
<service
    android:foregroundServiceType="mediaProjection"
    ... />
```

### 6.3 权限声明

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

---

## 7. 调试技巧

### 7.1 Flutter DevTools

```bash
# 启动 DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### 7.2 日志调试

```dart
import 'dart:developer' as developer;

developer.log('message', name: 'MyTag');
```

### 7.3 网络调试

使用 Dio 拦截器打印请求/响应：

```dart
dio.interceptors.add(LogInterceptor(
  requestBody: true,
  responseBody: true,
));
```

---

## 8. 常见问题

### Q: flutter pub get 失败？

```bash
# 清除缓存
flutter pub cache clean
flutter pub get
```

### Q: iOS 编译失败？

```bash
cd ios
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

### Q: Android Gradle 同步失败？

检查 `android/build.gradle` 中的 Kotlin 和 Gradle 版本，确保与 Flutter 兼容。

### Q: WebRTC 连接失败？

1. 确保设备网络可访问 COTURN 服务器
2. 检查防火墙/NAT 配置
3. 确认 ICE Candidate 正常交换