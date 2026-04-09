# Claude Code 从零开始使用指南

> 蓝瀚互动团队内部教程 | 2026 年 4 月

---

## 什么是 Claude Code？

你可能已经用过 Cherry Studio、ChatGPT 网页版或其他 AI 对话工具来问问题、写文案。Claude Code 和它们有本质区别：

| | Cherry Studio 等对话工具 | Claude Code |
|---|---|---|
| **交互方式** | 在浏览器里打字聊天 | 在终端（命令行）里对话 |
| **能力范围** | 只能文字对话，你复制粘贴代码/文件 | 能直接读写你电脑上的文件、执行命令、联网搜索 |
| **工作方式** | 你问一句它答一句 | 它像一个助手，能自主完成多步骤的复杂任务 |
| **使用场景** | 简单问答、文案撰写 | 数据处理、文件批量操作、自动化工作流、编程开发 |
| **可扩展性** | 基本没有 | 可以连接飞书、搜索引擎、浏览器等各种工具 |

**简单来说：Cherry Studio 是一个聊天窗口，Claude Code 是一个能干活的 AI 助手。**

它可以：
- 帮你批量处理 Excel/CSV 文件
- 读取飞书文档、日历、消息
- 联网搜索信息并整理成报告
- 自动创建 PPT、Word 文档
- 分析数据、生成图表
- 以及任何你能用自然语言描述的任务

---

## 准备工作

### 1. 申请 API Key

Claude Code 通过公司统一的 API 服务使用，你需要先申请一个 API Key。

