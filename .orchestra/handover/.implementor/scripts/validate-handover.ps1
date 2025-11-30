# Validate Handover Script (Implementor)
# =======================================
# Run this BEFORE starting work on a task.
# Verifies the task instructions are complete and unambiguous.
#
# Usage: .\.orchestra\handover\.implementor\scripts\validate-handover.ps1
#
# Returns: Exit code 0 if all checks pass, 1 if any fail

$ErrorActionPreference = "Stop"

# ============================================================================
# LOAD COMMON UTILITIES (from parent scripts folder)
# ============================================================================

$orchestraRoot = (Get-Item "$PSScriptRoot\..\..\..").FullName
. "$orchestraRoot\scripts\set-env.ps1" 2>$null
. "$orchestraRoot\scripts\common\check-utils.ps1"

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n" 
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║          IMPLEMENTOR HANDOVER VALIDATION                     ║" -ForegroundColor Blue
Write-Host "║   Verify task instructions before starting work              ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue

$checks = New-CheckCollector

# ============================================================================
# READ CURRENT TASK
# ============================================================================

$currentTaskPath = "$env:HANDOVER_PATH/current-task.md"

if (-not (Test-Path $currentTaskPath)) {
    Write-Host "`n❌ current-task.md not found!" -ForegroundColor Red
    Write-Host "   Location: $currentTaskPath" -ForegroundColor Yellow
    Write-Host "   Ask orchestrator to prepare the task handover." -ForegroundColor Yellow
    exit 1
}

$content = Get-Content $currentTaskPath -Raw
$lines = Get-Content $currentTaskPath

Write-Host "`n  Reading: $currentTaskPath" -ForegroundColor Gray

# ============================================================================
# 1. BASIC STRUCTURE CHECKS
# ============================================================================

Write-Section "Task Structure"

# Has task title
$hasTitle = $content -match "^#\s*Task\s+\d+:|^##\s*Task\s+\d+:"
Add-CheckResult $checks "Has task title (Task N: ...)" $hasTitle `
    "Missing task title in expected format" `
    "Orchestrator should add: # Task N: Title" `
    $currentTaskPath

# Extract task number for later
$taskNumber = if ($content -match "Task\s+(\d+):") { $Matches[1] } else { "?" }
Write-Host "     Task number: $taskNumber" -ForegroundColor Gray

# Has objective/overview
$hasObjective = $content -match "(?i)(objective|overview|goal|purpose)\s*[:\n]"
Add-CheckResult $checks "Has objective/overview section" $hasObjective `
    "Missing objective - unclear what to accomplish" `
    "Orchestrator should add objective statement" `
    $currentTaskPath

# Has deliverables section
$hasDeliverables = $content -match "(?i)(deliverables|files to create|files to modify)\s*[:\n]|## Files|### Files"
Add-CheckResult $checks "Has deliverables section" $hasDeliverables `
    "No deliverables section - what files to create/modify?" `
    "Orchestrator should add Deliverables section" `
    $currentTaskPath

# Has TDD section
$hasTDD = $content -match "(?i)(tdd|test.?first|test requirements|testing)\s*[:\n]|## Test|### Test"
Add-CheckResult $checks "Has TDD/testing section" $hasTDD `
    "No testing section - what tests to write?" `
    "Orchestrator should add TDD requirements" `
    $currentTaskPath

# ============================================================================
# 2. FILE PATH CHECKS
# ============================================================================

Write-Section "File Paths"

# Extract CREATE file paths
$createPaths = @()
if ($content -match "(?i)CREATE[:\s]+[`]?([^\n`]+)[`]?") {
    $createPaths += $Matches[1]
}
# Also match table format: | CREATE | path |
$tableCreateMatches = [regex]::Matches($content, "(?i)\|\s*CREATE\s*\|\s*[`]?([^|`\n]+)[`]?\s*\|")
foreach ($match in $tableCreateMatches) {
    $createPaths += $match.Groups[1].Value.Trim()
}
# Also match list format: - CREATE: path
$listCreateMatches = [regex]::Matches($content, "(?i)-\s*CREATE[:\s]+[`]?([^\n`]+)[`]?")
foreach ($match in $listCreateMatches) {
    $createPaths += $match.Groups[1].Value.Trim()
}

