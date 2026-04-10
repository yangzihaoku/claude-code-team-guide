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
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[信息]${NC} $1"; }
success() { echo -e "${GREEN}[完成]${NC} $1"; }
warn()    { echo -e "${YELLOW}[注意]${NC} $1"; }
error()   { echo -e "${RED}[错误]${NC} $1"; }
step()    { echo -e "\n${BOLD}${CYAN}━━━ 第 $1 步：$2 ━━━${NC}\n"; }

# --- 公司 API 中转地址（所有人通用） ---
RELAY_URL="https://bmc-llm-relay.bluemediagroup.cn"

# --- 兼容 curl | bash 模式：所有用户输入从终端读取 ---
exec 3</dev/tty 2>/dev/null || exec 3<&0
ask() { read -p "$1" "$2" <&3; }

# --- 检测 shell 配置文件 ---
if [[ "$SHELL" == *"zsh"* ]] || [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
    SHELL_NAME="zsh"
else
    SHELL_RC="$HOME/.bashrc"
    SHELL_NAME="bash"
fi

# ============================================================================
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║     Claude Code 一键安装配置脚本             ║"
echo "  ║     BV 品牌团队                             ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
step "0" "检查科学上网 / VPN"
# ============================================================================

echo -e "${YELLOW}${BOLD}重要提醒：${NC}"
echo "  Claude Code 需要科学上网才能正常使用。"
echo "  请确保你的 VPN 工具已开启，并且开启了以下任一模式："
echo ""
echo "  Clash:   增强模式 或 TUN 模式"
echo "  V2Ray:   虚拟网卡 或 系统代理"
echo "  其他:    确保终端（Terminal）的流量也走代理"
echo ""
echo -e "  ${YELLOW}原因：普通的「系统代理」只对浏览器生效，终端不走代理。${NC}"
echo ""
ask "已确认 VPN 已正确配置？(回车继续) " _dummy

# 测试连通性
info "正在测试网络连通性..."
if curl -s --connect-timeout 10 --max-time 15 "https://claude.ai" > /dev/null 2>&1; then
    success "网络连通正常"
else
    error "无法连接到 claude.ai"
    echo ""
    echo "  可能的原因："
    echo "  1. VPN 工具未开启"
    echo "  2. VPN 未开启增强模式/TUN 模式"
    echo "  3. 终端需要重启以应用代理设置"
    echo ""
    echo "  解决方法："
    echo "  - 开启 Clash 的增强模式（Enhance Mode）或 TUN 模式"
    echo "  - 或者在终端手动设置代理："
    echo "    export https_proxy=http://127.0.0.1:7890"
    echo "    export http_proxy=http://127.0.0.1:7890"
    echo ""
    ask "修复后按回车重试，或输入 skip 跳过检查: " choice
    if [[ "$choice" != "skip" ]]; then
        if ! curl -s --connect-timeout 10 --max-time 15 "https://claude.ai" > /dev/null 2>&1; then
            error "仍然无法连接。请检查 VPN 配置后重新运行此脚本。"
            exit 1
        fi
        success "网络连通正常"
    else
        warn "已跳过网络检查，后续步骤可能会失败"
    fi
fi

# ============================================================================
step "1" "检查 Node.js 环境"
# ============================================================================

# Node.js 是 MCP 工具（Brave Search、Lark CLI 等）所需的
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    success "Node.js 已安装: $NODE_VERSION"
else
    warn "未检测到 Node.js（MCP 工具需要 Node.js）"
    echo ""

    if command -v brew &> /dev/null; then
        ask "是否通过 Homebrew 安装 Node.js？(y/n) " install_node
        if [[ "$install_node" == "y" || "$install_node" == "Y" ]]; then
            info "正在安装 Node.js..."
            brew install node
            success "Node.js 安装完成: $(node --version)"
        fi
    else
        echo "  请先安装 Node.js，推荐方式："
        echo ""
        echo "  方式 1 - 先安装 Homebrew，再装 Node.js："
        echo "    /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "    brew install node"
        echo ""
        echo "  方式 2 - 直接下载安装："
        echo "    https://nodejs.org/zh-cn （选择 LTS 版本）"
        echo ""
        ask "安装好 Node.js 后按回车继续，或输入 skip 跳过: " choice
        if [[ "$choice" != "skip" ]]; then
            if ! command -v node &> /dev/null; then
                error "仍未检测到 Node.js，MCP 工具将无法使用。"
                warn "继续安装 Claude Code（核心功能不受影响）..."
            fi
        fi
    fi
fi

# ============================================================================
step "2" "创建工作目录"
# ============================================================================

DEFAULT_WORKSPACE="$HOME/claudeworkspace"
echo "  Claude Code 需要一个本地目录作为工作空间。"
echo "  建议使用一个专门的目录，而不是在桌面或根目录使用。"
echo ""
ask "工作目录路径 [默认: $DEFAULT_WORKSPACE]: " WORKSPACE
WORKSPACE="${WORKSPACE:-$DEFAULT_WORKSPACE}"

if [[ -d "$WORKSPACE" ]]; then
    success "目录已存在: $WORKSPACE"
else
    mkdir -p "$WORKSPACE"
    success "已创建目录: $WORKSPACE"
fi

# ============================================================================
step "3" "安装 Claude Code"
# ============================================================================

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "未知版本")
    success "Claude Code 已安装: $CLAUDE_VERSION"
    ask "是否重新安装/更新？(y/n) [n]: " reinstall
    reinstall="${reinstall:-n}"
