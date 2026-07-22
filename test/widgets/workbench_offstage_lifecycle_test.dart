// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// Workbench lifecycle around a REMOUNTED chart and a retained, hidden pane.
///
/// Two contracts a host page relies on:
///
/// * a workbench-hosted chart may be remounted (a preset switch, a rebuilt
///   subtree) while the workbench controller still holds table/source state.
///   The chart state attaches from `initState`, i.e. inside the workbench's
///   own build. Nothing on that path may notify workbench listeners
///   synchronously, or the AnimatedBuilder above it is marked dirty during
///   build;
/// * a pane the workbench keeps mounted but hidden must stop animating.
///   A retained Source pane whose progress bar keeps ticking schedules frames
///   forever, which is both a battery/CPU leak on the web and the reason a
///   workbench test can never settle.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'remounting the chart after Source was visited never notifies during build',
    (tester) async {
      final chartController = BravenChartController();
      final workbenchController = ChartWorkbenchController();
      addTearDown(chartController.dispose);
      addTearDown(workbenchController.dispose);

      await tester.pumpWidget(
        _host(
          chartController: chartController,
          workbenchController: workbenchController,
          chartKey: 'preset-a',
        ),
      );
      await tester.pumpAndSettle();
      expect(workbenchController.generatedSource, isNotNull);

      // A preset switch: the chart subtree is replaced, so a fresh chart state
      // attaches to the retained controller from inside the workbench build.
      await tester.pumpWidget(
        _host(
          chartController: chartController,
          workbenchController: workbenchController,
          chartKey: 'preset-b',
          chartValue: 40,
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'attaching a remounted chart must not rebuild during build',
      );
    },
  );

  testWidgets('a hidden Source pane stops scheduling frames', (tester) async {
    final chartController = BravenChartController();
    final workbenchController = ChartWorkbenchController();
    addTearDown(chartController.dispose);
    addTearDown(workbenchController.dispose);

    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        chartKey: 'preset-a',
      ),
    );
    await tester.pumpAndSettle();
    expect(workbenchController.generatedSource, isNotNull);

    // Leave Source. The pane stays mounted so returning to it is instant.
    workbenchController.setDisplayMode(ChartDisplayMode.chart);
    await tester.pumpAndSettle();

    // The chart moves on while Source is hidden, so the retained pane goes
    // stale and shows its "awaiting refresh" progress bar — offstage.
    await tester.pumpWidget(
      _host(
        chartController: chartController,
        workbenchController: workbenchController,
        chartKey: 'preset-b',
        chartValue: 40,
      ),
    );
    await tester.pump();
    expect(workbenchController.sourceIsStale, isTrue);

    // A hidden pane must not keep the scheduler awake.
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  required BravenChartController chartController,
  required ChartWorkbenchController workbenchController,
  required String chartKey,
  double chartValue = 10,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 1000,
        height: 560,
        child: BravenChartWorkbench(
          chartController: chartController,
          workbenchController: workbenchController,
          initialDisplayMode: ChartDisplayMode.source,
          availableDisplayModes: const {
            ChartDisplayMode.chart,
            ChartDisplayMode.source,
          },
          chartBuilder: (context, controller) => BravenChartPlus(
            key: ValueKey(chartKey),
            bravenChartController: controller,
            showLegend: false,
            series: [
              LineChartSeries(
                id: 'signal',
                name: 'Signal',
                points: [
                  ChartDataPoint(x: 0, y: chartValue),
                  ChartDataPoint(x: 1, y: chartValue + 2),
                  ChartDataPoint(x: 2, y: chartValue + 1),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
