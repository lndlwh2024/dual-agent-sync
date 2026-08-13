# dual-agent-sync skill 使用说明书 V2.0


## 一、 整体文档与物理结构全景（附关联逻辑说明）

很多开发者在接触模块化设计时会有疑问：为什么 Git 信息只记录在 `collab`，而 `codegraph` 里没有？
这是因为整个双语协作系统遵循**“数据来源唯一（Single Source of Truth）”**原则：
- **物理 `.git`** 只有一个，必须在项目的最外层（根目录），管控包含代码和 `.ai-sync/` 在内的所有文件。
- **Git 锚点（Hash）记录**也只存一份，放在 `collab/ledger.jsonl` 中。
- `codegraph` 模块只需通过版本号（`trigger_version`）与 `collab` 进行**外键关联**，就能顺藤摸瓜找到对应的 Git 记录，无需在图谱中冗余存储 Git 信息。

以下是带有完整中文说明的系统结构树，为您清晰展示各模块如何联动：

```text
[项目根目录] 
 │
 ├─ .git/                           ← 【真实的物理 Git 目录】
 │                                     管控整个项目（含代码和下面的同步数据）的回滚与版本。
 │
 ├─ src/, docs/, etc.               ← 您的业务代码
 │
 └─ .ai-sync/                       ← 🎯 双端协作系统的统一存放点
     │
     ├─ collab/                     ← ════ 【模块一：项目协作追踪】 ════
     │  │                             （回答：谁改了什么、什么时候改的、对应哪个 Git 快照）
     │  │
     │  ├─ ledger.jsonl             ← 📓 核心账本（事件流水）
     │  │                              ★ 这是整个系统唯一的“时间与事实源”！
     │  │                              [内含字段]
     │  │                              - "version": "v0005"
     │  │                              - "git.head_commit": "abc1234" ← 将协作版本与 Git 物理快照绑定的唯一指针！
     │  │
     │  ├─ AUDIT_LOG.md             ← 供人类阅读的账本摘要 Markdown
     │  ├─ PROJECT_STATE.md         ← 供人类阅读的当前项目状态
     │  ├─ cursors/                 ← 各 AI IDE 的阅读游标（读到了哪一行）
     │  └─ locks/                   ← 协作软锁（防文件编辑冲突）
     │
     └─ codegraph/                  ← ════ 【模块二：代码架构图谱】 ════
        │                             （回答：当前的业务文件结构和依赖关系是怎样的）
        │                             ★ 被动更新模块：跟随 collab 事件而变化
        │
        ├─ graph.json               ← 🗺️ 当前最新的全项目文件关系图谱（直接覆盖更新）
        │
        ├─ graph.changelog.jsonl    ← 📝 图谱历史变更日志
        │                              [内含字段]
        │                              - "trigger_version": "v0005"
        │                              ★ 外键机制：图谱本身不记录 Git Hash！它记录 trigger_version。
        │                              当需要回滚图谱时，系统看到 v0005，就会去上面的 ledger.jsonl
        │                              找 v0005 对应的 "git.head_commit"，从而指挥最外层的 .git 恢复文件。
        │
        └─ locks/                   ← 图谱写入互斥锁（确保图谱更新不发生并发覆盖）
```


本文档是 `dual-agent-sync` 的场景版使用说明。核心目标是让多个 AI IDE 在同一个项目中同步“个体进展、问题判断、代码/文档变化、风险和下一步”，而不是让下一个 AI 重新全量阅读项目。

## 1. 总原则

- 每个 AI IDE 默认已经了解项目全景，只需要同步其他成员的最新个体进展。
- 已解决问题记录交付结果，允许简洁流水账。
- 未解决问题记录诊断病历，禁止聊天流水账。
- 推翻旧结论时必须显式纠错，避免旧结论继续误导后续 AI。
- 共享事实源是 `.ai-sync/collab/ledger.jsonl`，人类阅读入口是 `.ai-sync/collab/AUDIT_LOG.md`。
- 每个 AI IDE 只推进自己的 cursor，不替其他 AI IDE 标记已读。
- 后续 `git push` 必须得到用户明确授权。

## 2. 项目目录分工

### 2.1 AI IDE 私有使能目录

这些目录只用于让对应 AI IDE 加载 skill 规则，不记录项目同步事件。

