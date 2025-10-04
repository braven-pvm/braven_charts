# Web Testing Guide for Braven Charts

This guide covers comprehensive web-specific testing for the Braven Charts Flutter package. Our testing strategy is **web-first** and includes browser-specific features, responsive design, and web performance testing.

## 🌐 Web Testing Overview

### Why Web-First Testing?

Braven Charts is designed primarily for web applications, which means our testing strategy prioritizes:
- **Browser compatibility** across Chrome, Firefox, Safari, and Edge
- **Responsive design** across various viewport sizes
- **Mouse and keyboard interactions** specific to web
- **Web performance** characteristics (canvas rendering, DOM updates)
- **Accessibility** standards for web (WCAG compliance)

### Web Testing Stack

```yaml
dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  # Web-specific testing
  web: ^1.1.0
  js: ^0.7.1
  
  # Integration testing
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  
  # Standard testing
  flutter_test:
    sdk: flutter
  test: ^1.24.0
```

## 📁 Web Test Structure

```
test/
├── web/                         # Web-specific tests
│   └── web_test_utils.dart      # Web testing utilities
├── unit/                        # Unit tests (platform agnostic)
├── widget/                      # Widget tests
└── braven_charts_test.dart      # Main test suite

integration_test/
├── web_app_test.dart            # Web integration tests
└── app_test.dart                # General integration tests

test_driver/
└── integration_test.dart        # Web test driver
```

## 🚀 Running Web Tests

### Quick Start

```bash
# Run all tests (default platform)
flutter test

# Run tests on Chrome
flutter test -d chrome

# Run tests on Edge
flutter test -d edge

# Run web-specific tests
flutter test test/web/

# Run web integration tests
flutter test integration_test/web_app_test.dart -d chrome
```

### Using the Web Test Runner

**Windows:**
```cmd
test_runner_web.bat
```

This automated runner will:
1. ✅ Check prerequisites (Flutter, Chrome)
2. ✅ Install dependencies
3. ✅ Enable web platform
4. ✅ Run static analysis
5. ✅ Execute all test suites
6. ✅ Build for web (verification)
7. ✅ Run integration tests on Chrome
8. ✅ Generate coverage reports

### Manual Web Testing

```bash
# Run app in Chrome for manual testing
flutter run -d chrome

# Run app in Edge
flutter run -d edge

# Build for web
flutter build web

# Serve built web app
cd build/web
python -m http.server 8000
# Open http://localhost:8000
```

## 🎯 Web-Specific Test Utilities

### WebTestUtils Class

The `WebTestUtils` class provides comprehensive utilities for web testing:

#### Viewport Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import '../test/web/web_test_utils.dart';

