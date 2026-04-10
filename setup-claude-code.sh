#!/bin/bash
# ============================================================================
# Claude Code 一键安装配置脚本
# 适用于 macOS (zsh)
# BV 品牌团队内部使用
# ============================================================================

set -e

# --- 颜色和格式 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "${BLUE}[信息]${NC} $1"; }
success() { echo -e "${GREEN}  ✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}[注意]${NC} $1"; }
error()   { echo -e "${RED}[错误]${NC} $1"; }

step() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  第 $1 步（共 7 步）：$2${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# --- 兼容 curl | bash 模式：所有用户输入从终端读取 ---
if [[ -t 0 ]]; then
    ask()   { read -p "$1" "$2"; }
    pause() { echo ""; read -p "$(echo -e "${DIM}  按回车继续下一步...${NC}")" _p; }
else
    ask()   { printf '%s' "$1" > /dev/tty; read "$2" < /dev/tty; }
    pause() { printf '\n  \033[2m按回车继续下一步...\033[0m' > /dev/tty; read _p < /dev/tty; }
fi

# --- 公司 API 中转地址（所有人通用） ---
RELAY_URL="https://bmc-llm-relay.bluemediagroup.cn"

# --- 检测 shell 配置文件 ---
if [[ "$SHELL" == *"zsh"* ]] || [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
else
    SHELL_RC="$HOME/.bashrc"
fi

# ============================================================================
clear 2>/dev/null || true
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║     Claude Code 一键安装配置                 ║"
echo "  ║     BV 品牌团队                              ║"
echo "  ║                                              ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  这个脚本会一步一步帮你完成 Claude Code 的安装和配置。"
echo "  整个过程大约需要 5-10 分钟，请跟着提示操作。"
echo ""
echo -e "  ${DIM}已经安装过？没关系，脚本会自动跳过已完成的步骤。${NC}"
echo ""
ask "  准备好了吗？按回车开始 → " _dummy

# ============================================================================
step "1" "检查网络（科学上网 / VPN）"
# ============================================================================

echo "  Claude Code 需要科学上网才能使用。"
echo "  请确认你的 VPN 已开启，并且开启了以下模式之一："
echo ""
echo "    Clash / ClashX  →  增强模式 或 TUN 模式"
echo "    V2Ray / V2RayN  →  虚拟网卡 或 系统代理"
echo "    Surge           →  增强模式"
echo ""
echo -e "  ${YELLOW}重要：普通的「系统代理」只对浏览器生效，终端不走代理！${NC}"
echo ""
ask "  确认 VPN 已开启？按回车检测网络 → " _dummy

info "正在测试网络连通性..."
if curl -s --connect-timeout 10 --max-time 15 "https://claude.ai" > /dev/null 2>&1; then
    success "网络连通正常，可以继续"
else
    echo ""
    error "无法连接到 claude.ai"
    echo ""
    echo "  请检查："
    echo "    1. VPN 是否已开启"
    echo "    2. 是否开启了增强模式 / TUN 模式"
    echo "    3. 尝试关闭终端重新打开"
    echo ""
    echo "  如果不确定，可以尝试在终端执行："
    echo "    export https_proxy=http://127.0.0.1:7890"
    echo "    export http_proxy=http://127.0.0.1:7890"
    echo ""
    ask "  修复后按回车重试，或输入 skip 跳过: " choice
    if [[ "$choice" != "skip" ]]; then
        info "重新检测..."
        if ! curl -s --connect-timeout 10 --max-time 15 "https://claude.ai" > /dev/null 2>&1; then
            error "仍然无法连接。请检查 VPN 后重新运行此脚本。"
            exit 1
        fi
        success "网络连通正常"
    else
        warn "跳过网络检查，后续步骤可能失败"
    fi
fi

pause

# ============================================================================
step "2" "检查 Node.js"
# ============================================================================

echo "  Node.js 是一些扩展工具（飞书集成等）需要的运行环境。"
echo "  即使没有也不影响 Claude Code 核心功能。"
echo ""

if command -v node &> /dev/null; then
    success "Node.js 已安装: $(node --version)"
else
    warn "未检测到 Node.js"
    echo ""

    if command -v brew &> /dev/null; then
        ask "  是否通过 Homebrew 安装？(y/n): " install_node
        if [[ "$install_node" == "y" || "$install_node" == "Y" ]]; then
            info "正在安装 Node.js（可能需要几分钟）..."
            brew install node
            success "Node.js 安装完成: $(node --version)"
        else
            info "跳过，后续可以再安装"
        fi
    else
        echo "  请手动安装 Node.js："
        echo "    方式 1: 先装 Homebrew，再 brew install node"
        echo "    方式 2: 去 https://nodejs.org/zh-cn 下载 LTS 版本"
        echo ""
        ask "  安装好后按回车继续，或输入 skip 跳过: " choice
        if [[ "$choice" != "skip" ]] && ! command -v node &> /dev/null; then
            warn "未检测到 Node.js，部分扩展功能暂时无法使用"
        fi
    fi
fi

pause

# ============================================================================
step "3" "创建工作目录"
# ============================================================================

DEFAULT_WORKSPACE="$HOME/claudeworkspace"
echo "  Claude Code 需要一个本地文件夹作为工作空间。"
echo "  你可以把需要处理的文件放到这个目录下。"
echo ""
ask "  文件夹路径 [直接回车使用默认: $DEFAULT_WORKSPACE]: " WORKSPACE
WORKSPACE="${WORKSPACE:-$DEFAULT_WORKSPACE}"

if [[ -d "$WORKSPACE" ]]; then
    success "目录已存在: $WORKSPACE"
else
    mkdir -p "$WORKSPACE"
    success "已创建目录: $WORKSPACE"
fi

pause

# ============================================================================
step "4" "安装 Claude Code"
# ============================================================================

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "未知版本")
    success "Claude Code 已安装: $CLAUDE_VERSION"
    echo ""
    ask "  是否重新安装/更新？(y/n) [直接回车跳过]: " reinstall
    reinstall="${reinstall:-n}"
else
    echo "  即将为你安装 Claude Code，这是整个脚本最关键的一步。"
    echo "  安装过程大约需要 1-2 分钟。"
    echo ""
    reinstall="y"
fi

if [[ "$reinstall" == "y" || "$reinstall" == "Y" ]]; then
    info "正在安装 Claude Code，请耐心等待..."
    echo ""
    curl -fsSL https://claude.ai/install.sh | bash
    echo ""

    # 验证安装
    export PATH="$HOME/.local/bin:$PATH"
    if command -v claude &> /dev/null; then
        success "Claude Code 安装成功: $(claude --version 2>/dev/null)"
    else
        error "安装似乎未成功，请检查上方的错误信息"
        echo "  也可以尝试: npm install -g @anthropic-ai/claude-code"
        exit 1
    fi
fi

pause

# ============================================================================
step "5" "配置 API Key"
# ============================================================================

echo "  Claude Code 通过公司的 API 中转服务使用。"
echo "  你需要一个个人 API Key 才能使用。"
echo ""
echo -e "  ${CYAN}还没有 Key？去这里申请：${NC}"
echo "  https://bluefocus.feishu.cn/docx/A8ozdc5HdoGgooxhTugcp7bHnae"
echo ""

# 检查是否已配置
EXISTING_KEY=""
if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
    EXISTING_KEY=$(grep "ANTHROPIC_API_KEY" "$SHELL_RC" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
fi

if [[ -n "$EXISTING_KEY" ]]; then
    MASKED="${EXISTING_KEY:0:8}...${EXISTING_KEY: -4}"
    success "检测到已有 API Key: $MASKED"
    echo ""
    ask "  是否更换？(y/n) [直接回车保留现有]: " reconfig
    reconfig="${reconfig:-n}"
fi

if [[ -z "$EXISTING_KEY" || "$reconfig" == "y" || "$reconfig" == "Y" ]]; then
    echo ""
    echo -e "  ${BOLD}请粘贴你的 API Key（以 sk- 开头）：${NC}"
    echo ""
    while true; do
        ask "  API Key: " API_KEY
        if [[ "$API_KEY" == sk-* ]] && [[ ${#API_KEY} -gt 10 ]]; then
            break
        else
            echo ""
            error "格式不对，API Key 应该以 sk- 开头，请重新粘贴"
            echo ""
        fi
    done

    # 备份并写入
    if [[ -f "$SHELL_RC" ]]; then
        cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%Y%m%d%H%M%S)"
        sed -i '' '/# Claude Code API Configuration/,/^$/d' "$SHELL_RC" 2>/dev/null || true
    fi

    cat >> "$SHELL_RC" << EOF

# Claude Code API Configuration
export ANTHROPIC_API_KEY="$API_KEY"
export ANTHROPIC_BASE_URL="$RELAY_URL"
EOF

    export ANTHROPIC_API_KEY="$API_KEY"
    export ANTHROPIC_BASE_URL="$RELAY_URL"

    success "API Key 已保存"
else
    export ANTHROPIC_API_KEY="$EXISTING_KEY"
    export ANTHROPIC_BASE_URL="$RELAY_URL"
fi

pause

# ============================================================================
step "6" "配置系统设置 + 联网搜索"
# ============================================================================

echo "  正在自动完成两项配置，不需要你操作："
echo "    1. 禁用不兼容的实验功能（公司 API 需要）"
echo "    2. 配置 Exa 搜索（让 Claude Code 能联网搜索）"
echo ""

# --- 6a: settings.json ---
SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

if [[ -f "$SETTINGS_FILE" ]] && grep -q "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" "$SETTINGS_FILE" 2>/dev/null; then
    success "系统设置：已配置"
else
    if [[ -f "$SETTINGS_FILE" ]] && command -v node &> /dev/null; then
        node -e "
const fs = require('fs');
const f = '$SETTINGS_FILE';
const cfg = JSON.parse(fs.readFileSync(f, 'utf8'));
if (!cfg.env) cfg.env = {};
cfg.env.CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = '1';
fs.writeFileSync(f, JSON.stringify(cfg, null, 2) + '\n');
"
    else
        cat > "$SETTINGS_FILE" << 'SETTINGSEOF'
{
  "env": {
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
SETTINGSEOF
    fi
    success "系统设置：已配置"
fi

# --- 6b: Exa 搜索 ---
if command -v claude &> /dev/null; then
    if grep -q '"exa"' "$HOME/.claude.json" 2>/dev/null; then
        success "联网搜索：已配置（Exa）"
    else
        claude mcp add --transport http exa -s user "https://mcp.exa.ai/mcp?exaApiKey=ff847a3e-e7bb-46b3-b763-23f3120bc6e2" 2>/dev/null && \
            success "联网搜索：已配置（Exa）" || \
            warn "联网搜索配置未成功，稍后可在 Claude Code 中让它帮你配"
    fi
else
    warn "Claude Code 未就绪，搜索配置已跳过"
fi

echo ""
info "搜索使用团队共享额度。如果提示额度不足："
echo "  去 https://dashboard.exa.ai/api-keys 注册个人 Key"
echo "  然后在 Claude Code 里说「帮我更换 Exa 的 API Key」"

pause

# ============================================================================
step "7" "飞书集成（可选）"
# ============================================================================

echo "  安装飞书 CLI 后，Claude Code 可以帮你："
echo "  查日历、发消息、读文档、操作表格等。"
echo ""
echo "  这一步是可选的，以后也可以随时安装。"
echo ""

ask "  现在安装吗？(y/n) [直接回车跳过]: " setup_lark
setup_lark="${setup_lark:-n}"

if [[ "$setup_lark" == "y" || "$setup_lark" == "Y" ]]; then
    if ! command -v npm &> /dev/null; then
        error "需要先安装 Node.js 才能装飞书 CLI"
    else
        info "正在安装（可能需要几分钟）..."
        npm install -g @larksuite/cli

        info "正在安装飞书技能包..."
        npx skills add larksuite/cli -y -g 2>/dev/null || warn "技能包可能需要稍后重试"

        if command -v lark-cli &> /dev/null; then
            success "Lark CLI 安装完成"
            echo ""
            echo "  还需要手动完成登录（安装完脚本后执行）："
            echo ""
            echo "    1. lark-cli config init      （选择 feishu，按提示操作）"
            echo "    2. lark-cli auth login --recommend （浏览器登录授权）"
            echo "    3. lark-cli auth status       （验证是否成功）"
            echo ""
            echo "  详细文档: https://github.com/larksuite/cli/blob/main/README.zh.md"
        else
            error "安装失败，请稍后重试或在 Claude Code 中让它帮你安装"
        fi
    fi
else
    info "跳过飞书集成"
    echo "  以后想装的话，在 Claude Code 里说："
    echo "  「帮我安装飞书 CLI，参考 https://github.com/larksuite/cli/blob/main/README.zh.md」"
fi

# ============================================================================
echo ""
echo ""
echo -e "${BOLD}${GREEN}  ╔══════════════════════════════════════════════╗"
echo "  ║                                              ║"
echo "  ║           全部完成！可以开始使用了             ║"
echo "  ║                                              ║"
echo -e "  ╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "  接下来：关闭这个终端窗口，重新打开一个，然后执行："
echo ""
echo -e "    ${BOLD}${CYAN}cd $WORKSPACE${NC}"
echo -e "    ${BOLD}${CYAN}claude${NC}"
echo ""
echo "  首次启动时："
echo "    1. 选择「Use an API key」"
echo "    2. 粘贴你的 API Key"
echo "    3. 开始对话！"
echo ""
echo -e "  ${DIM}提示：Ctrl+C 可以打断 Claude，Ctrl+D 退出${NC}"
echo ""
