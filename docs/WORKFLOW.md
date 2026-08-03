# Workflow

## 1. Initialize A Target Repository

Copy `templates/.ai-sync/` into the target repository root as `.ai-sync/`.

Assign every AI IDE a stable ID:

- `trae-main`
- `cursor-rpa`
- `vscode-agent-a`

## 2. Start Work

The AI IDE invokes `dual-agent-sync`.

It determines the current session ID for this conversation window.

It reads its cursor file and locates the current session's entry. If no entry exists (new window), it performs a full read of the ledger. If an entry exists with `last_read_line`, it verifies the version at that line and reads incrementally from `last_read_line + 1`. If verification fails, it falls back to a full read.

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
