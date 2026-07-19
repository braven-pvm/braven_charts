import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CSV uses raw values and RFC-style escaping', () {
    final row = ChartTableRowExport(
      rowId: 'row-1',
      headers: const ['#', 'Sample', 'Power, average', 'Note'],
      rawValues: const [1, 7, 241.44, 'Hard "finish"\ninterval'],
      displayValues: const ['1', '00:07', '241 W', 'Hard finish'],
      references: const [
        ChartTablePointReference(seriesId: 'power', pointIndex: 0),
      ],
    );

    final export = ChartTableCsvExport(headers: row.headers, rows: [row]);

    expect(row.tabSeparatedText, '1\t00:07\t241 W\tHard finish');
    expect(
      export.tabSeparatedText,
      '#\tSample\tPower, average\tNote\r\n'
      '1\t00:07\t241 W\tHard finish',
    );
    expect(
      export.csv,
      '#,Sample,"Power, average",Note\r\n'
      '1,7,241.44,"Hard ""finish""\ninterval"',
    );
  });

  test('TSV flattens tabs and line breaks inside displayed cells', () {
    final row = ChartTableRowExport(
      rowId: 'row-1',
      headers: const ['Series\tname', 'Note'],
      rawValues: const ['Power', 'First\nSecond'],
      displayValues: const ['Power\toutput', 'First\nSecond'],
      references: const [],
    );
    final export = ChartTableCsvExport(headers: row.headers, rows: [row]);

    expect(
      export.tabSeparatedText,
      'Series name\tNote\r\nPower output\tFirst Second',
    );
  });

  test('rejects row values that do not align with headers', () {
    expect(
      () => ChartTableRowExport(
        rowId: 'broken',
        headers: const ['X', 'Y'],
        rawValues: const [1],
        displayValues: const ['1', '2'],
        references: const [],
      ),
      throwsArgumentError,
    );
  });

  test('pie CSV and clipboard exports use category, value, and share', () {
    final model = _pieModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      pieRows: model.pieRows,
    );

    expect(export.headers, ['#', 'Category', 'Value (USD)', 'Share']);
    expect(
      export.tabSeparatedText,
      '#\tCategory\tValue (USD)\tShare\r\n'
      '1\tSubscriptions\t42.00\t42.00%\r\n'
      '2\tServices\t58.00\t58.00%',
    );
    expect(
      export.csv,
      '#,Category,Value (USD),Share\r\n'
      '1,Subscriptions,42.0,0.42\r\n'
      '2,Services,58.0,0.58',
    );
    expect(export.rows.first.references.single.pointIndex, 0);
  });

  test('candlestick CSV preserves Time, X, OHLC, change, and overlays', () {
    final model = _candlestickModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      candlestickRows: model.candlestickRows,
    );

    expect(export.headers, [
      '#',
      'Time',
      'Session',
      'Open',
      'High',
      'Low',
      'Close',
      'Change',
      'Change %',
      'Unit',
      'Label',
      'Volume (shares)',
    ]);
    expect(export.rows.single.rawValues, [
      1,
      '2026-07-18T09:30:00.000Z',
      1784367000000.0,
      100.0,
      112.0,
      98.0,
      110.0,
      10.0,
      10.0,
      'USD',
      'Open',
      2500.0,
    ]);
    expect(export.rows.single.references, hasLength(2));
  });

  test(
    'grouped concentric export retains every source row and stable ring identity',
    () {
      final model = _concentricGroupedModel();
      final export = ChartTableExporter.csvForDisplayedRows(
        model,
        pieRows: model.pieRows,
      );

      expect(export.headers, [
        '#',
        'Ring',
        'Series ID',
        'Category',
        'Value (USD)',
        'Share',
      ]);
      expect(export.rows, hasLength(8));
      expect(
        export.rows
            .where((row) => row.rawValues[2] == 'current')
            .map((row) => row.rawValues[3]),
        ['Core', 'Email', 'Chat', 'Other source'],
      );
      expect(
        export.rows
            .where((row) => row.rawValues[2] == 'previous')
            .map((row) => row.rawValues[3]),
        ['Core', 'Email', 'Chat', 'Other source'],
      );
      expect(export.rows[5].references, const [
        ChartPointRef(seriesId: 'previous', pointIndex: 1),
      ]);
    },
  );

  test('variable-radius Pie export includes the raw second metric', () {
    final model = _pieModel(variableRadius: true);
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      pieRows: model.pieRows,
    );

    expect(export.headers, [
      '#',
      'Category',
      'Value (USD)',
      'Total area (km²)',
      'Share',
    ]);
    expect(export.rows.first.displayValues, [
      '1',
      'Subscriptions',
      '42.00',
      '120.00',
      '42.00%',
    ]);
    expect(export.csv, contains('Subscriptions,42.0,120.0,0.42'));
  });

  test('bar export includes range, target, and uncertainty fields', () {
    final model = _barModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      wideRows: model.wideRows,
    );

    expect(export.headers, [
      '#',
      'X value',
      'Estimate (%)',
      'Estimate start (%)',
      'Estimate target (%)',
      'Estimate lower (%)',
      'Estimate upper (%)',
    ]);
    expect(export.rows.first.rawValues, [1, 0, 10, 2, 12, 8, 13]);
    expect(export.rows.first.references, [
      const ChartPointRef(seriesId: 'estimate', pointIndex: 0),
    ]);
    expect(export.csv, contains('1,0.0,10.0,2.0,12.0,8.0,13.0'));
  });

  test('Waterfall export preserves source steps and adds running totals', () {
    final model = _waterfallModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      wideRows: model.wideRows,
    );

    expect(export.headers, [
      '#',
      'X value',
      'Cash flow (k)',
      'Cash flow running total (k)',
    ]);
    expect(export.rows.last.rawValues, [7, 6, 0, 91]);
    expect(export.csv, contains('7,6.0,0.0,91.0'));
  });

  test('normalized stack export includes rendered percentage shares', () {
    final model = _normalizedStackModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      wideRows: model.wideRows,
    );

    expect(export.headers, [
      '#',
      'X value',
      'Actual (hours)',
      'Actual share (%)',
      'Planned (hours)',
      'Planned share (%)',
    ]);
    expect(export.rows.first.rawValues, [1, 0, 30, 30, 70, 70]);
    expect(export.csv, contains('1,0.0,30.0,30.0,70.0,70.0'));
  });

  test('regular stack export includes cumulative segment bounds', () {
    final model = _stackModel();
    final export = ChartTableExporter.csvForDisplayedRows(
      model,
      wideRows: model.wideRows,
    );

    expect(export.headers, [
      '#',
      'X value',
      'Actual (hours)',
      'Actual stack start (hours)',
      'Actual stack end (hours)',
      'Planned (hours)',
      'Planned stack start (hours)',
      'Planned stack end (hours)',
    ]);
    expect(export.rows.first.rawValues, [1, 0, 40, 10, 40, 80, 40, 110]);
    expect(export.csv, contains('1,0.0,40.0,10.0,40.0,80.0,40.0,110.0'));
  });
}

