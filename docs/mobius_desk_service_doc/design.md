# MobiusDesk Service - 项目设计文档

> 版本：v1.0  
> 更新日期：2026-06-24  

---

## 1. 系统架构设计

### 1.1 整体架构

服务端采用 NestJS 三层架构 + WebSocket Gateway，负责设备管理、信令转发、用户认证。

```
┌──────────────────────────────────────────────────────────┐
│                     客户端层                              │
│   mobius-desk (Electron/React)                           │
│   mobius-desk-flutter (Android/iOS)                      │
│   Web Browser                                            │
└──────────────────────────┬───────────────────────────────┘
                           │
            ┌──────────────┴──────────────┐
            │         HTTP API            │
            │    (NestJS Controllers)      │
            └──────────────┬──────────────┘
                           │
┌──────────────────────────┴───────────────────────────────┐
│                    Service Layer                          │
│   AuthService / DevicesService / VersionsService /       │
│   DeskService / UsersService / ConfigService             │
└──────────────────────────┬───────────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────────┐
│                    Data Layer                             │
│   ┌────────────────┐  ┌────────────────┐                 │
│   │  MongoDB       │  │  Redis         │                 │
│   │  (Mongoose)    │  │  (ioredis)     │                 │
│   │  持久化存储     │  │  在线状态/缓存  │                 │
│   └────────────────┘  └────────────────┘                 │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│              WebSocket Gateway (Socket.IO)                │
│   DeskGateway — 远程桌面信令转发                           │
│   join / leave / startRemote / offer / answer /          │
│   candidate / behavior / changeParams                    │
└──────────────────────────────────────────────────────────┘
```

### 1.2 请求处理流程

```
HTTP Request
   │
   ├── LoggerMiddleware (日志记录)
   ├── ValidationPipe (参数校验)
   ├── JwtAuthGuard (认证守卫，部分路由)
   ├── Controller (路由处理)
   ├── Service (业务逻辑)
   ├── Repository (数据访问)
   ├── TransformInterceptor (响应格式化)
   └── AllExceptionsFilter (异常捕获)
```

---

## 2. 核心模块设计

### 2.1 认证模块（Auth）

**职责**：用户注册、登录、JWT Token 签发

**流程**：
1. 用户提交用户名+密码注册
2. 密码使用 bcrypt 加密存储（`crypto.util.ts`）
3. 登录成功后签发 JWT Token
4. 后续请求通过 `Authorization: Bearer <token>` 鉴权

**JWT 策略**：
- 使用 Passport + passport-jwt
- Token 有效期：7天
- 从请求头 `Authorization` 提取 Token

### 2.2 设备模块（Devices）

**职责**：设备注册、认证、在线状态管理

**核心流程**：
1. 客户端调用 `POST /devices` 注册，获取 UUID + 密码
2. 客户端调用 `POST /devices/login` 登录
3. 登录后连接 WebSocket，发送 `desk:join` 加入房间
4. 定时发送 `desk:update-status` 心跳（10秒），刷新 Redis TTL
5. 主控端通过 `POST /devices/verify` 验证被控端密码
6. 发起远程连接，服务端验证双方后转发信令

### 2.3 远程桌面信令模块（Desk）

**职责**：WebSocket 信令转发

**核心设计**：
- 使用 Socket.IO Gateway 处理 WebSocket 连接
- 每个设备连接后加入以 UUID 标识的房间
- 信令转发：根据 `target_socket_id` 将消息转发到目标设备
- 在线状态：通过 Redis 缓存管理，10秒 TTL 自动过期

**信令处理流程**：

```
desk:start-remote
   │
   ├── 1. 验证主控端密码
   ├── 2. 验证被控端密码
   ├── 3. 检查被控端在线状态
   ├── 4. 转发连接请求到被控端
   └── 5. 返回结果到主控端

desk:behavior
   │
   └── 根据 target_socket_id 转发到被控端

desk:offer / desk:answer / desk:candidate
   │
   └── 根据 target_socket_id 转发到对端
```

### 2.4 配置模块（Config）

**职责**：COTURN 配置下发

**接口**：`GET /api/v1/config/coturn`

**返回**：
```json
{
  "code": 0,
  "data": {
    "urls": ["turn:server:3478"],
    "username": "mobius",
    "credential": "password"
  }
}
```

### 2.5 版本模块（Versions）

**职责**：客户端版本检查、更新提示

**逻辑**：
1. 客户端上报当前版本号和平台
2. 服务端查询最新版本记录
3. 比较版本号，返回是否有更新
4. 返回下载链接和是否强制更新

---

## 3. 数据存储设计

### 3.1 MongoDB 集合

| 集合 | 说明 | 核心字段 |
|------|------|----------|
| users | 用户信息 | username, password(bcrypt), status |
| devices | 设备信息 | uuid, password, user_id, status |
| versions | 版本信息 | version, force, download_* |

### 3.2 Redis 缓存

| Key 模式 | 类型 | TTL | 说明 |
|----------|------|-----|------|
| `mobius:device:uuid:{uuid}` | STRING | 10s | UUID → SocketId |
| `mobius:device:socket:{socketId}` | STRING | 10s | SocketId → UUID |
| `mobius:device:room:{roomId}` | HASH | 30s | 房间在线列表 |

**TTL 策略**：
- 设备在线状态 10 秒过期，需客户端心跳续期
- 房间列表 30 秒过期
- 过期后设备视为离线

---

## 4. 公共模块设计

### 4.1 统一响应格式

```typescript
// TransformInterceptor
{
  code: 0,        // 0=成功, 非0=错误码
  data: {},       // 业务数据
  message: "success"
}
```

### 4.2 异常处理

```typescript
// AllExceptionsFilter
{
  code: 500,
  data: null,
  message: "Internal server error"
}
```

### 4.3 参数校验

使用 `class-validator` + `ValidationPipe`，DTO 类定义校验规则。

### 4.4 认证守卫

`JwtAuthGuard`：从请求头提取 Token，验证 JWT 签名和有效期。

---

## 5. 部署架构设计

```
┌─────────────────────────────────────────────┐
│              Docker Compose                  │
│                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ MongoDB  │  │  Redis   │  │  Coturn   │  │
│  │  7.0     │  │  7.0     │  │  latest   │  │
│  │  :27017  │  │  :6379   │  │  :3478    │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                              │
│  ┌──────────────────────────────────────┐   │
│  │  MobiusDesk Service                  │   │
│  │  NestJS :4200                        │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

**数据卷**：
- `mongo_data` → MongoDB 数据持久化
- `redis_data` → Redis 数据持久化

---

## 6. 关键技术决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 框架 | NestJS | 模块化、TypeScript 原生、装饰器 |
| 数据库 | MongoDB | 灵活 Schema、无需迁移 |
| 缓存 | Redis | 高性能、TTL 原生支持 |
| WebSocket | Socket.IO | 房间机制、自动重连、广泛兼容 |
| 认证 | Passport + JWT | 标准方案、无状态 |
| NAT 穿透 | Coturn | 开源 TURN 服务器、标准 STUN/TURN 协议 |