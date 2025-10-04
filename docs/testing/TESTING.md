# Testing Guide for Braven Charts

This guide covers the comprehensive testing framework set up for the Braven Charts Flutter package. Our testing strategy follows Test-Driven Development (TDD) principles and includes multiple layers of testing.

## 🧪 Testing Framework Overview

### Testing Layers

1. **Unit Tests** - Test individual functions and classes
2. **Widget Tests** - Test individual widgets and their behavior
3. **Integration Tests** - Test complete user workflows
4. **Golden Tests** - Visual regression testing
5. **Performance Tests** - Performance and memory testing
6. **E2E Tests** - End-to-end application testing

### Testing Dependencies

```yaml
dev_dependencies:
  # Core testing
  flutter_test:
    sdk: flutter
  test: ^1.24.0
  
  # Mocking and test utilities
  mockito: ^5.4.0
  build_runner: ^2.4.0
  fake_async: ^1.3.0
  
  # Widget and integration testing
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
  
  # Golden file testing
  golden_toolkit: ^0.15.0
  alchemist: ^0.7.0
  
  # Performance testing
  benchmark_harness: ^2.2.0
  
  # Coverage
  coverage: ^1.6.0
```

## 📁 Test Directory Structure

```
test/
├── unit/                    # Unit tests
│   └── chart_utils_test.dart
├── widget/                  # Widget tests
│   └── chart_widget_test.dart
├── integration/             # Integration test utilities
│   └── integration_test_utils.dart
├── golden/                  # Golden test utilities
│   └── golden_test_utils.dart
├── performance/             # Performance test utilities
│   └── performance_test_utils.dart
├── mocks/                   # Mock definitions
│   └── mock_definitions.dart
├── test_utils.dart          # Common test utilities
├── analysis_options.yaml   # Test-specific linting rules
└── braven_charts_test.dart  # Main test suite

integration_test/            # E2E integration tests
└── app_test.dart
```

## 🚀 Running Tests

### Quick Start

```bash
# Run all tests
flutter test

# Run specific test categories
flutter test test/unit/
flutter test test/widget/
flutter test integration_test/

# Run with coverage
flutter test --coverage
```

### Using Test Runners

We provide automated test runners for different platforms:

**Linux/macOS:**
```bash
chmod +x test_runner.sh
./test_runner.sh
```

**Windows:**
```cmd
test_runner.bat
```

## 🎯 Test-Driven Development (TDD) Workflow

### 1. Red Phase - Write Failing Test

```dart
test('should calculate chart bounds correctly', () {
  final chartData = TestUtils.getTestChartData();
  final bounds = ChartBounds.fromData(chartData);
  
  expect(bounds.minX, 0);
  expect(bounds.maxX, 4);
  expect(bounds.minY, 10);
  expect(bounds.maxY, 30);
});
```

### 2. Green Phase - Write Minimal Implementation

```dart
class ChartBounds {
  final double minX, maxX, minY, maxY;
  
  ChartBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
  
  static ChartBounds fromData(List<Map<String, dynamic>> data) {
    // Minimal implementation to pass test
    return ChartBounds(minX: 0, maxX: 4, minY: 10, maxY: 30);
  }
}
```

### 3. Refactor Phase - Improve Implementation

```dart
static ChartBounds fromData(List<Map<String, dynamic>> data) {
  if (data.isEmpty) {
    return ChartBounds(minX: 0, maxX: 0, minY: 0, maxY: 0);
  }
  
  final xValues = data.map((point) => point['x'] as num).toList();
  final yValues = data.map((point) => point['y'] as num).toList();
  
  return ChartBounds(
    minX: xValues.reduce(math.min).toDouble(),
    maxX: xValues.reduce(math.max).toDouble(),
    minY: yValues.reduce(math.min).toDouble(),
    maxY: yValues.reduce(math.max).toDouble(),
  );
}
```

## 🎨 Widget Testing

### Basic Widget Test

```dart
testWidgets('LineChart should render with data', (tester) async {
  final data = TestUtils.getTestChartData();
  final chart = LineChart(data: data);
  
  await tester.pumpWidget(
    TestUtils.createTestApp(child: chart),
  );
  
  expect(find.byType(LineChart), findsOneWidget);
  expect(find.byType(CustomPaint), findsOneWidget);
});
```

### Interaction Testing

```dart
testWidgets('Chart should respond to tap gestures', (tester) async {
  var tapped = false;
  final chart = LineChart(
    data: TestUtils.getTestChartData(),
    onTap: (point) => tapped = true,
  );
  
  await tester.pumpWidget(TestUtils.createTestApp(child: chart));
  await tester.tap(find.byType(LineChart));
  
  expect(tapped, isTrue);
});
```

## 🏆 Golden Tests (Visual Regression)

### Basic Golden Test

```dart
testWidgets('LineChart golden test', (tester) async {
  await tester.pumpWidgetBuilder(
    LineChart(data: TestUtils.getTestChartData()),
    wrapper: materialAppWrapper(),
    surfaceSize: const Size(600, 400),
  );
  
  await screenMatchesGolden(tester, 'line_chart_basic');
});
```

### Theme Testing

