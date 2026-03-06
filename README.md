# Claude Root 管理脚本

这个目录包含用于管理 dev 用户 Claude Code 环境的脚本。

## 快速开始

### 全新安装

```bash
cd /root/claude-root
./install.sh
```

install.sh 会自动完成：
- 创建 dev 用户
- 配置 sudo 权限
- 复制 Oh My Zsh 配置
- 复制字体和工具
- 创建 .claude 目录结构
- 设置软链接
- 创建环境配置
- 链接 Node.js
- 修复所有权限
- 安装管理脚本

### 验证安装

```bash
claude-diagnose
```

### 启动 Claude Code

```bash
claude-dev
```

---

## 脚本说明

### 0. install.sh
**用途：** 全新安装和初始化 dev 用户环境

**功能：**
- 创建 dev 用户（如果不存在）
- 配置无密码 sudo
- 复制所有必要的配置文件
- 设置目录权限
- 安装管理脚本到系统路径

**使用：**
```bash
./install.sh
```

**注意：** 必须以 root 用户运行

---

### 1. claude-dev
**用途：** 从 root 用户一键启动 Claude Code（dev 用户模式）

**功能：**
- 自动切换到 dev 用户
- 加载完整的环境变量（ANTHROPIC_BASE_URL, TOKEN 等）
- 保持当前工作目录
- 启动 `--dangerously-skip-permissions` 模式

**使用：**
```bash
claude-dev
```

**位置：**
- 源文件：`/root/claude-root/claude-dev`
- 系统链接：`/usr/local/bin/claude-dev`

---

### 2. claude-diagnose
**用途：** 诊断 dev 用户的 Claude Code 环境

**检查项目：**
- 用户信息
- 环境变量（ANTHROPIC_BASE_URL, TOKEN）
- 命令可用性（claude, node, npm）
- 目录访问权限
- 配置文件读取
- 插件目录
- Sudo 权限

**使用：**
```bash
claude-diagnose
```

**位置：**
- 源文件：`/root/claude-root/claude-diagnose`
- 系统链接：`/usr/local/bin/claude-diagnose`

---

### 3. sync-dev-config
**用途：** 同步 root 配置到 dev 用户

**同步内容：**
1. .config 配置（ccstatusline, Claude, git）
2. Git 配置和凭证
3. SSH 密钥
4. Docker 配置
5. .claude.json 配置文件
6. .claude 目录软链接
7. .codemap 软链接
8. 环境变量文件（.claude_env）
9. Node.js 全局链接
10. 工作目录权限（所有项目的 docs/ 和 tests/）

**使用：**
```bash
sync-dev-config
```

**位置：**
- 源文件：`/root/claude-root/sync-dev-config`
- 系统链接：`/usr/local/bin/sync-dev-config`

---

## 安装

将脚本链接到系统路径：

```bash
cd /root/claude-root
ln -sf $(pwd)/claude-dev /usr/local/bin/claude-dev
ln -sf $(pwd)/claude-diagnose /usr/local/bin/claude-diagnose
ln -sf $(pwd)/sync-dev-config /usr/local/bin/sync-dev-config
```

---

## 架构说明

### dev 用户环境架构

**独立拥有（可写）：**
- `/home/dev/.claude/session-env/` - 会话环境
- `/home/dev/.claude/cache/` - 缓存
- `/home/dev/.claude/debug/` - 调试日志
- `/home/dev/.claude/telemetry/` - 遥测数据
- `/home/dev/.claude/projects/` - 项目配置
- `/home/dev/.claude/.claude.json` - 用户配置
- `/home/dev/.claude/history.jsonl` - 历史记录

**软链接到 root（只读）：**
- `/home/dev/.claude/CLAUDE.md` → `/root/.claude/CLAUDE.md`
- `/home/dev/.claude/settings.json` → `/root/.claude/settings.json`
- `/home/dev/.claude/plugins/` → `/root/.claude/plugins/`
- `/home/dev/.claude/skills/` → `/root/.claude/skills/`
- `/home/dev/.codemap/` → `/root/.codemap/`

**工作目录权限：**
- `/root/` - 755（dev 可进入）
- `/root/*/` - 755（所有项目可访问）
- `/root/*/docs/` - 777（可写）
- `/root/*/tests/` - 777（可写）

**受保护目录：**
- `/root/.ssh/` - 700（仅 root）
- `/root/.gnupg/` - 700（仅 root）
- `/root/.claude/.credentials.json` - 600（仅 root）

---

## 环境变量

dev 用户的环境变量配置在 `/home/dev/.claude_env`：

```bash
export ANTHROPIC_BASE_URL="https://code.mmkg.cloud"
export ANTHROPIC_AUTH_TOKEN="sk-4d6a..."
export PATH="$HOME/.local/bin:/usr/local/bin:..."
```

---

## 故障排除

### 问题：环境变量未加载
**解决：** 运行 `sync-dev-config` 重新生成 `.claude_env`

### 问题：无法写入 docs/memory
**解决：** 运行 `sync-dev-config` 修复目录权限

### 问题：statusline 显示异常
**解决：** 运行 `sync-dev-config` 同步 ccstatusline 配置

### 问题：插件无法加载
**解决：** 检查 `/root/.claude/plugins` 权限，运行 `sync-dev-config`

---

## 维护

### 更新脚本
1. 编辑 `/root/claude-root/` 中的脚本
2. 脚本会自动生效（通过软链接）

### 添加新配置
1. 在 root 用户下配置
2. 运行 `sync-dev-config` 同步到 dev 用户

### 重置环境
```bash
# 完全重新同步
sync-dev-config

# 验证环境
claude-diagnose
```

---

## 版本信息

- 创建日期：2026-03-06
- Claude Code 版本：2.1.70
- Node.js 版本：v24.14.0
- 系统：Linux (Debian)
