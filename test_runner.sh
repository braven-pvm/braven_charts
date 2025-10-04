#!/bin/bash

# Comprehensive test runner for Braven Charts
# This script runs all types of tests in sequence

set -e

echo "🧪 Running Braven Charts Test Suite"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_step "Checking prerequisites..."

if ! command_exists flutter; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

if ! command_exists dart; then
    print_error "Dart is not installed or not in PATH"
    exit 1
fi

print_success "Prerequisites check passed"

# Get dependencies
print_step "Getting dependencies..."
flutter pub get || {
    print_error "Failed to get dependencies"
    exit 1
}
print_success "Dependencies installed"

# Generate mocks
print_step "Generating mocks..."
if flutter packages pub run build_runner build --delete-conflicting-outputs; then
    print_success "Mocks generated successfully"
else
    print_warning "Mock generation failed, continuing anyway..."
fi

# Run static analysis
print_step "Running static analysis..."
if flutter analyze; then
    print_success "Static analysis passed"
else
    print_error "Static analysis failed"
    exit 1
fi

# Run unit tests
print_step "Running unit tests..."
if flutter test test/unit/; then
    print_success "Unit tests passed"
else
    print_error "Unit tests failed"
    exit 1
fi

# Run widget tests
print_step "Running widget tests..."
if flutter test test/widget/; then
    print_success "Widget tests passed"
else
    print_warning "Widget tests failed or no widget tests found"
fi

# Run main test suite
print_step "Running main test suite..."
if flutter test test/braven_charts_test.dart; then
    print_success "Main test suite passed"
else
    print_error "Main test suite failed"
    exit 1
fi

# Run performance tests
print_step "Running performance tests..."
if flutter test test/performance/; then
    print_success "Performance tests passed"
else
    print_warning "Performance tests failed or no performance tests found"
fi

# Generate test coverage
print_step "Generating test coverage..."
if flutter test --coverage; then
    print_success "Test coverage generated"
    
    # Check if lcov is available for HTML report
    if command_exists lcov; then
        print_step "Generating HTML coverage report..."
        genhtml coverage/lcov.info -o coverage/html/
        print_success "HTML coverage report generated in coverage/html/"
    else
        print_warning "lcov not available, HTML coverage report not generated"
    fi
else
    print_warning "Test coverage generation failed"
fi

# Run golden tests (if any)
print_step "Running golden tests..."
if find test/ -name "*golden*" -type f | grep -q .; then
    if flutter test test/golden/; then
        print_success "Golden tests passed"
    else
        print_warning "Golden tests failed"
    fi
else
    print_warning "No golden tests found"
fi

# Run integration tests
print_step "Running integration tests..."
if flutter test integration_test/; then
    print_success "Integration tests passed"
else
    print_warning "Integration tests failed or no integration tests found"
fi

# Summary
echo ""
echo "=================================="
echo -e "${GREEN}🎉 Test Suite Completed Successfully!${NC}"
echo "=================================="

# Display coverage summary if available
if [ -f "coverage/lcov.info" ]; then
    echo ""
    print_step "Coverage Summary:"
    if command_exists lcov; then
        lcov --summary coverage/lcov.info
    else
        echo "Run 'lcov --summary coverage/lcov.info' to see detailed coverage"
    fi
fi

echo ""
print_step "Next steps:"
echo "1. Review test coverage results"
echo "2. Add more tests for uncovered code"
echo "3. Run 'flutter test --help' for more testing options"
echo "4. Consider adding more integration tests"

exit 0