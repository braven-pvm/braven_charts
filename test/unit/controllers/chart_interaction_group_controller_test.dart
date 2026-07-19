import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/controllers/chart_interaction_group_controller.dart'
    show ChartInteractionGroupParticipant;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartInteractionGroupController', () {
    test('broadcasts finite data X to every cursor participant', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final firstValues = <double?>[];
      final secondValues = <double?>[];
      final first = group.attachChart(
        attachment: Object(),
        onCursorChanged: firstValues.add,
        onViewportChanged: (_) {},
      );
      final second = group.attachChart(
        attachment: Object(),
        onCursorChanged: secondValues.add,
        onViewportChanged: (_) {},
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      first.publishCursor(3.25);
      first.publishCursor(3.25);
      first.clearCursor();

      expect(firstValues, <double?>[3.25, null]);
      expect(secondValues, <double?>[3.25, null]);
      expect(group.cursorX, isNull);
    });

    test('rejects non-finite cursor values', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final participant = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: (_) {},
      );
      addTearDown(participant.dispose);

      expect(() => participant.publishCursor(double.nan), throwsArgumentError);
      expect(
        () => participant.publishCursor(double.infinity),
        throwsArgumentError,
      );
    });

    test('synchronizes X viewport values without a source feedback loop', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final firstValues = <ChartXViewport>[];
      final secondValues = <ChartXViewport>[];
      late ChartInteractionGroupParticipant second;
      final first = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: firstValues.add,
      );
      second = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: (viewport) {
          secondValues.add(viewport);
          second.publishViewport(viewport);
        },
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      first.publishViewport(const ChartXViewport(min: 2, max: 8));

      expect(firstValues, const [ChartXViewport(min: 2, max: 8)]);
      expect(secondValues, const [ChartXViewport(min: 2, max: 8)]);
      expect(group.viewport, const ChartXViewport(min: 2, max: 8));
    });

    test('host viewport command drives participants without a fake source', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final firstValues = <ChartXViewport>[];
      final secondValues = <ChartXViewport>[];
      final first = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: firstValues.add,
      );
      final second = group.attachChart(
        attachment: Object(),
        options: const ChartInteractionGroupOptions(synchronizeViewport: false),
        onCursorChanged: (_) {},
        onViewportChanged: secondValues.add,
      );
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      group.setViewport(const ChartXViewport(min: 4, max: 12));

      expect(firstValues, const [ChartXViewport(min: 4, max: 12)]);
      expect(secondValues, isEmpty);
      expect(group.viewport, const ChartXViewport(min: 4, max: 12));
      expect(
        () => group.setViewport(
          const ChartXViewport(
            min: double.negativeInfinity,
            max: double.infinity,
          ),
        ),
        throwsArgumentError,
      );
    });

    test('honors independent cursor and viewport opt-outs', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final cursorValues = <double?>[];
      final viewportValues = <ChartXViewport>[];
      final source = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: (_) {},
      );
      final cursorOptOut = group.attachChart(
        attachment: Object(),
        options: const ChartInteractionGroupOptions(synchronizeCursor: false),
        onCursorChanged: cursorValues.add,
        onViewportChanged: viewportValues.add,
      );
      final viewportOptOut = group.attachChart(
        attachment: Object(),
        options: const ChartInteractionGroupOptions(synchronizeViewport: false),
        onCursorChanged: cursorValues.add,
        onViewportChanged: viewportValues.add,
      );
      addTearDown(source.dispose);
      addTearDown(cursorOptOut.dispose);
      addTearDown(viewportOptOut.dispose);

      source.publishCursor(4);
      source.publishViewport(const ChartXViewport(min: 1, max: 6));

      expect(cursorValues, <double?>[4]);
      expect(viewportValues, const [ChartXViewport(min: 1, max: 6)]);
    });

    test('detached charts stop receiving and publishing immediately', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final values = <double?>[];
      final first = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: (_) {},
      );
      final second = group.attachChart(
        attachment: Object(),
        onCursorChanged: values.add,
        onViewportChanged: (_) {},
      );
      addTearDown(first.dispose);

      second.dispose();
      first.publishCursor(7);
      second.publishCursor(9);

      expect(values, isEmpty);
      expect(group.cursorX, 7);
    });

    test('new participants receive the current transient state', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final source = group.attachChart(
        attachment: Object(),
        onCursorChanged: (_) {},
        onViewportChanged: (_) {},
      );
      addTearDown(source.dispose);
      source.publishCursor(5);
      source.publishViewport(const ChartXViewport(min: 3, max: 9));
      final cursorValues = <double?>[];
      final viewportValues = <ChartXViewport>[];

      final lateParticipant = group.attachChart(
        attachment: Object(),
        onCursorChanged: cursorValues.add,
        onViewportChanged: viewportValues.add,
      );
      addTearDown(lateParticipant.dispose);

      expect(cursorValues, <double?>[5]);
      expect(viewportValues, const [ChartXViewport(min: 3, max: 9)]);
    });

    test('reset clears remembered state and active cursors', () {
      final group = ChartInteractionGroupController();
      addTearDown(group.dispose);
      final cursorValues = <double?>[];
      final participant = group.attachChart(
        attachment: Object(),
        onCursorChanged: cursorValues.add,
        onViewportChanged: (_) {},
      );
      addTearDown(participant.dispose);
      participant.publishCursor(5);
      participant.publishViewport(const ChartXViewport(min: 2, max: 8));

      group.reset();

      expect(group.cursorX, isNull);
      expect(group.viewport, isNull);
      expect(cursorValues, <double?>[5, null]);
    });
  });
}
