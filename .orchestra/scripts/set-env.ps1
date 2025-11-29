# Orchestra Environment Setup
# ===========================
# Sets environment variables for the current sprint.
# Run this at the start of any orchestrator session.
#
# Usage: . .\.orchestra\scripts\set-env.ps1
# (Note the dot-space prefix for sourcing)

param(
    [string]$SprintOverride,  # Override sprint name
    [int]$TaskOverride        # Override current task
)

$ErrorActionPreference = "Stop"

# ============================================================================
# SPRINT CONFIGURATION
# Edit these values when starting a new sprint
# ============================================================================

$script:CONFIG = @{
    # Sprint identification
    SprintName = "011-multi-axis-normalization"
    
    # Paths (relative to repo root)
    OrchestraRoot = ".orchestra"
    SpeckitRoot = "specs/011-multi-axis-normalization"
    SprintTestPath = "test/unit/multi_axis"
    SprintIntegrationTestPath = "test/integration"
    ScreenshotPath = ".orchestra/screenshots"
    
    # File patterns
    TestFilePattern = "test/unit/multi_axis/*_test.dart"
    ImplementationPath = "lib/src"
}

# ============================================================================
# SET ENVIRONMENT VARIABLES
# ============================================================================

# Sprint-level (static for the sprint)
$env:ORCHESTRA_ROOT = $script:CONFIG.OrchestraRoot
$env:SPECKIT_ROOT = if ($SprintOverride) { "specs/$SprintOverride" } else { $script:CONFIG.SpeckitRoot }
$env:SPRINT_NAME = if ($SprintOverride) { $SprintOverride } else { $script:CONFIG.SprintName }
$env:SPRINT_TEST_PATH = $script:CONFIG.SprintTestPath
$env:SPRINT_INTEGRATION_TEST_PATH = $script:CONFIG.SprintIntegrationTestPath
$env:SCREENSHOT_PATH = $script:CONFIG.ScreenshotPath
$env:IMPLEMENTATION_PATH = $script:CONFIG.ImplementationPath

# Task-level (derived from progress.yaml)
$progressPath = "$env:ORCHESTRA_ROOT/progress.yaml"
if (Test-Path $progressPath) {
    $progressContent = Get-Content $progressPath -Raw
    
    if ($TaskOverride) {
        $env:CURRENT_TASK = $TaskOverride
    } elseif ($progressContent -match 'current_task_id:\s*(\d+)') {
        $env:CURRENT_TASK = [int]$Matches[1]
    } else {
        $env:CURRENT_TASK = 1
    }
    
    $env:PREVIOUS_TASK = [Math]::Max(0, [int]$env:CURRENT_TASK - 1)
} else {
    Write-Warning "progress.yaml not found - using defaults"
    $env:CURRENT_TASK = if ($TaskOverride) { $TaskOverride } else { 1 }
    $env:PREVIOUS_TASK = 0
}

# Derived paths
$env:MANIFEST_PATH = "$env:ORCHESTRA_ROOT/manifest.yaml"
$env:PROGRESS_PATH = "$env:ORCHESTRA_ROOT/progress.yaml"
$env:SPECKIT_TASKS_PATH = "$env:SPECKIT_ROOT/tasks.md"
$env:HANDOVER_PATH = "$env:ORCHESTRA_ROOT/handover"
$env:VERIFICATION_PATH = "$env:ORCHESTRA_ROOT/verification"
$env:TEMPLATES_PATH = "$env:ORCHESTRA_ROOT/templates"

# ============================================================================
# DISPLAY CURRENT STATE
# ============================================================================

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              ORCHESTRA ENVIRONMENT LOADED                     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Sprint:        $env:SPRINT_NAME" -ForegroundColor White
Write-Host "  Current Task:  $env:CURRENT_TASK" -ForegroundColor Green
Write-Host "  Previous Task: $env:PREVIOUS_TASK" -ForegroundColor Gray
Write-Host ""
Write-Host "  Paths:" -ForegroundColor DarkGray
Write-Host "    Orchestra:   $env:ORCHESTRA_ROOT" -ForegroundColor DarkGray
Write-Host "    SpecKit:     $env:SPECKIT_ROOT" -ForegroundColor DarkGray
Write-Host "    Tests:       $env:SPRINT_TEST_PATH" -ForegroundColor DarkGray
Write-Host ""

# ============================================================================
# EXPORT HELPER FUNCTION
# ============================================================================

function global:Get-OrchestraEnv {
    <#
    .SYNOPSIS
    Returns all orchestra environment variables as a hashtable
    #>
    @{
        ORCHESTRA_ROOT = $env:ORCHESTRA_ROOT
        SPECKIT_ROOT = $env:SPECKIT_ROOT
        SPRINT_NAME = $env:SPRINT_NAME
        CURRENT_TASK = $env:CURRENT_TASK
        PREVIOUS_TASK = $env:PREVIOUS_TASK
        SPRINT_TEST_PATH = $env:SPRINT_TEST_PATH
        MANIFEST_PATH = $env:MANIFEST_PATH
        PROGRESS_PATH = $env:PROGRESS_PATH
        SPECKIT_TASKS_PATH = $env:SPECKIT_TASKS_PATH
        HANDOVER_PATH = $env:HANDOVER_PATH
        VERIFICATION_PATH = $env:VERIFICATION_PATH
        SCREENSHOT_PATH = $env:SCREENSHOT_PATH
    }
}
