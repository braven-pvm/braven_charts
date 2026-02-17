import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for cursor changes at scrollbar handle edges.
///
/// T083 [US3] - Tests that cursor selection logic returns correct cursor type
/// when hovering over left/right edges of horizontal scrollbar handle or
/// top/bottom edges of vertical scrollbar handle.
///
/// Requirements from FR-011:
/// - Mouse cursor changes to ew-resize (↔) at left/right edges of horizontal handle
/// - Mouse cursor changes to ns-resize (↕) at top/bottom edges of vertical handle
/// - Mouse cursor remains grab when hovering over center of handle
/// - Edge zone width = 8px (from ScrollbarConfig.edgeGripWidth)
/// - Visual feedback that edges are interactive resize areas
///
/// This is a PURE LOGIC contract test - no widget rendering needed.
void main() {
  group('EdgeCursor - CONTRACT', () {
    test('MUST return ew-resize cursor at left edge of horizontal handle', () {
      // ARRANGE: Horizontal scrollbar handle at position 100-200 on 400px track
      const axis = Axis.horizontal;
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const mousePosition = 104.0; // Within 8px of left edge
      const edgeZoneWidth = 8.0;

      // ACT: Get cursor for position
      final cursor = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: mousePosition,
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor is ew-resize (horizontal resize)
      expect(cursor, equals(SystemMouseCursors.resizeLeftRight));
    });

    test('MUST return ew-resize cursor at right edge of horizontal handle', () {
      // ARRANGE: Horizontal scrollbar handle at position 100-200 on 400px track
      const axis = Axis.horizontal;
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const mousePosition =
          196.0; // Within 8px of right edge (200-8=192, 196>192)
      const edgeZoneWidth = 8.0;

      // ACT: Get cursor for position
      final cursor = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: mousePosition,
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor is ew-resize (horizontal resize)
      expect(cursor, equals(SystemMouseCursors.resizeLeftRight));
    });

    test('MUST return grab cursor at center of horizontal handle', () {
      // ARRANGE: Horizontal scrollbar handle at position 100-200 on 400px track
      const axis = Axis.horizontal;
      const handleStart = 100.0;
      const handleEnd = 200.0;
      const mousePosition = 150.0; // Center of handle
      const edgeZoneWidth = 8.0;

      // ACT: Get cursor for position
      final cursor = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: mousePosition,
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor is grab (for panning center)
      expect(cursor, equals(SystemMouseCursors.grab));
    });

    test('MUST return ns-resize cursor at top edge of vertical handle', () {
      // ARRANGE: Vertical scrollbar handle at position 50-150 on 300px track
      const axis = Axis.vertical;
      const handleStart = 50.0;
      const handleEnd = 150.0;
      const mousePosition = 54.0; // Within 8px of top edge
      const edgeZoneWidth = 8.0;

      // ACT: Get cursor for position
      final cursor = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: mousePosition,
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor is ns-resize (vertical resize)
      expect(cursor, equals(SystemMouseCursors.resizeUpDown));
    });

    test('MUST return ns-resize cursor at bottom edge of vertical handle', () {
      // ARRANGE: Vertical scrollbar handle at position 50-150 on 300px track
      const axis = Axis.vertical;
      const handleStart = 50.0;
      const handleEnd = 150.0;
      const mousePosition =
          146.0; // Within 8px of bottom edge (150-8=142, 146>142)
      const edgeZoneWidth = 8.0;

      // ACT: Get cursor for position
      final cursor = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: mousePosition,
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor is ns-resize (vertical resize)
      expect(cursor, equals(SystemMouseCursors.resizeUpDown));
    });

    test('MUST return grab cursor at center of vertical handle', () {
      // ARRANGE: Vertical scrollbar handle at position 50-150 on 300px track
      const axis = Axis.vertical;
      const handleStart = 50.0;
      const handleEnd = 150.0;
      const mousePosition = 100.0; // Center of handle
      const edgeZoneWidth = 8.0;

      // ACT: Get cursor for position
      final cursor = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: mousePosition,
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor is grab (for panning center)
      expect(cursor, equals(SystemMouseCursors.grab));
    });

    test('MUST transition cursor correctly across edge zone boundaries', () {
      // ARRANGE: Horizontal handle 0-100, test boundary positions
      const axis = Axis.horizontal;
      const handleStart = 0.0;
      const handleEnd = 100.0;
      const edgeZoneWidth = 8.0;

      // ACT: Test positions at boundary transitions
      final cursor7_9 = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: 7.9, // Just inside left edge zone
        edgeZoneWidth: edgeZoneWidth,
      );

      final cursor8_1 = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: 8.1, // Just outside left edge zone (center)
        edgeZoneWidth: edgeZoneWidth,
      );

      final cursor91_9 = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: 91.9, // Just outside right edge zone (center)
        edgeZoneWidth: edgeZoneWidth,
      );

      final cursor92_1 = _getCursorForPosition(
        axis: axis,
        handleStart: handleStart,
        handleEnd: handleEnd,
        mousePosition: 92.1, // Just inside right edge zone
        edgeZoneWidth: edgeZoneWidth,
      );

      // ASSERT: Cursor transitions correctly
      expect(
        cursor7_9,
        equals(SystemMouseCursors.resizeLeftRight),
      ); // Left edge
      expect(cursor8_1, equals(SystemMouseCursors.grab)); // Center
      expect(cursor91_9, equals(SystemMouseCursors.grab)); // Center
      expect(
        cursor92_1,
        equals(SystemMouseCursors.resizeLeftRight),
      ); // Right edge
    });
  });
}

/// Detect which cursor to show based on mouse position within handle.
///
/// This is the contract being tested - implementation will go in ScrollbarController.
MouseCursor _getCursorForPosition({
  required Axis axis,
  required double handleStart,
  required double handleEnd,
  required double mousePosition,
  required double edgeZoneWidth,
}) {
  // Convert mouse position to position within handle (0 = start, size = end)
  final positionInHandle = mousePosition - handleStart;
  final handleSize = handleEnd - handleStart;

  // Check if in left/top edge zone
  if (positionInHandle < edgeZoneWidth) {
    return axis == Axis.horizontal
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;
  }

  // Check if in right/bottom edge zone
  if (positionInHandle > handleSize - edgeZoneWidth) {
    return axis == Axis.horizontal
        ? SystemMouseCursors.resizeLeftRight
        : SystemMouseCursors.resizeUpDown;
  }

  // In center zone - use grab cursor for panning
  return SystemMouseCursors.grab;
}
