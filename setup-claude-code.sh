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

TOTAL_STEPS=6

info()    { echo -e "${BLUE}[信息]${NC} $1"; }
success() { echo -e "${GREEN}  ✓ $1${NC}"; }
warn()    { echo -e "${YELLOW}[注意]${NC} $1"; }
error()   { echo -e "${RED}[错误]${NC} $1"; }

step() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  第 $1 步（共 ${TOTAL_STEPS} 步）：$2${NC}"
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

# --- 安全写入 shell 配置：只在不存在时追加，不删除任何已有内容 ---
ensure_line() {
    # $1 = 要检查的关键词, $2 = 要写入的完整行
    if ! grep -qF "$1" "$SHELL_RC" 2>/dev/null; then
        echo "$2" >> "$SHELL_RC"
    fi
}

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
echo "  整个过程大约需要 5 分钟，请跟着提示操作。"
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
step "2" "创建工作目录"
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
step "3" "安装 Claude Code"
# ============================================================================

# 确保 PATH 包含常见安装位置
export PATH="$HOME/.local/bin:$HOME/.claude/local/bin:$PATH"

if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "未知版本")
    success "Claude Code 已安装: $CLAUDE_VERSION，自动跳过"
else
    echo "  即将为你安装 Claude Code，这是整个脚本最关键的一步。"
    echo "  安装过程大约需要 1-2 分钟。"
    echo ""

    info "正在安装 Claude Code，请耐心等待..."
    echo ""
    curl -fsSL https://claude.ai/install.sh | bash
    echo ""

    # 重新检测 PATH（安装器可能把二进制放到不同位置）
    export PATH="$HOME/.local/bin:$HOME/.claude/local/bin:$PATH"
    if command -v claude &> /dev/null; then
        success "Claude Code 安装成功: $(claude --version 2>/dev/null)"
    else
        error "安装似乎未成功，请检查上方的错误信息"
        exit 1
    fi
fi

# 确保 PATH 持久化到 shell 配置
ensure_line '.local/bin' 'export PATH="$HOME/.local/bin:$PATH"'

pause

# ============================================================================
step "4" "配置 API Key"
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

    # 安全写入：用 grep 逐行检查，不用 sed 删除
    # 如果已有旧的 KEY 行，用 sed 原地替换（只替换那一行）
    if grep -q "ANTHROPIC_API_KEY" "$SHELL_RC" 2>/dev/null; then
        # 备份
        cp "$SHELL_RC" "${SHELL_RC}.bak.$(date +%Y%m%d%H%M%S)"
        # 只替换包含 ANTHROPIC_API_KEY 的那一行
        sed -i '' "s|export ANTHROPIC_API_KEY=.*|export ANTHROPIC_API_KEY=\"$API_KEY\"|" "$SHELL_RC"
        success "API Key 已更新"
    else
        # 首次写入
        cat >> "$SHELL_RC" << EOF

# Claude Code API Configuration
export ANTHROPIC_API_KEY="$API_KEY"
export ANTHROPIC_BASE_URL="$RELAY_URL"
EOF
        success "API Key 已保存"
    fi

    export ANTHROPIC_API_KEY="$API_KEY"
    export ANTHROPIC_BASE_URL="$RELAY_URL"
else
    export ANTHROPIC_API_KEY="$EXISTING_KEY"
    export ANTHROPIC_BASE_URL="$RELAY_URL"
fi

# 确保 BASE_URL 也在配置中（可能之前只写了 KEY 没写 URL）
ensure_line 'ANTHROPIC_BASE_URL' "export ANTHROPIC_BASE_URL=\"$RELAY_URL\""

# 添加快捷命令 cc
if ! grep -q "alias cc=" "$SHELL_RC" 2>/dev/null; then
    cat >> "$SHELL_RC" << EOF

# 快捷命令：输入 cc 即可进入工作目录并启动 Claude Code
alias cc='cd $WORKSPACE && claude'
EOF
    success "已添加快捷命令：输入 cc 即可启动 Claude Code"
else
    success "快捷命令 cc 已存在"
fi