else
    reinstall="y"
fi

if [[ "$reinstall" == "y" || "$reinstall" == "Y" ]]; then
    info "正在安装 Claude Code..."
    echo "  （安装过程可能需要 1-2 分钟，请耐心等待）"
    echo ""
    curl -fsSL https://claude.ai/install.sh | bash
    echo ""

    # 验证安装
    if command -v claude &> /dev/null; then
        success "Claude Code 安装成功: $(claude --version 2>/dev/null)"
    else
        # 可能需要重新加载 PATH
        export PATH="$HOME/.local/bin:$PATH"
        if command -v claude &> /dev/null; then
            success "Claude Code 安装成功: $(claude --version 2>/dev/null)"
        else
            error "安装似乎未成功，请检查上方的错误信息"
            echo "  也可以尝试手动安装: npm install -g @anthropic-ai/claude-code"
            exit 1
        fi
    fi
fi

# ============================================================================
step "4" "配置 API"
# ============================================================================

echo "  Claude Code 通过公司的 API 中转服务使用。"
echo "  你需要提供你的个人 API Key。"
echo ""
echo -e "  ${CYAN}如果还没有 API Key，请先到飞书文档申请：${NC}"
echo "  https://bluefocus.feishu.cn/docx/A8ozdc5HdoGgooxhTugcp7bHnae"
echo ""

# 检查是否已配置
EXISTING_KEY=""
if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
    EXISTING_KEY=$(grep "ANTHROPIC_API_KEY" "$SHELL_RC" | grep -o '"[^"]*"' | tail -1 | tr -d '"')
    if [[ -n "$EXISTING_KEY" ]]; then
        MASKED_KEY="${EXISTING_KEY:0:8}...${EXISTING_KEY: -4}"
        warn "检测到已有配置: $MASKED_KEY"
        ask "是否重新配置？(y/n) [n]: " reconfig
        reconfig="${reconfig:-n}"
    fi
fi

