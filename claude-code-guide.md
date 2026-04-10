# Claude Code 从零开始使用指南

> BV 品牌团队内部教程 | 2026 年 4 月

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

**申请文档：** [AI API 申请指南](https://bluefocus.feishu.cn/docx/A8ozdc5HdoGgooxhTugcp7bHnae?from=from_copylink)

申请完成后你会得到一个以 `sk-` 开头的密钥字符串，请妥善保管。

### 2. 确认科学上网 / VPN 配置

Claude Code 在终端（Terminal）中运行，**普通的系统代理对终端无效**。你需要确保 VPN 工具开启了以下模式之一：

| VPN 工具 | 需要开启的模式 |
|---|---|
| Clash / ClashX | **增强模式（Enhanced Mode）** 或 **TUN 模式** |
| V2RayU / V2RayN | **虚拟网卡模式** 或手动设置终端代理 |
| Surge | **增强模式** |
| Shadowrocket | **全局路由模式** |

> 如果不确定怎么开，先打开 Terminal（终端），输入 `curl google.com`，如果有返回内容说明终端已经可以正常访问外网。如果超时没反应，说明终端流量没走代理。

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
1. 检查 VPN 是否生效
2. 检查/安装 Node.js（扩展工具需要）
3. 创建工作目录
4. 安装 Claude Code
5. 配置 API Key 和中转地址
6. 配置核心设置（禁用不兼容的 beta 功能）
7. [可选] 安装 Lark CLI（飞书集成）

脚本会自动帮你配置 DuckDuckGo 搜索（免费、无需注册），装完就能让 Claude Code 联网搜索了。

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

安装完成后，关闭终端重新打开，输入：

```bash
cc
```

就会自动进入工作目录并启动 Claude Code。

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

### 1. 遇到问题？直接问 Claude Code

Claude Code 本身就是一个 AI 助手。遇到任何配置、安装、报错的问题，**把错误信息直接粘贴给它，让它帮你解决**。不需要你自己去搜索或排查。

### 2. 联网搜索

安装脚本已经自动配置了 Exa 搜索（AI 语义搜索，团队共享额度），Claude Code 开箱就能帮你搜索网页信息。

如果提示搜索额度不足，去 https://dashboard.exa.ai/api-keys 注册一个免费账号，拿到你自己的 API Key，然后在 Claude Code 里说：

> 帮我更换 Exa 的 API Key，新的 Key 是 xxxxx

它会自动帮你完成。

### 3. 让 Claude Code 连接飞书

安装飞书 CLI 后，Claude Code 可以帮你查日历、发消息、读文档、操作表格。

直接在 Claude Code 里说：

> 帮我安装和配置飞书 CLI，参考这个文档 https://github.com/larksuite/cli/blob/main/README.zh.md

它会自动安装，过程中会给你一个授权链接，你用浏览器打开、飞书登录授权就行。

### 4. 想安装其他工具？同样的思路

以后不管是想装什么新工具、配置什么新功能，思路都一样：**找到官方文档或 GitHub 链接，把链接丢给 Claude Code，让它帮你搞定**。你不需要看懂那些技术文档，Claude Code 能看懂。

### 5. 常用快捷操作

| 操作 | 说明 |
|---|---|
| `Ctrl+C` | 打断 Claude 当前正在做的事情 |
| `Ctrl+D` | 退出 Claude Code |
| `/help` | 查看帮助信息 |
| `/status` | 查看当前连接状态和配置 |
| `Esc` 连按两次 | 撤销 Claude 刚刚的代码修改 |

### 6. 几个建议

- **描述清楚你的需求**：不用写代码，但要说清楚你想要什么结果
- **提供文件路径**：直接把文件拖进终端窗口，就能自动填入路径
- **分步骤来**：复杂任务可以先让 Claude 做个计划，确认后再执行
- **不满意就说**：如果结果不对，直接告诉它哪里不对，它会修改
- **善用工作目录**：把相关文件放到工作目录下，Claude 操作起来更方便

---

## 常见问题

### Q: 输入 `claude` 提示 command not found？
关闭终端窗口，重新打开一个再试。因为安装脚本写入的配置需要新终端才生效。如果重开还不行，在终端里输入 `source ~/.zshrc` 然后再输入 `claude`。还不行就在群里问。

### Q: 连接超时 / 网络错误？
最常见的原因是 VPN 没有开启增强模式/TUN 模式。先确认 VPN 配置（参考上面的「准备工作」部分），然后重新打开终端再试。

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

---

## 推荐阅读

想深入了解 Claude Code 的用法和技巧，可以看看这些文章：

- [Claude Code 官方快速入门（中文）](https://code.claude.com/docs/zh-CN/quickstart) — 官方文档，最权威
- [Claude Code 教程 — 菜鸟教程](https://www.runoob.com/claude-code/claude-code-tutorial.html) — 从零开始的中文系列教程，覆盖全面
- [Claude Code 最佳实践指南 — 知乎](https://zhuanlan.zhihu.com/p/2009744974980331332) — 实用技巧和工作流建议
- [这可能是目前最全的 Claude Code 使用指南 — 知乎](https://zhuanlan.zhihu.com/p/1954938233126381432) — 基于实操经验的详细指南
- [45 Tips for Claude Code — GitHub](https://github.com/ykdojo/claude-code-tips) — 45 个实用技巧合集（英文）