pause

# ============================================================================
step "5" "自动配置（系统设置 + 联网搜索）"
# ============================================================================

echo "  正在自动完成以下配置，不需要你操作："
echo "    1. 调整系统设置（让公司 API 正常工作）"
echo "    2. 开启联网搜索（让 Claude Code 能搜索网页信息）"
echo ""

# --- 5a: settings.json ---
SETTINGS_DIR="$HOME/.claude"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

if [[ -f "$SETTINGS_FILE" ]] && grep -q "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" "$SETTINGS_FILE" 2>/dev/null; then
    success "系统设置：已配置"
else
    if [[ -f "$SETTINGS_FILE" ]]; then
        python3 -c "
import json
f = '$SETTINGS_FILE'
with open(f) as fh: cfg = json.load(fh)
cfg.setdefault('env', {})['CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS'] = '1'
with open(f, 'w') as fh: json.dump(cfg, fh, indent=2); fh.write('\n')
" 2>/dev/null || {
            cat > "$SETTINGS_FILE" << 'SETTINGSEOF'
{
  "env": {
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
SETTINGSEOF
        }
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

# --- 5b: Exa 搜索 ---
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
step "6" "飞书集成（可选）"
# ============================================================================

echo "  安装飞书 CLI 后，Claude Code 可以帮你："
echo "  查日历、发消息、读文档、操作表格等。"
echo ""
echo "  这一步是可选的，以后随时可以让 Claude Code 帮你安装。"
echo ""

if ! command -v node &> /dev/null; then
    info "飞书集成需要 Node.js，当前未安装，先跳过"
    echo "  以后想装的话，在 Claude Code 里说："
    echo "  「帮我安装 Node.js 和飞书 CLI，参考 https://github.com/larksuite/cli/blob/main/README.zh.md」"
else
    ask "  现在安装吗？(y/n) [直接回车跳过]: " setup_lark
    setup_lark="${setup_lark:-n}"

    if [[ "$setup_lark" == "y" || "$setup_lark" == "Y" ]]; then
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
            error "安装失败，请稍后在 Claude Code 中让它帮你安装"
        fi
    else
        info "跳过飞书集成"
        echo "  以后想装的话，在 Claude Code 里说："
        echo "  「帮我安装飞书 CLI，参考 https://github.com/larksuite/cli/blob/main/README.zh.md」"
    fi
fi

# ============================================================================
# 最终验证
# ============================================================================
echo ""
echo ""

# 验证 claude 命令可用
if command -v claude &> /dev/null; then
    echo -e "${BOLD}${GREEN}  ╔══════════════════════════════════════════════╗"
    echo "  ║                                              ║"
    echo "  ║           全部完成！可以开始使用了             ║"
    echo "  ║                                              ║"
    echo -e "  ╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  接下来：关闭这个终端窗口，重新打开一个，然后输入："
    echo ""
    echo -e "    ${BOLD}${CYAN}cc${NC}"
    echo ""
    echo "  就会自动进入工作目录并启动 Claude Code。"
    echo ""
    echo "  首次启动时："
    echo "    1. 选择「Use an API key」"
    echo "    2. 粘贴你的 API Key"
    echo "    3. 开始对话！"
    echo ""
    echo -e "  ${DIM}提示：Ctrl+C 可以打断 Claude，Ctrl+D 退出${NC}"
else
    echo -e "${BOLD}${YELLOW}  ╔══════════════════════════════════════════════╗"
    echo "  ║                                              ║"
    echo "  ║           配置已完成，但需要注意              ║"
    echo "  ║                                              ║"
    echo -e "  ╚══════════════════════════════════════════════╝${NC}"
    echo ""
    warn "claude 命令当前不可用（可能是 PATH 未生效）"
    echo ""
    echo "  请关闭终端，重新打开一个新终端，然后输入："
    echo ""
    echo -e "    ${BOLD}${CYAN}cc${NC}"
    echo ""
    echo "  如果仍然提示 command not found，请在新终端中执行："
    echo "    source $SHELL_RC"
    echo "    claude --version"
fi
echo ""
