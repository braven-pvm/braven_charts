# Development Setup Guide

This guide will help you set up your development environment for contributing to Braven Charts.

## 📋 Prerequisites

### Required

- **Flutter SDK** ≥ 3.10.0 ([Download](https://flutter.dev/docs/get-started/install))
- **Dart SDK** ≥ 3.0.0 (included with Flutter)
- **Git** ([Download](https://git-scm.com/downloads))
- **Google Chrome** (for web testing)

### Recommended

- **VS Code** with Flutter extension ([Download](https://code.visualstudio.com/))
- **Android Studio** (optional, for Android testing)
- **ChromeDriver** (included in project at `chromedriver/`)

## 🚀 Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd braven_charts_v2.0
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Setup

```bash
# Check Flutter installation
flutter doctor

# Run tests to verify everything works
flutter test
```

You should see: **✅ 26/26 tests passing**

### 4. Configure Flutter Path (Windows)

If Flutter commands don't work in new terminals, run the setup script:

```powershell
./scripts/setup/fix_flutter_path.ps1
```

This adds Flutter to your permanent system PATH.

## 🧪 Testing Setup

### Unit & Widget Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/chart_utils_test.dart

# Watch mode (runs tests on file changes)
flutter test --watch
```

### Web Tests

```bash
# Web unit tests
flutter test test/web/

# Web integration tests (requires ChromeDriver)
./scripts/testing/run_chromedriver_tests.ps1
```

### Golden Tests

```bash
# Run golden tests
flutter test --update-goldens

# Compare against golden files
flutter test test/golden/
```

## 🏗️ Project Structure

```
braven_charts_v2.0/
│
├── lib/                                # Source code
│   ├── src/                           # Internal implementation
│   │   ├── charts/                    # Chart components
│   │   ├── annotations/               # Annotation system
│   │   ├── theming/                   # Theme system
│   │   └── utils/                     # Utilities
│   └── braven_charts.dart             # Public API
│
├── test/                              # Tests
│   ├── web/                           # Web-specific tests
│   │   ├── web_test_utils.dart       # Web test utilities
│   │   └── web_utils_test.dart       # Web utility tests
│   ├── unit/                          # Unit tests
│   │   └── chart_utils_test.dart     # Chart utility tests
│   ├── golden/                        # Golden file tests
│   │   └── golden_test_utils.dart    # Golden test framework
│   ├── performance/                   # Performance tests
│   │   └── performance_test_utils.dart
│   ├── integration/                   # Integration test utilities
│   │   └── integration_test_utils.dart
│   ├── test_utils.dart               # Shared test utilities
│   └── braven_charts_test.dart       # Main test suite
│
├── integration_test/                  # E2E tests
│   ├── app_test.dart                 # Standard integration tests
│   └── web_app_test.dart             # Web integration tests
│
├── test_driver/                       # Test drivers
│   └── integration_test.dart         # Integration test driver
│
├── docs/                              # Documentation
│   ├── testing/                       # Testing guides
│   ├── architecture/                  # Architecture docs
│   └── readme.md                      # Docs index
│
├── scripts/                           # Utility scripts
│   ├── testing/                       # Test runners
│   │   ├── run_chromedriver_tests.ps1
│   │   ├── run_web_tests.ps1
│   │   ├── test_runner.bat
│   │   ├── test_runner.sh
│   │   └── test_runner_web.bat
│   └── setup/                         # Setup scripts
│       └── fix_flutter_path.ps1
│
├── chromedriver/                      # ChromeDriver for web testing
│   └── win64-140.0.7339.82/
│       └── chromedriver-win64/
│           └── chromedriver.exe
│
├── build.yaml                         # Mock generation config
├── pubspec.yaml                       # Package definition
├── analysis_options.yaml              # Linter rules
└── readme.md                          # Project overview
```

## 🔧 Development Workflow

### TDD Cycle (Recommended)

1. **Write Test First**

   ```bash
   # Create test file in test/
   # Example: test/unit/line_chart_test.dart

   flutter test test/unit/line_chart_test.dart --watch
   ```

2. **See Test Fail**
   - Test should fail (no implementation yet)
   - Verify test is checking the right thing

3. **Write Minimum Code**
   - Implement in `lib/src/`
   - Make the test pass
   - Don't over-engineer

4. **Refactor**
   - Clean up code
   - Keep tests passing
   - Improve design

5. **Repeat**
   - Next test case
   - Build incrementally

### Feature Development

```bash
# 1. Create feature branch
git checkout -b feature/line-chart

# 2. Write tests
# test/unit/line_chart_test.dart

# 3. Run tests in watch mode
flutter test --watch

# 4. Implement feature
# lib/src/charts/line_chart.dart

# 5. Verify all tests pass
flutter test

# 6. Test on web
./scripts/testing/run_chromedriver_tests.ps1

# 7. Commit
git add .
git commit -m "feat: Add line chart component"

# 8. Push and create PR
git push origin feature/line-chart
```

## 🎯 Code Standards

### Dart Code Style

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

```dart
// ✅ Good
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.data,
  });

  final ChartData data;

  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}

// ❌ Bad
class linechart extends StatelessWidget {
  linechart(this.data);
  ChartData data;
  build(context) { }
}
```

### Test Style

```dart
// ✅ Good test structure
void main() {
  group('LineChart', () {
    testWidgets('renders with valid data', (tester) async {
      // Arrange
      final data = ChartData(/* ... */);

      // Act
      await tester.pumpWidget(LineChart(data: data));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LineChart), findsOneWidget);
    });
  });
}
```

### Documentation

Every public API must have documentation:

````dart
/// A chart that displays data as a series of points connected by lines.
///
/// The [LineChart] is ideal for showing trends over time or continuous data.
///
/// Example:
/// ```dart
/// LineChart(
///   data: ChartData(
///     points: [Point(0, 10), Point(1, 20), Point(2, 15)],
///   ),
/// )
/// ```
class LineChart extends StatelessWidget {
  // Implementation
}
````

## 🐛 Debugging

### VS Code

1. Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter: Run Tests",
      "type": "dart",
      "request": "launch",
      "program": "test/braven_charts_test.dart"
    }
  ]
}
```

2. Set breakpoints
3. Press F5 to debug

### Chrome DevTools

When running web tests:

1. Look for DevTools URL in output
2. Open in browser
3. Use Flutter DevTools for debugging

## 📊 Performance Testing

```bash
# Run performance tests
flutter test test/performance/

# Profile specific test
flutter test --profile test/performance/render_benchmark_test.dart
```

## 🔍 Code Analysis

```bash
# Run static analysis
flutter analyze

# Fix auto-fixable issues
dart fix --apply

# Format code
dart format .
```

## 📝 Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: Add line chart component
fix: Correct annotation positioning
docs: Update theming guide
test: Add golden tests for bar chart
refactor: Simplify coordinate transformer
perf: Optimize rendering for large datasets
```

## 🚦 CI/CD

Tests run automatically on push. Ensure locally first:

```bash
# Run all checks
flutter test && flutter analyze
```

## 🆘 Troubleshooting

### Flutter not found

```powershell
./scripts/setup/fix_flutter_path.ps1
```

### Tests failing

```bash
flutter clean
flutter pub get
flutter test
```

### ChromeDriver issues

1. Check Chrome version: `chrome://version`
2. Verify ChromeDriver version matches
3. See [ChromeDriver Setup](testing/CHROMEDRIVER_SETUP.md)

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Package Guidelines](https://dart.dev/guides/libraries/create-packages)

---

**Ready to start developing!** 🚀

If you have questions, check the [docs](readme.md) or open an issue.