| AI IDE | 私有使能目录 | 作用 |
| --- | --- | --- |
| Trae | `.trae/skills/dual-agent-sync/SKILL.md` | Trae 项目级 skill 入口 |
| Codex | `.codex/skills/dual-agent-sync/SKILL.md` | Codex 项目级 skill 入口 |
| Cursor | `.cursor/skills/dual-agent-sync/SKILL.md` | Cursor 项目级 skill 入口 |
| Cline | `.cline/skills/dual-agent-sync/SKILL.md` | Cline 项目级 skill 入口 |
| Windsurf | `.windsurf/skills/dual-agent-sync/SKILL.md` | Windsurf 项目级 skill 入口 |

规则：

- 私有使能目录可以复制同一份 `SKILL.md`。
- 私有使能目录不作为跨 IDE 同步账本。
- AI IDE 不应把协作事件写入 `.trae/`、`.codex/`、`.cursor/` 等私有目录。

### 2.2 项目共享同步目录

所有 AI IDE 共同读写的唯一同步目录：

```text
<project-root>/.ai-sync/
```

推荐结构：

```text
.ai-sync/
├─ ledger.jsonl
├─ AUDIT_LOG.md
├─ PROJECT_STATE.md
├─ cursors/
│  ├─ trae-main.json      # 单个 IDE 对应一个文件，内部记录该 IDE 下多会话的同步进度
│  ├─ codex-main.json
│  └─ <ai-ide-id>.json
└─ locks/
   ├─ <scope>.lock.json
   └─ .gitkeep
```

## 3. 共享文件职责

| 文件 | 类型 | 谁写 | 作用 |
| --- | --- | --- | --- |
| `.ai-sync/collab/ledger.jsonl` | 共写文件 | 所有 AI IDE 追加 | 机器可读事实源，每行一个版本事件 |
| `.ai-sync/collab/AUDIT_LOG.md` | 共写文件 | 所有 AI IDE 追加 | 人类可读审计摘要 |
| `.ai-sync/collab/PROJECT_STATE.md` | 共写文件 | 所有 AI IDE 更新 | 项目协作状态快照 |
| `.ai-sync/collab/cursors/<ai-ide-id>.json` | 私有进度文件 | 对应 AI IDE | 记录该 AI IDE 已读到哪个版本 |
| `.ai-sync/collab/locks/*.lock.json` | 共写声明文件 | 所有 AI IDE | 声明准备修改的模块/文件范围 |

## 4. AI IDE 命名规范

推荐格式：

```text
<ide-name>-<role-or-instance>
```

示例：

- `trae-main`
- `codex-main`
- `cursor-rpa`
- `cline-qa`
- `windsurf-ui`

规则：

- 使用小写英文、数字和连字符。
- 不使用空格、中文或特殊符号。
- 同一项目内 AI IDE ID 不得重复。
- cursor 文件名必须与 AI IDE ID 一致，例如 `.ai-sync/collab/cursors/trae-main.json`。

### 4.1 会话 ID 规范

每个 AI IDE 的对话窗口需要一个会话 ID，用于在 cursor 文件中独立追踪每个窗口的读取位置。

会话 ID 来源：

- 如果 IDE 提供内置 conversation ID（如 UUID），直接使用。
- 如果 IDE 无内置 ID，由 skill 自动生成。

自动生成规则：

- 格式：`<IDE大写>_<YYYYMMDDHHmm>_<字母><4位数字>`
- 示例：`CODEX_202608031701_A0001`
- 序号从 `A0001` 递增到 `A9999`，满后切换为 `B0001`（使用当前真实时间戳），依次类推直到 `Z9999`，然后循环回 `A`（使用新时间戳）。
- 序号在当前项目的 cursor 文件内隔离递增，不同项目互不影响。

确定下一个自动生成 ID 的方法：读取当前 cursor 文件，找到所有匹配本 IDE 前缀的会话 key，取最大字母和序号，递增生成。

## 5. 通用写入流程

每次 AI IDE 开始任务前：

