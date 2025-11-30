# Pre-Signal Check Script (Implementor)
# ======================================
# Run this BEFORE signaling completion to the orchestrator.
# Verifies all deliverables are created and tests pass.
#
# Usage: .\.orchestra\handover\.implementor\scripts\pre-signal-check.ps1
#
# Returns: Exit code 0 if all checks pass, 1 if any fail

$ErrorActionPreference = "Stop"

# ============================================================================
# LOAD COMMON UTILITIES
# ============================================================================

$orchestraRoot = (Get-Item "$PSScriptRoot\..\..\..").FullName
. "$orchestraRoot\scripts\set-env.ps1" 2>$null
. "$orchestraRoot\scripts\common\check-utils.ps1"

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n" 
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "║          IMPLEMENTOR PRE-SIGNAL CHECK                        ║" -ForegroundColor Blue
Write-Host "║   Verify deliverables before signaling completion            ║" -ForegroundColor Blue
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Blue

$checks = New-CheckCollector

# ============================================================================
# READ CURRENT TASK FOR REQUIREMENTS
# ============================================================================

$currentTaskPath = "$env:HANDOVER_PATH/current-task.md"

if (-not (Test-Path $currentTaskPath)) {
    Write-Host "`n❌ current-task.md not found!" -ForegroundColor Red
    exit 1
}

$content = Get-Content $currentTaskPath -Raw
$taskNumber = if ($content -match "Task\s+(\d+):") { $Matches[1] } else { "?" }

Write-Host "`n  Checking deliverables for Task $taskNumber" -ForegroundColor Gray

# ============================================================================
# 1. EXTRACT REQUIRED FILES FROM TASK
# ============================================================================

# Extract CREATE files
$createPaths = @()
$tableCreateMatches = [regex]::Matches($content, "(?i)\|\s*CREATE\s*\|\s*[`]?([^|`\n]+)[`]?\s*\|")
foreach ($match in $tableCreateMatches) {
    $createPaths += $match.Groups[1].Value.Trim().TrimStart('`').TrimEnd('`')
}
$listCreateMatches = [regex]::Matches($content, "(?i)-\s*CREATE[:\s]+[`]?([^\n`]+)[`]?")
foreach ($match in $listCreateMatches) {
    $createPaths += $match.Groups[1].Value.Trim().TrimStart('`').TrimEnd('`')
}

# Extract UPDATE files
$updatePaths = @()
$tableUpdateMatches = [regex]::Matches($content, "(?i)\|\s*UPDATE\s*\|\s*[`]?([^|`\n]+)[`]?\s*\|")
foreach ($match in $tableUpdateMatches) {
    $updatePaths += $match.Groups[1].Value.Trim().TrimStart('`').TrimEnd('`')
}
$listUpdateMatches = [regex]::Matches($content, "(?i)-\s*UPDATE[:\s]+[`]?([^\n`]+)[`]?")
foreach ($match in $listUpdateMatches) {
    $updatePaths += $match.Groups[1].Value.Trim().TrimStart('`').TrimEnd('`')
}

# ============================================================================
# 2. FILE CREATION CHECKS
# ============================================================================

Write-Section "Created Files"

if ($createPaths.Count -eq 0) {
    Write-Host "  No CREATE files specified in task" -ForegroundColor Gray
}
else {
    foreach ($path in $createPaths) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        
        $exists = Test-Path $path
        Add-CheckResult $checks "Created: $path" $exists `
            "File was not created" `
            "Create the file as specified in task" `
            $path
        
        if ($exists) {
            # Check it has content
            $hasContent = Test-FileHasContent $path 50
            if (-not $hasContent) {
                Add-CheckResult $checks "Has content: $path" $false `
                    "File exists but is empty or too small" `
                    "Implement the file content" `
                    $path
            }
        }
    }
}

# ============================================================================
# 3. FILE MODIFICATION CHECKS
# ============================================================================

Write-Section "Modified Files"

