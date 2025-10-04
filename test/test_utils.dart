import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Common test utilities and helpers for Braven Charts testing
class TestUtils {
  /// Creates a test app wrapper with Material theme
  static Widget createTestApp({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Creates a minimal test widget for widget testing
  static Widget createMinimalTestWidget(Widget child) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }

  /// Common chart test data
  static List<Map<String, dynamic>> getTestChartData() {
    return [
      {'x': 0, 'y': 10, 'label': 'Point 1'},
      {'x': 1, 'y': 20, 'label': 'Point 2'},
      {'x': 2, 'y': 15, 'label': 'Point 3'},
      {'x': 3, 'y': 30, 'label': 'Point 4'},
      {'x': 4, 'y': 25, 'label': 'Point 5'},
    ];
  }

  /// Large dataset for performance testing
  static List<Map<String, dynamic>> getLargeTestDataset(int size) {
    return List.generate(size, (index) => {
      'x': index,
      'y': (index * 0.5) + (index % 10),
      'label': 'Point $index',
    });
  }

  /// Custom matcher for comparing doubles with tolerance
  static Matcher closeTo(double value, {double tolerance = 0.001}) {
    return _CloseToMatcher(value, tolerance);
  }

  /// Waits for animations to complete
  static Future<void> pumpAndSettle(WidgetTester tester, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Simulates device pixel ratio changes
  static void setDevicePixelRatio(WidgetTester tester, double ratio) {
    tester.binding.window.devicePixelRatioTestValue = ratio;
  }

  /// Resets device pixel ratio to default
  static void resetDevicePixelRatio(WidgetTester tester) {
    tester.binding.window.clearDevicePixelRatioTestValue();
  }
}

class _CloseToMatcher extends Matcher {
  final double _value;
  final double _tolerance;

  const _CloseToMatcher(this._value, this._tolerance);

  @override
  bool matches(item, Map matchState) {
    if (item is! double) return false;
    return (item - _value).abs() <= _tolerance;
  }

  @override
  Description describe(Description description) {
    return description.add('close to $_value within tolerance $_tolerance');
  }
}