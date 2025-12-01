# Handover Validate Script (Orchestrator)
# ========================================
# Validates that current-task.md is complete and follows template.
# Run AFTER creating handover, BEFORE handing off to implementor.
#
# Usage: .\.orchestra\orchestrator\scripts\handover-validate.ps1
#
# Returns: Exit code 0 if valid, 1 if invalid

$ErrorActionPreference = "Stop"

# ============================================================================
# LOAD COMMON UTILITIES
# ============================================================================

$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$scriptRoot\common\scripts\set-env.ps1" 2>$null
. "$scriptRoot\common\scripts\check-utils.ps1"

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║          HANDOVER VALIDATION                                 ║" -ForegroundColor Green
Write-Host "║   Verify current-task.md is complete and correct             ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Green

$checks = New-CheckCollector

# ============================================================================
# CHECK FILE EXISTS
# ============================================================================

$currentTaskPath = "$env:HANDOVER_PATH/current-task.md"

if (-not (Test-Path $currentTaskPath)) {
    Write-Host "`n❌ current-task.md not found at: $currentTaskPath" -ForegroundColor Red
    Write-Host "   Create the handover document first." -ForegroundColor Yellow
    exit 1
}

$content = Get-Content $currentTaskPath -Raw
$lineCount = ($content -split "`n").Count

Write-Host "`n  Validating: current-task.md ($lineCount lines)" -ForegroundColor Gray

# ============================================================================
# 1. HEADER VALIDATION
# ============================================================================

Write-Section "Header & Metadata"

# Task number and title
$hasTaskTitle = $content -match "^#\s+Task\s+\d+:"
Add-CheckResult $checks "Has task title (# Task N: ...)" $hasTaskTitle `
    "Missing task header" `
    "Add '# Task N: Title' as first line" `
    $currentTaskPath

# Extract task info for later checks
$taskNumber = if ($content -match "Task\s+(\d+):") { $Matches[1] } else { "?" }
$taskTitle = if ($content -match "Task\s+\d+:\s*(.+)") { $Matches[1].Trim() } else { "" }

Write-Host "     Task ${taskNumber}: ${taskTitle}" -ForegroundColor Gray

# Sprint/spec reference
$hasSprintRef = $content -match "(?i)sprint|spec|011-multi-axis"
Add-CheckResult $checks "References sprint/spec" $hasSprintRef `
    "No reference to sprint or spec" `
    "Add context about which sprint/spec this belongs to" `
    $currentTaskPath

# ============================================================================
# 2. OBJECTIVE SECTION
# ============================================================================

Write-Section "Objective"

$hasObjective = $content -match "(?i)##\s*(Objective|Goal|Purpose)"
Add-CheckResult $checks "Has Objective section" $hasObjective `
    "Missing ## Objective section" `
    "Add '## Objective' with clear single-sentence goal" `
    $currentTaskPath

# Check objective is specific
if ($hasObjective) {
    $objectiveMatch = [regex]::Match($content, "(?i)##\s*Objective[^\n]*\n+([^\n#]+)")
    if ($objectiveMatch.Success) {
        $objectiveText = $objectiveMatch.Groups[1].Value
        $isVague = $objectiveText -match "(?i)^(implement|create|add|update)\s+(the|some|a)\s*$"
        
        if ($isVague -or $objectiveText.Length -lt 30) {
            Write-CheckWarning "Objective may be too vague" `
                "Be more specific about what exactly to implement"
        }
        else {
            Write-CheckPass "Objective appears specific"
        }
    }
}

# ============================================================================
# 3. FILE OPERATIONS
# ============================================================================

Write-Section "File Operations"

