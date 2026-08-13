# Examples V2.0

## Example Audit Notice (`collab/AUDIT_LOG.md`)

```markdown
**协作同步审计**
- 来源 AI IDE：cursor-rpa
- 版本：v0007
- 时间：2026-07-08T12:00:00+08:00
- 摘要：修复 Mode1 runtime 键名不一致。
- 影响文件：src/lib/newsAideConfig.ts, DOCS/SDD.md
- 当前状态：代码已改，前端 build 通过，实机 RPA 未验证。
- 后续建议：Trae 读取相关文件后继续客户端联调。
```

## Example Ledger Event (`collab/ledger.jsonl`)

```json
{"version":"v0007","timestamp":"2026-07-08T12:00:00+08:00","project":"news2-service","source_ai_ide":"cursor-rpa","event_type":"code_update","feature_scope":"Mode1 Runtime Setup","git":{"branch":"master","base_commit":"abc123","head_commit":"def456"},"scope":{"modules":["mode1-runtime"],"files_changed":[{"file":"src/lib/newsAideConfig.ts","lines":["10-20"],"purpose":"Update namespaces"}],"docs_changed":["DOCS/SDD.md"]},"graph_impact":{"updated":true,"nodes_added":[],"nodes_removed":[],"edges_added":[{"from":"src/lib/newsAideConfig.ts","to":"src/lib/constants.ts","type":"imports"}],"edges_removed":[]},"context":{"requirement_background":"Mode1 runtime must be independent from M23.","problem_background":"Frontend wrote m23_* keys while client reads mode1_* keys.","solution":"Changed frontend defaults and fields to mode1_* namespace.","current_status":"Build passed; real RPA verification pending.","remaining_issues":["Need pre-release manual verification"],"next_steps":["Run Mode1 task with custom runtime values"],"risks":["Existing DB settings may still contain old m23_* keys"]},"verification":{"tests_run":["npm run build"],"tests_not_run":["real browser RPA"],"result":"pass"},"summary":"Align Mode1 runtime key namespace."}
```

## Example Cursor (`collab/cursors/<ai-ide-id>.json`)

```json
{
  "ai_ide_id": "trae-main",
  "sessions": {
    "5ec98d64-6f1f-4c7b": {
      "last_read_version": "v0007",
      "last_read_line": 7,
      "last_read_timestamp": "2026-07-08T12:10:00+08:00"
    },
    "TRAE_202607081200_A0001": {
      "last_read_version": "v0003",
      "last_read_line": 3,
      "last_read_timestamp": "2026-07-08T11:00:00+08:00"
    }
  }
}
```

## Example Graph Changelog (`codegraph/graph.changelog.jsonl`)

```json
{"timestamp":"2026-07-08T12:05:00+08:00","source_ai_ide":"cursor-rpa","action":"update","trigger_version":"v0007","summary":"Add new edge for constants.ts import.","diff":{"nodes_added":[],"edges_added":[{"from":"src/lib/newsAideConfig.ts","to":"src/lib/constants.ts","type":"imports"}]}}
```
