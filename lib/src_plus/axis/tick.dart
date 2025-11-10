// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Axis System

/// Represents a tick mark on an axis.
///
/// Each tick has a data value and a formatted label for display.
class Tick {
  /// The data value at this tick position.
  final double value;

  /// The formatted label to display for this tick.
  final String label;

  /// Whether this is a major tick (larger mark, always labeled).
  ///
  /// Minor ticks can be used for finer graduations without labels.
  final bool isMajor;

  const Tick({
    required this.value,
    required this.label,
    this.isMajor = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tick && runtimeType == other.runtimeType && value == other.value && label == other.label && isMajor == other.isMajor;

  @override
  int get hashCode => Object.hash(value, label, isMajor);

  @override
  String toString() => 'Tick(value: $value, label: "$label", major: $isMajor)';
}
