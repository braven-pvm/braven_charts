import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/gauge_chart_config.dart';
import '../models/gauge_chart_series.dart';
import 'annular_sector_geometry.dart';
import 'radial_pane_geometry.dart';

/// Resolved annular geometry for one operational Gauge zone.
@immutable
class GaugeZoneGeometry {
  const GaugeZoneGeometry({required this.zone, required this.sector});

  final GaugeZone zone;
  final AnnularSectorGeometry sector;
}

/// One deterministic tick on a Gauge numeric domain.
@immutable
class GaugeTickGeometry {
  const GaugeTickGeometry({
    required this.index,
    required this.isMajor,
    required this.value,
    required this.fraction,
    required this.angle,
    required this.innerPoint,
    required this.outerPoint,
    required this.labelAnchor,
  });

  final int index;
  final bool isMajor;
  final double value;
  final double fraction;
  final double angle;
  final Offset innerPoint;
  final Offset outerPoint;

  /// Boundary point after the configured label gap.
  ///
  /// Rendering offsets the measured text bounds beyond this point so a
  /// zero-pixel gap touches the tick endpoint without centering text on it.
  final Offset labelAnchor;
}

/// Radial marker geometry shared by Gauge targets and thresholds.
@immutable
class GaugeReferenceGeometry {
  const GaugeReferenceGeometry._({
    required this.value,
    required this.label,
    required this.angle,
    required this.innerPoint,
    required this.outerPoint,
  });

  final double value;
  final String? label;
  final double angle;
  final Offset innerPoint;
  final Offset outerPoint;
}

/// Needle, pivot, and widened interaction geometry.
@immutable
class GaugeNeedleGeometry {
  const GaugeNeedleGeometry._({
    required this.center,
    required this.tip,
    required this.visualPath,
    required this.hitPath,
    required this.pivotBounds,
    required this.hitRadius,
  });

  final Offset center;
  final Offset tip;
  final Path visualPath;
  final Path hitPath;
  final Rect pivotBounds;
  final double hitRadius;

  bool contains(Offset position) =>
      hitPath.contains(position) ||
      pivotBounds.inflate(hitRadius).contains(position) ||
      (position - tip).distance <= hitRadius;
}

/// Passive track and baseline-to-value progress geometry.
@immutable
class GaugeSolidGeometry {
  const GaugeSolidGeometry._({required this.track, required this.progress});

  final AnnularSectorGeometry track;
  final AnnularSectorGeometry progress;
}

/// Immutable pure geometry for one Gauge measurement.
@immutable
class GaugeGeometry {
  GaugeGeometry._({
    required this.minimum,
    required this.maximum,
    required this.value,
    required this.normalizedProgress,
    required this.valueAngle,
    required this.axis,
    required List<GaugeZoneGeometry> zones,
    required List<GaugeTickGeometry> ticks,
    required this.target,
    required List<GaugeReferenceGeometry> thresholds,
    required this.tooltipAnchor,
    required this.centerBounds,
    required this.needle,
    required this.solid,
  }) : zones = UnmodifiableListView(zones),
       ticks = UnmodifiableListView(ticks),
       thresholds = UnmodifiableListView(thresholds);

  final double minimum;
  final double maximum;
  final double value;
  final double normalizedProgress;
  final double valueAngle;
  final AnnularSectorGeometry axis;
  final List<GaugeZoneGeometry> zones;
  final List<GaugeTickGeometry> ticks;
  final GaugeReferenceGeometry? target;
  final List<GaugeReferenceGeometry> thresholds;
  final Offset tooltipAnchor;
  final Rect centerBounds;
  final GaugeNeedleGeometry? needle;
  final GaugeSolidGeometry? solid;

  bool hitTest(Offset position) {
    final resolvedNeedle = needle;
    if (resolvedNeedle != null) return resolvedNeedle.contains(position);
    return solid?.progress.contains(position) ?? false;
  }
}