1. 确定当前对话窗口的会话 ID（使用 IDE 内置 ID 或自动生成）。
2. 读取自己的 `.ai-sync/collab/cursors/<ai-ide-id>.json`，在 `sessions` 中查找当前会话 ID 的记录。
3. 如果当前会话无记录（新窗口），全量读取 `.ai-sync/collab/ledger.jsonl`。
4. 如果有记录且包含 `last_read_line`：
   a. 读取 `ledger.jsonl` 的第 `last_read_line` 行，校验 `version` 是否等于 `last_read_version`。
   b. 校验通过：从 `last_read_line + 1` 行开始增量读取。
   c. 校验失败：打印警告，回退全量读取（说明 ledger 文件可能被手动编辑）。
5. 如果有记录但无 `last_read_line`（旧版 cursor 升级），全量读取。
6. 如果发现其他 AI IDE 更新，打印协作同步审计。
7. 如果没有更新，静默继续。

每次 AI IDE 完成一段有价值工作后：

1. 选择本文第 6 节中的一个记录场景。
2. 向 `.ai-sync/collab/ledger.jsonl` 追加一条事件。
3. 向 `.ai-sync/collab/AUDIT_LOG.md` 追加人类可读摘要。
4. 更新 `.ai-sync/collab/PROJECT_STATE.md`。
5. 推进自己的 `.ai-sync/collab/cursors/<ai-ide-id>.json`：更新当前会话在 `sessions` 中的 `last_read_version`、`last_read_line`（刚写入事件所在的行号）和 `last_read_timestamp`。
6. 如有软锁，完成记录后释放自己的锁。

### 5.1 增量读取安全机制

增量读取依赖 `ledger.jsonl` 的纯追加（append-only）特性，行号与版本号存在稳定映射关系。

校验机制：每次增量读取前，先读取 `last_read_line` 所在行，验证该行的 `version` 字段是否与 cursor 中记录的 `last_read_version` 一致。

回退策略：如果校验失败（说明 ledger 被手动编辑或 repair 操作改变了行号），自动回退为全量读取，并在聊天窗口打印警告。

向后兼容：旧版 cursor 文件缺少 `last_read_line` 和 `sessions` 字段时，视为全量读取模式，不影响正常工作。

## 6. 记录场景总表

| 场景 | 适用情况 | 推荐 event_type | 是否允许流水账 | 核心记录目标 |
| --- | --- | --- | --- | --- |
| 已解决交付 | 问题明确，已更新代码/文档/配置 | `code_update`、`doc_update`、`bugfix`、`config_update`、`migration_update` | 可以简洁流水账 | 让其他 AI 知道改了什么、为何改、如何验证 |
| 未解决排查 | 问题未解决，处于多轮诊断 | `analysis_handoff` | 不允许 | 形成当前有效诊断病历 |
| 纠错诊断 | 新证据推翻旧结论 | `analysis_handoff`、`risk_notice` | 不允许 | 明确旧结论失效，新结论生效 |
| 方案计划 | 只有方案、计划、边界或门禁状态 | `planning` | 可以简洁流水账 | 同步决策、边界、待确认项 |
| 阶段交接 | 一个阶段结束，需要其他 AI 接手 | `handoff` | 可以结构化摘要 | 同步完成项、未完成项、风险和接手点 |
| 部署运行 | CI、部署、线上/预发运行状态变化 | `deployment_update`、`risk_notice` | 可以简洁流水账 | 同步环境、结果、证据、回滚/后续验证 |
| 冲突风险 | 发现并行修改、锁冲突、未读重叠变更 | `conflict_notice` | 不建议 | 说明冲突范围和决策需求 |
| 测试验证 | 专门补充测试结果或验证证据 | `test_update` | 可以简洁流水账 | 同步测试范围、结果、未测风险 |

## 7. 场景一：已解决交付

### 7.1 触发条件

- 问题已经明确。
- 已经完成代码、文档、配置、迁移或测试更新。
- 有明确的验证结果或明确说明未验证内容。

### 7.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

可选更新：

- `.ai-sync/collab/locks/*.lock.json`，如果此前创建了锁，完成后删除。

### 7.3 ledger 记录内容

必须包含：

- `event_type`：`code_update`、`doc_update`、`bugfix`、`config_update` 或 `migration_update`。
- `git.branch`、`git.base_commit`、`git.head_commit`：如尚未提交，写 `null` 并在摘要中说明。
- `scope.files_changed`：代码/配置/迁移文件列表（推荐记录具体的修改行号范围，如 `{"file": "src/main.py", "lines": ["10-20"]}`，以实现后续 AI 的按需精准加载，降低 Token 消耗）。
- `scope.docs_changed`：文档文件列表。
- `context.requirement_background`：需求背景。
- `context.problem_background`：问题背景或触发原因。
- `context.solution`：本次修改内容。
- `context.current_status`：当前状态。
- `context.remaining_issues`：遗留问题。
- `context.next_steps`：后续动作。
- `context.risks`：风险。
- `verification.tests_run`：已执行验证。
- `verification.tests_not_run`：未验证项及原因。
- `summary`：一句话摘要。

