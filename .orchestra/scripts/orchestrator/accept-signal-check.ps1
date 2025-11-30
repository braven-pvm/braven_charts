# Accept Signal Check Script (Orchestrator)
# ==========================================
# MANDATORY: Run this BEFORE accepting implementor's completion signal.
# Verifies the implementor ran required scripts and checks.
#
# Purpose: Gate check BEFORE orchestrator begins verification
# Timing:  Implementor signals done → THIS SCRIPT → Orchestrator verifies
#
# Usage: .\.orchestra\scripts\orchestrator\accept-signal-check.ps1
#
# Returns: Exit code 0 if implementor followed process, 1 if not

param(
    [int]$TaskId = 0  # If not specified, uses current task from progress.yaml
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
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║          ACCEPT SIGNAL CHECK                                 ║" -ForegroundColor Yellow
Write-Host "║   Verify implementor followed process before verification   ║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

# Determine task ID
if ($TaskId -eq 0) {
    $TaskId = [int]$env:CURRENT_TASK
}

Write-Host "`n  Checking Task $TaskId signal acceptance criteria" -ForegroundColor Gray

$checks = New-CheckCollector

# ============================================================================
# 1. COMPLETION SIGNAL EXISTS AND HAS CONTENT
# ============================================================================

Write-Section "Completion Signal"

$completionPath = "$env:HANDOVER_PATH/completion-signal.md"
if (Test-Path $completionPath) {
    $signalContent = Get-Content $completionPath -Raw
    $hasContent = -not [string]::IsNullOrWhiteSpace($signalContent)
    
    Add-CheckResult $checks "completion-signal.md has content" $hasContent `
        "File is empty - implementor didn't write completion signal" `
        "Implementor must write status and file changes to completion-signal.md" `
        $completionPath
    
    if ($hasContent) {
        # Check for required sections
        $hasStatus = $signalContent -match "(?i)status:\s*(COMPLETED|complete|done)"
        Add-CheckResult $checks "Signal contains COMPLETED status" $hasStatus `
            "Missing 'status: COMPLETED' in signal" `
            "Implementor must include status in completion-signal.md" `
            $completionPath
        
        $hasFiles = $signalContent -match "(?i)(files|created|modified|changed):"
        if ($hasFiles) {
            Write-Host "  ✅ Signal lists file changes" -ForegroundColor Green
        } else {
            Write-CheckWarning "Signal may not list file changes" `
                "Consider requiring file list in completion signal"
        }
    }
}
else {
    Add-CheckResult $checks "completion-signal.md exists" $false `
        "File not found" `
        "Implementor must create completion-signal.md" `
        $completionPath
}

# ============================================================================
# 2. PRE-SIGNAL CHECK ARTIFACT EXISTS (CRITICAL)
# ============================================================================

Write-Section "Pre-Signal Check Artifact (Process Compliance)"

$artifactDir = "$env:ORCHESTRA_ROOT/artifacts/pre-signal"
$artifactPattern = "task-$TaskId-*.txt"

if (Test-Path $artifactDir) {
    $artifacts = Get-ChildItem -Path $artifactDir -Filter $artifactPattern -ErrorAction SilentlyContinue | 
                 Sort-Object LastWriteTime -Descending
    
    if ($artifacts) {
        $latestArtifact = $artifacts[0]
        $artifactContent = Get-Content $latestArtifact.FullName -Raw
        
        # Check artifact shows PASSED status
        $passed = $artifactContent -match "status:\s*PASSED"
        
        Add-CheckResult $checks "Pre-signal check was run" $true `
            $latestArtifact.Name
        
        Add-CheckResult $checks "Pre-signal check PASSED" $passed `
            "Artifact shows FAILED status - implementor signaled despite failures" `
            "Implementor must fix all issues and re-run pre-signal-check.ps1" `
            $latestArtifact.FullName
        
        # Extract timestamp from artifact
        if ($artifactContent -match "timestamp:\s*(.+)") {
            $artifactTime = $Matches[1]
            Write-Host "     Last run: $artifactTime" -ForegroundColor Gray
        }
        
        # Check if artifact is recent (within last 2 hours)
        $artifactAge = (Get-Date) - $latestArtifact.LastWriteTime
        if ($artifactAge.TotalHours -gt 2) {
            Write-CheckWarning "Pre-signal artifact is old ($([math]::Round($artifactAge.TotalHours, 1)) hours ago)" `
                "Consider having implementor re-run pre-signal-check.ps1"
        }
    }
    else {
        Add-CheckResult $checks "Pre-signal check was run" $false `
            "No pre-signal artifact found for Task $TaskId" `
            "Implementor MUST run: .\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1" `
            $artifactDir
    }
}
else {
    Add-CheckResult $checks "Pre-signal check was run" $false `
        "No pre-signal artifacts directory - scripts never run" `
        "Implementor MUST run: .\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1" `
        $artifactDir
}

# ============================================================================
# 3. GIT CHANGES EXIST
# ============================================================================

Write-Section "Git Changes"

$stagedChanges = git diff --staged --name-only 2>$null
$unstagedChanges = git diff --name-only 2>$null
$untrackedFiles = git ls-files --others --exclude-standard 2>$null

$hasChanges = ($stagedChanges -or $unstagedChanges -or $untrackedFiles)

Add-CheckResult $checks "Git changes detected" $hasChanges `
    "No git changes found - did implementor make any changes?" `
    "Verify implementor created/modified the required files" `
    "git status"

if ($stagedChanges) {
    Write-Host "     Staged: $($stagedChanges.Count) file(s)" -ForegroundColor Gray
}
if ($unstagedChanges) {
    Write-Host "     Unstaged: $($unstagedChanges.Count) file(s)" -ForegroundColor Yellow
    Write-CheckWarning "Some changes not staged" `
        "Have implementor run: git add -A"
}
if ($untrackedFiles) {
    Write-Host "     Untracked: $($untrackedFiles.Count) file(s)" -ForegroundColor Yellow
}

# ============================================================================
# 4. BASIC TEST CHECK (Quick sanity)
# ============================================================================

Write-Section "Quick Sanity Checks"

# Check that at least tests exist for this sprint
$testPath = $env:SPRINT_TEST_PATH
if (Test-Path $testPath) {
    $testFiles = Get-ChildItem -Path $testPath -Filter "*_test.dart" -Recurse
    Add-CheckResult $checks "Sprint test files exist" ($testFiles.Count -gt 0) `
        "No test files found in sprint test path" `
        "Verify test directory: $testPath" `
        $testPath
    
    if ($testFiles.Count -gt 0) {
        Write-Host "     Found: $($testFiles.Count) test file(s)" -ForegroundColor Gray
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow

if ($summary.AllPassed) {
    Write-Host "✅ SIGNAL ACCEPTED - Proceed with verification" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Run verification against task-$TaskId criteria" -ForegroundColor White
    Write-Host "  2. Capture screenshot (if visual task)" -ForegroundColor White
    Write-Host "  3. Record results in verification/task-XXX-results.md" -ForegroundColor White
    
    exit 0
}
else {
    Write-Host "❌ SIGNAL REJECTED - Implementor did not follow process" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    
    Write-Host "`n🚫 Process violations:" -ForegroundColor Red
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
    Write-Host "⚠️  Do NOT proceed with verification until implementor:" -ForegroundColor Yellow
    Write-Host "   1. Runs pre-signal-check.ps1 successfully" -ForegroundColor White
    Write-Host "   2. Writes proper completion signal" -ForegroundColor White
    Write-Host "   3. Stages all changes" -ForegroundColor White
    
    exit 1
}
