import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/polar_column_series_element.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scenarioBuilders = <String, _PolarScenario Function()>{
    'layered full-sweep references': _layeredScenario,
    'grouped partial counter-clockwise pane': _groupedScenario,
    'diverging stack in a narrow sweep': _stackedScenario,
    'dense Rose area scale': _roseScenario,
  };

  for (final MapEntry(key: name, value: buildScenario)
      in scenarioBuilders.entries) {
    testWidgets('$name preserves exact selection through resize', (
      tester,
    ) async {
      final scenario = buildScenario();
      final controller = BravenChartController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          size: const Size(420, 360),
          controller: controller,
          scenario: scenario,
        ),
      );
      await tester.pump();
      final initialElements = _elements(tester);
      expect(initialElements, hasLength(scenario.series.length));
      expect(
        initialElements.first.pane.sweepAngle.abs(),
        closeTo(scenario.config.pane.sweepAngleDegrees * math.pi / 180, 1e-9),
      );
      expect(
        initialElements.every(
          (element) =>
              element.geometry.marks.length ==
              scenario.series.first.points.length,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);

      final revision = controller.effectiveDocumentRevision.value!;
      expect(
        controller.selectPoint(scenario.selectedRef, revision: revision),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();

      var selectedElement = _elements(tester).singleWhere(
        (element) => element.series.id == scenario.selectedRef.seriesId,
      );
      expect(selectedElement.selectedPointIndices, {
        scenario.selectedRef.pointIndex,
      });
      _expectExactHit(selectedElement, scenario.selectedRef);

      await tester.pumpWidget(
        _host(
          size: const Size(260, 220),
          controller: controller,
          scenario: scenario,
        ),
      );
      await tester.pump();

      expect(controller.selectedPointRefs, {scenario.selectedRef});
      selectedElement = _elements(tester).singleWhere(
        (element) => element.series.id == scenario.selectedRef.seriesId,
      );
      expect(selectedElement.selectedPointIndices, {
        scenario.selectedRef.pointIndex,
      });
      _expectExactHit(selectedElement, scenario.selectedRef);
      expect(
        _elements(tester).expand((element) => element.semanticDataHits),
        hasLength(
          scenario.series.fold<int>(
            0,
            (total, series) => total + series.points.length,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}

void _expectExactHit(
  PolarColumnSeriesElement element,
  ChartPointRef selectedRef,
) {
  final hit = element.dataHitForPointIndex(selectedRef.pointIndex);
  expect(hit, isNotNull);
  expect(hit!.seriesId, selectedRef.seriesId);
  expect(hit.pointIndex, selectedRef.pointIndex);
  expect(hit.category, element.series.categories[selectedRef.pointIndex]);
  expect(hit.isSelected, isTrue);
  expect(hit.plotPosition.dx.isFinite, isTrue);
  expect(hit.plotPosition.dy.isFinite, isTrue);
  expect(hit.semanticBounds.isEmpty, isFalse);
}

List<PolarColumnSeriesElement> _elements(WidgetTester tester) => tester
    .renderObject<ChartRenderBox>(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
      ),
    )
    .debugElements
    .whereType<PolarColumnSeriesElement>()
    .toList();

Widget _host({
  required Size size,
  required BravenChartController controller,
  required _PolarScenario scenario,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: BravenChartPlus(
          bravenChartController: controller,
          series: scenario.series,
          polarChartConfig: scenario.config,
          theme: scenario.theme,
          showLegend: false,
        ),
      ),
    ),
  ),
);

class _PolarScenario {
  _PolarScenario({
    required this.config,
    required this.series,
    required this.selectedRef,
    ChartTheme? theme,
  }) : theme = theme ?? ChartTheme.light;

  final PolarChartConfig config;
  final List<PolarColumnChartSeries> series;
  final ChartPointRef selectedRef;
  final ChartTheme theme;
}

_PolarScenario _layeredScenario() => _PolarScenario(
  config: const PolarChartConfig(
    pane: PolarPaneConfig(startAngleDegrees: 40),
    thresholds: [
      PolarThreshold(value: 50, label: 'Target', color: Colors.deepPurple),
    ],
  ),
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'capacity',
      values: const {'Search': 80, 'Social': 70, 'Email': 60, 'Partners': 75},
      color: Colors.blueGrey,
      targets: const {'Search': 72, 'Social': 64},
      polarStyle: const PolarColumnStyle(
        cornerRadius: 6,
        cornerRadiusMode: PolarColumnCornerRadiusMode.outerEnd,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'actual',
      values: const {'Search': 55, 'Social': 48, 'Email': 51, 'Partners': 64},
      color: Colors.blue,
      intervals: const {
        'Search': PolarColumnInterval(lower: 49, upper: 62),
        'Partners': PolarColumnInterval(lower: 58, upper: 70),
      },
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.explode,
        liftOffset: 8,
      ),
    ),
  ],
  selectedRef: const ChartPointRef(seriesId: 'actual', pointIndex: 3),
);