### 7.4 记录方式

允许简洁流水账，但不能缺失关键事实。

推荐摘要：

```text
修复 <问题>，更新 <文件/模块>，验证 <测试> 通过，剩余风险 <风险>。
```

### 7.5 AUDIT_LOG 写法

```markdown
## 2026-07-09 18:00:00 +08:00 - v0004 - trae-main

- Project: news2-service
- Type: bugfix
- Summary: 修复 Mode1 runtime 键名不一致。
- Files: src/lib/newsAideConfig.ts
- Docs: LLM-RPA-Bot-news_aide_V1/DOCS/SDD.md
- Git: master abc123 -> def456
- Tests: npm run build passed
- Risks: 仍需实机 RPA 验证。
```

## 8. 场景二：未解决排查

### 8.1 触发条件

- 问题还没有解决。
- 已经进行了复杂分析、日志阅读、代码阅读或多轮假设验证。
- 即使没有修改代码和文档，该分析结论对其他 AI IDE 有价值。

### 8.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

通常不更新：

- `scope.files_changed` 和 `scope.docs_changed`，除非排查过程中确实修改了文件。

### 8.3 禁止流水账

不要记录完整聊天过程。

不要写：

```text
第一轮怀疑 A，第二轮怀疑 B，第三轮又怀疑 C，后来发现 D，接着看了 E...
```

应该写成诊断病历：

- 当前症状是什么。
- 当前最新有效判断是什么。
- 支撑证据是什么。
- 哪些假设已经排除。
- 哪些假设仍待验证。
- 下一位 AI 应该先做什么。
- 哪些检查不要重复。

### 8.4 diagnostic_record 结构

`analysis_handoff` 必须优先使用 `diagnostic_record`。

```json
{
  "diagnostic_record": {
    "status": "unresolved",
    "symptom": "用户可见现象或失败表现",
    "current_best_conclusion": "当前最新有效判断，接手 AI 优先相信这一条",
    "confidence": "low|medium|high",
    "evidence": [
      {
        "source": "日志/代码/截图/命令/用户描述",
        "finding": "关键发现",
        "supports": "它支持哪个结论"
      }
    ],
    "ruled_out": [
      {
        "hypothesis": "已排除假设",
        "reason": "排除原因"
      }
    ],
    "open_hypotheses": [
      {
        "hypothesis": "仍待验证假设",
        "next_check": "下一步如何验证"
      }
    ],
    "next_actions": [
      "接手 AI 应优先做什么"
    ],
    "do_not_repeat": [
      "已经做过且无效的检查，避免重复消耗"
    ],
    "handoff_prompt": "给下一个大模型的精简提示词式上下文"
  }
}
```

### 8.5 handoff_prompt 写法

`handoff_prompt` 应直接适合给下一位 AI 使用。

推荐格式：

```text
你正在接手 <问题>。当前最新判断是 <结论>。关键证据包括 <证据>。已排除 <假设>。不要重复 <无效检查>。下一步优先验证 <检查项>。如需改代码，优先查看 <文件/模块>。
```

### 8.6 AUDIT_LOG 写法

```markdown
## 2026-07-09 18:20:00 +08:00 - v0005 - codex-main

- Project: news2-service
- Type: analysis_handoff
- Summary: Mode1 提交后无回传，当前更可能是 callback 未触发而非前端渲染问题。
- Files Analyzed: LLM-RPA-Bot-news_aide_V1/app/services/callback_client.py, supabase/functions/mode1-callback/index.ts
- Current Conclusion: callback 链路需要优先验证。
- Ruled Out: 前端 Mode1ReportRenderer 不是当前首要原因。
- Next: Trae 优先检查客户端 callback 日志和 Edge Function 日志。
- Do Not Repeat: 已检查前端历史报告渲染路径，无直接证据指向渲染层。
```

## 9. 场景三：纠错诊断

### 9.1 触发条件

