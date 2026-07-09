<div align="center">

# ♟️ Dual Agent Sync 

**告别在不同 AI IDE 间繁琐的“复制粘贴上下文”，让多 Agent 无缝接力、高效协同！**

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
*“如棋局般精准落子，多 Agent 步步为营”*

</div>

## 🚀 核心优势：为什么需要 Dual Agent Sync？

在多 AI IDE（如 Trae, Cursor, Windsurf）同时开发一个项目时，你是否受够了：

| 痛点场景 | 传统方式（手动/多开） | 🌟 Dual Agent Sync（本 Skill） |
| :--- | :--- | :--- |
| **上下文传递** | ❌ 满屏“复制粘贴代码和报错”，费时费力 | ✅ **静默同步**：基于本地账本，无需人工搬运 |
| **文件状态对齐** | ❌ 切换 IDE 时反复确认“文件保存没、更新没” | ✅ **防冲突软锁**：明确的游标与声明式锁定 |
| **疑难杂症排查** | ❌ 多轮排查变成流水账，换 IDE 彻底断片 | ✅ **病历级交接**：严格结构化传递“结论与证据链” |

**✨ 核心价值**：省时、省力、不丢上下文！

## ⚡ 快速安装 / 启动

只需在终端执行以下命令，即可将 Skill 的核心协议（`SKILL.md`）安装到你的项目中（以 Trae 为例）：

```bash
mkdir -p .trae/skills/dual-agent-sync
curl -o .trae/skills/dual-agent-sync/SKILL.md https://raw.githubusercontent.com/lndlwh2024/dual-agent-sync/main/.trae/skills/dual-agent-sync/SKILL.md
```

*(💡 **Tips**: AI IDE 加载 `SKILL.md` 后，会根据其中的指令自动为你创建 `.ai-sync` 目录、初始化 `ledger.jsonl` 等所有必要的基础设施)*

## 📖 更多文档
- [使用说明书与场景指南 (MANUAL.md)](./MANUAL.md)
- [事件结构定义 (EVENT_SCHEMA.md)](./docs/EVENT_SCHEMA.md)

## 📄 License 说明

本项目采用 **[Apache 2.0 License](./LICENSE)** 开源。
- **个人与开源使用**：完全免费，欢迎 Star 🌟 与 PR。
- **商用授权提示**：若需将其集成至商业化闭源 IDE 或作为商业卖点，请遵守 Apache 2.0 协议要求，并在分发时保留原作者版权声明及 License 文件。

---
<div align="center">
  <i>Made with ❤️ for the AI Developer Community.</i>
</div>
