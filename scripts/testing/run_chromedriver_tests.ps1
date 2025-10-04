# Start ChromeDriver and run web integration tests
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
    Write-Host "`n Running integration tests..." -ForegroundColor Yellow
    
    flutter drive `
        --driver=test/test_driver/integration_test.dart `
        --target=test/integration_test/web_app_test.dart `
        -d chrome
    
    $exitCode = $LASTEXITCODE
    
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

