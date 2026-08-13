---
name: dual-agent-sync
description: Protocol for seamless collaboration between multiple AI IDEs working on the same project using V2.0 split-architecture.
---

# Dual-Agent-Sync V2.0

You are operating under the Dual-Agent-Sync protocol V2.0. This allows you to safely collaborate with other AI IDEs (Trae, Cursor, Codex, Windsurf, Cline).

## 0. V2.0 Migration Check (IMPORTANT)
Before starting ANY task, verify the project's .ai-sync/ directory.
If .ai-sync/ledger.jsonl exists in the ROOT of .ai-sync/ (i.e. not in collab/), this project is on V1.x.
You MUST trigger the **Strong Transactional Migration**:
1. Try acquiring .ai-sync/migration.lock. (Wait if locked by others).
2. Ask the user to commit git changes if working directory isn't clean.
3. Backup all legacy files to .ai-sync/.migration_backup_v1/.
4. Create .ai-sync/collab/, .ai-sync/collab/cursors/, .ai-sync/collab/locks/.
5. Move ledger.jsonl, AUDIT_LOG.md, PROJECT_STATE.md to collab/. Move old cursors to collab/cursors/.
6. Create .ai-sync/codegraph/ and .ai-sync/codegraph/locks/.
7. Write migration_update event to collab/ledger.jsonl.
8. Delete backup. Migration success.

## 1. Start Of Task Sync
Every time the user gives you a new task:
1. Identify your i_ide_id (e.g. 	rae-main).
2. Read your cursor from .ai-sync/collab/cursors/<ai-ide-id>.json.
3. Check collab/ledger.jsonl from your last_read_line onwards.
4. Read .ai-sync/codegraph/graph.json to understand the whole project architecture.
5. Notify the user of updates made by other agents.
6. Check .ai-sync/collab/locks/ for any soft locks on files you intend to edit.

## 2. After Changes (Dual-Update)
When you finish a task, you MUST update BOTH domains atomically:

**A. Project Collaboration (collab/)**
- Append a new event to collab/ledger.jsonl. It must include event_type, scope, context, graph_impact, summary.
- graph_impact MUST declare exactly what nodes/edges were added/removed/modified.
- Update collab/AUDIT_LOG.md (human readable summary).
- Update collab/PROJECT_STATE.md (current snapshot).
- Acquire cursor write lock (collab/locks/cursor-<id>.lock.json), update your cursor file with the new line number, and release the lock.

**B. Code Architecture Graph (codegraph/)**
- Acquire graph write lock (codegraph/locks/codegraph.lock.json).
- If missing, create codegraph/graph.json by mapping all project files (nodes) and their import/require dependencies (edges). If existing, incrementally update it.
- Append a diff entry to codegraph/graph.changelog.jsonl.
- Release graph write lock.

## 3. Git Anchor
Suggest the user runs git commit to snapshot .ai-sync/ alongside the code changes.