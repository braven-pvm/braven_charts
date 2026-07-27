import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _zoomIn = CustomSemanticsAction(label: 'Zoom in');
const _zoomOut = CustomSemanticsAction(label: 'Zoom out');
const _panLeft = CustomSemanticsAction(label: 'Pan left');
const _panRight = CustomSemanticsAction(label: 'Pan right');
const _panUp = CustomSemanticsAction(label: 'Pan up');
const _panDown = CustomSemanticsAction(label: 'Pan down');
const _fitAllData = CustomSemanticsAction(label: 'Fit all data');
const _returnToLive = CustomSemanticsAction(label: 'Return to live data');
const _selectAllData = CustomSemanticsAction(label: 'Select all chart data');
const _clearSelection = CustomSemanticsAction(label: 'Clear chart selection');

void main() {
  group('mobile accessibility actions', () {
    testWidgets('advertises capability-gated viewport and selection commands', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller: controller));
      await tester.pumpAndSettle();

      final viewportData = _semanticsData(tester, 'Chart viewport actions');
      expect(
        _customActionIds(viewportData),
        containsAll([
          _actionId(_zoomIn),
          _actionId(_zoomOut),
          _actionId(_panLeft),
          _actionId(_panRight),
          _actionId(_panUp),
          _actionId(_panDown),
          _actionId(_fitAllData),
        ]),
      );

      final selectionData = _semanticsData(tester, 'Chart selection actions');
      expect(
        _customActionIds(selectionData),
        contains(_actionId(_selectAllData)),
      );
      expect(
        _customActionIds(selectionData),
        isNot(contains(_actionId(_clearSelection))),
      );
      semantics.dispose();
    });

    testWidgets('viewport actions mutate and fit the mounted viewport', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller: controller));
      await tester.pumpAndSettle();

      final initial = _viewport(tester);
      _performCustomAction(tester, 'Chart viewport actions', _zoomIn);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      final zoomed = _viewport(tester);
      expect(zoomed.width, lessThan(initial.width));
      expect(
        _semanticsData(tester, 'Chart viewport actions').value,
        startsWith('Zoomed in.'),
      );

      _performCustomAction(tester, 'Chart viewport actions', _panRight);
      await tester.pumpAndSettle();
      final panned = _viewport(tester);
      expect(panned.left, greaterThan(zoomed.left));
      expect(
        _semanticsData(tester, 'Chart viewport actions').value,
        startsWith('Panned right.'),
      );

      _performCustomAction(tester, 'Chart viewport actions', _fitAllData);
      await tester.pumpAndSettle();
      final fitted = _viewport(tester);
      expect(fitted.width, greaterThan(zoomed.width));
      expect(fitted.left, lessThan(panned.left));
      expect(
        _semanticsData(tester, 'Chart viewport actions').value,
        startsWith('Showing all data.'),
      );
      semantics.dispose();
    });

    testWidgets('selection commands select bounded data and clear all state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller: controller));
      await tester.pumpAndSettle();

      _performCustomAction(tester, 'Chart selection actions', _selectAllData);
      await tester.pump();
      expect(controller.selectedPointRefs, hasLength(4));
      expect(
        _semanticsData(tester, 'Chart selection actions').value,
        'Selected 4 data points.',
      );

      final selectedActions = _customActionIds(
        _semanticsData(tester, 'Chart selection actions'),
      );
      expect(selectedActions, contains(_actionId(_clearSelection)));

      _performCustomAction(tester, 'Chart selection actions', _clearSelection);
      await tester.pump();
      expect(controller.selectedPointRefs, isEmpty);
      expect(controller.selectedSeriesIds, isEmpty);
      expect(
        _semanticsData(tester, 'Chart selection actions').value,
        'Selection cleared.',
      );
      semantics.dispose();
    });

    testWidgets('public controller uses the same viewport and selection path', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller: controller));
      await tester.pumpAndSettle();

      final initial = _viewport(tester);
      expect(controller.zoomViewport(1.5), isTrue);
      await tester.pumpAndSettle();
      final zoomed = _viewport(tester);
      expect(zoomed.width, lessThan(initial.width));

      expect(
        controller.panViewport(horizontalPixels: 20, verticalPixels: 0),
        isTrue,
      );
      await tester.pump();
      expect(_viewport(tester).left, greaterThan(zoomed.left));

      expect(controller.selectAllData(), isTrue);
      await tester.pump();
      expect(controller.selectedPointRefs, hasLength(4));
      expect(controller.clearAllSelection(), isTrue);
      await tester.pump();
      expect(controller.selectedPointRefs, isEmpty);

      expect(controller.fitData(), isTrue);
      await tester.pump();
    });

    testWidgets('return to live is offered only while exploring live data', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      final streaming = StreamingController();
      addTearDown(controller.dispose);
      addTearDown(streaming.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          streamingController: streaming,
          autoScrollConfig: const AutoScrollConfig(enabled: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _customActionIds(_semanticsData(tester, 'Chart viewport actions')),
        isNot(contains(_actionId(_returnToLive))),
      );

      streaming.pauseStreaming();
      await tester.pump();
      expect(streaming.isPaused, isTrue);
      expect(
        _customActionIds(_semanticsData(tester, 'Chart viewport actions')),
        contains(_actionId(_returnToLive)),
      );

      _performCustomAction(tester, 'Chart viewport actions', _returnToLive);
      await tester.pumpAndSettle();
      expect(streaming.isStreaming, isTrue);
      expect(
        _semanticsData(tester, 'Chart viewport actions').value,
        startsWith('Following live data.'),
      );
      semantics.dispose();
    });

    testWidgets('disabled interaction exposes no command nodes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          interactionConfig: InteractionConfig.none(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel('Chart viewport actions'), findsNothing);
      expect(find.semantics.byLabel('Chart selection actions'), findsNothing);
      semantics.dispose();
    });
  });
}

