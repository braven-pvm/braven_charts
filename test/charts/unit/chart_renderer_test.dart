/// Unit tests for ChartRenderer
///
/// Tests marker shape rendering, gradient shader caching, and object pooling
/// for optimized chart rendering performance.
library;

import 'dart:ui' show Canvas, Paint, Path, Rect, Shader, Offset, Size, Color;

import 'package:braven_charts/legacy/src/charts/base/chart_config.dart';
import 'package:braven_charts/legacy/src/charts/base/chart_renderer.dart';
import 'package:flutter/material.dart' hide Paint;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartRenderer', () {
    group('Marker Shape Rendering', () {
      testWidgets('renders circle marker correctly', (tester) async {
        final renderer = ChartRenderer();

        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.circle,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        // Verify no exceptions thrown during rendering
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders square marker correctly', (tester) async {
        final renderer = ChartRenderer();

        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.square,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders triangle marker correctly', (tester) async {
        final renderer = ChartRenderer();

        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.triangle,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders diamond marker correctly', (tester) async {
        final renderer = ChartRenderer();

        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.diamond,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders cross marker correctly', (tester) async {
        final renderer = ChartRenderer();

        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.cross,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('renders plus marker correctly', (tester) async {
        final renderer = ChartRenderer();

        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.plus,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      test('marker shapes have different path definitions', () {
        final renderer = ChartRenderer();

        // Get paths for different shapes
        final circlePath = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(0, 0),
          10.0,
        );
        final squarePath = renderer.getMarkerPath(
          MarkerShape.square,
          const Offset(0, 0),
          10.0,
        );
        final trianglePath = renderer.getMarkerPath(
          MarkerShape.triangle,
          const Offset(0, 0),
          10.0,
        );

        // Paths should be different objects
        expect(identical(circlePath, squarePath), isFalse);
        expect(identical(circlePath, trianglePath), isFalse);
        expect(identical(squarePath, trianglePath), isFalse);
      });

      test('marker size affects path dimensions', () {
        final renderer = ChartRenderer();

        final smallPath = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(0, 0),
          5.0,
        );
        final largePath = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(0, 0),
          20.0,
        );

        // Bounds should be different sizes
        expect(
            smallPath.getBounds().width, lessThan(largePath.getBounds().width));
      });

      testWidgets('none marker shape does not render', (tester) async {
        final renderer = ChartRenderer();

        // Should not throw when trying to render 'none' marker
        await tester.pumpWidget(
          CustomPaint(
            painter: _TestMarkerPainter(
              renderer: renderer,
              shape: MarkerShape.none,
              position: const Offset(50, 50),
              size: 10.0,
            ),
            size: const Size(100, 100),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    });

    group('Gradient Shader Caching', () {
      test('creates gradient shader for area fills', () {
        final renderer = ChartRenderer();

        final shader = renderer.createGradientShader(
          bounds: const Rect.fromLTWH(0, 0, 100, 100),
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );

        expect(shader, isNotNull);
        expect(shader, isA<Shader>());
      });

      test('caches shader for same parameters', () {
        final renderer = ChartRenderer();

        final bounds = const Rect.fromLTWH(0, 0, 100, 100);
        final shader1 = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );
        final shader2 = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );

        // Should return same cached shader instance
        expect(identical(shader1, shader2), isTrue);
      });

      test('creates different shader for different colors', () {
        final renderer = ChartRenderer();

        final bounds = const Rect.fromLTWH(0, 0, 100, 100);
        final shader1 = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );
        final shader2 = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.green,
          endColor: Colors.yellow,
          vertical: true,
        );

        // Should be different shader instances
        expect(identical(shader1, shader2), isFalse);
      });

      test('creates different shader for different bounds', () {
        final renderer = ChartRenderer();

        final shader1 = renderer.createGradientShader(
          bounds: const Rect.fromLTWH(0, 0, 100, 100),
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );
        final shader2 = renderer.createGradientShader(
          bounds: const Rect.fromLTWH(0, 0, 200, 200),
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );

        // Should be different shader instances (different bounds)
        expect(identical(shader1, shader2), isFalse);
      });

      test('creates different shader for different orientations', () {
        final renderer = ChartRenderer();

        final bounds = const Rect.fromLTWH(0, 0, 100, 100);
        final shaderVertical = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );
        final shaderHorizontal = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: false,
        );

        // Should be different shader instances
        expect(identical(shaderVertical, shaderHorizontal), isFalse);
      });

      test('clearCache() invalidates shader cache', () {
        final renderer = ChartRenderer();

        final bounds = const Rect.fromLTWH(0, 0, 100, 100);
        final shader1 = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );

        renderer.clearCache();

        final shader2 = renderer.createGradientShader(
          bounds: bounds,
          startColor: Colors.blue,
          endColor: Colors.red,
          vertical: true,
        );

        // Should be different instances after cache clear
        expect(identical(shader1, shader2), isFalse);
      });
    });

    group('Object Pooling for Marker Paths', () {
      test('pools marker paths for reuse', () {
        final renderer = ChartRenderer();

        // Get path from pool
        final path1 = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(10, 10),
          8.0,
        );

        // Return to pool (implicit or explicit)
        renderer.returnPathToPool(path1);

        // Get path again (should reuse from pool)
        final path2 = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(20, 20),
          8.0,
        );

        // May be same instance (pooled) or different (if pool empty)
        // The important thing is no exception occurs
        expect(path2, isNotNull);
      });

      test('pools paths separately by shape', () {
        final renderer = ChartRenderer();

        final circlePath = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(0, 0),
          10.0,
        );
        final squarePath = renderer.getMarkerPath(
          MarkerShape.square,
          const Offset(0, 0),
          10.0,
        );

        // Different shapes should not share pool
        expect(identical(circlePath, squarePath), isFalse);
      });

      test('pool handles concurrent access', () {
        final renderer = ChartRenderer();

        // Get multiple paths concurrently
        final paths = List.generate(
          10,
          (i) => renderer.getMarkerPath(
            MarkerShape.circle,
            Offset(i.toDouble(), i.toDouble()),
            8.0,
          ),
        );

        // All paths should be valid
        for (final path in paths) {
          expect(path, isNotNull);
        }

        // Return all to pool
        for (final path in paths) {
          renderer.returnPathToPool(path);
        }

        // Pool should handle this without error
        expect(() => renderer.clearPathPool(), returnsNormally);
      });

      test('clearPathPool() releases all pooled objects', () {
        final renderer = ChartRenderer();

        // Create and pool several paths
        for (int i = 0; i < 5; i++) {
          final path = renderer.getMarkerPath(
            MarkerShape.circle,
            Offset(i.toDouble(), i.toDouble()),
            8.0,
          );
          renderer.returnPathToPool(path);
        }

        // Clear pool
        renderer.clearPathPool();

        // Should work without error
        final newPath = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(0, 0),
          8.0,
        );
        expect(newPath, isNotNull);
      });

      test('pool limits prevent memory bloat', () {
        final renderer = ChartRenderer();

        // Create many paths
        final paths = List.generate(
          100,
          (i) => renderer.getMarkerPath(
            MarkerShape.circle,
            Offset(i.toDouble(), i.toDouble()),
            8.0,
          ),
        );

        // Return all to pool
        for (final path in paths) {
          renderer.returnPathToPool(path);
        }

        // Pool should handle this (may have limit on pool size)
        expect(() => renderer.getPoolSize(MarkerShape.circle), returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('handles zero marker size', () {
        final renderer = ChartRenderer();

        expect(
          () => renderer.getMarkerPath(
            MarkerShape.circle,
            const Offset(0, 0),
            0.0,
          ),
          returnsNormally,
        );
      });

      test('handles negative position coordinates', () {
        final renderer = ChartRenderer();

        expect(
          () => renderer.getMarkerPath(
            MarkerShape.square,
            const Offset(-10, -10),
            8.0,
          ),
          returnsNormally,
        );
      });

      test('handles very large marker size', () {
        final renderer = ChartRenderer();

        final path = renderer.getMarkerPath(
          MarkerShape.circle,
          const Offset(0, 0),
          1000.0,
        );

        expect(path, isNotNull);
        expect(path.getBounds().width, greaterThan(100));
      });
    });
  });
}

/// Test helper painter to render markers
class _TestMarkerPainter extends CustomPainter {
  final ChartRenderer renderer;
  final MarkerShape shape;
  final Offset position;
  final double size;

  _TestMarkerPainter({
    required this.renderer,
    required this.shape,
    required this.position,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    renderer.drawMarker(
      canvas: canvas,
      shape: shape,
      position: position,
      size: size,
      paint: Paint()..color = Colors.blue,
    );
  }

  @override
  bool shouldRepaint(_TestMarkerPainter oldDelegate) =>
      shape != oldDelegate.shape ||
      position != oldDelegate.position ||
      size != oldDelegate.size;
}
