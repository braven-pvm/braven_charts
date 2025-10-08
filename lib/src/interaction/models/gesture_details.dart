/// Gesture details model for tracking user gestures.
///
/// Captures information about tap, pan, pinch, and long press gestures
/// including positions, deltas, scale, timestamps, and calculated properties.
///
/// This model is immutable.
library;

import 'dart:ui' show Offset;

/// Types of gestures that can be recognized.
enum GestureType {
  /// A single tap or click.
  tap,

  /// A pan or drag gesture.
  pan,

  /// A pinch or zoom gesture (multi-touch).
  pinch,

  /// A long press gesture.
  longPress,
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
  /// Creates gesture details with the specified properties.
  const GestureDetails({
    required this.type,
    required this.startPosition,
    required this.currentPosition,
    this.delta = Offset.zero,
    this.scale = 1.0,
    this.pointerCount = 1,
    required this.startTime,
    this.endTime,
  }) : assert(pointerCount > 0, 'pointerCount must be greater than 0'),
       assert(
         type != GestureType.pinch || pointerCount >= 2,
         'Pinch gesture requires at least 2 pointers',
       );

  /// Creates gesture details for a tap gesture.
  factory GestureDetails.tap({
    required Offset position,
    required DateTime timestamp,
  }) {
    return GestureDetails(
      type: GestureType.tap,
      startPosition: position,
      currentPosition: position,
      startTime: timestamp,
      endTime: timestamp,
    );
  }

  /// Creates gesture details for a pan gesture.
  factory GestureDetails.pan({
    required Offset startPosition,
    required Offset currentPosition,
    required Offset delta,
    required DateTime startTime,
    DateTime? endTime,
  }) {
    return GestureDetails(
      type: GestureType.pan,
      startPosition: startPosition,
      currentPosition: currentPosition,
      delta: delta,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Creates gesture details for a pinch gesture.
  factory GestureDetails.pinch({
    required Offset startPosition,
    required Offset currentPosition,
    required double scale,
    required int pointerCount,
    required DateTime startTime,
    DateTime? endTime,
  }) {
    return GestureDetails(
      type: GestureType.pinch,
      startPosition: startPosition,
      currentPosition: currentPosition,
      scale: scale,
      pointerCount: pointerCount,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Creates gesture details for a long press gesture.
  factory GestureDetails.longPress({
    required Offset position,
    required DateTime startTime,
    DateTime? endTime,
  }) {
    return GestureDetails(
      type: GestureType.longPress,
      startPosition: position,
      currentPosition: position,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// The type of gesture.
  final GestureType type;

  /// The starting position of the gesture.
  final Offset startPosition;

  /// The current position of the gesture.
  ///
  /// For completed gestures, this is the final position.
  final Offset currentPosition;

  /// The delta (change) in position for pan gestures.
  ///
  /// Zero for non-pan gestures.
  final Offset delta;

  /// The scale factor for pinch gestures.
  ///
  /// 1.0 for non-pinch gestures. Values > 1.0 indicate zoom in,
  /// values < 1.0 indicate zoom out.
  final double scale;

  /// The number of pointers (fingers/touches) involved in the gesture.
  ///
  /// Must be >= 2 for pinch gestures, typically 1 for others.
  final int pointerCount;

  /// The time when the gesture started.
  final DateTime startTime;

  /// The time when the gesture ended.
  ///
  /// Null for ongoing gestures.
  final DateTime? endTime;

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
      'startPosition': {
        'dx': startPosition.dx,
        'dy': startPosition.dy,
      },
      'currentPosition': {
        'dx': currentPosition.dx,
        'dy': currentPosition.dy,
      },
      'delta': {
        'dx': delta.dx,
        'dy': delta.dy,
      },
      'scale': scale,
      'pointerCount': pointerCount,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  /// Creates gesture details from a JSON map.
  factory GestureDetails.fromJson(Map<String, dynamic> json) {
    return GestureDetails(
      type: GestureType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      startPosition: Offset(
        (json['startPosition']['dx'] as num).toDouble(),
        (json['startPosition']['dy'] as num).toDouble(),
      ),
      currentPosition: Offset(
        (json['currentPosition']['dx'] as num).toDouble(),
        (json['currentPosition']['dy'] as num).toDouble(),
      ),
      delta: Offset(
        (json['delta']['dx'] as num).toDouble(),
        (json['delta']['dy'] as num).toDouble(),
      ),
      scale: (json['scale'] as num).toDouble(),
      pointerCount: json['pointerCount'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GestureDetails &&
        other.type == type &&
        other.startPosition == startPosition &&
        other.currentPosition == currentPosition &&
        other.delta == delta &&
        other.scale == scale &&
        other.pointerCount == pointerCount &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      startPosition,
      currentPosition,
      delta,
      scale,
      pointerCount,
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
