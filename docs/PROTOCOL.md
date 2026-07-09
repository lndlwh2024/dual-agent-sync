# Dual Agent Sync Protocol

## Overview

The protocol coordinates multiple AI IDEs working on one repository by using repository-local files under `.ai-sync/`.

The protocol has five parts:

- Append-only ledger: `.ai-sync/ledger.jsonl`
- Per-AI read cursors: `.ai-sync/cursors/<ai-ide-id>.json`
- Human audit log: `.ai-sync/AUDIT_LOG.md`
- Current state summary: `.ai-sync/PROJECT_STATE.md`
- Soft locks: `.ai-sync/locks/*.lock.json`

## Start Of Task

Every AI IDE must run this sequence before doing work:

1. Identify its stable `ai_ide_id`.
2. Read its cursor.
3. Read all ledger events after the cursor version.
4. Print a chat audit notice for updates from other AI IDEs.
5. Read only files referenced by relevant new events.
6. Update its cursor after understanding the updates.

## Before Editing

Before editing, the AI IDE must:

1. Recheck unread ledger events.
2. Check active locks.
3. Compare intended files against unread events and locks.
4. Stop and ask the user if there is overlap.

## After Editing

After work is complete, the AI IDE must:

1. Append one new event to `ledger.jsonl`.
2. Update `AUDIT_LOG.md`.
3. Update `PROJECT_STATE.md`.
4. Update its own cursor.
5. Include Git commit SHA when available.

## Repair Rules

Ledger repair is exceptional. Do not rewrite history unless the user explicitly approves a repair plan.

If a version conflict occurs, append a `conflict_notice` event after the conflict is resolved.
