import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('chart-table-header-row-actions')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('chart-table-header-index')))
            .dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byTooltip('Copy Series row').first).dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('chart-table-row-index-0')))
            .dx,
      ),
    );
    semantics.dispose();
  });

  testWidgets('sorts raw values and activates stable point references', (
    tester,
  ) async {
    final controller = ChartTableController();
    addTearDown(controller.dispose);
    List<ChartPointRef>? activated;
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
    expect(activated?.single.seriesId, 'series');
    expect(activated?.single.pointIndex, 1);
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

  testWidgets('renders and sorts passive bar measure columns', (tester) async {
    final controller = ChartTableController();
    addTearDown(controller.dispose);
    final model = _barTableModel();

    await tester.pumpWidget(
      _host(ChartDataTable(model: model, controller: controller), width: 1400),
    );

    expect(find.text('Estimate (%)'), findsOneWidget);
    expect(find.text('Estimate start (%)'), findsOneWidget);
    expect(find.text('Estimate target (%)'), findsOneWidget);
    expect(find.text('Estimate lower (%)'), findsOneWidget);
    expect(find.text('Estimate upper (%)'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);

    await tester.tap(find.text('Estimate target (%)'));
    await tester.pump();

    expect(controller.sortColumnId, 'series:estimate:aux:target');
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide row activation reports every populated point reference', (
    tester,
  ) async {
    List<ChartPointRef>? activated;
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(7, 241.44)]),
        _series('heart-rate', [_point(7, 133.75)]),
      ]),
    );

    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          onRowActivated: (points) => activated = points,
        ),
      ),
    );
    await tester.tap(find.byKey(ValueKey(model.wideRows.single.rowId)));

    expect(activated, const [
      ChartPointRef(seriesId: 'power', pointIndex: 0),
      ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    ]);
  });

  testWidgets('reports Ctrl activation details without breaking legacy taps', (
    tester,
  ) async {
    final activations = <ChartTableRowActivationDetails>[];
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(7, 241.44)]),
        _series('heart-rate', [_point(7, 133.75)]),
      ]),
    );
    final row = find.byKey(ValueKey(model.wideRows.single.rowId));

    await tester.pumpWidget(
      _host(ChartDataTable(model: model, onRowActivation: activations.add)),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.tap(row);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(activations.single.additive, isTrue);
    expect(activations.single.points, const [
      ChartPointRef(seriesId: 'power', pointIndex: 0),
      ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    ]);

    final detector = tester.widget<FocusableActionDetector>(
      find.descendant(of: row, matching: find.byType(FocusableActionDetector)),
    );
    detector.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(activations, hasLength(2));
    expect(activations.last.additive, isTrue);
  });

  testWidgets('mirrors complete point selection into a themed table row', (
    tester,
  ) async {
    const selectedColor = Color(0xFFE0E7FF);
    final points = <ChartPointRef>{
      const ChartPointRef(seriesId: 'power', pointIndex: 0),
      const ChartPointRef(seriesId: 'heart-rate', pointIndex: 0),
    };
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(7, 241.44)]),
        _series('heart-rate', [_point(7, 133.75)]),
      ]),
    );
    final row = find.byKey(ValueKey(model.wideRows.single.rowId));

    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          selectedPointRefs: points,
          theme: const ChartDataTableTheme(selectedRowColor: selectedColor),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.descendant(of: row, matching: find.byType(Container)).first,
    );
    expect((surface.decoration! as BoxDecoration).color, selectedColor);
    final selectionBorder =
        (surface.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(selectionBorder.left.width, 4);
    final semantics = tester.widget<Semantics>(
      find.descendant(of: row, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.selected, isTrue);
  });

  testWidgets('reveals a newly selected point without taking over scrolling', (
    tester,
  ) async {
    final model = _model(
      points: [
        for (var index = 0; index < 1000; index++)
          _point(index.toDouble(), index.toDouble(), label: 'Row $index'),
      ],
    );
    Set<ChartPointRef> selected = const {};
    late StateSetter update;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return ChartDataTable(model: model, selectedPointRefs: selected);
          },
        ),
      ),
    );
    final target = find.byKey(ValueKey(model.longRows.last.rowId));
    expect(target, findsNothing);

    update(() {
      selected = {const ChartPointRef(seriesId: 'series', pointIndex: 999)};
    });
    await tester.pumpAndSettle();

    expect(target, findsOneWidget);
    final list = tester.widget<ListView>(find.byType(ListView));
    expect(list.controller!.offset, greaterThan(0));

    list.controller!.jumpTo(0);
    await tester.pump();
    update(() {});
    await tester.pumpAndSettle();

    expect(list.controller!.offset, 0);
    expect(target, findsNothing);
  });

  testWidgets(
    'mirrors and reveals chart focus without claiming keyboard focus',
    (tester) async {
      const focusedColor = Color(0xFFDBEAFE);
      final model = _model(
        points: [
          for (var index = 0; index < 1000; index++)
            _point(index.toDouble(), index.toDouble(), label: 'Row $index'),
        ],
      );
      Set<ChartPointRef> focused = const {};
      late StateSetter update;

      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return ChartDataTable(
                model: model,
                focusedPointRefs: focused,
                theme: const ChartDataTableTheme(focusedRowColor: focusedColor),
              );
            },
          ),
        ),
      );
      final target = find.byKey(ValueKey(model.longRows.last.rowId));
      expect(target, findsNothing);

      update(() {
        focused = {const ChartPointRef(seriesId: 'series', pointIndex: 999)};
      });
      await tester.pumpAndSettle();

      expect(target, findsOneWidget);
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.controller!.offset, greaterThan(0));
      final surface = tester.widget<Container>(
        find.descendant(of: target, matching: find.byType(Container)).first,
      );
      expect((surface.decoration! as BoxDecoration).color, focusedColor);
      final semantics = tester.widget<Semantics>(
        find.descendant(of: target, matching: find.byType(Semantics)).first,
      );
      expect(semantics.properties.focused, isFalse);
      expect(semantics.properties.selected, isFalse);

      list.controller!.jumpTo(0);
      await tester.pump();
      update(() {});
      await tester.pumpAndSettle();

      expect(list.controller!.offset, 0);
      expect(target, findsNothing);
    },
  );

  testWidgets(
    'uses compact themed rows, aligned numbers, indexes, and series colors',
    (tester) async {
      const powerColor = Color(0xFF2563EB);
      final document = _document([
        _series('power', [_point(7, 241.44)], color: powerColor),
        _series('heart-rate', [
          _point(7, 133.75),
        ], color: const Color(0xFFDC2626)),
      ]);
      final model = ChartTableModel.fromDocument(document);
      final rowKey = ValueKey(model.wideRows.single.rowId);
      const tableTheme = ChartDataTableTheme(
        rowHeight: 32,
        cellTextStyle: TextStyle(fontSize: 10, color: Colors.purple),
        evenRowColor: Color(0xFFF1F5F9),
      );

      await tester.pumpWidget(
        _host(
          ChartDataTable(model: model),
          theme: ThemeData(extensions: const [tableTheme]),
        ),
      );

      expect(find.byKey(const ValueKey('chart-table-header-index')), findsOne);
      expect(find.byKey(const ValueKey('chart-table-row-index-0')), findsOne);
      expect(find.text('#'), findsOne);
      expect(tester.getSize(find.byKey(rowKey)).height, 32);

      final xHeader = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('chart-table-header-x')),
          matching: find.text('X value'),
        ),
      );
      final xValue = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('chart-table-cell-x-0')),
          matching: find.text('7'),
        ),
      );
      expect(xHeader.textAlign, TextAlign.right);
      expect(xValue.textAlign, TextAlign.right);
      expect(xValue.style?.fontSize, 10);
      expect(xValue.style?.color, Colors.purple);

      final powerValue = tester.widget<Text>(find.text('241.44'));
      expect(powerValue.textAlign, TextAlign.right);
      expect(powerValue.style?.color, powerColor);
      expect(
        find.byKey(const ValueKey('chart-table-series-color-series:power')),
        findsOne,
      );
    },
  );

  testWidgets('copies wide rows and exports raw values in displayed order', (
    tester,
  ) async {
    ChartTableRowExport? copied;
    ChartTableCsvExport? copiedDataset;
    ChartTableCsvExport? exported;
    final semantics = tester.ensureSemantics();
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(2, 220), _point(1, 110)]),
        _series('heart-rate', [_point(2, 142), _point(1, 131)]),
      ]),
    );

    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          onCopyRow: (row) => copied = row,
          onCopyDataset: (value) => copiedDataset = value,
          onExportCsv: (value) => exported = value,
        ),
      ),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('chart-table-header-row-actions')),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('chart-table-header-index')))
            .dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byTooltip('Copy row 1')).dx,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('chart-table-row-index-0')))
            .dx,
      ),
    );
    await tester.tap(find.text('X value'));
    await tester.pump();

    await tester.tap(find.byTooltip('Copy row 1'));
    await tester.tap(find.text('Copy data'));
    await tester.tap(find.text('Export CSV'));

    expect(copied?.headers, ['#', 'X value', 'Power', 'Heart rate']);
    expect(find.bySemanticsLabel('Row actions'), findsOneWidget);
    expect(copied?.rawValues, [1, 1.0, 110.0, 131.0]);
    expect(copied?.displayValues, ['1', '1', '110', '131']);
    expect(copied?.references.map((item) => item.pointIndex), [1, 1]);
    expect(copiedDataset?.rows, hasLength(2));
    expect(copiedDataset?.rows.first.displayValues, ['1', '1', '110', '131']);
    expect(exported?.rows, hasLength(2));
    expect(exported?.rows.first.rawValues, [1, 1.0, 110.0, 131.0]);
    expect(exported?.rows.last.rawValues, [2, 2.0, 220.0, 142.0]);
    expect(exported?.csv, contains('\r\n1,1.0,110.0,131.0\r\n'));
    semantics.dispose();
  });

  testWidgets('copies the displayed dataset and individual rows natively', (
    tester,
  ) async {
    final clipboard = _mockClipboard();
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(1, 110), _point(2, 220)]),
        _series('heart-rate', [_point(1, 131), _point(2, 142)]),
      ]),
    );

    await tester.pumpWidget(_host(ChartDataTable(model: model)));
    await tester.tap(find.text('Copy data'));
    await tester.pump();

    expect(
      clipboard.text,
      '#\tX value\tPower\tHeart rate\r\n'
      '1\t1\t110\t131\r\n'
      '2\t2\t220\t142',
    );
    expect(find.text('Copied 2 rows to the clipboard.'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy row 1'));
    await tester.pump();
    expect(clipboard.text, '1\t1\t110\t131');
    expect(find.text('Copied row 1 to the clipboard.'), findsOneWidget);
  });

  testWidgets('blocks oversized dataset copies and directs users to export', (
    tester,
  ) async {
    final clipboard = _mockClipboard()..text = 'keep-me';
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(1, 110), _point(2, 220), _point(3, 330)]),
      ]),
    );
    await tester.pumpWidget(
      _host(ChartDataTable(model: model, clipboardRowLimit: 2)),
    );
    await tester.tap(find.text('Copy data'));
    await tester.pump();

    expect(
      find.text(
        'This table has 3 rows and is too large to copy. '
        'Use Export CSV instead.',
      ),
      findsOneWidget,
    );
    expect(find.text('Export CSV'), findsOneWidget);
    expect(clipboard.text, 'keep-me');
  });

  testWidgets('also bounds dataset copy by serialized character count', (
    tester,
  ) async {
    final clipboard = _mockClipboard()..text = 'keep-me';
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(1, 110)]),
      ]),
    );

    await tester.pumpWidget(
      _host(ChartDataTable(model: model, clipboardCharacterLimit: 8)),
    );
    await tester.tap(find.text('Copy data'));
    await tester.pump();

    expect(
      find.text(
        'This table is too large to copy safely. Use Export CSV instead.',
      ),
      findsOneWidget,
    );
    expect(clipboard.text, 'keep-me');
  });

  testWidgets('uses compact tooltipped actions on narrow tables', (
    tester,
  ) async {
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(1, 110)]),
      ]),
    );

    await tester.pumpWidget(_host(ChartDataTable(model: model), width: 360));

    expect(find.byTooltip('Copy data'), findsOneWidget);
    expect(find.byTooltip('Export CSV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow keys traverse rows and Enter activates the focused row', (
    tester,
  ) async {
    List<ChartPointRef>? focused;
    List<ChartPointRef>? activated;
    var focusCleared = false;
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(1, 100), _point(2, 200), _point(3, 300)]),
      ]),
    );

    await tester.pumpWidget(
      _host(
        ChartDataTable(
          model: model,
          onRowFocused: (value) => focused = value,
          onRowFocusCleared: () => focusCleared = true,
          onRowActivated: (value) => activated = value,
        ),
        width: 260,
      ),
    );

    final firstDetector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byKey(ValueKey(model.wideRows[0].rowId)),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    firstDetector.focusNode!.requestFocus();
    await tester.pump();
    expect(focused?.single.pointIndex, 0);
    final focusedContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(ValueKey(model.wideRows[0].rowId)),
            matching: find.byType(Container),
          )
          .first,
    );
    final focusedBorder =
        (focusedContainer.foregroundDecoration! as BoxDecoration).border!
            as Border;
    expect(focusedBorder.top.width, 2);

    final horizontalScroll = tester.widget<SingleChildScrollView>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(horizontalScroll.controller?.offset, greaterThan(0));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    final secondDetector = tester.widget<FocusableActionDetector>(
      find.descendant(
        of: find.byKey(ValueKey(model.wideRows[1].rowId)),
        matching: find.byType(FocusableActionDetector),
      ),
    );
    expect(secondDetector.focusNode?.hasFocus, isTrue);
    expect(focused?.single.pointIndex, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activated?.single.pointIndex, 1);

    secondDetector.focusNode?.unfocus();
    await tester.pump();
    expect(focusCleared, isTrue);
  });

  testWidgets('large text and high contrast expand density without overflow', (
    tester,
  ) async {
    final model = ChartTableModel.fromDocument(
      _document([
        _series('power', [_point(1, 100)]),
      ]),
    );
    final rowKey = ValueKey(model.wideRows.single.rowId);

    await tester.pumpWidget(
      _host(
        ChartDataTable(model: model),
        theme: ThemeData.dark(),
        textScaler: const TextScaler.linear(2),
        highContrast: true,
      ),
    );

    expect(tester.getSize(find.byKey(rowKey)).height, greaterThan(36));
    expect(find.text('Power'), findsOneWidget);
    tester
        .widget<FocusableActionDetector>(
          find.descendant(
            of: find.byKey(rowKey),
            matching: find.byType(FocusableActionDetector),
          ),
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    final focusedContainer = tester.widget<Container>(
      find
          .descendant(of: find.byKey(rowKey), matching: find.byType(Container))
          .first,
    );
    final focusedBorder =
        (focusedContainer.foregroundDecoration! as BoxDecoration).border!
            as Border;
    expect(focusedBorder.top.width, 3);
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

Widget _host(
  Widget child, {
  double height = 420,
  double width = 900,
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
  bool highContrast = false,
}) => MaterialApp(
  theme: theme,
  home: Scaffold(
    body: Center(
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: textScaler,
          highContrast: highContrast,
        ),
        child: SizedBox(width: width, height: height, child: child),
      ),
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

ChartTableModel _barTableModel() {
  const bar = BarChartSeries(
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
  );
  return ChartTableModel.fromDocument(
    _document([_success(ChartSeriesDocumentCodec.encode(bar)).value]),
  );
}

ChartSeriesDocument _series(
  String id,
  List<ChartPointDocument> points, {
  Color? color,
}) => ChartSeriesDocument(
  type: 'line',
  id: id,
  name: switch (id) {
    'power' => 'Power',
    'heart-rate' => 'Heart rate',
    _ => 'Series',
  },
  data: InlinePointPayload(points),
  style: color == null
      ? null
      : JsonValue.fromJson({'color': color.toARGB32()}) as JsonObjectValue,
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

_ClipboardHarness _mockClipboard() {
  final harness = _ClipboardHarness();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    switch (call.method) {
      case 'Clipboard.setData':
        harness.text =
            (call.arguments as Map<Object?, Object?>)['text'] as String?;
        return null;
      case 'Clipboard.getData':
        return <String, Object?>{'text': harness.text};
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return harness;
}

class _ClipboardHarness {
  String? text;
}
