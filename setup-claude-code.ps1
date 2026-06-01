# ============================================================================
# Claude Code 一键安装配置脚本 (Windows PowerShell)
# 适用于 Windows 10 1809+ / Windows 11
# BV 品牌团队内部使用
# ============================================================================
# 使用方法：
#   以管理员或普通用户身份打开 PowerShell，运行：
#   irm https://raw.githubusercontent.com/yangzihaoku/claude-code-team-guide/main/setup-claude-code.ps1 | iex
# ============================================================================

$ErrorActionPreference = "Stop"

# --- 颜色输出 ---
function Info($msg)    { Write-Host "  [信息] $msg" -ForegroundColor Cyan }
function Success($msg) { Write-Host "    ✓ $msg" -ForegroundColor Green }
function Warn($msg)    { Write-Host "  [注意] $msg" -ForegroundColor Yellow }
function Err($msg)     { Write-Host "  [错误] $msg" -ForegroundColor Red }

function Step($num, $total, $title) {
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "    第 $num 步（共 $total 步）：$title" -ForegroundColor Cyan
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
}

function Pause-Step {
    Write-Host ""
    Read-Host "    按回车继续下一步"
}

$TOTAL_STEPS = 6
$RELAY_URL = "https://bmc-llm-relay.bluemediagroup.cn"

# --- 配置 / 更换 API Key（完整安装和「仅更换 Key」模式共用） ---
function Set-ApiKey {
    # 清理旧版变量名（早期脚本用的是 ANTHROPIC_API_KEY，现已改为 ANTHROPIC_AUTH_TOKEN）
    $legacyKey = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")
    if ($legacyKey) {
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
        Remove-Item Env:\ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
        Warn "检测到旧版 ANTHROPIC_API_KEY，已清除（新版改用 ANTHROPIC_AUTH_TOKEN）"
    }

    # 检查已有配置
    $existingKey = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "User")
    $reconfig = "n"

    if ($existingKey) {
        $masked = $existingKey.Substring(0, 8) + "..." + $existingKey.Substring($existingKey.Length - 4)
        Success "检测到已有 API Key: $masked"
        Write-Host ""
        $reconfig = Read-Host "  是否更换？(y/n) [直接回车保留现有]"
        if (-not $reconfig) { $reconfig = "n" }
    }

    if (-not $existingKey -or $reconfig -eq "y" -or $reconfig -eq "Y") {
        Write-Host ""
        Write-Host "  请粘贴你的 API Key（以 blueai- 开头）：" -ForegroundColor White
        Write-Host ""

        while ($true) {
            $apiKey = Read-Host "  API Key"
            if ($apiKey -match "^blueai-.{10,}") {
                break
            } else {
                Write-Host ""
                Err "格式不对，API Key 应该以 blueai- 开头，请重新粘贴"
                Write-Host ""
            }
        }

        # 写入用户级环境变量（永久生效，不需要管理员权限）
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $apiKey, "User")
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $RELAY_URL, "User")
        $env:ANTHROPIC_AUTH_TOKEN = $apiKey
        $env:ANTHROPIC_BASE_URL = $RELAY_URL
        Success "API Key 和中转地址已保存到用户环境变量"
    } else {
        $env:ANTHROPIC_AUTH_TOKEN = $existingKey
        $existingUrl = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
        if (-not $existingUrl) {
            [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $RELAY_URL, "User")
        }
        $env:ANTHROPIC_BASE_URL = $RELAY_URL
    }
}

# ============================================================================
Clear-Host
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║                                              ║" -ForegroundColor Cyan
Write-Host "  ║     Claude Code 一键安装配置 (Windows)       ║" -ForegroundColor Cyan
Write-Host "  ║     BV 品牌团队                              ║" -ForegroundColor Cyan
Write-Host "  ║                                              ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  这个脚本会一步一步帮你完成 Claude Code 的安装和配置。"
Write-Host "  整个过程大约需要 5-10 分钟，请跟着提示操作。"
Write-Host ""
Write-Host "  已经安装过？没关系，脚本会自动跳过已完成的步骤。" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  请选择要做什么："
Write-Host ""
Write-Host "    1) 完整安装 / 检查（首次使用，推荐）"
Write-Host "    2) 仅更换 API Key（已经装过，公司换了新 key）"
Write-Host ""
$mode = Read-Host "  输入 1 或 2 [直接回车 = 1]"
if (-not $mode) { $mode = "1" }