/// Converts one explicit Gauge measurement into deterministic pane geometry.
abstract final class GaugeGeometryCalculator {
  static GaugeGeometry calculate({
    required RadialPaneGeometry pane,
    required double minimum,
    required double maximum,
    required double value,
    required GaugeIndicatorStyle style,
    List<GaugeZone> zones = const [],
    GaugeTarget? target,
    List<GaugeThreshold> thresholds = const [],
    int tickCount = 6,
    int minorTicksPerInterval = 0,
    double tickLength = 10,
    double minorTickLength = 5,
    GaugeTickPosition tickPosition = GaugeTickPosition.centered,
    double tickGap = 0,
    GaugeScaleLabelPosition labelPosition = GaugeScaleLabelPosition.outside,
    double tickLabelOffset = 10,
    double zoneGap = 0,
    double zoneCornerRadius = 0,
    double referenceInnerOffset = 4,
    double referenceOuterOffset = 6,
  }) {
    _validateInput(
      minimum: minimum,
      maximum: maximum,
      value: value,
      style: style,
      zones: zones,
      target: target,
      thresholds: thresholds,
      tickCount: tickCount,
      minorTicksPerInterval: minorTicksPerInterval,
      tickLength: tickLength,
      minorTickLength: minorTickLength,
      tickGap: tickGap,
      tickLabelOffset: tickLabelOffset,
      zoneGap: zoneGap,
      zoneCornerRadius: zoneCornerRadius,
      referenceInnerOffset: referenceInnerOffset,
      referenceOuterOffset: referenceOuterOffset,
    );

    final domain = maximum - minimum;
    final normalizedProgress = (value - minimum) / domain;
    final valueAngle = pane.angleAt(normalizedProgress);
    final (axisInnerRadius, axisOuterRadius, cornerRadius) = switch (style) {
      NeedleGaugeStyle(:final axisThickness) => (
        math.max(pane.innerRadius, pane.outerRadius - axisThickness),
        pane.outerRadius,
        0.0,
      ),
      SolidGaugeStyle(:final cornerRadius) => (
        pane.innerRadius,
        pane.outerRadius,
        cornerRadius,
      ),
    };
    final axis = AnnularSectorGeometry(
      center: pane.center,
      innerRadius: axisInnerRadius,
      outerRadius: axisOuterRadius,
      startAngle: pane.startAngle,
      sweepAngle: pane.signedSweepAngle,
      cornerRadius: cornerRadius,
    );
    final zoneGeometry = <GaugeZoneGeometry>[
      for (final (index, zone) in zones.indexed)
        GaugeZoneGeometry(
          zone: zone,
          sector: _zoneSector(
            pane: pane,
            zone: zone,
            index: index,
            zones: zones,
            minimum: minimum,
            domain: domain,
            innerRadius: axisInnerRadius,
            outerRadius: axisOuterRadius,
            gap: zoneGap,
            cornerRadius: zoneCornerRadius,
          ),
        ),
    ];
    final ticks = _ticks(
      pane: pane,
      majorTickCount: tickCount,
      minorTicksPerInterval: minorTicksPerInterval,
      minimum: minimum,
      domain: domain,
      majorTickLength: tickLength,
      minorTickLength: minorTickLength,
      tickPosition: tickPosition,
      tickGap: tickGap,
      axisInnerRadius: axisInnerRadius,
      axisOuterRadius: axisOuterRadius,
      labelPosition: labelPosition,
      labelOffset: tickLabelOffset,
    );
    final markerInnerRadius = math.max(
      0.0,
      axisInnerRadius - referenceInnerOffset,
    );
    final markerOuterRadius = axisOuterRadius + referenceOuterOffset;
    final targetGeometry = target == null
        ? null
        : _reference(
            pane: pane,
            value: target.value,
            label: target.label,
            minimum: minimum,
            domain: domain,
            innerRadius: markerInnerRadius,
            outerRadius: markerOuterRadius,
          );
    final thresholdGeometry = <GaugeReferenceGeometry>[
      for (final threshold in thresholds)
        _reference(
          pane: pane,
          value: threshold.value,
          label: threshold.label,
          minimum: minimum,
          domain: domain,
          innerRadius: markerInnerRadius,
          outerRadius: markerOuterRadius,
        ),
    ];

    GaugeNeedleGeometry? needle;
    GaugeSolidGeometry? solid;
    late final Offset tooltipAnchor;
    switch (style) {
      case NeedleGaugeStyle():
        final needleLength = pane.outerRadius * style.needleLengthFactor;
        final tip =
            pane.center + Offset.fromDirection(valueAngle, needleLength);
        final hitRadius = math.max(6.0, style.needleWidth * 2);
        needle = GaugeNeedleGeometry._(
          center: pane.center,
          tip: tip,
          visualPath: _needlePath(
            center: pane.center,
            tip: tip,
            width: style.needleWidth,
            tipWidth: style.needleTipWidth,
          ),
          hitPath: _lineCorridor(
            start: pane.center,
            end: tip,
            halfWidth: hitRadius,
          ),
          pivotBounds: Rect.fromCircle(
            center: pane.center,
            radius: style.pivotRadius,
          ),
          hitRadius: hitRadius,
        );
        tooltipAnchor = tip;
      case SolidGaugeStyle():
        final progress = AnnularSectorGeometry(
          center: pane.center,
          innerRadius: axisInnerRadius,
          outerRadius: axisOuterRadius,
          startAngle: pane.startAngle,
          sweepAngle: pane.signedSweepAngle * normalizedProgress,
          cornerRadius: style.cornerRadius,
        );
        solid = GaugeSolidGeometry._(track: axis, progress: progress);
        tooltipAnchor =
            pane.center +
            Offset.fromDirection(
              valueAngle,
              (axisInnerRadius + axisOuterRadius) / 2,
            );
    }

    return GaugeGeometry._(
      minimum: minimum,
      maximum: maximum,
      value: value,
      normalizedProgress: normalizedProgress,
      valueAngle: valueAngle,
      axis: axis,
      zones: zoneGeometry,
      ticks: ticks,
      target: targetGeometry,
      thresholds: thresholdGeometry,
      tooltipAnchor: tooltipAnchor,
      centerBounds: Rect.fromCircle(
        center: pane.center,
        radius: math.max(0.0, axisInnerRadius - 8),
      ),
      needle: needle,
      solid: solid,
    );
  }
}

