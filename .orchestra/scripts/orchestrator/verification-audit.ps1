# Verification Audit Script (Orchestrator)
# =========================================
# Audits all verification records to ensure completeness.
# Identifies any gaps in verification logging.
#
# Usage: .\.orchestra\scripts\orchestrator\verification-audit.ps1
#        .\.orchestra\scripts\orchestrator\verification-audit.ps1 -TaskId 10
#
# Returns: Exit code 0 if all audits pass, 1 if any fail

param(
    [Parameter(Mandatory=$false)]
    [int]$TaskId
)

$ErrorActionPreference = "Stop"

# ============================================================================
# LOAD COMMON UTILITIES
# ============================================================================

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptRoot\..\set-env.ps1" 2>$null
. "$scriptRoot\..\common\check-utils.ps1"

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║          VERIFICATION AUDIT                                  ║" -ForegroundColor Magenta
Write-Host "║   Ensure all verification records are complete               ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

$checks = New-CheckCollector

# ============================================================================
# DETERMINE TASK SCOPE
# ============================================================================

# Get current task from progress.yaml
$progressPath = "$env:ORCHESTRA_ROOT/progress.yaml"
if (Test-Path $progressPath) {
    $progressContent = Get-Content $progressPath -Raw
    $currentTask = if ($progressContent -match "current_task_id:\s*(\d+)") { [int]$Matches[1] } else { 1 }
} else {
    $currentTask = 1
}

$auditScope = if ($TaskId -gt 0) { 
    @($TaskId) 
} else { 
    # Audit all completed tasks
    $completedTasks = @()
    if ($progressContent -match "(?s)completed_tasks:(.*?)(?:current_|$)") {
        $completedSection = $Matches[1]
        $taskMatches = [regex]::Matches($completedSection, "task_id:\s*(\d+)")
        foreach ($m in $taskMatches) {
            $completedTasks += [int]$m.Groups[1].Value
        }
    }
    $completedTasks
}

Write-Host "`n  Auditing $($auditScope.Count) task(s): $($auditScope -join ', ')" -ForegroundColor Gray

# ============================================================================
# 1. VERIFICATION FILE EXISTENCE
# ============================================================================

Write-Section "Verification Records"

$verificationPath = "$env:ORCHESTRA_ROOT/verification"

foreach ($taskNum in $auditScope) {
    $taskIdPadded = $taskNum.ToString().PadLeft(3, '0')
    
    # Check for task-XXX.yaml
    $yamlFile = "$verificationPath/task-$taskIdPadded.yaml"
    $yamlExists = Test-Path $yamlFile
    
    Add-CheckResult $checks "task-$taskIdPadded.yaml exists" $yamlExists `
        "Verification YAML not found" `
        "Create verification YAML from template" `
        $yamlFile
    
    # Check for task-XXX-results.md (optional but recommended)
    $resultsFile = "$verificationPath/task-$taskIdPadded-results.md"
    $resultsExists = Test-Path $resultsFile
    
    if (-not $resultsExists) {
        Write-CheckWarning "task-$taskIdPadded-results.md not found" `
            "Consider creating detailed results log"
    } else {
        Write-CheckPass "task-$taskIdPadded-results.md exists"
    }
}

# ============================================================================
# 2. VERIFICATION YAML COMPLETENESS
# ============================================================================

Write-Section "Verification Content Quality"

foreach ($taskNum in $auditScope) {
    $taskIdPadded = $taskNum.ToString().PadLeft(3, '0')
    $yamlFile = "$verificationPath/task-$taskIdPadded.yaml"
    
    if (-not (Test-Path $yamlFile)) { continue }
    
    $content = Get-Content $yamlFile -Raw
    
    # Required sections per VERIFICATION_TEMPLATE.yaml
    $hasTaskId = $content -match "task_id:"
    $hasTitle = $content -match "title:|task_title:"
    $hasSpeckitTasks = $content -match "speckit_tasks:"
    $hasStandardChecks = $content -match "standard_checks:|verification_criteria:"
    $hasVerificationChecks = $content -match "verification_checks:|existence:|structure:|tests:"
    
    Add-CheckResult $checks "Task ${taskNum} - Has task_id" $hasTaskId `
        "Missing task_id field" `
        "Add task_id: N to YAML" `
        $yamlFile
    
    Add-CheckResult $checks "Task ${taskNum} - Has title" $hasTitle `
        "Missing title field" `
        "Add title: 'Task description'" `
        $yamlFile
    
    Add-CheckResult $checks "Task ${taskNum} - Has speckit_tasks" $hasSpeckitTasks `
        "Missing speckit_tasks field" `
        "Add speckit_tasks: [T0XX, T0YY]" `
        $yamlFile
    
    Add-CheckResult $checks "Task ${taskNum} - Has checks section" ($hasStandardChecks -or $hasVerificationChecks) `
        "Missing verification checks" `
        "Add standard_checks or verification_checks section" `
        $yamlFile
    
    # Check for severity on all checks (per template requirement)
    $hasSeverity = $content -match "severity:\s*(BLOCKING|MAJOR|MINOR|INFO)"
    Add-CheckResult $checks "Task ${taskNum} - Has severity levels" $hasSeverity `
        "No severity levels defined on checks" `
        "Add severity: BLOCKING/MAJOR/MINOR/INFO to each check" `
        $yamlFile
    
    # Visual verification (if visual/integration task)
    $isVisual = $content -match "(?i)visual|demo|integration|category:\s*INTEGRATION"
    if ($isVisual) {
        $hasVisualVerification = $content -match "visual_verification:|visual:|screenshot"
        Add-CheckResult $checks "Task ${taskNum} - Visual verification defined" $hasVisualVerification `
            "Visual task missing visual verification section" `
            "Add visual_verification: with screenshot_path and content_checks" `
            $yamlFile
    }
}

