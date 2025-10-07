// Contract Interface: Gesture Recognizer
// Feature: Layer 7 Interaction System
// Requirement: FR-005 (Gesture Recognition)

/// Interface for recognizing touch gestures on charts.
///
/// Responsibilities:
/// - Recognize tap, double-tap, long-press, pinch, pan/swipe gestures
/// - Distinguish gesture types with >95% accuracy
/// - Implement gesture conflict resolution via priority system
/// - Handle gesture cancellation (e.g., incoming phone call)
/// - Work on iOS, Android, and touch-enabled web browsers
///
/// Performance Requirements:
/// - Tap recognized within 10ms of touch-up event
/// - Pinch vs pan distinguished correctly with >95% accuracy
/// - Long-press timer cancels if finger moves >10px
abstract class IGestureRecognizer {
  /// Recognizes gesture from pointer events.
  ///
  /// Called on each pointer event (down, move, up, cancel) to determine
  /// if a gesture is occurring and what type it is.
  ///
  /// Parameters:
  /// - [event]: Raw pointer event from Flutter
  /// - [state]: Current gesture recognition state
  ///
  /// Returns: GestureDetails if gesture recognized, null otherwise
  ///
  /// Performance: Must complete in <10ms
  GestureDetails? recognizeGesture(
    PointerEvent event,
    GestureRecognitionState state,
  );

  /// Starts tracking a potential gesture.
  ///
  /// Called on pointer down event.
  ///
  /// Parameters:
  /// - [position]: Initial touch position
  /// - [pointerCount]: Number of active pointers
  /// - [deviceKind]: Type of device (touch, mouse, stylus)
  ///
  /// Returns: New gesture recognition state
  GestureRecognitionState startGesture(
    Offset position,
    int pointerCount,
    PointerDeviceKind deviceKind,
  );

  /// Updates gesture tracking.
  ///
  /// Called on pointer move event.
  ///
  /// Parameters:
  /// - [state]: Current gesture state
  /// - [position]: New pointer position
  /// - [delta]: Movement delta from last position
  ///
  /// Returns: Updated gesture state (may change gesture type)
  GestureRecognitionState updateGesture(
    GestureRecognitionState state,
    Offset position,
    Offset delta,
  );

  /// Completes gesture tracking.
  ///
  /// Called on pointer up event.
  ///
  /// Parameters:
  /// - [state]: Current gesture state
  /// - [position]: Final pointer position
  ///
  /// Returns: Final GestureDetails
  GestureDetails completeGesture(
    GestureRecognitionState state,
    Offset position,
  );

  /// Cancels gesture tracking.
  ///
  /// Called on pointer cancel event (e.g., incoming call, system interrupt).
  ///
  /// Parameters:
  /// - [state]: Current gesture state
  void cancelGesture(GestureRecognitionState state);

  /// Resolves conflicts between multiple possible gestures.
  ///
  /// Priority rules:
  /// - Tap loses to pan if movement >10px within 300ms
  /// - Pan loses to pinch if second finger detected
  /// - Long-press wins if no movement for 500ms
  ///
  /// Parameters:
  /// - [candidates]: List of possible gesture types
  /// - [state]: Current gesture state
  ///
  /// Returns: Winning gesture type
  GestureType resolveConflict(
    List<GestureType> candidates,
    GestureRecognitionState state,
  );
}

/// Current state of gesture recognition.
class GestureRecognitionState {
  final Offset startPosition;
  final Offset currentPosition;
  final DateTime startTime;
  final int pointerCount;
  final PointerDeviceKind deviceKind;
  final List<GestureType> candidateGestures;
  final bool isComplete;
  final bool isCancelled;

  GestureRecognitionState({
    required this.startPosition,
    required this.currentPosition,
    required this.startTime,
    required this.pointerCount,
    required this.deviceKind,
    required this.candidateGestures,
    this.isComplete = false,
    this.isCancelled = false,
  });

  /// Distance moved from start position
  double get distance => (currentPosition - startPosition).distance;

  /// Duration since gesture started
  Duration get duration => DateTime.now().difference(startTime);
}

/// Gesture type enumeration.
enum GestureType {
  tap,
  doubleTap,
  longPress,
  pan,
  pinch,
  unknown,
}

/// Pointer device kind (from Flutter).
enum PointerDeviceKind {
  touch,
  mouse,
  stylus,
  trackpad,
  unknown,
}

/// Complete gesture information.
class GestureDetails {
  final GestureType type;
  final Offset startPosition;
  final Offset endPosition;
  final double? scale;        // For pinch gestures
  final Offset? delta;         // For pan gestures
  final Duration duration;
  final int pointerCount;
  final PointerDeviceKind deviceKind;

  GestureDetails({
    required this.type,
    required this.startPosition,
    required this.endPosition,
    this.scale,
    this.delta,
    required this.duration,
    required this.pointerCount,
    required this.deviceKind,
  });
}