if [[ -z "$EXISTING_KEY" || "$reconfig" == "y" || "$reconfig" == "Y" ]]; then
    while true; do
        echo ""
        ask "请粘贴你的 API Key (以 sk- 开头): " API_KEY
        if [[ "$API_KEY" == sk-* ]] && [[ ${#API_KEY} -gt 10 ]]; then
            break
        else
            error "API Key 格式不正确，应该以 sk- 开头。请重新输入。"
        fi
    done

    # 写入 shell 配置
    # 先移除旧配置（如果有）
    if [[ -f "$SHELL_RC" ]]; then
        # 创建备份
        cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%Y%m%d%H%M%S)"
        # 移除旧的 Claude API 配置块
        sed -i '' '/# Claude Code API Configuration/,/^$/d' "$SHELL_RC" 2>/dev/null || true
    fi

    # 添加新配置
    cat >> "$SHELL_RC" << EOF

# Claude Code API Configuration
export ANTHROPIC_API_KEY="$API_KEY"
export ANTHROPIC_BASE_URL="$RELAY_URL"
EOF

    # 立即生效
    export ANTHROPIC_API_KEY="$API_KEY"
    export ANTHROPIC_BASE_URL="$RELAY_URL"

    success "API 配置已写入 $SHELL_RC"
else
    info "保留现有 API 配置"
    # 确保当前 session 也有这些变量
    export ANTHROPIC_API_KEY="$EXISTING_KEY"
    export ANTHROPIC_BASE_URL="$RELAY_URL"
fi

# ============================================================================
step "5" "配置 Claude Code 设置"
# ============================================================================

info "正在配置 Claude Code 核心设置..."

SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

# 关键设置：禁用实验性 beta headers
# 公司 API 中转不支持这些 headers，不禁用会导致请求失败
if [[ -f "$SETTINGS_FILE" ]]; then
    # 检查是否已有此设置
    if grep -q "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" "$SETTINGS_FILE" 2>/dev/null; then
        success "核心设置已存在，跳过"
    else
        # 已有设置文件，需要合并 env 配置
        # 使用 python 或 node 来安全处理 JSON
        if command -v node &> /dev/null; then
            node -e "
const fs = require('fs');
const f = '$SETTINGS_FILE';
const cfg = JSON.parse(fs.readFileSync(f, 'utf8'));
if (!cfg.env) cfg.env = {};
cfg.env.CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = '1';
fs.writeFileSync(f, JSON.stringify(cfg, null, 2) + '\n');
"
            success "已更新 settings.json（添加了 DISABLE_EXPERIMENTAL_BETAS）"
        else
            warn "无法自动更新 settings.json（需要 Node.js）"
            echo "  请手动编辑 $SETTINGS_FILE，在 env 中添加："
            echo '  "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"'
        fi
    fi
else
    # 创建新的设置文件
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "env": {
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
EOF
    success "已创建 settings.json"
fi

echo ""
info "为什么需要这个设置？"
echo "  公司的 API 中转服务不支持 Anthropic 的实验性功能请求头。"
echo "  不禁用的话，Claude Code 的部分请求会返回错误。"

# ============================================================================
step "6" "配置联网搜索"
# ============================================================================

echo "  Claude Code 默认不能联网搜索（公司 API 不支持内置搜索功能）。"
echo "  现在为你配置 DuckDuckGo 搜索（免费、无需注册）。"
echo ""

if command -v npx &> /dev/null; then
    if command -v claude &> /dev/null; then
        # 检查是否已配置
        if grep -q "ddg-search" "$HOME/.claude.json" 2>/dev/null; then
            success "DuckDuckGo 搜索已配置，跳过"
        else
            info "正在配置 DuckDuckGo 搜索..."
            claude mcp add ddg-search -s user -- npx -y duckduckgo-mcp-server 2>/dev/null && \
                success "DuckDuckGo 搜索配置完成（免费、无限次数）" || \
                warn "自动配置未成功，你可以稍后在 Claude Code 中让它帮你配置"
        fi
    else
        warn "Claude Code 未就绪，跳过搜索配置"
        echo "  稍后在 Claude Code 中输入以下内容让它帮你配置："
        echo "  「帮我配置 DuckDuckGo 搜索 MCP」"
    fi

    echo ""
    echo -e "  ${CYAN}想要更好的搜索质量？可以额外注册以下服务（都有免费额度）：${NC}"
    echo "  - Brave Search: https://brave.com/search/api/   （1000 次/月）"
    echo "  - Tavily:       https://tavily.com/              （1000 次/月，注册不需要信用卡）"
    echo "  - Exa:          https://exa.ai/                  （1000 次/月，语义搜索最强）"
    echo "  注册拿到 Key 后，直接在 Claude Code 里说「帮我配置 xxx 搜索」就行。"
else
    warn "Node.js 未安装，跳过搜索配置"
    echo "  安装 Node.js 后，在 Claude Code 中让它帮你配置搜索功能。"
fi

# ============================================================================
step "7" "安装 Lark CLI（飞书集成）[可选]"
# ============================================================================

echo "  安装 Lark CLI 后，Claude Code 可以直接操作飞书："
echo "  查日历、发消息、读文档、操作表格等。"
echo ""

ask "是否现在安装 Lark CLI？(y/n) [跳过按回车]: " setup_lark
setup_lark="${setup_lark:-n}"

if [[ "$setup_lark" == "y" || "$setup_lark" == "Y" ]]; then
    if ! command -v npm &> /dev/null; then
        error "需要 Node.js/npm 才能安装 Lark CLI"
    else
        info "正在安装 Lark CLI..."
        npm install -g @larksuite/cli

        info "正在安装飞书技能包到 Claude Code..."
        npx skills add larksuite/cli -y -g 2>/dev/null || warn "技能包安装可能需要稍后重试"

        if command -v lark-cli &> /dev/null || npx @larksuite/cli --version &> /dev/null; then
            success "Lark CLI 安装完成"
            echo ""
            echo "  接下来需要初始化和登录（交互式操作）："
            echo ""
            echo "  1. 初始化应用配置："
            echo "     lark-cli config init"
            echo "     （选择 feishu，按提示操作）"
            echo ""
            echo "  2. 登录授权："
            echo "     lark-cli auth login --recommend"
            echo "     （会输出授权链接，在浏览器中打开完成登录）"
            echo ""
            echo "  3. 验证登录："
            echo "     lark-cli auth status"
            echo ""
            echo "  详细文档: https://github.com/larksuite/cli/blob/main/README.zh.md"
            echo ""
            warn "这些步骤需要交互操作，请安装完成后手动执行。"
        else
            error "Lark CLI 安装失败，请检查网络或 npm 配置"
        fi
    fi
else
    info "跳过 Lark CLI，你可以之后再安装"
    echo "  安装命令: npm install -g @larksuite/cli"
fi

# ============================================================================
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║          安装配置完成！                       ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

echo "  现在你可以开始使用 Claude Code 了："
echo ""
echo -e "  ${CYAN}cd $WORKSPACE${NC}"
echo -e "  ${CYAN}claude${NC}"
echo ""
echo "  首次启动时："
echo "  - 会要求登录，选择「Use an API key」"
echo "  - 粘贴你的 API Key 即可"
echo "  - 如果提示选择模型，选 claude-sonnet-4-20250514 即可开始"
echo ""
echo "  几个有用的命令："
echo "  - /help        查看帮助"
echo "  - /status      查看当前配置状态"
echo "  - /model       切换模型"
echo "  - Ctrl+C       取消当前操作"
echo "  - Ctrl+D       退出 Claude Code"
echo ""

# 提醒新终端
warn "如果新开终端窗口，环境变量才会生效。"
echo "  或者在当前终端执行: source $SHELL_RC"
echo ""