- 新一轮排查推翻了旧结论。
- 旧 ledger 版本中的判断可能误导其他 AI。
- 需要明确“当前应采用哪个结论”。

### 9.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

### 9.3 ledger 记录内容

使用 `event_type: "analysis_handoff"` 或 `event_type: "risk_notice"`。

必须包含：

```json
{
  "diagnostic_record": {
    "status": "corrected",
    "supersedes_version": "v0005",
    "invalidated_assumption": "被推翻的旧假设",
    "correction_reason": "为什么旧假设失效",
    "current_best_conclusion": "当前最新有效结论",
    "evidence": [],
    "next_actions": [],
    "handoff_prompt": "提醒下一位 AI 不要继续沿用旧结论"
  }
}
```

### 9.4 记录方式

不要写成“又发现了一个新情况”。

必须明确：

- 旧结论来自哪个版本。
- 旧结论为什么失效。
- 新结论是什么。
- 接手 AI 应该忽略哪些旧判断。

### 9.5 AUDIT_LOG 写法

```markdown
## 2026-07-09 18:40:00 +08:00 - v0006 - trae-main

- Project: news2-service
- Type: analysis_handoff
- Summary: 纠正 v0005：Mode1 无回传不是 callback 未触发，而是客户端未进入上传分支。
- Supersedes: v0005
- Invalidated Assumption: callback 链路是首要问题。
- Current Conclusion: 优先检查客户端提交后 B1 轮询和上传前校验。
- Next: Codex 不要继续排查前端渲染和 Edge Function，先看客户端日志。
```

## 10. 场景四：方案计划

### 10.1 触发条件

- 只确认了方案、计划、边界或门禁状态。
- 尚未修改代码或文档。

### 10.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

### 10.3 ledger 记录内容

使用 `event_type: "planning"`。

必须包含：

- 已确认方案。
- 未确认问题。
- 当前门禁状态。
- 文件范围预估。
- 下一步动作。
- 风险。

### 10.4 AUDIT_LOG 写法

```markdown
## 2026-07-09 19:00:00 +08:00 - v0007 - codex-main

- Project: news2-service
- Type: planning
- Summary: 已确认 Mode1 runtime 键名修复方案，等待确认开发。
- Gate: 已确认方案，未确认开发。
- Scope: src/lib/newsAideConfig.ts, V1 DOCS
- Next: 等用户确认开发后实施。
```

## 11. 场景五：阶段交接

### 11.1 触发条件

- 一个 AI IDE 完成阶段工作，需要另一个 AI IDE 接手。
- 长任务中断、切换模型、切换 IDE 或进入下一阶段。

### 11.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

### 11.3 ledger 记录内容

使用 `event_type: "handoff"`。

必须包含：

- 已完成。
- 未完成。
- 当前阻塞。
- 下一步建议。
- 风险。
- 相关文件。
- Git commit 或未提交状态。

### 11.4 AUDIT_LOG 写法

```markdown
## 2026-07-09 19:20:00 +08:00 - v0008 - trae-main

- Project: news2-service
- Type: handoff
- Summary: 完成 V1 客户端文档阅读，发现 Mode1 runtime 键名契约风险。
- Completed: V1 DOCS 和关键代码只读梳理。
- Pending: 尚未修改代码。
- Next: Codex 可复核前端配置写入字段。
- Risks: 前端保存 m23_*，客户端只读 mode1_*。
```

## 12. 场景六：部署运行状态

### 12.1 触发条件

- CI、部署、migration、Edge Function、Vercel、Supabase 或运行时状态发生变化。
- 需要其他 AI IDE 了解环境状态。

### 12.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

### 12.3 ledger 记录内容

使用 `event_type: "deployment_update"` 或 `event_type: "risk_notice"`。

必须包含：

- 环境：local、pre-release、production。
- 操作：deploy、migration、rollback、manual verification。
- 结果：success、failed、partial。
- 证据：run id、URL、日志摘要。
- 影响范围。
- 回滚或下一步验证。

### 12.4 AUDIT_LOG 写法

```markdown
## 2026-07-09 19:40:00 +08:00 - v0009 - codex-main

- Project: news2-service
- Type: deployment_update
- Summary: Supabase migration 部署成功。
- Environment: pre-release
- Evidence: GitHub Actions run 123456 passed
- Git: master abc123 -> def456
- Next: Trae 可继续客户端联调。
- Risks: 生产未部署。
```

