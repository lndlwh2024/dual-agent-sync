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
2. Determine the current session ID for this conversation window.
3. Read its cursor file and locate the current session's entry in `sessions`.
4. If the session has a `last_read_line`, verify the version at that line matches `last_read_version`.
5. If verified, read only ledger events after `last_read_line` (incremental read).
6. If not verified or no `last_read_line` exists, read all ledger events (full read).
7. Print a chat audit notice for updates from other AI IDEs.
8. Read only files referenced by relevant new events.
9. Update the current session's cursor entry after understanding the updates.

## Session-Level Cursors

Read positions are tracked per conversation window, not per AI IDE. Each cursor file contains a `sessions` object where each key is a session ID and each value tracks that session's read position.

A new conversation window with no cursor entry performs a full read. A resumed window with an existing entry performs an incremental read from its last position.

Session IDs come from the IDE's built-in conversation ID or are auto-generated using the format `<IDE_UPPERCASE>_<YYYYMMDDHHmm>_<Letter><4-digit>` (e.g., `CODEX_202608031701_A0001`).

## Incremental Read Safety

Incremental reads depend on `ledger.jsonl` being append-only. Before reading from `last_read_line + 1`, the agent verifies that line `last_read_line` contains the expected `last_read_version`.

If the verification fails (e.g., the ledger was manually edited), the agent falls back to a full read and prints a warning.

If `last_read_line` is missing from a cursor entry (upgraded from an older cursor format), the agent performs a full read.

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
