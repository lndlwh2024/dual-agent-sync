# Dual Agent Sync Protocol V2.0

## Overview

The protocol coordinates multiple AI IDEs working on one repository by using repository-local files under .ai-sync/.
In V2.0, the architecture is strictly split into two domains to avoid cross-contamination and support architectural tracking:

1. **collab/ (Project Collaboration Module)**: Answers "who changed what, when, and why".
2. **codegraph/ (Code Architecture Graph Module)**: Answers "what does the project structure look like".

The protocol uses the following core files:

- Append-only collaboration ledger: .ai-sync/collab/ledger.jsonl
- Per-AI read cursors: .ai-sync/collab/cursors/<ai-ide-id>.json
- Human audit logs: .ai-sync/collab/AUDIT_LOG.md & PROJECT_STATE.md
- Code architecture graph: .ai-sync/codegraph/graph.json
- Graph changelog: .ai-sync/codegraph/graph.changelog.jsonl
- Soft locks: .ai-sync/collab/locks/*.lock.json and .ai-sync/codegraph/locks/*.lock.json

## Start Of Task

Every AI IDE must run this sequence before doing work:

0. **V2.0 Migration Check**: Check if .ai-sync/ledger.jsonl exists at the root. If yes, it's a V1.x structure. You MUST initiate the **Strong Transactional Migration** (see Migration Rules).
1. Identify its stable i_ide_id.
2. Determine the current session ID for this conversation window.
3. Read its cursor file from .ai-sync/collab/cursors/ and locate the current session's entry in sessions.
4. If the session has a last_read_line, verify the version at that line matches last_read_version in collab/ledger.jsonl.
5. If verified, read only ledger events after last_read_line (incremental read).
6. If not verified or no last_read_line exists, read all ledger events (full read).
7. Read the current architecture from .ai-sync/codegraph/graph.json.
8. Print a chat audit notice for updates from other AI IDEs.
9. Read only files referenced by relevant new events.
10. Update the current session's cursor entry after understanding the updates.

## Automatic Migration to V2.0 (Migration Rules)

If a V1.x structure is detected, an atomic migration is required:
1. Lock: Try to acquire .ai-sync/migration.lock. If failed, wait for the other IDE to finish migration.
2. Ensure Git is clean. If uncommitted changes exist in .ai-sync/, abort and ask the user to commit.
3. Backup: Copy all old files into .ai-sync/.migration_backup_v1/.
4. Reorganize:
   - Create collab/, collab/cursors/, collab/locks/
   - Move ledger.jsonl, AUDIT_LOG.md, PROJECT_STATE.md into collab/
   - Move cursors/*.json into collab/cursors/
5. Verify: Check that collab/ledger.jsonl size and lines strictly match the backup. Check cursor JSON validity.
6. Commit Migration: Append an event migration_update to collab/ledger.jsonl noting the V2.0 upgrade. Remove .migration_backup_v1/ and migration.lock.
7. **Rollback on Error**: If any step or validation fails, restore from backup entirely and abort the task. Do NOT proceed with any V2.0 logic on broken data.

## Session-Level Cursors

Read positions are tracked per conversation window, not per AI IDE. Each cursor file contains a sessions object.
Session IDs come from the IDE's built-in conversation ID or are auto-generated.

## Incremental Read Safety

Incremental reads depend on ledger.jsonl being append-only.
If verification fails, fallback to a full read.

## Before Editing

Before editing, the AI IDE must:
1. Recheck unread ledger events.
2. Check active locks in .ai-sync/collab/locks/.
3. Compare intended files against unread events and locks.
4. Stop and ask the user if there is overlap.

## After Editing (Atomic Dual-Update)

After work is complete, the AI IDE must update both domains:

**1. Update Collaboration Module (collab/)**
- Append one new event to collab/ledger.jsonl (MUST include graph_impact field if code structure changed).
- Update collab/AUDIT_LOG.md and PROJECT_STATE.md.
- Acquire cursor write lock, merge update its own cursor in collab/cursors/, then release lock.

**2. Update Code Graph Module (codegraph/)**
- Acquire graph write lock (.ai-sync/codegraph/locks/codegraph.lock.json).
- If this is the very first time, initialize the graph by scanning the repo (exclude .git, 
ode_modules, etc.).
- Otherwise, incrementally update .ai-sync/codegraph/graph.json based on the file modifications (add/remove nodes, update edges).
- Append a diff summary entry to .ai-sync/codegraph/graph.changelog.jsonl.
- Release graph write lock.

**3. Anchor Git State**
- Suggest user to git commit so that .ai-sync/ and code changes are snapshot together.