List<GaugeTickGeometry> _ticks({
  required RadialPaneGeometry pane,
  required int majorTickCount,
  required int minorTicksPerInterval,
  required double minimum,
  required double domain,
  required double majorTickLength,
  required double minorTickLength,
  required GaugeTickPosition tickPosition,
  required double tickGap,
  required double axisInnerRadius,
  required double axisOuterRadius,
  required GaugeScaleLabelPosition labelPosition,
  required double labelOffset,
}) {
  final ticks = <GaugeTickGeometry>[];
  var index = 0;
  final intervalCount = majorTickCount - 1;
  for (var majorIndex = 0; majorIndex < majorTickCount; majorIndex++) {
    ticks.add(
      _tick(
        pane: pane,
        index: index++,
        isMajor: true,
        fraction: majorIndex / intervalCount,
        minimum: minimum,
        domain: domain,
        tickLength: majorTickLength,
        tickPosition: tickPosition,
        tickGap: tickGap,
        axisInnerRadius: axisInnerRadius,
        axisOuterRadius: axisOuterRadius,
        labelPosition: labelPosition,
        labelOffset: labelOffset,
      ),
    );
    if (majorIndex == majorTickCount - 1) continue;
    for (
      var minorIndex = 1;
      minorIndex <= minorTicksPerInterval;
      minorIndex++
    ) {
      ticks.add(
        _tick(
          pane: pane,
          index: index++,
          isMajor: false,
          fraction:
              (majorIndex + minorIndex / (minorTicksPerInterval + 1)) /
              intervalCount,
          minimum: minimum,
          domain: domain,
          tickLength: minorTickLength,
          tickPosition: tickPosition,
          tickGap: tickGap,
          axisInnerRadius: axisInnerRadius,
          axisOuterRadius: axisOuterRadius,
          labelPosition: labelPosition,
          labelOffset: labelOffset,
        ),
      );
    }
  }
  return ticks;
}

