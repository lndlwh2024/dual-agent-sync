# dual-agent-sync skill 使用说明书 (MANUAL.md)

本文档指导你如何在一个模拟项目中试用 `dual-agent-sync` skill，体验两个 AI IDE 协同工作的完整流程。

## 1. 准备模拟项目

首先，我们需要一个用于协作的“目标项目”。

1.  **创建项目目录**：在任意位置创建一个新的空目录，例如 `H:\AIcode\Trae\test-collab-project`。

2.  **复制同步模板**：将 `dual-agent-sync-skill` 项目中的 `templates\.ai-sync` 目录复制到你的模拟项目中，并重命名为 `.ai-sync`。

    ```powershell
    # 在 PowerShell 中执行
    Copy-Item -Path "H:\AIcode\Trae\skill\dual-agent-sync-skill\templates\.ai-sync" -Destination "H:\AIcode\Trae\test-collab-project\.ai-sync" -Recurse
    ```

现在，你的 `test-collab-project` 应该包含一个 `.ai-sync` 目录，里面有 `ledger.jsonl` 等模板文件。

## 2. 定义 AI IDE 身份

为了模拟两个 AI 协作，我们为它们设定身份 ID：

*   `ai-ide-alpha`
*   `ai-ide-bravo`

## 3. 模拟协作流程

我们将轮流扮演 `alpha` 和 `bravo`，在 `test-collab-project` 中进行操作。

### 第 1 步：Alpha 的首次工作

**场景**：`alpha` 接到新需求，要在项目中创建一个新模块。

1.  **调用 skill (检查更新)**：作为 `alpha`，在任务开始前，先调用 skill 读取更新。
    *   **输入给 AI 的指令**：“使用 `dual-agent-sync` skill，在 `H:\AIcode\Trae\test-collab-project` 项目中检查更新。我的 AI IDE ID 是 `ai-ide-alpha`。”
    *   **预期行为**：
        *   AI 会在 `.ai-sync/cursors/` 目录下创建 `ai-ide-alpha.json`，内容为 `{"last_read_version": "v0000"}`。
        *   AI 读取 `.ai-sync/ledger.jsonl`，发现只有 `v0000` (模板)，没有新变更。
        *   AI 回复你：“`ai-ide-alpha` 已是最新状态，没有来自其他 AI 的更新。”

2.  **模拟开发**：让 `alpha` 在项目中创建一个文件。
    *   **输入给 AI 的指令**：“在 `H:\AIcode\Trae\test-collab-project` 中创建一个新文件 `module-a.js`，内容为 `console.log("Module A loaded by Alpha");`。”

3.  **调用 skill (记录变更)**：工作完成后，让 `alpha` 记录这次变更。
    *   **输入给 AI 的指令**：“使用 `dual-agent-sync` skill，记录刚才的变更。需求是‘创建模块A’，文件是`module-a.js`。我的 ID 是 `ai-ide-alpha`。”
    *   **预期行为**：
        *   AI 会在 `.ai-sync/ledger.jsonl` 中追加一条 `v0001` 的新事件。
        *   AI 会更新 `.ai-sync/AUDIT_LOG.md` 和 `PROJECT_STATE.md`。
        *   AI 会更新 `cursors/ai-ide-alpha.json`，将其 `last_read_version` 更新为 `v0001`。
        *   AI 回复你：“已记录版本 `v0001`。”

### 第 2 步：Bravo 同步并继续工作

**场景**：现在切换到 `bravo` 的视角，它需要接手项目。

1.  **调用 skill (检查更新)**：作为 `bravo`，在任务开始前，先调用 skill 读取更新。
    *   **输入给 AI 的指令**：“使用 `dual-agent-sync` skill，在 `H:\AIcode\Trae\test-collab-project` 项目中检查更新。我的 AI IDE ID 是 `ai-ide-bravo`。”
    *   **预期行为**：
        *   AI 会创建 `cursors/ai-ide-bravo.json`。
        *   AI 读取 `ledger.jsonl`，发现 `v0001` 是 `bravo` 未读的。
        *   **AI 会在聊天窗口打印审计日志**，告知你收到了来自 `alpha` 的更新。
        *   AI 读取 `v0001` 事件中提到的 `module-a.js` 文件以了解具体变更。
        *   AI 更新 `cursors/ai-ide-bravo.json`，将其 `last_read_version` 更新为 `v0001`。

2.  **模拟开发**：让 `bravo` 修改 `module-a.js`。
    *   **输入给 AI 的指令**：“在 `H:\AIcode\Trae\test-collab-project` 中，修改 `module-a.js` 的内容为 `console.log("Module A enhanced by Bravo");`。”

3.  **调用 skill (记录变更)**：工作完成后，让 `bravo` 记录变更。
    *   **输入给 AI 的指令**：“使用 `dual-agent-sync` skill 记录变更，需求是‘增强模块A’。我的 ID 是 `ai-ide-bravo`。”
    *   **预期行为**：
        *   AI 在 `ledger.jsonl` 中追加 `v0002` 事件。
        *   AI 更新 `AUDIT_LOG.md` 和 `PROJECT_STATE.md`。
        *   AI 更新 `cursors/ai-ide-bravo.json` 至 `v0002`。

### 第 3 步：Alpha 同步 Bravo 的工作

**场景**：切回 `alpha` 视角，看看它是否能收到 `bravo` 的更新。

1.  **调用 skill (检查更新)**：
    *   **输入给 AI 的指令**：“使用 `dual-agent-sync` skill 检查 `H:\AIcode\Trae\test-collab-project` 的更新。我的 ID 是 `ai-ide-alpha`。”
    *   **预期行为**：
        *   AI 读取 `ledger.jsonl`，发现 `v0002` 是 `alpha` 未读的。
        *   AI 在聊天窗口打印 `v0002` 的审计日志。
        *   AI 更新 `cursors/ai-ide-alpha.json` 至 `v0002`。

## 4. 总结

通过以上步骤，你可以验证 `dual-agent-sync` skill 的核心功能：

- **版本化变更**：`ledger.jsonl` 记录了每一次工作的完整上下文。
- **增量同步**：每个 AI IDE 只读取自己未读的变更，而非全量扫描。
- **透明审计**：当一个 AI IDE 的工作被另一个 AI IDE 读取时，用户会在聊天中收到明确通知。
- **状态隔离**：每个 AI IDE 的读取进度（cursor）是独立维护的。

你可以继续这个流程，模拟更复杂的场景，如文件冲突、并行开发等，来检验 skill 的完整性。