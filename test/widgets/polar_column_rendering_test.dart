import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/polar_column_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Polar Column through BravenChartPlus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'orders',
                  values: const {
                    'Search': 64,
                    'Social': 28,
                    'Partners': 45,
                    'Email': 16,
                  },
                ),
              ],
              polarChartConfig: const PolarChartConfig(
                angularAxis: PolarCategoryAxisConfig(showLabels: false),
              ),
              theme: ChartTheme.light,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.geometry.marks, hasLength(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pointer activation selects a Polar Column mark', (tester) async {
    List<ChartDataPoint> selection = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.square(
              dimension: 360,
              child: BravenChartPlus(
                series: [
                  PolarColumnChartSeries.fromMap(
                    id: 'orders',
                    values: const {'Search': 64, 'Social': 28},
                  ),
                ],
                polarChartConfig: const PolarChartConfig(
                  angularAxis: PolarCategoryAxisConfig(showLabels: false),
                ),
                interactionConfig: InteractionConfig(
                  onSelectionChanged: (points) => selection = points,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final chartFinder = find.byType(BravenChartPlus);
    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    final localTarget = renderBox.plotToWidget(
      element.geometry.marks.first.tooltipAnchor,
    );
    await tester.tapAt(tester.getTopLeft(chartFinder) + localTarget);
    await tester.pump();

    expect(selection, hasLength(1));
    expect(selection.single.label, 'Search');
    expect(tester.takeException(), isNull);
  });

  testWidgets('honors large text while preserving complete semantic data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 240,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'dense',
                  values: {
                    for (var index = 0; index < 16; index++)
                      'Category ${index + 1}': 20 + index,
                  },
                ),
              ],
              theme: ChartTheme.highContrast,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.textScaleFactor, 1.6);
    expect(element.visibleAngularLabelIndices.length, lessThan(16));
    expect(element.semanticDataHits, hasLength(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion resolves Polar Column at its final geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox.square(
            dimension: 320,
            child: BravenChartPlus(
              series: [
                PolarColumnChartSeries.fromMap(
                  id: 'reduced-motion',
                  values: const {'North': 12, 'East': 24, 'South': 18},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<PolarColumnSeriesElement>()
        .single;
    expect(element.revealProgress, 1);
    expect(element.geometry.marks.every((mark) => mark.isVisible), isTrue);
    expect(tester.takeException(), isNull);
  });
}