ChartTableModel _barModel() {
  final series =
      (ChartSeriesDocumentCodec.encode(
                const BarChartSeries(
                  id: 'estimate',
                  name: 'Estimate',
                  unit: '%',
                  barWidthPercent: 0.7,
                  baselineValue: 2,
                  points: [ChartDataPoint(x: 0, y: 10)],
                  rangeStartValues: [null],
                  targetValues: [12],
                  errorLowerValues: [8],
                  errorUpperValues: [13],
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'bar-export',
      revision: 1,
      series: [series],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}

ChartTableModel _waterfallModel() {
  final series =
      (ChartSeriesDocumentCodec.encode(
                const BarChartSeries(
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
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'waterfall-export',
      revision: 1,
      series: [series],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}

ChartTableModel _normalizedStackModel() {
  const bars = [
    BarChartSeries(
      id: 'actual',
      name: 'Actual',
      unit: 'hours',
      barWidthPercent: 0.7,
      layoutMode: BarLayoutMode.normalizedStacked,
      groupId: 'work',
      points: [ChartDataPoint(x: 0, y: 30)],
    ),
    BarChartSeries(
      id: 'planned',
      name: 'Planned',
      unit: 'hours',
      barWidthPercent: 0.7,
      layoutMode: BarLayoutMode.normalizedStacked,
      groupId: 'work',
      points: [ChartDataPoint(x: 0, y: 70)],
    ),
  ];
  final series = [
    for (final bar in bars)
      (ChartSeriesDocumentCodec.encode(bar)
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value,
  ];
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'normalized-export',
      revision: 1,
      series: series,
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}

ChartTableModel _stackModel() {
  const bars = [
    BarChartSeries(
      id: 'actual',
      name: 'Actual',
      unit: 'hours',
      barWidthPercent: 0.7,
      baselineValue: 10,
      layoutMode: BarLayoutMode.stacked,
      groupId: 'work',
      points: [ChartDataPoint(x: 0, y: 40)],
    ),
    BarChartSeries(
      id: 'planned',
      name: 'Planned',
      unit: 'hours',
      barWidthPercent: 0.7,
      baselineValue: 10,
      layoutMode: BarLayoutMode.stacked,
      groupId: 'work',
      points: [ChartDataPoint(x: 0, y: 80)],
    ),
  ];
  final series = [
    for (final bar in bars)
      (ChartSeriesDocumentCodec.encode(bar)
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value,
  ];
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'stack-export',
      revision: 1,
      series: series,
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}

ChartTableModel _pieModel({bool variableRadius = false}) {
  final series =
      (ChartSeriesDocumentCodec.encode(
                PieChartSeries.fromMap(
                  id: 'revenue',
                  unit: 'USD',
                  values: const {'Subscriptions': 42, 'Services': 58},
                  radiusValues: variableRadius
                      ? const {'Subscriptions': 120, 'Services': 80}
                      : const {},
                  sliceRadiusConfig: variableRadius
                      ? const PieSliceRadiusConfig(
                          label: 'Total area',
                          unit: 'km²',
                        )
                      : null,
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'pie-export',
      revision: 1,
      series: [series],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}

ChartTableModel _candlestickModel() {
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
    ],
  );
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'candlestick-export',
      revision: 1,
      series: [
        for (final series in [candles, volume])
          (ChartSeriesDocumentCodec.encode(series)
                  as ChartArtifactSuccess<ChartSeriesDocument>)
              .value,
      ],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom', label: 'Session'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}

ChartTableModel _concentricGroupedModel() {
  final rings = [
    DonutChartSeries.fromMap(
      id: 'current',
      name: 'Current period',
      unit: 'USD',
      values: const {'Core': 80, 'Email': 8, 'Chat': 7, 'Other source': 5},
      sliceGroupingConfig: const RadialSliceGroupingConfig(minimumShare: 0.1),
    ),
    DonutChartSeries.fromMap(
      id: 'previous',
      name: 'Previous period',
      unit: 'USD',
      values: const {'Core': 80, 'Email': 8, 'Chat': 7, 'Other source': 5},
      sliceGroupingConfig: const RadialSliceGroupingConfig(minimumShare: 0.1),
    ),
  ];
  return ChartTableModel.fromDocument(
    ChartDocument(
      documentId: 'concentric-grouped-export',
      revision: 1,
      series: [
        for (final ring in rings)
          (ChartSeriesDocumentCodec.encode(ring)
                  as ChartArtifactSuccess<ChartSeriesDocument>)
              .value,
      ],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme:
          (ChartThemeDocumentCodec.encode(ChartTheme.light)
                  as ChartArtifactSuccess<ChartThemeDocument>)
              .value,
      interaction:
          (ChartInteractionDocumentCodec.encode(const InteractionConfig())
                  as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
    ),
  );
}
