// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    '5,000-point brush hit resolution and overlay paint stay below 1 ms median',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 900,
            height: 500,
            child: BravenChartPlus(
              bravenChartController: controller,
              showLegend: false,
              series: [
                LineChartSeries(
                  id: 'signal',
                  isXOrdered: true,
                  points: [
                    for (var index = 0; index < 5000; index++)
                      ChartDataPoint(
                        x: index.toDouble(),
                        y: 50 + math.sin(index / 29) * 20,
                      ),
                  ],
                ),
              ],
              interactionConfig: const InteractionConfig(
                selection: ChartSelectionConfig(
                  acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
                  useModifierKeys: false,
                  brush: ChartSelectionBrushConfig(
                    enabled: true,
                    initialVisible: true,
                    initialRange: ChartSelectionBrushRange(
                      minimum: 1800,
                      maximum: 2400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox =
          find
                  .byWidgetPredicate(
                    (widget) =>
                        widget.runtimeType.toString() == '_ChartRenderWidget',
                  )
                  .evaluate()
                  .single
                  .renderObject!
              as ChartRenderBox;
      final rect = renderBox.selectionBrushWidgetRect!;

      void runOne() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        renderBox.debugPaintPersistentSelectionBrush(canvas);
        final result = renderBox.selectionGestureForWidgetRect(
          rect,
          isPersistentBrushUpdate: true,
          isFinal: false,
        );
        expect(result, isNotNull);
        recorder.endRecording().dispose();
      }

      for (var warmup = 0; warmup < 60; warmup++) {
        runOne();
      }
      final samples = <int>[];
      for (var iteration = 0; iteration < 300; iteration++) {
        final stopwatch = Stopwatch()..start();
        runOne();
        stopwatch.stop();
        samples.add(stopwatch.elapsedMicroseconds);
      }
      samples.sort();
      final median = samples[samples.length ~/ 2];
      final p95 = samples[(samples.length * 0.95).ceil() - 1];

      // ignore: avoid_print
      print(
        'Persistent brush (5,000 points): '
        'median ${(median / 1000).toStringAsFixed(3)}ms; '
        'p95 ${(p95 / 1000).toStringAsFixed(3)}ms',
      );
      expect(
        median,
        lessThan(1000),
        reason:
            'brush hit resolution plus overlay recording must remain below '
            '1 ms median',
      );
    },
  );
}