GaugeTickGeometry _tick({
  required RadialPaneGeometry pane,
  required int index,
  required bool isMajor,
  required double fraction,
  required double minimum,
  required double domain,
  required double tickLength,
  required GaugeTickPosition tickPosition,
  required double tickGap,
  required double axisInnerRadius,
  required double axisOuterRadius,
  required GaugeScaleLabelPosition labelPosition,
  required double labelOffset,
}) {
  final angle = pane.angleAt(fraction);
  final (innerRadius, outerRadius) = switch (tickPosition) {
    GaugeTickPosition.inside => (
      math.max(0.0, axisInnerRadius - tickGap - tickLength),
      math.max(0.0, axisInnerRadius - tickGap),
    ),
    // Preserve Gauge V1's established 60/40 outer-boundary split.
    GaugeTickPosition.centered => (
      math.max(0.0, axisOuterRadius - tickLength * 0.6),
      axisOuterRadius + tickLength * 0.4,
    ),
    GaugeTickPosition.outside => (
      axisOuterRadius + tickGap,
      axisOuterRadius + tickGap + tickLength,
    ),
  };
  final innerPoint = pane.center + Offset.fromDirection(angle, innerRadius);
  final outerPoint = pane.center + Offset.fromDirection(angle, outerRadius);
  final labelRadius = switch (labelPosition) {
    GaugeScaleLabelPosition.outside =>
      math.max(axisOuterRadius, outerRadius) + labelOffset,
    GaugeScaleLabelPosition.inside => math.max(
      0.0,
      math.min(axisInnerRadius, innerRadius) - labelOffset,
    ),
  };
  return GaugeTickGeometry(
    index: index,
    isMajor: isMajor,
    value: minimum + domain * fraction,
    fraction: fraction,
    angle: angle,
    innerPoint: innerPoint,
    outerPoint: outerPoint,
    labelAnchor: pane.center + Offset.fromDirection(angle, labelRadius),
  );
}

AnnularSectorGeometry _zoneSector({
  required RadialPaneGeometry pane,
  required GaugeZone zone,
  required int index,
  required List<GaugeZone> zones,
  required double minimum,
  required double domain,
  required double innerRadius,
  required double outerRadius,
  required double gap,
  required double cornerRadius,
}) {
  final rawStart = pane.angleAt((zone.from - minimum) / domain);
  final rawSweep = pane.signedSweepAngle * ((zone.to - zone.from) / domain);
  final contiguousBefore =
      index > 0 && (zones[index - 1].to - zone.from).abs() < 1e-9;
  final contiguousAfter =
      index < zones.length - 1 &&
      (zone.to - zones[index + 1].from).abs() < 1e-9;
  final gapAngle = gap == 0
      ? 0.0
      : gap / math.max(1, (innerRadius + outerRadius) / 2);
  final requestedStartInset = contiguousBefore ? gapAngle / 2 : 0.0;
  final requestedEndInset = contiguousAfter ? gapAngle / 2 : 0.0;
  final requestedTotal = requestedStartInset + requestedEndInset;
  final maximumTotal = rawSweep.abs() * 0.9;
  final insetScale = requestedTotal > maximumTotal && requestedTotal > 0
      ? maximumTotal / requestedTotal
      : 1.0;
  final direction = rawSweep.sign;
  final startInset = requestedStartInset * insetScale;
  final endInset = requestedEndInset * insetScale;
  return AnnularSectorGeometry(
    center: pane.center,
    innerRadius: innerRadius,
    outerRadius: outerRadius,
    startAngle: rawStart + direction * startInset,
    sweepAngle: rawSweep - direction * (startInset + endInset),
    cornerRadius: cornerRadius,
  );
}

GaugeReferenceGeometry _reference({
  required RadialPaneGeometry pane,
  required double value,
  required String? label,
  required double minimum,
  required double domain,
  required double innerRadius,
  required double outerRadius,
}) {
  final angle = pane.angleAt((value - minimum) / domain);
  return GaugeReferenceGeometry._(
    value: value,
    label: label,
    angle: angle,
    innerPoint: pane.center + Offset.fromDirection(angle, innerRadius),
    outerPoint: pane.center + Offset.fromDirection(angle, outerRadius),
  );
}

Path _needlePath({
  required Offset center,
  required Offset tip,
  required double width,
  required double tipWidth,
}) {
  final direction = tip - center;
  final length = direction.distance;
  if (length == 0) return Path();
  final perpendicular = Offset(-direction.dy / length, direction.dx / length);
  final halfWidth = width / 2;
  final halfTipWidth = tipWidth / 2;
  final left = center + perpendicular * halfWidth;
  final right = center - perpendicular * halfWidth;
  final tipLeft = tip + perpendicular * halfTipWidth;
  final tipRight = tip - perpendicular * halfTipWidth;
  return Path()
    ..moveTo(left.dx, left.dy)
    ..lineTo(tipLeft.dx, tipLeft.dy)
    ..lineTo(tipRight.dx, tipRight.dy)
    ..lineTo(right.dx, right.dy)
    ..close();
}

