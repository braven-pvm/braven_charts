import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Golden test utilities for visual regression testing
class GoldenTestUtils {
  /// Standard test sizes for chart golden tests
  static const Size chartSmall = Size(300, 200);
  static const Size chartMedium = Size(600, 400);
  static const Size chartLarge = Size(1200, 800);
  
  static const List<Size> chartSizes = [
    chartSmall,
    chartMedium,
    chartLarge,
  ];

  /// Runs golden tests for different chart sizes
  static Future<void> testChartForSizes({
    required String name,
    required Widget widget,
    List<Size> sizes = chartSizes,
  }) async {
    for (int i = 0; i < sizes.length; i++) {
      final size = sizes[i];
      final sizeName = ['small', 'medium', 'large'][i];
      
      testGoldens(
        '${name}_$sizeName',
        (tester) async {
          await tester.pumpWidgetBuilder(
            widget,
            wrapper: materialAppWrapper(
              theme: ThemeData.light(),
            ),
            surfaceSize: size,
          );
        },
      );
    }
  }

  /// Tests chart themes (light and dark)
  static Future<void> testChartThemes({
    required String name,
    required Widget Function(ThemeData theme) chartBuilder,
    Size size = chartMedium,
  }) async {
    final themes = {
      'light': ThemeData.light(),
      'dark': ThemeData.dark(),
    };

    for (final entry in themes.entries) {
      testGoldens(
        '${name}_${entry.key}',
        (tester) async {
          await tester.pumpWidgetBuilder(
            chartBuilder(entry.value),
            wrapper: materialAppWrapper(theme: entry.value),
            surfaceSize: size,
          );
        },
      );
    }
  }

  /// Tests chart states (loading, error, data)
  static Future<void> testChartStates({
    required String name,
    required Map<String, Widget> stateWidgets,
    Size size = chartMedium,
  }) async {
    for (final entry in stateWidgets.entries) {
      testGoldens(
        '${name}_${entry.key}',
        (tester) async {
          await tester.pumpWidgetBuilder(
            entry.value,
            wrapper: materialAppWrapper(),
            surfaceSize: size,
          );
        },
      );
    }
  }

  /// Helper to create material app wrapper
  static Widget Function(Widget) materialAppWrapper({ThemeData? theme}) {
    return (Widget child) => MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
      debugShowCheckedModeBanner: false,
    );
  }
}