// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';
import 'dart:ui';

import 'package:braven_charts/src/models/chart_theme.dart';
import 'package:braven_charts/src/models/grid_config.dart';
import 'package:braven_charts/src/rendering/grid_renderer.dart';
import 'package:braven_charts/src/theming/components/grid_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GridRenderer', () {
    // Common test fixtures
    late Rect plotArea;

    setUp(() {
      plotArea = const Rect.fromLTWH(50, 50, 400, 300);
    });

    group('Construction', () {
      test('creates instance with no parameters', () {
        const renderer = GridRenderer();
        expect(renderer, isNotNull);
        expect(renderer.theme, isNull);
        expect(renderer.config, isNull);
      });

      test('creates instance with theme only', () {
        final theme = ChartTheme.light;
        final renderer = GridRenderer(theme: theme);
        expect(renderer, isNotNull);
        expect(renderer.theme, equals(theme));
        expect(renderer.config, isNull);
      });

      test('creates instance with config only', () {
        const config = GridConfig(horizontal: true, vertical: false);
        const renderer = GridRenderer(config: config);
        expect(renderer, isNotNull);
        expect(renderer.theme, isNull);
        expect(renderer.config, equals(config));
      });

      test('creates instance with both theme and config', () {
        final theme = ChartTheme.dark;
        const config = GridConfig(
          horizontal: true,
          vertical: true,
          horizontalColor: Color(0xFFFF0000),
          verticalColor: Color(0xFF00FF00),
        );
        final renderer = GridRenderer(theme: theme, config: config);
        expect(renderer, isNotNull);
        expect(renderer.theme, equals(theme));
        expect(renderer.config, equals(config));
      });
    });

    group('Visibility Control - Horizontal Grid', () {
      test('paintHorizontalGrid skips rendering when horizontal=false', () {
        const config = GridConfig(horizontal: false, vertical: true);
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(
          canvas,
          plotArea,
          [100.0, 150.0, 200.0],
        );

        expect(canvas.drawLineCalls.length, equals(0),
            reason: 'Should not draw any lines when horizontal=false');
      });

      test('paintHorizontalGrid renders when horizontal=true', () {
        const config = GridConfig(horizontal: true, vertical: false);
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(
          canvas,
          plotArea,
          [100.0, 150.0, 200.0],
        );

        expect(canvas.drawLineCalls.length, greaterThan(0),
            reason: 'Should draw lines when horizontal=true');
      });

      test('paintHorizontalGrid uses default config when not provided', () {
        const renderer = GridRenderer();
        final canvas = MockCanvas();

        // Default GridConfig has horizontal=true
        renderer.paintHorizontalGrid(
          canvas,
          plotArea,
          [100.0, 150.0, 200.0],
        );

        expect(canvas.drawLineCalls.length, equals(3),
            reason: 'Should draw lines with default config (horizontal=true)');
      });
    });

    group('Visibility Control - Vertical Grid', () {
      test('paintVerticalGrid skips rendering when vertical=false', () {
        const config = GridConfig(horizontal: true, vertical: false);
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(
          canvas,
          plotArea,
          [100.0, 150.0, 200.0],
        );

        expect(canvas.drawLineCalls.length, equals(0),
            reason: 'Should not draw any lines when vertical=false');
      });

      test('paintVerticalGrid renders when vertical=true', () {
        const config = GridConfig(horizontal: false, vertical: true);
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(
          canvas,
          plotArea,
          [100.0, 150.0, 200.0],
        );

        expect(canvas.drawLineCalls.length, greaterThan(0),
            reason: 'Should draw lines when vertical=true');
      });

      test('paintVerticalGrid uses default config when not provided', () {
        const renderer = GridRenderer();
        final canvas = MockCanvas();

        // Default GridConfig has vertical=true
        renderer.paintVerticalGrid(
          canvas,
          plotArea,
          [100.0, 150.0, 200.0],
        );

        expect(canvas.drawLineCalls.length, equals(3),
            reason: 'Should draw lines with default config (vertical=true)');
      });
    });

    group('Color Fallback Precedence - Horizontal', () {
      test('uses config horizontalColor when set', () {
        const configColor = Color(0xFFFF0000);
        const config = GridConfig(horizontalColor: configColor);
        final theme = ChartTheme.light.copyWith(
          gridStyle: const GridStyle(
            majorColor: Color(0xFF00FF00),
            majorWidth: 1.0,
          ),
        );
        final renderer = GridRenderer(theme: theme, config: config);
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.color, equals(configColor),
            reason: 'Should use config color when set');
      });

      test('uses theme.gridStyle.majorColor when config color is null', () {
        const themeColor = Color(0xFF00FF00);
        const config = GridConfig(); // No horizontalColor set
        final theme = ChartTheme.light.copyWith(
          gridStyle: const GridStyle(
            majorColor: themeColor,
            majorWidth: 1.0,
          ),
        );
        final renderer = GridRenderer(theme: theme, config: config);
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.color, equals(themeColor),
            reason: 'Should use theme color when config color is null');
      });

      test('uses hardcoded default when both config and theme color are null',
          () {
        const config = GridConfig(); // No horizontalColor set
        const renderer = GridRenderer(config: config); // No theme
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.color.toARGB32(),
            equals(0xFFE0E0E0),
            reason:
                'Should use hardcoded default (0xFFE0E0E0) when both are null');
      });
    });

    group('Color Fallback Precedence - Vertical', () {
      test('uses config verticalColor when set', () {
        const configColor = Color(0xFFFF0000);
        const config = GridConfig(verticalColor: configColor);
        final theme = ChartTheme.light.copyWith(
          gridStyle: const GridStyle(
            majorColor: Color(0xFF00FF00),
            majorWidth: 1.0,
          ),
        );
        final renderer = GridRenderer(theme: theme, config: config);
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.color, equals(configColor),
            reason: 'Should use config color when set');
      });

      test('uses theme.gridStyle.majorColor when config color is null', () {
        const themeColor = Color(0xFF00FF00);
        const config = GridConfig(); // No verticalColor set
        final theme = ChartTheme.light.copyWith(
          gridStyle: const GridStyle(
            majorColor: themeColor,
            majorWidth: 1.0,
          ),
        );
        final renderer = GridRenderer(theme: theme, config: config);
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.color, equals(themeColor),
            reason: 'Should use theme color when config color is null');
      });

      test('uses hardcoded default when both config and theme color are null',
          () {
        const config = GridConfig(); // No verticalColor set
        const renderer = GridRenderer(config: config); // No theme
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.color.toARGB32(),
            equals(0xFFE0E0E0),
            reason:
                'Should use hardcoded default (0xFFE0E0E0) when both are null');
      });
    });

    group('PlotArea Bounds Clipping - Horizontal', () {
      test('clips horizontal lines outside plotArea bounds', () {
        const config = GridConfig();
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        // plotArea is y: 50-350, provide positions outside this range
        renderer.paintHorizontalGrid(canvas, plotArea, [
          25.0, // Above plotArea.top (50)
          100.0, // Inside
          200.0, // Inside
          400.0, // Below plotArea.bottom (350)
        ]);

        // Should only draw lines for 100.0 and 200.0
        expect(canvas.drawLineCalls.length, equals(2),
            reason: 'Should clip lines outside plotArea bounds');

        // Verify the Y coordinates of drawn lines
        final yPositions =
            canvas.drawLineCalls.map((call) => call.p1.dy).toList();
        expect(yPositions, containsAll([100.0, 200.0]));
        expect(yPositions, isNot(contains(25.0)));
        expect(yPositions, isNot(contains(400.0)));
      });

      test('draws horizontal lines at plotArea boundaries', () {
        const config = GridConfig();
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        // Test at exact boundaries
        renderer.paintHorizontalGrid(canvas, plotArea, [
          plotArea.top, // Exactly at top boundary (50.0)
          plotArea.bottom, // Exactly at bottom boundary (350.0)
        ]);

        expect(canvas.drawLineCalls.length, equals(2),
            reason: 'Should draw lines at plotArea boundaries');
      });
    });

    group('PlotArea Bounds Clipping - Vertical', () {
      test('clips vertical lines outside plotArea bounds', () {
        const config = GridConfig();
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        // plotArea is x: 50-450, provide positions outside this range
        renderer.paintVerticalGrid(canvas, plotArea, [
          25.0, // Before plotArea.left (50)
          100.0, // Inside
          200.0, // Inside
          500.0, // After plotArea.right (450)
        ]);

        // Should only draw lines for 100.0 and 200.0
        expect(canvas.drawLineCalls.length, equals(2),
            reason: 'Should clip lines outside plotArea bounds');

        // Verify the X coordinates of drawn lines
        final xPositions =
            canvas.drawLineCalls.map((call) => call.p1.dx).toList();
        expect(xPositions, containsAll([100.0, 200.0]));
        expect(xPositions, isNot(contains(25.0)));
        expect(xPositions, isNot(contains(500.0)));
      });

      test('draws vertical lines at plotArea boundaries', () {
        const config = GridConfig();
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        // Test at exact boundaries
        renderer.paintVerticalGrid(canvas, plotArea, [
          plotArea.left, // Exactly at left boundary (50.0)
          plotArea.right, // Exactly at right boundary (450.0)
        ]);

        expect(canvas.drawLineCalls.length, equals(2),
            reason: 'Should draw lines at plotArea boundaries');
      });
    });

    group('Stroke Width - Horizontal', () {
      test('applies custom horizontalStrokeWidth from config', () {
        const customWidth = 2.5;
        const config = GridConfig(horizontalStrokeWidth: customWidth);
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(
            canvas.drawLineCalls.first.paint.strokeWidth, equals(customWidth),
            reason: 'Should apply custom stroke width from config');
      });

      test('uses default horizontalStrokeWidth when not specified', () {
        const config = GridConfig(); // Default horizontalStrokeWidth is 0.5
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.strokeWidth, equals(0.5),
            reason: 'Should use default stroke width (0.5)');
      });
    });

    group('Stroke Width - Vertical', () {
      test('applies custom verticalStrokeWidth from config', () {
        const customWidth = 3.5;
        const config = GridConfig(verticalStrokeWidth: customWidth);
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(
            canvas.drawLineCalls.first.paint.strokeWidth, equals(customWidth),
            reason: 'Should apply custom stroke width from config');
      });

      test('uses default verticalStrokeWidth when not specified', () {
        const config = GridConfig(); // Default verticalStrokeWidth is 0.5
        const renderer = GridRenderer(config: config);
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.length, equals(1));
        expect(canvas.drawLineCalls.first.paint.strokeWidth, equals(0.5),
            reason: 'Should use default stroke width (0.5)');
      });
    });

    group('Additional Coverage', () {
      test('handles empty position lists for horizontal grid', () {
        const renderer = GridRenderer();
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, []);

        expect(canvas.drawLineCalls.length, equals(0),
            reason: 'Should handle empty position list gracefully');
      });

      test('handles empty position lists for vertical grid', () {
        const renderer = GridRenderer();
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, []);

        expect(canvas.drawLineCalls.length, equals(0),
            reason: 'Should handle empty position list gracefully');
      });

      test('horizontal grid uses PaintingStyle.stroke', () {
        const renderer = GridRenderer();
        final canvas = MockCanvas();

        renderer.paintHorizontalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.first.paint.style,
            equals(PaintingStyle.stroke),
            reason: 'Should use stroke painting style');
      });

      test('vertical grid uses PaintingStyle.stroke', () {
        const renderer = GridRenderer();
        final canvas = MockCanvas();

        renderer.paintVerticalGrid(canvas, plotArea, [100.0]);

        expect(canvas.drawLineCalls.first.paint.style,
            equals(PaintingStyle.stroke),
            reason: 'Should use stroke painting style');
      });
    });
  });
}