Path _lineCorridor({
  required Offset start,
  required Offset end,
  required double halfWidth,
}) {
  final direction = end - start;
  final length = direction.distance;
  if (length == 0) {
    return Path()..addOval(Rect.fromCircle(center: start, radius: halfWidth));
  }
  final unit = direction / length;
  final perpendicular = Offset(-unit.dy, unit.dx) * halfWidth;
  final extendedStart = start - unit * halfWidth;
  final extendedEnd = end + unit * halfWidth;
  return Path()
    ..moveTo(
      (extendedStart + perpendicular).dx,
      (extendedStart + perpendicular).dy,
    )
    ..lineTo((extendedEnd + perpendicular).dx, (extendedEnd + perpendicular).dy)
    ..lineTo((extendedEnd - perpendicular).dx, (extendedEnd - perpendicular).dy)
    ..lineTo(
      (extendedStart - perpendicular).dx,
      (extendedStart - perpendicular).dy,
    )
    ..close();
}

void _validateInput({
  required double minimum,
  required double maximum,
  required double value,
  required GaugeIndicatorStyle style,
  required List<GaugeZone> zones,
  required GaugeTarget? target,
  required List<GaugeThreshold> thresholds,
  required int tickCount,
  required int minorTicksPerInterval,
  required double tickLength,
  required double minorTickLength,
  required double tickGap,
  required double tickLabelOffset,
  required double zoneGap,
  required double zoneCornerRadius,
  required double referenceInnerOffset,
  required double referenceOuterOffset,
}) {
  if (!minimum.isFinite || !maximum.isFinite || minimum >= maximum) {
    throw ArgumentError.value(
      '$minimum / $maximum',
      'minimum / maximum',
      'Bounds must be finite and maximum must be greater than minimum',
    );
  }
  if (!value.isFinite || value < minimum || value > maximum) {
    throw ArgumentError.value(
      value,
      'value',
      'Measurement must be finite and inside the explicit domain',
    );
  }
  if (tickCount < 2 || tickCount > 12) {
    throw ArgumentError.value(
      tickCount,
      'tickCount',
      'Tick count must be between 2 and 12',
    );
  }
  if (minorTicksPerInterval < 0 || minorTicksPerInterval > 20) {
    throw ArgumentError.value(
      minorTicksPerInterval,
      'minorTicksPerInterval',
      'Minor ticks per interval must be between 0 and 20',
    );
  }
  _requireNonNegative(tickLength, 'tickLength');
  _requireNonNegative(minorTickLength, 'minorTickLength');
  _requireNonNegative(tickGap, 'tickGap');
  _requireNonNegative(tickLabelOffset, 'tickLabelOffset');
  _requireNonNegative(zoneGap, 'zoneGap');
  _requireNonNegative(zoneCornerRadius, 'zoneCornerRadius');
  _requireNonNegative(referenceInnerOffset, 'referenceInnerOffset');
  _requireNonNegative(referenceOuterOffset, 'referenceOuterOffset');
  style.validate();
  GaugeZone? previous;
  for (final (index, zone) in zones.indexed) {
    zone.validate(
      minimum: minimum,
      maximum: maximum,
      argumentName: 'zones[$index]',
    );
    if (previous != null && zone.from < previous.to) {
      throw ArgumentError.value(
        zone.from,
        'zones[$index].from',
        'Zones must be declared in ascending non-overlapping order',
      );
    }
    previous = zone;
  }
  target?.validate(minimum: minimum, maximum: maximum);
  for (final (index, threshold) in thresholds.indexed) {
    threshold.validate(
      minimum: minimum,
      maximum: maximum,
      argumentName: 'thresholds[$index]',
    );
  }
}

void _requireNonNegative(double value, String argumentName) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(
      value,
      argumentName,
      'Value must be finite and non-negative',
    );
  }
}
