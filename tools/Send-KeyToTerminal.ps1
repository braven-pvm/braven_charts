<# 
.SYNOPSIS
    Send keystrokes to a window by title or to the currently active window.

.DESCRIPTION
    This script can send keystrokes to:
    1. The currently active window (default)
    2. A specific window by partial title match

.PARAMETER Key
    The key to send (e.g., 's', 'r', 'R')

.PARAMETER WindowTitle
    Optional: Partial window title to find and focus before sending keys

.EXAMPLE
    .\Send-KeyToTerminal.ps1 -Key "s"
    Sends 's' to the currently active window

.EXAMPLE
    .\Send-KeyToTerminal.ps1 -Key "s" -WindowTitle "flutter"
    Finds a window with "flutter" in the title, focuses it, and sends 's'
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Key,
    
    [Parameter(Mandatory = $false)]
    [string]$WindowTitle = $null
)

Add-Type -AssemblyName System.Windows.Forms

# If WindowTitle specified, try to find and focus that window
if ($WindowTitle) {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@
    
    $process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$WindowTitle*" } | Select-Object -First 1
    
    if ($process) {
        Write-Host "Found window: $($process.MainWindowTitle)"
        [WindowHelper]::ShowWindow($process.MainWindowHandle, 9) # SW_RESTORE
        [WindowHelper]::SetForegroundWindow($process.MainWindowHandle)
        Start-Sleep -Milliseconds 100
    }
    else {
        Write-Host "Warning: No window found with title containing '$WindowTitle'"
        Write-Host "Sending to currently active window instead..."
    }
}

Write-Host "Sending key: $Key"
[System.Windows.Forms.SendKeys]::SendWait($Key)
Write-Host "Key sent successfully"
