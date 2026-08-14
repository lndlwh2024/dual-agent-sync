<div align="center">

# ♟️ Dual Agent Sync (V2.0) 

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

| 痛点场景 | 传统方式（手动/多开） | 🌟 Dual Agent Sync (V2.0) |
| :--- | :--- | :--- |
| **上下文传递** | ❌ 满屏"复制粘贴代码和报错"，费时费力 | ✅ **增量静默同步**：基于 append-only 本地账本与会话游标，按需增量拉取，零人工搬运 |
| **架构与依赖感知** | ❌ 换 IDE/新会话后"瞎子摸象"，全盘盲目搜索扫码，浪费海量 Token 且容易改坏未知依赖 | ✅ **文件级代码架构图谱 (`codegraph`)**：单文件极速掌握项目全景拓扑、模块职责与引用依赖；修改代码时自动声明 `graph_impact` 联动维护 |
| **文件状态对齐** | ❌ 切换 IDE 时反复确认"文件保存没、更新没" | ✅ **声明式意图软锁**：明确行级修改范围与文件独占声明，避免多 IDE 撞车冲突 |
| **疑难杂症排查** | ❌ 多轮排查变成流水账，换 IDE 彻底断片 | ✅ **病历级交接**：严格结构化传递"结论与证据链"，错误结论显式推翻纠错 |
| **多窗口并发冲突** | ❌ 同一 IDE 多窗口同时启动，会话 ID 碰撞、游标互相覆盖 | ✅ **Cursor 专用锁**：原子检查 + 归属校验 + 6步 RMW 协议 + 超时拒绝，彻底消除并发竞争 |
| **跨版本平滑升级** | ❌ 协议升级导致不同步的旧 IDE 冲突崩溃或破坏数据 | ✅ **强事务性自动数据迁移**：精准版本嗅探 + 排他迁移锁 + 全量备份 + 三道门禁校验 + 异常全量回滚，无缝升级 |
| **数据安全与回滚** | ❌ 协同数据散落各处脱离版本控制，回滚时状态错位 | ✅ **Git 原子物理锚定**：协作事件与 Git Commit SHA 强绑定，代码、账本与图谱随 Git 快照 100% 同步回滚 |

**✨ 核心价值**：省时、省力、省 Token，懂架构、不丢上下文！

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

- **v2.0 (Latest)**：
  - 🌟 **代码架构图谱 (codegraph)**：拆分 collab/ 与 codegraph/ 双模块结构，记录文件级架构依赖关系，无缝联动。
  - 🔄 **强事务性数据迁移协议**：识别跨版本 IDE，支持全自动 V1.x 到 V2.0 的安全数据重构、备份及熔断回滚，完美向下兼容遗留协作数据。
  - 🔒 **并发锁机制隔离解耦**：彻底剥离全局锁设计，使软锁下沉至对应业务物理目录中，消除侵入式扫描。

- **v1.5**：
  - 🔬 **锁协议语义精确化（由 Codex 并发模拟验证推动）**：升级为 O_EXCL 独占写入语义。

- **v1.4.1**：
  - 🔒 **Cursor 锁协议全面强化**：升级为六步机制，原子独占检查与归属校验。

- **v1.4**：
  - 🆕 **新增 Cursor Write Safety（Read-Merge-Write）章节**：引入五步写入协议。

- **v1.3**：
  - 新增**增量读取机制**与**会话级游标追踪**。

- **v1.2**：
  - 增强 iles_changed 字段，支持精确记录修改的行号范围。

- **v1.1**：
  - 重构 MANUAL.md，引入基于 8 大场景的写入规范。

- **v1.0**：
  - 初始开源发布。

---
<div align="center">
  <i>Made with ❤️ for the AI Developer Community.</i>
</div>
