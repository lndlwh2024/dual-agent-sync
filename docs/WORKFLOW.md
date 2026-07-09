# Workflow

## 1. Initialize A Target Repository

Copy `templates/.ai-sync/` into the target repository root as `.ai-sync/`.

Assign every AI IDE a stable ID:

- `trae-main`
- `cursor-rpa`
- `vscode-agent-a`

## 2. Start Work

The AI IDE invokes `dual-agent-sync`.

It reads its cursor, then reads all ledger events after that cursor.

If it detects another AI IDE's update, it prints a chat audit notice.

## 3. Plan And Lock

Before editing, create or inspect soft locks under `.ai-sync/locks/`.

Soft locks are advisory. They reduce accidental overlap but do not replace Git conflict handling.

## 4. Implement

Work on the smallest safe file scope.

Preserve unrelated changes.

## 5. Record Update

After implementation, append a ledger event and update the human-readable logs.

## 6. Commit Anchor

When a Git commit exists, record the commit SHA in the event or append a follow-up event.

## 7. Handoff

The next AI IDE starts by reading all versions after its cursor. It must not jump directly to the latest version without reading intermediate events.
