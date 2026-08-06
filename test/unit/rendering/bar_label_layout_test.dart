import 'dart:ui';

import 'dart:math' as math;

import 'package:braven_charts/src/models/bar_chart_style.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/rendering/bar_geometry.dart';
import 'package:braven_charts/src/rendering/bar_label_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveBarLabelTransform', () {
    test('uses transformed bounds for a fixed vertical label', () {
      final transform = resolveBarLabelTransform(
        localSize: const Size(40, 12),
        mode: BarLabelRotationMode.fixed,
        rotationDegrees: 90,
      );

      expect(transform.visualSize.width, closeTo(12, 0.0001));
      expect(transform.visualSize.height, closeTo(40, 0.0001));
    });

    test('auto fit turns a wide label when the perpendicular fits', () {
      final transform = resolveBarLabelTransform(
        localSize: const Size(48, 12),
        mode: BarLabelRotationMode.autoFit,
        rotationDegrees: 0,
        fitSize: const Size(16, 60),
      );

      expect(transform.visualSize.width, closeTo(12, 0.0001));
      expect(transform.visualSize.height, closeTo(48, 0.0001));
      expect(transform.radians, closeTo(math.pi / 2, 0.0001));
    });

    test('fixed mode preserves an overflowing authored angle', () {
      final transform = resolveBarLabelTransform(
        localSize: const Size(48, 12),
        mode: BarLabelRotationMode.fixed,
        rotationDegrees: 0,
        fitSize: const Size(16, 60),
      );

      expect(transform.visualSize, const Size(48, 12));
      expect(transform.radians, 0);
    });
  });

  group('resolveBarOutsideEndLabelRect', () {
    test('clears a vertical lollipop marker by its radius plus padding', () {
      final geometry = _lollipopGeometry(
        orientation: BarOrientation.vertical,
        rect: const Rect.fromLTRB(90, 50, 110, 100),
        baselinePosition: 100,
        valueEndPosition: 50,
        headBounds: const Rect.fromLTRB(82, 32, 118, 68),
      );

      expect(
        resolveBarOutsideEndLabelRect(
          geometry: geometry,
          labelSize: const Size(20, 10),
          padding: 8,
        ),
        const Rect.fromLTWH(90, 14, 20, 10),
      );
    });

    test('clears a horizontal lollipop marker by its radius plus padding', () {
      final geometry = _lollipopGeometry(
        orientation: BarOrientation.horizontal,
        rect: const Rect.fromLTRB(100, 40, 200, 60),
        baselinePosition: 100,
        valueEndPosition: 200,
        headBounds: const Rect.fromLTRB(182, 32, 218, 68),
      );

      expect(
        resolveBarOutsideEndLabelRect(
          geometry: geometry,
          labelSize: const Size(20, 10),
          padding: 8,
        ),
        const Rect.fromLTWH(226, 45, 20, 10),
      );
    });
  });

  group('BarLabelLayoutCoordinator', () {
    late BarLabelLayoutCoordinator coordinator;

    setUp(() {
      coordinator = BarLabelLayoutCoordinator(
        plotBounds: const Rect.fromLTWH(0, 0, 100, 100),
      );
    });

    test('uses the next semantic candidate when the first collides', () {
      coordinator.place(
        candidates: const [Rect.fromLTWH(10, 10, 20, 10)],
        collisionPolicy: BarLabelCollisionPolicy.reposition,
        plotEdgeAware: true,
        collisionPadding: 2,
      );

      final result = coordinator.place(
        candidates: const [
          Rect.fromLTWH(10, 10, 20, 10),
          Rect.fromLTWH(10, 30, 20, 10),
        ],
        collisionPolicy: BarLabelCollisionPolicy.reposition,
        plotEdgeAware: true,
        collisionPadding: 2,
      );

      expect(result?.rect, const Rect.fromLTWH(10, 30, 20, 10));
      expect(result?.displaced, isTrue);
    });

    test('rejects a label when hide policy has no clear first choice', () {
      coordinator.place(
        candidates: const [Rect.fromLTWH(10, 10, 20, 10)],
        collisionPolicy: BarLabelCollisionPolicy.reposition,
        plotEdgeAware: true,
        collisionPadding: 2,
      );

      final result = coordinator.place(
        candidates: const [
          Rect.fromLTWH(10, 10, 20, 10),
          Rect.fromLTWH(50, 50, 20, 10),
        ],
        collisionPolicy: BarLabelCollisionPolicy.hide,
        plotEdgeAware: true,
        collisionPadding: 2,
      );

      expect(result, isNull);
    });

    test('chooses an inside fallback at a plot edge', () {
      final result = coordinator.place(
        candidates: const [
          Rect.fromLTWH(90, 20, 20, 10),
          Rect.fromLTWH(70, 20, 20, 10),
        ],
        collisionPolicy: BarLabelCollisionPolicy.reposition,
        plotEdgeAware: true,
        collisionPadding: 2,
      );

      expect(result?.rect, const Rect.fromLTWH(70, 20, 20, 10));
    });

    test('can displace a label after semantic candidates collide', () {
      coordinator.place(
        candidates: const [Rect.fromLTWH(10, 10, 20, 10)],
        collisionPolicy: BarLabelCollisionPolicy.reposition,
        plotEdgeAware: true,
        collisionPadding: 0,
      );

      final result = coordinator.place(
        candidates: const [Rect.fromLTWH(10, 10, 20, 10)],
        collisionPolicy: BarLabelCollisionPolicy.reposition,
        plotEdgeAware: true,
        collisionPadding: 0,
        displacementDirection: const Offset(0, 1),
        displacementStep: 12,
      );

      expect(result?.rect, const Rect.fromLTWH(10, 22, 20, 10));
      expect(result?.displaced, isTrue);
    });

    test('legacy none policy clamps to the plot instead of hiding', () {
      final result = coordinator.place(
        candidates: const [Rect.fromLTWH(-10, 95, 20, 10)],
        collisionPolicy: BarLabelCollisionPolicy.none,
        plotEdgeAware: true,
        collisionPadding: 0,
      );

      expect(result?.rect, const Rect.fromLTWH(0, 90, 20, 10));
    });

    test('indexes dense labels without scanning every occupied rectangle', () {
      final denseCoordinator = BarLabelLayoutCoordinator(
        plotBounds: const Rect.fromLTWH(0, 0, 100000, 100),
        collisionCellSize: 32,
      );

      for (var index = 0; index < 2000; index++) {
        final result = denseCoordinator.place(
          candidates: [Rect.fromLTWH(index * 40.0, 20, 18, 10)],
          collisionPolicy: BarLabelCollisionPolicy.hide,
          plotEdgeAware: true,
          collisionPadding: 2,
        );
        expect(result, isNotNull);
      }

      expect(denseCoordinator.occupiedBounds, hasLength(2000));
      expect(denseCoordinator.collisionComparisonCount, lessThan(5000));
    });
  });
}

BarGeometry _lollipopGeometry({
  required BarOrientation orientation,
  required Rect rect,
  required double baselinePosition,
  required double valueEndPosition,
  required Rect headBounds,
}) => BarGeometry(
  pointIndex: 0,
  point: const ChartDataPoint(x: 0, y: 1),
  rect: rect,
  rrect: RRect.fromRectAndRadius(rect, Radius.zero),
  orientation: orientation,
  baselinePosition: baselinePosition,
  valueEndPosition: valueEndPosition,
  isNegative: false,
  startValue: 0,
  endValue: 1,
  lollipopHeadCenter: headBounds.center,
  lollipopHeadBounds: headBounds,
);
