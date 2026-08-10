<div align="center">

# ♟️ Dual Agent Sync 

**告别在不同 AI IDE 间繁琐的"复制粘贴上下文"，让多 Agent 无缝接力、高效协同！**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](#license)
[![GitHub stars](https://img.shields.io/github/stars/lndlwh2024/dual-agent-sync?style=social)](https://github.com/lndlwh2024/dual-agent-sync/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/lndlwh2024/dual-agent-sync)](https://github.com/lndlwh2024/dual-agent-sync/issues)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)

<pre>
    ┌─┬─┬─┐
    ├─●─┼─┤
    ├─┼─○─┤
    └─┴─┴─┘
</pre>
*"如棋局般精准落子，多 Agent 步步为营"*

</div>

## 🚀 核心优势：为什么需要 Dual Agent Sync？

在多 AI IDE（如 Trae, Cursor, Windsurf, Codex）同时开发一个项目时，你是否受够了：

| 痛点场景 | 传统方式（手动/多开） | 🌟 Dual Agent Sync（本 Skill） |
| :--- | :--- | :--- |
| **上下文传递** | ❌ 满屏"复制粘贴代码和报错"，费时费力 | ✅ **静默同步**：基于本地账本，无需人工搬运 |
| **文件状态对齐** | ❌ 切换 IDE 时反复确认"文件保存没、更新没" | ✅ **防冲突软锁**：明确的游标与声明式锁定 |
| **疑难杂症排查** | ❌ 多轮排查变成流水账，换 IDE 彻底断片 | ✅ **病历级交接**：严格结构化传递"结论与证据链" |
| **多窗口并发冲突** | ❌ 同一 IDE 多窗口同时启动，会话 ID 碰撞、游标互相覆盖 | ✅ **Cursor 专用锁**：原子检查 + 归属校验 + 超时拒绝，彻底消除并发竞争 |

**✨ 核心价值**：省时、省力、不丢上下文！

## ⚡ 快速安装 / 启动

在终端执行以下对应 IDE 的命令，即可将 Skill 核心协议（`SKILL.md`）安装到你的项目中：

```bash
# Trae
mkdir -p .trae/skills/dual-agent-sync
curl -s -o .trae/skills/dual-agent-sync/SKILL.md https://raw.githubusercontent.com/lndlwh2024/dual-agent-sync/main/.trae/skills/dual-agent-sync/SKILL.md

# Codex
mkdir -p .codex/skills/dual-agent-sync
curl -s -o .codex/skills/dual-agent-sync/SKILL.md https://raw.githubusercontent.com/lndlwh2024/dual-agent-sync/main/.trae/skills/dual-agent-sync/SKILL.md

# Cursor
mkdir -p .cursor/skills/dual-agent-sync
curl -s -o .cursor/skills/dual-agent-sync/SKILL.md https://raw.githubusercontent.com/lndlwh2024/dual-agent-sync/main/.trae/skills/dual-agent-sync/SKILL.md

# Windsurf
mkdir -p .windsurf/skills/dual-agent-sync
curl -s -o .windsurf/skills/dual-agent-sync/SKILL.md https://raw.githubusercontent.com/lndlwh2024/dual-agent-sync/main/.trae/skills/dual-agent-sync/SKILL.md

# Cline
mkdir -p .cline/skills/dual-agent-sync
curl -s -o .cline/skills/dual-agent-sync/SKILL.md https://raw.githubusercontent.com/lndlwh2024/dual-agent-sync/main/.trae/skills/dual-agent-sync/SKILL.md
```

*(💡 **Tips**: AI IDE 加载 `SKILL.md` 后，会根据其中的指令自动为你创建 `.ai-sync` 目录、初始化 `ledger.jsonl` 等所有必要的基础设施。重新安装只更新规则文件，**不会覆盖 `.ai-sync/` 下任何已有的同步记录**。)*

## 📖 更多文档
- [使用说明书与场景指南 (MANUAL.md)](./MANUAL.md)
- [事件结构定义 (EVENT_SCHEMA.md)](./docs/EVENT_SCHEMA.md)

## 📄 License 说明

本项目采用 **[Apache 2.0 License](./LICENSE)** 开源。
- **个人与开源使用**：完全免费，欢迎 Star 🌟 与 PR。
- **商用授权提示**：若需将其集成至商业化闭源 IDE 或作为商业卖点，请遵守 Apache 2.0 协议要求，并在分发时保留原作者版权声明及 License 文件。

## 📅 变更日志 (Changelog)

- **v1.4.1 (Latest)**：
  - 🔒 **Cursor 锁协议全面强化**（由 Codex 并发测试发现并推动），将 v1.4 五步协议升级为六步：
    - **Step 1 原子独占检查**：写锁前先判断锁文件是否存在，分支处理——不存在则写入；未过期则等待重试（最多 10 次 / 10 秒）；已过期则覆盖旧锁；超时后**拒绝游标写入并向用户报错**，彻底移除 best-effort 降级路径。
    - **Step 2 归属校验（新增）**：写锁后立即回读锁文件，比对 `lock_id`；不匹配说明另一窗口赢得竞争，退让重试；连续失败 3 次则报告用户并中止。
    - **Step 6 所有者释放（升级）**：释放前回读验证 `lock_id`，非所有者不得删除锁文件，防止误删他人锁。

- **v1.4**：
  - 🆕 **新增 Cursor Write Safety（Read-Merge-Write）章节**：引入 Cursor 专用锁文件（`.ai-sync/locks/cursor-<ai-ide-id>.lock.json`）与五步写入协议，解决同一 IDE 多窗口并发启动时的**会话 ID 碰撞**与**游标文件最后写入覆盖**两类问题。
  - 🔗 **After Changes 游标更新步骤**强制引用 Read-Merge-Write 协议。
  - 🐛 **修复孤立 Markdown 代码围栏**：删除字段引用表后的格式错误（由 Codex 发现上报）。

- **v1.3**：
  - 新增**增量读取机制**：基于行号 + 版本校验（`last_read_line`）的增量同步，AI IDE 只读取上次位置之后的新事件，大幅降低 Token 消耗与加载延迟。
  - 新增**会话级游标追踪**：每个 IDE 维护单一 cursor 文件，内部通过 `sessions` 对象独立记录不同对话窗口的读取位置，切换或恢复窗口时精准续读。
  - 新增**会话 ID 智能识别与自动命名**：优先使用 IDE 内置 Conversation ID（如 UUID）；若 IDE 未提供，则自动生成格式化序列 ID（如 `CODEX_202608031701_A0001`，支持 A0001~Z9999 跨年/跨月递增循环），项目间自动隔离。
  - **Cursor Schema 升级与全兼容**：新增 `sessions` 映射与 `last_read_line` 字段，完全向后兼容旧版单游标格式。
- **v1.2**：
  - 增强 `files_changed` 字段，支持精确记录修改的行号范围（如 `{"file": "src/main.py", "lines": ["10-20"]}`），大幅降低接手 AI 的 Token 消耗，实现精准"按需加载"。
  - 将 `README.md` 重构为产品落地页。
- **v1.1**：
  - 重构 `MANUAL.md`，引入基于 8 大场景的写入规范。
  - 引入"诊断病历"结构，强制规范排查过程中的上下文交接，彻底杜绝聊天流水账。
- **v1.0**：
  - 初始开源发布，建立基于 `ledger.jsonl` 的核心账本机制与软锁防冲突机制。

---
<div align="center">
  <i>Made with ❤️ for the AI Developer Community.</i>
</div>