if ($createPaths.Count -gt 0) {
    Write-Host "  Found $($createPaths.Count) CREATE file(s):" -ForegroundColor Gray
    foreach ($path in $createPaths) {
        $cleanPath = $path.Trim().TrimStart('`').TrimEnd('`')
        Write-Host "    - $cleanPath" -ForegroundColor Gray
        
        # Check file doesn't already exist
        if (Test-Path $cleanPath) {
            Add-CheckResult $checks "CREATE file doesn't exist: $cleanPath" $false `
                "File already exists - should this be UPDATE instead?" `
                "Verify with orchestrator: CREATE vs UPDATE" `
                $cleanPath
        }
    }
    Add-CheckResult $checks "CREATE paths specified" $true
}
else {
    Write-CheckWarning "No CREATE file paths found" `
        "May be OK if task only updates existing files"
}

# Extract UPDATE file paths
$updatePaths = @()
$tableUpdateMatches = [regex]::Matches($content, "(?i)\|\s*UPDATE\s*\|\s*[`]?([^|`\n]+)[`]?\s*\|")
foreach ($match in $tableUpdateMatches) {
    $updatePaths += $match.Groups[1].Value.Trim()
}
$listUpdateMatches = [regex]::Matches($content, "(?i)-\s*UPDATE[:\s]+[`]?([^\n`]+)[`]?")
foreach ($match in $listUpdateMatches) {
    $updatePaths += $match.Groups[1].Value.Trim()
}

if ($updatePaths.Count -gt 0) {
    Write-Host "  Found $($updatePaths.Count) UPDATE file(s):" -ForegroundColor Gray
    foreach ($path in $updatePaths) {
        $cleanPath = $path.Trim().TrimStart('`').TrimEnd('`')
        Write-Host "    - $cleanPath" -ForegroundColor Gray
        
        # Check file exists
        if (-not (Test-Path $cleanPath)) {
            Add-CheckResult $checks "UPDATE file exists: $cleanPath" $false `
                "File doesn't exist - should this be CREATE instead?" `
                "Verify with orchestrator: file path correct?" `
                $cleanPath
        }
    }
}

# ============================================================================
# 3. COMPLETENESS CHECKS
# ============================================================================

Write-Section "Completeness"

# No TODO/TBD markers
$hasTodos = $content -match '\[TODO\]|\[TBD\]|\[PLACEHOLDER\]|XXX|FIXME'
Add-CheckResult $checks "No TODO/TBD markers" (-not $hasTodos) `
    "Found incomplete markers - task instructions not finished" `
    "Ask orchestrator to complete the handover" `
    $currentTaskPath

# Has code scaffold (for non-trivial tasks)
$hasCodeScaffold = $content -match '```dart|```'
if ($hasDeliverables -and $createPaths.Count -gt 0) {
    Add-CheckResult $checks "Has code scaffold" $hasCodeScaffold `
        "No code scaffold provided for new files" `
        "Ask orchestrator for implementation scaffold" `
        $currentTaskPath
}
else {
    Write-Host "  ⏭️  Code scaffold check skipped (no CREATE files)" -ForegroundColor DarkGray
}

# Has test sample data (if TDD section exists)
$hasTestData = $content -match "(?i)test.*data|sample.*object|mock|stub|fixture" -or 
($content -match '```dart' -and $content -match 'test\(|group\(|expect\(')
if ($hasTDD) {
    if ($hasTestData) {
        Add-CheckResult $checks "Has test sample data" $true
    }
    else {
        Write-CheckWarning "Test sample data not obvious" `
            "Ensure you have concrete test objects, not just test names"
    }
}

# ============================================================================
# 4. INTEGRATION TASK CHECKS (if applicable)
# ============================================================================

Write-Section "Integration Requirements"

$isIntegration = $content -match "(?i)INTEGRATION|VISUAL|category:\s*integration"

if ($isIntegration) {
    Write-Host "  Task identified as INTEGRATION/VISUAL" -ForegroundColor Gray
    
    # Should have MUST USE section
    $hasMustUse = $content -match "(?i)MUST USE|Must Use|must-use"
    Add-CheckResult $checks "Has MUST USE section (integration task)" $hasMustUse `
        "Integration tasks should specify what existing code to use" `
        "Ask orchestrator for MUST USE section with specific imports/methods" `
        $currentTaskPath
    
    # Should have demo file specified
    $hasDemo = $content -match "(?i)demo|example.*lib.*demo|visual.*verification"
    Add-CheckResult $checks "Has demo file requirement" $hasDemo `
        "Visual tasks should specify demo file to create" `
        "Ask orchestrator for demo scaffold" `
        $currentTaskPath
}
else {
    Write-Host "  ⏭️  Integration checks skipped (not an integration task)" -ForegroundColor DarkGray
}

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue

if ($summary.AllPassed) {
    Write-Host "✅ HANDOVER VALIDATION PASSED - Ready to start Task $taskNumber" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Read the full task instructions" -ForegroundColor White
    Write-Host "  2. Write tests first (TDD)" -ForegroundColor White
    Write-Host "  3. Implement to pass tests" -ForegroundColor White
    Write-Host "  4. Run pre-signal-check.ps1 before signaling done" -ForegroundColor White
    
    exit 0
}
else {
    Write-Host "❌ HANDOVER VALIDATION FAILED - Task instructions incomplete" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue
    
    Write-Host "`n⚠️  Do NOT start work until these issues are resolved:" -ForegroundColor Yellow
    foreach ($failure in $checks.Failures) {
        Write-Host "`n   ─────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "   Check:    $($failure.Name)" -ForegroundColor Red
        Write-Host "   Problem:  $($failure.Details)" -ForegroundColor Yellow
        Write-Host "   Fix:      $($failure.Fix)" -ForegroundColor Green
    }
    
    Write-Host "`n📢 Signal to orchestrator: 'Handover incomplete - see validation output'" -ForegroundColor Yellow
    
    exit 1
}
