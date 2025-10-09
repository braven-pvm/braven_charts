/// Debug Integration Test: Zoom Bounds Analysis
///
/// This test creates a chart and applies zoom operations while capturing
/// detailed debug information about the bounds calculations.
///
/// Purpose: Identify why chart data disappears during keyboard zoom operations.
library;

import 'dart:convert';
import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Debug zoom bounds - analyze bounds at each zoom level', (tester) async {
    // Create test data - simple line from (0,0) to (10,100)
    final series = ChartSeries(
      id: 'test',
      name: 'Test Data',
      points: [
        const ChartDataPoint(x: 0, y: 0),
        const ChartDataPoint(x: 2, y: 20),
        const ChartDataPoint(x: 4, y: 40),
        const ChartDataPoint(x: 6, y: 60),
        const ChartDataPoint(x: 8, y: 80),
        const ChartDataPoint(x: 10, y: 100),
      ],
    );

    // Build test app
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: BravenChart(
                chartType: ChartType.line,
                series: [series],
                theme: ChartTheme.defaultLight,
                xAxis: AxisConfig.defaults(),
                yAxis: AxisConfig.defaults(),
                interactionConfig: const InteractionConfig(
                  keyboard: KeyboardConfig(enabled: true),
                  enableZoom: true,
                  enablePan: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Helper to create debug report
    Future<void> captureDebugInfo(String label, int zoomLevel) async {
      final screenshot = await binding.takeScreenshot('debug_zoom_${zoomLevel}_$label');
      final report = {
        'label': label,
        'zoomLevel': zoomLevel,
        'expectedZoomFactor': (1.2 * zoomLevel).toStringAsFixed(2),
        'screenshotSize': screenshot.length,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Write report to file
      final reportFile = File('example/screenshots/debug_zoom_${zoomLevel}_${label}_report.json');
      await reportFile.parent.create(recursive: true);
      await reportFile.writeAsString(const JsonEncoder.withIndent('  ').convert(report));

      print('');
      print('=' * 80);
      print('DEBUG REPORT: $label');
      print('=' * 80);
      print('Zoom Level: $zoomLevel');
      print('Expected Zoom Factor: ${report['expectedZoomFactor']}');
      print('Screenshot Size: ${screenshot.length} bytes');
      print('=' * 80);
      print('');
    }

    // Capture baseline (no zoom)
    await captureDebugInfo('baseline', 0);

    // Apply incremental zoom and capture at each level
    for (int i = 1; i <= 6; i++) {
      print('Applying zoom step $i (Numpad +)...');

      // Simulate NumpadAdd keypress
      await tester.sendKeyDownEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.numpadAdd);
      await tester.pumpAndSettle();

      // Wait for render
      await Future.delayed(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Capture debug info
      await captureDebugInfo('after_zoom', i);
    }

    print('');
    print('=' * 80);
    print('DEBUG TEST COMPLETE');
    print('=' * 80);
    print('Check example/screenshots/ for:');
    print('  - Screenshots: debug_zoom_N_*.png');
    print('  - Reports: debug_zoom_N_*_report.json');
    print('=' * 80);
    print('');

    // Test passes - we're just collecting debug data
    expect(true, true);
  });
}
