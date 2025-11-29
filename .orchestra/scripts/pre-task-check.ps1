# Pre-Task Check Script
# Run this BEFORE preparing any new task to ensure previous task is fully closed out
#
# Usage: .\.orchestra\scripts\pre-task-check.ps1
#
# Returns: Exit code 0 if all checks pass, 1 if any fail

param(
    [switch]$Fix  # If set, will attempt to fix some issues automatically
)

$ErrorActionPreference = "Stop"
$script:failures = @()
$script:warnings = @()

function Write-Check {
    param([string]$Name, [bool]$Passed, [string]$Details = "")
    if ($Passed) {
        Write-Host "  ✅ $Name" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $Name" -ForegroundColor Red
        if ($Details) { Write-Host "     $Details" -ForegroundColor Yellow }
        $script:failures += $Name
    }
}

function Write-Warning {
    param([string]$Name, [string]$Details = "")
    Write-Host "  ⚠️  $Name" -ForegroundColor Yellow
    if ($Details) { Write-Host "     $Details" -ForegroundColor Yellow }
    $script:warnings += $Name
}

function Write-Section {
    param([string]$Name)
    Write-Host "`n📋 $Name" -ForegroundColor Cyan
    Write-Host ("─" * 50) -ForegroundColor DarkGray
}

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n" 
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║          ORCHESTRATOR PRE-TASK CHECK                        ║" -ForegroundColor Magenta
Write-Host "║   Run before preparing ANY new task                          ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

# ============================================================================
# 1. GIT STATUS CHECK
# ============================================================================

Write-Section "Git Status"

$gitStatus = git status --porcelain
$hasUncommitted = $gitStatus.Length -gt 0

if ($hasUncommitted) {
    Write-Check "No uncommitted changes" $false "Found uncommitted files - commit or stash before proceeding"
    Write-Host "`n  Uncommitted files:" -ForegroundColor Yellow
    $gitStatus | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
} else {
    Write-Check "No uncommitted changes" $true
}

# Check we're on the right branch
$currentBranch = git branch --show-current
Write-Check "On agent-research branch" ($currentBranch -eq "agent-research") "Current: $currentBranch"

# ============================================================================
# 2. PROGRESS.YAML CHECKS
# ============================================================================

Write-Section "Progress Tracking (progress.yaml)"

$progressPath = ".orchestra/progress.yaml"
if (Test-Path $progressPath) {
    $progressContent = Get-Content $progressPath -Raw
    
    # Extract current task ID
    if ($progressContent -match 'current_task_id:\s*(\d+)') {
        $currentTaskId = [int]$Matches[1]
        Write-Host "  Current task ID: $currentTaskId" -ForegroundColor Gray
    }
    
    # Check last task in history has status: completed
    $lastTaskPattern = 'task_id:\s*' + ($currentTaskId - 1) + '[\s\S]*?status:\s*"?(\w+)"?'
    if ($progressContent -match $lastTaskPattern) {
        $lastStatus = $Matches[1]
        Write-Check "Previous task (Task $($currentTaskId - 1)) marked completed" ($lastStatus -eq "completed") "Status: $lastStatus"
    } else {
        Write-Warning "Could not find previous task status" "Manual verification needed"
    }
    
    # Check last task has commit hash
    $commitPattern = 'task_id:\s*' + ($currentTaskId - 1) + '[\s\S]*?commit:\s*"?([a-f0-9]+|null|pending)"?'
    if ($progressContent -match $commitPattern) {
        $commitHash = $Matches[1]
        $hasCommit = ($commitHash -ne "null" -and $commitHash -ne "pending" -and $commitHash.Length -ge 7)
        Write-Check "Previous task has commit hash" $hasCommit "Commit: $commitHash"
    }
    
    # Check note doesn't say "in progress" for previous task
    if ($progressContent -match 'note:\s*"([^"]*)"') {
        $note = $Matches[1]
        $noteOk = -not ($note -match "Task $($currentTaskId - 1).*in.?progress" -or $note -match "IN PROGRESS")
        Write-Check "Note reflects completion" $noteOk "Note: $note"
    }
} else {
    Write-Check "progress.yaml exists" $false
}

# ============================================================================
# 3. SPECKIT TASKS.MD CHECK
# ============================================================================

Write-Section "SpecKit Traceability (tasks.md)"

$tasksPath = "specs/011-multi-axis-normalization/tasks.md"
if (Test-Path $tasksPath) {
    $tasksContent = Get-Content $tasksPath -Raw
    
    # Count how many times the previous orchestrator task is referenced with completion marker
    $prevTaskRef = "Orchestrator Task $($currentTaskId - 1)"
    $completedPattern = "✅ Completed:.*$prevTaskRef"
    $completedCount = ([regex]::Matches($tasksContent, $completedPattern)).Count
    
    if ($completedCount -gt 0) {
        Write-Check "SpecKit tasks checked for previous task" $true "$completedCount task(s) marked complete"
    } else {
        # Check if there are any references at all (even unchecked)
        $anyRef = $tasksContent -match $prevTaskRef
        if ($anyRef) {
            Write-Check "SpecKit tasks checked for previous task" $false "Found reference but not marked with ✅ Completed"
        } else {
            Write-Warning "No SpecKit task references found for Task $($currentTaskId - 1)" "May need manual verification"
        }
    }
} else {
    Write-Check "tasks.md exists" $false
}

