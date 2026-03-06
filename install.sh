#!/bin/bash
# Claude Root 环境安装脚本
# 用于初始化 dev 用户和 Claude Code 环境

set -e  # 遇到错误立即退出

echo "=========================================="
echo "  Claude Root 环境安装"
echo "=========================================="
echo ""

# 检查是否以 root 运行
if [ "$EUID" -ne 0 ]; then
    echo "错误：此脚本必须以 root 用户运行"
    exit 1
fi

# 1. 创建 dev 用户
echo "1. 创建 dev 用户..."
if id "dev" &>/dev/null; then
    echo "   ⚠ dev 用户已存在，跳过创建"
else
    useradd -m -s /bin/zsh dev
    echo "   ✓ dev 用户已创建"
fi

# 2. 配置 sudo 权限
echo "2. 配置 sudo 权限..."
if grep -q "^dev ALL=(ALL) NOPASSWD:ALL" /etc/sudoers; then
    echo "   ⚠ sudo 权限已配置，跳过"
else
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    echo "   ✓ sudo 权限已配置"
fi

# 3. 检查 zsh 是否安装
echo "3. 检查 zsh..."
if ! command -v zsh &> /dev/null; then
    echo "   ⚠ zsh 未安装，请先安装 zsh"
    echo "   运行: apt install zsh -y"
    exit 1
else
    echo "   ✓ zsh 已安装"
fi

# 4. 复制 Oh My Zsh 配置
echo "4. 复制 Oh My Zsh 配置..."
if [ -d "/root/.oh-my-zsh" ]; then
    cp -r /root/.oh-my-zsh /home/dev/ 2>/dev/null || true
    cp /root/.zshrc /home/dev/ 2>/dev/null || true
    cp /root/.p10k.zsh /home/dev/ 2>/dev/null || true
    echo "   ✓ Oh My Zsh 配置已复制"
else
    echo "   ⚠ /root/.oh-my-zsh 不存在，跳过"
fi

# 5. 复制字体
echo "5. 复制字体..."
if [ -d "/root/.local/share/fonts" ]; then
    mkdir -p /home/dev/.local/share
    cp -r /root/.local/share/fonts /home/dev/.local/share/ 2>/dev/null || true
    echo "   ✓ 字体已复制"
else
    echo "   ⚠ 字体目录不存在，跳过"
fi

