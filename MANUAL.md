# dual-agent-sync skill 使用说明书 v1.0

本文档说明如何在一个项目中部署和使用 `dual-agent-sync`，让多个 AI IDE 协同开发同一个仓库时，以最小沟通成本完成更新同步、审计提示和上下文继承。

## 1. 设计目标

`dual-agent-sync` 的目标不是替代 Git，而是在 Git 之外补充 AI 协作所需的“意图、背景、状态、风险、后续计划”信息。

它解决的问题包括：

- 多个 AI IDE 同时开发同一项目时，如何知道其他 AI 最近做了什么。
- 如何避免一个 AI 跳过中间版本，只读到最新状态而漏掉重要背景。
- 如何让 AI 只读相关变更，而不是每次全量扫描项目。
- 如何让人类只看到必要的审计结果，而不是承担大量手工同步成本。
- 如何在同一模块或同一文件并行开发前，先声明范围并降低冲突概率。

## 2. 两类目录

在目标项目中使用该 skill 时，会出现两类目录：

- AI IDE 私有使能目录：让某个 AI IDE 能识别并加载 `dual-agent-sync` skill。
- 项目共享同步目录：让所有 AI IDE 共同读写协作状态。

这两类目录必须分清楚。

## 3. AI IDE 私有使能目录

每个 AI IDE 可以有自己的 skill 目录。该目录只负责“让该 IDE 知道这个 skill 的规则”，不负责记录项目协作状态。

推荐结构：

```text
<project-root>/
├─ .trae/
│  └─ skills/
│     └─ dual-agent-sync/
│        └─ SKILL.md
├─ .codex/
│  └─ skills/
│     └─ dual-agent-sync/
│        └─ SKILL.md
└─ .ai-sync/
```

### 3.1 `.trae/skills/dual-agent-sync/`

用途：Trae IDE 的项目级 skill 使能目录。

推荐文件：

```text
.trae/skills/dual-agent-sync/SKILL.md
```

说明：

- 这是 Trae 的私有加载入口。
- Trae 读取该文件后，应在共享项目任务前自动执行同步前置检查。
- Trae 不应该把自己的协作事件写到 `.trae/` 目录中。

### 3.2 `.codex/skills/dual-agent-sync/`

用途：Codex 的项目级 skill 使能目录。

推荐文件：

```text
.codex/skills/dual-agent-sync/SKILL.md
```

说明：

- 这是 Codex 的私有加载入口。
- Codex 读取该文件后，应遵守同一套 `.ai-sync` 协议。
- Codex 不应该把自己的协作事件写到 `.codex/` 目录中。

### 3.3 其他 AI IDE 的私有目录

如果接入新的 AI IDE，建议按 IDE 名称创建私有目录。

推荐命名：

```text
.<ide-name>/skills/dual-agent-sync/SKILL.md
```

示例：

```text
.cursor/skills/dual-agent-sync/SKILL.md
.cline/skills/dual-agent-sync/SKILL.md
.windsurf/skills/dual-agent-sync/SKILL.md
```

规则：

- 私有目录只存该 AI IDE 的 skill 加载文件。
- 私有目录不作为跨 IDE 的同步账本。
- 每个 IDE 可以复制同一份 `SKILL.md`，但实际协作状态统一写入 `.ai-sync/`。

## 4. 项目共享同步目录

所有 AI IDE 共同使用的唯一共享目录是：

```text
<project-root>/.ai-sync/
```

这是项目级协作工作区。多个 AI IDE 都从这里读取更新，也向这里写入自己的同步事件。

推荐结构：

```text
.ai-sync/
├─ ledger.jsonl
├─ AUDIT_LOG.md
├─ PROJECT_STATE.md
├─ cursors/
│  ├─ codex-main.json
│  ├─ trae-main.json
│  └─ <ai-ide-id>.json
└─ locks/
   ├─ <scope>.lock.json
   └─ .gitkeep
```

## 5. 共享目录文件职责

### 5.1 `ledger.jsonl`

类型：所有 AI IDE 共写文件。

职责：

- 项目的全量协作变更账本。
- 每一行是一条 JSON 事件。
- 版本号必须单调递增，例如 `v0001`、`v0002`、`v0003`。
- 不允许跳号。
- 不允许随意重写历史。

所有 AI IDE 在完成一次有意义的工作后，都应该追加一条事件。

事件必须尽量包含：

- 需求背景。
- 问题背景。
- 解决方案。
- 当前状态。
- 遗留问题。
- 后续计划。
- 潜在风险。
- 代码更新文件。
- 文档更新文件。
- Git 分支和 commit 信息。
- 测试结果。
- 一句话摘要。

