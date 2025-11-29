# Pre-Task Check Script (Orchestrator)
# =====================================
# MANDATORY: Run this BEFORE preparing any new task.
# Verifies the previous task is fully closed out.
#
# Usage: .\.orchestra\scripts\orchestrator\pre-task-check.ps1
#
# Returns: Exit code 0 if all checks pass, 1 if any fail

param(
    [switch]$Fix  # If set, will attempt to fix some issues automatically
)

$ErrorActionPreference = "Stop"

# ============================================================================
# LOAD DEPENDENCIES
# ============================================================================

$scriptRoot = Split-Path -Parent $PSScriptRoot
. "$scriptRoot\set-env.ps1"
. "$scriptRoot\common\check-utils.ps1"

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n" 
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║          ORCHESTRATOR PRE-TASK CHECK                         ║" -ForegroundColor Magenta
Write-Host "║   Run before preparing ANY new task                          ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Checking Task $env:PREVIOUS_TASK completion before Task $env:CURRENT_TASK prep" -ForegroundColor Gray

# Initialize collector
$checks = New-CheckCollector

# ============================================================================
# 1. GIT STATUS CHECK
# ============================================================================

Write-Section "Git Status"

$uncommitted = Get-UncommittedFiles
$hasUncommitted = $uncommitted.Count -gt 0

if ($hasUncommitted) {
    Add-CheckResult $checks "No uncommitted changes" $false `
        "Found uncommitted files - commit or stash before proceeding" `
        "Run: git add -A && git commit -m 'message'" `
        "Working directory"
    
    Write-Host "`n  Uncommitted files:" -ForegroundColor Yellow
    $uncommitted | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
} else {
    Add-CheckResult $checks "No uncommitted changes" $true
}

$currentBranch = Get-CurrentBranch
Add-CheckResult $checks "On agent-research branch" ($currentBranch -eq "agent-research") `
    "Current branch: $currentBranch" `
    "Run: git checkout agent-research" `
    "Git branch"

# ============================================================================
# 2. PROGRESS.YAML CHECKS
# ============================================================================

Write-Section "Progress Tracking ($env:PROGRESS_PATH)"

if (Test-Path $env:PROGRESS_PATH) {
    $progressContent = Get-Content $env:PROGRESS_PATH -Raw
    
    # Check previous task status
    $prevStatus = Get-ProgressTaskStatus $env:PROGRESS_PATH $env:PREVIOUS_TASK
    Add-CheckResult $checks "Previous task (Task $env:PREVIOUS_TASK) marked completed" `
        ($prevStatus -eq "completed") `
        "Status: $prevStatus" `
        "Update progress.yaml task_history for Task $env:PREVIOUS_TASK" `
        $env:PROGRESS_PATH
    
    # Check commit hash
    $commitPattern = "task_id:\s*$env:PREVIOUS_TASK[\s\S]*?commit:\s*[`"']?([a-f0-9]+|null|pending)[`"']?"
    if ($progressContent -match $commitPattern) {
        $commitHash = $Matches[1]
        $hasCommit = ($commitHash -ne "null" -and $commitHash -ne "pending" -and $commitHash.Length -ge 7)
        Add-CheckResult $checks "Previous task has commit hash" $hasCommit `
            "Commit: $commitHash" `
            "Record the actual commit hash in progress.yaml" `
            $env:PROGRESS_PATH
    } else {
        Add-CheckResult $checks "Previous task has commit hash" $false `
            "No commit field found for Task $env:PREVIOUS_TASK" `
            "Add commit hash to progress.yaml task_history" `
            $env:PROGRESS_PATH
    }
    
    # Check note reflects completion
    if ($progressContent -match 'note:\s*"([^"]*)"') {
        $note = $Matches[1]
        $noteOk = -not ($note -match "Task $env:PREVIOUS_TASK.*in.?progress|IN PROGRESS")
        Add-CheckResult $checks "Note reflects completion" $noteOk `
            "Note still says in-progress" `
            "Update note field in progress.yaml" `
            $env:PROGRESS_PATH
    }
} else {
    Add-CheckResult $checks "progress.yaml exists" $false `
        "File not found" `
        "Create progress.yaml from template" `
        $env:PROGRESS_PATH
}

