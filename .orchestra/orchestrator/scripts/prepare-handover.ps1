# Prepare Handover Script (Orchestrator)
# =======================================
# Clears the handover folder and populates from templates.
# Run AFTER task-closeout-check.ps1 passes.
#
# Usage: .\.orchestra\orchestrator\scripts\prepare-handover.ps1 -TaskNumber 16
#
# This script:
#   1. Clears all transient files from handover/
#   2. Preserves agent_readme.md (persistent instructions)
#   3. Copies templates to create fresh current-task.md
#   4. Creates completion-signal.md (empty, from template)
#   5. Updates task-context.md placeholder

param(
    [Parameter(Mandatory = $true)]
    [int]$TaskNumber
)

$ErrorActionPreference = "Stop"

# ============================================================================
# LOAD DEPENDENCIES
# ============================================================================

$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$scriptRoot\common\scripts\set-env.ps1" 2>$null

# ============================================================================
# HEADER
# ============================================================================

Write-Host "`n"
Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          PREPARE HANDOVER                                     ║" -ForegroundColor Cyan
Write-Host "║   Clear and populate handover for Task $($TaskNumber.ToString('D3'))                      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# VALIDATION
# ============================================================================

# Verify task number matches expected
if ($TaskNumber -ne [int]$env:CURRENT_TASK) {
    Write-Host "⚠️  Warning: TaskNumber ($TaskNumber) differs from CURRENT_TASK ($env:CURRENT_TASK)" -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -ne 'y') {
        Write-Host "❌ Aborted" -ForegroundColor Red
        exit 1
    }
}

# ============================================================================
# STEP 1: CLEAR TRANSIENT FILES
# ============================================================================

Write-Host "📋 Step 1: Clear transient handover files" -ForegroundColor White
Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray

$handoverPath = $env:HANDOVER_PATH

# Files to PRESERVE (not delete)
$preserveFiles = @(
    "agent_readme.md",
    "AGENT_README.md"  # Case variation
)

# Get all files in handover
$allFiles = Get-ChildItem -Path $handoverPath -File -ErrorAction SilentlyContinue

foreach ($file in $allFiles) {
    if ($preserveFiles -contains $file.Name) {
        Write-Host "  ⏭️  Preserved: $($file.Name)" -ForegroundColor DarkGray
    }
    else {
        Remove-Item $file.FullName -Force
        Write-Host "  🗑️  Removed: $($file.Name)" -ForegroundColor Yellow
    }
}

# ============================================================================
# STEP 2: COPY TEMPLATES
# ============================================================================

Write-Host "`n📋 Step 2: Copy templates" -ForegroundColor White
Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray

$templatesPath = $env:TEMPLATES_PATH

# Copy current-task template
$currentTaskTemplate = Join-Path $templatesPath "current-task-template.md"
$currentTaskDest = Join-Path $handoverPath "current-task.md"

if (Test-Path $currentTaskTemplate) {
    Copy-Item $currentTaskTemplate $currentTaskDest -Force
    Write-Host "  ✅ Created: current-task.md (from template)" -ForegroundColor Green
}
else {
    Write-Host "  ❌ Template not found: current-task-template.md" -ForegroundColor Red
    exit 1
}

# Copy completion-signal template (empty state)
$completionTemplate = Join-Path $templatesPath "completion-signal.md.template"
$completionDest = Join-Path $handoverPath "completion-signal.md"

if (Test-Path $completionTemplate) {
    Copy-Item $completionTemplate $completionDest -Force
    Write-Host "  ✅ Created: completion-signal.md (empty template)" -ForegroundColor Green
}
else {
    # Create minimal empty file if template doesn't exist
    "<!-- Implementor: Fill this when task is complete -->`n" | Set-Content $completionDest
    Write-Host "  ✅ Created: completion-signal.md (minimal)" -ForegroundColor Green
}

# ============================================================================
# STEP 3: UPDATE TASK-CONTEXT.MD
# ============================================================================

Write-Host "`n📋 Step 3: Update task-context.md" -ForegroundColor White
Write-Host "───────────────────────────────────────────────────────────" -ForegroundColor DarkGray

$taskContextPath = Join-Path $handoverPath "task-context.md"

# Read manifest for phase info
$manifestPath = $env:MANIFEST_PATH
if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    # Extract current phase
    if ($manifestContent -match 'current_phase:\s*"?([^"\n]+)"?') {
        $currentPhase = $Matches[1]
    }
    else {
        $currentPhase = "unknown"
    }
    
    # Extract sprint
    if ($manifestContent -match 'sprint:\s*"?([^"\n]+)"?') {
        $sprint = $Matches[1]
    }
    else {
        $sprint = "unknown"
    }
}

# Create/update task-context.md
$taskContextContent = @"
# Task Context

## Sprint Information

- **Sprint**: $sprint
- **Current Task**: $TaskNumber
- **Phase**: $currentPhase

## Background

This is Task $TaskNumber of the multi-axis normalization sprint.

See the handover document (current-task.md) for specific task details.

## Key Files

Refer to current-task.md for the files to CREATE and MODIFY.

---

*Generated by prepare-handover.ps1 at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*
"@

$taskContextContent | Set-Content $taskContextPath -Encoding UTF8
Write-Host "  ✅ Updated: task-context.md" -ForegroundColor Green

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host "`n"
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ HANDOVER PREPARED FOR TASK $TaskNumber" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor White
Write-Host "  1. Edit: $currentTaskDest" -ForegroundColor Gray
Write-Host "     - Fill in task details from manifest.yaml" -ForegroundColor Gray
Write-Host "     - Remove the orchestrator checklist comment block" -ForegroundColor Gray
Write-Host "  2. Create verification YAML if not exists:" -ForegroundColor Gray
Write-Host "     - $env:VERIFICATION_PATH/task-$($TaskNumber.ToString('D3')).yaml" -ForegroundColor Gray
Write-Host "  3. Validate handover:" -ForegroundColor Gray
Write-Host "     - .\.orchestra\orchestrator\scripts\handover-validate.ps1" -ForegroundColor Gray
Write-Host ""
