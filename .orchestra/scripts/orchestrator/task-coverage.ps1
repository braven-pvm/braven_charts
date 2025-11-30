# Task Coverage Check Script (Orchestrator)
# ==========================================
# Verifies bidirectional sync between SpecKit tasks and Orchestrator tasks.
# Run periodically to ensure all tasks are properly mapped.
#
# Usage: .\.orchestra\scripts\orchestrator\task-coverage.ps1
#
# Returns: Exit code 0 if all checks pass, 1 if any fail

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
Write-Host "║          TASK COVERAGE CHECK                                 ║" -ForegroundColor Magenta
Write-Host "║   SpecKit ↔ Orchestrator Bidirectional Sync                 ║" -ForegroundColor Magenta
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta

$checks = New-CheckCollector

# ============================================================================
# 1. PARSE SPECKIT TASKS
# ============================================================================

Write-Section "SpecKit Tasks ($env:SPECKIT_TASKS_PATH)"

$speckitTasks = Get-SpeckitTasks $env:SPECKIT_TASKS_PATH
$speckitCount = $speckitTasks.Count

if ($speckitCount -eq 0) {
    Add-CheckResult $checks "SpecKit tasks found" $false `
        "No tasks found in tasks.md" `
        "Verify tasks.md format uses [x] TXXX or [ ] TXXX pattern" `
        $env:SPECKIT_TASKS_PATH
    
    Write-Host "`n❌ Cannot continue without SpecKit tasks" -ForegroundColor Red
    exit 1
}

Write-Host "  Found $speckitCount SpecKit tasks" -ForegroundColor Gray

$checkedTasks = ($speckitTasks.Values | Where-Object { $_.checked }).Count
$uncheckedTasks = $speckitCount - $checkedTasks
Write-Host "  Checked: $checkedTasks | Unchecked: $uncheckedTasks" -ForegroundColor Gray

# ============================================================================
# 2. PARSE ORCHESTRATOR TASKS
# ============================================================================

Write-Section "Orchestrator Tasks ($env:MANIFEST_PATH)"

$orchestratorTasks = Get-OrchestratorTasks $env:MANIFEST_PATH
$orchestratorCount = $orchestratorTasks.Count

if ($orchestratorCount -eq 0) {
    Add-CheckResult $checks "Orchestrator tasks found" $false `
        "No tasks found in manifest.yaml" `
        "Verify manifest.yaml format" `
        $env:MANIFEST_PATH
    
    Write-Host "`n❌ Cannot continue without orchestrator tasks" -ForegroundColor Red
    exit 1
}

Write-Host "  Found $orchestratorCount orchestrator tasks" -ForegroundColor Gray

# Count speckit task references
$allReferences = @()
foreach ($task in $orchestratorTasks.Values) {
    $allReferences += $task.speckit_tasks
}
$uniqueReferences = $allReferences | Select-Object -Unique
Write-Host "  Referencing $($uniqueReferences.Count) unique SpecKit tasks" -ForegroundColor Gray

# ============================================================================
# 3. CHECK: Every SpecKit task mapped to orchestrator
# ============================================================================

Write-Section "Coverage: SpecKit → Orchestrator"

$unmappedSpeckit = @()
foreach ($taskId in $speckitTasks.Keys | Sort-Object) {
    $found = $orchestratorTasks.Values | Where-Object { $_.speckit_tasks -contains $taskId }
    if (-not $found) {
        $unmappedSpeckit += $taskId
    }
}

if ($unmappedSpeckit.Count -eq 0) {
    Add-CheckResult $checks "All SpecKit tasks mapped" $true
}
else {
    Add-CheckResult $checks "All SpecKit tasks mapped" $false `
        "$($unmappedSpeckit.Count) task(s) not mapped to any orchestrator task" `
        "Add these tasks to speckit_tasks array in manifest.yaml" `
        $env:MANIFEST_PATH
    
    Write-Host "`n  Unmapped SpecKit tasks:" -ForegroundColor Yellow
    foreach ($taskId in $unmappedSpeckit) {
        $line = $speckitTasks[$taskId].line
        Write-Host "    $taskId (line $line)" -ForegroundColor Yellow
    }
}

# ============================================================================
# 4. CHECK: Orchestrator references exist in SpecKit
# ============================================================================

Write-Section "Coverage: Orchestrator → SpecKit"

$orphanedReferences = @()
foreach ($ref in $uniqueReferences) {
    if (-not $speckitTasks.ContainsKey($ref)) {
        $orphanedReferences += $ref
    }
}

