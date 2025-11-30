# Common Check Utilities
# ======================
# Shared functions for all orchestra scripts
#
# Usage: . .\.orchestra\scripts\common\check-utils.ps1

# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

function Write-Check {
    <#
    .SYNOPSIS
    Writes a check result with pass/fail formatting
    #>
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    if ($Passed) {
        Write-Host "  ✅ $Name" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $Name" -ForegroundColor Red
        if ($Details) { 
            Write-Host "     $Details" -ForegroundColor Yellow 
        }
    }
    
    return $Passed
}

function Write-CheckPass {
    <#
    .SYNOPSIS
    Writes a passing check (standalone, not in collector)
    #>
    param([string]$Name)
    
    Write-Host "  ✅ $Name" -ForegroundColor Green
}

function Write-CheckFail {
    <#
    .SYNOPSIS
    Writes a failing check (standalone, not in collector)
    #>
    param(
        [string]$Name,
        [string]$Details = ""
    )
    
    Write-Host "  ❌ $Name" -ForegroundColor Red
    if ($Details) { 
        Write-Host "     $Details" -ForegroundColor Yellow 
    }
}

function Write-CheckWarning {
    <#
    .SYNOPSIS
    Writes a warning (non-blocking but notable)
    #>
    param(
        [string]$Name,
        [string]$Details = ""
    )
    
    Write-Host "  ⚠️  $Name" -ForegroundColor Yellow
    if ($Details) { 
        Write-Host "     $Details" -ForegroundColor Yellow 
    }
}

function Write-Section {
    <#
    .SYNOPSIS
    Writes a section header
    #>
    param([string]$Name)
    
    Write-Host "`n📋 $Name" -ForegroundColor Cyan
    Write-Host ("─" * 50) -ForegroundColor DarkGray
}

function Write-FailureDetails {
    <#
    .SYNOPSIS
    Writes detailed failure information with fix instructions
    #>
    param(
        [string]$CheckName,
        [string]$Problem,
        [string]$Fix,
        [string]$Location = ""
    )
    
    Write-Host ""
    Write-Host "  ┌─ FAILURE DETAILS ─────────────────────────────────────" -ForegroundColor Red
    Write-Host "  │ Check:    $CheckName" -ForegroundColor Red
    Write-Host "  │ Problem:  $Problem" -ForegroundColor Yellow
    Write-Host "  │ Fix:      $Fix" -ForegroundColor Green
    if ($Location) {
        Write-Host "  │ Location: $Location" -ForegroundColor DarkGray
    }
    Write-Host "  └───────────────────────────────────────────────────────" -ForegroundColor Red
    Write-Host ""
}

# ============================================================================
# ENVIRONMENT HELPERS
# ============================================================================

function Get-EnvOrDefault {
    <#
    .SYNOPSIS
    Gets an environment variable or returns a default value
    #>
    param(
        [string]$Name,
        [string]$Default = ""
    )
    
    $value = [Environment]::GetEnvironmentVariable($Name)
    if ([string]::IsNullOrEmpty($value)) {
        return $Default
    }
    return $value
}

# ============================================================================
# YAML PARSING (Simple, no external dependencies)
# ============================================================================

function Get-YamlValue {
    <#
    .SYNOPSIS
    Extracts a simple value from YAML content
    #>
    param(
        [string]$Content,
        [string]$Key
    )
    
    if ($Content -match "$Key\s*:\s*[`"']?([^`"'\n]+)[`"']?") {
        return $Matches[1].Trim()
    }
    return $null
}

function Get-YamlArrayValues {
    <#
    .SYNOPSIS
    Extracts array values from YAML content (simple format)
    Example: speckit_tasks: [T001, T002, T003]
    #>
    param(
        [string]$Content,
        [string]$Key
    )
    
    if ($Content -match "$Key\s*:\s*\[([^\]]+)\]") {
        $arrayContent = $Matches[1]
        return $arrayContent -split '\s*,\s*' | ForEach-Object { $_.Trim().Trim('"').Trim("'") }
    }
    return @()
}

# ============================================================================
# TASK PARSING
# ============================================================================

function Get-SpeckitTasks {
    <#
    .SYNOPSIS
    Parses SpecKit tasks.md and returns all task IDs with their status
    Returns: @{T001 = @{checked=$true; line=15}; T002 = @{checked=$false; line=23}; ...}
    #>
    param([string]$TasksPath)
    
    if (-not (Test-Path $TasksPath)) {
        Write-Warning "tasks.md not found at $TasksPath"
        return @{}
    }
    
    $content = Get-Content $TasksPath
    $tasks = @{}
    $lineNum = 0
    
    foreach ($line in $content) {
        $lineNum++
        # Match patterns like: - [x] T001, - [ ] T002, [x] T003, [x] T012a
        # T\d+[a-z]? captures task IDs with optional letter suffix (T001, T012, T012a, T012b, etc.)
        if ($line -match '\[(x| )\]\s*(T\d+[a-z]?)') {
            $checked = $Matches[1] -eq 'x'
            $taskId = $Matches[2]
            $tasks[$taskId] = @{
                checked = $checked
                line    = $lineNum
                text    = $line.Trim()
            }
        }
    }
    
    return $tasks
}

function Get-OrchestratorTasks {
    <#
    .SYNOPSIS
    Parses manifest.yaml and returns orchestrator tasks with their SpecKit mappings
    Returns: @{1 = @{speckit_tasks=@("T001","T002"); status="completed"}; ...}
    #>
    param([string]$ManifestPath)
    
    if (-not (Test-Path $ManifestPath)) {
        Write-Warning "manifest.yaml not found at $ManifestPath"
        return @{}
    }
    
    $content = Get-Content $ManifestPath -Raw
    $tasks = @{}
    
    # Split by task entries (looking for "- id:" pattern)
    $taskBlocks = $content -split '(?=\n\s*-\s*id:\s*\d+)'
    
    foreach ($block in $taskBlocks) {
        if ($block -match 'id:\s*(\d+)') {
            $taskId = [int]$Matches[1]
            
            # Get speckit_tasks array
            $speckitTasks = @()
            if ($block -match 'speckit_tasks:\s*\[([^\]]+)\]') {
                $speckitTasks = $Matches[1] -split '\s*,\s*' | 
                ForEach-Object { $_.Trim().Trim('"').Trim("'") } |
                Where-Object { $_ -match '^T\d+[a-z]?$' }
            }
            
            # Get status
            $status = "unknown"
            if ($block -match 'status:\s*[`"'']?(\w+)[`"'']?') {
                $status = $Matches[1]
            }
            
            $tasks[$taskId] = @{
                speckit_tasks = $speckitTasks
                status        = $status
            }
        }
    }
    
    return $tasks
}