# ============================================================================
# 3. SPECKIT TASKS.MD CHECK
# ============================================================================

Write-Section "SpecKit Traceability ($env:SPECKIT_TASKS_PATH)"

if (Test-Path $env:SPECKIT_TASKS_PATH) {
    $tasksContent = Get-Content $env:SPECKIT_TASKS_PATH -Raw
    
    # Check for completed markers for previous task
    $prevTaskRef = "Orchestrator Task $env:PREVIOUS_TASK"
    $completedPattern = "✅ Completed:.*$prevTaskRef"
    $completedCount = ([regex]::Matches($tasksContent, $completedPattern)).Count
    
    if ($completedCount -gt 0) {
        Add-CheckResult $checks "SpecKit tasks checked for previous task" $true `
            "$completedCount task(s) marked complete"
    } else {
        $anyRef = $tasksContent -match $prevTaskRef
        if ($anyRef) {
            Add-CheckResult $checks "SpecKit tasks checked for previous task" $false `
                "Found reference but not marked with ✅ Completed" `
                "Add '✅ Completed: Orchestrator Task $env:PREVIOUS_TASK, commit XXXXX' to tasks.md" `
                $env:SPECKIT_TASKS_PATH
        } else {
            Add-CheckResult $checks "SpecKit tasks referenced for previous task" $false `
                "No SpecKit task references Task $env:PREVIOUS_TASK" `
                "Update tasks.md with orchestrator task mapping" `
                $env:SPECKIT_TASKS_PATH
        }
    }
} else {
    Add-CheckResult $checks "tasks.md exists" $false `
        "SpecKit tasks.md not found" `
        "Verify SPECKIT_ROOT path in set-env.ps1" `
        $env:SPECKIT_TASKS_PATH
}

# ============================================================================
# 4. VERIFICATION RESULTS CHECK
# ============================================================================

Write-Section "Verification Records"

$prevTaskPadded = ([int]$env:PREVIOUS_TASK).ToString().PadLeft(3, '0')
$verificationResultsPath = "$env:VERIFICATION_PATH/task-$prevTaskPadded-results.md"

$resultsExist = Test-Path $verificationResultsPath
Add-CheckResult $checks "Verification results recorded" $resultsExist `
    "File not found: task-$prevTaskPadded-results.md" `
    "Create verification results after task verification" `
    $verificationResultsPath

# Check screenshot for visual tasks
$screenshotPattern = "$env:SCREENSHOT_PATH/task-0$env:PREVIOUS_TASK*.png"
$screenshots = Get-ChildItem -Path $env:SCREENSHOT_PATH -Filter "task-0$env:PREVIOUS_TASK*.png" -ErrorAction SilentlyContinue

if ($screenshots) {
    Add-CheckResult $checks "Screenshot exists for Task $env:PREVIOUS_TASK" $true `
        $screenshots[0].Name
    
    # Check screenshot isn't empty
    $screenshotSize = $screenshots[0].Length
    Add-CheckResult $checks "Screenshot has content (not empty)" ($screenshotSize -gt 1024) `
        "Size: $([math]::Round($screenshotSize/1024, 1)) KB - may be empty/corrupt" `
        "Recapture screenshot using Chrome DevTools MCP" `
        $screenshots[0].FullName
} else {
    # This is a warning, not a failure (not all tasks are visual)
    Write-CheckWarning "No screenshot found for Task $env:PREVIOUS_TASK" `
        "OK if not a visual/integration task"
}

# ============================================================================
# 5. TEST EXECUTION CHECK
# ============================================================================

Write-Section "Test Suite Status"