testWidgets('Chart should be responsive', (tester) async {
  await WebTestUtils.testWebResponsiveness(
    tester: tester,
    chartBuilder: (viewport) {
      return MyChart(
        width: viewport.width,
        height: viewport.height * 0.6,
      );
    },
    viewportNames: [
      'mobile_portrait',    // 375x667
      'tablet_landscape',   // 1024x768
      'desktop_medium',     // 1920x1080
    ],
  );
});
```

#### Available Viewports

```dart
WebTestUtils.webViewports = {
  'mobile_portrait': Size(375, 667),      // iPhone SE
  'mobile_landscape': Size(667, 375),     
  'tablet_portrait': Size(768, 1024),     // iPad
  'tablet_landscape': Size(1024, 768),    
  'desktop_small': Size(1366, 768),       // Laptop
  'desktop_medium': Size(1920, 1080),     // Full HD
  'desktop_large': Size(2560, 1440),      // 2K
  'desktop_ultrawide': Size(3440, 1440),  // Ultrawide
}
```

### Mouse Interaction Testing

```dart
testWidgets('Chart should handle mouse interactions', (tester) async {
  final chart = LineChart(data: testData);
  
  await tester.pumpWidget(
    WebTestUtils.createWebTestApp(chart: chart),
  );
  
  // Test mouse hover, click, and wheel
  await WebTestUtils.testMouseInteractions(
    tester: tester,
    chartFinder: find.byType(LineChart),
  );
  
  // Verify tooltips appear on hover
  expect(find.byType(Tooltip), findsWidgets);
});
```

### Keyboard Navigation Testing

```dart
testWidgets('Chart should support keyboard navigation', (tester) async {
  final chart = LineChart(data: testData);
  
  await tester.pumpWidget(
    WebTestUtils.createWebTestApp(chart: chart),
  );
  
  // Test arrow keys, shortcuts, and focus management
  await WebTestUtils.testKeyboardNavigation(
    tester: tester,
    chartFinder: find.byType(LineChart),
  );
});
```

### Browser Resize Testing

```dart
testWidgets('Chart should handle browser resize', (tester) async {
  final chart = ResponsiveChart(data: testData);
  
  await WebTestUtils.testBrowserResize(
    tester: tester,
    chart: chart,
    resizeSequence: [
      const Size(375, 667),   // Start mobile
      const Size(1024, 768),  // Resize to tablet
      const Size(1920, 1080), // Resize to desktop
      const Size(375, 667),   // Back to mobile
    ],
  );
});
```

### Web Performance Testing

```dart
testWidgets('Chart should perform well on web', (tester) async {
  final largeDataChart = LineChart(
    data: List.generate(10000, (i) => {'x': i, 'y': i * 0.5}),
  );
  
  final metrics = await WebTestUtils.measureWebPerformance(
    tester: tester,
    chart: largeDataChart,
    iterations: 10,
  );
  
  expect(metrics.isPerformant, isTrue); // < 16ms per frame
  expect(metrics.averageRenderTime.inMilliseconds, lessThan(100));
  
  print('Performance: $metrics');
});
```

### Real-Time Updates Testing

```dart
testWidgets('Chart should handle real-time updates', (tester) async {
  final dataSequence = [
    [{'x': 0, 'y': 10}],
    [{'x': 0, 'y': 10}, {'x': 1, 'y': 20}],
    [{'x': 0, 'y': 10}, {'x': 1, 'y': 20}, {'x': 2, 'y': 15}],
  ];
  
  await WebTestUtils.testRealTimeUpdates(
    tester: tester,
    chartBuilder: (data) => LineChart(data: data),
    dataSequence: dataSequence,
    updateInterval: const Duration(milliseconds: 100),
  );
});
```

### Cross-Browser Compatibility Testing

```dart
testWidgets('Chart should work across browsers', (tester) async {
  final chart = LineChart(data: testData);
  
  // Simulates different browser configurations
  await WebTestUtils.testCrossBrowserCompatibility(
    tester: tester,
    chart: chart,
  );
  
  // This tests:
  // - Chrome (pixel ratio 1.0)
  // - Firefox (pixel ratio 1.0)
  // - Safari (pixel ratio 2.0)
  // - Edge (pixel ratio 1.25)
});
```

## 🎨 Web-Specific Features Testing

### Fullscreen Support

```dart
testWidgets('Chart should support fullscreen', (tester) async {
  await WebTestUtils.testWebChartFeatures(
    tester: tester,
    chart: MyChart(),
  );
  
  // Verifies fullscreen button works
  expect(find.byKey(const Key('fullscreen_button')), findsOneWidget);
});
```

### Download/Export Features

```dart
testWidgets('Chart should support export', (tester) async {
  final chart = LineChart(data: testData);
  
  await tester.pumpWidget(
    WebTestUtils.createWebTestApp(chart: chart),
  );
  
  // Test download button
  await tester.tap(find.byKey(const Key('download_button')));
  await tester.pumpAndSettle();
  
  // Test export button
  await tester.tap(find.byKey(const Key('export_button')));
  await tester.pumpAndSettle();
});
```

## ♿ Web Accessibility Testing

### WCAG Compliance

```dart
testWidgets('Chart should be accessible', (tester) async {
  final chart = Semantics(
    label: 'Sales chart showing data from 2024',
    child: LineChart(data: testData),
  );
  
  await WebTestUtils.testWebAccessibility(
    tester: tester,
    chart: chart,
  );
  
  // Verifies:
  // - Semantic labels present
  // - Keyboard navigation works
  // - Focus management correct
  // - Screen reader support
});
```

### Keyboard-Only Navigation

```dart
testWidgets('Chart should work with keyboard only', (tester) async {
  final chart = LineChart(data: testData);
  
  await tester.pumpWidget(
    WebTestUtils.createWebTestApp(chart: chart),
  );
  
  // Navigate using Tab key
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pumpAndSettle();
  
  // Activate with Enter/Space
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
  
  // Verify chart is accessible
  expect(find.byType(LineChart), findsOneWidget);
});
```

## 🔧 Integration Testing on Web

### Running Integration Tests

```bash
# Method 1: Direct test execution
flutter test integration_test/web_app_test.dart -d chrome

# Method 2: Using flutter drive
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/web_app_test.dart \
  -d chrome

# Method 3: Using headless Chrome
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/web_app_test.dart \
  -d web-server --web-port=8080
```

### Headless Testing (CI/CD)

For CI/CD pipelines, use headless Chrome:

```bash
# Install Chrome (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y chromium-browser

