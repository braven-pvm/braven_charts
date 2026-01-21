# ChromeDriver Web Testing Setup

## Overview

This project uses **ChromeDriver** for web integration testing. ChromeDriver is a WebDriver implementation that enables automated testing of Flutter web applications in Chrome.

## ChromeDriver Location

```
test/chromedriver/win64-140.0.7339.82/chromedriver-win64/chromedriver.exe
```

**Version**: 140.0.7339.82 (matches Chrome 140)

## Available Test Scripts

### 1. `run_web_tests.ps1` - Complete Web Test Suite
Runs all web tests including unit and integration tests with ChromeDriver.

```powershell
.\run_web_tests.ps1
```

**What it does:**
- Sets `CHROMEDRIVER_EXECUTABLE` environment variable
- Enables Flutter web platform
- Runs web unit tests (`test/web/`)
- Runs integration tests on Chrome with ChromeDriver

### 2. `run_chromedriver_tests.ps1` - ChromeDriver Integration Tests
Starts ChromeDriver server and runs integration tests.

```powershell
.\run_chromedriver_tests.ps1
```

**What it does:**
- Starts ChromeDriver on port 4444
- Runs `flutter drive` integration tests
- Automatically stops ChromeDriver when done

### 3. Manual ChromeDriver Testing

**Step 1:** Start ChromeDriver manually
```powershell
.\test\chromedriver\win64-140.0.7339.82\chromedriver-win64\chromedriver.exe --port=4444
```

**Step 2:** In another terminal, run tests
```powershell
flutter drive --driver=test/test_driver/integration_test.dart --target=test/integration_test/web_app_test.dart -d chrome
```

## Test Files

### Unit Tests
- `test/web/web_test_utils.dart` - Web testing utilities
- `test/web/web_utils_test.dart` - Unit tests for web utilities

**Run with:**
```powershell
flutter test test/web/
```

### Integration Tests
- `test/integration_test/web_app_test.dart` - Web integration tests
- `test/test_driver/integration_test.dart` - Integration test driver

**Run with:**
```powershell
flutter drive --driver=test/test_driver/integration_test.dart --target=test/integration_test/web_app_test.dart -d chrome
```

## ChromeDriver Configuration

### Environment Variables
```powershell
$env:CHROMEDRIVER_EXECUTABLE = "X:\path\to\chromedriver.exe"
```

### Port Configuration
Default port: **4444**

To use a different port:
```powershell
chromedriver.exe --port=9515
```

## Troubleshooting

### Issue: "Unable to start a WebDriver session"
**Solution:** Ensure ChromeDriver is running on port 4444
```powershell
.\run_chromedriver_tests.ps1
```

### Issue: "This application is not configured to build on the web"
**Solution:** This is normal for Flutter packages. Integration tests work differently:
- Use `flutter drive` instead of `flutter test` for integration tests
- ChromeDriver must be running first

### Issue: ChromeDriver version mismatch
**Current version:** 140.0.7339.82
**Check Chrome version:**
```powershell
(Get-Item "C:\Program Files\Google\Chrome\Application\chrome.exe").VersionInfo.FileVersion
```

**Download matching ChromeDriver:**
https://googlechromelabs.github.io/chrome-for-testing/

## Web Testing Capabilities

### Viewport Testing
The `WebTestUtils` class provides 8 standard viewport sizes:
- Mobile: 375x667
- Mobile Landscape: 667x375
- Tablet: 768x1024
- Tablet Landscape: 1024x768
- Desktop: 1366x768
- Desktop HD: 1920x1080
- Desktop QHD: 2560x1440
- Ultrawide: 3440x1440

### Mouse Interactions
- `hoverAt()` - Simulate mouse hover
- `clickAt()` - Simulate mouse click

### Performance Testing
- `WebPerformanceMetrics` - Track render and interaction times
- Render threshold: 50ms
- Interaction threshold: 16ms (60fps)

## Quick Start

1. **Run all web unit tests:**
   ```powershell
   flutter test test/web/
   ```

2. **Run integration tests with ChromeDriver:**
   ```powershell
   .\run_chromedriver_tests.ps1
   ```

3. **Full web test suite:**
   ```powershell
   .\run_web_tests.ps1
   ```

## CI/CD Integration

For CI/CD pipelines, use the automated scripts:

```yaml
# GitHub Actions example
- name: Run Web Tests
  run: |
    pwsh -File run_web_tests.ps1
```

## Additional Resources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Flutter Web Testing](https://docs.flutter.dev/cookbook/testing/integration/web)
- [ChromeDriver Documentation](https://chromedriver.chromium.org/)
- [WebDriver Specification](https://www.w3.org/TR/webdriver/)