Write-Host "  Running sprint tests..." -ForegroundColor Gray
try {
    $testOutput = flutter test $env:SPRINT_TEST_PATH --no-pub 2>&1 | Out-String
    $allPassed = $testOutput -match "All tests passed"
    $testCount = if ($testOutput -match '\+(\d+)') { $Matches[1] } else { "?" }
    Add-CheckResult $checks "Sprint tests pass" $allPassed `
        "Tests failed - fix before proceeding" `
        "Run: flutter test $env:SPRINT_TEST_PATH" `
        $env:SPRINT_TEST_PATH
    
    if ($allPassed) {
        Write-Host "     $testCount tests passed" -ForegroundColor Gray
    }
} catch {
    Add-CheckResult $checks "Sprint tests pass" $false `
        "Could not run tests: $_" `
        "Check Flutter installation and test files" `
        $env:SPRINT_TEST_PATH
}

# ============================================================================
# 6. HANDOVER STATE CHECK
# ============================================================================

Write-Section "Handover State"

$completionPath = "$env:HANDOVER_PATH/completion-signal.md"
if (Test-Path $completionPath) {
    $completionContent = Get-Content $completionPath -Raw
    $isEmpty = [string]::IsNullOrWhiteSpace($completionContent) -or $completionContent.Trim() -eq ""
    
    if ($isEmpty) {
        Add-CheckResult $checks "completion-signal.md is clear" $true
    } else {
        $passed = Add-CheckResult $checks "completion-signal.md is clear" $false `
            "Contains content from previous task" `
            "Clear the file before preparing new task" `
            $completionPath
        
        if ($Fix -and -not $passed) {
            Set-Content $completionPath ""
            Write-Host "     ✓ Fixed: Cleared completion-signal.md" -ForegroundColor Green
            # Remove from failures
            $checks.Failures = $checks.Failures | Where-Object { $_.Name -ne "completion-signal.md is clear" }
        }
    }
}

# Check current-task.md state
$currentTaskPath = "$env:HANDOVER_PATH/current-task.md"
if (Test-Path $currentTaskPath) {
    $currentTaskContent = Get-Content $currentTaskPath -Raw
    
    # Warn if it references the previous task (stale)
    if ($currentTaskContent -match "Task\s+$env:PREVIOUS_TASK\b" -and 
        -not ($currentTaskContent -match "Task\s+$env:CURRENT_TASK\b")) {
        Write-CheckWarning "current-task.md may be stale" `
            "References Task $env:PREVIOUS_TASK, will be replaced for Task $env:CURRENT_TASK"
    } else {
        Write-Host "  ✅ current-task.md ready for update" -ForegroundColor Green
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta

if ($summary.AllPassed) {
    Write-Host "✅ ALL CHECKS PASSED - Ready to prepare Task $env:CURRENT_TASK" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Read $env:ORCHESTRA_ROOT/readme.md" -ForegroundColor White
    Write-Host "  2. Read $env:MANIFEST_PATH for Task $env:CURRENT_TASK" -ForegroundColor White
    Write-Host "  3. Prepare handover using template" -ForegroundColor White
    
    exit 0
} else {
    Write-Host "❌ $($summary.Failed) CHECK(S) FAILED - Cannot proceed until fixed" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    Write-Host "`n🚫 Blocking issues:" -ForegroundColor Red
    foreach ($failure in $checks.Failures) {
        Write-Host "`n   ─────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "   Check:    $($failure.Name)" -ForegroundColor Red
        Write-Host "   Problem:  $($failure.Details)" -ForegroundColor Yellow
        Write-Host "   Fix:      $($failure.Fix)" -ForegroundColor Green
        if ($failure.Location) {
            Write-Host "   Location: $($failure.Location)" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n"
    Write-Host "Run with -Fix to auto-fix some issues:" -ForegroundColor Cyan
    Write-Host "  .\.orchestra\scripts\orchestrator\pre-task-check.ps1 -Fix" -ForegroundColor White
    
    exit 1
}
