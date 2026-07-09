# Examples

## Example Audit Notice

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

## Example Ledger Event

```json
{"version":"v0007","timestamp":"2026-07-08T12:00:00+08:00","project":"news2-service","source_ai_ide":"cursor-rpa","event_type":"code_update","git":{"branch":"master","base_commit":"abc123","head_commit":"def456"},"scope":{"modules":["mode1-runtime"],"files_changed":["src/lib/newsAideConfig.ts"],"docs_changed":["LLM-RPA-Bot-news_aide_V1/DOCS/SDD.md"]},"context":{"requirement_background":"Mode1 runtime must be independent from M23.","problem_background":"Frontend wrote m23_* keys while client reads mode1_* keys.","solution":"Changed frontend defaults and fields to mode1_* namespace.","current_status":"Build passed; real RPA verification pending.","remaining_issues":["Need pre-release manual verification"],"next_steps":["Run Mode1 task with custom runtime values"],"risks":["Existing DB settings may still contain old m23_* keys"]},"verification":{"tests_run":["npm run build"],"tests_not_run":["real browser RPA"],"result":"pass"},"summary":"Align Mode1 runtime key namespace."}
```

## Example Cursor

```json
{
  "ai_ide_id": "trae-main",
  "last_read_version": "v0007",
  "last_read_timestamp": "2026-07-08T12:10:00+08:00",
  "notes": "Read and acknowledged v0001-v0007."
}
```
