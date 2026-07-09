---
name: "dual-agent-sync"
description: "Synchronizes multi-AI IDE project collaboration. Invoke before shared work, after changes, or when checking updates from another AI IDE."
---

# Dual Agent Sync

## Purpose

Use this skill when multiple AI IDEs or coding agents collaborate on the same project.

The skill minimizes communication cost by maintaining a repository-local synchronization ledger, per-agent read cursors, human-readable audit logs, and precise file-level change summaries.

## When To Invoke

Invoke this skill:

- Before starting any task in a shared project.
- Before editing files that may overlap with another AI IDE.
- After completing code, documentation, configuration, test, migration, or deployment changes.
- When the user says another AI IDE has updated the project.
- When the user asks to sync, catch up, hand off, audit, or coordinate work.
- Before merging, committing, or pushing work created in a shared AI IDE workflow.

## Required Repository Files

The target project should contain:

```text
.ai-sync/
├─ ledger.jsonl
├─ AUDIT_LOG.md
├─ PROJECT_STATE.md
├─ cursors/
│  └─ <ai-ide-id>.json
└─ locks/
   └─ <module-or-file>.lock.json
```

If `.ai-sync/` is missing, ask the user whether to initialize it from the skill template before doing shared work.

## Core Rules

- **Agent Behavior Mandate**: Any AI agent utilizing this skill **MUST** treat the synchronization check as a mandatory, silent, pre-flight operation before executing any user-requested task (e.g., code modification, analysis, new feature development). If no updates are found, proceed silently. If updates from another agent are found, the agent **MUST** report them to the user as an "Audit Notice" before proceeding with the primary task.
- Treat `.ai-sync/ledger.jsonl` as append-only.
- Never delete or rewrite historical sync events unless the user explicitly approves a repair.
- Maintain one cursor file per AI IDE.
- Always read all versions after the current cursor; never skip intermediate versions.
- Prefer precise file reads based on event `files_changed` and `docs_changed`.
- Do not reread the whole repository unless the ledger is missing, corrupt, or insufficient.
- Print a chat audit notice whenever updates from another AI IDE are detected.
- Stop and ask the user before editing if unread changes overlap with intended files.
- Preserve unrelated user and AI IDE changes.

## AI IDE Identity

Each AI IDE must have a stable ID, for example:

```text
trae-main
cursor-rpa
vscode-agent-a
```

If no ID exists, ask the user to choose one.

Store the read cursor in:

```text
.ai-sync/cursors/<ai-ide-id>.json
```

Recommended cursor schema:

```json
{
  "ai_ide_id": "trae-main",
  "last_read_version": "v0000",
  "last_read_timestamp": null,
  "notes": "Set by dual-agent-sync. Do not advance manually unless repairing sync state."
}
```

## Start-Of-Task Sync

Before starting work:

1. Locate `.ai-sync/ledger.jsonl`.
2. Locate `.ai-sync/cursors/<ai-ide-id>.json`.
3. Determine the last read version for this AI IDE.
4. Read every event after that version in order.
5. Print a chat audit notice for each relevant update from another AI IDE.
6. Read only files listed in new events when context is needed.
7. Update the local cursor only after the updates are understood.

Audit notice format:

```markdown
**协作同步审计**
- 来源 AI IDE：<source_ai_ide>
- 版本：<version>
- 时间：<timestamp>
- 摘要：<summary>
- 影响文件：<files_changed/docs_changed>
- 当前状态：<current_status>
- 后续建议：<next_steps>
```

## Before Editing

Before editing files:

1. Check unread ledger events again.
2. Check `.ai-sync/locks/`.
3. If another AI IDE has a relevant active lock, ask the user whether to wait, coordinate, or proceed.
4. If intended files overlap with unread changes, stop and ask the user.

## Advisory Locking (Soft Locks)

The lock mechanism is **advisory**, not a technical file lock. It is a **declarative** protocol that relies on the compliance of all participating AI agents. This soft-lock approach is a protective measure for the workflow, designed to prevent accidental concurrent edits and to signal intent to other agents. It is not a substitute for version control but a complement to it.

### Creating a Lock

