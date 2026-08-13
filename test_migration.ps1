# test_migration.ps1
Write-Host "Creating legacy V1 environment..."
Remove-Item -Recurse -Force ".ai-sync" -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force ".ai-sync"
New-Item -ItemType Directory -Force ".ai-sync/cursors"
New-Item -ItemType Directory -Force ".ai-sync/locks"
Set-Content -Path ".ai-sync/ledger.jsonl" -Value '{"version":"v0001","event_type":"code_update"}'
Set-Content -Path ".ai-sync/AUDIT_LOG.md" -Value 'Audit Log Data'
Set-Content -Path ".ai-sync/PROJECT_STATE.md" -Value 'State Data'
Set-Content -Path ".ai-sync/cursors/trae.json" -Value '{"ai_ide_id":"trae"}'

Write-Host "Simulating V2.0 AI Start-Of-Task Migration..."

if (Test-Path ".ai-sync/ledger.jsonl") {
    Write-Host "V1 detected. Running Migration..."
    
    # 1. Acquire Migration Lock
    New-Item -ItemType File -Force ".ai-sync/migration.lock"
    
    # 2. Backup
    Copy-Item -Path ".ai-sync" -Destination ".ai-sync-backup" -Recurse
    
    # 3. Restructure
    New-Item -ItemType Directory -Force ".ai-sync/collab/cursors"
    New-Item -ItemType Directory -Force ".ai-sync/collab/locks"
    
    Move-Item ".ai-sync/ledger.jsonl" ".ai-sync/collab/"
    Move-Item ".ai-sync/AUDIT_LOG.md" ".ai-sync/collab/"
    Move-Item ".ai-sync/PROJECT_STATE.md" ".ai-sync/collab/"
    Move-Item ".ai-sync/cursors/*" ".ai-sync/collab/cursors/"
    
    Remove-Item -Recurse -Force ".ai-sync/cursors"
    Remove-Item -Recurse -Force ".ai-sync/locks"
    
    New-Item -ItemType Directory -Force ".ai-sync/codegraph/locks"
    
    # Write Migration Event
    Add-Content -Path ".ai-sync/collab/ledger.jsonl" -Value '{"version":"v0002","event_type":"migration_update","summary":"Migrated to V2.0"}'
    
    # Release Lock & Cleanup
    Remove-Item ".ai-sync/migration.lock"
    Remove-Item -Recurse -Force ".ai-sync-backup"
    
    Write-Host "Migration logic executed."
}

# 4. Verify Validation
if (Test-Path ".ai-sync/collab/ledger.jsonl") {
    Write-Host "SUCCESS: ledger exists in collab/"
} else {
    Write-Host "FAIL: ledger missing"
    exit 1
}

if (Test-Path ".ai-sync/collab/cursors/trae.json") {
    Write-Host "SUCCESS: cursors migrated successfully"
} else {
    Write-Host "FAIL: cursors missing"
    exit 1
}

if (!(Test-Path ".ai-sync/ledger.jsonl")) {
    Write-Host "SUCCESS: legacy ledger.jsonl cleaned up"
} else {
    Write-Host "FAIL: legacy ledger not cleaned"
    exit 1
}

Write-Host "V2.0 Migration Test Passed."

# Cleanup test artifacts
Remove-Item -Recurse -Force ".ai-sync"