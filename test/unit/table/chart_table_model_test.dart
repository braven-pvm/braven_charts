import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartTableModel', () {
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
  });
}

ChartSeriesDocument _series({
  required String id,
  String? name,
  String? unit,
  required List<ChartPointDocument> points,
  JsonObjectValue? inlineAxis,
}) => ChartSeriesDocument(
  type: 'line',
  id: id,
  name: name,
  unit: unit,
  inlineAxis: inlineAxis,
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
}) => ChartDocument(
  documentId: 'table-test',
  revision: 3,
  series: series,
  xAxis: ChartAxisDocument(id: 'x', position: 'bottom', formatter: xFormatter),
  axes: [ChartAxisDocument(id: 'y', position: 'left', unit: 'units')],
  theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
  interaction: _success(
    ChartInteractionDocumentCodec.encode(const InteractionConfig()),
  ).value,
);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
