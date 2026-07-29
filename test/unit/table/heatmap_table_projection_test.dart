import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Heatmap table projection', () {
    late ChartDocument document;

    setUp(() {
      final series = HeatmapChartSeries(
        id: 'availability',
        name: 'Availability',
        unit: '%',
        points: [
          HeatmapDataPoint(x: 0, y: 0, value: 99, pointKey: 'mon-am'),
          HeatmapDataPoint.missing(x: 1, y: 0, pointKey: 'mon-pm'),
          HeatmapDataPoint(x: 0, y: 1, value: 96, pointKey: 'tue-am'),
          // Tuesday PM is intentionally absent rather than explicitly missing.
        ],
        colorScale: HeatmapColorScale.sequential(
          colors: const [Colors.red, Colors.green],
          label: 'Availability',
          unit: '%',
        ),
      );
      final encoded =
          ChartSeriesDocumentCodec.encode(series)
              as ChartArtifactSuccess<ChartSeriesDocument>;
      document = ChartDocument(
        documentId: 'heatmap-table',
        revision: 1,
        series: [encoded.value],
        xAxis: ChartAxisDocument(
          id: 'x',
          position: 'bottom',
          label: 'Period',
          categories: const ['AM', 'PM'],
        ),
        axes: [
          ChartAxisDocument(
            id: 'y',
            position: 'left',
            label: 'Day',
            categories: const ['Monday', 'Tuesday'],
          ),
        ],
        theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
        interaction: _success(
          ChartInteractionDocumentCodec.encode(const InteractionConfig()),
        ).value,
      );
    });

    test('long form preserves X, Y, value, identity, and missing state', () {
      final model = ChartTableModel.fromDocument(
        document,
        options: const ChartTableOptions(rowLayout: ChartTableRowLayout.long),
      );

      expect(model.longRows, hasLength(3));
      expect(model.longRows.first.xDisplay, 'AM');
      expect(model.longRows.first.yRaw, 99);
      expect(model.longRows.first.yDisplay, '99.00');
      expect(
        model
            .longRows
            .first
            .auxiliaryValues[ChartTableAuxiliaryField.heatmapRowCoordinate]
            ?.display,
        'Monday',
      );
      expect(
        model.longRows.first.reference,
        const ChartPointRef(seriesId: 'availability', pointIndex: 0),
      );
      expect(model.longRows[1].yDisplay, 'Missing');
      expect(model.longRows[1].isValid, isFalse);
      expect(model.longRows[1].yRaw.isNaN, isTrue);
    });

    test(
      'default wide form is a matrix and distinguishes missing from absent',
      () {
        final model = ChartTableModel.fromDocument(document);

        expect(model.xColumnLabel, r'Y \ X');
        expect(model.series.map((column) => column.seriesName), ['AM', 'PM']);
        expect(model.wideRows, hasLength(2));
        expect(model.wideRows.first.xDisplay, 'Monday');
        expect(model.wideRows.first.cells.values.first.yDisplay, '99.00');
        expect(model.wideRows.first.cells.values.last.yDisplay, 'Missing');
        expect(model.wideRows.last.xDisplay, 'Tuesday');
        expect(model.wideRows.last.cells, hasLength(1));

        final csv = ChartTableExporter.csvForDisplayedRows(
          model,
          wideRows: model.wideRows,
        );
        expect(csv.rows.first.displayValues, contains('Missing'));
        expect(csv.rows.last.displayValues, contains('No value'));
      },
    );
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