# Must have either CREATE or UPDATE
$hasFileOps = $content -match "(?i)\|\s*(CREATE|UPDATE)\s*\|" -or 
$content -match "(?i)-\s*(CREATE|UPDATE):"
Add-CheckResult $checks "Has file operations (CREATE/UPDATE)" $hasFileOps `
    "No CREATE or UPDATE operations specified" `
    "Add file operations table or list" `
    $currentTaskPath

# Check for placeholders
$hasPlaceholders = $content -match "\[TO BE DETERMINED\]|\[TBD\]|<path>|<file>"
if ($hasPlaceholders) {
    Add-CheckResult $checks "No file path placeholders" $false `
        "Found placeholder paths like [TBD] or <path>" `
        "Replace all placeholders with actual file paths" `
        $currentTaskPath
}
else {
    Write-CheckPass "No placeholders in file paths"
}

# Validate paths are complete (skip complex regex for now - rely on other checks)
# $pathMatches = [regex]::Matches($content, '(?i)\|\s*(?:CREATE|UPDATE)\s*\|\s*`?([^|`\n]+)`?\s*\|')
foreach ($match in $pathMatches) {
    $path = $match.Groups[1].Value.Trim()
    
    # Check path is specific (has folder and extension)
    $isComplete = $path -match "[\\/]" -and $path -match "\.\w+$"
    if (-not $isComplete) {
        Add-CheckResult $checks "Path complete: $path" $false `
            "Path appears incomplete (no folder or extension)" `
            "Provide full relative path with extension" `
            $path
    }
}

# ============================================================================
# 4. TDD SECTION
# ============================================================================

Write-Section "TDD / Testing"

$hasTDD = $content -match "(?i)##\s*(TDD|Test|Testing)"
Add-CheckResult $checks "Has TDD/Testing section" $hasTDD `
    "Missing ## TDD or ## Testing section" `
    "Add TDD section with test-first approach" `
    $currentTaskPath

if ($hasTDD) {
    # Check for test expectations
    $hasTestExpectations = $content -match "(?i)test.*should|expect|verify|assert|group\(|test\("
    Add-CheckResult $checks "Has test expectations" $hasTestExpectations `
        "TDD section has no test expectations" `
        "Add specific test cases with expected behaviors" `
        $currentTaskPath
    
    # Check test path is specified
    $hasTestPath = $content -match "test/unit/|_test\.dart"
    Add-CheckResult $checks "Test file path specified" $hasTestPath `
        "No test file path specified" `
        "Add path to test file (e.g., test/unit/multi_axis/xxx_test.dart)" `
        $currentTaskPath
}

# ============================================================================
# 5. ACCEPTANCE CRITERIA
# ============================================================================

Write-Section "Acceptance Criteria"

$hasAC = $content -match "(?i)##\s*(Acceptance|Success|Done|Criteria)"
Add-CheckResult $checks "Has Acceptance Criteria" $hasAC `
    "Missing acceptance criteria section" `
    "Add '## Acceptance Criteria' with checkable items" `
    $currentTaskPath

if ($hasAC) {
    # Check for checkbox items
    $hasCheckboxes = $content -match "\[ \]|\[x\]"
    if ($hasCheckboxes) {
        Write-CheckPass "Has checkbox items"
    }
    else {
        Write-CheckWarning "No checkbox items in acceptance criteria" `
            "Use [ ] for checkable acceptance items"
    }
}

# ============================================================================
# 6. DEPENDENCIES & CONTEXT
# ============================================================================

Write-Section "Dependencies & Context"

