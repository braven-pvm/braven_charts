import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/gauge_series_element.dart';
import 'package:braven_charts/src/models/gauge_chart_config.dart';
import 'package:braven_charts/src/models/gauge_chart_series.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders and inspects Gauge without durable selection', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    ChartDataPoint? tappedPoint;
    String? tappedSeriesId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox.square(
              dimension: 420,
              child: BravenChartPlus(
                key: const ValueKey('gauge'),
                bravenChartController: controller,
                series: [
                  GaugeChartSeries.needle(
                    id: 'uptime',
                    metric: 'Uptime',
                    unit: '%',
                    value: 82,
                    minimum: 0,
                    maximum: 100,
                    target: const GaugeTarget(value: 90, label: 'SLO'),
                  ),
                ],
                gaugeChartConfig: const GaugeChartConfig(showTickLabels: false),
                onPointTap: (point, seriesId) {
                  tappedPoint = point;
                  tappedSeriesId = seriesId;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<GaugeSeriesElement>()
        .single;
    final target = renderBox.plotToWidget(element.geometry.tooltipAnchor);
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const ValueKey('gauge'))) + target,
    );
    await tester.pump();

    expect(tappedPoint?.y, 82);
    expect(tappedSeriesId, 'uptime');
    expect(controller.selectedPointRefs, isEmpty);
    expect(
      controller.focusedPointRefs,
      contains(const ChartPointRef(seriesId: 'uptime', pointIndex: 0)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders Solid Gauge through the same dedicated element', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 360,
          child: BravenChartPlus(
            series: [
              GaugeChartSeries.solid(
                id: 'load',
                metric: 'Load',
                value: 3.8,
                minimum: 0,
                maximum: 5,
                style: const SolidGaugeStyle(cornerRadius: 10),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = tester.renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    );
    final element = renderBox.debugElements
        .whereType<GaugeSeriesElement>()
        .single;
    expect(element.geometry.solid, isNotNull);
    expect(element.geometry.normalizedProgress, closeTo(0.76, 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('interpolates Gauge value updates from the previous reading', (
    tester,
  ) async {
    var value = 20.0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return SizedBox.square(
              dimension: 360,
              child: BravenChartPlus(
                series: [
                  GaugeChartSeries.solid(
                    id: 'load',
                    metric: 'Load',
                    value: value,
                    minimum: 0,
                    maximum: 100,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    update(() => value = 80);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    final element = tester
        .renderObject<ChartRenderBox>(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        )
        .debugElements
        .whereType<GaugeSeriesElement>()
        .single;
    expect(element.series.value, greaterThan(20));
    expect(element.series.value, lessThan(80));

    await tester.pumpAndSettle();
    final settled = tester
        .renderObject<ChartRenderBox>(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        )
        .debugElements
        .whereType<GaugeSeriesElement>()
        .single;
    expect(settled.series.value, 80);
  });

  testWidgets('reduced motion applies Gauge value updates immediately', (
    tester,
  ) async {
    var value = 20.0;
    late StateSetter update;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SizedBox.square(
                dimension: 360,
                child: BravenChartPlus(
                  series: [
                    GaugeChartSeries.solid(
                      id: 'load',
                      metric: 'Load',
                      value: value,
                      minimum: 0,
                      maximum: 100,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    update(() => value = 80);
    await tester.pump();

    final element = tester
        .renderObject<ChartRenderBox>(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        )
        .debugElements
        .whereType<GaugeSeriesElement>()
        .single;
    expect(element.series.value, 80);
  });

  testWidgets('high contrast adds explicit zone boundaries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: SizedBox.square(
            dimension: 360,
            child: BravenChartPlus(
              theme: ChartTheme.highContrast,
              series: [
                GaugeChartSeries.needle(
                  id: 'latency',
                  metric: 'Latency',
                  value: 68,
                  minimum: 0,
                  maximum: 100,
                  zones: const [
                    GaugeZone(from: 0, to: 50, status: 'Healthy'),
                    GaugeZone(from: 50, to: 80, status: 'Elevated'),
                    GaugeZone(from: 80, to: 100, status: 'Critical'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final element = tester
        .renderObject<ChartRenderBox>(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
          ),
        )
        .debugElements
        .whereType<GaugeSeriesElement>()
        .single;
    expect(element.highContrast, isTrue);
    expect(element.geometry.zones, hasLength(3));
  });

  testWidgets('bounds a runtime Gauge center builder to the center opening', (
    tester,
  ) async {
    GaugeCenterContext? received;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 360,
          child: BravenChartPlus(
            series: [
              GaugeChartSeries.needle(
                id: 'latency',
                name: 'API latency',
                metric: 'Latency',
                unit: 'ms',
                value: 42,
                minimum: 0,
                maximum: 100,
              ),
            ],
            gaugeCenterBuilder: (context, center) {
              received = center;
              return Center(
                child: Text(center.formattedValue, key: const Key('center')),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('center')), findsOneWidget);
    expect(received?.seriesId, 'latency');
    expect(received?.metric, 'Latency');
    expect(received?.value, 42);
    expect(received?.availableSize.width, greaterThan(0));
    expect(received?.availableSize.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('extracts, hydrates, and emits a complete Gauge chart', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    final series = GaugeChartSeries.solid(
      id: 'availability',
      name: 'Availability',
      metric: 'Service availability',
      value: 99.93,
      minimum: 99,
      maximum: 100,
      unit: '%',
      target: const GaugeTarget(value: 99.9, label: 'SLO'),
      zones: const [
        GaugeZone(from: 99, to: 99.9, status: 'At risk'),
        GaugeZone(from: 99.9, to: 100, status: 'Healthy'),
      ],
      style: const SolidGaugeStyle(cornerRadius: 10),
    );
    const config = GaugeChartConfig(
      tickCount: 5,
      center: GaugeCenterConfig(showTarget: true),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 380,
          child: BravenChartPlus(
            bravenChartController: controller,
            series: [series],
            gaugeChartConfig: config,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final snapshot = _success(controller.extractDocument()).value;
    expect(
      snapshot.document.requiredCapabilities,
      containsAll(<String>['series.gauge.v1', 'chart.gauge.config.v1']),
    );
    final hydrated = _success(
      ChartDocumentHydrator.hydrateDocument(snapshot.document),
    ).value;
    expect(hydrated.series.single, series);
    expect(hydrated.gaugeChartConfig, config);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 380,
          child: hydrated.build(
            gaugeCenterBuilder: (context, center) =>
                Text(center.formattedValue, key: const Key('hydrated-center')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('hydrated-center')), findsOneWidget);

    final generated = _success(
      ChartDartSourceGenerator.generate(snapshot),
    ).value.source;
    expect(generated, contains('GaugeChartSeries.solid('));
    expect(generated, contains('metric: \'Service availability\''));
    expect(generated, contains('gaugeChartConfig: GaugeChartConfig('));
    expect(generated, contains('GaugeCenterConfig('));
    expect(tester.takeException(), isNull);
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  if (result case ChartArtifactFailure<T> failure) {
    fail(
      '${failure.error.code}: ${failure.error.message} '
      'at ${failure.error.path}',
    );
  }
  return result as ChartArtifactSuccess<T>;
}
