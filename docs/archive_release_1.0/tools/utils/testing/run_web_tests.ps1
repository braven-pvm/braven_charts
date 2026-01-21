# Web test runner with ChromeDriver support
# This script sets up ChromeDriver and runs integration tests on Chrome

$ErrorActionPreference = "Stop"

Write-Host "`n Braven Charts Web Test Runner (ChromeDriver)" -ForegroundColor Cyan
Write-Host "=" * 50 -ForegroundColor Cyan

# Get ChromeDriver path
$chromedriverPath = Join-Path (Get-Item $PSScriptRoot).Parent.Parent.FullName "test\chromedriver\win64-140.0.7339.82\chromedriver-win64\chromedriver.exe"

if (-not (Test-Path $chromedriverPath)) {
    Write-Host " ChromeDriver not found at: $chromedriverPath" -ForegroundColor Red
    exit 1
}

Write-Host " Found ChromeDriver: $chromedriverPath" -ForegroundColor Green

# Set ChromeDriver environment variable
$env:CHROMEDRIVER_EXECUTABLE = $chromedriverPath
Write-Host " Set CHROMEDRIVER_EXECUTABLE environment variable" -ForegroundColor Green

# Enable web
Write-Host "`n Enabling web platform..." -ForegroundColor Yellow
flutter config --enable-web | Out-Null
Write-Host " Web platform enabled" -ForegroundColor Green

# Get dependencies
Write-Host "`n Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host " Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host " Dependencies installed" -ForegroundColor Green

# Run unit tests for web utilities
Write-Host "`n Running web unit tests..." -ForegroundColor Yellow
flutter test test/web/
if ($LASTEXITCODE -ne 0) {
    Write-Host " Web unit tests failed" -ForegroundColor Red
    exit 1
}
Write-Host " Web unit tests passed" -ForegroundColor Green

# Run integration tests on Chrome
Write-Host "`n Running integration tests on Chrome..." -ForegroundColor Yellow
Write-Host "   Using ChromeDriver: $chromedriverPath" -ForegroundColor Gray

flutter drive `
    --driver=test/test_driver/integration_test.dart `
    --target=test/integration_test/web_app_test.dart `
    -d chrome `
    --dart-define=CHROMEDRIVER_EXECUTABLE=$chromedriverPath

if ($LASTEXITCODE -ne 0) {
    Write-Host " Integration tests failed" -ForegroundColor Red
    exit 1
}

Write-Host "`n All web tests passed!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Cyan

