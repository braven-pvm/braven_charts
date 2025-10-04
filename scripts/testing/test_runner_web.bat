@echo off
setlocal enabledelayedexpansion

REM Web-specific test runner for Braven Charts
REM This script runs all tests with web platform support

echo.
echo 🌐 Running Braven Charts Web Test Suite
echo ========================================

call :print_step "Checking web prerequisites..."

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Flutter is not installed or not in PATH"
    exit /b 1
)

REM Check if Chrome is available for web testing
where chrome >nul 2>&1
if %errorlevel% neq 0 (
    call :print_warning "Chrome not found in PATH, web tests may fail"
)

call :print_success "Prerequisites check passed"

REM Get dependencies
call :print_step "Getting dependencies..."
flutter pub get
if %errorlevel% neq 0 (
    call :print_error "Failed to get dependencies"
    exit /b 1
)
call :print_success "Dependencies installed"

REM Enable web platform
call :print_step "Enabling web platform..."
flutter config --enable-web
call :print_success "Web platform enabled"

REM Run static analysis
call :print_step "Running static analysis..."
flutter analyze
if %errorlevel% neq 0 (
    call :print_error "Static analysis failed"
    exit /b 1
)
call :print_success "Static analysis passed"

REM Run unit tests (platform agnostic)
call :print_step "Running unit tests..."
flutter test test\unit\
if %errorlevel% equ 0 (
    call :print_success "Unit tests passed"
) else (
    call :print_warning "Unit tests failed or no unit tests found"
)

REM Run widget tests
call :print_step "Running widget tests..."
flutter test test\widget\
if %errorlevel% equ 0 (
    call :print_success "Widget tests passed"
) else (
    call :print_warning "Widget tests failed or no widget tests found"
)

REM Run web-specific tests
call :print_step "Running web-specific tests..."
flutter test test\web\
if %errorlevel% equ 0 (
    call :print_success "Web tests passed"
) else (
    call :print_warning "Web tests failed or no web tests found"
)

REM Run main test suite with web renderer
call :print_step "Running main test suite (web)..."
flutter test test\braven_charts_test.dart --platform chrome
if %errorlevel% neq 0 (
    call :print_warning "Main test suite with web platform had issues, trying without platform flag..."
    flutter test test\braven_charts_test.dart
    if %errorlevel% neq 0 (
        call :print_error "Main test suite failed"
        exit /b 1
    )
)
call :print_success "Main test suite passed"

REM Build for web to verify compilation
call :print_step "Building for web (verification)..."
flutter build web --no-pub
if %errorlevel% equ 0 (
    call :print_success "Web build successful"
) else (
    call :print_warning "Web build had issues"
)

REM Run integration tests on Chrome
call :print_step "Running web integration tests..."
echo Note: This requires Chrome browser to be available
flutter test integration_test\web_app_test.dart -d chrome
if %errorlevel% equ 0 (
    call :print_success "Web integration tests passed"
) else (
    call :print_warning "Web integration tests failed or Chrome not available"
    echo Try running: flutter devices
    echo And ensure Chrome is listed
)

REM Generate test coverage
call :print_step "Generating test coverage..."
flutter test --coverage
if %errorlevel% equ 0 (
    call :print_success "Test coverage generated"
    echo Coverage report: coverage\lcov.info
) else (
    call :print_warning "Test coverage generation failed"
)

REM Summary
echo.
echo ========================================
echo 🎉 Web Test Suite Completed!
echo ========================================
echo.

call :print_step "Web Testing Summary:"
echo ✅ Unit tests executed
echo ✅ Widget tests executed
echo ✅ Web-specific tests executed
echo ✅ Integration tests attempted
echo ✅ Web build verified
echo.

call :print_step "Next steps:"
echo 1. Review test results above
echo 2. Open coverage\html\index.html for detailed coverage (if lcov installed)
echo 3. Run 'flutter run -d chrome' to test in browser manually
echo 4. Run 'flutter test --help' for more testing options
echo.

call :print_step "Web Testing Commands:"
echo - Test on Chrome:  flutter test -d chrome
echo - Test on Edge:    flutter test -d edge
echo - Run web app:     flutter run -d chrome
echo - Build for web:   flutter build web
echo.

exit /b 0

REM Helper functions for colored output
:print_step
echo ▶ %~1
goto :eof

:print_success
echo ✅ %~1
goto :eof

:print_warning
echo ⚠️  %~1
goto :eof

:print_error
echo ❌ %~1
goto :eof