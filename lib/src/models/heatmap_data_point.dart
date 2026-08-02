// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import '../meta/chart_surface.dart';
import 'chart_data_point.dart';
import 'segment_style.dart';

/// An explicit rectangular Heatmap cell in Cartesian data space.
///
/// The minimum and maximum values are closed bounds. Both axes require a
/// positive finite extent.
final class HeatmapCellBounds {
  HeatmapCellBounds({
    required this.xMinimum,
    required this.xMaximum,
    required this.yMinimum,
    required this.yMaximum,
  }) {
    _validateRange(xMinimum, xMaximum, 'x');
    _validateRange(yMinimum, yMaximum, 'y');
  }

  final double xMinimum;
  final double xMaximum;
  final double yMinimum;
  final double yMaximum;

  bool contains(double x, double y) =>
      x >= xMinimum && x <= xMaximum && y >= yMinimum && y <= yMaximum;

  static void _validateRange(double minimum, double maximum, String axis) {
    if (!minimum.isFinite) {
      throw ArgumentError.value(
        minimum,
        'heatmap.bounds.${axis}Minimum',
        'must be finite',
      );
    }
    if (!maximum.isFinite) {
      throw ArgumentError.value(
        maximum,
        'heatmap.bounds.${axis}Maximum',
        'must be finite',
      );
    }
    if (minimum >= maximum) {
      throw ArgumentError(
        'heatmap.bounds.${axis}Minimum must be less than '
        'heatmap.bounds.${axis}Maximum',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCellBounds &&
          other.xMinimum == xMinimum &&
          other.xMaximum == xMaximum &&
          other.yMinimum == yMinimum &&
          other.yMaximum == yMaximum;

  @override
  int get hashCode => Object.hash(xMinimum, xMaximum, yMinimum, yMaximum);

  @override
  String toString() =>
      'HeatmapCellBounds(x: $xMinimum..$xMaximum, '
      'y: $yMinimum..$yMaximum)';
}

/// Stable identity for one logical Heatmap cell.
///
/// A host-supplied key takes precedence over coordinate identity so the cell
/// can survive reordering or coordinate changes during a later transition.
final class HeatmapCellIdentity {
  factory HeatmapCellIdentity.keyed(String key) {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be empty');
    }
    return HeatmapCellIdentity._(pointKey: key);
  }

  factory HeatmapCellIdentity.coordinate(double x, double y) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Heatmap cell identity coordinates must be finite');
    }
    return HeatmapCellIdentity._(x: x, y: y);
  }

  const HeatmapCellIdentity._({this.pointKey, this.x, this.y});

  final String? pointKey;
  final double? x;
  final double? y;

  bool get isKeyed => pointKey != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCellIdentity &&
          other.pointKey == pointKey &&
          other.x == x &&
          other.y == y;

  @override
  int get hashCode => Object.hash(pointKey, x, y);

  @override
  String toString() => isKeyed
      ? 'HeatmapCellIdentity.keyed($pointKey)'
      : 'HeatmapCellIdentity.coordinate($x, $y)';
}

