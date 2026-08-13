# Workflow V2.0

## 1. Initialize A Target Repository

Copy 	emplates/.ai-sync/ into the target repository root as .ai-sync/.

Assign every AI IDE a stable ID:

- 	rae-main
- cursor-rpa
- scode-agent-a

## 2. Start Work & V2.0 Migration Check

The AI IDE invokes dual-agent-sync.

First, it checks for V2.0 structural compatibility. If .ai-sync/ledger.jsonl exists (V1.x legacy structure), it triggers the **Strong Transactional Migration** to upgrade the directory into collab/ and codegraph/ modules.

It determines the current session ID for this conversation window.

It reads its cursor file from .ai-sync/collab/cursors/ and locates the current session's entry. If no entry exists (new window), it performs a full read of the ledger (.ai-sync/collab/ledger.jsonl). If an entry exists with last_read_line, it verifies the version at that line and reads incrementally from last_read_line + 1. If verification fails, it falls back to a full read.

Next, it reads the current code architecture graph from .ai-sync/codegraph/graph.json to understand the project structure.

If it detects another AI IDE's update, it prints a chat audit notice.

## 3. Plan And Lock

Before editing, create or inspect soft locks under .ai-sync/collab/locks/.

Soft locks are advisory. They reduce accidental overlap but do not replace Git conflict handling.

## 4. Implement

Work on the smallest safe file scope.

Preserve unrelated changes.

## 5. Record Update (Atomic Dual-Update)

After implementation, the agent must update both modules:
1. **Collab**: Append a ledger event to collab/ledger.jsonl (including the graph_impact field) and update the human-readable logs (AUDIT_LOG.md and PROJECT_STATE.md).
2. **Codegraph**: Acquire the graph write lock (codegraph/locks/codegraph.lock.json), incrementally update the nodes/edges in codegraph/graph.json, append a diff summary to codegraph/graph.changelog.jsonl, and release the lock.

## 6. Commit Anchor

When a Git commit exists, record the commit SHA in the event or append a follow-up event. This ties the collaborative ledger, the code graph, and the codebase together for safe rollbacks.

## 7. Handoff

The next AI IDE starts by reading all versions after its cursor. It must not jump directly to the latest version without reading intermediate events.