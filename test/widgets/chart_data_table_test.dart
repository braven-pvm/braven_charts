import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('virtualizes long rows and exposes semantic sortable headers', (
    tester,
  ) async {
    final model = _model(
      points: [
        for (var index = 0; index < 1000; index++)
          _point(index.toDouble(), index * 10.0, label: 'Row $index'),
      ],
    );
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(_host(ChartDataTable(model: model)));

    expect(find.bySemanticsLabel('X value, not sorted'), findsOneWidget);
    expect(find.text('Row 0'), findsOneWidget);
    expect(find.text('Row 999'), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('sorts raw values and activates stable point references', (
    tester,
  ) async {
    final controller = ChartTableController();
    addTearDown(controller.dispose);
    ChartTablePointReference? activated;
    final model = _model(
      points: [
        _point(2, 220, label: 'Later'),
        _point(1, 110, label: 'Earlier'),
      ],
    );

    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          controller: controller,
          onRowActivated: (reference) => activated = reference,
        ),
      ),
    );
    await tester.tap(find.text('X value'));
    await tester.pump();

    expect(controller.sortColumnId, 'x');
    expect(controller.sortAscending, isTrue);
    expect(
      tester.getTopLeft(find.text('Earlier')).dy,
      lessThan(tester.getTopLeft(find.text('Later')).dy),
    );

    await tester.tap(find.text('Earlier'));
    expect(activated?.seriesId, 'series');
    expect(activated?.pointIndex, 1);
  });

  testWidgets('renders exact-X wide cells and meaningful missing values', (
    tester,
  ) async {
    final document = _document([
      _series('power', [_point(1, 200)]),
      _series('heart-rate', [_point(2, 140)]),
    ]);
    final model = ChartTableModel.fromDocument(
      document,
      options: const ChartTableOptions(rowLayout: ChartTableRowLayout.wide),
    );

    await tester.pumpWidget(_host(ChartDataTable(model: model)));

    expect(find.text('Power'), findsOneWidget);
    expect(find.text('Heart rate'), findsOneWidget);
    expect(find.text('No value'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('provides loading, error, empty, and warning states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ChartDataTable(isLoading: true), height: 240),
    );
    expect(find.text('Loading chart data…'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const ChartDataTable(errorMessage: 'The payload could not be read.'),
        height: 240,
      ),
    );
    expect(find.text('Chart data unavailable'), findsOneWidget);
    expect(find.text('The payload could not be read.'), findsOneWidget);

    await tester.pumpWidget(
      _host(ChartDataTable(model: _model(points: const [])), height: 240),
    );
    expect(find.text('No chart data'), findsOneWidget);

    final warningModel = _model(
      points: [_point(1, 2)],
      xFormatter: ChartFormatterDescriptor(
        id: 'com.example.missing',
      ).toDocument(),
    );
    await tester.pumpWidget(
      _host(ChartDataTable(model: warningModel), height: 320),
    );
    expect(find.textContaining('1 formatter warning'), findsOneWidget);
  });
}

Widget _host(Widget child, {double height = 420}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(width: 900, height: height, child: child),
    ),
  ),
);

ChartTableModel _model({
  required List<ChartPointDocument> points,
  JsonObjectValue? xFormatter,
}) => ChartTableModel.fromDocument(
  _document([_series('series', points)], xFormatter: xFormatter),
  options: const ChartTableOptions(rowLayout: ChartTableRowLayout.long),
);

ChartSeriesDocument _series(String id, List<ChartPointDocument> points) =>
    ChartSeriesDocument(
      type: 'line',
      id: id,
      name: switch (id) {
        'power' => 'Power',
        'heart-rate' => 'Heart rate',
        _ => 'Series',
      },
      data: InlinePointPayload(points),
      requiredCapabilities: const {'series.line'},
    );

ChartPointDocument _point(double x, double y, {String? label}) =>
    ChartPointDocument(
      x: ChartNumberDocument.fromDouble(x),
      y: ChartNumberDocument.fromDouble(y),
      label: label,
    );

ChartDocument _document(
  List<ChartSeriesDocument> series, {
  JsonObjectValue? xFormatter,
}) => ChartDocument(
  documentId: 'table-widget-test',
  revision: 1,
  series: series,
  xAxis: ChartAxisDocument(id: 'x', position: 'bottom', formatter: xFormatter),
  axes: [ChartAxisDocument(id: 'y', position: 'left')],
  theme: _success(ChartThemeDocumentCodec.encode(ChartTheme.light)).value,
  interaction: _success(
    ChartInteractionDocumentCodec.encode(const InteractionConfig()),
  ).value,
);

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) =>
    result as ChartArtifactSuccess<T>;
