/// Interaction zones within scrollbar for hit testing.
///
/// Determines which part of the scrollbar the pointer is over,
/// affecting cursor appearance and interaction behavior.
enum HitTestZone {
  /// Left edge of horizontal scrollbar (first edgeGripWidth pixels).
  ///
  /// Dragging adjusts viewportMin, keeping viewportMax fixed (zoom in/out left side).
  /// Cursor: SystemMouseCursors.resizeColumn
  leftEdge,

  /// Right edge of horizontal scrollbar (last edgeGripWidth pixels).
  ///
  /// Dragging adjusts viewportMax, keeping viewportMin fixed (zoom in/out right side).
  /// Cursor: SystemMouseCursors.resizeColumn
  rightEdge,

  /// Top edge of vertical scrollbar (first edgeGripWidth pixels).
  ///
  /// Dragging adjusts viewportMin, keeping viewportMax fixed.
  /// Cursor: SystemMouseCursors.resizeRow
  topEdge,

  /// Bottom edge of vertical scrollbar (last edgeGripWidth pixels).
  ///
  /// Dragging adjusts viewportMax, keeping viewportMin fixed.
  /// Cursor: SystemMouseCursors.resizeRow
  bottomEdge,

  /// Center of scrollbar handle (between edge zones).
  ///
  /// Dragging pans viewport (shifts both min and max by same delta).
  /// Cursor: SystemMouseCursors.grab
  center,

  /// Track area outside handle.
  ///
  /// Clicking jumps viewport to center around click position.
  /// Cursor: SystemMouseCursors.click
  track,
}