if ($updatePaths.Count -eq 0) {
    Write-Host "  No UPDATE files specified in task" -ForegroundColor Gray
}
else {
    foreach ($path in $updatePaths) {
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        
        # Check file was actually modified
        $isModified = Test-FileModified $path
        Add-CheckResult $checks "Modified: $path" $isModified `
            "File was not modified (git shows no changes)" `
            "Apply the required changes to this file" `
            $path
    }
}

# ============================================================================
# 4. TEST FILE CHECKS
# ============================================================================

Write-Section "Test Files"

# Find test files that should exist
$testPaths = @()

# From explicit mentions in task
$testMatches = [regex]::Matches($content, "test[/\\][^\s`]+_test\.dart")
foreach ($match in $testMatches) {
    $testPaths += $match.Value
}

# Infer from implementation files
foreach ($implPath in $createPaths) {
    if ($implPath -match "lib/src/(.+)\.dart$") {
        $relativePath = $Matches[1]
        $inferredTestPath = "test/unit/$relativePath`_test.dart"
        if ($inferredTestPath -notin $testPaths) {
            # Try multi_axis specific path
            $multiAxisTestPath = "$env:SPRINT_TEST_PATH/$($relativePath.Split('/')[-1])_test.dart"
            if ((Test-Path $multiAxisTestPath) -or (Test-Path $inferredTestPath)) {
                # Already exists, good
            }
        }
    }
}

if ($testPaths.Count -gt 0) {
    foreach ($testPath in $testPaths | Select-Object -Unique) {
        $exists = Test-Path $testPath
        Add-CheckResult $checks "Test exists: $testPath" $exists `
            "Test file not found" `
            "Create the test file (TDD)" `
            $testPath
    }
}
else {
    Write-CheckWarning "No explicit test paths found in task" `
        "Verify tests exist in $env:SPRINT_TEST_PATH"
}

# ============================================================================
# 5. CODE QUALITY CHECKS
# ============================================================================

Write-Section "Code Quality"

# Run analyzer on new/modified files
$filesToAnalyze = ($createPaths + $updatePaths) | Where-Object { 
    $_ -and (Test-Path $_) -and $_ -match "\.dart$"
}

if ($filesToAnalyze.Count -gt 0) {
    Write-Host "  Running analyzer on $($filesToAnalyze.Count) file(s)..." -ForegroundColor Gray
    
    foreach ($file in $filesToAnalyze) {
        try {
            $analyzeOutput = flutter analyze $file 2>&1 | Out-String
            $hasIssues = $analyzeOutput -match "error|warning" -and -not ($analyzeOutput -match "No issues found")
            
            Add-CheckResult $checks "No analyzer issues: $($file.Split('/')[-1])" (-not $hasIssues) `
                "Analyzer found issues" `
                "Run: flutter analyze $file" `
                $file
        }
        catch {
            Write-CheckWarning "Could not analyze $file" $_
        }
    }
}
else {
    Write-Host "  No Dart files to analyze" -ForegroundColor Gray
}

# Check for TODO/FIXME in new files
foreach ($file in $createPaths) {
    if ($file -and (Test-Path $file)) {
        $fileContent = Get-Content $file -Raw
        $hasTodos = $fileContent -match "//\s*TODO|//\s*FIXME|//\s*XXX"
        
        if ($hasTodos) {
            Add-CheckResult $checks "No TODO comments: $($file.Split('/')[-1])" $false `
                "Found TODO/FIXME comments in code" `
                "Complete or remove TODO comments before submission" `
                $file
        }
    }
}

# ============================================================================
# 6. TEST EXECUTION
# ============================================================================

Write-Section "Test Execution"

# Run sprint tests
Write-Host "  Running sprint tests..." -ForegroundColor Gray
try {
    $testOutput = flutter test $env:SPRINT_TEST_PATH --no-pub 2>&1 | Out-String
    $allPassed = $testOutput -match "All tests passed"
    $testCount = if ($testOutput -match '\+(\d+)') { $Matches[1] } else { "?" }
    
    Add-CheckResult $checks "Sprint tests pass" $allPassed `
        "Some tests failed" `
        "Run: flutter test $env:SPRINT_TEST_PATH" `
        $env:SPRINT_TEST_PATH
    
    if ($allPassed) {
        Write-Host "     $testCount tests passed" -ForegroundColor Gray
    }
}
catch {
    Add-CheckResult $checks "Sprint tests pass" $false `
        "Could not run tests: $_" `
        "Fix test environment" `
        $env:SPRINT_TEST_PATH
}

# ============================================================================
# 7. DEMO FILE CHECK (for visual tasks)
# ============================================================================

$isVisual = $content -match "(?i)VISUAL|INTEGRATION|demo"
if ($isVisual) {
    Write-Section "Visual/Demo Verification"
    
    $demoPath = "example/lib/demos/task_$($taskNumber.PadLeft(3,'0'))*.dart"
    $demoFiles = Get-ChildItem -Path "example/lib/demos" -Filter "task_$($taskNumber.PadLeft(3,'0'))*.dart" -ErrorAction SilentlyContinue
    
    if ($demoFiles) {
        Add-CheckResult $checks "Demo file created" $true $demoFiles[0].Name
        
        # Check demo has meaningful content
        $demoContent = Get-Content $demoFiles[0].FullName -Raw
        $hasWidgets = $demoContent -match "Widget|Scaffold|build\("
        Add-CheckResult $checks "Demo has widget content" $hasWidgets `
            "Demo file appears empty or incomplete" `
            "Add runnable demo widget" `
            $demoFiles[0].FullName
    }
    else {
        Add-CheckResult $checks "Demo file created" $false `
            "No demo file found for Task $taskNumber" `
            "Create example/lib/demos/task_${taskNumber}_demo.dart" `
            "example/lib/demos/"
    }
}

# ============================================================================
# 8. STAGED CHANGES CHECK
# ============================================================================

Write-Section "Git Status"

$stagedFiles = git diff --staged --name-only
$unstagedFiles = git diff --name-only

if ($stagedFiles) {
    Write-Host "  Staged files:" -ForegroundColor Gray
    $stagedFiles | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
}

$hasChanges = $stagedFiles -or $unstagedFiles
Add-CheckResult $checks "Has changes to commit" $hasChanges `
    "No git changes detected" `
    "Verify you made the required changes" `
    "git status"

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue

if ($summary.AllPassed) {
    Write-Host "✅ PRE-SIGNAL CHECK PASSED - Ready to signal completion" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "  1. Stage all changes: git add -A" -ForegroundColor White
    Write-Host "  2. Write to completion-signal.md" -ForegroundColor White
    Write-Host "  3. Say 'ready for review'" -ForegroundColor White
    
    exit 0
}
else {
    Write-Host "❌ PRE-SIGNAL CHECK FAILED - Do NOT signal completion yet" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Blue
    
    Write-Host "`n🚫 Fix these issues first:" -ForegroundColor Red
    foreach ($failure in $checks.Failures) {
        Write-Host "`n   ─────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "   Check:    $($failure.Name)" -ForegroundColor Red
        Write-Host "   Problem:  $($failure.Details)" -ForegroundColor Yellow
        Write-Host "   Fix:      $($failure.Fix)" -ForegroundColor Green
    }
    
    Write-Host "`n"
    exit 1
}
