import 'dart:math' as math;

import 'package:braven_charts/src/layout/gauge_geometry.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:braven_charts/src/models/gauge_chart_config.dart';
import 'package:braven_charts/src/models/gauge_chart_series.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GaugeGeometryCalculator', () {
    test('maps a needle value into a partial clockwise pane', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 300, 300),
        innerRadiusFactor: 0.56,
        outerRadiusFactor: 0.88,
        startAngle: -math.pi * 0.75,
        sweepAngle: math.pi * 1.5,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: 0,
        maximum: 100,
        value: 50,
        style: const NeedleGaugeStyle(),
        tickCount: 6,
      );

      expect(geometry.normalizedProgress, 0.5);
      expect(geometry.valueAngle, closeTo(0, 1e-9));
      expect(geometry.ticks.map((tick) => tick.value), [
        0,
        20,
        40,
        60,
        80,
        100,
      ]);
      expect(geometry.needle, isNotNull);
      expect(geometry.solid, isNull);
      expect(
        geometry.centerBounds.width,
        closeTo((geometry.axis.innerRadius - 8) * 2, 1e-9),
      );
      expect(geometry.needle!.tip.dx, greaterThan(pane.center.dx));
      expect(geometry.hitTest(geometry.needle!.tip), isTrue);
      expect(geometry.hitTest(pane.center), isTrue);
    });

    test('maps a solid value and zones into signed annular sectors', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 260, 260),
        innerRadiusFactor: 0.6,
        outerRadiusFactor: 0.9,
        startAngle: math.pi,
        sweepAngle: math.pi,
        clockwise: false,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: -50,
        maximum: 50,
        value: 0,
        style: const SolidGaugeStyle(cornerRadius: 6),
        zones: const [
          GaugeZone(from: -50, to: -10, status: 'Low'),
          GaugeZone(from: -10, to: 20, status: 'Nominal'),
          GaugeZone(from: 20, to: 50, status: 'High'),
        ],
      );

      expect(geometry.normalizedProgress, 0.5);
      expect(geometry.axis.sweepAngle, closeTo(-math.pi, 1e-9));
      expect(geometry.solid, isNotNull);
      expect(geometry.needle, isNull);
      expect(geometry.solid!.progress.sweepAngle, closeTo(-math.pi / 2, 1e-9));
      expect(geometry.zones, hasLength(3));
      expect(geometry.zones.first.sector.sweepAngle, lessThan(0));
      expect(geometry.hitTest(geometry.tooltipAnchor), isTrue);
    });

    test('creates deterministic target and threshold marker segments', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.85,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: 0,
        maximum: 200,
        value: 120,
        style: const NeedleGaugeStyle(axisThickness: 16),
        target: const GaugeTarget(value: 150, label: 'SLO'),
        thresholds: const [
          GaugeThreshold(value: 50, label: 'Floor'),
          GaugeThreshold(value: 180, label: 'Ceiling'),
        ],
      );

      expect(geometry.target?.value, 150);
      expect(geometry.target?.label, 'SLO');
      expect(geometry.thresholds.map((marker) => marker.value), [50, 180]);
      expect(
        geometry.target!.outerPoint - geometry.target!.innerPoint,
        isNot(Offset.zero),
      );
      expect(geometry.target!.angle, closeTo(pane.angleAt(0.75), 1e-9));
    });

    test('honors configured tick and reference callout reach', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.85,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: 0,
        maximum: 100,
        value: 50,
        style: const SolidGaugeStyle(),
        target: const GaugeTarget(value: 50, label: 'Target'),
        tickLength: 20,
        tickLabelOffset: 16,
        referenceInnerOffset: 9,
        referenceOuterOffset: 13,
      );

      final tick = geometry.ticks.first;
      expect((tick.outerPoint - tick.innerPoint).distance, closeTo(20, 1e-9));
      expect((tick.labelAnchor - tick.outerPoint).distance, closeTo(16, 1e-9));
      expect(
        (geometry.target!.innerPoint - pane.center).distance,
        closeTo(geometry.axis.innerRadius - 9, 1e-9),
      );
      expect(
        (geometry.target!.outerPoint - pane.center).distance,
        closeTo(geometry.axis.outerRadius + 13, 1e-9),
      );
    });

    test('lays out dense minor ticks inside while labels remain outside', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 300, 220),
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.85,
        startAngle: math.pi,
        sweepAngle: math.pi,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: 0,
        maximum: 200,
        value: 80,
        style: const NeedleGaugeStyle(),
        tickCount: 9,
        minorTicksPerInterval: 4,
        tickLength: 12,
        minorTickLength: 5,
        tickPosition: GaugeTickPosition.inside,
        tickGap: 8,
        labelPosition: GaugeScaleLabelPosition.outside,
        tickLabelOffset: 8,
      );

      expect(geometry.ticks, hasLength(9 + 8 * 4));
      expect(geometry.ticks.where((tick) => tick.isMajor), hasLength(9));
      expect(geometry.ticks.where((tick) => !tick.isMajor), hasLength(32));
      for (final tick in geometry.ticks) {
        expect(
          (tick.outerPoint - pane.center).distance,
          closeTo(geometry.axis.innerRadius - 8, 1e-9),
        );
        expect(
          (tick.innerPoint - pane.center).distance,
          lessThan((tick.outerPoint - pane.center).distance),
        );
      }
      expect(
        (geometry.ticks.first.labelAnchor - pane.center).distance,
        closeTo(geometry.axis.outerRadius + 8, 1e-9),
      );
    });

    test('supports inside scale labels and separated contiguous zones', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 260, 260),
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.9,
        startAngle: -math.pi * 0.75,
        sweepAngle: math.pi * 1.5,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: 0,
        maximum: 100,
        value: 50,
        style: const NeedleGaugeStyle(),
        zones: const [
          GaugeZone(from: 0, to: 50, status: 'Low'),
          GaugeZone(from: 50, to: 100, status: 'High'),
        ],
        tickPosition: GaugeTickPosition.outside,
        labelPosition: GaugeScaleLabelPosition.inside,
        tickLabelOffset: 6,
        zoneGap: 6,
        zoneCornerRadius: 3,
      );

      expect(
        (geometry.ticks.first.labelAnchor - pane.center).distance,
        lessThan(geometry.axis.outerRadius),
      );
      expect(
        geometry.zones.first.sector.startAngle +
            geometry.zones.first.sector.sweepAngle,
        lessThan(geometry.zones.last.sector.startAngle),
      );
    });

    test('creates a tapered needle with an authored tip width', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 260, 260),
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.9,
      );
      final geometry = GaugeGeometryCalculator.calculate(
        pane: pane,
        minimum: 0,
        maximum: 100,
        value: 50,
        style: const NeedleGaugeStyle(needleWidth: 20, needleTipWidth: 4),
      );

      expect(geometry.needle!.visualPath.getBounds().height, greaterThan(3));
      expect(
        geometry.needle!.visualPath.contains(geometry.needle!.tip),
        isTrue,
      );
    });

    test('keeps exact minimum and maximum geometry finite', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 180, 140),
        innerRadiusFactor: 0.4,
        outerRadiusFactor: 0.8,
        startAngle: 0.3,
        sweepAngle: math.pi * 1.2,
      );

      for (final value in const [10.0, 30.0]) {
        final geometry = GaugeGeometryCalculator.calculate(
          pane: pane,
          minimum: 10,
          maximum: 30,
          value: value,
          style: const SolidGaugeStyle(),
        );

        expect(geometry.valueAngle.isFinite, isTrue);
        expect(geometry.tooltipAnchor.dx.isFinite, isTrue);
        expect(geometry.tooltipAnchor.dy.isFinite, isTrue);
        expect(geometry.solid!.progress.bounds.isFinite, isTrue);
      }
    });

    test('rejects invalid raw geometry inputs', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.5,
        outerRadiusFactor: 0.85,
      );

      expect(
        () => GaugeGeometryCalculator.calculate(
          pane: pane,
          minimum: 0,
          maximum: 0,
          value: 0,
          style: const NeedleGaugeStyle(),
        ),
        throwsArgumentError,
      );
      expect(
        () => GaugeGeometryCalculator.calculate(
          pane: pane,
          minimum: 0,
          maximum: 100,
          value: 50,
          style: const NeedleGaugeStyle(),
          tickGap: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => GaugeGeometryCalculator.calculate(
          pane: pane,
          minimum: 0,
          maximum: 100,
          value: 50,
          style: const NeedleGaugeStyle(),
          tickLength: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => GaugeGeometryCalculator.calculate(
          pane: pane,
          minimum: 0,
          maximum: 100,
          value: 101,
          style: const SolidGaugeStyle(),
        ),
        throwsArgumentError,
      );
      expect(
        () => GaugeGeometryCalculator.calculate(
          pane: pane,
          minimum: 0,
          maximum: 100,
          value: 50,
          style: const NeedleGaugeStyle(),
          tickCount: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