## 13. 场景七：冲突风险

### 13.1 触发条件

- 发现未读事件涉及自己准备修改的文件。
- 发现 `locks/` 中存在重叠声明。
- Git status 显示非本人改动，且与当前任务相关。

### 13.2 要写哪些文件

一般先不写代码。

可写入：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

### 13.3 ledger 记录内容

使用 `event_type: "conflict_notice"`。

必须包含：

- 冲突文件或模块。
- 涉及版本或锁文件。
- 当前 AI 的计划。
- 需要用户决策的问题。

### 13.4 AUDIT_LOG 写法

```markdown
## 2026-07-09 20:00:00 +08:00 - v0010 - trae-main

- Project: news2-service
- Type: conflict_notice
- Summary: Trae 准备修改 mode1_runner.py，但 codex-main 已声明同文件软锁。
- Overlap: LLM-RPA-Bot-news_aide_V1/app/engine/mode1_runner.py
- Decision Needed: 等 Codex 完成、缩小范围，或由用户手工合并。
```

## 14. 场景八：测试验证

### 14.1 触发条件

- 只补充测试结果，没有新的代码或文档变更。
- 实机验证、浏览器验证、CI 复跑或日志确认有同步价值。

### 14.2 要写哪些文件

必须更新：

- `.ai-sync/collab/ledger.jsonl`
- `.ai-sync/collab/AUDIT_LOG.md`
- `.ai-sync/collab/PROJECT_STATE.md`
- `.ai-sync/collab/cursors/<ai-ide-id>.json`

### 14.3 ledger 记录内容

使用 `event_type: "test_update"`。

必须包含：

- 测试对象。
- 测试环境。
- 测试命令或操作。
- 结果。
- 未测项。
- 对下一步的影响。

### 14.4 AUDIT_LOG 写法

```markdown
## 2026-07-09 20:20:00 +08:00 - v0011 - codex-main

- Project: news2-service
- Type: test_update
- Summary: npm run build 通过，RPA 实机未测。
- Tests Run: npm run build
- Tests Not Run: real browser RPA
- Result: pass
- Next: Trae 可安排实机 Mode1 验证。
```

## 15. 标准 ledger 事件模板

```json
{
  "version": "v0001",
  "timestamp": "2026-07-09T20:30:00+08:00",
  "project": "project-name",
  "source_ai_ide": "trae-main",
  "event_type": "code_update",
  "git": {
    "branch": "master",
    "base_commit": null,
    "head_commit": null
  },
  "scope": {
    "modules": [],
    "files_changed": [
      {
        "file": "path/to/file",
        "lines": ["10-20"]
      }
    ],
    "docs_changed": [],
    "files_analyzed": []
  },
  "context": {
    "requirement_background": "",
    "problem_background": "",
    "solution": "",
    "current_status": "",
    "remaining_issues": [],
    "next_steps": [],
    "risks": [],
    "diagnostic_record": null
  },
  "verification": {
    "tests_run": [],
    "tests_not_run": [],
    "result": ""
  },
  "summary": ""
}
```

## 16. 协作同步审计输出

当 AI IDE 读取到其他 AI IDE 的未读事件时，必须在聊天窗口打印：

```markdown
**协作同步审计**
- 来源 AI IDE：<source_ai_ide>
- 版本：<version>
- 类型：<event_type>
- 时间：<timestamp>
- 摘要：<summary>
- 影响文件：<files_changed/docs_changed/files_analyzed>
- 当前状态：<current_status 或 diagnostic_record.current_best_conclusion>
- 后续建议：<next_steps 或 diagnostic_record.next_actions>
```

如果读取的是 `analysis_handoff`，必须优先展示：

- 当前最新有效结论。
- 被排除假设。
- 下一步检查。
- 不要重复的检查。
- handoff prompt。

## 17. 在 news 项目中的推荐落地

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

## 18. 版本说明

本文档版本：`1.1`

本版本重点：

- 改为按场景说明记录方式。
- 明确每个场景要写哪些文件。
- 明确已解决问题允许简洁流水账。
- 明确未解决排查必须使用诊断病历。
- 明确推翻旧结论时必须写纠错记录。
- 明确 `handoff_prompt` 应适合直接给下一位大模型使用。
