import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartTableModel', () {
    test('defaults to a transposed exact-X presentation', () {
      final yFormatter = ChartFormatterDescriptor(
        id: 'braven.number.fixed',
        arguments: {'decimals': JsonNumberValue(2)},
      ).toDocument();
      final model = ChartTableModel.fromDocument(
        _document(
          [
            _series(id: 'power', name: 'Power', points: [_point(7, 241.44)]),
            _series(
              id: 'heart-rate',
              name: 'Heart rate',
              points: [_point(7, 133.75)],
            ),
          ],
          xLabel: 'Sample',
          yFormatter: yFormatter,
        ),
      );

      expect(model.options.rowLayout, ChartTableRowLayout.wide);
      expect(model.xColumnLabel, 'Sample');
      expect(model.wideRows, hasLength(1));
      expect(model.wideRows.single.xDisplay, '7');
      expect(model.wideRows.single.cells['power']?.yDisplay, '241.44');
      expect(model.wideRows.single.cells['heart-rate']?.yDisplay, '133.75');
    });

    test('builds a lossless long form with stable point references', () {
      final document = _document([
        _series(
          id: 'power/raw',
          name: 'Power',
          unit: 'W',
          points: [
            ChartPointDocument(
              x: ChartNumberDocument.fromDouble(1),
              y: ChartNumberDocument.fromDouble(250),
              timestamp: DateTime.utc(2026, 7, 14, 6),
              label: 'Start',
              metadata: JsonObjectValue({'lap': JsonNumberValue(1)}),
            ),
            ChartPointDocument(
              x: ChartNumberDocument.fromDouble(2),
              y: ChartNumberDocument.fromDouble(double.nan),
            ),
          ],
        ),
      ]);

      final model = ChartTableModel.fromDocument(
        document,
        viewState: ChartViewState(hiddenSeriesIds: const {'power/raw'}),
        options: const ChartTableOptions(includeMetadata: true),
      );

      expect(model.documentId, 'table-test');
      expect(model.longRows, hasLength(2));
      expect(model.longRows.first.rowId, 'power%2Fraw:0');
      expect(model.longRows.first.reference.seriesId, 'power/raw');
      expect(model.longRows.first.reference.pointIndex, 0);
      expect(model.longRows.first.xRaw, 1);
      expect(model.longRows.first.yRaw, 250);
      expect(model.longRows.first.unit, 'W');
      expect(model.longRows.first.label, 'Start');
      expect(model.longRows.first.metadata?.values['lap']?.toJson(), 1);
      expect(model.longRows.first.hiddenSeries, isTrue);
      expect(model.longRows.last.isValid, isFalse);
      expect(model.longRows.last.yDisplay, 'No value');
    });

    test('applies visible, selected, specified, and viewport scopes', () {
      final document = _document([
        _series(
          id: 'power',
          points: [_point(1, 100), _point(2, 200), _point(3, 300)],
        ),
        _series(id: 'heart-rate', points: [_point(2, 140)]),
      ]);
      final viewState = ChartViewState(
        visibleBounds: const ChartBoundsDocument(
          xMin: 1.5,
          xMax: 2.5,
          yMin: 0,
          yMax: 400,
        ),
        hiddenSeriesIds: const {'heart-rate'},
        selectedSeriesId: 'heart-rate',
      );

      final visible = ChartTableModel.fromDocument(
        document,
        viewState: viewState,
        options: const ChartTableOptions(
          dataScope: ChartTableDataScope.visibleSeries,
          viewportOnly: true,
        ),
      );
      final selected = ChartTableModel.fromDocument(
        document,
        viewState: viewState,
        options: const ChartTableOptions(
          dataScope: ChartTableDataScope.selectedSeries,
        ),
      );
      final specified = ChartTableModel.fromDocument(
        document,
        options: const ChartTableOptions(
          dataScope: ChartTableDataScope.specifiedSeries,
          seriesIds: {'heart-rate'},
        ),
      );

      expect(visible.longRows.map((row) => row.rowId), ['power:1']);
      expect(selected.longRows.single.reference.seriesId, 'heart-rate');
      expect(selected.longRows.single.hiddenSeries, isTrue);
      expect(specified.longRows.single.reference.seriesId, 'heart-rate');
    });

    test('uses registered descriptors and records formatter fallbacks', () {
      final xFormatter = ChartFormatterDescriptor(
        id: 'com.example.elapsed',
        arguments: const {'suffix': JsonStringValue(' h')},
      ).toDocument();
      final yFormatter = ChartFormatterDescriptor(
        id: 'braven.number.fixed',
        arguments: {'decimals': JsonNumberValue(1)},
      ).toDocument();
      final document = _document([
        _series(
          id: 'power',
          points: [_point(1.25, 234.56)],
          inlineAxis: JsonObjectValue({
            'id': const JsonStringValue('power-axis'),
            'formatter': yFormatter,
          }),
        ),
      ], xFormatter: xFormatter);

      final formatted = ChartTableModel.fromDocument(
        document,
        options: ChartTableOptions(
          formatters: ChartFormatterRegistry(
            customFormatters: {
              'com.example.elapsed': (value, arguments) =>
                  '${value.toStringAsFixed(2)}${arguments['suffix']?.toJson()}',
            },
          ),
        ),
      );
      expect(formatted.longRows.single.xDisplay, '1.25 h');
      expect(formatted.longRows.single.yDisplay, '234.6');
      expect(formatted.warnings, isEmpty);

      final missing = ChartTableModel.fromDocument(
        _document(
          [
            _series(id: 'power', points: [_point(1, 2)]),
          ],
          xFormatter: ChartFormatterDescriptor(
            id: 'com.example.missing',
            fallbackPattern: '{value} elapsed',
          ).toDocument(),
        ),
      );
      expect(missing.longRows.single.xDisplay, '1.0 elapsed');
      expect(
        missing.warnings.single.code,
        ChartArtifactDiagnosticCodes.unregisteredFormatter,
      );

      final broken = ChartTableModel.fromDocument(
        document,
        options: ChartTableOptions(
          formatters: ChartFormatterRegistry(
            customFormatters: {
              'com.example.elapsed': (_, _) => throw StateError('broken'),
            },
          ),
        ),
      );
      expect(broken.longRows.single.xDisplay, '1.25');
      expect(
        broken.warnings.single.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
    });

    test('pivots sparse and duplicate X values only by exact occurrence', () {
      final document = _document([
        _series(id: 'a', points: [_point(1, 10), _point(1, 11), _point(3, 30)]),
        _series(id: 'b', points: [_point(1, 20), _point(2, 22), _point(1, 21)]),
      ]);

      final model = ChartTableModel.fromDocument(
        document,
        options: const ChartTableOptions(rowLayout: ChartTableRowLayout.wide),
      );

      expect(model.longRows, hasLength(6));
      expect(model.wideRows, hasLength(4));
      expect(model.wideRows[0].cells['a']?.yRaw, 10);
      expect(model.wideRows[0].cells['b']?.yRaw, 20);
      expect(model.wideRows[1].cells['a']?.yRaw, 11);
      expect(model.wideRows[1].cells['b']?.yRaw, 21);
      expect(model.wideRows[2].xRaw, 3);
      expect(model.wideRows[2].cells.keys, ['a']);
      expect(model.wideRows[3].xRaw, 2);
      expect(model.wideRows[3].cells.keys, ['b']);
      expect(
        model.wideRows
            .expand((row) => row.cells.values)
            .every((cell) => !cell.isDerived),
        isTrue,
      );
    });

    test('carries explicit and captured-theme series colors', () {
      final explicit =
          JsonValue.fromJson({'color': 0xFF2563EB}) as JsonObjectValue;
      final document = _document([
        _series(id: 'explicit', points: [_point(1, 10)], style: explicit),
        _series(id: 'theme', points: [_point(1, 20)]),
      ]);

      final model = ChartTableModel.fromDocument(document);

      expect(model.series[0].colorValue, 0xFF2563EB);
      expect(model.series[1].colorValue, isNotNull);
    });

    test('projects passive bar measures without creating extra series', () {
      const bar = BarChartSeries(
        id: 'estimate',
        name: 'Estimate',
        unit: '%',
        barWidthPercent: 0.7,
        baselineValue: 2,
        points: [ChartDataPoint(x: 0, y: 10), ChartDataPoint(x: 1, y: 20)],
        rangeStartValues: [null, 5],
        targetValues: [12, null],
        errorLowerValues: [8, null],
        errorUpperValues: [13, null],
      );
      final model = ChartTableModel.fromDocument(
        _document([_success(ChartSeriesDocumentCodec.encode(bar)).value]),
      );

      expect(model.series, hasLength(1));
      expect(model.series.single.auxiliaryFields, {
        ChartTableAuxiliaryField.rangeStart,
        ChartTableAuxiliaryField.target,
        ChartTableAuxiliaryField.errorLower,
        ChartTableAuxiliaryField.errorUpper,
      });
      expect(model.auxiliaryFields, model.series.single.auxiliaryFields);

      final first = model.longRows.first.auxiliaryValues;
      expect(first[ChartTableAuxiliaryField.rangeStart]?.raw, 2);
      expect(first[ChartTableAuxiliaryField.target]?.raw, 12);
      expect(first[ChartTableAuxiliaryField.errorLower]?.raw, 8);
      expect(first[ChartTableAuxiliaryField.errorUpper]?.raw, 13);

      final second = model.wideRows.last.cells['estimate']!.auxiliaryValues;
      expect(second[ChartTableAuxiliaryField.rangeStart]?.raw, 5);
      expect(second[ChartTableAuxiliaryField.target], isNull);
      expect(second[ChartTableAuxiliaryField.errorLower], isNull);
      expect(second[ChartTableAuxiliaryField.errorUpper], isNull);
    });

    test('projects Waterfall source steps beside their running totals', () {
      const bar = BarChartSeries(
        id: 'cash-flow',
        name: 'Cash flow',
        unit: 'k',
        barWidthPercent: 0.62,
        layoutMode: BarLayoutMode.waterfall,
        points: [
          ChartDataPoint(x: 0, y: 82),
          ChartDataPoint(x: 1, y: 28),
          ChartDataPoint(x: 2, y: 16),
          ChartDataPoint(x: 3, y: -18),
          ChartDataPoint(x: 4, y: -24),
          ChartDataPoint(x: 5, y: 7),
          ChartDataPoint(x: 6, y: 0),
        ],
        waterfallTotalIndices: {6},
      );
      final model = ChartTableModel.fromDocument(
        _document([_success(ChartSeriesDocumentCodec.encode(bar)).value]),
      );

      expect(model.series.single.auxiliaryFields, {
        ChartTableAuxiliaryField.waterfallCumulative,
      });
      expect(model.longRows.map((row) => row.yRaw), [
        82,
        28,
        16,
        -18,
        -24,
        7,
        0,
      ]);
      expect(
        model.longRows.map(
          (row) => row
              .auxiliaryValues[ChartTableAuxiliaryField.waterfallCumulative]!
              .raw,
        ),
        [82, 110, 126, 108, 84, 91, 91],
      );
      final total = model.wideRows.last.cells['cash-flow']!;
      expect(total.yRaw, 0);
      expect(
        total
            .auxiliaryValues[ChartTableAuxiliaryField.waterfallCumulative]
            ?.raw,
        91,
      );
    });

    test('projects normalized stack shares beside raw source values', () {
      const actual = BarChartSeries(
        id: 'actual',
        name: 'Actual',
        unit: 'hours',
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.normalizedStacked,
        groupId: 'work',
        points: [ChartDataPoint(x: 0, y: 30), ChartDataPoint(x: 1, y: -20)],
      );
      const planned = BarChartSeries(
        id: 'planned',
        name: 'Planned',
        unit: 'hours',
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.normalizedStacked,
        groupId: 'work',
        points: [ChartDataPoint(x: 0, y: 70), ChartDataPoint(x: 1, y: -30)],
      );
      final model = ChartTableModel.fromDocument(
        _document([
          _success(ChartSeriesDocumentCodec.encode(actual)).value,
          _success(ChartSeriesDocumentCodec.encode(planned)).value,
        ]),
      );

      expect(model.series.first.auxiliaryFields, {
        ChartTableAuxiliaryField.normalizedShare,
      });
      expect(model.longRows.map((row) => row.yRaw), [30, -20, 70, -30]);
      expect(
        model.longRows.map(
          (row) => row
              .auxiliaryValues[ChartTableAuxiliaryField.normalizedShare]!
              .raw,
        ),
        [30, -40, 70, -60],
      );
      expect(
        model
            .wideRows
            .first
            .cells['planned']!
            .auxiliaryValues[ChartTableAuxiliaryField.normalizedShare]
            ?.display,
        '70',
      );
    });

    test('projects centered diverging bounds beside raw response shares', () {
      const disagree = BarChartSeries(
        id: 'disagree',
        name: 'Disagree',
        unit: '%',
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.divergingStacked,
        groupId: 'responses',
        divergingRole: BarDivergingRole.negative,
        points: [ChartDataPoint(x: 0, y: 30)],
      );
      const neutral = BarChartSeries(
        id: 'neutral',
        name: 'Neutral',
        unit: '%',
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.divergingStacked,
        groupId: 'responses',
        divergingRole: BarDivergingRole.neutral,
        points: [ChartDataPoint(x: 0, y: 20)],
      );
      const agree = BarChartSeries(
        id: 'agree',
        name: 'Agree',
        unit: '%',
        barWidthPercent: 0.7,
        layoutMode: BarLayoutMode.divergingStacked,
        groupId: 'responses',
        points: [ChartDataPoint(x: 0, y: 50)],
      );
      final model = ChartTableModel.fromDocument(
        _document([
          _success(ChartSeriesDocumentCodec.encode(disagree)).value,
          _success(ChartSeriesDocumentCodec.encode(neutral)).value,
          _success(ChartSeriesDocumentCodec.encode(agree)).value,
        ]),
      );

      expect(model.series.first.auxiliaryFields, {
        ChartTableAuxiliaryField.stackStart,
        ChartTableAuxiliaryField.stackEnd,
        ChartTableAuxiliaryField.normalizedShare,
      });
      expect(
        model.longRows.map(
          (row) =>
              row.auxiliaryValues[ChartTableAuxiliaryField.stackStart]!.raw,
        ),
        [-10, -10, 10],
      );
      expect(
        model.longRows.map(
          (row) => row.auxiliaryValues[ChartTableAuxiliaryField.stackEnd]!.raw,
        ),
        [-40, 10, 60],
      );
      expect(
        model.longRows.map(
          (row) => row
              .auxiliaryValues[ChartTableAuxiliaryField.normalizedShare]!
              .raw,
        ),
        [30, 20, 50],
      );
    });

    test('projects signed stack bounds beside raw source values', () {
      const first = BarChartSeries(
        id: 'first',
        name: 'First',
        unit: 'hours',
        barWidthPercent: 0.7,
        baselineValue: 10,
        layoutMode: BarLayoutMode.stacked,
        groupId: 'work',
        points: [ChartDataPoint(x: 0, y: 40), ChartDataPoint(x: 1, y: -10)],
      );
      const second = BarChartSeries(
        id: 'second',
        name: 'Second',
        unit: 'hours',
        barWidthPercent: 0.7,
        baselineValue: 10,
        layoutMode: BarLayoutMode.stacked,
        groupId: 'work',
        points: [ChartDataPoint(x: 0, y: 80), ChartDataPoint(x: 1, y: -20)],
      );
      final model = ChartTableModel.fromDocument(
        _document([
          _success(ChartSeriesDocumentCodec.encode(first)).value,
          _success(ChartSeriesDocumentCodec.encode(second)).value,
        ]),
      );

      expect(model.series.first.auxiliaryFields, {
        ChartTableAuxiliaryField.stackStart,
        ChartTableAuxiliaryField.stackEnd,
      });
      expect(model.longRows.map((row) => row.yRaw), [40, -10, 80, -20]);
      expect(
        model.longRows.map(
          (row) =>
              row.auxiliaryValues[ChartTableAuxiliaryField.stackStart]!.raw,
        ),
        [10, 10, 40, -10],
      );
      expect(
        model.longRows.map(
          (row) => row.auxiliaryValues[ChartTableAuxiliaryField.stackEnd]!.raw,
        ),
        [40, -10, 110, -40],
      );
    });

    test(
      'projects Polar Column as category, series, and value without share',
      () {
        final polar = PolarColumnChartSeries.fromMap(
          id: 'demand',
          name: 'Demand',
          unit: 'orders',
          values: const {'North': 42, 'East': 68, 'South': -31},
          columnColors: const {'East': Color(0xFF00A878)},
        );
        final model = ChartTableModel.fromDocument(
          _document([_success(ChartSeriesDocumentCodec.encode(polar)).value]),
        );

        expect(model.projectionKind, ChartTableProjectionKind.polar);
        expect(model.xColumnLabel, 'Category');
        expect(model.polarRows, hasLength(3));
        expect(model.longRows, hasLength(3));
        expect(model.polarRows.first.category, 'North');
        expect(model.polarRows.first.seriesName, 'Demand');
        expect(model.polarRows.first.valueDisplay, '42.00');
        expect(model.polarRows.first.unit, 'orders');
        expect(model.polarRows[1].colorValue, 0xFF00A878);
        expect(model.polarRows.last.valueRaw, -31);
        expect(model.polarRows.last.valueDisplay, '-31.00');
        expect(model.polarRows.last.isValid, isTrue);
        expect(model.longRows.first.xDisplay, 'North');
        expect(ChartTableExporter.headers(model), [
          '#',
          'Category',
          'Series',
          'Value (orders)',
        ]);
        expect(ChartTableExporter.headers(model), isNot(contains('Share')));
        expect(
          ChartTableExporter.csvForDisplayedRows(
            model,
            polarRows: model.polarRows,
          ).csv,
          contains('-31.0'),
        );
      },
    );

    test('projects every layered Polar Column series with stable identity', () {
      final capacity = PolarColumnChartSeries.fromMap(
        id: 'capacity',
        name: 'Capacity',
        unit: 'orders',
        values: const {'North': 90, 'South': 80},
      );
      final observed = PolarColumnChartSeries.fromMap(
        id: 'observed',
        name: 'Observed',
        unit: 'orders',
        values: const {'North': 62, 'South': 74},
      );
      final model = ChartTableModel.fromDocument(
        _document([
          _success(ChartSeriesDocumentCodec.encode(capacity)).value,
          _success(ChartSeriesDocumentCodec.encode(observed)).value,
        ]),
      );

      expect(model.projectionKind, ChartTableProjectionKind.polar);
      expect(model.polarRows, hasLength(4));
      expect(model.polarRows.map((row) => row.seriesName), [
        'Capacity',
        'Capacity',
        'Observed',
        'Observed',
      ]);
      expect(model.polarRows.map((row) => row.reference), const [
        ChartPointRef(seriesId: 'capacity', pointIndex: 0),
        ChartPointRef(seriesId: 'capacity', pointIndex: 1),
        ChartPointRef(seriesId: 'observed', pointIndex: 0),
        ChartPointRef(seriesId: 'observed', pointIndex: 1),
      ]);
      expect(
        ChartTableExporter.csvForDisplayedRows(
          model,
          polarRows: model.polarRows,
        ).csv,
        allOf(contains('Capacity'), contains('Observed')),
      );
    });

    test('projects pie documents as category, value, and share rows', () {
      final pie = PieChartSeries(
        id: 'revenue',
        name: 'Revenue',
        unit: 'USD',
        points: const [
          ChartDataPoint(
            x: 0,
            y: 42,
            label: 'Subscriptions',
            pointStyle: PointStyle(color: Color(0xFF6750A4)),
          ),
          ChartDataPoint(x: 1, y: 31, label: 'Services'),
          ChartDataPoint(x: 2, y: 27, label: 'Hardware'),
          ChartDataPoint(x: 3, y: 0, label: 'Deferred'),
        ],
      );
      final model = ChartTableModel.fromDocument(
        _document([_success(ChartSeriesDocumentCodec.encode(pie)).value]),
      );

      expect(model.options.rowLayout, ChartTableRowLayout.wide);
      expect(model.projectionKind, ChartTableProjectionKind.pie);
      expect(model.xColumnLabel, 'Category');
      expect(model.pieRows, hasLength(4));
      expect(model.longRows, hasLength(4));
      expect(model.pieRows.first.category, 'Subscriptions');
      expect(model.pieRows.first.valueDisplay, '42.00');
      expect(model.pieRows.first.shareRaw, 0.42);
      expect(model.pieRows.first.shareDisplay, '42.00%');
      expect(model.pieRows.first.unit, 'USD');
      expect(model.pieRows.first.colorValue, 0xFF6750A4);
      expect(model.pieRows.last.shareDisplay, '0.00%');
      expect(model.pieRows.last.colorValue, isNull);
      expect(
        model.pieRows.first.reference,
        const ChartPointRef(seriesId: 'revenue', pointIndex: 0),
      );
    });

    test('projects the optional Pie radius metric as a native column', () {
      final pie = PieChartSeries.fromMap(
        id: 'countries',
        unit: 'people/km²',
        values: const {'Germany': 233, 'Spain': 96},
        radiusValues: const {'Germany': 357022, 'Spain': 505990},
        sliceRadiusConfig: const PieSliceRadiusConfig(
          label: 'Total area',
          unit: 'km²',
        ),
      );
      final model = ChartTableModel.fromDocument(
        _document([_success(ChartSeriesDocumentCodec.encode(pie)).value]),
      );

      expect(model.hasPieRadiusValues, isTrue);
      expect(model.pieRadiusColumnLabel, 'Total area (km²)');
      expect(model.pieRows.first.radiusRaw, 357022);
      expect(model.pieRows.first.radiusDisplay, '357022.00');
      expect(model.pieRows.first.radiusLabel, 'Total area');
      expect(model.pieRows.first.radiusUnit, 'km²');
    });

    test('projects Donut documents through the radial category table', () {
      final donut = DonutChartSeries.fromMap(
        id: 'donut',
        unit: 'vehicles',
        values: const {'EV': 24, 'Hybrid': 13, 'Diesel': 63},
      );
      final model = ChartTableModel.fromDocument(
        _document([_success(ChartSeriesDocumentCodec.encode(donut)).value]),
      );

      expect(model.projectionKind, ChartTableProjectionKind.pie);
      expect(model.xColumnLabel, 'Category');
      expect(model.pieRows.map((row) => row.category), [
        'EV',
        'Hybrid',
        'Diesel',
      ]);
      expect(model.pieRows.first.shareDisplay, '24.00%');
      expect(
        model.pieRows.first.reference,
        const ChartPointRef(seriesId: 'donut', pointIndex: 0),
      );
    });

    test(
      'projects multiple Donut rings with independent shares and identity',
      () {
        final current = DonutChartSeries.fromMap(
          id: 'current',
          name: 'Current period',
          unit: 'USD',
          values: const {'Subscriptions': 60, 'Services': 40},
        );
        final previous = DonutChartSeries.fromMap(
          id: 'previous',
          name: 'Previous period',
          unit: 'USD',
          values: const {'Subscriptions': 50, 'Services': 150},
        );
        final model = ChartTableModel.fromDocument(
          _document([
            _success(ChartSeriesDocumentCodec.encode(current)).value,
            _success(ChartSeriesDocumentCodec.encode(previous)).value,
          ]),
        );

        expect(model.projectionKind, ChartTableProjectionKind.pie);
        expect(model.hasMultipleRadialSeries, isTrue);
        expect(model.pieRows, hasLength(4));
        expect(model.pieRows.map((row) => row.ringIndex), [0, 0, 1, 1]);
        expect(model.pieRows.map((row) => row.seriesId), [
          'current',
          'current',
          'previous',
          'previous',
        ]);
        expect(model.pieRows.map((row) => row.seriesName), [
          'Current period',
          'Current period',
          'Previous period',
          'Previous period',
        ]);
        expect(model.pieRows.map((row) => row.shareDisplay), [
          '60.00%',
          '40.00%',
          '25.00%',
          '75.00%',
        ]);
      },
    );

    test('keeps all-zero pie categories visible with zero shares', () {
      final pie = PieChartSeries.fromMap(
        id: 'zero',
        values: const {'A': 0, 'B': 0},
      );
      final model = ChartTableModel.fromDocument(
        _document([_success(ChartSeriesDocumentCodec.encode(pie)).value]),
      );

      expect(model.projectionKind, ChartTableProjectionKind.pie);
      expect(model.pieRows.map((row) => row.shareDisplay), ['0.00%', '0.00%']);
      expect(model.pieRows.every((row) => row.isValid), isTrue);
    });

    test('projects lossless OHLC rows with exact-X Cartesian overlays', () {
      final time = DateTime.utc(2026, 7, 18, 9, 30);
      final candles = CandlestickChartSeries(
        id: 'price',
        name: 'Price',
        unit: 'USD',
        points: [
          CandlestickDataPoint.atTime(
            timestamp: time,
            open: 100,
            high: 112,
            low: 98,
            close: 110,
            label: 'Open',
          ),
        ],
      );
      final volume = LineChartSeries(
        id: 'volume',
        name: 'Volume',
        unit: 'shares',
        points: [
          ChartDataPoint(x: time.millisecondsSinceEpoch.toDouble(), y: 2500),
          ChartDataPoint(
            x: (time.millisecondsSinceEpoch + 1).toDouble(),
            y: 9999,
          ),
        ],
      );
      final model = ChartTableModel.fromDocument(
        _document([
          _success(ChartSeriesDocumentCodec.encode(candles)).value,
          _success(ChartSeriesDocumentCodec.encode(volume)).value,
        ], xLabel: 'Session'),
      );

      expect(model.projectionKind, ChartTableProjectionKind.candlestick);
      expect(model.candlestickRows, hasLength(1));
      final row = model.candlestickRows.single;
      expect(row.timestamp, time);
      expect(
        [row.openRaw, row.highRaw, row.lowRaw, row.closeRaw],
        [100, 112, 98, 110],
      );
      expect(row.changeRaw, 10);
      expect(row.changePercentDisplay, '10.00%');
      expect(row.overlayCells.keys, ['volume']);
      expect(row.overlayCells['volume']?.yRaw, 2500);
      expect(row.overlayCells['volume']?.reference.pointIndex, 0);
    });

    test('rejects mixed pie and Cartesian table projections', () {
      final pie = PieChartSeries.fromMap(id: 'pie', values: const {'A': 1});
      final document = _document([
        _success(ChartSeriesDocumentCodec.encode(pie)).value,
        _series(id: 'line', points: [_point(0, 1)]),
      ]);

      expect(
        () => ChartTableModel.fromDocument(document),
        throwsUnsupportedError,
      );
    });
  });
}

