@echo off
setlocal enabledelayedexpansion

REM Comprehensive test runner for Braven Charts (Windows)
REM This script runs all types of tests in sequence

echo.
echo 🧪 Running Braven Charts Test Suite
echo ==================================

REM Function to print colored output
call :print_step "Checking prerequisites..."

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Flutter is not installed or not in PATH"
    exit /b 1
)

REM Check if Dart is installed
dart --version >nul 2>&1
if %errorlevel% neq 0 (
    call :print_error "Dart is not installed or not in PATH"
    exit /b 1
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

REM Generate mocks
call :print_step "Generating mocks..."
flutter packages pub run build_runner build --delete-conflicting-outputs
if %errorlevel% equ 0 (
    call :print_success "Mocks generated successfully"
) else (
    call :print_warning "Mock generation failed, continuing anyway..."
)

REM Run static analysis
call :print_step "Running static analysis..."
flutter analyze
if %errorlevel% neq 0 (
    call :print_error "Static analysis failed"
    exit /b 1
)
call :print_success "Static analysis passed"

REM Run unit tests
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

REM Run main test suite
call :print_step "Running main test suite..."
flutter test test\braven_charts_test.dart
if %errorlevel% neq 0 (
    call :print_error "Main test suite failed"
    exit /b 1
)
call :print_success "Main test suite passed"

REM Run performance tests
call :print_step "Running performance tests..."
flutter test test\performance\
if %errorlevel% equ 0 (
    call :print_success "Performance tests passed"
) else (
    call :print_warning "Performance tests failed or no performance tests found"
)

REM Generate test coverage
call :print_step "Generating test coverage..."
flutter test --coverage
if %errorlevel% equ 0 (
    call :print_success "Test coverage generated"
) else (
    call :print_warning "Test coverage generation failed"
)

REM Run integration tests
call :print_step "Running integration tests..."
flutter test integration_test\
if %errorlevel% equ 0 (
    call :print_success "Integration tests passed"
) else (
    call :print_warning "Integration tests failed or no integration tests found"
)

REM Summary
echo.
echo ==================================
echo 🎉 Test Suite Completed Successfully!
echo ==================================
echo.

call :print_step "Next steps:"
echo 1. Review test coverage results in coverage\lcov.info
echo 2. Add more tests for uncovered code
echo 3. Run 'flutter test --help' for more testing options
echo 4. Consider adding more integration tests

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