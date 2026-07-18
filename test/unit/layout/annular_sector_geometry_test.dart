import 'dart:math' as math;

import 'package:braven_charts/src/layout/annular_sector_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnnularSectorGeometry', () {
    test('builds a complete ring with stable bounds and containment', () {
      final geometry = AnnularSectorGeometry(
        center: const Offset(100, 80),
        innerRadius: 30,
        outerRadius: 70,
        startAngle: -math.pi / 2,
        sweepAngle: math.pi * 2,
      );

      expect(geometry.bounds, const Rect.fromLTWH(30, 10, 140, 140));
      expect(geometry.contains(geometry.center), isFalse);
      expect(geometry.contains(const Offset(150, 80)), isTrue);
      expect(geometry.contains(const Offset(180, 80)), isFalse);
    });

    test('supports signed partial sweeps and deterministic point lookup', () {
      final clockwise = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 80,
        startAngle: 0,
        sweepAngle: math.pi / 2,
      );
      final counterClockwise = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 80,
        startAngle: 0,
        sweepAngle: -math.pi / 2,
      );

      expect(clockwise.contains(const Offset(140, 140)), isTrue);
      expect(clockwise.contains(const Offset(140, 60)), isFalse);
      expect(counterClockwise.contains(const Offset(140, 60)), isTrue);
      expect(counterClockwise.contains(const Offset(140, 140)), isFalse);
      expect(
        clockwise.pointAt(angularFraction: 0.5, radialFraction: 0.5),
        const Offset(100, 100) + Offset.fromDirection(math.pi / 4, 60),
      );
    });

    test('rounded sectors retain their annular centerline', () {
      final roundAll = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 90,
        startAngle: 0,
        sweepAngle: math.pi / 2,
        cornerRadius: 12,
      );
      final outerOnly = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 90,
        startAngle: 0,
        sweepAngle: math.pi / 2,
        cornerRadius: 12,
        roundInnerCorners: false,
      );

      expect(roundAll.contains(roundAll.pointAt()), isTrue);
      expect(outerOnly.contains(outerOnly.pointAt()), isTrue);
      expect(roundAll.contains(roundAll.center), isFalse);
      expect(outerOnly.contains(outerOnly.center), isFalse);
      expect(roundAll.bounds, isNot(Rect.zero));
      expect(outerOnly.bounds, isNot(Rect.zero));
    });

    test('rejects invalid radii, angles, corners, and lookup fractions', () {
      AnnularSectorGeometry build({
        double innerRadius = 20,
        double outerRadius = 40,
        double startAngle = 0,
        double sweepAngle = math.pi,
        double cornerRadius = 0,
      }) => AnnularSectorGeometry(
        center: Offset.zero,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        cornerRadius: cornerRadius,
      );

      expect(() => build(innerRadius: -1), throwsArgumentError);
      expect(
        () => build(innerRadius: 50, outerRadius: 40),
        throwsArgumentError,
      );
      expect(() => build(startAngle: double.infinity), throwsArgumentError);
      expect(() => build(sweepAngle: double.nan), throwsArgumentError);
      expect(() => build(cornerRadius: -1), throwsArgumentError);

      final geometry = build();
      expect(
        () => geometry.pointAt(angularFraction: -0.1),
        throwsArgumentError,
      );
      expect(() => geometry.pointAt(radialFraction: 1.1), throwsArgumentError);
    });
  });
}
