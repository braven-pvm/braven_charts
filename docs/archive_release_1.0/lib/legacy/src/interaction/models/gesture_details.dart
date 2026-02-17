/// Gesture details model for tracking user gestures.
///
/// Captures information about tap, pan, pinch, and long press gestures
/// including positions, deltas, scale, timestamps, and calculated properties.
///
/// This model is immutable.
library;

import 'dart:ui' show Offset, PointerDeviceKind;

/// Types of gestures that can be recognized.
enum GestureType {
  /// A single tap or click.
  tap,

  /// A double tap or double click.
  doubleTap,

  /// A long press gesture.
  longPress,

  /// A pan or drag gesture.
  pan,

  /// A pinch or zoom gesture (multi-touch).
  pinch,
}

/// Represents the details of a user gesture.
///
/// This immutable model captures all relevant information about a gesture
/// including type, positions, timing, and calculated properties like
/// distance, duration, and velocity.
///
/// Example:
/// ```dart
/// final tapGesture = GestureDetails.tap(
///   position: Offset(100, 200),
///   timestamp: DateTime.now(),
/// );
///
/// final panGesture = GestureDetails.pan(
///   startPosition: Offset(100, 200),
///   currentPosition: Offset(150, 250),
///   delta: Offset(50, 50),
/// );
/// ```
class GestureDetails {
  /// Creates gesture details from a JSON map.
  factory GestureDetails.fromJson(Map<String, dynamic> json) {
    return GestureDetails(
      type: GestureType.values.firstWhere((e) => e.name == json['type']),
      startPosition: Offset(
        (json['startPosition']['dx'] as num).toDouble(),
        (json['startPosition']['dy'] as num).toDouble(),
      ),
      currentPosition: Offset(
        (json['currentPosition']['dx'] as num).toDouble(),
        (json['currentPosition']['dy'] as num).toDouble(),
      ),
      endPosition: json['endPosition'] != null
          ? Offset(
              (json['endPosition']['dx'] as num).toDouble(),
              (json['endPosition']['dy'] as num).toDouble(),
            )
          : null,
      initialScale: (json['initialScale'] as num?)?.toDouble(),
      currentScale: (json['currentScale'] as num?)?.toDouble(),
      panDelta: json['panDelta'] != null
          ? Offset(
              (json['panDelta']['dx'] as num).toDouble(),
              (json['panDelta']['dy'] as num).toDouble(),
            )
          : null,
      totalPanDelta: json['totalPanDelta'] != null
          ? Offset(
              (json['totalPanDelta']['dx'] as num).toDouble(),
              (json['totalPanDelta']['dy'] as num).toDouble(),
            )
          : null,
      pointerCount: json['pointerCount'] as int? ?? 1,
      deviceKind: PointerDeviceKind.values.firstWhere(
        (e) => e.name == json['deviceKind'],
        orElse: () => PointerDeviceKind.mouse,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  /// Creates gesture details with the specified properties.
  const GestureDetails({
    required this.type,
    required this.startPosition,
    required this.currentPosition,
    this.endPosition,
    this.initialScale,
    this.currentScale,
    this.panDelta,
    this.totalPanDelta,
    required this.startTime,
    this.endTime,
    this.pointerCount = 1,
    this.deviceKind = PointerDeviceKind.mouse,
  }) : assert(pointerCount > 0, 'pointerCount must be greater than 0'),
       assert(
         type != GestureType.pinch || pointerCount >= 2,
         'Pinch gesture requires at least 2 pointers',
       ),
       assert(
         type != GestureType.pinch ||
             (initialScale != null && currentScale != null),
         'Pinch gesture requires initialScale and currentScale',
       ),
       assert(
         type != GestureType.pan || (panDelta != null && totalPanDelta != null),
         'Pan gesture requires panDelta and totalPanDelta',
       ),
       assert(
         endPosition == null || endTime != null,
         'endPosition requires endTime (completed gesture)',
       );

  /// Creates gesture details for a tap gesture.
  factory GestureDetails.tap({
    required Offset position,
    required DateTime timestamp,
    PointerDeviceKind deviceKind = PointerDeviceKind.mouse,
  }) {
    return GestureDetails(
      type: GestureType.tap,
      startPosition: position,
      currentPosition: position,
      endPosition: position,
      startTime: timestamp,
      endTime: timestamp,
      deviceKind: deviceKind,
    );
  }

  /// Creates gesture details for a pan gesture.
  factory GestureDetails.pan({
    required Offset startPosition,
    required Offset currentPosition,
    required Offset delta,
    required Offset totalDelta,
    required DateTime startTime,
    DateTime? endTime,
    Offset? endPosition,
    PointerDeviceKind deviceKind = PointerDeviceKind.mouse,
  }) {
    return GestureDetails(
      type: GestureType.pan,
      startPosition: startPosition,
      currentPosition: currentPosition,
      endPosition: endPosition,
      panDelta: delta,
      totalPanDelta: totalDelta,
      startTime: startTime,
      endTime: endTime,
      deviceKind: deviceKind,
    );
  }

  /// Creates gesture details for a pinch gesture.
  factory GestureDetails.pinch({
    required Offset startPosition,
    required Offset currentPosition,
    required double initialScale,
    required double currentScale,
    required int pointerCount,
    required DateTime startTime,
    DateTime? endTime,
    Offset? endPosition,
    PointerDeviceKind deviceKind = PointerDeviceKind.touch,
  }) {
    return GestureDetails(
      type: GestureType.pinch,
      startPosition: startPosition,
      currentPosition: currentPosition,
      endPosition: endPosition,
      initialScale: initialScale,
      currentScale: currentScale,
      pointerCount: pointerCount,
      startTime: startTime,
      endTime: endTime,
      deviceKind: deviceKind,
    );
  }

  /// Creates gesture details for a long press gesture.
  factory GestureDetails.longPress({
    required Offset position,
    required DateTime startTime,
    DateTime? endTime,
    PointerDeviceKind deviceKind = PointerDeviceKind.mouse,
  }) {
    return GestureDetails(
      type: GestureType.longPress,
      startPosition: position,
      currentPosition: position,
      endPosition: endTime != null ? position : null,
      startTime: startTime,
      endTime: endTime,
      deviceKind: deviceKind,
    );
  }

  /// The type of gesture.
  final GestureType type;

  /// The starting position of the gesture in screen coordinates.
  final Offset startPosition;

  /// The current position of the gesture in screen coordinates.
  ///
  /// For completed gestures, this is the final position.
  final Offset currentPosition;

  /// The ending position of the gesture in screen coordinates.
  ///
  /// Null for ongoing gestures.
  final Offset? endPosition;

  /// The initial scale/distance for pinch gestures.
  ///
  /// Null for non-pinch gestures.
  final double? initialScale;

  /// The current scale for pinch gestures (currentDistance / initialDistance).
  ///
  /// Null for non-pinch gestures. Values > 1.0 indicate zoom in,
  /// values < 1.0 indicate zoom out.
  final double? currentScale;

  /// The delta (change) from the last pan update.
  ///
  /// Null for non-pan gestures.
  final Offset? panDelta;

  /// The total delta from the start of the pan gesture.
  ///
  /// Null for non-pan gestures.
  final Offset? totalPanDelta;

  /// The time when the gesture started.
  final DateTime startTime;

  /// The time when the gesture ended.
  ///
  /// Null for ongoing gestures.
  final DateTime? endTime;

  /// The number of pointers (fingers/touches) involved in the gesture.
  ///
  /// Must be >= 2 for pinch gestures, typically 1 for others.
  final int pointerCount;

  /// The type of pointer device (mouse, touch, stylus, trackpad).
  final PointerDeviceKind deviceKind;

  /// The distance traveled from start to current position.
  ///
  /// Calculated as the Euclidean distance between [startPosition] and [currentPosition].
  double get distance {
    final dx = currentPosition.dx - startPosition.dx;
    final dy = currentPosition.dy - startPosition.dy;
    return (dx * dx + dy * dy).squareRoot;
  }

  /// The duration of the gesture.
  ///
  /// If [endTime] is null (ongoing gesture), uses the current time.
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// The average velocity of the gesture in pixels per second.
  ///
  /// Returns zero if duration is zero.
  double get velocity {
    final durationSeconds = duration.inMicroseconds / 1000000.0;
    if (durationSeconds == 0) return 0;
    return distance / durationSeconds;
  }

  /// Whether the gesture has completed.
  bool get isCompleted => endTime != null;

  /// Converts this gesture details to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'startPosition': {'dx': startPosition.dx, 'dy': startPosition.dy},
      'currentPosition': {'dx': currentPosition.dx, 'dy': currentPosition.dy},
      'endPosition': endPosition != null
          ? {'dx': endPosition!.dx, 'dy': endPosition!.dy}
          : null,
      'initialScale': initialScale,
      'currentScale': currentScale,
      'panDelta': panDelta != null
          ? {'dx': panDelta!.dx, 'dy': panDelta!.dy}
          : null,
      'totalPanDelta': totalPanDelta != null
          ? {'dx': totalPanDelta!.dx, 'dy': totalPanDelta!.dy}
          : null,
      'pointerCount': pointerCount,
      'deviceKind': deviceKind.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GestureDetails &&
        other.type == type &&
        other.startPosition == startPosition &&
        other.currentPosition == currentPosition &&
        other.endPosition == endPosition &&
        other.initialScale == initialScale &&
        other.currentScale == currentScale &&
        other.panDelta == panDelta &&
        other.totalPanDelta == totalPanDelta &&
        other.pointerCount == pointerCount &&
        other.deviceKind == deviceKind &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      startPosition,
      currentPosition,
      endPosition,
      initialScale,
      currentScale,
      panDelta,
      totalPanDelta,
      pointerCount,
      deviceKind,
      startTime,
      endTime,
    );
  }
}

/// Extension to add a square root method to double.
extension on double {
  double get squareRoot {
    if (this < 0) return 0;
    // Simple Newton-Raphson implementation
    if (this == 0) return 0;
    double x = this;
    double prev;
    do {
      prev = x;
      x = (x + this / x) / 2;
    } while ((x - prev).abs() > 1e-10);
    return x;
  }
}