# ============================================================================
# 3. VERIFICATION RESULTS RECORDED
# ============================================================================

Write-Section "Verification Outcomes"

foreach ($taskNum in $auditScope) {
    $taskIdPadded = $taskNum.ToString().PadLeft(3, '0')
    $resultsFile = "$verificationPath/task-$taskIdPadded-results.md"
    
    if (-not (Test-Path $resultsFile)) {
        Add-CheckResult $checks "Task ${taskNum} - Results recorded" $false `
            "No verification results file found" `
            "Create task-${taskIdPadded}-results.md with verification execution log" `
            $resultsFile
        continue
    }
    
    $content = Get-Content $resultsFile -Raw
    
    # Check for verdict in results
    $hasVerdict = $content -match "(?i)PASS|FAIL|VERIFIED|✅|❌|verdict"
    Add-CheckResult $checks "Task ${taskNum} - Has verdict" $hasVerdict `
        "Results file has no clear verdict" `
        "Add PASS/FAIL verdict to results" `
        $resultsFile
}

# ============================================================================
# 4. COMMIT TRACEABILITY
# ============================================================================

Write-Section "Commit Traceability"

foreach ($taskNum in $auditScope) {
    $taskIdPadded = $taskNum.ToString().PadLeft(3, '0')
    
    # Check progress.yaml has commit hash for completed task
    # Matches: - task_id: N ... commit: "HASH" (YAML format with quotes)
    if ($progressContent -match "(?s)-\s*task_id:\s*$taskNum\s.+?commit:\s*`"([a-f0-9]+)`"") {
        $commitHash = $Matches[1]
        
        # Verify commit exists in git
        $commitExists = (git rev-parse --verify $commitHash 2>$null) -ne $null
        Add-CheckResult $checks "Task ${taskNum} - Commit ${commitHash} exists" $commitExists `
            "Referenced commit not found in git history" `
            "Verify correct commit hash" `
            $commitHash
        
        # Check commit message mentions task
        $commitMsg = git log -1 --format=%s $commitHash 2>$null
        $mentionsTask = $commitMsg -match "(?i)task\s*$taskNum|T$taskIdPadded"
        if (-not $mentionsTask) {
            Write-CheckWarning "Commit message doesn't mention Task ${taskNum}" `
                "Consider more descriptive commit messages"
        }
    } else {
        Add-CheckResult $checks "Task ${taskNum} - Commit recorded" $false `
            "No commit hash recorded in progress.yaml" `
            "Add commit hash to task_history entry" `
            $progressPath
    }
}

# ============================================================================
# 5. SCREENSHOT CONTENT VERIFICATION (if visual)
# ============================================================================

Write-Section "Screenshot Content Verification"

$screenshotPath = "$env:ORCHESTRA_ROOT/verification/screenshots"
if (Test-Path $screenshotPath) {
    $screenshots = Get-ChildItem $screenshotPath -Filter "*.png" -ErrorAction SilentlyContinue
    
    foreach ($taskNum in $auditScope) {
        $taskIdPadded = $taskNum.ToString().PadLeft(3, '0')
        $yamlFile = "$verificationPath/task-$taskIdPadded.yaml"
        
        if (-not (Test-Path $yamlFile)) { continue }
        
        $yamlContent = Get-Content $yamlFile -Raw
        
        # Check if task has screenshots
        $taskScreenshots = $screenshots | Where-Object { $_.Name -match "task[_-]?$taskIdPadded" }
        
        if ($taskScreenshots.Count -gt 0) {
            # Verify content was actually viewed (per mandatory protocol)
            $hasContentDescription = $yamlContent -match "(?i)screenshot_content:|visual_elements:|what_was_seen:"
            
            if (-not $hasContentDescription) {
                Add-CheckResult $checks "Task ${taskNum} - Screenshot content verified" $false `
                    "Screenshot exists but content was not described" `
                    "MANDATORY: View screenshot via Chrome DevTools MCP and describe what you see" `
                    $taskScreenshots[0].FullName
            } else {
                Write-CheckPass "Task ${taskNum} - Screenshot content verified"
            }
        }
    }
} else {
    Write-Host "  No screenshots directory found" -ForegroundColor Gray
}

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta

if ($summary.AllPassed) {
    Write-Host "✅ VERIFICATION AUDIT PASSED - All records complete" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    Write-Host "`n  Audited Tasks: $($auditScope.Count)" -ForegroundColor Gray
    Write-Host "  All verification records are complete and valid." -ForegroundColor Gray
    
    exit 0
} else {
    Write-Host "❌ VERIFICATION AUDIT FAILED - Gaps in verification" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    Write-Host "`n🚫 Fix these verification gaps:" -ForegroundColor Red
    foreach ($failure in $checks.Failures) {
        Write-Host "`n   ─────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "   Check:    $($failure.Name)" -ForegroundColor Red
        Write-Host "   Problem:  $($failure.Details)" -ForegroundColor Yellow
        Write-Host "   Fix:      $($failure.Fix)" -ForegroundColor Green
    }
    
    Write-Host "`n"
    exit 1
}
