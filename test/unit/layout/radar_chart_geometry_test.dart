import 'dart:math' as math;

import 'package:braven_charts/src/axis/polar_numeric_scale.dart';
import 'package:braven_charts/src/axis/radar_category_scale.dart';
import 'package:braven_charts/src/layout/radar_chart_geometry.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RadialPaneGeometry pane({
    double startAngle = -math.pi / 2,
    bool clockwise = true,
  }) => RadialPaneGeometry.resolve(
    viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
    startAngle: startAngle,
    clockwise: clockwise,
  );

  test('category scale maps authored order to exact clockwise spokes', () {
    final scale = RadarCategoryScale(
      pane: pane(),
      categories: const ['North', 'East', 'South', 'West'],
    );

    expect(scale.angleAt(0), closeTo(-math.pi / 2, 1e-12));
    expect(scale.angleAt(1), closeTo(0, 1e-12));
    expect(scale.angleAt(2), closeTo(math.pi / 2, 1e-12));
    expect(scale.angleAt(3), closeTo(math.pi, 1e-12));
    expect(scale.angleForCategory('East'), closeTo(0, 1e-12));
  });

  test(
    'counter-clockwise start angle deterministically reverses traversal',
    () {
      final scale = RadarCategoryScale(
        pane: pane(startAngle: 0, clockwise: false),
        categories: const ['A', 'B', 'C', 'D'],
      );

      expect(scale.angleAt(0), closeTo(0, 1e-12));
      expect(scale.angleAt(1), closeTo(-math.pi / 2, 1e-12));
      expect(scale.angleAt(2), closeTo(-math.pi, 1e-12));
    },
  );

  test('profile closes with an edge and never duplicates a source vertex', () {
    final frame = pane();
    final geometry = RadarChartGeometry(
      categoryScale: RadarCategoryScale(
        pane: frame,
        categories: const ['A', 'B', 'C'],
      ),
      numericScale: PolarNumericScale(pane: frame, minimum: 0, maximum: 100),
    );

    final profile = geometry.profileFor(const [100, 50, 25]);

    expect(profile.vertices, hasLength(3));
    expect(profile.closedEdges, hasLength(3));
    expect(profile.closedEdges.last.startIndex, 2);
    expect(profile.closedEdges.last.endIndex, 0);
    expect(profile.closedEdges.last.end, profile.vertices.first);
    expect(profile.vertices.first, isNot(profile.vertices.last));
  });

  test('grid rings preserve exact spoke vertices and physical radius', () {
    final frame = pane();
    final geometry = RadarChartGeometry(
      categoryScale: RadarCategoryScale(
        pane: frame,
        categories: const ['A', 'B', 'C', 'D'],
      ),
      numericScale: PolarNumericScale(pane: frame, minimum: 0, maximum: 100),
    );

    final ring = geometry.ringAt(0.5);
    expect(ring.radius, 50);
    expect(ring.polygonVertices, hasLength(4));
    expect(ring.polygonVertices.first, const Offset(100, 50));
  });

  test('dense authored category counts preserve every vertex and edge', () {
    for (final categoryCount in const [3, 6, 12, 24, 64]) {
      final frame = pane();
      final categories = List<String>.generate(
        categoryCount,
        (index) => 'Category ${index + 1}',
      );
      final geometry = RadarChartGeometry(
        categoryScale: RadarCategoryScale(pane: frame, categories: categories),
        numericScale: PolarNumericScale(pane: frame, minimum: 0, maximum: 100),
      );

      final profile = geometry.profileFor(
        List<double>.generate(categoryCount, (index) => 1 + (index % 100)),
      );

      expect(profile.vertices, hasLength(categoryCount));
      expect(profile.closedEdges, hasLength(categoryCount));
      expect(profile.closedEdges.last.endIndex, 0);
      expect(profile.vertices.every((vertex) => vertex.dx.isFinite), isTrue);
      expect(profile.vertices.every((vertex) => vertex.dy.isFinite), isTrue);
    }
  });

  test('rejects partial panes, holes, mismatched scales, and bad values', () {
    expect(
      () => RadarCategoryScale(
        pane: RadialPaneGeometry.resolve(
          viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
          sweepAngle: math.pi,
        ),
        categories: const ['A', 'B', 'C'],
      ),
      throwsArgumentError,
    );
    final first = pane();
    final second = pane();
    expect(
      () => RadarChartGeometry(
        categoryScale: RadarCategoryScale(
          pane: first,
          categories: const ['A', 'B', 'C'],
        ),
        numericScale: PolarNumericScale(pane: second, minimum: 0, maximum: 10),
      ),
      throwsArgumentError,
    );
  });
}
