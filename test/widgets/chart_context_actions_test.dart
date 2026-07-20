import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/core/interaction_mode.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chart overlay action is hidden until explicitly provided', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chart-overlay-action-button-host.add')),
      findsNothing,
    );
  });

  testWidgets('chart overlay action is configurable and invokes its host', (
    tester,
  ) async {
    var invocations = 0;
    await tester.pumpWidget(
      _host(
        chartActionButtonBuilder: (context) => ChartOverlayAction(
          id: 'host.add',
          tooltip: 'Add chart to report',
          semanticLabel: 'Add this chart to the current report',
          icon: Icons.bookmark_add_outlined,
          onPressed: () => invocations++,
        ),
        chartActionButtonConfig: const ChartOverlayActionButtonConfig(
          alignment: Alignment.bottomRight,
          margin: EdgeInsets.all(16),
          iconSize: 18,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(
      const ValueKey('chart-overlay-action-button-host.add'),
    );
    expect(button, findsOneWidget);
    expect(tester.getSize(button), const Size.square(48));
    final chartBounds =
        _renderBox(tester).localToGlobal(Offset.zero) & _renderBox(tester).size;
    final buttonBounds = tester.getRect(button);
    expect(buttonBounds.right, closeTo(chartBounds.right - 16, 0.1));
    expect(buttonBounds.bottom, closeTo(chartBounds.bottom - 16, 0.1));
    final iconButton = tester.widget<IconButton>(button);
    final defaultBackground = iconButton.style!.backgroundColor!.resolve({});
    expect(defaultBackground!.a, closeTo(0.48, 0.001));

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(invocations, 1);
  });

  testWidgets('chart overlay action accepts a host Material style', (
    tester,
  ) async {
    const background = Color(0xCC102A43);
    const foreground = Color(0xFFF0F4F8);
    await tester.pumpWidget(
      _host(
        chartActionButtonBuilder: (context) => ChartOverlayAction(
          id: 'host.themed',
          tooltip: 'Add chart to report',
          icon: Icons.bookmark_add_outlined,
          onPressed: () {},
        ),
        chartActionButtonConfig: const ChartOverlayActionButtonConfig(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(background),
            foregroundColor: WidgetStatePropertyAll(foreground),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final iconButton = tester.widget<IconButton>(
      find.byKey(const ValueKey('chart-overlay-action-button-host.themed')),
    );
    expect(iconButton.style!.backgroundColor!.resolve({}), background);
    expect(iconButton.style!.foregroundColor!.resolve({}), foreground);
  });

  testWidgets(
    'secondary click exposes host actions without annotation infrastructure',
    (tester) async {
      ChartContextInvocation? invocation;
      InteractionMode? modeWhenSelected;

      await tester.pumpWidget(
        _host(
          contextActionsBuilder: (context, value) {
            invocation = value;
            return [
              ChartContextAction(
                id: 'host.inspect',
                label: 'Inspect in host',
                icon: Icons.open_in_new,
                onSelected: () {
                  modeWhenSelected = _renderBox(tester).coordinator.currentMode;
                },
              ),
            ];
          },
        ),
      );
      await tester.pumpAndSettle();

      await _secondaryClick(tester, _plotCenter(tester));

      expect(find.text('Inspect in host'), findsOneWidget);
      expect(invocation?.source, ChartContextInvocationSource.secondaryClick);
      expect(invocation?.capabilities.annotationsAvailable, isFalse);

      await tester.tap(find.text('Inspect in host'));
      await tester.pumpAndSettle();

      expect(modeWhenSelected, InteractionMode.idle);
      expect(_renderBox(tester).coordinator.currentMode, InteractionMode.idle);
    },
  );

  testWidgets('secondary click with no effective actions releases the chart', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await _secondaryClick(tester, _plotCenter(tester));

    expect(find.byType(PopupMenuItem), findsNothing);
    expect(_renderBox(tester).coordinator.currentMode, InteractionMode.idle);
  });

  testWidgets('bar hits expose renderer-neutral series and point identity', (
    tester,
  ) async {
    ChartContextInvocation? invocation;
    await tester.pumpWidget(
      _host(
        series: const [
          BarChartSeries(
            id: 'revenue',
            name: 'Revenue',
            barWidthPercent: 0.6,
            points: [
              ChartDataPoint(x: 0, y: 42, label: 'January'),
              ChartDataPoint(x: 1, y: 61, label: 'February'),
            ],
          ),
        ],
        contextActionsBuilder: (context, value) {
          invocation = value;
          return [
            ChartContextAction(
              id: 'host.capture',
              label: 'Capture point',
              onSelected: () {},
            ),
          ];
        },
      ),
    );
    await tester.pumpAndSettle();

    final renderBox = _renderBox(tester);
    final dataHit = renderBox.dataHitForPointIndex('revenue', 0)!;
    final pointPosition = renderBox.localToGlobal(
      renderBox.plotToWidget(dataHit.plotPosition),
    );
    await _secondaryClick(tester, pointPosition);

    expect(invocation?.hit.kind, ChartContextHitKind.point);
    expect(invocation?.hit.seriesId, 'revenue');
    expect(invocation?.hit.pointIndex, 0);
    expect(invocation?.hit.point?.label, 'January');
    expect(invocation?.capabilities.hasDataHit, isTrue);
  });

  testWidgets('Shift+F10 opens the same menu and Escape restores chart focus', (
    tester,
  ) async {
    ChartContextInvocationSource? source;
    await tester.pumpWidget(
      _host(
        contextActionsBuilder: (context, invocation) {
          source = invocation.source;
          return [
            ChartContextAction(
              id: 'host.keyboard',
              label: 'Keyboard action',
              onSelected: () {},
            ),
          ];
        },
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(_plotCenter(tester));
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.f10);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();

    expect(source, ChartContextInvocationSource.keyboard);
    expect(find.text('Keyboard action'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('Keyboard action'), findsNothing);
    expect(_renderBox(tester).coordinator.currentMode, InteractionMode.idle);
  });

  testWidgets('Context Menu key supports arrow navigation and activation', (
    tester,
  ) async {
    String? selected;
    InteractionMode? modeWhenSelected;
    await tester.pumpWidget(
      _host(
        contextActionsBuilder: (context, invocation) => [
          ChartContextAction(
            id: 'host.first',
            label: 'First action',
            onSelected: () => selected = 'first',
          ),
          ChartContextAction(
            id: 'host.disabled',
            label: 'Disabled action',
            enabled: false,
            onSelected: () => selected = 'disabled',
          ),
          ChartContextAction(
            id: 'host.last',
            label: 'Last action',
            onSelected: () {
              selected = 'last';
              modeWhenSelected = _renderBox(tester).coordinator.currentMode;
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(_plotCenter(tester));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected, 'last');
    expect(modeWhenSelected, InteractionMode.idle);
    expect(find.text('First action'), findsNothing);
  });

  testWidgets('touch long press is opt-in and uses the shared action path', (
    tester,
  ) async {
    ChartContextInvocationSource? source;
    await tester.pumpWidget(
      _host(
        contextMenuConfig: const ChartContextMenuConfig(
          enableLongPress: true,
          longPressDuration: Duration(milliseconds: 100),
        ),
        contextActionsBuilder: (context, invocation) {
          source = invocation.source;
          return [
            ChartContextAction(
              id: 'host.touch',
              label: 'Touch action',
              onSelected: () {},
            ),
          ];
        },
      ),
    );
    await tester.pumpAndSettle();

    final touch = await tester.startGesture(
      _plotCenter(tester),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle();

    expect(source, ChartContextInvocationSource.longPress);
    expect(find.text('Touch action'), findsOneWidget);

    await touch.up();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  testWidgets('moving a touch pointer cancels the opt-in long press', (
    tester,
  ) async {
    var builderCalls = 0;
    await tester.pumpWidget(
      _host(
        contextMenuConfig: const ChartContextMenuConfig(
          enableLongPress: true,
          longPressDuration: Duration(milliseconds: 100),
        ),
        contextActionsBuilder: (context, invocation) {
          builderCalls++;
          return [
            ChartContextAction(
              id: 'host.touch',
              label: 'Touch action',
              onSelected: () {},
            ),
          ];
        },
      ),
    );
    await tester.pumpAndSettle();

    final start = _plotCenter(tester);
    final touch = await tester.startGesture(
      start,
      kind: PointerDeviceKind.touch,
    );
    await touch.moveTo(start + const Offset(80, 0));
    await tester.pump(const Duration(milliseconds: 120));
    await touch.up();
    await tester.pumpAndSettle();

    expect(builderCalls, 0);
    expect(find.text('Touch action'), findsNothing);
  });

  testWidgets(
    'host actions are grouped before annotation and destructive rows',
    (tester) async {
      final annotations = AnnotationController();
      addTearDown(annotations.dispose);
      await tester.pumpWidget(
        _host(
          annotationController: annotations,
          contextActionsBuilder: (context, invocation) => [
            ChartContextAction(
              id: 'host.inspect',
              label: 'Inspect in host',
              onSelected: () {},
            ),
            ChartContextAction(
              id: 'host.remove',
              label: 'Remove from host',
              section: ChartContextActionSection.destructive,
              onSelected: () {},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await _secondaryClick(tester, _plotCenter(tester));

      final hostY = tester.getCenter(find.text('Inspect in host')).dy;
      final annotationY = tester.getCenter(find.text('Add Text Annotation')).dy;
      final destructiveY = tester.getCenter(find.text('Remove from host')).dy;
      expect(hostY, lessThan(annotationY));
      expect(annotationY, lessThan(destructiveY));
    },
  );

  testWidgets('disabled actions cannot run', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      _host(
        contextActionsBuilder: (context, invocation) => [
          ChartContextAction(
            id: 'host.disabled',
            label: 'Unavailable action',
            enabled: false,
            onSelected: () => selected = true,
          ),
          ChartContextAction(
            id: 'host.enabled',
            label: 'Available action',
            onSelected: () {},
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _secondaryClick(tester, _plotCenter(tester));
    await tester.tap(find.text('Unavailable action'));
    await tester.pump();

    expect(selected, isFalse);
    expect(find.text('Available action'), findsOneWidget);
  });

  testWidgets('async host failures are reported after coordinator cleanup', (
    tester,
  ) async {
    final reportedErrors = <FlutterErrorDetails>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = reportedErrors.add;
    addTearDown(() => FlutterError.onError = previousHandler);

    await tester.pumpWidget(
      _host(
        contextActionsBuilder: (context, invocation) => [
          ChartContextAction(
            id: 'host.failing',
            label: 'Fail safely',
            onSelected: () async {
              await Future<void>.delayed(Duration.zero);
              throw StateError('host action failed');
            },
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await _secondaryClick(tester, _plotCenter(tester));
    await tester.tap(find.text('Fail safely'));
    await tester.pumpAndSettle();

    expect(reportedErrors, hasLength(1));
    expect(reportedErrors.single.exception, isA<StateError>());
    expect(_renderBox(tester).coordinator.currentMode, InteractionMode.idle);
  });

  testWidgets('disposing a chart with an open menu is safe', (tester) async {
    await tester.pumpWidget(
      _host(
        contextActionsBuilder: (context, invocation) => [
          ChartContextAction(
            id: 'host.open',
            label: 'Open action',
            onSelected: () {},
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await _secondaryClick(tester, _plotCenter(tester));
    expect(find.text('Open action'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pumpAndSettle();

    expect(find.text('Open action'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _host({
  List<ChartSeries> series = const [
    LineChartSeries(
      id: 'signal',
      name: 'Signal',
      points: [
        ChartDataPoint(x: 0, y: 10),
        ChartDataPoint(x: 1, y: 14),
        ChartDataPoint(x: 2, y: 12),
      ],
    ),
  ],
  ChartContextActionsBuilder? contextActionsBuilder,
  ChartContextMenuConfig contextMenuConfig = const ChartContextMenuConfig(),
  AnnotationController? annotationController,
  ChartOverlayActionBuilder? chartActionButtonBuilder,
  ChartOverlayActionButtonConfig chartActionButtonConfig =
      const ChartOverlayActionButtonConfig(),
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 620,
        height: 420,
        child: BravenChartPlus(
          series: series,
          showLegend: false,
          contextActionsBuilder: contextActionsBuilder,
          contextMenuConfig: contextMenuConfig,
          annotationController: annotationController,
          chartActionButtonBuilder: chartActionButtonBuilder,
          chartActionButtonConfig: chartActionButtonConfig,
        ),
      ),
    ),
  ),
);

ChartRenderBox _renderBox(WidgetTester tester) =>
    tester.allRenderObjects.whereType<ChartRenderBox>().single;

Offset _plotCenter(WidgetTester tester) {
  final renderBox = _renderBox(tester);
  return renderBox.localToGlobal(
    renderBox.plotToWidget(
      Offset(renderBox.plotWidth / 2, renderBox.plotHeight / 2),
    ),
  );
}

Future<void> _secondaryClick(WidgetTester tester, Offset position) async {
  final gesture = await tester.startGesture(
    position,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await gesture.up();
  await tester.pumpAndSettle();
}
