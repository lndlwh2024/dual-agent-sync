# Event Schema

Each line of `.ai-sync/ledger.jsonl` is one JSON object.

## Required Fields

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
    "modules": ["module-name"],
    "files_changed": [
      {
        "file": "src/file.ts",
        "lines": ["10-20", "45-50"]
      }
    ],
    "docs_changed": ["docs/SPEC.md"]
  },
  "context": {
    "requirement_background": "Why this work was requested.",
    "problem_background": "What problem or bug existed.",
    "solution": "What was changed.",
    "current_status": "Current implementation and verification state.",
    "remaining_issues": ["Open issue"],
    "next_steps": ["Next action"],
    "risks": ["Residual risk"]
  },
  "verification": {
    "tests_run": ["test command"],
    "tests_not_run": ["manual browser verification"],
    "result": "pass"
  },
  "summary": "One-line summary."
}
```

## Version Rules

- Use `v0001`, `v0002`, `v0003`.
- The next version must be previous max version plus one.
- Never skip versions.
- Never advance a cursor past an unread version.
- In an append-only ledger, line N (1-indexed) corresponds to version `v{N:04d}` (where the init event v0000 is not stored, so line 1 = v0001, line 2 = v0002, etc.). This stable mapping enables incremental reads by line number.

## Event Types

- `analysis_handoff`
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

## Cursor Schema

Each AI IDE maintains one cursor file at `.ai-sync/cursors/<ai-ide-id>.json`. The file tracks read positions per conversation window (session).

```json
{
  "ai_ide_id": "trae-main",
  "sessions": {
    "5ec98d64-6f1f-4c7b": {
      "last_read_version": "v0007",
      "last_read_line": 7,
      "last_read_timestamp": "2026-08-03T12:10:00+08:00"
    }
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ai_ide_id` | string | Yes | The AI IDE identifier |
| `sessions` | object | Yes | Map of session ID → read position |
| `sessions.<id>.last_read_version` | string | Yes | Last read ledger version |
| `sessions.<id>.last_read_line` | number | No | Line number of last read version (1-indexed). If absent, triggers full read. |
| `sessions.<id>.last_read_timestamp` | string | No | ISO 8601 timestamp of last sync |

Session ID may be an IDE-provided conversation UUID or auto-generated in the format `<IDE_UPPERCASE>_<YYYYMMDDHHmm>_<Letter><4-digit>` (e.g., `CODEX_202608031701_A0001`).