if ($orphanedReferences.Count -eq 0) {
    Add-CheckResult $checks "All orchestrator references valid" $true
}
else {
    Add-CheckResult $checks "All orchestrator references valid" $false `
        "$($orphanedReferences.Count) reference(s) to non-existent SpecKit tasks" `
        "Remove or correct these references in manifest.yaml" `
        $env:MANIFEST_PATH
    
    Write-Host "`n  Orphaned references:" -ForegroundColor Yellow
    foreach ($ref in $orphanedReferences) {
        Write-Host "    $ref (not found in tasks.md)" -ForegroundColor Yellow
    }
}

# ============================================================================
# 5. CHECK: Completion sync
# ============================================================================

Write-Section "Completion Sync"

$outOfSync = @()

foreach ($orchTaskId in $orchestratorTasks.Keys | Sort-Object) {
    $orchTask = $orchestratorTasks[$orchTaskId]
    
    if ($orchTask.status -eq "completed") {
        # Check all SpecKit tasks should be checked
        foreach ($speckitId in $orchTask.speckit_tasks) {
            if ($speckitTasks.ContainsKey($speckitId)) {
                if (-not $speckitTasks[$speckitId].checked) {
                    $outOfSync += @{
                        OrchestratorTask = $orchTaskId
                        SpeckitTask      = $speckitId
                        Issue            = "Orchestrator completed but SpecKit unchecked"
                    }
                }
            }
        }
    }
    elseif ($orchTask.status -eq "not_started" -or $orchTask.status -eq "pending") {
        # Check no SpecKit tasks should be checked (unless by another completed task)
        foreach ($speckitId in $orchTask.speckit_tasks) {
            if ($speckitTasks.ContainsKey($speckitId) -and $speckitTasks[$speckitId].checked) {
                # Check if another completed task also references this
                $alsoCompletedBy = $orchestratorTasks.GetEnumerator() | Where-Object {
                    $_.Key -ne $orchTaskId -and 
                    $_.Value.status -eq "completed" -and 
                    $_.Value.speckit_tasks -contains $speckitId
                }
                
                if (-not $alsoCompletedBy) {
                    $outOfSync += @{
                        OrchestratorTask = $orchTaskId
                        SpeckitTask      = $speckitId
                        Issue            = "SpecKit checked but Orchestrator not completed"
                    }
                }
            }
        }
    }
}

if ($outOfSync.Count -eq 0) {
    Add-CheckResult $checks "Completion status in sync" $true
}
else {
    Add-CheckResult $checks "Completion status in sync" $false `
        "$($outOfSync.Count) sync issue(s) found" `
        "Update either SpecKit tasks.md or orchestrator progress" `
        "See details below"
    
    Write-Host "`n  Sync issues:" -ForegroundColor Yellow
    foreach ($issue in $outOfSync) {
        Write-Host "    Orch Task $($issue.OrchestratorTask) / $($issue.SpeckitTask): $($issue.Issue)" -ForegroundColor Yellow
    }
}

# ============================================================================
# 6. CHECK: No duplicate mappings (warning only)
# ============================================================================

Write-Section "Duplicate Mappings (Info)"

$referenceCounts = @{}
foreach ($ref in $allReferences) {
    if ($referenceCounts.ContainsKey($ref)) {
        $referenceCounts[$ref]++
    }
    else {
        $referenceCounts[$ref] = 1
    }
}

$duplicates = $referenceCounts.GetEnumerator() | Where-Object { $_.Value -gt 1 }

if ($duplicates) {
    Write-Host "  ⚠️  Some SpecKit tasks mapped to multiple orchestrator tasks:" -ForegroundColor Yellow
    foreach ($dup in $duplicates) {
        Write-Host "    $($dup.Key): mapped $($dup.Value) times" -ForegroundColor Yellow
    }
    Write-Host "  (This may be intentional for shared tasks)" -ForegroundColor DarkGray
}
else {
    Write-Host "  ✅ No duplicate mappings (each SpecKit task → one orchestrator task)" -ForegroundColor Green
}

# ============================================================================
# SUMMARY
# ============================================================================

$summary = Get-CheckSummary $checks

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta

# Statistics
Write-Host "`n📊 Coverage Statistics:" -ForegroundColor Cyan
Write-Host "   SpecKit tasks:      $speckitCount total ($checkedTasks checked, $uncheckedTasks remaining)" -ForegroundColor White
Write-Host "   Orchestrator tasks: $orchestratorCount" -ForegroundColor White
Write-Host "   Mapped SpecKit:     $($speckitCount - $unmappedSpeckit.Count) / $speckitCount ($([math]::Round(($speckitCount - $unmappedSpeckit.Count) / $speckitCount * 100, 1))%)" -ForegroundColor White

if ($summary.AllPassed) {
    Write-Host "`n✅ ALL COVERAGE CHECKS PASSED" -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    exit 0
}
else {
    Write-Host "`n❌ $($summary.Failed) COVERAGE CHECK(S) FAILED" -ForegroundColor Red
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    
    Write-Host "`nFix the issues listed above before proceeding." -ForegroundColor Yellow
    exit 1
}