_PolarScenario _groupedScenario() => _PolarScenario(
  config: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: 135,
      sweepAngleDegrees: 220,
      clockwise: false,
      innerRadiusFactor: 0.16,
      outerRadiusFactor: 0.92,
    ),
    angularAxis: PolarCategoryAxisConfig(
      innerPadding: 0.18,
      outerPadding: 0.08,
    ),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.grouped,
      groupInnerPadding: 0.22,
    ),
  ),
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'north',
      values: const {'Search': 42, 'Social': 35, 'Email': 51, 'Partners': 46},
      color: Colors.indigo,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 8,
        cornerRadiusMode: PolarColumnCornerRadiusMode.bothEnds,
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.1,
        liftOffset: 6,
        backdropBlur: 1.5,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'south',
      values: const {'Search': 38, 'Social': 40, 'Email': 44, 'Partners': 49},
      color: Colors.teal,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 8,
        cornerRadiusMode: PolarColumnCornerRadiusMode.bothEnds,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'west',
      values: const {'Search': 31, 'Social': 45, 'Email': 39, 'Partners': 43},
      color: Colors.orange,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 8,
        cornerRadiusMode: PolarColumnCornerRadiusMode.bothEnds,
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.1,
        liftOffset: 6,
        backdropBlur: 1.5,
      ),
    ),
  ],
  selectedRef: const ChartPointRef(seriesId: 'west', pointIndex: 2),
);

_PolarScenario _stackedScenario() => _PolarScenario(
  config: const PolarChartConfig(
    pane: PolarPaneConfig(
      startAngleDegrees: 40,
      sweepAngleDegrees: 110,
      innerRadiusFactor: 0.12,
    ),
    radialAxis: PolarNumericAxisConfig(tickCount: 6),
    composition: PolarColumnCompositionConfig(
      mode: PolarColumnCompositionMode.stacked,
    ),
    thresholds: [PolarThreshold(value: 40, label: 'Plan')],
  ),
  series: [
    PolarColumnChartSeries.fromMap(
      id: 'base',
      values: const {'Search': 30, 'Social': 24, 'Email': 28, 'Partners': 32},
      color: Colors.blue,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 7,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
      ),
      selectionStyle: const RadialSelectionStyle(
        effect: RadialSelectionEffect.lift,
        liftScale: 1.12,
        liftOffset: 7,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'growth',
      values: const {'Search': 12, 'Social': 9, 'Email': 14, 'Partners': 11},
      color: Colors.red,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 7,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
      ),
    ),
    PolarColumnChartSeries.fromMap(
      id: 'churn',
      values: const {'Search': -8, 'Social': -11, 'Email': -7, 'Partners': -10},
      color: Colors.green,
      polarStyle: const PolarColumnStyle(
        cornerRadius: 7,
        cornerRadiusMode: PolarColumnCornerRadiusMode.stackExterior,
      ),
    ),
  ],
  selectedRef: const ChartPointRef(seriesId: 'base', pointIndex: 0),
  theme: ChartTheme.highContrast,
);

_PolarScenario _roseScenario() => _PolarScenario(
  config: const PolarChartConfig(
    pane: PolarPaneConfig(startAngleDegrees: -135, innerRadiusFactor: 0.08),
    angularAxis: PolarCategoryAxisConfig(
      maximumVisibleLabels: 8,
      maximumVisibleGridLines: 12,
    ),
    radialAxis: PolarNumericAxisConfig(
      scaleMode: PolarRadialScaleMode.areaCorrect,
    ),
  ),
  series: [
    PolarColumnChartSeries.rose(
      id: 'rose',
      values: const {
        'Channel 1': 12,
        'Channel 2': 29,
        'Channel 3': 46,
        'Channel 4': 22,
        'Channel 5': 39,
        'Channel 6': 15,
        'Channel 7': 32,
        'Channel 8': 49,
        'Channel 9': 25,
        'Channel 10': 42,
        'Channel 11': 18,
        'Channel 12': 35,
        'Channel 13': 52,
        'Channel 14': 28,
        'Channel 15': 45,
        'Channel 16': 21,
      },
      polarStyle: const PolarColumnStyle(maximumVisibleDataLabels: 7),
    ),
  ],
  selectedRef: const ChartPointRef(seriesId: 'rose', pointIndex: 13),
);
