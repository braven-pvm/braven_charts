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
      final innerOnly = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 90,
        startAngle: 0,
        sweepAngle: math.pi / 2,
        cornerRadius: 12,
        roundOuterCorners: false,
      );

      expect(roundAll.contains(roundAll.pointAt()), isTrue);
      expect(outerOnly.contains(outerOnly.pointAt()), isTrue);
      expect(innerOnly.contains(innerOnly.pointAt()), isTrue);
      expect(roundAll.contains(roundAll.center), isFalse);
      expect(outerOnly.contains(outerOnly.center), isFalse);
      expect(innerOnly.contains(innerOnly.center), isFalse);
      expect(roundAll.bounds, isNot(Rect.zero));
      expect(outerOnly.bounds, isNot(Rect.zero));
      expect(innerOnly.bounds, isNot(Rect.zero));
    });

    test('physical seam insets keep adjacent rounded sides parallel', () {
      final first = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 90,
        startAngle: 0,
        sweepAngle: math.pi / 2,
        cornerRadius: 6,
        seamInset: 5,
      );
      final adjacent = AnnularSectorGeometry(
        center: const Offset(100, 100),
        innerRadius: 40,
        outerRadius: 90,
        startAngle: math.pi / 2,
        sweepAngle: math.pi / 2,
        cornerRadius: 6,
        seamInset: 5,
      );

      expect(first.seamInset, 5);
      expect(adjacent.seamInset, 5);
      for (final distance in const [60.0, 78.0]) {
        // The first sector ends at x = 105 and its neighbor starts at x = 95
        // for the complete straight side, proving a constant 10 px channel.
        expect(first.contains(Offset(105.1, 100 + distance)), isTrue);
        expect(first.contains(Offset(104.9, 100 + distance)), isFalse);
        expect(adjacent.contains(Offset(94.9, 100 + distance)), isTrue);
        expect(adjacent.contains(Offset(95.1, 100 + distance)), isFalse);
      }
    });

    test('corner modes stay bounded across radii and sweep directions', () {
      const center = Offset(120, 100);
      for (final innerRadius in const [18.0, 44.0, 72.0]) {
        for (final sweepAngle in const [math.pi / 7, -math.pi / 3, math.pi]) {
          for (final cornerMode in const [
            (roundOuter: true, roundInner: true),
            (roundOuter: true, roundInner: false),
            (roundOuter: false, roundInner: true),
          ]) {
            final geometry = AnnularSectorGeometry(
              center: center,
              innerRadius: innerRadius,
              outerRadius: 92,
              startAngle: 0.7,
              sweepAngle: sweepAngle,
              cornerRadius: 14,
              roundOuterCorners: cornerMode.roundOuter,
              roundInnerCorners: cornerMode.roundInner,
              seamInset: 4,
            );

            expect(geometry.contains(geometry.pointAt()), isTrue);
            expect(
              geometry.contains(
                center + Offset.fromDirection(0.7, innerRadius * 0.5),
              ),
              isFalse,
            );
            for (final fraction in const [0.25, 0.5, 0.75]) {
              final angle = 0.7 + sweepAngle * fraction;
              expect(
                geometry.contains(center + Offset.fromDirection(angle, 92.5)),
                isFalse,
              );
            }
          }
        }
      }
    });

    test('rejects invalid radii, angles, corners, and lookup fractions', () {
      AnnularSectorGeometry build({
        double innerRadius = 20,
        double outerRadius = 40,
        double startAngle = 0,
        double sweepAngle = math.pi,
        double cornerRadius = 0,
        double seamInset = 0,
      }) => AnnularSectorGeometry(
        center: Offset.zero,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        cornerRadius: cornerRadius,
        seamInset: seamInset,
      );

      expect(() => build(innerRadius: -1), throwsArgumentError);
      expect(
        () => build(innerRadius: 50, outerRadius: 40),
        throwsArgumentError,
      );
      expect(() => build(startAngle: double.infinity), throwsArgumentError);
      expect(() => build(sweepAngle: double.nan), throwsArgumentError);
      expect(() => build(cornerRadius: -1), throwsArgumentError);
      expect(() => build(seamInset: -1), throwsArgumentError);
      expect(() => build(seamInset: double.nan), throwsArgumentError);

      final geometry = build();
      expect(
        () => geometry.pointAt(angularFraction: -0.1),
        throwsArgumentError,
      );
      expect(() => geometry.pointAt(radialFraction: 1.1), throwsArgumentError);
    });
  });
}