```dart
testWidgets('Chart themes golden test', (tester) async {
  await GoldenTestUtils.testChartThemes(
    name: 'line_chart_themes',
    chartBuilder: (theme) => LineChart(
      data: TestUtils.getTestChartData(),
      theme: ChartTheme.fromMaterialTheme(theme),
    ),
  );
});
```

## ⚡ Performance Testing

### Render Performance

```dart
testWidgets('Chart render performance', (tester) async {
  final largeData = TestUtils.getLargeTestDataset(10000);
  
  final duration = await PerformanceTestUtils.measureRenderTime(
    renderFunction: () => LineChart(data: largeData),
    iterations: 10,
  );
  
  expect(duration.inMilliseconds, lessThan(100));
});
```

### Memory Usage

```dart
testWidgets('Chart memory usage', (tester) async {
  final memoryUsage = await PerformanceTestUtils.measureMemoryUsage(
    operation: () async {
      final data = TestUtils.getLargeTestDataset(50000);
      final chart = LineChart(data: data);
      await tester.pumpWidget(TestUtils.createTestApp(child: chart));
    },
  );
  
  expect(memoryUsage.difference, lessThan(10000000)); // 10MB limit
});
```

## 🔄 Integration Testing

### Complete User Workflow

```dart
testWidgets('Complete chart interaction workflow', (tester) async {
  final app = IntegrationTestUtils.createTestApp(
    chart: LineChart(data: TestUtils.getTestChartData()),
  );
  
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  
  // Test pan gesture
  await tester.drag(find.byType(LineChart), const Offset(100, 0));
  await tester.pumpAndSettle();
  
  // Test zoom gesture
  await IntegrationTestUtils.testChartInteractions(
    tester: tester,
    chartFinder: find.byType(LineChart),
  );
  
  // Verify chart is still responsive
  expect(find.byType(LineChart), findsOneWidget);
});
```

## 🎭 Mocking

### Mock Definition

```dart
@GenerateMocks([ChartRenderer, DataProvider])
class MockDefinitions {}
```

### Using Mocks

```dart
testWidgets('Chart with mock data provider', (tester) async {
  final mockProvider = MockDataProvider();
  when(mockProvider.getData()).thenReturn(TestUtils.getTestChartData());
  
  final chart = LineChart(dataProvider: mockProvider);
  await tester.pumpWidget(TestUtils.createTestApp(child: chart));
  
  verify(mockProvider.getData()).called(1);
});
```

## 📊 Test Coverage

### Generating Coverage

```bash
# Generate coverage data
flutter test --coverage

# View coverage summary (requires lcov)
lcov --summary coverage/lcov.info

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html/
```

### Coverage Goals

- **Unit Tests**: 90%+ coverage
- **Widget Tests**: 80%+ coverage
- **Integration Tests**: Key user flows covered
- **Golden Tests**: All visual components tested

## 🔧 Test Utilities

### TestUtils Class

```dart
// Get test data
final data = TestUtils.getTestChartData();
final largeData = TestUtils.getLargeTestDataset(1000);

// Create test widgets
final app = TestUtils.createTestApp(child: myChart);
final minimal = TestUtils.createMinimalTestWidget(myWidget);

// Custom matchers
expect(3.14159, TestUtils.closeTo(3.14, tolerance: 0.01));
```

### GoldenTestUtils Class

```dart
// Test multiple sizes
await GoldenTestUtils.testChartForSizes(
  name: 'my_chart',
  widget: MyChart(),
);

// Test themes
await GoldenTestUtils.testChartThemes(
  name: 'my_chart',
  chartBuilder: (theme) => MyChart(theme: theme),
);
```

### PerformanceTestUtils Class

```dart
// Measure performance
final duration = await PerformanceTestUtils.measureRenderTime(
  renderFunction: () => myRenderFunction(),
);

// Check for memory leaks
final hasLeaks = await PerformanceTestUtils.testForMemoryLeaks(
  operation: () async => myOperation(),
);
```

## 🚨 Best Practices

### 1. Test Organization
- Group related tests together
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

### 2. Test Data
- Use consistent test data across tests
- Create helper functions for data generation
- Test edge cases (empty data, invalid data)

### 3. Widget Testing
- Test both happy path and error conditions
- Use appropriate test utilities
- Verify both visual and behavioral aspects

### 4. Performance
- Set reasonable performance expectations
- Test with realistic data sizes
- Monitor memory usage

### 5. Golden Tests
- Use consistent device sizes
- Test both light and dark themes
- Update golden files when UI changes

## 🔄 Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

## 📚 Additional Resources

- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Golden Toolkit Documentation](https://pub.dev/packages/golden_toolkit)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Test Documentation](https://docs.flutter.dev/testing/integration-tests)

## ❓ Troubleshooting

### Common Issues

**Golden test failures:**
- Run `flutter test --update-goldens` to update golden files
- Check for font rendering differences across platforms

**Mock generation issues:**
- Run `flutter packages pub run build_runner clean`
- Then `flutter packages pub run build_runner build`

**Performance test instability:**
- Increase iteration counts for more stable results
- Run tests multiple times to identify flaky tests

**Integration test failures:**
- Ensure proper setup in `IntegrationTestUtils.initialize()`
- Check for race conditions with `pumpAndSettle()`