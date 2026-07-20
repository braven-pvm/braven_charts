import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'captures, tables, transports, and hydrates Polar Column without shares',
    (tester) async {
      final sourceController = BravenChartController();
      addTearDown(sourceController.dispose);
      const sourceConfig = PolarChartConfig(
        pane: PolarPaneConfig(
          startAngleDegrees: -35,
          sweepAngleDegrees: 285,
          clockwise: false,
          innerRadiusFactor: 0.18,
          outerRadiusFactor: 0.91,
          clipMarks: false,
        ),
        angularAxis: PolarCategoryAxisConfig(
          innerPadding: 0.2,
          outerPadding: 0.1,
          showLabels: true,
          showGridLines: false,
        ),
        radialAxis: PolarNumericAxisConfig(
          minimum: 0,
          maximum: 100,
          scaleMode: PolarRadialScaleMode.areaCorrect,
          tickCount: 6,
          showLabels: false,
          showGridLines: true,
        ),
      );
      final sourceSeries = PolarColumnChartSeries.rose(
        id: 'demand',
        name: 'Demand',
        unit: 'orders',
        color: const Color(0xFF6750A4),
        values: const {'North': 42, 'East': 68, 'South': 31, 'West': 55},
        columnColors: const {'East': Color(0xFF00A878)},
        polarStyle: const PolarColumnStyle(
          cornerRadius: 9,
          opacity: 0.82,
          borderColor: Color(0xFF102030),
          borderWidth: 2,
          showDataLabels: false,
        ),
        selectionStyle: const RadialSelectionStyle(
          effect: RadialSelectionEffect.lift,
          liftScale: 1.12,
          liftOffset: 8,
          backdropBlur: 2,
        ),
      );

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: sourceController,
            polarChartConfig: sourceConfig,
            showLegend: false,
            series: [sourceSeries],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initial = _snapshot(sourceController.extractDocument());
      expect(
        sourceController.selectPoint(
          const ChartPointRef(seriesId: 'demand', pointIndex: 1),
          revision: initial.revision,
        ),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pumpAndSettle();

      final snapshot = _snapshot(
        sourceController.extractDocument(
          const ChartDocumentExtractOptions(documentId: 'polar-demand'),
        ),
      );
      expect(snapshot.document.series.single.type, 'polarColumn');
      expect(
        snapshot.document.requiredCapabilities,
        containsAll({'series.polar.column.v1', 'chart.polar.config.v1'}),
      );
      expect(
        snapshot.document.configuration.values['polarChart'],
        isA<JsonObjectValue>(),
      );
      expect(snapshot.viewState?.selectedPointRefs, const [
        ChartPointRef(seriesId: 'demand', pointIndex: 1),
      ]);

      final table = ChartTableModel.fromDocument(snapshot.document);
      expect(table.projectionKind, ChartTableProjectionKind.polar);
      expect(table.polarRows.map((row) => row.category), [
        'North',
        'East',
        'South',
        'West',
      ]);
      expect(table.polarRows.map((row) => row.valueDisplay), [
        '42.00',
        '68.00',
        '31.00',
        '55.00',
      ]);
      final export = ChartTableExporter.csvForDisplayedRows(
        table,
        polarRows: table.polarRows,
      );
      expect(export.headers, ['#', 'Category', 'Series', 'Value (orders)']);
      expect(export.csv, isNot(contains('Share')));

      final capture = await _capture(
        tester,
        sourceController.extractArtifact(
          ChartArtifactExtractOptions(
            artifactId: 'polar-artifact',
            createdAt: DateTime.utc(2026, 7, 19, 12),
            documentOptions: const ChartDocumentExtractOptions(
              documentId: 'polar-demand',
            ),
          ),
        ),
      );
      expect(capture, isA<ChartArtifactSuccess<ChartArtifact>>());
      final artifact = (capture as ChartArtifactSuccess<ChartArtifact>).value;
      final firstJson = _json(ChartArtifactJsonCodec.encode(artifact));
      final secondJson = _json(ChartArtifactJsonCodec.encode(artifact));
      expect(secondJson, firstJson);

      final hydrated = _configuration(
        ChartDocumentHydrator.hydrateJson(firstJson),
      );
      expect(hydrated.polarChartConfig, sourceConfig);
      final restoredSeries = hydrated.series.single as PolarColumnChartSeries;
      expect(restoredSeries.preset, PolarColumnPreset.rose);
      expect(restoredSeries.polarStyle, sourceSeries.polarStyle);
      expect(restoredSeries.selectionStyle, sourceSeries.selectionStyle);
      expect(restoredSeries.categories, sourceSeries.categories);

      final restoredController = BravenChartController();
      addTearDown(restoredController.dispose);
      await tester.pumpWidget(
        _host(hydrated.build(bravenChartController: restoredController)),
      );
      await tester.pumpAndSettle();

      expect(restoredController.selectedPointRefs, {
        const ChartPointRef(seriesId: 'demand', pointIndex: 1),
      });
      expect(find.byType(BravenChartPlus), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'round-trips layered Polar Column series with explicit capability',
    (tester) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final series = <PolarColumnChartSeries>[
        PolarColumnChartSeries.fromMap(
          id: 'capacity',
          name: 'Capacity',
          unit: 'orders',
          color: const Color(0xFF94A3B8),
          values: const {'Search': 100, 'Social': 80, 'Partners': 90},
          polarStyle: const PolarColumnStyle(
            opacity: 0.35,
            showDataLabels: false,
          ),
        ),
        PolarColumnChartSeries.fromMap(
          id: 'observed',
          name: 'Observed',
          unit: 'orders',
          color: const Color(0xFF2563EB),
          values: const {'Search': 64, 'Social': 48, 'Partners': 72},
        ),
      ];

      await tester.pumpWidget(
        _host(
          BravenChartPlus(
            bravenChartController: controller,
            polarChartConfig: const PolarChartConfig(),
            series: series,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final snapshot = _snapshot(
        controller.extractDocument(
          const ChartDocumentExtractOptions(documentId: 'polar-comparison'),
        ),
      );
      expect(snapshot.document.series, hasLength(2));
      expect(
        snapshot.document.requiredCapabilities,
        contains('chart.polar.multiple-series.v1'),
      );

      final table = ChartTableModel.fromDocument(snapshot.document);
      expect(table.projectionKind, ChartTableProjectionKind.polar);
      expect(table.polarRows, hasLength(6));
      expect(table.polarRows.map((row) => row.seriesId), [
        'capacity',
        'capacity',
        'capacity',
        'observed',
        'observed',
        'observed',
      ]);
      final export = ChartTableExporter.csvForDisplayedRows(
        table,
        polarRows: table.polarRows,
      );
      expect(export.csv, contains('Capacity'));
      expect(export.csv, contains('Observed'));

      final hydrated = _configuration(
        ChartDocumentHydrator.hydrateDocument(snapshot.document),
      );
      expect(hydrated.series.map((item) => item.id), ['capacity', 'observed']);
      expect(
        hydrated.series.every((item) => item is PolarColumnChartSeries),
        isTrue,
      );

      final generated = ChartDartSourceGenerator.generate(snapshot);
      expect(generated, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      final source = (generated as ChartArtifactSuccess<ChartGeneratedSource>)
          .value
          .source;
      expect(
        RegExp('PolarColumnChartSeries\\(').allMatches(source),
        hasLength(2),
      );
      expect(source, contains("id: 'capacity'"));
      expect(source, contains("id: 'observed'"));

      final invalidJson = snapshot.document.toJson();
      invalidJson['requiredCapabilities'] = snapshot
          .document
          .requiredCapabilities
          .where((capability) => capability != 'chart.polar.multiple-series.v1')
          .toList();
      final invalid = ChartDocumentHydrator.hydrateDocument(
        ChartDocument.fromJson(invalidJson),
      );
      expect(invalid, isA<ChartArtifactFailure<HydratedChartConfiguration>>());
      expect(
        (invalid as ChartArtifactFailure<HydratedChartConfiguration>)
            .error
            .message,
        contains('chart.polar.multiple-series.v1'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('round-trips grouped Polar Column composition', (tester) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    const config = PolarChartConfig(
      composition: PolarColumnCompositionConfig(
        mode: PolarColumnCompositionMode.grouped,
        groupInnerPadding: 0.18,
      ),
    );
    final series = <PolarColumnChartSeries>[
      PolarColumnChartSeries.fromMap(
        id: 'north',
        name: 'North',
        unit: 'orders',
        values: const {'Search': 54, 'Social': 38},
      ),
      PolarColumnChartSeries.fromMap(
        id: 'south',
        name: 'South',
        unit: 'orders',
        values: const {'Search': 47, 'Social': 42},
      ),
      PolarColumnChartSeries.fromMap(
        id: 'west',
        name: 'West',
        unit: 'orders',
        values: const {'Search': 41, 'Social': 35},
      ),
    ];

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: config,
          series: series,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final snapshot = _snapshot(controller.extractDocument());
    expect(
      snapshot.document.requiredCapabilities,
      containsAll({
        'chart.polar.multiple-series.v1',
        'chart.polar.grouped-series.v1',
      }),
    );
    final table = ChartTableModel.fromDocument(snapshot.document);
    expect(table.polarRows, hasLength(6));
    expect(table.polarRows.map((row) => row.seriesName).toSet(), {
      'North',
      'South',
      'West',
    });

    final hydrated = _configuration(
      ChartDocumentHydrator.hydrateDocument(snapshot.document),
    );
    expect(hydrated.polarChartConfig, config);
    expect(hydrated.series.map((item) => item.id), ['north', 'south', 'west']);

    final generated = ChartDartSourceGenerator.generate(snapshot);
    expect(generated, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
    final source =
        (generated as ChartArtifactSuccess<ChartGeneratedSource>).value.source;
    expect(source, contains('PolarColumnCompositionMode.grouped'));
    expect(source, contains('groupInnerPadding: 0.18'));

    final invalidJson = snapshot.document.toJson();
    invalidJson['requiredCapabilities'] = snapshot.document.requiredCapabilities
        .where((capability) => capability != 'chart.polar.grouped-series.v1')
        .toList();
    final invalid = ChartDocumentHydrator.hydrateDocument(
      ChartDocument.fromJson(invalidJson),
    );
    expect(invalid, isA<ChartArtifactFailure<HydratedChartConfiguration>>());
    expect(
      (invalid as ChartArtifactFailure<HydratedChartConfiguration>)
          .error
          .message,
      contains('chart.polar.grouped-series.v1'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('round-trips diverging stacked Polar Column composition', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    const config = PolarChartConfig(
      pane: PolarPaneConfig(innerRadiusFactor: 0.12),
      composition: PolarColumnCompositionConfig(
        mode: PolarColumnCompositionMode.stacked,
      ),
    );
    final series = <PolarColumnChartSeries>[
      PolarColumnChartSeries.fromMap(
        id: 'new',
        name: 'New',
        unit: 'accounts',
        values: const {'Search': 30, 'Social': 20},
      ),
      PolarColumnChartSeries.fromMap(
        id: 'expansion',
        name: 'Expansion',
        unit: 'accounts',
        values: const {'Search': 12, 'Social': 8},
      ),
      PolarColumnChartSeries.fromMap(
        id: 'churn',
        name: 'Churn',
        unit: 'accounts',
        values: const {'Search': -15, 'Social': -24},
      ),
    ];

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: config,
          series: series,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final snapshot = _snapshot(controller.extractDocument());
    expect(
      snapshot.document.requiredCapabilities,
      containsAll({
        'chart.polar.multiple-series.v1',
        'chart.polar.stacked-series.v1',
      }),
    );
    final table = ChartTableModel.fromDocument(snapshot.document);
    expect(table.polarRows, hasLength(6));
    expect(table.polarRows.map((row) => row.valueRaw), [
      30,
      20,
      12,
      8,
      -15,
      -24,
    ]);

    final hydrated = _configuration(
      ChartDocumentHydrator.hydrateDocument(snapshot.document),
    );
    expect(hydrated.polarChartConfig, config);
    expect(hydrated.series.map((item) => item.id), [
      'new',
      'expansion',
      'churn',
    ]);

    final generated = ChartDartSourceGenerator.generate(snapshot);
    expect(generated, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
    final source =
        (generated as ChartArtifactSuccess<ChartGeneratedSource>).value.source;
    expect(source, contains('PolarColumnCompositionMode.stacked'));
    expect(source, contains('y: -24.0'));

    final invalidJson = snapshot.document.toJson();
    invalidJson['requiredCapabilities'] = snapshot.document.requiredCapabilities
        .where((capability) => capability != 'chart.polar.stacked-series.v1')
        .toList();
    final invalid = ChartDocumentHydrator.hydrateDocument(
      ChartDocument.fromJson(invalidJson),
    );
    expect(invalid, isA<ChartArtifactFailure<HydratedChartConfiguration>>());
    expect(
      (invalid as ChartArtifactFailure<HydratedChartConfiguration>)
          .error
          .message,
      contains('chart.polar.stacked-series.v1'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('round-trips Polar Column targets and pane thresholds', (
    tester,
  ) async {
    final controller = BravenChartController();
    addTearDown(controller.dispose);
    const config = PolarChartConfig(
      thresholds: <PolarThreshold>[
        PolarThreshold(
          value: 80,
          label: 'Capacity',
          color: Color(0xFFE65100),
          width: 2,
          dashPattern: <double>[5, 3],
        ),
      ],
    );
    final series = PolarColumnChartSeries.fromMap(
      id: 'actual',
      name: 'Actual',
      unit: 'orders',
      values: const {'Search': 62, 'Social': 48},
      targets: const {'Search': 70, 'Social': 50},
      targetMarkerStyle: const PolarColumnTargetMarkerStyle(
        color: Color(0xFFFFB300),
        width: 3,
        lengthFactor: 0.65,
        opacity: 0.9,
      ),
    );

    await tester.pumpWidget(
      _host(
        BravenChartPlus(
          bravenChartController: controller,
          polarChartConfig: config,
          series: <ChartSeries>[series],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final snapshot = _snapshot(controller.extractDocument());
    expect(
      snapshot.document.requiredCapabilities,
      containsAll(<String>{
        'series.polar.column.targets.v1',
        'chart.polar.thresholds.v1',
      }),
    );

    final table = ChartTableModel.fromDocument(snapshot.document);
    expect(table.hasPolarTargets, isTrue);
    expect(table.polarRows.map((row) => row.targetDisplay), ['70.00', '50.00']);
    final export = ChartTableExporter.csvForDisplayedRows(
      table,
      polarRows: table.polarRows,
    );
    expect(export.headers, [
      '#',
      'Category',
      'Series',
      'Value (orders)',
      'Target (orders)',
    ]);

    final hydrated = _configuration(
      ChartDocumentHydrator.hydrateDocument(snapshot.document),
    );
    expect(hydrated.polarChartConfig, config);
    final restored = hydrated.series.single as PolarColumnChartSeries;
    expect(restored.targetValues, series.targetValues);
    expect(restored.targetMarkerStyle, series.targetMarkerStyle);

    final generated = ChartDartSourceGenerator.generate(snapshot);
    expect(generated, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
    final source =
        (generated as ChartArtifactSuccess<ChartGeneratedSource>).value.source;
    expect(source, contains('targetValues: [70.0, 50.0]'));
    expect(source, contains('PolarColumnTargetMarkerStyle('));
    expect(source, contains("label: 'Capacity'"));
    expect(source, contains('PolarThreshold('));

    final missingTargetCapability = snapshot.document.toJson();
    missingTargetCapability['requiredCapabilities'] = snapshot
        .document
        .requiredCapabilities
        .where((capability) => capability != 'series.polar.column.targets.v1')
        .toList();
    expect(
      ChartDocumentHydrator.hydrateDocument(
        ChartDocument.fromJson(missingTargetCapability),
      ),
      isA<ChartArtifactFailure<HydratedChartConfiguration>>(),
    );

    final missingThresholdCapability = snapshot.document.toJson();
    missingThresholdCapability['requiredCapabilities'] = snapshot
        .document
        .requiredCapabilities
        .where((capability) => capability != 'chart.polar.thresholds.v1')
        .toList();
    expect(
      ChartDocumentHydrator.hydrateDocument(
        ChartDocument.fromJson(missingThresholdCapability),
      ),
      isA<ChartArtifactFailure<HydratedChartConfiguration>>(),
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 760, height: 620, child: child)),
  ),
);

ChartDocumentSnapshot _snapshot(
  ChartArtifactResult<ChartDocumentSnapshot> result,
) {
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

String _json(ChartArtifactResult<String> result) {
  expect(result, isA<ChartArtifactSuccess<String>>());
  return (result as ChartArtifactSuccess<String>).value;
}

HydratedChartConfiguration _configuration(
  ChartArtifactResult<HydratedChartConfiguration> result,
) {
  expect(result, isA<ChartArtifactSuccess<HydratedChartConfiguration>>());
  return (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;
}

Future<ChartArtifactResult<ChartArtifact>> _capture(
  WidgetTester tester,
  Future<ChartArtifactResult<ChartArtifact>> future,
) async {
  for (var index = 0; index < 6; index++) {
    await tester.pump();
  }
  return (await tester.runAsync(
    () => future.timeout(const Duration(seconds: 10)),
  ))!;
}