// Mock Canvas for testing
class MockCanvas implements Canvas {
  final List<DrawLineCall> drawLineCalls = [];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    drawLineCalls.add(DrawLineCall(p1, p2, paint));
  }

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {}

  @override
  void clipRect(Rect rect,
      {ClipOp clipOp = ClipOp.intersect, bool doAntiAlias = true}) {}

  @override
  void clipRSuperellipse(RSuperellipse rsuperellipse,
      {bool doAntiAlias = true}) {}

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter,
      Paint paint) {}

  @override
  void drawAtlas(Image atlas, List<RSTransform> transforms, List<Rect> rects,
      List<Color>? colors, BlendMode? blendMode, Rect? cullRect, Paint paint) {}

  @override
  void drawCircle(Offset c, double radius, Paint paint) {}

  @override
  void drawColor(Color color, BlendMode blendMode) {}

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) {}

  @override
  void drawImage(Image image, Offset offset, Paint paint) {}

  @override
  void drawImageNine(Image image, Rect center, Rect dst, Paint paint) {}

  @override
  void drawImageRect(Image image, Rect src, Rect dst, Paint paint) {}

  @override
  void drawOval(Rect rect, Paint paint) {}

  @override
  void drawPaint(Paint paint) {}

  @override
  void drawParagraph(Paragraph paragraph, Offset offset) {}

  @override
  void drawPath(Path path, Paint paint) {}

  @override
  void drawPicture(Picture picture) {}

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {}

  @override
  void drawRRect(RRect rrect, Paint paint) {}

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) {}

  @override
  void drawRawAtlas(Image atlas, Float32List rstTransforms, Float32List rects,
      Int32List? colors, BlendMode? blendMode, Rect? cullRect, Paint paint) {}

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {}

  @override
  void drawRect(Rect rect, Paint paint) {}

  @override
  void drawShadow(
      Path path, Color color, double elevation, bool transparentOccluder) {}

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {}

  @override
  int getSaveCount() => 0;

  @override
  Rect getLocalClipBounds() => Rect.largest;

  @override
  Rect getDestinationClipBounds() => Rect.largest;

  @override
  Float64List getTransform() => Float64List(16);

  @override
  void restore() {}

  @override
  void restoreToCount(int count) {}

  @override
  void rotate(double radians) {}

  @override
  void save() {}

  @override
  void saveLayer(Rect? bounds, Paint paint) {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void skew(double sx, double sy) {}

  @override
  void transform(Float64List matrix4) {}

  @override
  void translate(double dx, double dy) {}
}

// Data class to record drawLine calls
class DrawLineCall {
  final Offset p1;
  final Offset p2;
  final Paint paint;

  DrawLineCall(this.p1, this.p2, Paint originalPaint)
      : paint = Paint()
          ..color = originalPaint.color
          ..strokeWidth = originalPaint.strokeWidth
          ..style = originalPaint.style;
}