# Run tests in headless mode
flutter test integration_test/ -d chrome --headless
```

### Example Integration Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../test/web/web_test_utils.dart';

void main() {
  WebTestUtils.initialize();

  testWidgets('Complete web workflow', (tester) async {
    // 1. Load app
    final app = WebTestUtils.createWebTestApp(
      chart: MyChart(data: testData),
    );
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    
    // 2. Test interactions
    await tester.tap(find.byType(MyChart));
    await tester.pumpAndSettle();
    
    // 3. Test responsive behavior
    await WebTestUtils.testWebResponsiveness(
      tester: tester,
      chartBuilder: (viewport) => MyChart(data: testData),
    );
    
    // 4. Take screenshots
    await WebTestUtils.binding.takeScreenshot('complete_workflow');
  });
}
```

## 📊 Coverage and Reporting

### Generate Coverage for Web

```bash
# Generate coverage
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html/
open coverage/html/index.html  # macOS
start coverage/html/index.html # Windows
```

### Web-Specific Coverage Goals

- **Unit Tests**: 90%+ coverage
- **Widget Tests**: 85%+ coverage
- **Web Integration Tests**: All critical user flows
- **Responsive Tests**: All major viewport sizes
- **Browser Tests**: Chrome, Firefox, Safari, Edge

## 🐛 Debugging Web Tests

### Enable Verbose Output

```bash
flutter test --verbose test/web/
```

### Debug in Browser

```bash
# Run with debug mode
flutter run -d chrome --debug

# Open DevTools
# Press 'Shift + D' in terminal or open:
# http://localhost:9100 (or whatever port is shown)
```

### Common Issues

**Issue: Tests fail on web but pass on VM**
```bash
# Solution: Check for web-specific constraints
# - Canvas rendering differences
# - Mouse vs touch events
# - Browser security restrictions
```

**Issue: Integration tests timeout**
```bash
# Solution: Increase timeout
flutter test integration_test/ -d chrome --timeout=5m
```

**Issue: Chrome not found**
```bash
# Solution: Specify Chrome path
export CHROME_EXECUTABLE=/path/to/chrome
flutter test -d chrome
```

## 🚀 CI/CD Integration

### GitHub Actions Example

```yaml
name: Web Tests
on: [push, pull_request]

jobs:
  web-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
      
      - name: Install Chrome
        run: |
          sudo apt-get update
          sudo apt-get install -y chromium-browser
      
      - name: Enable web
        run: flutter config --enable-web
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Run web tests
        run: flutter test -d chrome --coverage
      
      - name: Run integration tests
        run: |
          flutter test integration_test/web_app_test.dart -d chrome
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

## 📚 Best Practices

### 1. Test Responsiveness First
Always test charts across multiple viewport sizes:
```dart
final criticalViewports = [
  'mobile_portrait',
  'tablet_landscape',
  'desktop_medium',
];
```

### 2. Test Both Mouse and Touch
Web supports both, so test both interaction patterns.

### 3. Test Loading States
Web has network delays, always test:
- Loading state
- Loaded state
- Error state
- Empty state

### 4. Test Browser Resize
Users resize browsers constantly on web.

### 5. Test Keyboard Navigation
Essential for accessibility and power users.

### 6. Monitor Performance
Web performance differs from mobile:
```dart
expect(metrics.averageRenderTime.inMilliseconds, lessThan(16)); // 60fps
```

### 7. Test Cross-Browser
Don't just test on Chrome - test on all major browsers.

## 🎯 Web Testing Checklist

Before releasing, ensure:

- [ ] Tests pass on Chrome
- [ ] Tests pass on Firefox
- [ ] Tests pass on Safari (macOS)
- [ ] Tests pass on Edge
- [ ] Responsive design tested (8 viewport sizes)
- [ ] Mouse interactions work
- [ ] Keyboard navigation works
- [ ] Touch gestures work
- [ ] Browser resize handled
- [ ] Loading states tested
- [ ] Error handling tested
- [ ] Accessibility compliance (WCAG 2.1 AA)
- [ ] Performance benchmarks met (<16ms render)
- [ ] Real-time updates work smoothly
- [ ] Export/download features work
- [ ] Fullscreen mode works
- [ ] Screenshots/golden tests updated

## 📖 Additional Resources

- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Flutter Web Testing](https://docs.flutter.dev/testing/integration-tests)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Web Performance Best Practices](https://web.dev/performance/)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/)

## 🆘 Getting Help

If you encounter issues:

1. Check browser console for errors
2. Run with `--verbose` flag
3. Verify Chrome/browser is in PATH
4. Check Flutter version compatibility
5. Review integration test logs
6. Open DevTools for debugging

---

**Remember**: Web-first testing ensures your charts work flawlessly in the primary deployment environment!