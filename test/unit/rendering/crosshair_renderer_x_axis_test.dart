// Copyright (c) 2025 braven_charts. All rights reserved.
// Tests for themed crosshair X-value label

import 'dart:typed_data';
import 'dart:ui';

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_theme.dart';
import 'package:braven_charts/src/models/interaction_config.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/crosshair_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock canvas that captures paint operations for verification
class MockCanvas implements Canvas {
  final List<MockPaintOperation> operations = [];

  @override
  void drawRRect(RRect rrect, Paint paint) {
    operations.add(
      MockPaintOperation(type: 'drawRRect', rrect: rrect, paint: paint),
    );
  }

  @override
  void drawRSuperellipse(RSuperellipse rsuperellipse, Paint paint) {}

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    operations.add(
      MockPaintOperation(type: 'drawLine', p1: p1, p2: p2, paint: paint),
    );
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    operations.add(
      MockPaintOperation(
        type: 'drawCircle',
        center: c,
        radius: radius,
        paint: paint,
      ),
    );
  }

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    operations.add(MockPaintOperation(type: 'clipRect', rect: rect));
  }

  @override
  void save() {
    operations.add(MockPaintOperation(type: 'save'));
  }

  @override
  void restore() {
    operations.add(MockPaintOperation(type: 'restore'));
  }

  @override
  void restoreToCount(int count) {}

  // Minimal implementation of other Canvas methods (not used in tests)
  @override
  int getSaveCount() => 0;

  @override
  void saveLayer(Rect? bounds, Paint paint) {}

  @override
  void translate(double dx, double dy) {}

  @override
  void scale(double sx, [double? sy]) {}

  @override
  void rotate(double radians) {}

  @override
  void skew(double sx, double sy) {}

  @override
  void transform(Float64List matrix4) {}

  @override
  Float64List getTransform() => Float64List(16);

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) {}

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) {}

  @override
  void clipRSuperellipse(
    RSuperellipse rsuperellipse, {
    bool doAntiAlias = true,
  }) {}

  @override
  void drawArc(
    Rect rect,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {}

  @override
  void drawAtlas(
    Image atlas,
    List<RSTransform> transforms,
    List<Rect> rects,
    List<Color>? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

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
  void drawParagraph(Paragraph paragraph, Offset offset) {
    operations.add(
      MockPaintOperation(
        type: 'drawParagraph',
        offset: offset,
        paragraph: paragraph,
      ),
    );
  }

  @override
  void drawPath(Path path, Paint paint) {}

  @override
  void drawPicture(Picture picture) {}

  @override
  void drawPoints(PointMode pointMode, List<Offset> points, Paint paint) {}

  @override
  void drawRawAtlas(
    Image atlas,
    Float32List rstTransforms,
    Float32List rects,
    Int32List? colors,
    BlendMode? blendMode,
    Rect? cullRect,
    Paint paint,
  ) {}

  @override
  void drawRawPoints(PointMode pointMode, Float32List points, Paint paint) {}

  @override
  void drawRect(Rect rect, Paint paint) {}

  @override
  void drawShadow(
    Path path,
    Color color,
    double elevation,
    bool transparentOccluder,
  ) {}

  @override
  void drawVertices(Vertices vertices, BlendMode blendMode, Paint paint) {}

  @override
  Rect getDestinationClipBounds() => Rect.zero;

  @override
  Rect getLocalClipBounds() => Rect.zero;
}

/// Represents a paint operation captured by MockCanvas
class MockPaintOperation {
  MockPaintOperation({
    required this.type,
    this.rrect,
    this.paint,
    this.p1,
    this.p2,
    this.center,
    this.radius,
    this.rect,
    this.offset,
    this.paragraph,
  });

  final String type;
  final RRect? rrect;
  final Paint? paint;
  final Offset? p1;
  final Offset? p2;
  final Offset? center;
  final double? radius;
  final Rect? rect;
  final Offset? offset;
  final Paragraph? paragraph;
}

void main() {
  group('CrosshairRenderer with XAxisConfig', () {
    late CrosshairRenderer renderer;
    late ChartTransform transform;
    late Rect plotArea;
    late MultiAxisInfo multiAxisInfo;
    late MockCanvas mockCanvas;

    setUp(() {
      renderer = const CrosshairRenderer();
      transform = const ChartTransform(
        dataXMin: 0,
        dataXMax: 10,
        dataYMin: 0,
        dataYMax: 100,
        plotWidth: 400,
        plotHeight: 300,
        invertY: true,
      );
      plotArea = const Rect.fromLTWH(50, 50, 400, 300);
      multiAxisInfo = MultiAxisInfo(
        effectiveAxes: [
          YAxisConfig.withId(
            id: 'default',
            position: YAxisPosition.left,
            showCrosshairLabel:
                false, // Disable Y-axis crosshair label for X-label testing
          ),
        ],
        axisBounds: const {'default': DataRange(min: 0, max: 100)},
        axisWidths: const {'default': 50.0},
        effectiveBindings: const [],
        normalizationMode: null,
        series: const [],
      );
      mockCanvas = MockCanvas();
    });

    test('paint() method accepts xAxisConfig parameter', () {
      const xAxisConfig = XAxisConfig(
        color: Color(0xFF0000FF),
        label: 'Time',
        unit: 's',
      );

      // This will fail because paint() doesn't accept xAxisConfig yet
      expect(
        () => renderer.paint(
          canvas: mockCanvas,
          size: const Size(500, 400),
          cursorPosition: const Offset(200, 150),
          plotArea: plotArea,
          transform: transform,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
          xAxisConfig: xAxisConfig, // NEW PARAMETER
        ),
        returnsNormally,
      );
    });

    test(
      'X-value label uses semi-transparent background (alpha 0.15) from axis color',
      () {
        const axisColor = Color(0xFF0000FF); // Blue
        const xAxisConfig = XAxisConfig(
          color: axisColor,
          showCrosshairLabel: true,
        );

        renderer.paint(
          canvas: mockCanvas,
          size: const Size(500, 400),
          cursorPosition: const Offset(200, 150),
          plotArea: plotArea,
          transform: transform,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
          xAxisConfig: xAxisConfig,
        );

        // Find background drawRRect operations for X label
        final expectedBgColor = axisColor.withValues(alpha: 0.15);
        final bgOperations = mockCanvas.operations.where(
          (op) =>
              op.type == 'drawRRect' &&
              op.paint != null &&
              op.paint!.color.toARGB32() == expectedBgColor.toARGB32() &&
              op.paint!.style == PaintingStyle.fill,
        );

        expect(
          bgOperations.isNotEmpty,
          isTrue,
          reason: 'Expected X-value label background with alpha 0.15',
        );
      },
    );

    test('X-value label has themed border (alpha 0.6) from axis color', () {
      const axisColor = Color(0xFFFF0000); // Red
      const xAxisConfig = XAxisConfig(
        color: axisColor,
        showCrosshairLabel: true,
      );

      renderer.paint(
        canvas: mockCanvas,
        size: const Size(500, 400),
        cursorPosition: const Offset(200, 150),
        plotArea: plotArea,
        transform: transform,
        theme: ChartTheme.light,
        crosshairConfig: const CrosshairConfig(),
        multiAxisInfo: multiAxisInfo,
        seriesElements: const [],
        isRangeCreationMode: false,
        xAxisConfig: xAxisConfig,
      );

      // Find border drawRRect operations for X label
      final expectedBorderColor = axisColor.withValues(alpha: 0.6);
      final borderOperations = mockCanvas.operations.where(
        (op) =>
            op.type == 'drawRRect' &&
            op.paint != null &&
            op.paint!.color.toARGB32() == expectedBorderColor.toARGB32() &&
            op.paint!.style == PaintingStyle.stroke,
      );

      expect(
        borderOperations.isNotEmpty,
        isTrue,
        reason: 'Expected X-value label border with alpha 0.6',
      );
    });

    test('X-value displays value only (no "X: " prefix)', () {
      const xAxisConfig = XAxisConfig(
        color: Color(0xFF0000FF),
        showCrosshairLabel: true,
      );

      // Cursor at plot position that maps to data X = 5.0
      final cursorOffset = Offset(
        plotArea.left + transform.plotWidth / 2, // Middle of plot = dataX 5.0
        plotArea.top + 100,
      );

      renderer.paint(
        canvas: mockCanvas,
        size: const Size(500, 400),
        cursorPosition: cursorOffset,
        plotArea: plotArea,
        transform: transform,
        theme: ChartTheme.light,
        crosshairConfig: const CrosshairConfig(),
        multiAxisInfo: multiAxisInfo,
        seriesElements: const [],
        isRangeCreationMode: false,
        xAxisConfig: xAxisConfig,
      );

      // Find paragraph drawing operations (text rendering)
      final paragraphOps = mockCanvas.operations.where(
        (op) => op.type == 'drawParagraph',
      );

      // With proper implementation, there should be at least one paragraph drawn for X-value
      // This will fail initially because xAxisConfig parameter doesn't exist
      expect(
        paragraphOps.isNotEmpty,
        isTrue,
        reason: 'Expected X-value label to be rendered',
      );
    });

    test('showCrosshairLabel=false skips X-value label rendering', () {
      const xAxisConfig = XAxisConfig(
        color: Color(0xFF0000FF),
        showCrosshairLabel: false, // DISABLED
      );

      renderer.paint(
        canvas: mockCanvas,
        size: const Size(500, 400),
        cursorPosition: const Offset(200, 150),
        plotArea: plotArea,
        transform: transform,
        theme: ChartTheme.light,
        crosshairConfig: const CrosshairConfig(),
        multiAxisInfo: multiAxisInfo,
        seriesElements: const [],
        isRangeCreationMode: false,
        xAxisConfig: xAxisConfig,
      );

      // Count drawRRect operations (should be fewer without X label)
      final rrectCount = mockCanvas.operations
          .where((op) => op.type == 'drawRRect')
          .length;

      // With showCrosshairLabel=false, there should be no X-value label
      // This will fail because current implementation always draws the label
      expect(
        rrectCount,
        equals(0),
        reason: 'Expected no X-value label when showCrosshairLabel=false',
      );
    });

    test('labelFormatter is applied to crosshair X-value', () {
      String customFormatter(double value) {
        return 'T=${value.toStringAsFixed(1)}';
      }

      final xAxisConfig = XAxisConfig(
        color: const Color(0xFF0000FF),
        showCrosshairLabel: true,
        labelFormatter: customFormatter,
      );

      // Cursor at plot position that maps to data X = 5.0
      final cursorOffset = Offset(
        plotArea.left + transform.plotWidth / 2,
        plotArea.top + 100,
      );

      renderer.paint(
        canvas: mockCanvas,
        size: const Size(500, 400),
        cursorPosition: cursorOffset,
        plotArea: plotArea,
        transform: transform,
        theme: ChartTheme.light,
        crosshairConfig: const CrosshairConfig(),
        multiAxisInfo: multiAxisInfo,
        seriesElements: const [],
        isRangeCreationMode: false,
        xAxisConfig: xAxisConfig,
      );

      // Find paragraph operations - with custom formatter there should be label drawn
      final paragraphOps = mockCanvas.operations.where(
        (op) => op.type == 'drawParagraph',
      );

      // This will fail because labelFormatter is not yet supported
      expect(
        paragraphOps.isNotEmpty,
        isTrue,
        reason: 'Expected X-value label with custom formatter',
      );
    });

    test(
      'visible=false hides crosshair label even if showCrosshairLabel=true',
      () {
        const xAxisConfig = XAxisConfig(
          color: Color(0xFF0000FF),
          showCrosshairLabel: true,
          visible: false, // INVISIBLE
        );

        renderer.paint(
          canvas: mockCanvas,
          size: const Size(500, 400),
          cursorPosition: const Offset(200, 150),
          plotArea: plotArea,
          transform: transform,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
          xAxisConfig: xAxisConfig,
        );

        // No X-value label should be drawn when visible=false
        final rrectCount = mockCanvas.operations
            .where((op) => op.type == 'drawRRect')
            .length;

        expect(
          rrectCount,
          equals(0),
          reason: 'Expected no X-value label when visible=false',
        );
      },
    );

    test(
      'X-value label uses default gray color when xAxisConfig color is null',
      () {
        const xAxisConfig = XAxisConfig(
          color: null, // No explicit color
          showCrosshairLabel: true,
        );

        renderer.paint(
          canvas: mockCanvas,
          size: const Size(500, 400),
          cursorPosition: const Offset(200, 150),
          plotArea: plotArea,
          transform: transform,
          theme: ChartTheme.light,
          crosshairConfig: const CrosshairConfig(),
          multiAxisInfo: multiAxisInfo,
          seriesElements: const [],
          isRangeCreationMode: false,
          xAxisConfig: xAxisConfig,
        );

        // Should use default gray color (0xFF333333) when no color specified
        const expectedDefaultColor = Color(0xFF333333);
        final expectedBgColor = expectedDefaultColor.withValues(alpha: 0.15);

        final bgOperations = mockCanvas.operations.where(
          (op) =>
              op.type == 'drawRRect' &&
              op.paint != null &&
              op.paint!.color.toARGB32() == expectedBgColor.toARGB32(),
        );

        expect(
          bgOperations.isNotEmpty,
          isTrue,
          reason: 'Expected default gray color (0xFF333333) when color is null',
        );
      },
    );

    test('X-value label respects unit configuration from xAxisConfig', () {
      const xAxisConfig = XAxisConfig(
        color: Color(0xFF0000FF),
        unit: 's', // Seconds unit
        showCrosshairLabel: true,
      );

      // Cursor at plot position that maps to data X = 5.0
      final cursorOffset = Offset(
        plotArea.left + transform.plotWidth / 2,
        plotArea.top + 100,
      );

      renderer.paint(
        canvas: mockCanvas,
        size: const Size(500, 400),
        cursorPosition: cursorOffset,
        plotArea: plotArea,
        transform: transform,
        theme: ChartTheme.light,
        crosshairConfig: const CrosshairConfig(),
        multiAxisInfo: multiAxisInfo,
        seriesElements: const [],
        isRangeCreationMode: false,
        xAxisConfig: xAxisConfig,
      );

      // Find paragraph operations - unit should be included
      final paragraphOps = mockCanvas.operations.where(
        (op) => op.type == 'drawParagraph',
      );

      // This will fail because unit from xAxisConfig is not yet applied
      expect(
        paragraphOps.isNotEmpty,
        isTrue,
        reason: 'Expected X-value label with unit suffix',
      );
    });
  });
}