### 5.2 `AUDIT_LOG.md`

类型：所有 AI IDE 共写文件。

职责：

- 人机共看的审计日志。
- 用 Markdown 记录每个版本的可读摘要。
- 方便人类快速查看“什么时候、哪个 AI、对哪个项目做了什么”。

该文件不是机器读取的唯一依据，机器读取应优先使用 `ledger.jsonl`。

### 5.3 `PROJECT_STATE.md`

类型：所有 AI IDE 共写文件。

职责：

- 项目当前协作状态摘要。
- 记录当前分支、最新 commit、最新同步版本、活跃 AI IDE、当前工作、风险和下一步。
- 方便新 AI IDE 快速了解项目状态。

建议保持简短，不要变成大型交接文档。

### 5.4 `cursors/<ai-ide-id>.json`

类型：AI IDE 私有文件，但位于共享目录内。

职责：

- 记录某个 AI IDE 已经读到哪个同步版本。
- 防止该 AI IDE 跳过中间版本。
- 每个 AI IDE 只更新自己的 cursor 文件。

示例：

```json
{
  "ai_ide_id": "trae-main",
  "last_read_version": "v0002",
  "last_read_timestamp": "2026-07-09T16:45:00+08:00",
  "notes": "Read and acknowledged v0000-v0002."
}
```

规则：

- `trae-main` 只更新 `.ai-sync/cursors/trae-main.json`。
- `codex-main` 只更新 `.ai-sync/cursors/codex-main.json`。
- 一个 AI IDE 不应替另一个 AI IDE 直接推进 cursor，除非用户明确要求修复同步状态。

### 5.5 `locks/*.lock.json`

类型：所有 AI IDE 可写的声明文件。

职责：

- 声明某个 AI IDE 正准备修改哪些模块或文件。
- 降低多个 AI IDE 同时改同一模块的风险。
- 这是软锁，不是操作系统级文件锁。

示例：

```json
{
  "lock_id": "lock-20260709-164500-trae-main",
  "source_ai_ide": "trae-main",
  "timestamp": "2026-07-09T16:45:00+08:00",
  "scope": {
    "modules": ["news-aide-mode1"],
    "files": ["LLM-RPA-Bot-news_aide_V1/app/engine/mode1_runner.py"]
  },
  "intent": "Investigate Mode1 submit confirmation behavior",
  "expires_at": "2026-07-09T18:45:00+08:00"
}
```

规则：

- 修改前检查 `locks/`。
- 如果发现重叠锁，必须提示用户。
- 工作完成并写入 ledger 后，创建者应删除自己的锁。

## 6. 新 AI IDE 接入命名规范

每个 AI IDE 必须有稳定 ID。

推荐格式：

```text
<ide-name>-<role-or-instance>
```

推荐示例：

```text
trae-main
codex-main
cursor-main
cursor-rpa
cline-qa
windsurf-ui
```

命名建议：

- `ide-name` 使用小写英文，例如 `trae`、`codex`、`cursor`、`cline`。
- `role-or-instance` 用于区分用途或实例，例如 `main`、`rpa`、`qa`、`ui`。
- 不建议使用空格、中文、特殊符号。
- 同一个项目中不要重复使用同一个 AI IDE ID。

对应私有 cursor 文件：

```text
.ai-sync/cursors/<ai-ide-id>.json
```

例如：

```text
.ai-sync/cursors/trae-main.json
.ai-sync/cursors/codex-main.json
.ai-sync/cursors/cursor-rpa.json
```

对应私有 skill 使能目录：

```text
.<ide-name>/skills/dual-agent-sync/SKILL.md
```

例如：

```text
.trae/skills/dual-agent-sync/SKILL.md
.codex/skills/dual-agent-sync/SKILL.md
.cursor/skills/dual-agent-sync/SKILL.md
```

## 7. AI IDE 标准工作流

### 7.1 开始任务前

AI IDE 必须静默执行：

1. 读取 `.ai-sync/ledger.jsonl`。
2. 读取自己的 `.ai-sync/cursors/<ai-ide-id>.json`。
3. 找出 cursor 之后所有未读版本。
4. 按版本顺序读取，不能跳过。
5. 如果发现来自其他 AI IDE 的更新，打印协作同步审计。
6. 如果没有更新，则静默继续，不打扰用户。

协作同步审计格式：

```markdown
**协作同步审计**
- 来源 AI IDE：codex-main
- 版本：v0003
- 时间：2026-07-09T17:00:00+08:00
- 摘要：修复 Mode1 runtime 键名不一致。
- 影响文件：src/lib/newsAideConfig.ts
- 当前状态：代码已改，测试通过。
- 后续建议：Trae 可继续验证客户端读取。
```