- Before starting a non-trivial change, an agent should write a `.json` file to the `.ai-sync/locks/` directory.
- The lock file should declare the `scope` (modules/files) and `intent`.

### Respecting a Lock

- Before working on a set of files, an agent **MUST** check for existing locks that overlap with its intended scope.
- If a lock exists, the agent must raise this to the user and wait for a decision.

### Releasing a Lock

- The lock file should be deleted by the creating agent after the corresponding `ledger.jsonl` event has been written and the work is considered complete.

Soft lock format:

```json
{
  "lock_id": "lock-20260708-120000-trae-main",
  "source_ai_ide": "trae-main",
  "timestamp": "2026-07-08T12:00:00+08:00",
  "scope": {
    "modules": ["mode1-runtime"],
    "files": ["src/lib/newsAideConfig.ts"]
  },
  "intent": "Update Mode1 runtime key namespace",
  "expires_at": "2026-07-08T14:00:00+08:00"
}
```

## After Changes

After completing work, append a new event to `.ai-sync/ledger.jsonl`.

Required event fields:

```json
{
  "version": "v0001",
  "timestamp": "2026-07-08T12:00:00+08:00",
  "project": "project-name",
  "source_ai_ide": "trae-main",
  "event_type": "code_update",
  "git": {
    "branch": "master",
    "base_commit": "abc123",
    "head_commit": "def456"
  },
  "scope": {
    "modules": [],
    "files_changed": [],
    "docs_changed": []
  },
  "context": {
    "requirement_background": "",
    "problem_background": "",
    "solution": "",
    "current_status": "",
    "remaining_issues": [],
    "next_steps": [],
    "risks": []
  },
  "verification": {
    "tests_run": [],
    "tests_not_run": [],
    "result": ""
  },
  "summary": ""
}
```

Also update:

- `.ai-sync/AUDIT_LOG.md`
- `.ai-sync/PROJECT_STATE.md`
- `.ai-sync/cursors/<ai-ide-id>.json`

## Versioning

Use monotonic ledger versions:

```text
v0001
v0002
v0003
```

Rules:

- New version = previous max version + 1.
- If two AI IDEs create the same next version, stop and ask the user to resolve.
- Never skip versions.
- Never mark a cursor beyond a version that has not been read.

## Event Types

Recommended event types:

- `planning`
- `code_update`
- `doc_update`
- `test_update`
- `config_update`
- `migration_update`
- `deployment_update`
- `bugfix`
- `handoff`
- `risk_notice`
- `conflict_notice`

## Conflict Handling

If conflict risk is detected:

1. Stop before editing.
2. Print the conflicting event or lock.
3. Identify overlapping files/modules.
4. Ask the user whether to sync and re-plan, continue with a narrowed scope, let the other AI IDE finish first, or manually resolve.

## Human-Visible Audit Log

Append entries like:

```markdown
## 2026-07-08 12:00:00 +08:00 - v0001 - trae-main

- Project: news2-service
- Type: code_update
- Summary: Updated Mode1 runtime key namespace.
- Files: src/lib/newsAideConfig.ts
- Git: master abc123 -> def456
- Tests: npm run build passed
- Risks: Requires client verification.
```

## PROJECT_STATE.md

Keep this file compact.

Recommended sections:

```markdown
# Project State

## Current Baseline

- Branch:
- Latest commit:
- Last sync version:
- Active AI IDEs:

## Current Work

- In progress:
- Blocked:
- Recently completed:

## Open Risks

- Risk:

## Next Steps

- Step:
```

## Installation In A Target Project

To use this skill in another project:

1. Install or copy the skill into the AI IDE skill directory.
2. Copy `templates/.ai-sync/` into the target repository root.
3. Assign each AI IDE a stable ID.
4. Start every task by invoking `dual-agent-sync`.
5. End every task by writing a sync event.

## Non-Goals

This skill does not provide a background daemon by itself.

For instant push-style notification, pair this skill with one of:

- Git hooks.
- File watcher scripts.
- CI comments.
- ChatOps bot.
- Shared cloud storage notifications.

The skill still defines the authoritative protocol for what to read, write, print, and verify.
