import 'package:flutter_test/flutter_test.dart';

/// Contract test for scrollbar HitTestZone detection (leftEdge/rightEdge/center).
///
/// T079 [US3] - Tests that hit testing correctly identifies which zone of the handle
/// was clicked/hovered: left edge (for left resize), right edge (for right resize),
/// or center (for pan). This is foundational for zoom via edge resize.
///
/// Requirements from FR-011:
/// - Left edge zone: first 8px (edgeGripWidth) of handle
/// - Right edge zone: last 8px (edgeGripWidth) of handle
/// - Center zone: everything between edge zones
/// - MUST work for both horizontal and vertical scrollbars
void main() {
  group('ScrollbarHitTest - CONTRACT', () {
    test(
        'MUST detect left edge zone when hit within first edgeGripWidth pixels',
        () {
      // ARRANGE: Handle at position 100-200px, edgeGripWidth=8px
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const edgeGripWidth = 8.0;

      // ACT: Hit at position 105 (within first 8px of handle)
      const hitPosition = 105.0;

      // ASSERT: Should detect leftEdge zone
      final zone =
          _detectHitZone(hitPosition, handleStart, handleEnd, edgeGripWidth);
      expect(zone, equals(HitTestZone.leftEdge));
    });

    test(
        'MUST detect right edge zone when hit within last edgeGripWidth pixels',
        () {
      // ARRANGE: Handle at position 100-200px, edgeGripWidth=8px
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const edgeGripWidth = 8.0;

      // ACT: Hit at position 195 (within last 8px of handle)
      const hitPosition = 195.0;

      // ASSERT: Should detect rightEdge zone
      final zone =
          _detectHitZone(hitPosition, handleStart, handleEnd, edgeGripWidth);
      expect(zone, equals(HitTestZone.rightEdge));
    });

    test('MUST detect center zone when hit between edge zones', () {
      // ARRANGE: Handle at position 100-200px, edgeGripWidth=8px
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const edgeGripWidth = 8.0;

      // ACT: Hit at position 150 (middle of handle, between edges)
      const hitPosition = 150.0;

      // ASSERT: Should detect center zone
      final zone =
          _detectHitZone(hitPosition, handleStart, handleEnd, edgeGripWidth);
      expect(zone, equals(HitTestZone.center));
    });

    test(
        'MUST prioritize left edge over center when hit is exactly at boundary',
        () {
      // ARRANGE: Handle at position 100-200px, edgeGripWidth=8px
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const edgeGripWidth = 8.0;

      // ACT: Hit at position 108 (exactly at left edge boundary)
      const hitPosition = 108.0;

      // ASSERT: Should detect leftEdge (inclusive boundary)
      final zone =
          _detectHitZone(hitPosition, handleStart, handleEnd, edgeGripWidth);
      expect(zone, equals(HitTestZone.leftEdge));
    });

    test(
        'MUST prioritize right edge over center when hit is exactly at boundary',
        () {
      // ARRANGE: Handle at position 100-200px, edgeGripWidth=8px
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const edgeGripWidth = 8.0;

      // ACT: Hit at position 192 (exactly at right edge boundary)
      const hitPosition = 192.0;

      // ASSERT: Should detect rightEdge (inclusive boundary)
      final zone =
          _detectHitZone(hitPosition, handleStart, handleEnd, edgeGripWidth);
      expect(zone, equals(HitTestZone.rightEdge));
    });

    test('MUST handle minimum-sized handle (both edges overlap)', () {
      // ARRANGE: Handle at position 100-120px (size=20px), edgeGripWidth=8px
      // Total edgeGripWidth: 8 + 8 = 16px, handle size = 20px, center zone = 4px
      const handleStart = 100.0;
      const handleEnd = 120.0;
      const edgeGripWidth = 8.0;

      // ACT & ASSERT: Left edge zone (100-108)
      expect(_detectHitZone(105.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone.leftEdge));

      // ACT & ASSERT: Small center zone (108-112)
      expect(_detectHitZone(110.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone.center));

      // ACT & ASSERT: Right edge zone (112-120)
      expect(_detectHitZone(115.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone.rightEdge));
    });

    test('MUST return none when hit is outside handle bounds', () {
      // ARRANGE: Handle at position 100-200px
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const edgeGripWidth = 8.0;

      // ACT & ASSERT: Hit before handle start
      expect(_detectHitZone(50.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone.none));

      // ACT & ASSERT: Hit after handle end
      expect(_detectHitZone(250.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone.none));
    });

    test('MUST work for vertical scrollbar (hit on Y-axis)', () {
      // ARRANGE: Vertical handle at Y position 200-300px
      const handleStart = 200.0;
      const handleEnd = 300.0;
      const edgeGripWidth = 8.0;

      // ACT & ASSERT: Top edge (leftEdge in horizontal becomes topEdge in vertical)
      expect(
          _detectHitZone(205.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone
              .leftEdge)); // "leftEdge" represents "topEdge" for vertical

      // ACT & ASSERT: Bottom edge
      expect(
          _detectHitZone(295.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone
              .rightEdge)); // "rightEdge" represents "bottomEdge" for vertical

      // ACT & ASSERT: Center
      expect(_detectHitZone(250.0, handleStart, handleEnd, edgeGripWidth),
          equals(HitTestZone.center));
    });
  });
}

/// Enum representing hit test zones within scrollbar handle.
enum HitTestZone {
  none, // Outside handle
  leftEdge, // First edgeGripWidth pixels (or top edge for vertical)
  center, // Between edge zones
  rightEdge, // Last edgeGripWidth pixels (or bottom edge for vertical)
}

/// Detect which zone of the scrollbar handle was hit.
///
/// This is the contract being tested - implementation will go in ScrollbarState.
HitTestZone _detectHitZone(
  double hitPosition,
  double handleStart,
  double handleEnd,
  double edgeGripWidth,
) {
  // Outside handle bounds
  if (hitPosition < handleStart || hitPosition > handleEnd) {
    return HitTestZone.none;
  }

  // Left edge zone: [handleStart, handleStart + edgeGripWidth]
  if (hitPosition <= handleStart + edgeGripWidth) {
    return HitTestZone.leftEdge;
  }

  // Right edge zone: [handleEnd - edgeGripWidth, handleEnd]
  if (hitPosition >= handleEnd - edgeGripWidth) {
    return HitTestZone.rightEdge;
  }

  // Center zone: everything between edges
  return HitTestZone.center;
}