### 7.2 修改前

AI IDE 必须检查：

- 是否有未读 ledger 事件。
- 是否有重叠的 `locks/*.lock.json`。
- 计划修改文件是否与其他 AI IDE 最近修改范围重叠。

如果有重叠风险，先提示用户，不直接改。

### 7.3 修改后

AI IDE 必须更新：

- `.ai-sync/ledger.jsonl`：追加事件。
- `.ai-sync/AUDIT_LOG.md`：追加人类可读摘要。
- `.ai-sync/PROJECT_STATE.md`：更新当前状态。
- `.ai-sync/cursors/<ai-ide-id>.json`：推进自己的读取版本。

## 8. 在 `news` 项目中的推荐落地

以 `H:\AIcode\Trae\news` 为例：

Trae 私有使能目录：

```text
H:\AIcode\Trae\news\.trae\skills\dual-agent-sync\SKILL.md
```

Codex 私有使能目录：

```text
H:\AIcode\Trae\news\.codex\skills\dual-agent-sync\SKILL.md
```

项目共享同步目录：

```text
H:\AIcode\Trae\news\.ai-sync\
```

多个 AI IDE 共同更新：

```text
H:\AIcode\Trae\news\.ai-sync\ledger.jsonl
H:\AIcode\Trae\news\.ai-sync\AUDIT_LOG.md
H:\AIcode\Trae\news\.ai-sync\PROJECT_STATE.md
H:\AIcode\Trae\news\.ai-sync\locks\*.lock.json
```

各 AI IDE 只更新自己的 cursor：

```text
H:\AIcode\Trae\news\.ai-sync\cursors\trae-main.json
H:\AIcode\Trae\news\.ai-sync\cursors\codex-main.json
```

## 9. 为什么需要 `.codex` 和 `.trae`

`.codex` 和 `.trae` 是不同 AI IDE 的项目级配置/skill 目录。

原因：

- 不同 AI IDE 对 skill 的加载路径可能不同。
- 让每个 AI IDE 都能在当前项目内找到自己的 skill 定义。
- 避免依赖全局安装，保证项目迁移后仍能带着协作规则走。

重要边界：

- `.codex` 不是共享账本。
- `.trae` 不是共享账本。
- 真正跨 IDE 共享的是 `.ai-sync`。

## 10. 初始化一个新项目

在新项目根目录执行或等效复制：

```powershell
Copy-Item -Path "H:\AIcode\Trae\skill\dual-agent-sync-skill\templates\.ai-sync" -Destination "<project-root>\.ai-sync" -Recurse
```

为 Trae 安装项目级 skill：

```powershell
New-Item -ItemType Directory -Force -Path "<project-root>\.trae\skills\dual-agent-sync"
Copy-Item -Path "H:\AIcode\Trae\skill\dual-agent-sync-skill\.trae\skills\dual-agent-sync\SKILL.md" -Destination "<project-root>\.trae\skills\dual-agent-sync\SKILL.md"
```

为 Codex 安装项目级 skill：

```powershell
New-Item -ItemType Directory -Force -Path "<project-root>\.codex\skills\dual-agent-sync"
Copy-Item -Path "H:\AIcode\Trae\skill\dual-agent-sync-skill\.trae\skills\dual-agent-sync\SKILL.md" -Destination "<project-root>\.codex\skills\dual-agent-sync\SKILL.md"
```

然后为每个 AI IDE 创建自己的 cursor。

## 11. 试用验证流程

### 11.1 Trae 写入测试事件

Trae 使用 `trae-main` 作为 AI IDE ID，向 `.ai-sync/ledger.jsonl` 追加一条测试事件。

示例摘要：

```text
测试skill同步更新机制，代码和文档没有任何变化
```

### 11.2 Codex 读取测试事件

Codex 下次开始任务时应读取自己的 cursor，发现未读版本，并打印协作同步审计。

预期审计：

```markdown
**协作同步审计**
- 来源 AI IDE：trae-main
- 版本：v0002
- 摘要：测试skill同步更新机制，代码和文档没有任何变化
```

## 12. 版本说明

本文档版本：`1.0`

适用范围：

- 项目级安装。
- 多 AI IDE 协作。
- Trae、Codex、Cursor、Cline、Windsurf 等可读取项目文件的 AI IDE。

核心原则：

- skill 私有使能目录按 AI IDE 分开。
- `.ai-sync` 是项目唯一共享协作目录。
- `ledger.jsonl` 是机器可读事实源。
- `AUDIT_LOG.md` 是人类可读审计源。
- cursor 是每个 AI IDE 的私有读取进度。
- lock 是声明式软锁，不是强制文件锁。
