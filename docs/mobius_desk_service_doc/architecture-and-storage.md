# MobiusDesk Service - 项目架构与数据存储设计文档

> 版本：v1.0  
> 更新日期：2026-06-22  
> 项目定位：远程桌面控制系统 - 信令与API服务端

---

## 目录

1. [项目概述](#1-项目概述)
2. [技术架构](#2-技术架构)
3. [项目目录结构](#3-项目目录结构)
4. [核心模块设计](#4-核心模块设计)
5. [数据存储设计](#5-数据存储设计)
6. [API 接口设计](#6-api-接口设计)
7. [WebSocket 信令设计](#7-websocket-信令设计)
8. [配置与部署](#8-配置与部署)

---

## 1. 项目概述

### 1.1 项目名称

**MobiusDesk Service** - 远程桌面控制系统服务端

### 1.2 项目职责

作为远程桌面控制系统的核心枢纽，提供以下能力：

- **设备管理**：注册设备、设备认证、在线状态管理
- **信令转发**：WebRTC 信令交换（Offer/Answer/Candidate）
- **连接协商**：远程桌面连接请求的验证与转发
- **行为转发**：鼠标/键盘操作指令的实时转发
- **用户认证**：简单的用户名+密码登录

### 1.3 设计原则

- **极简可用**：只保留远程桌面控制闭环所需的最小功能集
- **无外部依赖**：不依赖云服务（七牛云/腾讯云等），不依赖消息队列
- **清晰分层**：Controller → Service → Repository 三层架构
- **标准命名**：接口路径使用复数名词，遵循 RESTful 风格

---

## 2. 技术架构

### 2.1 技术栈

| 类别 | 技术 | 版本 | 用途 |
|------|------|------|------|
| 框架 | NestJS | ^10.x | 服务端框架 |
| 语言 | TypeScript | ^5.x | 类型安全 |
| ODM | Mongoose | ^8.x | 数据库操作 |
| 数据库 | MongoDB | 7.0 | 持久化存储 |
| 缓存 | Redis | 7.0 | 在线状态/缓存 |
| WebSocket | Socket.IO | ^4.x | 信令服务器 |
| 认证 | Passport + JWT | - | 用户认证 |
| 参数校验 | class-validator | - | DTO 校验 |
| API 文档 | @nestjs/swagger | - | Swagger 文档 |

### 2.2 架构图

```
┌──────────────────────────────────────────────────────────┐
│                     客户端层                              │
│   ┌────────────┐   ┌────────────────┐   ┌────────────┐  │
│   │ mobius-desk│   │mobius-desk-    │   │ Web Browser│  │
│   │ (Electron/ │   │  flutter       │   │            │  │
│   │  React)    │   │ (Android/iOS)  │   │            │  │
│   └─────┬──────┘   └───────┬────────┘   └─────┬──────┘  │
└─────────┼──────────────────┼──────────────────┼─────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌──────────────────────────────────────────────────────────┐
│                  MobiusDesk Service                      │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │  HTTP Layer (NestJS Controller)                  │  │
│   │  - AuthController    用户认证                     │  │
│   │  - DevicesController 设备管理                     │  │
│   │  - VersionsController 版本管理                    │  │
│   └────────────────┬─────────────────────────────────┘  │
│                    │                                     │
│   ┌────────────────┴─────────────────────────────────┐  │
│   │  Service Layer                                   │  │
│   │  - AuthService                                    │  │
│   │  - DevicesService                                 │  │
│   │  - VersionsService                                │  │
│   └────────────────┬─────────────────────────────────┘  │
│                    │                                     │
│   ┌────────────────┴─────────────────────────────────┐  │
│   │  WebSocket Gateway (Socket.IO)                   │  │
│   │  - DeskGateway 远程桌面信令                       │  │
│   │    - join / leave                                 │  │
│   │    - startRemote / startRemoteResult              │  │
│   │    - offer / answer / candidate                   │  │
│   │    - behavior                                     │  │
│   │    - changeParams                                 │  │
│   └──────────────────────────────────────────────────┘  │
│                                                          │
│   ┌──────────────────────────────────────────────────┐  │
│   │  Data Layer                                       │  │
│   │  - Mongoose Models (MongoDB)                     │  │
│   │  - Redis Online State Store                       │  │
│   └──────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
          │                  │
          ▼                  ▼
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│  MongoDB 7.0 │   │  Redis 7.0   │   │   Coturn     │
│  持久化存储   │   │  在线状态     │   │  NAT穿透     │
└──────────────┘   └──────────────┘   └──────────────┘
```

---

## 3. 项目目录结构

```
mobius-desk-service/
├── src/
│   ├── main.ts                          # 应用入口
│   ├── app.module.ts                    # 根模块
│   │
│   ├── config/                          # 配置
│   │   ├── database.config.ts           # 数据库连接配置
│   │   ├── redis.config.ts              # Redis连接配置
│   │   └── jwt.config.ts                # JWT配置
│   │
│   ├── common/                          # 公共模块
│   │   ├── decorators/                  # 自定义装饰器
│   │   ├── filters/                     # 异常过滤器
│   │   ├── guards/                      # 守卫（JWT认证）
│   │   ├── interceptors/               # 拦截器（响应格式化）
│   │   ├── pipes/                       # 管道（参数校验）
│   │   └── dto/                         # 公共DTO
│   │       └── pagination.dto.ts        # 分页DTO
│   │
│   ├── modules/
│   │   ├── auth/                        # 认证模块
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── login.dto.ts
│   │   │   │   └── register.dto.ts
│   │   │   └── strategies/
│   │   │       └── jwt.strategy.ts
│   │   │
│   │   ├── users/                       # 用户模块
│   │   │   ├── users.module.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── dto/
│   │   │   │   └── update-user.dto.ts
│   │   │   └── schemas/
│   │   │       └── user.schema.ts
│   │   │
│   │   ├── devices/                     # 设备模块
│   │   │   ├── devices.module.ts
│   │   │   ├── devices.controller.ts
│   │   │   ├── devices.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── create-device.dto.ts
│   │   │   │   ├── login-device.dto.ts
│   │   │   │   └── verify-device.dto.ts
│   │   │   └── schemas/
│   │   │       └── device.schema.ts
│   │   │
│   │   ├── versions/                    # 版本模块
│   │   │   ├── versions.module.ts
│   │   │   ├── versions.controller.ts
│   │   │   ├── versions.service.ts
│   │   │   └── schemas/
│   │   │       └── version.schema.ts
│   │   │
│   │   └── desk/                        # 远程桌面信令模块
│   │       ├── desk.module.ts
│   │       ├── desk.gateway.ts          # WebSocket Gateway
│   │       └── desk.service.ts          # 信令处理逻辑
│   │
│   └── utils/                           # 工具函数
│       ├── crypto.util.ts               # 加密工具
│       └── uuid.util.ts                 # UUID生成
│
├── docker/                              # Docker配置
│   ├── docker-compose.yml
│   ├── mongodb/
│   ├── redis/
│   └── coturn/
│
├── test/                                # 测试
│   ├── app.e2e-spec.ts
│   └── jest-e2e.json
│
├── nest-cli.json
├── tsconfig.json
├── tsconfig.build.json
├── package.json
├── .env                                 # 环境变量
├── .env.example                         # 环境变量模板
└── README.md
```

---

## 4. 核心模块设计

### 4.1 认证模块（Auth）

**职责**：用户注册、登录、JWT Token 签发

**流程**：
1. 用户提交用户名+密码注册
2. 密码使用 bcrypt 加密存储
3. 登录成功后签发 JWT Token
4. 后续请求通过 `Authorization: Bearer <token>` 鉴权

### 4.2 用户模块（Users）

**职责**：用户信息管理

**极简设计**：仅保留用户名、密码、状态三个核心字段

### 4.3 设备模块（Devices）

**职责**：远程桌面设备注册、认证、在线状态

**流程**：
1. 客户端启动时调用注册接口，获取设备码（UUID）+ 临时密码
2. 设备登录后连接 WebSocket，加入房间
3. 定时（10秒）发送心跳更新在线状态（Redis）
4. 主控端通过设备码+密码发起远程连接
5. 服务端验证双方密码后转发连接请求

### 4.4 版本模块（Versions）

**职责**：客户端版本检查、更新提示

**极简设计**：仅保留版本号、下载链接、是否强制更新

### 4.5 远程桌面信令模块（Desk）

**职责**：WebSocket 信令转发

**核心信令**：
- `desk:join` — 加入房间
- `desk:start-remote` — 发起远程控制
- `desk:start-remote-result` — 远程控制结果
- `desk:offer` — WebRTC Offer
- `desk:answer` — WebRTC Answer
- `desk:candidate` — WebRTC ICE Candidate
- `desk:behavior` — 远程操作行为
- `desk:change-params` — 动态调整参数

---

## 5. 数据存储设计

### 5.1 MongoDB 集合设计

#### users（用户集合）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| _id | ObjectId | PK | 主键 |
| username | String | UNIQUE, REQUIRED | 用户名 |
| password | String | REQUIRED | 密码（bcrypt加密） |
| status | Number | REQUIRED, DEFAULT 0 | 状态：0正常, 1禁用 |
| created_at | Date | REQUIRED, DEFAULT Date.now | 创建时间 |
| updated_at | Date | REQUIRED, DEFAULT Date.now | 更新时间 |

```javascript
const UserSchema = new Schema({
  username: { type: String, required: true, unique: true, trim: true, maxlength: 64 },
  password: { type: String, required: true },
  status: { type: Number, required: true, default: 0, enum: [0, 1] }
}, {
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'users'
});

UserSchema.index({ username: 1 }, { unique: true });
```

#### devices（设备集合）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| _id | ObjectId | PK | 主键 |
| uuid | String | UNIQUE, REQUIRED | 设备码 |
| password | String | REQUIRED | 连接密码 |
| user_id | ObjectId | REF users, NULLABLE | 关联用户（可选） |
| status | Number | REQUIRED, DEFAULT 0 | 状态：0正常, 1禁用 |
| created_at | Date | REQUIRED, DEFAULT Date.now | 创建时间 |
| updated_at | Date | REQUIRED, DEFAULT Date.now | 更新时间 |

```javascript
const DeviceSchema = new Schema({
  uuid: { type: String, required: true, unique: true, trim: true, maxlength: 64 },
  password: { type: String, required: true },
  user_id: { type: Schema.Types.ObjectId, ref: 'users', default: null },
  status: { type: Number, required: true, default: 0, enum: [0, 1] }
}, {
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'devices'
});

DeviceSchema.index({ uuid: 1 }, { unique: true });
DeviceSchema.index({ user_id: 1 });
```

#### versions（版本集合）

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| _id | ObjectId | PK | 主键 |
| version | String | REQUIRED | 版本号 |
| force | Number | REQUIRED, DEFAULT 0 | 是否强制更新 |
| content | String | NULL | 更新内容 |
| download_win | String | NULL | Windows下载链接 |
| download_mac | String | NULL | macOS下载链接 |
| download_linux | String | NULL | Linux下载链接 |
| download_android | String | NULL | Android下载链接 |
| created_at | Date | REQUIRED, DEFAULT Date.now | 创建时间 |
| updated_at | Date | REQUIRED, DEFAULT Date.now | 更新时间 |

```javascript
const VersionSchema = new Schema({
  version: { type: String, required: true, maxlength: 32 },
  force: { type: Number, required: true, default: 0, enum: [0, 1] },
  content: { type: String, default: null },
  download_win: { type: String, default: null, maxlength: 512 },
  download_mac: { type: String, default: null, maxlength: 512 },
  download_linux: { type: String, default: null, maxlength: 512 },
  download_android: { type: String, default: null, maxlength: 512 }
}, {
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  collection: 'versions'
});
```

### 5.2 Redis 缓存设计

| Key 模式 | 类型 | 过期时间 | 说明 |
|----------|------|----------|------|
| `mobius:device:uuid:{uuid}` | STRING | 10s | 设备UUID → SocketId 映射 |
| `mobius:device:socket:{socketId}` | STRING | 10s | SocketId → 设备UUID 映射 |
| `mobius:device:room:{roomId}` | HASH | 30s | 房间在线设备列表 |

**说明**：
- 设备在线状态通过 Redis Key 的 TTL 自动过期
- 客户端需每 10 秒发送 `desk:update-status` 心跳续期
- 房间在线列表每 30 秒续期

### 5.3 ER 图

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│    users     │       │   devices    │       │  versions    │
├──────────────┤       ├──────────────┤       ├──────────────┤
│ _id (PK)     │←──┐   │ _id (PK)     │       │ _id (PK)     │
│ username     │   │   │ uuid         │       │ version      │
│ password     │   └───│ user_id (FK) │       │ force        │
│ status       │       │ password     │       │ content      │
│ created_at   │       │ status       │       │ download_*   │
│ updated_at   │       │ created_at   │       │ created_at   │
└──────────────┘       │ updated_at   │       │ updated_at   │
                       └──────────────┘       └──────────────┘
```

---

## 6. API 接口设计

### 6.1 通用约定

- 基础路径：`/api/v1`
- 认证方式：`Authorization: Bearer <jwt_token>`
- 响应格式：

```json
{
  "code": 0,
  "data": {},
  "message": "success"
}
```

- 错误码约定：

| code | 说明 |
|------|------|
| 0 | 成功 |
| 400 | 参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器错误 |

### 6.2 认证接口

#### POST /api/v1/auth/register

注册用户

**请求体**：
```json
{
  "username": "string, 3-64字符, 必填",
  "password": "string, 6-32字符, 必填"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "id": 1,
    "username": "admin"
  },
  "message": "success"
}
```

#### POST /api/v1/auth/login

用户登录

**请求体**：
```json
{
  "username": "string, 必填",
  "password": "string, 必填"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": 1,
      "username": "admin"
    }
  },
  "message": "success"
}
```

### 6.3 设备接口

#### POST /api/v1/devices

注册设备（自动生成UUID+密码）

**请求体**：
```json
{
  "username": "string, 可选, 关联用户名"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "password": "abc123"
  },
  "message": "success"
}
```

#### POST /api/v1/devices/login

设备登录（验证UUID+密码）

**请求体**：
```json
{
  "uuid": "string, 必填",
  "password": "string, 必填"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "id": 1,
    "uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  },
  "message": "success"
}
```

#### POST /api/v1/devices/verify

连接验证（主控端验证被控端密码）

**请求体**：
```json
{
  "uuid": "string, 必填, 被控端设备码",
  "password": "string, 必填, 被控端密码"
}
```

**响应**：
```json
{
  "code": 0,
  "data": {
    "valid": true
  },
  "message": "success"
}
```

#### PUT /api/v1/devices/{uuid}/password

更新设备密码

**请求体**：
```json
{
  "password": "string, 必填, 新密码"
}
```

**响应**：
```json
{
  "code": 0,
  "data": null,
  "message": "success"
}
```

#### GET /api/v1/devices/{uuid}/online

查询设备是否在线

**响应**：
```json
{
  "code": 0,
  "data": {
    "online": true
  },
  "message": "success"
}
```

### 6.4 版本接口

#### GET /api/v1/versions/check?platform={platform}&version={version}

检查版本更新

**查询参数**：
- `platform`：win / mac / linux / android
- `version`：当前版本号

**响应**：
```json
{
  "code": 0,
  "data": {
    "hasUpdate": true,
    "force": false,
    "version": "1.0.1",
    "content": "修复已知问题",
    "downloadUrl": "https://..."
  },
  "message": "success"
}
```

---

## 7. WebSocket 信令设计

### 7.1 连接

**地址**：`ws://{host}:{port}/desk`

**传输方式**：WebSocket

**认证**：连接时携带 `token` 查询参数或 `device_uuid` + `device_password`

### 7.2 消息格式

**发送格式**：
```typescript
{
  event: string;       // 事件名
  request_id: string;  // 请求ID
  socket_id: string;   // 发送者Socket ID
  time: number;        // 时间戳
  data: any;           // 业务数据
}
```

**接收格式**：
```typescript
{
  event: string;       // 事件名
  request_id: string;  // 请求ID
  time: number;        // 时间戳
  data: any;           // 业务数据
}
```

### 7.3 信令事件

#### desk:join — 加入房间

**发送**：
```json
{
  "event": "desk:join",
  "request_id": "xxx",
  "socket_id": "xxx",
  "time": 1719000000000,
  "data": {
    "uuid": "设备码",
    "password": "设备密码"
  }
}
```

**接收**（desk:joined）：
```json
{
  "event": "desk:joined",
  "request_id": "xxx",
  "time": 1719000000000,
  "data": {
    "roomId": "room_xxx"
  }
}
```

#### desk:update-status — 更新在线状态（心跳）

**发送**：
```json
{
  "event": "desk:update-status",
  "request_id": "xxx",
  "socket_id": "xxx",
  "time": 1719000000000,
  "data": {
    "uuid": "设备码"
  }
}
```

服务端收到后刷新 Redis 中 `mobius:device:uuid:{uuid}` 的 TTL（10秒）。

#### desk:start-remote — 发起远程控制

**发送**：
```json
{
  "event": "desk:start-remote",
  "request_id": "xxx",
  "socket_id": "xxx",
  "time": 1719000000000,
  "data": {
    "controller_uuid": "主控端设备码",
    "controller_password": "主控端密码",
    "target_uuid": "被控端设备码",
    "target_password": "被控端密码",
    "max_bitrate": 2000,
    "max_framerate": 60,
    "resolution": "1080p",
    "video_hint": "detailed",
    "audio_hint": "speech"
  }
}
```

**接收**（desk:start-remote-result）：
```json
{
  "event": "desk:start-remote-result",
  "request_id": "xxx",
  "time": 1719000000000,
  "data": {
    "code": 0,
    "message": "success",
    "controller": { "uuid": "xxx", "socket_id": "xxx" },
    "target": { "uuid": "xxx", "socket_id": "xxx" }
  }
}
```

**错误码**：

| code | 说明 |
|------|------|
| 0 | 成功 |
| 1 | 参数为空 |
| 2 | 主控端密码错误 |
| 3 | 被控端密码错误 |
| 4 | 被控端不在线 |
| 5 | 服务器内部错误 |

#### desk:offer / desk:answer / desk:candidate — WebRTC 信令

**发送/接收**：
```json
{
  "event": "desk:offer",
  "request_id": "xxx",
  "socket_id": "xxx",
  "time": 1719000000000,
  "data": {
    "target_socket_id": "目标Socket ID",
    "sdp": "SDP内容"
  }
}
```

服务端根据 `target_socket_id` 转发信令到目标设备。

#### desk:behavior — 远程操作行为

**发送**（主控端）：
```json
{
  "event": "desk:behavior",
  "request_id": "xxx",
  "socket_id": "xxx",
  "time": 1719000000000,
  "data": {
    "type": "mouseMove",
    "x": 100,
    "y": 200,
    "amount": 0,
    "keyboard_type": ""
  }
}
```

**行为类型枚举**：

| type | 说明 | 参数 |
|------|------|------|
| mouseMove | 鼠标移动 | x, y |
| mouseDrag | 鼠标拖拽 | x, y |
| leftClick | 左键单击 | x, y |
| rightClick | 右键单击 | x, y |
| doubleClick | 双击 | x, y |
| pressButtonLeft | 按下左键 | x, y |
| releaseButtonLeft | 释放左键 | x, y |
| scrollUp | 向上滚动 | amount |
| scrollDown | 向下滚动 | amount |
| scrollLeft | 向左滚动 | amount |
| scrollRight | 向右滚动 | amount |
| keyboardType | 键盘输入 | keyboard_type |
| keyboardPressKey | 按键按下 | keyboard_type |
| keyboardReleaseKey | 按键释放 | keyboard_type |
| performDown | 触摸按下（移动端） | x, y |
| performMove | 触摸移动（移动端） | x, y |
| performUp | 触摸释放（移动端） | x, y |

#### desk:change-params — 动态调整参数

**发送**：
```json
{
  "event": "desk:change-params",
  "request_id": "xxx",
  "socket_id": "xxx",
  "time": 1719000000000,
  "data": {
    "target_socket_id": "目标Socket ID",
    "max_bitrate": 3000,
    "max_framerate": 60,
    "resolution": "1080p",
    "video_hint": "detailed",
    "audio_hint": "speech"
  }
}
```

### 7.4 信令流程图

```
被控端                          服务端                          主控端
  │                              │                              │
  │──desk:join─────────────────>│                              │
  │<──desk:joined───────────────│                              │
  │                              │                              │
  │──desk:update-status(心跳)──>│                              │
  │                              │                              │
  │                              │<──desk:join─────────────────│
  │                              │──desk:joined───────────────>│
  │                              │                              │
  │                              │<──desk:start-remote─────────│
  │<──desk:start-remote-result──│──desk:start-remote-result──>│
  │                              │                              │
  │<──desk:offer────────────────│<──desk:offer────────────────│
  │──desk:answer───────────────>│──desk:answer───────────────>│
  │<──desk:candidate───────────>│<──desk:candidate───────────>│
  │                              │                              │
  │         ═══ WebRTC P2P 连接建立 ═══                        │
  │                              │                              │
  │<──desk:behavior─────────────│<──desk:behavior─────────────│
  │                              │                              │
  │         ═══ 视频流 (WebRTC MediaStream) ═══                │
  │═══════════════════════════════════════════════════════════>│
```

---

## 8. 配置与部署

### 8.1 环境变量

```env
# 应用
APP_PORT=4200
APP_ENV=development

# MongoDB
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_USERNAME=root
MONGO_PASSWORD=123456
MONGO_DATABASE=mobius_desk

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT
JWT_SECRET=your-jwt-secret-key
JWT_EXPIRES_IN=7d

# Coturn
COTURN_URL=turn:your-server:3478
COTURN_USERNAME=mobius
COTURN_PASSWORD=your-coturn-password
```

### 8.2 Docker Compose

```yaml
version: '3.8'
services:
  mongodb:
    image: mongo:7.0
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: 123456
      MONGO_INITDB_DATABASE: mobius_desk
    volumes:
      - mongo_data:/data/db

  redis:
    image: redis:7.0
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  coturn:
    image: coturn/coturn:latest
    network_mode: host
    environment:
      - REALM=mobius-desk
      - MIN_PORT=49152
      - MAX_PORT=65535

volumes:
  mongo_data:
  redis_data:
```

### 8.3 构建与启动

```bash
# 安装依赖
npm install

# 开发模式
npm run start:dev

# 生产构建
npm run build

# 生产启动
npm run start:prod
```