# --- 模式 2：仅更换 API Key，跳过其余所有步骤 ---
if ($mode -eq "2") {
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "    更换 API Key" -ForegroundColor Cyan
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  公司轮换了 API Key（新 key 以 blueai- 开头）。"
    Write-Host "  把新 key 粘进来即可，旧的会自动清理。"
    Write-Host ""
    Write-Host "  还没拿到新 Key？去这里申请：" -ForegroundColor Cyan
    Write-Host "  https://bluefocus.feishu.cn/docx/A8ozdc5HdoGgooxhTugcp7bHnae"
    Write-Host ""
    Set-ApiKey
    Write-Host ""
    Success "Key 已更换完成！"
    Write-Host ""
    Warn "请关闭当前 PowerShell 窗口、重新打开一个，新 key 才会生效。"
    Write-Host ""
    exit 0
}

Read-Host "  准备好了吗？按回车开始"

# ============================================================================
Step 1 $TOTAL_STEPS "检查网络（科学上网 / VPN）"
# ============================================================================

Write-Host "  Claude Code 需要科学上网才能使用。"
Write-Host "  请确认你的 VPN 已开启，并且开启了以下模式之一："
Write-Host ""
Write-Host "    Clash / ClashX  →  增强模式 或 TUN 模式"
Write-Host "    V2Ray / V2RayN  →  虚拟网卡 或 系统代理"
Write-Host "    Surge           →  增强模式"
Write-Host ""
Warn "重要：普通的「系统代理」可能对 PowerShell 无效！"
Write-Host ""
Read-Host "  确认 VPN 已开启？按回车检测网络"

Info "正在测试网络连通性..."
try {
    $response = Invoke-WebRequest -Uri "https://claude.ai" -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
    Success "网络连通正常，可以继续"
} catch {
    Write-Host ""
    Err "无法连接到 claude.ai"
    Write-Host ""
    Write-Host "  请检查："
    Write-Host "    1. VPN 是否已开启"
    Write-Host "    2. 是否开启了增强模式 / TUN 模式"
    Write-Host ""
    Write-Host "  如果你的 VPN 只支持系统代理，可以尝试手动设置 PowerShell 代理："
    Write-Host '    $env:HTTPS_PROXY = "http://127.0.0.1:7890"' -ForegroundColor Yellow
    Write-Host '    $env:HTTP_PROXY  = "http://127.0.0.1:7890"' -ForegroundColor Yellow
    Write-Host "  （端口号 7890 根据你的 VPN 实际情况调整）"
    Write-Host ""
    $choice = Read-Host "  修复后按回车重试，或输入 skip 跳过"
    if ($choice -ne "skip") {
        Info "重新检测..."
        try {
            Invoke-WebRequest -Uri "https://claude.ai" -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop | Out-Null
            Success "网络连通正常"
        } catch {
            Err "仍然无法连接。请检查 VPN 后重新运行此脚本。"
            exit 1
        }
    } else {
        Warn "跳过网络检查，后续步骤可能失败"
    }
}

Pause-Step

# ============================================================================
Step 2 $TOTAL_STEPS "检查 / 安装 Git for Windows"
# ============================================================================

Write-Host "  Claude Code 在 Windows 上运行需要 Git for Windows。"
Write-Host ""

$gitInstalled = $false
try {
    $gitVersion = & git --version 2>$null
    if ($gitVersion) {
        Success "Git 已安装: $gitVersion，自动跳过"
        $gitInstalled = $true
    }
} catch {}

