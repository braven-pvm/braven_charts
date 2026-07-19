import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/src/rendering/scatter_marker_path.dart';
import 'package:braven_charts/src/theming/components/series_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Scatter marker paths', () {
    for (final shape in SeriesMarkerShape.values.where(
      (shape) => shape != SeriesMarkerShape.none,
    )) {
      test('${shape.name} produces centered finite geometry', () {
        final path = Path();
        addScatterMarkerPath(
          path,
          center: const Offset(20, 20),
          radius: 8,
          shape: shape,
        );

        expect(path.getBounds().isFinite, isTrue);
        expect(path.getBounds().isEmpty, isFalse);
        expect(
          scatterMarkerContains(
            position: const Offset(20, 20),
            center: const Offset(20, 20),
            radius: 8,
            shape: shape,
          ),
          isTrue,
        );
      });
    }

    test('none has no paint or direct-hit silhouette', () {
      final path = Path();
      addScatterMarkerPath(
        path,
        center: const Offset(20, 20),
        radius: 8,
        shape: SeriesMarkerShape.none,
      );

      expect(path.getBounds().isEmpty, isTrue);
      expect(
        scatterMarkerContains(
          position: const Offset(20, 20),
          center: const Offset(20, 20),
          radius: 8,
          shape: SeriesMarkerShape.none,
        ),
        isFalse,
      );
    });

    test('dimensions and rotation share paint and hit geometry', () {
      final path = Path();
      addScatterMarkerPath(
        path,
        center: const Offset(20, 20),
        radius: 10,
        width: 20,
        height: 6,
        rotationRadians: math.pi / 2,
        shape: SeriesMarkerShape.square,
      );

      expect(path.getBounds().width, closeTo(6, 0.001));
      expect(path.getBounds().height, closeTo(20, 0.001));
      expect(
        scatterMarkerContains(
          position: const Offset(20, 28),
          center: const Offset(20, 20),
          radius: 10,
          width: 20,
          height: 6,
          rotationRadians: math.pi / 2,
          shape: SeriesMarkerShape.square,
        ),
        isTrue,
      );
      expect(
        scatterMarkerContains(
          position: const Offset(28, 20),
          center: const Offset(20, 20),
          radius: 10,
          width: 20,
          height: 6,
          rotationRadians: math.pi / 2,
          shape: SeriesMarkerShape.square,
        ),
        isFalse,
      );
    });

    test('inverted triangle points down and preserves its silhouette', () {
      final path = Path();
      addScatterMarkerPath(
        path,
        center: const Offset(20, 20),
        radius: 8,
        shape: SeriesMarkerShape.invertedTriangle,
      );

      expect(path.contains(const Offset(20, 27)), isTrue);
      expect(path.contains(const Offset(20, 13)), isTrue);
      expect(path.contains(const Offset(14, 26)), isFalse);
    });
  });
}
