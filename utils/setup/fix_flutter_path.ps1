<#
.SYNOPSIS
    Permanently adds Flutter to Windows User PATH environment variable

.DESCRIPTION
    This script adds G:\Media\SDK\flutter\bin to the User PATH environment variable
    so Flutter commands are available in all terminal sessions without manual setup.
    
    Run this script once to fix the "flutter command not found" issue permanently.

.NOTES
    Author: Braven Charts Team
    Date: October 4, 2025
    
.EXAMPLE
    .\fix_flutter_path.ps1
#>

#Requires -Version 5.1

[CmdletBinding()]
param()

# Set error action preference
$ErrorActionPreference = "Stop"

# Flutter path to add
$flutterPath = "G:\Media\SDK\flutter\bin"

Write-Host ""
Write-Host "🔧 Flutter PATH Fix Script" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator (not required but recommended)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Host "✅ Running as Administrator" -ForegroundColor Green
}
else {
    Write-Host "⚠️  Not running as Administrator (this is okay)" -ForegroundColor Yellow
    Write-Host "   If this fails, try running: 'Run as Administrator'" -ForegroundColor Yellow
}
Write-Host ""

# Verify Flutter installation exists
Write-Host "🔍 Checking Flutter installation..." -ForegroundColor Cyan
if (Test-Path $flutterPath) {
    Write-Host "✅ Flutter directory found: $flutterPath" -ForegroundColor Green
}
else {
    Write-Host "❌ ERROR: Flutter directory not found at: $flutterPath" -ForegroundColor Red
    Write-Host "   Please verify your Flutter installation location." -ForegroundColor Red
    exit 1
}

if (Test-Path "$flutterPath\flutter.bat") {
    Write-Host "✅ Flutter executable found" -ForegroundColor Green
}
else {
    Write-Host "❌ ERROR: flutter.bat not found in $flutterPath" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Get current User PATH
Write-Host "📋 Reading current User PATH..." -ForegroundColor Cyan
try {
    $currentPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
    if ([string]::IsNullOrEmpty($currentPath)) {
        $currentPath = ""
        Write-Host "⚠️  User PATH is empty (this is unusual but okay)" -ForegroundColor Yellow
    }
    else {
        Write-Host "✅ Current User PATH retrieved" -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ ERROR: Could not read User PATH environment variable" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Check if Flutter is already in PATH
Write-Host "🔍 Checking if Flutter is already in PATH..." -ForegroundColor Cyan
$pathEntries = $currentPath -split ';' | Where-Object { $_ -ne '' }
$flutterInPath = $pathEntries | Where-Object { $_ -like "*flutter\bin*" }

if ($flutterInPath) {
    Write-Host "⚠️  Flutter is already in User PATH:" -ForegroundColor Yellow
    $flutterInPath | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    Write-Host ""
    
    $response = Read-Host "Do you want to clean up and re-add Flutter? (y/n)"
    if ($response -ne 'y' -and $response -ne 'Y') {
        Write-Host "❌ Operation cancelled by user" -ForegroundColor Yellow
        exit 0
    }
    
    # Remove existing Flutter paths
    Write-Host ""
    Write-Host "🧹 Removing existing Flutter paths..." -ForegroundColor Cyan
    $pathEntries = $pathEntries | Where-Object { $_ -notlike "*flutter*" }
    Write-Host "✅ Existing Flutter paths removed" -ForegroundColor Green
}
Write-Host ""

# Add Flutter to PATH
Write-Host "➕ Adding Flutter to User PATH..." -ForegroundColor Cyan
try {
    # Build new PATH with Flutter first (for priority)
    $newPathEntries = @($flutterPath) + $pathEntries
    $newPath = ($newPathEntries | Where-Object { $_ -ne '' }) -join ';'
    
    # Set the new PATH
    [System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
    Write-Host "✅ Flutter added to User PATH successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ ERROR: Failed to update User PATH" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    Write-Host "   You may need to run this script as Administrator" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Verify the change
Write-Host "🔍 Verifying PATH update..." -ForegroundColor Cyan
$verifyPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User')
if ($verifyPath -like "*$flutterPath*") {
    Write-Host "✅ Verification successful - Flutter is in User PATH!" -ForegroundColor Green
}
else {
    Write-Host "⚠️  WARNING: Verification failed - Flutter may not have been added" -ForegroundColor Yellow
}
Write-Host ""

# Success message
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "✅ SUCCESS! Flutter PATH Configuration Complete" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📝 IMPORTANT - Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. CLOSE ALL TERMINAL WINDOWS (including this one)" -ForegroundColor Yellow
Write-Host "2. RESTART VS CODE completely" -ForegroundColor Yellow
Write-Host "3. Open a new terminal and test:" -ForegroundColor Yellow
Write-Host "   flutter --version" -ForegroundColor White
Write-Host ""
Write-Host "If 'flutter --version' works without any PATH setup," -ForegroundColor Green
Write-Host "then the fix is permanent! 🎉" -ForegroundColor Green
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Optional: Update current session PATH
Write-Host "💡 TIP: To use Flutter in THIS session without restarting:" -ForegroundColor Cyan
Write-Host "   `$env:PATH = `"$flutterPath;`$env:PATH`"" -ForegroundColor White
Write-Host ""

# Create a verification test
Write-Host "🧪 Testing Flutter in current session..." -ForegroundColor Cyan
$env:PATH = "$flutterPath;$env:PATH"
try {
    $flutterVersion = & flutter --version 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Flutter is working in current session!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Flutter version:" -ForegroundColor Cyan
        Write-Host $flutterVersion -ForegroundColor Gray
    }
    else {
        Write-Host "⚠️  Flutter command found but returned an error" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "⚠️  Could not test Flutter in current session" -ForegroundColor Yellow
    Write-Host "   This is normal - restart your terminal to use Flutter" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "✨ Script completed successfully!" -ForegroundColor Green
Write-Host ""