ChartSeriesDocument _series({
  required String id,
  String? name,
  String? unit,
  required List<ChartPointDocument> points,
  JsonObjectValue? inlineAxis,
  JsonObjectValue? style,
}) => ChartSeriesDocument(
  type: 'line',
  id: id,
  name: name,
  unit: unit,
  inlineAxis: inlineAxis,
  style: style,
  data: InlinePointPayload(points),
  requiredCapabilities: const {'series.line'},
);

ChartPointDocument _point(double x, double y) => ChartPointDocument(
  x: ChartNumberDocument.fromDouble(x),
  y: ChartNumberDocument.fromDouble(y),
);

ChartDocument _document(
  List<ChartSeriesDocument> series, {
  JsonObjectValue? xFormatter,
  JsonObjectValue? yFormatter,
  String? xLabel,
}) => ChartDocument(
  documentId: 'table-test',
  revision: 3,
  series: series,
  xAxis: ChartAxisDocument(
    id: 'x',
    position: 'bottom',
    label: xLabel,
    formatter: xFormatter,
  ),
  axes: [
    ChartAxisDocument(
      id: 'y',
      position: 'left',
      unit: 'units',
      formatter: yFormatter,
    ),
  ],
  theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
  interaction: _success(
    ChartInteractionDocumentCodec.encode(const InteractionConfig()),
  ).value,
);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
