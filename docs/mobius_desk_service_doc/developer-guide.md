# MobiusDesk Service - 开发者使用说明

> 版本：v1.0  
> 更新日期：2026-06-24  

---

## 1. 环境准备

### 1.1 必需软件

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 22.12.0 | 运行时 |
| pnpm | 最新版 | 包管理器 |
| MongoDB | 7.0 | 数据库 |
| Redis | 7.0 | 缓存 |
| Docker | 最新版 | 容器化部署（可选） |
| Git | 最新版 | 版本控制 |

### 1.2 安装 pnpm

```bash
npm install -g pnpm
```

---

## 2. 项目启动

### 2.1 克隆项目

```bash
git clone <repository-url>
cd remote-control/mobius_desk_service
```

### 2.2 安装依赖

```bash
pnpm install
```

如遇构建脚本问题：

```bash
pnpm approve-builds
```

### 2.3 配置环境变量

复制环境变量模板：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

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

### 2.4 启动基础设施

**方式一：Docker Compose（推荐）**

```bash
cd docker
docker compose up -d
```

这将启动 MongoDB、Redis、Coturn 三个服务。

**方式二：本地安装**

分别安装并启动 MongoDB 7.0 和 Redis 7.0。

### 2.5 启动开发服务器

```bash
pnpm start:dev
```

服务启动后：
- HTTP API：`http://localhost:4200/api/v1`
- WebSocket：`ws://localhost:4200/desk`
- Swagger 文档：`http://localhost:4200/api-docs`（如已配置）

---

## 3. 项目结构

```
mobius_desk_service/
├── src/
│   ├── main.ts                 # 应用入口
│   ├── app.module.ts           # 根模块
│   ├── config/                 # 配置模块
│   │   ├── database.config.ts  # MongoDB 连接
│   │   ├── redis.config.ts     # Redis 连接
│   │   ├── jwt.config.ts       # JWT 配置
│   │   └── coturn.config.ts    # COTURN 配置
│   ├── common/                 # 公共模块
│   │   ├── decorators/         # 自定义装饰器
│   │   ├── dto/                # 公共 DTO
│   │   ├── filters/            # 异常过滤器
│   │   ├── guards/             # 认证守卫
│   │   ├── interceptors/       # 响应拦截器
│   │   ├── middleware/         # 中间件
│   │   ├── pipes/              # 参数校验管道
│   │   └── redis/              # Redis 模块
│   ├── modules/                # 业务模块
│   │   ├── auth/               # 认证
│   │   ├── users/              # 用户
│   │   ├── devices/            # 设备
│   │   ├── versions/           # 版本
│   │   ├── desk/               # 远程桌面信令
│   │   └── config/             # COTURN 配置
│   └── utils/                  # 工具函数
├── docker/                     # Docker 配置
│   └── docker-compose.yml
├── test/                       # 测试
├── .env                        # 环境变量
├── .env.example                # 环境变量模板
└── package.json
```

---

## 4. 开发指南

### 4.1 新增业务模块

使用 NestJS CLI 生成模块骨架：

```bash
pnpm nest g module modules/xxx
pnpm nest g controller modules/xxx
pnpm nest g service modules/xxx
```

或手动创建：

1. 在 `src/modules/` 下创建模块目录
2. 创建 `xxx.module.ts`、`xxx.controller.ts`、`xxx.service.ts`
3. 在 `app.module.ts` 中注册模块

### 4.2 新增 API 接口

1. 在 Controller 中定义路由

```typescript
@Post()
async create(@Body() dto: CreateXxxDto) {
  return this.xxxService.create(dto);
}
```

2. 创建 DTO 并添加校验

```typescript
export class CreateXxxDto {
  @IsString()
  @IsNotEmpty()
  name: string;
}
```

3. 在 Service 中实现业务逻辑

4. 如需持久化，创建 Mongoose Schema

### 4.3 新增 WebSocket 事件

在 `src/modules/desk/desk.gateway.ts` 中添加：

```typescript
@SubscribeMessage('desk:xxx')
async handleXxx(@ConnectedSocket() client: Socket, @MessageBody() data: any) {
  // 处理逻辑
}
```

### 4.4 新增 MongoDB 集合

1. 在对应模块下创建 `schemas/xxx.schema.ts`

```typescript
@Schema({ collection: 'xxx', timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' } })
export class Xxx extends Document {
  @Prop({ required: true })
  name: string;
}

export const XxxSchema = SchemaFactory.createForClass(Xxx);
```

2. 在 Module 中注册 Schema

```typescript
MongooseModule.forFeature([{ name: Xxx.name, schema: XxxSchema }])
```

### 4.5 Redis 操作

注入 RedisService：

```typescript
constructor(private readonly redisService: RedisService) {}

// 设置值（带TTL）
await this.redisService.set('key', 'value', 'EX', 10);

// 获取值
const value = await this.redisService.get('key');

// 删除
await this.redisService.del('key');
```

---

## 5. 构建与部署

### 5.1 构建

```bash
# 生产构建
pnpm build
```

### 5.2 启动

```bash
# 开发模式（热重载）
pnpm start:dev

# 生产模式
pnpm start:prod
```

### 5.3 Docker 部署

```bash
# 启动所有服务
cd docker
docker compose up -d

# 查看日志
docker compose logs -f

# 停止
docker compose down

# 重建
docker compose up -d --build
```

### 5.4 生产环境检查清单

- [ ] 修改 `.env` 中的 `JWT_SECRET` 为强随机字符串
- [ ] 修改 MongoDB 默认密码
- [ ] 配置 COTURN 服务器地址
- [ ] 配置防火墙规则（开放 4200、3478 端口）
- [ ] 启用 HTTPS（推荐使用 Nginx 反向代理）
- [ ] 配置日志持久化

---

## 6. API 测试

### 6.1 使用 Swagger

访问 `http://localhost:4200/api-docs` 查看交互式 API 文档。

### 6.2 使用 cURL

```bash
# 用户注册
curl -X POST http://localhost:4200/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'

# 用户登录
curl -X POST http://localhost:4200/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}'

# 设备注册
curl -X POST http://localhost:4200/api/v1/devices \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{}'

# 查询设备在线
curl http://localhost:4200/api/v1/devices/{uuid}/online \
  -H "Authorization: Bearer <token>"
```

### 6.3 单元测试

```bash
# 运行所有测试
pnpm test

# 运行 e2e 测试
pnpm test:e2e

# 运行测试覆盖率
pnpm test:cov
```

---

## 7. 常见问题

### Q: MongoDB 连接失败？

1. 检查 MongoDB 是否启动：`mongosh --eval "db.runCommand({ ping: 1 })"`
2. 检查 `.env` 中的连接配置
3. 检查防火墙是否开放 27017 端口

### Q: Redis 连接失败？

1. 检查 Redis 是否启动：`redis-cli ping`
2. 检查 `.env` 中的 Redis 配置
3. 如有密码，确认密码正确

### Q: WebSocket 连接失败？

1. 确认服务已启动并监听 4200 端口
2. 检查 Socket.IO 路径配置（默认 `/desk`）
3. 如使用 Nginx 反向代理，确保 WebSocket 升级头正确配置

### Q: JWT 认证失败？

1. 确认 `.env` 中 `JWT_SECRET` 已配置
2. 检查 Token 是否过期
3. 确认请求头格式：`Authorization: Bearer <token>`