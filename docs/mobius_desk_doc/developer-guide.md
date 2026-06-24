# MobiusDesk - 开发者使用说明

> 版本：v1.0  
> 更新日期：2026-06-24  

---

## 1. 环境准备

### 1.1 必需软件

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| Node.js | >= 22.12.0 | 运行时 |
| pnpm | 最新版 | 包管理器 |
| Git | 最新版 | 版本控制 |

### 1.2 安装 Node.js

推荐使用 nvm 管理 Node.js 版本：

```bash
nvm install 22
nvm use 22
```

### 1.3 安装 pnpm

```bash
npm install -g pnpm
```

---

## 2. 项目启动

### 2.1 克隆项目

```bash
git clone <repository-url>
cd remote-control/mobius_desk
```

### 2.2 安装依赖

```bash
pnpm install
```

如遇构建脚本问题：

```bash
pnpm approve-builds esbuild
```

### 2.3 配置环境变量

项目使用 Vite 环境变量，默认配置如下：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VITE_API_URL` | `/api/v1` | API 基础路径 |
| `VITE_WSS_URL` | `ws://localhost:4200/desk` | WebSocket 地址 |
| `VITE_COTURN_URL` | 空 | COTURN TURN 服务器地址 |

开发模式下 API 请求通过 Vite 代理转发到 `http://localhost:4200`。

### 2.4 启动开发服务器

```bash
# Web 开发模式
pnpm dev

# Electron 开发模式（自动启动 Electron 窗口）
pnpm dev
```

开发服务器默认地址：`http://localhost:5173`

### 2.5 前置依赖

确保以下服务已启动：

- **MobiusDesk Service**：`http://localhost:4200`（API + WebSocket）
- **MongoDB**：`localhost:27017`
- **Redis**：`localhost:6379`

---

## 3. 项目结构

```
mobius_desk/
├── electron-main/          # Electron 主进程
│   ├── index.ts            # 主进程入口（窗口管理/IPC）
│   ├── preload.ts          # 预加载脚本
│   └── ipc/                # IPC 处理模块
│       ├── mouse.ts        # 鼠标操作
│       ├── keyboard.ts     # 键盘操作
│       ├── screen.ts       # 屏幕捕获
│       └── window.ts       # 窗口管理
├── src/
│   ├── main.tsx            # React 入口
│   ├── App.tsx             # 根组件（路由配置）
│   ├── api/                # API 接口层
│   ├── stores/             # Zustand 状态管理
│   ├── hooks/              # 自定义 Hooks
│   ├── lib/                # 核心库（WebSocket/WebRTC/IPC）
│   ├── pages/              # 页面组件
│   ├── components/         # 公共组件
│   ├── types/              # TypeScript 类型定义
│   ├── constants/          # 常量
│   └── utils/              # 工具函数
├── electron-builder.json5  # Electron 构建配置
├── vite.config.ts          # Vite 配置
└── tailwind.config.js      # TailwindCSS 配置
```

---

## 4. 开发指南

### 4.1 新增页面

1. 在 `src/pages/` 下创建页面目录和组件
2. 在 `src/App.tsx` 中添加路由
3. 在 `src/components/Sidebar.tsx` 中添加导航项（如需要）

### 4.2 新增 API 接口

1. 在 `src/api/` 下创建或编辑接口文件
2. 在 `src/types/api.ts` 中定义请求/响应类型
3. 在对应的 Store 或 Hook 中调用

### 4.3 新增 Electron IPC

1. 在 `electron-main/ipc/` 下创建或编辑 IPC 处理模块
2. 在 `electron-main/index.ts` 中注册 IPC Handler
3. 在 `src/lib/ipc/ipc-renderer.ts` 中添加渲染进程调用方法
4. 在 `src/constants/events.ts` 中定义事件名常量

### 4.4 状态管理

使用 Zustand，按功能模块划分 Store：

```typescript
// src/stores/xxx-store.ts
import { create } from 'zustand';

interface XxxState {
  data: string;
  setData: (data: string) => void;
}

export const useXxxStore = create<XxxState>((set) => ({
  data: '',
  setData: (data) => set({ data }),
}));
```

需要持久化时使用 `persist` 中间件：

```typescript
import { persist } from 'zustand/middleware';

export const useXxxStore = create(
  persist<XxxState>(
    (set) => ({ ... }),
    { name: 'mobius_xxx' }
  )
);
```

---

## 5. 构建与打包

### 5.1 构建命令

```bash
# Web 生产构建
pnpm build

# Electron Windows 安装包
pnpm build:win

# Electron macOS 安装包
pnpm build:mac

# Electron Linux 安装包
pnpm build:linux
```

### 5.2 输出目录

| 平台 | 输出路径 |
|------|----------|
| Web | `dist/` |
| Windows | `dist-electron/` (.exe) |
| macOS | `dist-electron/` (.dmg) |
| Linux | `dist-electron/` (.deb) |

### 5.3 Electron Builder 配置

编辑 `electron-builder.json5` 修改打包配置：

- `appId`：应用 ID
- `productName`：产品名称
- `win/mac/linux`：各平台打包选项
- `nsis`：Windows 安装程序配置

---

## 6. 调试技巧

### 6.1 渲染进程调试

- 开发模式下按 `F12` 或 `Ctrl+Shift+I` 打开 DevTools
- Web 模式直接使用浏览器 DevTools

### 6.2 主进程调试

在 `.vscode/launch.json` 中配置 Electron 主进程调试：

```json
{
  "type": "node",
  "request": "launch",
  "name": "Electron Main",
  "runtimeExecutable": "${workspaceFolder}/node_modules/.bin/electron",
  "program": "${workspaceFolder}/dist-electron/main/index.js"
}
```

### 6.3 IPC 通信调试

在主进程 IPC Handler 中添加日志：

```typescript
ipcMain.handle('mouse:move', (_, x, y) => {
  console.log('[IPC] mouse:move', x, y);
  return mouse.move({ x, y });
});
```

---

## 7. 常见问题

### Q: pnpm install 失败？

```bash
# 清除缓存重新安装
pnpm store prune
pnpm install
```

### Q: Electron 启动白屏？

检查 Vite 开发服务器是否正常运行，Electron 加载的 URL 是否正确。

### Q: nut-js 报错？

nut-js 需要 native 依赖，确保 Node.js 版本匹配。Windows 上可能需要安装 Visual Studio Build Tools。

### Q: WebRTC 连接失败？

1. 检查 COTURN 服务器是否正常运行
2. 检查防火墙是否开放端口
3. 检查 ICE Candidate 是否正常交换