import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/generated_source_compile.dart';

void main() {
  testWidgets(
    'Radar survives document, JSON, table, and both source round trips',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final series = <RadarChartSeries>[
        RadarChartSeries.fromMap(
          id: 'allocated',
          name: 'Allocated budget',
          unit: 'k USD',
          color: const Color(0xFF2563EB),
          values: const {
            'Sales': 80,
            'Marketing': 45,
            'Development': 72,
            'Support': 51,
          },
          radarStyle: const RadarSeriesStyle(
            strokeWidth: 3,
            strokeOpacity: 0.85,
            strokeDashPattern: <double>[8, 4],
            fillColor: Color(0x332563EB),
            fillOpacity: 0.2,
            gradient: RadarGradientStyle(
              type: RadarGradientType.linear,
              startColor: Color(0xFF38BDF8),
              endColor: Color(0xFF1D4ED8),
              angleDegrees: 30,
            ),
            shadow: RadarShadowStyle(
              color: Color(0xFF1E3A8A),
              blurRadius: 9,
              spreadRadius: 1.5,
              offset: Offset(2, 3),
              opacity: 0.32,
            ),
            markerShape: SeriesMarkerShape.diamond,
            markerRadius: 4,
            markerFillColor: Color(0xFFF8FAFC),
            markerBorderColor: Color(0xFF1E3A8A),
            markerBorderWidth: 1.5,
            showDataLabels: true,
            maximumVisibleDataLabels: 3,
            dataLabelOffset: 11,
            dataLabelStyle: PolarLabelStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        RadarChartSeries.fromMap(
          id: 'actual',
          name: 'Actual spending',
          unit: 'k USD',
          color: const Color(0xFFDB2777),
          values: const {
            'Sales': 68,
            'Marketing': 61,
            'Development': 84,
            'Support': 43,
          },
        ),
      ];
      const config = RadarChartConfig(
        pane: PolarPaneConfig(startAngleDegrees: -75, outerRadiusFactor: 0.82),
        categoryAxis: RadarCategoryAxisConfig(
          maximumVisibleLabels: 12,
          labelOffset: 11,
        ),
        radialAxis: RadarNumericAxisConfig(
          maximum: 100,
          tickCount: 6,
          gridShape: RadarGridShape.circle,
          labelPosition: PolarRadialLabelPosition.end,
          labelAngleOffsetDegrees: 8,
          labelOffset: 6,
        ),
        webStyle: RadarWebStyle(
          ringColor: Color(0xFFCBD5E1),
          ringWidth: 1.25,
          ringDashPattern: <double>[4, 3],
          spokeColor: Color(0xFF94A3B8),
          spokeWidth: 0.75,
          spokeDashPattern: <double>[],
          boundaryColor: Color(0xFF475569),
          boundaryWidth: 2,
          boundaryDashPattern: <double>[8, 3],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 520,
              child: BravenChartPlus(
                title: 'Budget vs spending',
                bravenChartController: controller,
                series: series,
                radarChartConfig: config,
                showLegend: true,
                grid: const GridConfig(horizontal: false, vertical: false),
                xAxisConfig: const XAxisConfig(visible: false),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final snapshot = _success(controller.extractDocument()).value;
      expect(
        snapshot.document.requiredCapabilities,
        containsAll(<String>{
          'series.radar',
          'series.radar.v1',
          'chart.radar.config.v1',
        }),
      );

      final hydrated = _success(
        ChartDocumentHydrator.hydrateDocument(snapshot.document),
      ).value;
      expect(hydrated.series, series);
      expect(hydrated.radarChartConfig, config);

      final artifact = _success(
        await controller.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'radar-budget',
            createdAt: DateTime.utc(2026, 8, 7, 12),
          ),
        ),
      ).value;
      final encoded = _success(ChartArtifactJsonCodec.encode(artifact)).value;
      final restored = _success(
        ChartDocumentHydrator.hydrateJson(encoded),
      ).value;
      expect(restored.series, series);
      expect(restored.radarChartConfig, config);

      final table = ChartTableModel.fromDocument(snapshot.document);
      expect(table.xColumnLabel, 'Category');
      expect(table.wideRows.map((row) => row.xDisplay), <String>[
        'Sales',
        'Marketing',
        'Development',
        'Support',
      ]);
      expect(table.wideRows.every((row) => row.cells.length == 2), isTrue);

      final direct = _success(
        ChartDartSourceGenerator.generate(snapshot),
      ).value.source;
      expect(direct, contains('RadarChartSeries('));
      expect(direct, contains('radarChartConfig: RadarChartConfig('));
      expect(direct, contains('strokeDashPattern: <double>[8.0, 4.0]'));
      expect(direct, contains('gradient: RadarGradientStyle('));
      expect(direct, contains('shadow: RadarShadowStyle('));
      expect(direct, contains('markerShape: SeriesMarkerShape.diamond'));
      expect(direct, contains('markerBorderWidth: 1.5'));
      expect(direct, contains('maximumVisibleDataLabels: 3'));
      expect(direct, contains('dataLabelOffset: 11.0'));
      expect(direct, contains('dataLabelStyle: PolarLabelStyle('));
      expect(direct, contains('webStyle: RadarWebStyle('));

      final grammar = _success(
        ChartGrammarSourceGenerator.generate(
          snapshot,
          options: const ChartGrammarSourceOptions(
            variableName: 'budgetRadar',
            rowClassName: 'BudgetProfileRow',
            rowsVariableName: 'budgetRows',
          ),
        ),
      ).value.source;
      expect('.geomRadar('.allMatches(grammar), hasLength(2));
      expect(grammar, contains('.radarConfig('));
      expect(grammar, contains('class BudgetProfileRow'));

      await tester.runAsync(() async {
        await expectGeneratedSourceCompiles(
          direct,
          fixtureName: 'radar_direct_source_compile_test',
        );
        await expectGeneratedSourceCompiles(
          grammar,
          fixtureName: 'radar_grammar_source_compile_test',
        );
      });
      expect(tester.takeException(), isNull);
    },
  );
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  if (result case final ChartArtifactFailure<T> failure) {
    fail(
      '${failure.error.code}: ${failure.error.message} '
      'at ${failure.error.path}',
    );
  }
  return result as ChartArtifactSuccess<T>;
}
