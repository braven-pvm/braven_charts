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

    test('line contours use a lossless long projection beside the matrix', () {
      final contour = LineChartSeries(
        id: 'availability-contour',
        name: '95% contour',
        points: const [
          ChartDataPoint(
            x: 0.25,
            y: 0.5,
            metadata: {
              'densityContourPathId': 'contour-0-path-0',
              'densityContourLevel': 0.95,
            },
          ),
          ChartDataPoint(
            x: 0.75,
            y: 1.5,
            metadata: {
              'densityContourPathId': 'contour-0-path-0',
              'densityContourLevel': 0.95,
            },
          ),
        ],
      );
      final encoded =
          ChartSeriesDocumentCodec.encode(contour)
              as ChartArtifactSuccess<ChartSeriesDocument>;
      final composed = ChartDocument(
        documentId: document.documentId,
        revision: document.revision,
        series: [...document.series, encoded.value],
        xAxis: document.xAxis,
        axes: document.axes,
        theme: document.theme,
        interaction: document.interaction,
      );

      final model = ChartTableModel.fromDocument(
        composed,
        options: const ChartTableOptions(includeMetadata: true),
      );

      expect(model.projectionKind, ChartTableProjectionKind.cartesianLong);
      expect(model.series.map((column) => column.seriesId), [
        'availability',
        'availability-contour',
      ]);
      expect(model.longRows, hasLength(5));
      expect(model.wideRows, isEmpty);
      expect(
        model.longRows.last.metadata?.values['densityContourPathId']?.toJson(),
        'contour-0-path-0',
      );
    });

    test(
      'multiple Heatmap colour axes retain series identity in long form',
      () {
        final errorRate = HeatmapChartSeries(
          id: 'error-rate',
          name: 'Error rate',
          unit: '%',
          points: [
            HeatmapDataPoint(x: 0, y: 1, value: 1.2, pointKey: 'errors-00'),
            HeatmapDataPoint(x: 1, y: 1, value: 2.4, pointKey: 'errors-04'),
          ],
          colorScale: HeatmapColorScale.sequential(
            colors: const [Colors.white, Colors.orange],
            minimumValue: 0,
            maximumValue: 3,
            label: 'Error rate',
            unit: '%',
          ),
        );
        final latency = HeatmapChartSeries(
          id: 'latency',
          name: 'Latency',
          unit: 'ms',
          points: [
            HeatmapDataPoint(x: 0, y: 0, value: 42, pointKey: 'latency-00'),
            HeatmapDataPoint(x: 1, y: 0, value: 88, pointKey: 'latency-04'),
          ],
          colorScale: HeatmapColorScale.sequential(
            colors: const [Colors.white, Colors.blue],
            minimumValue: 35,
            maximumValue: 100,
            label: 'Latency',
            unit: 'ms',
          ),
        );
        final encoded = [
          for (final series in [errorRate, latency])
            (ChartSeriesDocumentCodec.encode(series)
                    as ChartArtifactSuccess<ChartSeriesDocument>)
                .value,
        ];
        final composed = ChartDocument(
          documentId: 'multiple-heatmap-table',
          revision: 1,
          series: encoded,
          xAxis: document.xAxis,
          axes: document.axes,
          theme: document.theme,
          interaction: document.interaction,
        );

        final model = ChartTableModel.fromDocument(composed);

        expect(model.projectionKind, ChartTableProjectionKind.cartesianLong);
        expect(model.series.map((column) => column.seriesId), [
          'error-rate',
          'latency',
        ]);
        expect(model.series.map((column) => column.unit), ['%', 'ms']);
        expect(model.longRows, hasLength(4));
        expect(model.longRows.map((row) => row.reference.seriesId).toSet(), {
          'error-rate',
          'latency',
        });
        expect(model.longRows.first.yDisplay, '1.20');
        expect(model.longRows.last.yDisplay, '88.00');
      },
    );

    test(
      'explicit cell rectangles default to long form and expose their bounds',
      () {
        final irregular = HeatmapChartSeries(
          id: 'schedule',
          name: 'Schedule',
          unit: '%',
          points: [
            HeatmapDataPoint(
              x: 2,
              y: 1,
              value: 72,
              pointKey: 'build',
              bounds: HeatmapCellBounds(
                xMinimum: 0,
                xMaximum: 4,
                yMinimum: 0.5,
                yMaximum: 1.5,
              ),
            ),
            HeatmapDataPoint.missing(
              x: 5,
              y: 2,
              pointKey: 'gap',
              bounds: HeatmapCellBounds(
                xMinimum: 4,
                xMaximum: 6,
                yMinimum: 1.5,
                yMaximum: 2.5,
              ),
            ),
          ],
          colorScale: HeatmapColorScale.sequential(
            colors: const [Colors.blue, Colors.green],
          ),
        );
        final encoded =
            ChartSeriesDocumentCodec.encode(irregular)
                as ChartArtifactSuccess<ChartSeriesDocument>;
        final irregularDocument = ChartDocument(
          documentId: 'irregular-heatmap-table',
          revision: 1,
          series: [encoded.value],
          xAxis: document.xAxis,
          axes: document.axes,
          theme: document.theme,
          interaction: document.interaction,
        );

        final model = ChartTableModel.fromDocument(irregularDocument);

        expect(model.projectionKind, ChartTableProjectionKind.cartesianLong);
        expect(model.wideRows, isEmpty);
        expect(model.longRows, hasLength(2));
        expect(
          model.series.single.auxiliaryFields,
          containsAll(const {
            ChartTableAuxiliaryField.heatmapRowCoordinate,
            ChartTableAuxiliaryField.heatmapXMinimum,
            ChartTableAuxiliaryField.heatmapXMaximum,
            ChartTableAuxiliaryField.heatmapYMinimum,
            ChartTableAuxiliaryField.heatmapYMaximum,
          }),
        );
        final bounds = model.longRows.first.auxiliaryValues;
        expect(bounds[ChartTableAuxiliaryField.heatmapXMinimum]?.raw, 0);
        expect(bounds[ChartTableAuxiliaryField.heatmapXMaximum]?.raw, 4);
        expect(bounds[ChartTableAuxiliaryField.heatmapYMinimum]?.raw, 0.5);
        expect(bounds[ChartTableAuxiliaryField.heatmapYMaximum]?.raw, 1.5);
        expect(model.longRows.last.yDisplay, 'Missing');
        expect(
          model
              .longRows
              .last
              .auxiliaryValues[ChartTableAuxiliaryField.heatmapXMinimum]
              ?.raw,
          4,
        );
      },
    );
  });
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