function Get-ProgressTaskStatus {
    <#
    .SYNOPSIS
    Gets task status from progress.yaml
    #>
    param(
        [string]$ProgressPath,
        [int]$TaskId
    )
    
    if (-not (Test-Path $ProgressPath)) {
        return $null
    }
    
    $content = Get-Content $ProgressPath -Raw
    
    # Find the task block
    if ($content -match "task_id:\s*$TaskId[\s\S]*?status:\s*[`"']?(\w+)[`"']?") {
        return $Matches[1]
    }
    
    return $null
}

# ============================================================================
# FILE VALIDATION
# ============================================================================

function Test-FileHasContent {
    <#
    .SYNOPSIS
    Checks if a file exists and has meaningful content
    #>
    param(
        [string]$Path,
        [int]$MinBytes = 100
    )
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    $file = Get-Item $Path
    return $file.Length -ge $MinBytes
}

function Test-TemplateComplete {
    <#
    .SYNOPSIS
    Checks if a file has any TODO/TBD markers remaining
    #>
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    $content = Get-Content $Path -Raw
    return -not ($content -match '\[TODO\]|\[TBD\]|\[PLACEHOLDER\]')
}

# ============================================================================
# GIT UTILITIES
# ============================================================================

function Get-UncommittedFiles {
    <#
    .SYNOPSIS
    Returns list of uncommitted files
    #>
    $status = git status --porcelain
    if ($status) {
        return $status -split "`n" | Where-Object { $_ }
    }
    return @()
}

function Test-FileModified {
    <#
    .SYNOPSIS
    Checks if a file has been modified in the working tree
    #>
    param([string]$Path)
    
    $diff = git diff --name-only -- $Path 2>$null
    $staged = git diff --staged --name-only -- $Path 2>$null
    
    return ($diff -or $staged)
}

function Get-CurrentBranch {
    return git branch --show-current
}

# ============================================================================
# RESULT COLLECTION
# ============================================================================

class CheckResult {
    [string]$Name
    [bool]$Passed
    [string]$Details
    [string]$Fix
    [string]$Location
    
    CheckResult([string]$name, [bool]$passed) {
        $this.Name = $name
        $this.Passed = $passed
        $this.Details = ""
        $this.Fix = ""
        $this.Location = ""
    }
    
    CheckResult([string]$name, [bool]$passed, [string]$details, [string]$fix, [string]$location) {
        $this.Name = $name
        $this.Passed = $passed
        $this.Details = $details
        $this.Fix = $fix
        $this.Location = $location
    }
}

function New-CheckCollector {
    <#
    .SYNOPSIS
    Creates a new check result collector
    #>
    return @{
        Results  = [System.Collections.ArrayList]@()
        Failures = [System.Collections.ArrayList]@()
        Warnings = [System.Collections.ArrayList]@()
    }
}

function Add-CheckResult {
    <#
    .SYNOPSIS
    Adds a check result to the collector
    #>
    param(
        [hashtable]$Collector,
        [string]$Name,
        [bool]$Passed,
        [string]$Details = "",
        [string]$Fix = "",
        [string]$Location = ""
    )
    
    $result = [CheckResult]::new($Name, $Passed, $Details, $Fix, $Location)
    $Collector.Results.Add($result) | Out-Null
    
    if (-not $Passed) {
        $Collector.Failures.Add($result) | Out-Null
    }
    
    # Display immediately
    if ($Passed) {
        Write-Host "  ✅ $Name" -ForegroundColor Green
    }
    else {
        Write-Host "  ❌ $Name" -ForegroundColor Red
        if ($Details) { Write-Host "     $Details" -ForegroundColor Yellow }
    }
    
    return $Passed
}

function Get-CheckSummary {
    <#
    .SYNOPSIS
    Returns summary of all checks
    #>
    param([hashtable]$Collector)
    
    $total = $Collector.Results.Count
    $passed = ($Collector.Results | Where-Object { $_.Passed }).Count
    $failed = $Collector.Failures.Count
    
    return @{
        Total     = $total
        Passed    = $passed
        Failed    = $failed
        AllPassed = ($failed -eq 0)
    }
}