if (-not $gitInstalled) {
    Write-Host "  未检测到 Git，尝试自动安装..."
    Write-Host ""

    $wingetAvailable = $false
    try {
        $wgVer = & winget --version 2>$null
        if ($wgVer) { $wingetAvailable = $true }
    } catch {}

    if ($wingetAvailable) {
        Info "通过 winget 安装 Git for Windows..."
        & winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        try {
            $gitVersion = & git --version 2>$null
            if ($gitVersion) {
                Success "Git 安装成功: $gitVersion"
                $gitInstalled = $true
            }
        } catch {}
    }

    if (-not $gitInstalled) {
        Write-Host ""
        Err "无法自动安装 Git"
        Write-Host ""
        Write-Host "  请手动安装 Git for Windows："
        Write-Host "  下载地址: https://git-scm.com/downloads/win" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  安装后重新运行此脚本。"
        exit 1
    }
}

Pause-Step

# ============================================================================
Step 3 $TOTAL_STEPS "安装 Claude Code"
# ============================================================================

# 确保常见安装路径在 PATH 中
$localBin = Join-Path $env:USERPROFILE ".local\bin"
if ($env:Path -notlike "*$localBin*") {
    $env:Path = "$localBin;$env:Path"
}

$claudeInstalled = $false
try {
    $claudeVersion = & claude --version 2>$null
    if ($claudeVersion) {
        Success "Claude Code 已安装: $claudeVersion，自动跳过"
        $claudeInstalled = $true
    }
} catch {}

if (-not $claudeInstalled) {
    Write-Host "  即将安装 Claude Code，这是整个脚本最关键的一步。"
    Write-Host "  安装过程大约需要 1-2 分钟。"
    Write-Host ""

    Info "正在安装 Claude Code..."
    Write-Host ""
    Invoke-RestMethod https://claude.ai/install.ps1 | Invoke-Expression
    Write-Host ""

    # 刷新 PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    $localBin = Join-Path $env:USERPROFILE ".local\bin"
    if ($env:Path -notlike "*$localBin*") {
        $env:Path = "$localBin;$env:Path"
    }

    try {
        $claudeVersion = & claude --version 2>$null
        if ($claudeVersion) {
            Success "Claude Code 安装成功: $claudeVersion"
        } else {
            throw "未找到 claude 命令"
        }
    } catch {
        Err "安装似乎未成功，请检查上方的错误信息"
        exit 1
    }
}

Pause-Step

# ============================================================================
Step 4 $TOTAL_STEPS "配置 API Key"
# ============================================================================

Write-Host "  Claude Code 通过公司的 API 中转服务使用。"
Write-Host "  你需要一个个人 API Key 才能使用。"
Write-Host ""
Write-Host "  还没有 Key？去这里申请：" -ForegroundColor Cyan
Write-Host "  https://bluefocus.feishu.cn/docx/A8ozdc5HdoGgooxhTugcp7bHnae"
Write-Host ""

Set-ApiKey

Pause-Step

# ============================================================================
Step 5 $TOTAL_STEPS "自动配置（系统设置 + 联网搜索）"
# ============================================================================

Write-Host "  正在自动完成以下配置，不需要你操作："
Write-Host "    1. 调整系统设置（让公司 API 正常工作）"
Write-Host "    2. 开启联网搜索（让 Claude Code 能搜索网页信息）"
Write-Host ""

# --- 5a: settings.json ---
$settingsDir = Join-Path $env:USERPROFILE ".claude"
$settingsFile = Join-Path $settingsDir "settings.json"

if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

