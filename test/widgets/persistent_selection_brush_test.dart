import 'dart:ui' as ui;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/chart_render_box.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('persistent selection brush', () {
    testWidgets(
      'keyboard arrows move and Shift arrows resize through selection callbacks',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        var callbackCount = 0;
        await tester.pumpWidget(
          _host(
            controller: controller,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
            ),
            onSelectionResultChanged: (_) => callbackCount++,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BravenChartPlus));
        await tester.pump();
        callbackCount = 0;
        expect(
          tester
              .renderObject<ChartRenderBox>(_chartRenderFinder())
              .debugSelectionBrushKeyboardFocused,
          isTrue,
        );

        final initial = controller.selectionBrushState!.range;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        final moved = controller.selectionBrushState!.range;
        expect(moved.minimum, greaterThan(initial.minimum));
        expect(moved.maximum, greaterThan(initial.maximum));
        expect(
          moved.maximum - moved.minimum,
          closeTo(initial.maximum - initial.minimum, 0.01),
        );

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        final resized = controller.selectionBrushState!.range;
        expect(resized.minimum, closeTo(moved.minimum, 0.01));
        expect(resized.maximum, lessThan(moved.maximum));

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        final lowerBoundResized = controller.selectionBrushState!.range;
        expect(lowerBoundResized.minimum, greaterThan(resized.minimum));
        expect(lowerBoundResized.maximum, closeTo(resized.maximum, 0.01));
        expect(callbackCount, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'semantics announce bounds and expose move and resize actions',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            controller: controller,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final finder = find.semantics.byLabel('X range selection');
        expect(finder, findsOne);
        final data = finder.evaluate().single.getSemanticsData();
        expect(data.value, '2.00 to 6.00');
        final actionIds = data.customSemanticsActionIds ?? const <int>[];
        for (final action in const [
          CustomSemanticsAction(label: 'Move interval lower'),
          CustomSemanticsAction(label: 'Move interval higher'),
          CustomSemanticsAction(label: 'Decrease lower bound'),
          CustomSemanticsAction(label: 'Increase lower bound'),
          CustomSemanticsAction(label: 'Decrease upper bound'),
          CustomSemanticsAction(label: 'Increase upper bound'),
        ]) {
          expect(
            actionIds,
            contains(CustomSemanticsAction.getIdentifier(action)),
            reason: 'expected ${action.label}',
          );
        }

        const moveHigher = CustomSemanticsAction(label: 'Move interval higher');
        final node = finder.evaluate().single;
        tester.binding.pipelineOwner.semanticsOwner!.performAction(
          node.id,
          ui.SemanticsAction.customAction,
          CustomSemanticsAction.getIdentifier(moveHigher),
        );
        await tester.pump();
        expect(controller.selectionBrushState!.range.minimum, greaterThan(2));
        semantics.dispose();
      },
    );

    testWidgets('transposed horizontal bars keep X brush on category axis', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_horizontalBarHost(controller));
      await tester.pumpAndSettle();

      final finder = _chartRenderFinder();
      var renderBox = tester.renderObject<ChartRenderBox>(finder);
      final initialRect = renderBox.selectionBrushWidgetRect!;
      expect(initialRect.width, closeTo(renderBox.debugPlotArea.width, 0.01));
      expect(initialRect.height, lessThan(renderBox.debugPlotArea.height));

      await tester.tapAt(tester.getTopLeft(finder) + initialRect.center);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();

      renderBox = tester.renderObject<ChartRenderBox>(finder);
      expect(controller.selectionBrushState!.range.minimum, greaterThan(0));
      expect(
        renderBox.selectionBrushWidgetRect!.center.dy,
        greaterThan(initialRect.center.dy),
      );
    });

    testWidgets('RTL and chart resize preserve data-domain brush bounds', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      const brush = ChartSelectionBrushConfig(
        enabled: true,
        initialVisible: true,
        initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
      );
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: brush,
          width: 520,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      final finder = _chartRenderFinder();
      final before = tester
          .renderObject<ChartRenderBox>(finder)
          .selectionBrushWidgetRect!;
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: brush,
          width: 800,
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<ChartRenderBox>(finder);
      final after = renderBox.selectionBrushWidgetRect!;
      expect(after.width, greaterThan(before.width));
      expect(controller.selectionBrushState!.range.minimum, 2);
      expect(controller.selectionBrushState!.range.maximum, 6);
      final resolved = renderBox.selectionBrushRangeForWidgetRect(
        after,
        acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
      )!;
      expect(resolved.minimum, closeTo(2, 0.01));
      expect(resolved.maximum, closeTo(6, 0.01));
    });

    testWidgets('zoom reprojects the durable range without changing intent', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 4, maximum: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<ChartRenderBox>(
        _chartRenderFinder(),
      );
      final before = renderBox.selectionBrushWidgetRect!;
      renderBox.zoomChart(1.5, animate: false);
      await tester.pump();
      final after = renderBox.selectionBrushWidgetRect!;

      expect(after.width, greaterThan(before.width));
      expect(controller.selectionBrushState!.range.minimum, 4);
      expect(controller.selectionBrushState!.range.maximum, 6);
    });

    testWidgets(
      'one-finger touch moves and resizes the brush without panning',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        var callbackCount = 0;
        await tester.pumpWidget(
          _host(
            controller: controller,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
            ),
            onSelectionResultChanged: (_) => callbackCount++,
          ),
        );
        await tester.pumpAndSettle();

        var renderBox = tester.renderObject<ChartRenderBox>(
          _chartRenderFinder(),
        );
        final viewportBefore = (
          renderBox.transform!.dataXMin,
          renderBox.transform!.dataXMax,
        );
        final initial = controller.selectionBrushState!.range;
        var rect = renderBox.selectionBrushWidgetRect!;
        final move = await tester.createGesture(
          pointer: 301,
          kind: PointerDeviceKind.touch,
        );
        final moveStart = renderBox.localToGlobal(rect.center);
        await move.down(moveStart);
        await move.moveTo(moveStart + const Offset(48, 0));
        await tester.pump();
        await move.up();
        await tester.pump();

        final moved = controller.selectionBrushState!.range;
        expect(moved.minimum, greaterThan(initial.minimum));
        expect(moved.maximum, greaterThan(initial.maximum));

        renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
        rect = renderBox.selectionBrushWidgetRect!;
        final resize = await tester.createGesture(
          pointer: 302,
          kind: PointerDeviceKind.touch,
        );
        final resizeStart = renderBox.localToGlobal(rect.centerRight);
        await resize.down(resizeStart);
        await resize.moveTo(resizeStart + const Offset(42, 0));
        await tester.pump();
        await resize.up();
        await tester.pump();

        final resized = controller.selectionBrushState!.range;
        expect(resized.minimum, closeTo(moved.minimum, 0.01));
        expect(resized.maximum, greaterThan(moved.maximum));
        renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
        expect((
          renderBox.transform!.dataXMin,
          renderBox.transform!.dataXMax,
        ), viewportBefore);
        expect(callbackCount, greaterThanOrEqualTo(2));
      },
    );

    testWidgets(
      'two-finger touch takes over from a brush and restores partial movement',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            controller: controller,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
            ),
          ),
        );
        await tester.pumpAndSettle();

        var renderBox = tester.renderObject<ChartRenderBox>(
          _chartRenderFinder(),
        );
        final initialRange = controller.selectionBrushState!.range;
        final initialSpan =
            renderBox.transform!.dataXMax - renderBox.transform!.dataXMin;
        final originalCenter = renderBox.selectionBrushWidgetRect!.center;
        final first = await tester.createGesture(
          pointer: 311,
          kind: PointerDeviceKind.touch,
        );
        final second = await tester.createGesture(
          pointer: 312,
          kind: PointerDeviceKind.touch,
        );
        final firstStart = renderBox.localToGlobal(originalCenter);
        await first.down(firstStart);
        await first.moveTo(firstStart + const Offset(24, 0));
        await tester.pump();
        expect(
          controller.selectionBrushState!.range.minimum,
          greaterThan(initialRange.minimum),
        );

        renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
        final takeoverCenter = renderBox.localToGlobal(
          renderBox.selectionBrushWidgetRect!.center,
        );
        await second.down(takeoverCenter + const Offset(12, 0));
        await tester.pump();
        await first.moveTo(takeoverCenter - const Offset(70, 0));
        await second.moveTo(takeoverCenter + const Offset(70, 0));
        await tester.pump();

        renderBox = tester.renderObject<ChartRenderBox>(_chartRenderFinder());
        expect(
          renderBox.transform!.dataXMax - renderBox.transform!.dataXMin,
          lessThan(initialSpan),
        );
        expect(controller.selectionBrushState!.range, initialRange);

        await first.up();
        await second.up();
        await tester.pump();
        expect(controller.selectionBrushState!.range, initialRange);
        expect(renderBox.debugIsSuppressingTouchSequence, isFalse);
      },
    );

    testWidgets(
      'hidden Y reference suppresses geometry without discarding state',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_yReferenceHost(controller));
        await tester.pumpAndSettle();
        expect(
          tester
              .renderObject<ChartRenderBox>(_chartRenderFinder())
              .selectionBrushWidgetRect,
          isNotNull,
        );

        controller.setSeriesVisible('signal', false);
        await tester.pumpAndSettle();
        expect(
          tester
              .renderObject<ChartRenderBox>(_chartRenderFinder())
              .selectionBrushWidgetRect,
          isNull,
        );
        expect(controller.selectionBrushState?.visible, isTrue);
        expect(
          controller.selectionBrushState?.range.referenceSeriesId,
          'signal',
        );

        controller.setSeriesVisible('signal', true);
        await tester.pumpAndSettle();
        expect(
          tester
              .renderObject<ChartRenderBox>(_chartRenderFinder())
              .selectionBrushWidgetRect,
          isNotNull,
        );
      },
    );

    testWidgets('initial visible range renders and selects on first frame', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      final results = <ChartSelectionResult>[];

      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
          ),
          onSelectionResultChanged: results.add,
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<ChartRenderBox>(
        _chartRenderFinder(),
      );
      expect(renderBox.selectionBrushWidgetRect, isNotNull);
      expect(
        controller.selectionBrushState,
        const ChartSelectionBrushState(
          acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
          range: ChartSelectionBrushRange(minimum: 2, maximum: 6),
          visible: true,
        ),
      );
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'signal', pointIndex: 1),
        const ChartPointRef(seriesId: 'signal', pointIndex: 2),
        const ChartPointRef(seriesId: 'signal', pointIndex: 3),
      });
      expect(results, isNotEmpty);
    });

    testWidgets('controller sets, hides, shows, and clears the brush', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(enabled: true),
        ),
      );
      await tester.pumpAndSettle();

      final setResult = controller.setSelectionBrush(minimum: 4, maximum: 8);
      expect(setResult, isA<ChartArtifactSuccess<void>>());
      await tester.pumpAndSettle();
      expect(controller.selectionBrushState?.range.minimum, closeTo(4, 0.01));
      expect(controller.selectionBrushState?.range.maximum, closeTo(8, 0.01));
      expect(controller.selectionBrushState?.visible, isTrue);
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'signal', pointIndex: 2),
        const ChartPointRef(seriesId: 'signal', pointIndex: 3),
        const ChartPointRef(seriesId: 'signal', pointIndex: 4),
      });

      expect(
        controller.hideSelectionBrush(),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.selectionBrushState?.visible, isFalse);
      expect(
        tester
            .renderObject<ChartRenderBox>(_chartRenderFinder())
            .selectionBrushWidgetRect,
        isNull,
      );
      expect(controller.selectedPointRefs, isNotEmpty);

      expect(
        controller.showSelectionBrush(),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.selectionBrushState?.visible, isTrue);

      expect(
        controller.clearSelectionBrush(),
        isA<ChartArtifactSuccess<void>>(),
      );
      await tester.pump();
      expect(controller.selectionBrushState, isNull);
      expect(controller.selectedPointRefs, isEmpty);
    });

    testWidgets('Y range uses its reference series and vertical handles', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          acquisitionMode: ChartSelectionAcquisitionMode.yInterval,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(
              minimum: 30,
              maximum: 50,
              referenceSeriesId: 'signal',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<ChartRenderBox>(
        _chartRenderFinder(),
      );
      final rect = renderBox.selectionBrushWidgetRect!;
      expect(rect.width, closeTo(renderBox.debugPlotArea.width, 0.01));
      expect(rect.height, lessThan(renderBox.debugPlotArea.height));
      expect(controller.selectedPointRefs, {
        const ChartPointRef(seriesId: 'signal', pointIndex: 1),
        const ChartPointRef(seriesId: 'signal', pointIndex: 2),
        const ChartPointRef(seriesId: 'signal', pointIndex: 3),
      });
      expect(controller.selectionBrushState?.range.referenceSeriesId, 'signal');
    });

    testWidgets('moving and resizing reuse the ordinary selection callback', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      var callbackCount = 0;
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
          ),
          onSelectionResultChanged: (_) => callbackCount++,
        ),
      );
      await tester.pumpAndSettle();
      callbackCount = 0;

      final finder = _chartRenderFinder();
      var renderBox = tester.renderObject<ChartRenderBox>(finder);
      final origin = tester.getTopLeft(finder);
      var rect = renderBox.selectionBrushWidgetRect!;
      final initial = controller.selectionBrushState!.range;

      final move = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(move.removePointer);
      await move.addPointer(location: Offset.zero);
      final moveStart = origin + rect.center;
      await move.moveTo(moveStart);
      await move.down(moveStart);
      await move.moveTo(moveStart + const Offset(36, 0));
      await tester.pump();
      await tester.pump();
      await move.up();
      await tester.pumpAndSettle();

      final moved = controller.selectionBrushState!.range;
      expect(
        moved.minimum,
        greaterThan(initial.minimum),
        reason:
            'Expected a translated range; initial=${initial.minimum}–${initial.maximum}, '
            'moved=${moved.minimum}–${moved.maximum}.',
      );
      expect(
        moved.maximum,
        greaterThan(initial.maximum),
        reason:
            'Expected a translated range; initial=${initial.minimum}–${initial.maximum}, '
            'moved=${moved.minimum}–${moved.maximum}.',
      );
      expect(
        moved.maximum - moved.minimum,
        closeTo(initial.maximum - initial.minimum, 0.05),
      );
      renderBox = tester.renderObject<ChartRenderBox>(finder);
      expect(
        renderBox.selectionBrushWidgetRect!.center.dx,
        greaterThan(rect.center.dx),
        reason:
            'The committed render-object brush must reconcile to the final '
            'live-drag position on pointer-up.',
      );
      expect(callbackCount, greaterThan(0));

      callbackCount = 0;
      renderBox = tester.renderObject<ChartRenderBox>(finder);
      rect = renderBox.selectionBrushWidgetRect!;
      final resizeStart = origin + rect.centerLeft;
      await move.moveTo(resizeStart);
      await move.down(resizeStart);
      await move.moveTo(resizeStart + const Offset(80, 0));
      await tester.pump();
      await tester.pump();
      await move.up();
      await tester.pumpAndSettle();

      final resized = controller.selectionBrushState!.range;
      expect(resized.minimum, greaterThan(moved.minimum));
      expect(resized.maximum, closeTo(moved.maximum, 0.05));
      expect(callbackCount, greaterThan(0));
    });

    testWidgets('background taps do not dismiss a persistent brush', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(finder);
      final origin = tester.getTopLeft(finder);
      final before = controller.selectionBrushState;
      final selectedBefore = {...controller.selectedPointRefs};
      final plot = renderBox.debugPlotArea;

      await tester.tapAt(origin + Offset(plot.right - 8, plot.top + 8));
      await tester.pumpAndSettle();

      expect(controller.selectionBrushState, before);
      expect(controller.selectedPointRefs, selectedBefore);
      expect(
        tester.renderObject<ChartRenderBox>(finder).selectionBrushWidgetRect,
        isNotNull,
      );
    });

    testWidgets(
      'multi-step brush drag remains stable across selection callback rebuilds',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        var callbackCount = 0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => _host(
              controller: controller,
              brush: const ChartSelectionBrushConfig(
                enabled: true,
                initialVisible: true,
                initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
              ),
              onSelectionResultChanged: (_) {
                callbackCount++;
                setState(() {});
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        callbackCount = 0;

        final finder = _chartRenderFinder();
        final origin = tester.getTopLeft(finder);
        final renderBox = tester.renderObject<ChartRenderBox>(finder);
        final rect = renderBox.selectionBrushWidgetRect!;
        final initial = controller.selectionBrushState!.range;
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        final start = origin + rect.center;
        await gesture.moveTo(start);
        await gesture.down(start);

        for (final dx in const [8.0, 16.0, 24.0, 32.0]) {
          await gesture.moveTo(start + Offset(dx, 0));
          await tester.pump();
          await tester.pump();
          final state = controller.selectionBrushState;
          expect(state, isNotNull, reason: 'Brush disappeared at dx=$dx.');
          expect(state!.visible, isTrue);
          expect(
            state.range.maximum - state.range.minimum,
            closeTo(initial.maximum - initial.minimum, 0.05),
            reason: 'Brush span jumped at dx=$dx.',
          );
        }

        await gesture.up();
        await tester.pumpAndSettle();

        final moved = controller.selectionBrushState;
        expect(moved, isNotNull);
        expect(moved!.visible, isTrue);
        expect(moved.range.minimum, greaterThan(initial.minimum));
        expect(
          moved.range.maximum - moved.range.minimum,
          closeTo(initial.maximum - initial.minimum, 0.05),
        );
        expect(callbackCount, greaterThan(0));
      },
    );

    testWidgets('a sub-slop brush move cannot be dismissed as a tap', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = _chartRenderFinder();
      final origin = tester.getTopLeft(finder);
      final rect = tester
          .renderObject<ChartRenderBox>(finder)
          .selectionBrushWidgetRect!;
      final initial = controller.selectionBrushState!.range;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      final start = origin + rect.center;
      await gesture.moveTo(start);
      await gesture.down(start);
      await gesture.moveTo(start + const Offset(6, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final state = controller.selectionBrushState;
      expect(state, isNotNull);
      expect(state!.visible, isTrue);
      expect(state.range.minimum, greaterThan(initial.minimum));
      expect(
        state.range.maximum - state.range.minimum,
        closeTo(initial.maximum - initial.minimum, 0.05),
      );
    });

    testWidgets(
      'pointer-up reconciles a moved brush when selected marks did not change',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            controller: controller,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(
                minimum: 2.2,
                maximum: 5.8,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final finder = _chartRenderFinder();
        final origin = tester.getTopLeft(finder);
        var renderBox = tester.renderObject<ChartRenderBox>(finder);
        final initialRect = renderBox.selectionBrushWidgetRect!;
        final selectedBefore = {...controller.selectedPointRefs};
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        final start = origin + initialRect.center;
        await gesture.moveTo(start);
        await gesture.down(start);
        await gesture.moveTo(start + const Offset(6, 0));
        await tester.pump();
        await tester.pump();

        expect(
          controller.selectedPointRefs,
          selectedBefore,
          reason: 'The regression requires unchanged selected marks.',
        );
        final committedRangeBeforeUp = controller.selectionBrushState!.range;
        await gesture.up();
        await tester.pumpAndSettle();

        expect(controller.selectionBrushState!.range, committedRangeBeforeUp);
        renderBox = tester.renderObject<ChartRenderBox>(finder);
        expect(
          renderBox.selectionBrushWidgetRect!.center.dx,
          closeTo(initialRect.center.dx + 6, 0.75),
          reason:
              'The render object must receive the final range even when the '
              'last live update did not change selected marks.',
        );
      },
    );

    testWidgets('brush dragging hands the final pointer X to the crosshair', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          controller: controller,
          brush: const ChartSelectionBrushConfig(
            enabled: true,
            initialVisible: true,
            initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final finder = _chartRenderFinder();
      final origin = tester.getTopLeft(finder);
      var renderBox = tester.renderObject<ChartRenderBox>(finder);
      final rect = renderBox.selectionBrushWidgetRect!;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      final start = origin + rect.center;
      final end = start + const Offset(36, 0);
      await gesture.moveTo(start);
      await tester.pump();
      expect(
        renderBox.debugPointerCursorPosition!.dx,
        closeTo(rect.center.dx, 0.01),
      );

      await gesture.down(start);
      await gesture.moveTo(end);
      await tester.pump();
      renderBox = tester.renderObject<ChartRenderBox>(finder);
      expect(
        renderBox.debugPointerCursorPosition!.dx,
        closeTo(rect.center.dx + 36, 0.01),
        reason:
            'The hidden crosshair must follow the owned brush gesture instead '
            'of retaining its pointer-down X.',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      renderBox = tester.renderObject<ChartRenderBox>(finder);
      expect(
        renderBox.debugPointerCursorPosition!.dx,
        closeTo(rect.center.dx + 36, 0.01),
        reason:
            'Releasing the brush must reveal the crosshair at the release X.',
      );
    });

    testWidgets('the existing interval gesture remains transient by default', (
      tester,
    ) async {
      final controller = BravenChartController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller: controller));
      await tester.pumpAndSettle();

      final finder = _chartRenderFinder();
      final renderBox = tester.renderObject<ChartRenderBox>(finder);
      final origin = tester.getTopLeft(finder);
      final plot = renderBox.debugPlotArea;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      final start = origin + Offset(plot.left + 80, plot.center.dy);
      final end = origin + Offset(plot.left + 240, plot.center.dy);
      await gesture.moveTo(start);
      await gesture.down(start);
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.selectionExpression.isNotEmpty, isTrue);
      expect(controller.selectionBrushState, isNull);
      expect(
        tester.renderObject<ChartRenderBox>(finder).selectionBrushWidgetRect,
        isNull,
      );
    });

    testWidgets(
      'artifact extraction and hydration preserve current brush state',
      (tester) async {
        final sourceController = BravenChartController();
        final hydratedController = BravenChartController();
        addTearDown(sourceController.dispose);
        addTearDown(hydratedController.dispose);

        await tester.pumpWidget(
          _host(
            controller: sourceController,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
              style: ChartSelectionBrushStyle(
                fillColor: Color(0xFF123456),
                borderRadius: 6,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        sourceController.setSelectionBrush(
          minimum: 4,
          maximum: 8,
          visible: false,
        );
        await tester.pumpAndSettle();

        final snapshot = _documentSuccess(sourceController.extractDocument());
        expect(snapshot.viewState?.selectionBrush?.visible, isFalse);
        expect(snapshot.viewState?.selectionBrush?.range?.minimum, 4);
        final hydration = _hydrationSuccess(
          ChartDocumentHydrator.hydrateDocument(
            snapshot.document,
            viewState: snapshot.viewState,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 420,
                child: hydration.build(
                  bravenChartController: hydratedController,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          hydratedController.selectionBrushState,
          const ChartSelectionBrushState(
            acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
            range: ChartSelectionBrushRange(minimum: 4, maximum: 8),
            visible: false,
          ),
        );
        final reextracted = _documentSuccess(
          hydratedController.extractDocument(),
        );
        expect(
          reextracted.document.interaction.toJson().toString(),
          contains('selection'),
        );
      },
    );

    testWidgets(
      'explicit clear survives hydration while an older view state keeps initial state',
      (tester) async {
        final controller = BravenChartController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(
            controller: controller,
            brush: const ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 2, maximum: 6),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.restoreViewState(
          ChartViewState(
            selectionBrush: const ChartSelectionBrushViewState.cleared(),
          ),
        );
        await tester.pumpAndSettle();
        expect(controller.selectionBrushState, isNull);

        controller.restoreViewState(ChartViewState());
        await tester.pumpAndSettle();
        expect(
          controller.selectionBrushState,
          isNull,
          reason:
              'An older view state must not resurrect or overwrite runtime brush state.',
        );
      },
    );
  });
}

ChartDocumentSnapshot _documentSuccess(
  ChartArtifactResult<ChartDocumentSnapshot> result,
) {
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

HydratedChartConfiguration _hydrationSuccess(
  ChartArtifactResult<HydratedChartConfiguration> result,
) {
  expect(result, isA<ChartArtifactSuccess<HydratedChartConfiguration>>());
  return (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;
}

Widget _host({
  required BravenChartController controller,
  ChartSelectionBrushConfig brush = const ChartSelectionBrushConfig(),
  ChartSelectionAcquisitionMode acquisitionMode =
      ChartSelectionAcquisitionMode.xInterval,
  ValueChanged<ChartSelectionResult>? onSelectionResultChanged,
  double width = 640,
  TextDirection textDirection = TextDirection.ltr,
}) => MaterialApp(
  home: Directionality(
    textDirection: textDirection,
    child: Scaffold(
      body: SizedBox(
        width: width,
        height: 420,
        child: BravenChartPlus(
          bravenChartController: controller,
          showLegend: false,
          series: const [
            LineChartSeries(
              id: 'signal',
              showDataPointMarkers: true,
              points: [
                ChartDataPoint(x: 0, y: 20),
                ChartDataPoint(x: 2, y: 30),
                ChartDataPoint(x: 4, y: 40),
                ChartDataPoint(x: 6, y: 50),
                ChartDataPoint(x: 8, y: 60),
                ChartDataPoint(x: 10, y: 70),
              ],
            ),
          ],
          interactionConfig: InteractionConfig(
            selection: ChartSelectionConfig(
              acquisitionMode: acquisitionMode,
              useModifierKeys: false,
              brush: brush,
            ),
            onSelectionResultChanged: onSelectionResultChanged,
          ),
        ),
      ),
    ),
  ),
);

Widget _horizontalBarHost(BravenChartController controller) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 640,
      height: 420,
      child: BravenChartPlus(
        bravenChartController: controller,
        showLegend: false,
        series: const [
          BarChartSeries(
            id: 'volume',
            orientation: BarOrientation.horizontal,
            barWidthPercent: 0.7,
            points: [
              ChartDataPoint(x: 0, y: 30),
              ChartDataPoint(x: 1, y: 50),
              ChartDataPoint(x: 2, y: 70),
              ChartDataPoint(x: 3, y: 90),
            ],
          ),
        ],
        interactionConfig: const InteractionConfig(
          selection: ChartSelectionConfig(
            acquisitionMode: ChartSelectionAcquisitionMode.xInterval,
            useModifierKeys: false,
            brush: ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(minimum: 0, maximum: 1),
            ),
          ),
        ),
      ),
    ),
  ),
);

Widget _yReferenceHost(BravenChartController controller) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      width: 640,
      height: 420,
      child: BravenChartPlus(
        bravenChartController: controller,
        showLegend: false,
        series: const [
          LineChartSeries(
            id: 'signal',
            points: [
              ChartDataPoint(x: 0, y: 20),
              ChartDataPoint(x: 5, y: 40),
              ChartDataPoint(x: 10, y: 60),
            ],
          ),
          LineChartSeries(
            id: 'context',
            points: [
              ChartDataPoint(x: 0, y: 100),
              ChartDataPoint(x: 5, y: 120),
              ChartDataPoint(x: 10, y: 140),
            ],
          ),
        ],
        interactionConfig: const InteractionConfig(
          selection: ChartSelectionConfig(
            acquisitionMode: ChartSelectionAcquisitionMode.yInterval,
            useModifierKeys: false,
            brush: ChartSelectionBrushConfig(
              enabled: true,
              initialVisible: true,
              initialRange: ChartSelectionBrushRange(
                minimum: 30,
                maximum: 50,
                referenceSeriesId: 'signal',
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _chartRenderFinder() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_ChartRenderWidget',
);
