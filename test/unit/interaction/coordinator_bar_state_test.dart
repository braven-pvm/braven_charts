import 'package:braven_charts/src/interaction/core/coordinator.dart';
import 'package:braven_charts/src/interaction/core/interaction_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tracks pressed markers and clears them for viewport interaction', () {
    final coordinator = ChartInteractionCoordinator();
    addTearDown(coordinator.dispose);
    const marker = HoveredMarkerInfo(
      seriesId: 'actual',
      markerIndex: 3,
      plotPosition: Offset(24, 80),
    );

    coordinator.setPressedMarker(marker);
    expect(coordinator.pressedMarker, marker);

    coordinator.claimMode(InteractionMode.panning);
    expect(coordinator.pressedMarker, isNull);
  });

  test(
    'same pressed marker can update position without notifying listeners',
    () {
      final coordinator = ChartInteractionCoordinator();
      addTearDown(coordinator.dispose);
      var notifications = 0;
      coordinator.addListener(() => notifications++);

      coordinator.setPressedMarker(
        const HoveredMarkerInfo(
          seriesId: 'actual',
          markerIndex: 1,
          plotPosition: Offset(10, 20),
        ),
      );
      coordinator.setPressedMarker(
        const HoveredMarkerInfo(
          seriesId: 'actual',
          markerIndex: 1,
          plotPosition: Offset(12, 22),
        ),
      );

      expect(notifications, 1);
      expect(coordinator.pressedMarker?.plotPosition, const Offset(12, 22));
    },
  );
}