if ((Test-Path $settingsFile) -and (Select-String -Path $settingsFile -Pattern "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" -Quiet)) {
    Success "系统设置：已配置"
} else {
    if (Test-Path $settingsFile) {
        try {
            $cfg = Get-Content $settingsFile -Raw | ConvertFrom-Json
            if (-not $cfg.env) {
                $cfg | Add-Member -NotePropertyName "env" -NotePropertyValue @{} -Force
            }
            $cfg.env | Add-Member -NotePropertyName "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" -NotePropertyValue "1" -Force
            $cfg | ConvertTo-Json -Depth 10 | Set-Content $settingsFile -Encoding UTF8
        } catch {
            @'
{
  "env": {
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
'@ | Set-Content $settingsFile -Encoding UTF8
        }
    } else {
        @'
{
  "env": {
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
  }
}
'@ | Set-Content $settingsFile -Encoding UTF8
    }
    Success "系统设置：已配置"
}

# --- 5b: Exa 搜索 ---
$claudeJson = Join-Path $env:USERPROFILE ".claude.json"
$exaConfigured = $false
if (Test-Path $claudeJson) {
    $exaConfigured = Select-String -Path $claudeJson -Pattern '"exa"' -Quiet
}

if ($exaConfigured) {
    Success "联网搜索：已配置（Exa）"
} else {
    try {
        & claude mcp add --transport http exa -s user "https://mcp.exa.ai/mcp?exaApiKey=ff847a3e-e7bb-46b3-b763-23f3120bc6e2" 2>$null
        Success "联网搜索：已配置（Exa）"
    } catch {
        Warn "联网搜索配置未成功，稍后可在 Claude Code 中让它帮你配"
    }
}

Write-Host ""
Info "搜索使用团队共享额度。如果提示额度不足："
Write-Host "  去 https://dashboard.exa.ai/api-keys 注册个人 Key"
Write-Host "  然后在 Claude Code 里说「帮我更换 Exa 的 API Key」"

Pause-Step

# ============================================================================
Step 6 $TOTAL_STEPS "创建工作目录 + 快捷命令"
# ============================================================================

$defaultWorkspace = Join-Path $env:USERPROFILE "claudeworkspace"

Write-Host "  Claude Code 需要一个本地文件夹作为工作空间。"
Write-Host "  你可以把需要处理的文件放到这个目录下。"
Write-Host ""
$workspace = Read-Host "  文件夹路径 [直接回车使用默认: $defaultWorkspace]"
if (-not $workspace) { $workspace = $defaultWorkspace }

if (Test-Path $workspace) {
    Success "目录已存在: $workspace"
} else {
    New-Item -ItemType Directory -Path $workspace -Force | Out-Null
    Success "已创建目录: $workspace"
}

# 创建快捷命令 cc
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}

$ccFunction = @"

# 快捷命令：输入 cc 即可进入工作目录并启动 Claude Code
function cc { Set-Location '$workspace'; claude }
"@

if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -notlike "*function cc*") {
        Add-Content -Path $PROFILE -Value $ccFunction
        Success "已添加快捷命令：输入 cc 即可启动 Claude Code"
    } else {
        Success "快捷命令 cc 已存在"
    }
} else {
    Set-Content -Path $PROFILE -Value $ccFunction
    Success "已添加快捷命令：输入 cc 即可启动 Claude Code"
}

Pause-Step

# ============================================================================
# 最终验证
# ============================================================================
Write-Host ""
Write-Host ""

try {
    $ver = & claude --version 2>$null
    if ($ver) {
        Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "  ║                                              ║" -ForegroundColor Green
        Write-Host "  ║          全部完成！可以开始使用了              ║" -ForegroundColor Green
        Write-Host "  ║                                              ║" -ForegroundColor Green
        Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "  接下来：关闭这个 PowerShell 窗口，重新打开一个，然后输入："
        Write-Host ""
        Write-Host "    cc" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  就会自动进入工作目录并启动 Claude Code。"
        Write-Host ""
        Write-Host "  首次启动会有几个初始设置（只需一次）："
        Write-Host "    1. 选择主题（明亮 / 暗色）"
        Write-Host "    2. 确认使用你的 API Key"
        Write-Host "    3. 信任当前文件夹（选 Yes）"
        Write-Host "    4. 选择权限模式（推荐选默认的即可）"
        Write-Host "  完成后就可以开始对话了！"
        Write-Host ""
        Write-Host "  提示：Ctrl+C 可以打断 Claude，输入 /exit 退出" -ForegroundColor DarkGray
    } else {
        throw "未找到"
    }
} catch {
    Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║                                              ║" -ForegroundColor Yellow
    Write-Host "  ║          配置已完成，但需要注意               ║" -ForegroundColor Yellow
    Write-Host "  ║                                              ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    Warn "claude 命令当前不可用（可能需要重启 PowerShell）"
    Write-Host ""
    Write-Host "  请关闭 PowerShell，重新打开一个新窗口，然后输入："
    Write-Host ""
    Write-Host "    cc" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  如果仍然提示找不到命令，尝试在新窗口中执行："
    Write-Host '    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")'
    Write-Host "    claude --version"
}
Write-Host ""