Widget _host({
  required BravenChartController controller,
  InteractionConfig? interactionConfig,
  StreamingController? streamingController,
  AutoScrollConfig? autoScrollConfig,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 560,
      height: 380,
      child: BravenChartPlus(
        bravenChartController: controller,
        showLegend: false,
        interactionConfig: interactionConfig,
        streamingController: streamingController,
        autoScrollConfig: autoScrollConfig,
        series: const [
          LineChartSeries(
            id: 'signal',
            name: 'Signal',
            unit: 'units',
            points: [
              ChartDataPoint(x: 0, y: 10, label: 'A'),
              ChartDataPoint(x: 1, y: 30, label: 'B'),
              ChartDataPoint(x: 2, y: 20, label: 'C'),
              ChartDataPoint(x: 3, y: 40, label: 'D'),
            ],
          ),
        ],
      ),
    ),
  ),
);

SemanticsData _semanticsData(WidgetTester tester, String label) {
  final finder = find.semantics.byLabel(label);
  expect(finder, findsOneWidget);
  return finder.evaluate().single.getSemanticsData();
}

Set<int> _customActionIds(SemanticsData data) =>
    (data.customSemanticsActionIds ?? const <int>[]).toSet();

int _actionId(CustomSemanticsAction action) =>
    CustomSemanticsAction.getIdentifier(action);

void _performCustomAction(
  WidgetTester tester,
  String nodeLabel,
  CustomSemanticsAction action,
) {
  final node = find.semantics.byLabel(nodeLabel).evaluate().single;
  tester.binding.pipelineOwner.semanticsOwner!.performAction(
    node.id,
    ui.SemanticsAction.customAction,
    _actionId(action),
  );
}

Rect _viewport(WidgetTester tester) {
  final renderBox = tester.renderObject<ChartRenderBox>(
    find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
    ),
  );
  final transform = renderBox.transform!;
  return Rect.fromLTRB(
    transform.dataXMin,
    transform.dataYMin,
    transform.dataXMax,
    transform.dataYMax,
  );
}