**申请文档：** [蓝瀚 AI API 申请指南](https://bluefocus.feishu.cn/docx/A8ozdc5HdoGgooxhTugcp7bHnae?from=from_copylink)

申请完成后你会得到一个以 `sk-` 开头的密钥字符串，请妥善保管。

### 2. 确认翻墙工具配置

Claude Code 在终端（Terminal）中运行，**普通的系统代理对终端无效**。你需要确保翻墙工具开启了以下模式之一：

| 翻墙工具 | 需要开启的模式 |
|---|---|
| Clash / ClashX | **增强模式（Enhanced Mode）** 或 **TUN 模式** |
| V2RayU / V2RayN | **虚拟网卡模式** 或手动设置终端代理 |
| Surge | **增强模式** |
| Shadowrocket | **全局路由模式** |

> 如果不确定怎么开，先打开 Terminal（终端），输入 `curl google.com`，如果有返回内容说明终端已经可以翻墙。如果超时没反应，说明终端流量没走代理。

---

## 安装与配置

### Mac 用户（推荐方式：一键脚本）

我们准备了一键安装配置脚本，帮你完成所有步骤。

**第一步：打开终端（Terminal）**

- 按 `Command + 空格`，输入 `Terminal`，回车
- 或者在「启动台」→「其他」→「终端」

**第二步：运行安装脚本**

复制以下命令，粘贴到终端，回车执行：

```bash
curl -fsSL https://raw.githubusercontent.com/yangzihaoku/claude-code-team-guide/main/setup-claude-code.sh | bash
```

> 如果上面的命令报错，也可以手动下载脚本再执行：
> ```bash
> curl -O https://raw.githubusercontent.com/yangzihaoku/claude-code-team-guide/main/setup-claude-code.sh
> chmod +x setup-claude-code.sh
> ./setup-claude-code.sh
> ```

脚本会引导你完成：
1. 检查翻墙工具是否生效
2. 检查/安装 Node.js（扩展工具需要）
3. 创建工作目录
4. 安装 Claude Code
5. 配置 API Key 和中转地址
6. 配置核心设置（禁用不兼容的 beta 功能）
7. [可选] 配置 Brave Search（联网搜索能力）
8. [可选] 安装 Lark CLI（飞书集成）

### Windows 用户

1. **安装 Git for Windows**：https://git-scm.com/downloads/win
2. **打开 PowerShell**，运行：
   ```powershell
   irm https://claude.ai/install.ps1 | iex
   ```
3. 安装完成后，需要手动配置环境变量（在「系统设置」→「高级系统设置」→「环境变量」中添加）：
   - `ANTHROPIC_API_KEY` = 你的 API Key
   - `ANTHROPIC_BASE_URL` = `https://bmc-llm-relay.bluemediagroup.cn`
4. 创建设置文件 `%USERPROFILE%\.claude\settings.json`，内容为：
   ```json
   {
     "env": {
       "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": "1"
     }
   }
   ```
5. 重新打开 PowerShell，输入 `claude` 即可启动

---

## 开始使用

安装完成后：

```bash
cd ~/claudeworkspace    # 进入你的工作目录
claude                  # 启动 Claude Code
```

首次启动会要求登录：
1. 选择 **Use an API key**
2. 粘贴你的 API Key
3. 开始对话！

你可以像和人说话一样告诉它你要做什么，比如：

```
帮我把桌面上的 report.xlsx 里的数据按月份汇总，生成一个新的表格
```

```
搜索一下最近关于东南亚电商市场的报告，整理成要点
```

```
帮我看看今天飞书日历上有什么会议
```

剩下的就自己探索吧！Claude Code 的能力边界远比你想象的大，多试试就知道了。

---

## 必知技巧

### 1. 联网搜索：安装 Brave Search

公司的 API 中转不支持 Claude 内置的联网搜索功能，所以你需要单独安装 Brave Search 插件。

**申请 Brave Search API Key：**
1. 打开 https://brave.com/search/api/ （需要翻墙）
2. 点击 **Get Started**
3. 注册账号
4. 选择 **Search** 计划（免费额度：每月约 1000 次搜索，足够日常使用）
5. 进入 Dashboard，复制你的 API Key

**配置方式：**

如果安装脚本里跳过了这步，可以在终端执行：

```bash
claude mcp add brave-search -s user -e BRAVE_API_KEY=你的Key -- npx -y @brave/brave-search-mcp-server
```

配置完成后重启 Claude Code，就可以让它联网搜索了。

### 2. 飞书集成：安装 Lark CLI

安装 Lark CLI 后，Claude Code 可以直接操作飞书（查日历、发消息、读文档、操作表格等）。

详细文档参考：https://github.com/larksuite/cli/blob/main/README.zh.md

**安装 CLI 和 Claude Code 技能包：**

```bash
npm install -g @larksuite/cli
npx skills add larksuite/cli -y -g
```

第二条命令会把飞书相关的技能（日历、消息、文档、表格等 19 个）安装到 Claude Code 中。

**初始化应用配置：**

```bash
lark-cli config init
```

按提示操作：选择 `feishu`，输入应用的 App ID 和 App Secret。
（如果还没有飞书应用，config init 过程会引导你自动创建。）

**登录授权：**

```bash
lark-cli auth login --recommend
```

运行后会输出一个授权链接，在浏览器中打开并完成飞书 OAuth 登录。授权成功后命令会自动退出。

**验证登录状态：**

```bash
lark-cli auth status
```

看到你的用户名和授权范围就说明配置成功了。

### 3. 常用快捷操作

| 操作 | 说明 |
|---|---|
| `Ctrl+C` | 打断 Claude 当前正在做的事情 |
| `Ctrl+D` | 退出 Claude Code |
| `/help` | 查看帮助信息 |
| `/status` | 查看当前连接状态和配置 |
| `/model` | 切换使用的 AI 模型 |
| `Esc` 连按两次 | 撤销 Claude 刚刚的代码修改 |

### 4. 几个建议

- **描述清楚你的需求**：不用写代码，但要说清楚你想要什么结果
- **提供文件路径**：直接把文件拖进终端窗口，就能自动填入路径
- **分步骤来**：复杂任务可以先让 Claude 做个计划，确认后再执行
- **不满意就说**：如果结果不对，直接告诉它哪里不对，它会修改
- **善用工作目录**：把相关文件放到工作目录下，Claude 操作起来更方便

---

## 常见问题

### Q: 输入 `claude` 提示 command not found？
- 新开一个终端窗口再试
- 或执行 `source ~/.zshrc` 重新加载配置
- 确认安装是否成功：`ls ~/.local/bin/claude`

### Q: 连接超时 / 网络错误？
- 检查翻墙工具是否开启了增强模式/TUN 模式
- 在终端测试：`curl -I https://claude.ai`（应该返回 HTTP 200 或 301）
- 临时方案：在终端设置代理
  ```bash
  export https_proxy=http://127.0.0.1:7890
  export http_proxy=http://127.0.0.1:7890
  ```
  （端口号 7890 视你的翻墙工具而定，Clash 默认是 7890）

### Q: API 报错 / 请求失败？
- 确认 `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` 已设置为 `1`
- 在 Claude Code 中输入 `/status` 查看配置是否正确
- 确认 API Key 没有过期

### Q: Brave Search 不生效？
- 确认 Node.js 已安装：`node --version`
- 重启 Claude Code 后再试
- 检查配置：在 Claude Code 中输入 `/mcp` 查看 MCP 服务器状态

### Q: 能用来做什么？
这取决于你的想象力。以下是一些真实使用场景：
- 批量翻译和本地化文案
- 竞品分析报告自动生成
- 数据清洗和格式转换
- 自动整理会议纪要
- 从网上搜索行业信息并汇总
- 生成周报/月报初稿
- ...

有问题随时在群里问！