# Previous task reference (if not Task 1)
if ($taskNumber -ne "1") {
    $hasPrevRef = $content -match "(?i)Task\s+$([int]$taskNumber - 1)|previous|builds on|depends on"
    if ($hasPrevRef) {
        Write-CheckPass "References previous task context"
    }
    else {
        Write-CheckWarning "No reference to previous task" `
            "Consider adding context about what previous task delivered"
    }
}

# Code examples or references
$hasCodeExamples = $content -match '```dart|```typescript|```'
if ($hasCodeExamples) {
    Write-CheckPass "Has code examples"
}
else {
    Write-CheckWarning "No code examples" `
        "Consider adding code snippets to clarify expectations"
}

# ============================================================================
# 7. NO INCOMPLETE MARKERS
# ============================================================================

Write-Section "Completeness"

$hasTodo = $content -match "TODO:| FIXME: | XXX: | INCOMPLETE:"
if ($hasTodo) {
    Add-CheckResult $checks "No TODO markers" $false `
        "Found TODO/FIXME markers in handover" `
        "Complete all TODO items before handover" `
        $currentTaskPath
}
else {
    Write-CheckPass "No TODO markers"
}

$hasEllipsis = $content -match "\.\.\.\s*$| …\s*$"
if ($hasEllipsis) {
    Add-CheckResult $checks "No incomplete ellipsis" $false `
        "Found '...' suggesting incomplete content" `
        "Complete all sections fully" `
        $currentTaskPath
}

# ============================================================================
# 8. LENGTH CHECK
# ============================================================================

Write-Section "Document Quality"

$wordCount = ($content -split '\s+').Count

if ($wordCount -lt 200) {
    Add-CheckResult $checks "Sufficient detail ($wordCount words)" $false `
        "Document too short ($wordCount words)" `
        "Add more detail (target 300+ words)" `
        $currentTaskPath
}
elseif ($wordCount -lt 300) {
    Write-CheckWarning "Document may be light on detail ($wordCount words)" `
        "Consider adding more context"
}
else {
    Write-CheckPass "Sufficient detail ($wordCount words)"
}

# ============================================================================
# 9. CROSS-REFERENCE TO PROGRESS
# ============================================================================

Write-Section "Progress Alignment"

$progressPath = "$env:PROGRESS_PATH"
if (Test-Path $progressPath) {
    $progressContent = Get-Content $progressPath -Raw
    $currentTaskInProgress = if ($progressContent -match "current_task_id:\s*(\d+)") { $Matches[1] } else { "?" }
    
    $matches = $taskNumber -eq $currentTaskInProgress
    Add-CheckResult $checks "Task matches progress.yaml" $matches `
        "Handover is for Task $taskNumber but progress.yaml shows Task $currentTaskInProgress" `
        "Update progress.yaml or correct task number" `
        $progressPath
    
    # Check current phase and verify task-context.md reflects it
    $currentPhase = ""
    if ($progressContent -match 'current_phase:\s*"?(\w+)"?') {
        $currentPhase = $Matches[1]
    }
    
    if ($currentPhase) {
        $taskContextPath = "$env:HANDOVER_PATH/task-context.md"
        if (Test-Path $taskContextPath) {
            $contextContent = Get-Content $taskContextPath -Raw
            $hasPhaseRef = $contextContent -match "(?i)\bphase\b.*$currentPhase | $currentPhase.*\bphase\b | \*\*Phase\*\*:\s*$currentPhase"
            
            Add-CheckResult $checks "task-context.md reflects '$currentPhase' phase" $hasPhaseRef `
                "task-context.md doesn't reference current phase '$currentPhase'" `
                "Update task-context.md with current phase info before handover" `
                $taskContextPath
        }
        else {
            Add-CheckResult $checks "task-context.md exists" $false `
                "task-context.md not found" `
                "Create task-context.md with sprint background and current phase" `
                $taskContextPath
        }
    }
}

# ============================================================================
# 10. COMPLETION-SIGNAL.MD MUST NOT EXIST (Fresh start for each task)
# ============================================================================

Write-Section "Pre-Handover State"

$completionPath = "$env:HANDOVER_PATH/completion-signal.md"
if (Test-Path $completionPath) {
    # File should not exist - closeout should have deleted it
    Add-CheckResult $checks "completion-signal.md cleaned up" $false `
        "completion-signal.md exists from previous task" `
        "Run task-closeout-check.ps1 -Fix to delete it, or delete manually" `
        $completionPath
}
else {
    Add-CheckResult $checks "completion-signal.md cleaned up" $true
}

# ============================================================================
# 11. VERIFICATION YAML MUST EXIST
# ============================================================================

Write-Section "Verification Criteria"

$taskIdPadded = ([int]$taskNumber).ToString().PadLeft(3, '0')
$verificationYamlPath = "$env:VERIFICATION_PATH/task-$taskIdPadded.yaml"

$verificationExists = Test-Path $verificationYamlPath
Add-CheckResult $checks "Verification YAML exists (task-$taskIdPadded.yaml)" $verificationExists `
    "Verification criteria not defined for Task $taskNumber" `
    "Create $verificationYamlPath with hidden verification criteria BEFORE handover" `
    $verificationYamlPath

if ($verificationExists) {
    $yamlContent = Get-Content $verificationYamlPath -Raw
    
    # Check for required sections
    $hasSeverity = $yamlContent -match "severity:\s*(BLOCKING|MAJOR|MINOR|INFO)"
    Add-CheckResult $checks "Verification has severity levels" $hasSeverity `
        "No severity levels defined" `
        "Add severity: BLOCKING/MAJOR/MINOR/INFO to each check" `
        $verificationYamlPath
}

# ============================================================================
# 12. TASK CATEGORY IN MANIFEST
# ============================================================================

Write-Section "Manifest Completeness"

if (Test-Path $env:MANIFEST_PATH) {
    $manifestContent = Get-Content $env:MANIFEST_PATH -Raw
    
    # Check task has category defined
    # Use a multi-line approach: look for "id: N" followed by category within same task block
    # The pattern finds "- id: N" then looks ahead for category before the next "- id:"
    $pattern = "(?s)-\s*id:\s*$taskNumber\b.*?category:\s*[`"']?(\w+)[`"']?(?=.*?(?:-\s*id:|\z))"
    $hasCategory = $manifestContent -match $pattern
    $category = if ($hasCategory) { $Matches[1] } else { "missing" }
    
    Add-CheckResult $checks "Task $taskNumber has category in manifest" $hasCategory `
        "No category field for Task $taskNumber" `
        "Add 'category: infrastructure|integration|visual' to manifest.yaml task entry" `
        $env:MANIFEST_PATH
    
    if ($hasCategory) {
        Write-Host "     Category: $category" -ForegroundColor Gray
        
        # If visual/integration, verify Section 7 is present in handover
        if ($category -eq "visual" -or $category -eq "integration") {
            $hasVisualSection = $content -match "(?i)##\s*(7\.|Visual|Flutter Agent)"
            Add-CheckResult $checks "Visual verification section for $category task" $hasVisualSection `
                "$category task requires Section 7 (Visual Verification) with flutter_agent.py workflow" `
                "Add Section 7 with standalone demo and flutter_agent.py commands" `
                $currentTaskPath
        }
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green

if ($summary.AllPassed) {
    Write-Host "✅ HANDOVER VALIDATION PASSED - Ready for implementor" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    
    Write-Host "`n  Task $taskNumber handover is complete and valid." -ForegroundColor Gray
    Write-Host "`n  Next steps:" -ForegroundColor Cyan
    Write-Host "    1. Commit the handover document" -ForegroundColor White
    Write-Host "    2. Hand off to implementor agent" -ForegroundColor White
    Write-Host "    3. Implementor runs: validate-handover.ps1" -ForegroundColor White
    
    exit 0
}
else {
    Write-Host "❌ HANDOVER VALIDATION FAILED - Fix before handoff" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
    
    Write-Host "`n🚫 Fix these issues:" -ForegroundColor Red
    foreach ($failure in $checks.Failures) {
        Write-Host "`n   ─────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "   Check:    $($failure.Name)" -ForegroundColor Red
        Write-Host "   Problem:  $($failure.Details)" -ForegroundColor Yellow
        Write-Host "   Fix:      $($failure.Fix)" -ForegroundColor Green
    }
    
    Write-Host "`n"
    exit 1
}
