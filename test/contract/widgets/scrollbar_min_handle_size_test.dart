import 'package:flutter_test/flutter_test.dart';

/// Contract test for minimum handle size clamping during zoom.
///
/// T082 [US3] - Tests that handle size never shrinks below minHandleSize even when
/// viewport ratio would calculate a smaller handle. This ensures handle remains
/// grabbable at extreme zoom levels.
///
/// Requirements from FR-011:
/// - Handle size = max(trackLength * viewportRatio, minHandleSize)
/// - minHandleSize default = 20px (from ScrollbarConfig)
/// - MUST enforce minimum even when zoomed to 1% (minZoomRatio)
/// - Handle position must adjust to keep viewport representation accurate
void main() {
  group('ScrollbarMinHandleSize - CONTRACT', () {
    test(
        'MUST use calculated size when viewport ratio yields handle >= minHandleSize',
        () {
      // ARRANGE: Track 400px, viewport 20% of data, minHandleSize 20px
      const trackLength = 400.0;
      const viewportRatio = 0.2; // 20% of data visible
      const minHandleSize = 20.0;

      // ACT: Calculate handle size
      final handleSize = _calculateHandleSize(
        trackLength: trackLength,
        viewportRatio: viewportRatio,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Uses calculated size (80px) since it's >= minHandleSize
      expect(handleSize, equals(80.0)); // 400 * 0.2 = 80px
    });

    test(
        'MUST clamp to minHandleSize when viewport ratio yields handle < minHandleSize',
        () {
      // ARRANGE: Track 400px, viewport 1% of data, minHandleSize 20px
      const trackLength = 400.0;
      const viewportRatio = 0.01; // 1% of data visible (extreme zoom)
      const minHandleSize = 20.0;

      // ACT: Calculate handle size
      final handleSize = _calculateHandleSize(
        trackLength: trackLength,
        viewportRatio: viewportRatio,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Clamped to minHandleSize (20px) instead of calculated 4px
      expect(handleSize, equals(20.0)); // max(400 * 0.01, 20) = max(4, 20) = 20
    });

    test('MUST enforce minHandleSize at extreme zoom (0.5% viewport)', () {
      // ARRANGE: Track 400px, viewport 0.5% of data, minHandleSize 20px
      const trackLength = 400.0;
      const viewportRatio = 0.005; // 0.5% of data visible
      const minHandleSize = 20.0;

      // ACT: Calculate handle size
      final handleSize = _calculateHandleSize(
        trackLength: trackLength,
        viewportRatio: viewportRatio,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Clamped to minHandleSize (20px) instead of calculated 2px
      expect(
          handleSize, equals(20.0)); // max(400 * 0.005, 20) = max(2, 20) = 20
    });

    test('MUST adjust handle position when clamped to minHandleSize', () {
      // ARRANGE: Track 400px, viewport 1% at position 0-1 on data 0-100, minHandleSize 20px
      const trackLength = 400.0;
      const dataMin = 0.0;
      const dataMax = 100.0;
      const viewportMin = 0.0;
      const viewportMax = 1.0; // 1% visible
      const minHandleSize = 20.0;

      // ACT: Calculate handle geometry
      final geometry = _calculateHandleGeometry(
        trackLength: trackLength,
        dataMin: dataMin,
        dataMax: dataMax,
        viewportMin: viewportMin,
        viewportMax: viewportMax,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Handle clamped to minHandleSize
      expect(geometry.size, equals(20.0)); // Clamped from 4px

      // ASSERT: Handle start position still represents viewport position
      // Viewport at 0% of data → handle at 0px of track
      expect(geometry.start, equals(0.0));

      // ASSERT: Handle end = start + size (may extend beyond viewport representation)
      expect(geometry.end, equals(20.0)); // 0 + 20 = 20
    });

    test('MUST allow handle position to slide along track when clamped', () {
      // ARRANGE: Track 400px, viewport 1% at position 50-51 on data 0-100, minHandleSize 20px
      const trackLength = 400.0;
      const dataMin = 0.0;
      const dataMax = 100.0;
      const viewportMin = 50.0;
      const viewportMax = 51.0; // 1% visible at 50% position
      const minHandleSize = 20.0;

      // ACT: Calculate handle geometry
      final geometry = _calculateHandleGeometry(
        trackLength: trackLength,
        dataMin: dataMin,
        dataMax: dataMax,
        viewportMin: viewportMin,
        viewportMax: viewportMax,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Handle clamped to minHandleSize
      expect(geometry.size, equals(20.0));

      // ASSERT: Handle start position represents viewport center at 50%
      // Viewport center at 50.5% → handle center at 202px (50.5% of 400)
      // Handle start = center - size/2 = 202 - 10 = 192
      expect(geometry.start, equals(192.0));
      expect(geometry.end, equals(212.0)); // 192 + 20 = 212
    });

    test('MUST prevent handle from exceeding track bounds when clamped', () {
      // ARRANGE: Track 400px, viewport 1% at position 99-100 on data 0-100, minHandleSize 20px
      const trackLength = 400.0;
      const dataMin = 0.0;
      const dataMax = 100.0;
      const viewportMin = 99.0;
      const viewportMax = 100.0; // 1% visible at far right
      const minHandleSize = 20.0;

      // ACT: Calculate handle geometry
      final geometry = _calculateHandleGeometry(
        trackLength: trackLength,
        dataMin: dataMin,
        dataMax: dataMax,
        viewportMin: viewportMin,
        viewportMax: viewportMax,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Handle clamped to minHandleSize
      expect(geometry.size, equals(20.0));

      // ASSERT: Handle end clamped to track end
      expect(geometry.end, equals(400.0)); // At track boundary

      // ASSERT: Handle start adjusted to keep size consistent
      expect(geometry.start, equals(380.0)); // 400 - 20 = 380
    });

    test('MUST work for vertical scrollbar (same logic on Y-axis)', () {
      // ARRANGE: Vertical track 300px, viewport 2% at position 25-27 on data 0-100
      const trackLength = 300.0;
      const dataMin = 0.0;
      const dataMax = 100.0;
      const viewportMin = 25.0;
      const viewportMax = 27.0; // 2% visible
      const minHandleSize = 20.0;

      // ACT: Calculate handle geometry (Y-axis)
      final geometry = _calculateHandleGeometry(
        trackLength: trackLength,
        dataMin: dataMin,
        dataMax: dataMax,
        viewportMin: viewportMin,
        viewportMax: viewportMax,
        minHandleSize: minHandleSize,
      );

      // ASSERT: Handle clamped to minHandleSize
      expect(geometry.size, equals(20.0)); // Clamped from 6px (300 * 0.02 = 6)

      // ASSERT: Handle positioned at viewport center (26% of data)
      // Center at 26% → 78px on 300px track
      // Start = 78 - 10 = 68px
      expect(geometry.start, equals(68.0));
      expect(geometry.end, equals(88.0));
    });
  });
}

/// Handle geometry after size calculation and clamping.
class HandleGeometry {
  const HandleGeometry(this.start, this.size);

  final double start;
  final double size;

  double get end => start + size;
}

/// Calculate handle size with minHandleSize clamping.
///
/// This is the contract being tested - implementation will go in ScrollbarController.
double _calculateHandleSize({
  required double trackLength,
  required double viewportRatio, // 0.0 to 1.0 (percentage of data visible)
  required double minHandleSize,
}) {
  final calculatedSize = trackLength * viewportRatio;
  return calculatedSize.clamp(minHandleSize, trackLength);
}

/// Calculate complete handle geometry including position and size.
///
/// This is the contract being tested - implementation will go in ScrollbarController.
HandleGeometry _calculateHandleGeometry({
  required double trackLength,
  required double dataMin,
  required double dataMax,
  required double viewportMin,
  required double viewportMax,
  required double minHandleSize,
}) {
  final dataSpan = dataMax - dataMin;
  final viewportSpan = viewportMax - viewportMin;
  final viewportRatio = viewportSpan / dataSpan;

  // Calculate handle size with clamping
  final handleSize = _calculateHandleSize(
    trackLength: trackLength,
    viewportRatio: viewportRatio,
    minHandleSize: minHandleSize,
  );

  // Calculate viewport center position (0.0 to 1.0)
  final viewportCenter = (viewportMin + viewportMax) / 2.0;
  final centerRatio = (viewportCenter - dataMin) / dataSpan;

  // Calculate handle center position on track
  final handleCenter = trackLength * centerRatio;

  // Calculate handle start position (center - half size)
  var handleStart = handleCenter - (handleSize / 2.0);

  // Clamp handle to track boundaries
  handleStart = handleStart.clamp(0.0, trackLength - handleSize);

  return HandleGeometry(handleStart, handleSize);
}
