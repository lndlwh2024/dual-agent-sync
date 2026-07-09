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