# ============================================================================
# 4. VERIFICATION RESULTS CHECK
# ============================================================================

Write-Section "Verification Records"

$prevTaskNum = $currentTaskId - 1
$prevTaskPadded = $prevTaskNum.ToString().PadLeft(3, '0')

# Check verification results file exists
$verificationResultsPath = ".orchestra/verification/task-$prevTaskPadded-results.md"
$verificationResultsAlt = ".orchestra/verification/task-0$prevTaskNum-results.md"

$resultsExist = (Test-Path $verificationResultsPath) -or (Test-Path $verificationResultsAlt)
Write-Check "Verification results recorded (task-$prevTaskPadded-results.md)" $resultsExist

# Check screenshot if previous task was visual
$screenshotPattern = ".orchestra/screenshots/task-0$prevTaskNum*.png"
$screenshots = Get-ChildItem -Path ".orchestra/screenshots" -Filter "task-0$prevTaskNum*.png" -ErrorAction SilentlyContinue

if ($screenshots) {
    Write-Check "Screenshot exists for Task $prevTaskNum" $true "$($screenshots.Name)"
    
    # Check screenshot isn't empty (> 1KB)
    $screenshotSize = $screenshots[0].Length
    Write-Check "Screenshot has content (not empty)" ($screenshotSize -gt 1024) "Size: $([math]::Round($screenshotSize/1024, 1)) KB"
} else {
    Write-Warning "No screenshot found for Task $prevTaskNum" "OK if not a visual task"
}

# ============================================================================
# 5. TEST EXECUTION CHECK
# ============================================================================

Write-Section "Test Suite Status"

Write-Host "  Running quick test check..." -ForegroundColor Gray
try {
    $testOutput = flutter test test/unit/multi_axis/ --no-pub 2>&1 | Out-String
    $allPassed = $testOutput -match "All tests passed"
    $testCount = if ($testOutput -match '\+(\d+)') { $Matches[1] } else { "?" }
    Write-Check "Sprint tests pass" $allPassed "$testCount tests"
} catch {
    Write-Check "Sprint tests pass" $false "Could not run tests: $_"
}

# ============================================================================
# 6. COMPLETION SIGNAL CHECK
# ============================================================================

Write-Section "Handover State"

$completionPath = ".orchestra/handover/completion-signal.md"
if (Test-Path $completionPath) {
    $completionContent = Get-Content $completionPath -Raw
    $isEmpty = [string]::IsNullOrWhiteSpace($completionContent) -or $completionContent.Trim() -eq ""
    
    if ($isEmpty) {
        Write-Check "completion-signal.md is clear" $true
    } else {
        Write-Check "completion-signal.md is clear" $false "Contains content from previous task"
        if ($Fix) {
            Set-Content $completionPath ""
            Write-Host "     Fixed: Cleared completion-signal.md" -ForegroundColor Green
            $script:failures = $script:failures | Where-Object { $_ -ne "completion-signal.md is clear" }
        }
    }
}

# Check current-task.md exists and isn't stale
$currentTaskPath = ".orchestra/handover/current-task.md"
if (Test-Path $currentTaskPath) {
    $currentTaskContent = Get-Content $currentTaskPath -Raw
    
    # Check if it references the completed task (stale)
    if ($currentTaskContent -match "Task\s+$prevTaskNum\b" -and -not ($currentTaskContent -match "Task\s+$currentTaskId\b")) {
        Write-Warning "current-task.md may be stale" "References Task $prevTaskNum, expected Task $currentTaskId"
    } else {
        Write-Check "current-task.md ready for new task" $true
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta

if ($script:failures.Count -eq 0) {
    Write-Host "✅ ALL CHECKS PASSED - Ready to prepare Task $currentTaskId" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    if ($script:warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings (review but not blocking):" -ForegroundColor Yellow
        $script:warnings | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Read .orchestra/readme.md" -ForegroundColor White
    Write-Host "  2. Read .orchestra/manifest.yaml for Task $currentTaskId" -ForegroundColor White
    Write-Host "  3. Prepare handover using template" -ForegroundColor White
    
    exit 0
} else {
    Write-Host "❌ CHECKS FAILED - Cannot proceed until fixed" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    Write-Host "`n🚫 Blocking issues:" -ForegroundColor Red
    $script:failures | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    
    if ($script:warnings.Count -gt 0) {
        Write-Host "`n⚠️  Warnings:" -ForegroundColor Yellow
        $script:warnings | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    }
    
    Write-Host "`nRun with -Fix to auto-fix some issues:" -ForegroundColor Cyan
    Write-Host "  .\.orchestra\scripts\pre-task-check.ps1 -Fix" -ForegroundColor White
    
    exit 1
}
