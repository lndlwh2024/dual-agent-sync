<div align="center">

# ♟️ Dual Agent Sync (V2.0)

**告别在不同 AI IDE 间繁琐的“复制粘贴上下文”，让多 Agent 具备全局架构感知、无缝接力与高并发协同！**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](#license)
[![GitHub stars](https://img.shields.io/github/stars/lndlwh2024/dual-agent-sync?style=social)](https://github.com/lndlwh2024/dual-agent-sync/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/lndlwh2024/dual-agent-sync)](https://github.com/lndlwh2024/dual-agent-sync/issues)
[![Version](https://img.shields.io/badge/version-2.0.0-success.svg)](#)

<pre>
    ┌─┬─┬─┐
    ├─●─┼─┤
    ├─┼─○─┤
    └─┴─┴─┘
</pre>
*"如棋局般精准落子，多 Agent 步步为营"*

</div>

---

## 🚀 核心优势与功能矩阵 (V2.0)

在多 AI IDE（如 Trae, Cursor, Windsurf, Codex）协同开发同一个项目时，**Dual Agent Sync** 提供了**三大独立核心子系统**，彻底解决上下文搬运困难、架构黑盒失序与并发冲突问题：

### 📦 模块一：项目协同系统 (Project Collaboration)

* **🔄 切换 IDE 上下文静默传递**
  * **痛点**：跨 IDE 切换时需频繁手动复制粘贴代码片段、报错信息和会话思路，费时费力且极易丢失上下文。
  * **能力**：基于 append-only 本地事实账本（`collab/ledger.jsonl`）与会话级读取游标（`collab/cursors/`），接手 AI 启动时自动执行行号校验并**增量静默拉取**，零人工搬运。

* **🩺 疑难杂症“病历级”排查交接**
  * **痛点**：多轮 Debug 排查极易演变成聊天流水账；换一个 IDE 后思路断片，后继 AI 经常重复尝试已被证伪的错误方案。
  * **能力**：严格结构化沉淀“问题现象、根因假设、已验证/未验证证据链、解决方案”，支持显式推翻纠错（`conflict_notice`），杜绝重复踩坑。

* **🪟 多窗口 / 多实例并发协同**
  * **痛点**：同一 IDE 开启多个对话窗口或同时启动多个实例时，会话 ID 碰撞、游标相互覆盖导致“最后写入者胜”（Last-Write-Wins 脏写）。
  * **能力**：智能识别 IDE 内置会话 ID 并支持跨项目隔离自动命名；在游标文件内通过 `sessions` 映射独立追踪各窗口进度，精准续读，互不覆盖。

* **🎯 精准文件状态对齐与按需加载**
  * **痛点**：切换 IDE 后需反复确认“修改了哪些文件、修改了哪里”，盲目全量重读大文件极度消耗 Token。
  * **能力**：在协作事件中精准记录 `scope.files_changed`，细化至修改行号区间（如 `["10-20"]`）及修改目的（`purpose`），按需精准拉取，大幅节省 Token。

* **🔒 多 IDE 协同防撞车锁机制**
  * **痛点**：多 IDE 同时修改同一批文件引发冲突；游标并发写时发生数据竞争。
  * **能力**：
    * **编辑意图软锁 (`<scope>.lock.json`)**：在修改文件前声明目标范围，遇冲突主动预警并请求人工确认。
    * **游标专属排他锁 (`cursor-*.lock.json`)**：采用严格的 **6 步 Read-Merge-Write 写入协议**（O_EXCL 独占检查、归属校验、合并写、所有者释放），彻底消除游标并发踩踏。

---

### 🗺️ 模块二：代码架构图谱系统 (Code Architecture Graph)

* **🌐 代码架构全局图谱生成与增量同步**
  * **痛点**：新会话或新 IDE 接手项目时如同“盲人摸象”，只能靠全局盲目 grep 或递归扫码，耗尽 Token 且极易破坏未声明的隐式依赖。
  * **能力**：
    * **单文件秒级掌握全景 (`codegraph/graph.json`)**：采用文件级邻接表，一次读取即可看透项目全局模块划分、文件职责（`purpose`/`exports`）与引用依赖（`imports`/`api_call`）。
    * **双轨联动与增量更新 (`graph_impact`)**：修改代码后在协作事件中显式声明 `graph_impact`，并在专属图谱锁（`codegraph/locks/`）保护下增量更新 `graph.json`，同时追加增量变更历史（`graph.changelog.jsonl`）。

* **🔄 老版本无缝兼容设计与强事务自动迁移**
  * **痛点**：团队中不同 IDE 升级节奏不一，V1 遗留平铺结构与 V2 模块化结构并存易引发格式冲突和数据脑裂。
  * **能力**：
    * **智能版本嗅探**：启动任务时自动识别 V1 遗留目录结构。
    * **强事务性迁移流水线**：独占排他迁移锁 (`migration.lock`) + 全量数据冷备份 (`.migration_backup_v1/`) + 目录物理重组 + 三道门禁严格校验。
    * **异常熔断与原子回滚**：迁移中遇任何异常立即全量复原旧结构并退出，绝不在受损数据上执行 V2 逻辑。

---

### 🛡️ 模块三：数据安全与 Git 原子回滚机制 (Data Safety & Atomic Rollback)

* **⚓ Git 物理原子锚定**
  * **能力**：依托项目根目录真实的物理 `.git` 作为底层版本持久化引擎；每次协作事件必须记录当前 `git.head_commit` SHA 作为唯一物理快照锚点。

* **⏪ 全链路绝对一致性时光倒流**
  * **能力**：执行 `git reset --hard <commit>` 时，业务源码、协作事件账本（`collab/ledger.jsonl`）与代码架构图谱（`codegraph/graph.json`）三者绝对同步回退，彻底消除图谱与代码脱节的风险。

* **🔑 外键机制与单一事实源**
  * **能力**：遵循单一数据源原则（Single Source of Truth），Git 锚点集中单点记录在 `collab/` 中，`codegraph/` 通过 `trigger_version` 外键关联，杜绝多处冗余记录导致的状态不一致。

---

> 💡 **核心价值总结**：**省时、省力、省 Token，懂架构、不丢上下文！**

---

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

*(💡 **Tips**: AI IDE 加载 `SKILL.md` 后，会根据协议指令自动为你初始化 `.ai-sync/` 下的 `collab/` 和 `codegraph/` 目录结构。重新安装只更新规则文件，**不会覆盖已有协作记录与代码图谱**。)*

---

## 📖 更多文档

* 📘 [用户使用说明书与场景指南 (MANUAL.md)](./MANUAL.md)
* 📜 [双端协同协议核心规范 (PROTOCOL.md)](./docs/PROTOCOL.md)
* 📐 [事件与游标模式定义 (EVENT_SCHEMA.md)](./docs/EVENT_SCHEMA.md)
* 💡 [数据实战样例展示 (EXAMPLES.md)](./docs/EXAMPLES.md)
* 🔄 [协同工作流全景说明 (WORKFLOW.md)](./docs/WORKFLOW.md)

---

## 📄 License 说明

本项目采用 **[Apache 2.0 License](./LICENSE)** 开源。
* **个人与开源使用**：完全免费，欢迎 Star 🌟 与 PR。
* **商用授权提示**：若需将其集成至商业化闭源 IDE 或作为商业卖点，请遵守 Apache 2.0 协议要求，并在分发时保留原作者版权声明及 License 文件。

---

## 📅 变更日志 (Changelog)

* **v2.0 (Latest)**：
  * 🌟 **代码架构图谱 (codegraph)**：拆分 `collab/` 与 `codegraph/` 双模块结构，记录文件级架构依赖关系，实现秒级架构全景感知与双轨联动。
  * 🔄 **强事务性数据迁移协议**：智能识别跨版本 IDE，支持全自动 V1.x 到 V2.0 的安全数据重构、全量冷备份与三道门禁校验，失败自动回滚。
  * 🔒 **并发锁机制物理隔离解耦**：彻底剥离全局锁设计，使软锁下沉至对应业务物理目录中，消除跨模块侵入式扫描。
  * ⚓ **Git 原子物理锚定**：确立 Git 为唯一版本持久化底层，协作事件绑定 Commit SHA，实现全链路绝对一致性时光倒流。

* **v1.5**：
  * 🔬 **锁协议语义精确化（由 Codex 并发模拟验证推动）**：升级为 O_EXCL 独占写入语义。

* **v1.4.1**：
  * 🔒 **Cursor 锁协议全面强化**：升级为六步机制，原子独占检查与归属校验。

* **v1.4**：
  * 🆕 **新增 Cursor Write Safety（Read-Merge-Write）章节**：引入五步写入协议。

* **v1.3**：
  * 新增**增量读取机制**与**会话级游标追踪**。

* **v1.2**：
  * 增强 `files_changed` 字段，支持精确记录修改的行号范围。

* **v1.1**：
  * 重构 MANUAL.md，引入基于 8 大场景的写入规范。

* **v1.0**：
  * 初始开源发布。

---

<div align="center">
  <i>Made with ❤️ for the AI Developer Community.</i>
</div>