# 6. 复制 .local/bin
echo "6. 复制 .local/bin..."
if [ -d "/root/.local/bin" ]; then
    mkdir -p /home/dev/.local/bin
    cp -r /root/.local/bin/* /home/dev/.local/bin/ 2>/dev/null || true
    echo "   ✓ .local/bin 已复制"
fi

# 7. 创建 .claude 目录结构
echo "7. 创建 .claude 目录..."
mkdir -p /home/dev/.claude/{session-env,cache,debug,telemetry,projects,backups}
echo "   ✓ .claude 目录已创建"

# 8. 复制 .claude.json
echo "8. 复制 .claude.json..."
if [ -f "/root/.claude.json" ]; then
    cp /root/.claude.json /home/dev/ 2>/dev/null || true
    cp /root/.claude.json /home/dev/.claude/ 2>/dev/null || true
    echo "   ✓ .claude.json 已复制"
fi

# 9. 创建软链接到共享配置
echo "9. 创建配置软链接..."
cd /home/dev/.claude
ln -sf /root/.claude/CLAUDE.md . 2>/dev/null || true
ln -sf /root/.claude/settings.json . 2>/dev/null || true
ln -sf /root/.claude/plugins . 2>/dev/null || true
ln -sf /root/.claude/skills . 2>/dev/null || true
ln -sf /root/.codemap /home/dev/.codemap 2>/dev/null || true
echo "   ✓ 软链接已创建"

# 10. 创建环境配置文件
echo "10. 创建环境配置..."

# 从 root 用户的 .zshrc 或环境变量中读取 API 配置
ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN:-}"

# 如果环境变量未设置，尝试从 root 的 .zshrc 读取
if [ -z "$ANTHROPIC_AUTH_TOKEN" ] && [ -f "/root/.zshrc" ]; then
    ANTHROPIC_BASE_URL=$(grep "export ANTHROPIC_BASE_URL" /root/.zshrc | cut -d'"' -f2 2>/dev/null || echo "https://api.anthropic.com")
    ANTHROPIC_AUTH_TOKEN=$(grep "export ANTHROPIC_AUTH_TOKEN" /root/.zshrc | cut -d'"' -f2 2>/dev/null || echo "")
fi

cat > /home/dev/.claude_env << ENVEOF
#!/bin/zsh
# Claude Code 环境配置

# Anthropic API 配置
export ANTHROPIC_BASE_URL="${ANTHROPIC_BASE_URL}"
export ANTHROPIC_AUTH_TOKEN="${ANTHROPIC_AUTH_TOKEN}"

# PATH 配置
export PATH="\$HOME/.local/bin:/usr/local/bin:\$HOME/.local/share/radare2/prefix/bin:\$HOME/.cargo/bin:\$PATH"

# NVM 配置
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"

# Cargo 配置
export PATH="\$HOME/.cargo/bin:\$PATH"
ENVEOF
echo "   ✓ .claude_env 已创建"

# 11. 链接 Node.js
echo "11. 链接 Node.js..."
if [ -f "/root/.nvm/versions/node/v24.14.0/bin/node" ]; then
    ln -sf /root/.nvm/versions/node/v24.14.0/bin/node /usr/local/bin/node 2>/dev/null || true
    ln -sf /root/.nvm/versions/node/v24.14.0/bin/npm /usr/local/bin/npm 2>/dev/null || true
    ln -sf /root/.nvm/versions/node/v24.14.0/bin/npx /usr/local/bin/npx 2>/dev/null || true
    echo "   ✓ Node.js 已链接"
else
    echo "   ⚠ Node.js 未找到，跳过"
fi

# 12. 设置文件所有权
echo "12. 设置文件所有权..."
chown -R dev:dev /home/dev
echo "   ✓ 所有权已设置"

# 13. 修复目录权限
echo "13. 修复目录权限..."
chmod 755 /root

# 开放所有一级子目录（除了敏感目录）
for dir in /root/*/; do
    dirname=$(basename "$dir")
    if [[ "$dirname" != ".ssh" && "$dirname" != ".gnupg" && "$dirname" != ".password-store" ]]; then
        chmod 755 "$dir" 2>/dev/null || true
        # 创建并设置 docs 和 tests 目录
        if [ -d "$dir" ]; then
            mkdir -p "$dir/docs/memory" "$dir/docs/plan" "$dir/tests/cases" 2>/dev/null || true
            chmod -R 777 "$dir/docs" 2>/dev/null || true
            chmod -R 777 "$dir/tests" 2>/dev/null || true
        fi
    fi
done

# 修复根目录的 docs 和 tests
mkdir -p /root/docs/memory /root/docs/plan /root/tests/cases 2>/dev/null || true
chmod -R 777 /root/docs 2>/dev/null || true
chmod -R 777 /root/tests 2>/dev/null || true

# 确保配置目录可访问
chmod -R 755 /root/.claude 2>/dev/null || true
chmod -R 755 /root/.codemap 2>/dev/null || true
chmod -R 755 /root/.config 2>/dev/null || true

# 保护敏感目录和文件
chmod 700 /root/.ssh 2>/dev/null || true
chmod 600 /root/.ssh/* 2>/dev/null || true
chmod 700 /root/.gnupg 2>/dev/null || true
chmod 600 /root/.claude/.credentials.json 2>/dev/null || true
chmod 600 /root/.claude/history.jsonl 2>/dev/null || true
chmod 700 /root/.claude/projects 2>/dev/null || true

echo "   ✓ 权限已修复"

# 14. 安装管理脚本
echo "14. 安装管理脚本..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ln -sf "$SCRIPT_DIR/claude-dev" /usr/local/bin/claude-dev
ln -sf "$SCRIPT_DIR/claude-diagnose" /usr/local/bin/claude-diagnose
ln -sf "$SCRIPT_DIR/sync-dev-config" /usr/local/bin/sync-dev-config
chmod +x "$SCRIPT_DIR"/{claude-dev,claude-diagnose,sync-dev-config}
echo "   ✓ 管理脚本已安装"

echo ""
echo "=========================================="
echo "  ✓ 安装完成！"
echo "=========================================="
echo ""
echo "可用命令："
echo "  claude-dev        - 启动 Claude Code"
echo "  claude-diagnose   - 诊断环境"
echo "  sync-dev-config   - 同步配置"
echo ""
echo "测试环境："
echo "  claude-diagnose"
echo ""
echo "启动 Claude Code："
echo "  claude-dev"
echo ""