/// One immutable Heatmap cell in Cartesian data space.
///
/// [x] and [y] locate the cell while [value] is the independent measure
/// encoded by colour. An explicitly missing cell retains its row/column
/// identity but has no measured value. Zero is a normal measured value.
@ChartSurface(
  bodyValidated: [
    BodyValidated(
      'The constructor rejects non-finite x, y, and value inputs and empty '
      'point keys, and bounds that do not contain the representative point. '
      'Each check concerns only the value supplied to that fluent '
      'verb, so generated mutation has the same failure boundary as direct '
      'construction.',
      params: ['x', 'y', 'value', 'pointKey', 'bounds'],
    ),
  ],
)
final class HeatmapDataPoint extends ChartDataPoint {
  // Deliberately not super-parameters: pointKey must be runtime-validated
  // before ChartDataPoint's debug assertion runs so debug and release builds
  // expose the same ArgumentError contract.
  // ignore: use_super_parameters
  HeatmapDataPoint({
    required double x,
    required double y,
    required double value,
    this.bounds,
    String? pointKey,
    double? magnitude,
    double? colorValue,
    double? opacityValue,
    String? categoryValue,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
    SegmentStyle? segmentStyle,
    PointStyle? pointStyle,
  }) : value = value,
       isMissing = false,
       super(
         x: x,
         y: y,
         pointKey: _validatedPointKey(pointKey),
         magnitude: magnitude,
         colorValue: colorValue,
         opacityValue: opacityValue,
         categoryValue: categoryValue,
         timestamp: timestamp,
         label: label,
         metadata: metadata,
         segmentStyle: segmentStyle,
         pointStyle: pointStyle,
       ) {
    _validateCoordinateAndKey(x: x, y: y, pointKey: pointKey);
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'heatmap.value', 'must be finite');
    }
    _validateBounds(bounds, x: x, y: y);
  }

  /// Creates a cell whose matrix position exists but has no measured value.
  factory HeatmapDataPoint.missing({
    required double x,
    required double y,
    HeatmapCellBounds? bounds,
    String? pointKey,
    DateTime? timestamp,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    _validateCoordinateAndKey(x: x, y: y, pointKey: pointKey);
    _validateBounds(bounds, x: x, y: y);
    return HeatmapDataPoint._(
      x: x,
      y: y,
      value: null,
      isMissing: true,
      bounds: bounds,
      pointKey: pointKey,
      timestamp: timestamp,
      label: label,
      metadata: metadata,
    );
  }

  HeatmapDataPoint._({
    required super.x,
    required super.y,
    required this.value,
    required this.isMissing,
    required this.bounds,
    super.pointKey,
    super.timestamp,
    super.label,
    super.metadata,
  });

  /// Creates a time-positioned Heatmap cell using UTC epoch milliseconds.
  factory HeatmapDataPoint.atTime({
    required DateTime timestamp,
    required double y,
    required double value,
    HeatmapCellBounds? bounds,
    String? pointKey,
    String? label,
    Map<String, dynamic>? metadata,
  }) {
    final utcTimestamp = timestamp.toUtc();
    return HeatmapDataPoint(
      x: utcTimestamp.millisecondsSinceEpoch.toDouble(),
      y: y,
      value: value,
      bounds: bounds,
      pointKey: pointKey,
      timestamp: utcTimestamp,
      label: label,
      metadata: metadata,
    );
  }

  /// Independent measure encoded by the Heatmap colour scale.
  final double? value;

  /// Whether this coordinate is an explicit missing cell.
  final bool isMissing;

  /// Optional data-space rectangle used instead of series-level cell size.
  final HeatmapCellBounds? bounds;

  /// Stable key identity when supplied, otherwise exact coordinate identity.
  HeatmapCellIdentity get identity => pointKey == null
      ? HeatmapCellIdentity.coordinate(x, y)
      : HeatmapCellIdentity.keyed(pointKey!);

  @override
  bool get isValid =>
      x.isFinite &&
      y.isFinite &&
      (bounds == null || bounds!.contains(x, y)) &&
      (isMissing || (value != null && value!.isFinite));

  static void _validateBounds(
    HeatmapCellBounds? bounds, {
    required double x,
    required double y,
  }) {
    if (bounds != null && !bounds.contains(x, y)) {
      throw ArgumentError.value(
        bounds,
        'heatmap.bounds',
        'must contain the representative x and y coordinates',
      );
    }
  }

  static void _validateCoordinateAndKey({
    required double x,
    required double y,
    required String? pointKey,
  }) {
    if (!x.isFinite) {
      throw ArgumentError.value(x, 'heatmap.x', 'must be finite');
    }
    if (!y.isFinite) {
      throw ArgumentError.value(y, 'heatmap.y', 'must be finite');
    }
    if (pointKey != null && pointKey.isEmpty) {
      throw ArgumentError.value(
        pointKey,
        'heatmap.pointKey',
        'must not be empty',
      );
    }
  }

  static String? _validatedPointKey(String? pointKey) {
    if (pointKey != null && pointKey.isEmpty) {
      throw ArgumentError.value(
        pointKey,
        'heatmap.pointKey',
        'must not be empty',
      );
    }
    return pointKey;
  }

  @override
  HeatmapDataPoint copyWith({
    double? x,
    double? y,
    String? pointKey,
    bool clearPointKey = false,
    double? magnitude,
    bool clearMagnitude = false,
    double? colorValue,
    bool clearColorValue = false,
    double? opacityValue,
    bool clearOpacityValue = false,
    String? categoryValue,
    bool clearCategoryValue = false,
    DateTime? timestamp,
    bool clearTimestamp = false,
    String? label,
    bool clearLabel = false,
    Map<String, dynamic>? metadata,
    bool clearMetadata = false,
    SegmentStyle? segmentStyle,
    bool clearSegmentStyle = false,
    PointStyle? pointStyle,
    bool clearPointStyle = false,
    HeatmapCellBounds? bounds,
    bool clearBounds = false,
    double? value,
    bool makeMissing = false,
  }) {
    if (makeMissing) {
      if (value != null) {
        throw ArgumentError(
          'An explicitly missing Heatmap cell cannot include a value',
        );
      }
      return HeatmapDataPoint.missing(
        x: x ?? this.x,
        y: y ?? this.y,
        bounds: clearBounds ? null : (bounds ?? this.bounds),
        pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
        timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
        label: clearLabel ? null : (label ?? this.label),
        metadata: clearMetadata ? null : (metadata ?? this.metadata),
      );
    }

    final resolvedValue = value ?? this.value;
    if (resolvedValue == null) {
      return HeatmapDataPoint.missing(
        x: x ?? this.x,
        y: y ?? this.y,
        bounds: clearBounds ? null : (bounds ?? this.bounds),
        pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
        timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
        label: clearLabel ? null : (label ?? this.label),
        metadata: clearMetadata ? null : (metadata ?? this.metadata),
      );
    }

    return HeatmapDataPoint(
      x: x ?? this.x,
      y: y ?? this.y,
      value: resolvedValue,
      bounds: clearBounds ? null : (bounds ?? this.bounds),
      pointKey: clearPointKey ? null : (pointKey ?? this.pointKey),
      magnitude: clearMagnitude ? null : (magnitude ?? this.magnitude),
      colorValue: clearColorValue ? null : (colorValue ?? this.colorValue),
      opacityValue: clearOpacityValue
          ? null
          : (opacityValue ?? this.opacityValue),
      categoryValue: clearCategoryValue
          ? null
          : (categoryValue ?? this.categoryValue),
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      label: clearLabel ? null : (label ?? this.label),
      metadata: clearMetadata ? null : (metadata ?? this.metadata),
      segmentStyle: clearSegmentStyle
          ? null
          : (segmentStyle ?? this.segmentStyle),
      pointStyle: clearPointStyle ? null : (pointStyle ?? this.pointStyle),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDataPoint &&
          super == other &&
          other.value == value &&
          other.isMissing == isMissing &&
          other.bounds == bounds;

  @override
  int get hashCode => Object.hash(super.hashCode, value, isMissing, bounds);

  @override
  String toString() => isMissing
      ? 'HeatmapDataPoint.missing(x: $x, y: $y, bounds: $bounds)'
      : 'HeatmapDataPoint(x: $x, y: $y, value: $value, bounds: $bounds)';
}
