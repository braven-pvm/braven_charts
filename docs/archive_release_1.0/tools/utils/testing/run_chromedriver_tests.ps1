# Start ChromeDriver and run web integration tests
param(
    [string]$TestFile = "proof_test.dart"
)

$ErrorActionPreference = "Stop"

Write-Host "`n Starting ChromeDriver for Web Testing" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

$chromedriverPath = Join-Path (Get-Item $PSScriptRoot).Parent.Parent.FullName "test\chromedriver\win64-140.0.7339.82\chromedriver-win64\chromedriver.exe"

if (-not (Test-Path $chromedriverPath)) {
    Write-Host " ChromeDriver not found" -ForegroundColor Red
    exit 1
}

Write-Host " Starting ChromeDriver on port 4444..." -ForegroundColor Yellow

# Start ChromeDriver in background
$chromedriverProcess = Start-Process -FilePath $chromedriverPath `
    -ArgumentList "--port=4444" `
    -PassThru `
    -NoNewWindow `
    -RedirectStandardOutput "chromedriver.log" `
    -RedirectStandardError "chromedriver.error.log"

Start-Sleep -Seconds 2

if ($chromedriverProcess.HasExited) {
    Write-Host " ChromeDriver failed to start" -ForegroundColor Red
    Get-Content "chromedriver.error.log"
    exit 1
}

Write-Host " ChromeDriver started (PID: $($chromedriverProcess.Id))" -ForegroundColor Green

try {
    Write-Host "`n Running Test: $TestFile" -ForegroundColor Yellow
    Write-Host " Watch the terminal output to see each step being performed!" -ForegroundColor Cyan
    
    # Change to example directory
    Push-Location (Join-Path (Get-Item $PSScriptRoot).Parent.Parent.FullName "example")
    
    flutter drive `
        --driver=test_driver/integration_test.dart `
        --target=integration_test/$TestFile `
        -d chrome
    
    $exitCode = $LASTEXITCODE
    
    Pop-Location
    
    if ($exitCode -eq 0) {
        Write-Host "`n All tests passed!" -ForegroundColor Green
    }
    else {
        Write-Host "`n Tests failed" -ForegroundColor Red
    }
}
finally {
    Write-Host "`n Stopping ChromeDriver..." -ForegroundColor Yellow
    Stop-Process -Id $chromedriverProcess.Id -Force -ErrorAction SilentlyContinue
    Write-Host " ChromeDriver stopped" -ForegroundColor Green
}

Write-Host "=" * 50 -ForegroundColor Cyan
exit $exitCode

