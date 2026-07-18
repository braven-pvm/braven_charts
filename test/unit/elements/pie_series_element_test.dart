import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:braven_charts/src/interaction/core/chart_element.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieSeriesElement', () {
    test('renders Donut series through the shared radial element', () {
      final series = DonutChartSeries.fromMap(
        id: 'donut',
        values: const {'A': 2, 'B': 1},
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.6,
          radiusFactor: 1,
          sliceGap: 0,
        ),
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(240),
        theme: ChartTheme.light,
      );

      expect(element.series, same(series));
      expect(
        element.geometry.innerRadius,
        closeTo(element.geometry.outerRadius * 0.6, 1e-9),
      );
      expect(element.hitTest(element.geometry.center), isFalse);
      expect(
        element.hitTest(element.geometry.slices.first.insideLabelAnchor),
        isTrue,
      );
      expect(element.semanticDataHits, hasLength(2));
    });

    test('resolves total, selected, fallback, and custom center content', () {
      DonutChartSeries series(DonutCenterContent centerContent) =>
          DonutChartSeries.fromMap(
            id: 'center',
            unit: 'USD',
            values: const {'Subscriptions': 42, 'Services': 58},
            centerContent: centerContent,
            donutStyle: const DonutChartStyle(
              innerRadiusFactor: 0.62,
              radiusFactor: 1,
              sliceGap: 0,
            ),
          );

      final fallback = PieSeriesElement(
        series: series(
          const DonutCenterContent(
            valueMode: DonutCenterValueMode.selectedOrTotal,
          ),
        ),
        size: const Size.square(240),
        theme: ChartTheme.light,
      );
      expect(fallback.centerPresentation?.label, isNull);
      expect(fallback.centerPresentation?.value, '100 USD');
      expect(
        fallback.centerPresentation?.semanticLabel,
        contains('total fallback'),
      );

      final selected = PieSeriesElement(
        series: fallback.series,
        size: const Size.square(240),
        theme: ChartTheme.light,
        selectedPointIndices: const {1},
      );
      expect(selected.centerPresentation?.label, 'Services');
      expect(selected.centerPresentation?.value, '58 USD');
      expect(selected.centerPresentation?.selectedPointIndex, 1);
      expect(
        selected.centerPresentation?.semanticLabel,
        contains('selected slice Services'),
      );

      final selectedOnly = PieSeriesElement(
        series: series(
          const DonutCenterContent(
            valueMode: DonutCenterValueMode.selectedValue,
          ),
        ),
        size: const Size.square(240),
        theme: ChartTheme.light,
      );
      expect(selectedOnly.centerPresentation, isNull);

      final custom = PieSeriesElement(
        series: series(
          const DonutCenterContent(
            label: 'Status',
            valueMode: DonutCenterValueMode.custom,
            customValue: 'Ready',
          ),
        ),
        size: const Size.square(240),
        theme: ChartTheme.light,
      );
      expect(custom.centerPresentation?.label, 'Status');
      expect(custom.centerPresentation?.value, 'Ready');
    });

    test('paints styled center content inside the measured opening', () async {
      const centerRed = Color(0xFFFF1744);
      final element = PieSeriesElement(
        series: DonutChartSeries.fromMap(
          id: 'paint-center',
          values: const {'Only': 1},
          donutStyle: const DonutChartStyle(
            innerRadiusFactor: 0.7,
            radiusFactor: 1,
            sliceGap: 0,
            borderWidth: 0,
          ),
          centerContent: const DonutCenterContent(
            valueMode: DonutCenterValueMode.custom,
            customValue: 'X',
            valueStyle: LabelStyle(
              textStyle: TextStyle(
                color: centerRed,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Color(0x00000000),
              borderColor: Color(0x00000000),
              borderWidth: 0,
              borderRadius: 0,
              padding: EdgeInsets.zero,
            ),
          ),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        ),
        size: const Size.square(200),
        theme: ChartTheme.light,
      );
      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(200));
      final image = await recorder.endRecording().toImage(200, 200);
      addTearDown(image.dispose);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);

      var redPixels = 0;
      final bounds = element.centerContentBounds!;
      for (var y = bounds.top.floor(); y < bounds.bottom.ceil(); y++) {
        for (var x = bounds.left.floor(); x < bounds.right.ceil(); x++) {
          final offset = (y * 200 + x) * 4;
          final red = bytes!.getUint8(offset);
          final green = bytes.getUint8(offset + 1);
          final blue = bytes.getUint8(offset + 2);
          if (red > 220 && green < 80 && blue < 110) redPixels++;
        }
      }
      expect(redPixels, greaterThan(12));
      expect(
        element.centerContentBounds!.contains(element.geometry.center),
        isTrue,
      );
      expect(element.semanticSummaries, hasLength(1));
    });

    test('large center text remains bounded and paints without overflow', () {
      final element = PieSeriesElement(
        series: DonutChartSeries.fromMap(
          id: 'scaled-center',
          values: const {'A': 1, 'B': 1},
          donutStyle: const DonutChartStyle(innerRadiusFactor: 0.28),
          centerContent: const DonutCenterContent(
            label: 'A deliberately long label',
            valueMode: DonutCenterValueMode.custom,
            customValue: '123456789 units',
          ),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        ),
        size: const Size.square(180),
        theme: ChartTheme.light,
        textScaleFactor: 2.4,
      );
      final bounds = element.centerContentBounds!;
      expect(
        (bounds.center - element.geometry.center).distance,
        lessThan(1e-9),
      );
      expect(bounds.width, lessThan(element.geometry.innerRadius * 2));
      expect(
        () => element.paint(Canvas(PictureRecorder()), const Size.square(180)),
        returnsNormally,
      );
    });

    test('participates in the shared cached data-series contract', () {
      final series = PieChartSeries.fromMap(
        id: 'pie',
        values: const {'A': 2, 'B': 1},
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size(320, 240),
        theme: ChartTheme.light,
      );

      expect(element, isA<DataSeriesElement>());
      expect(element.pointCount, 2);
      expect(element.geometry.slices, hasLength(2));
      expect(
        element.hitTest(element.geometry.slices.first.tooltipAnchor),
        isTrue,
      );
      expect(element.hitTest(const Offset(-10, -10)), isFalse);
    });

    test('resolves point override, first-slice color, then theme palette', () {
      final series = PieChartSeries(
        id: 'colors',
        color: const Color(0xFF112233),
        points: const [
          ChartDataPoint(x: 0, y: 1, label: 'A'),
          ChartDataPoint(x: 1, y: 1, label: 'B'),
          ChartDataPoint(
            x: 2,
            y: 1,
            label: 'C',
            pointStyle: PointStyle.color(Color(0xFFABCDEF)),
          ),
        ],
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(280),
        theme: ChartTheme.light,
      );

      expect(element.resolvedSliceColors, [
        const Color(0xFF112233),
        ChartTheme.light.seriesTheme.colorAt(1),
        const Color(0xFFABCDEF),
      ]);
    });

    test('resolves fixed and slice-derived border colors', () {
      const fixed = Color(0xFF102030);
      final fixedElement = PieSeriesElement(
        series: PieChartSeries.fromMap(
          id: 'fixed-border',
          values: const {'A': 2, 'B': 1},
          pieStyle: const PieChartStyle(borderColor: fixed),
        ),
        size: const Size.square(240),
        theme: ChartTheme.light,
      );
      expect(fixedElement.resolvedBorderColors, everyElement(fixed));

      const sliceColor = Color(0xFF6699CC);
      final derivedElement = PieSeriesElement(
        series: PieChartSeries.fromMap(
          id: 'derived-border',
          color: sliceColor,
          values: const {'A': 1},
          pieStyle: const PieChartStyle(
            borderColorMode: PieBorderColorMode.slice,
            borderHueShiftDegrees: 30,
            borderSaturationShift: -0.1,
            borderLightnessShift: -0.2,
          ),
        ),
        size: const Size.square(240),
        theme: ChartTheme.light,
      );
      final source = HSLColor.fromColor(sliceColor);
      final expected = source
          .withHue((source.hue + 30) % 360)
          .withSaturation(source.saturation - 0.1)
          .withLightness(source.lightness - 0.2)
          .toColor();
      expect(derivedElement.resolvedBorderColors, [expected]);
    });

    test(
      'paint writes the expected theme colors into opposite slices',
      () async {
        final series = PieChartSeries.fromMap(
          id: 'pixels',
          values: const {'Right': 1, 'Left': 1},
          pieStyle: const PieChartStyle(
            startAngleDegrees: -90,
            radiusFactor: 1,
            sliceGap: 0,
            borderWidth: 0,
          ),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        );
        final element = PieSeriesElement(
          series: series,
          size: const Size.square(200),
          theme: ChartTheme.light,
        );
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        element.paint(canvas, const Size.square(200));
        final image = await recorder.endRecording().toImage(200, 200);
        addTearDown(image.dispose);
        final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
        expect(bytes, isNotNull);

        Color pixelAt(int x, int y) {
          final offset = (y * 200 + x) * 4;
          return Color.fromARGB(
            bytes!.getUint8(offset + 3),
            bytes.getUint8(offset),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2),
          );
        }

        expect(pixelAt(145, 100), ChartTheme.light.seriesTheme.colorAt(0));
        expect(pixelAt(55, 100), ChartTheme.light.seriesTheme.colorAt(1));
      },
    );

    test('linear gradient shares one light axis across a slice', () async {
      final series = PieChartSeries.fromMap(
        id: 'gradient',
        color: const Color(0xFF808080),
        values: const {'Only': 1},
        pieStyle: const PieChartStyle(
          radiusFactor: 1,
          sliceGap: 0,
          borderWidth: 0,
          gradient: PieGradientStyle(
            type: PieGradientType.linear,
            startColor: Color(0xFFFF0000),
            endColor: Color(0xFF0000FF),
            angleDegrees: 0,
          ),
        ),
        dataLabels: const PieDataLabelConfig(isVisible: false),
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(200),
        theme: ChartTheme.light,
      );
      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(200));
      final image = await recorder.endRecording().toImage(200, 200);
      addTearDown(image.dispose);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);

      Color pixelAt(int x, int y) {
        final offset = (y * 200 + x) * 4;
        return Color.fromARGB(
          bytes!.getUint8(offset + 3),
          bytes.getUint8(offset),
          bytes.getUint8(offset + 1),
          bytes.getUint8(offset + 2),
        );
      }

      final left = pixelAt(30, 100);
      final right = pixelAt(170, 100);
      expect(left.r, greaterThan(left.b));
      expect(right.b, greaterThan(right.r));
      expect(left, isNot(right));
    });

    test('a disabled series gradient opts out of a theme gradient', () async {
      const solid = Color(0xFF336699);
      final series = PieChartSeries.fromMap(
        id: 'solid-override',
        color: solid,
        values: const {'Only': 1},
        pieStyle: const PieChartStyle(
          radiusFactor: 1,
          sliceGap: 0,
          borderWidth: 0,
          gradient: PieGradientStyle(enabled: false),
        ),
        dataLabels: const PieDataLabelConfig(isVisible: false),
      );
      final theme = ChartTheme.light.copyWith(
        pieChartTheme: const PieChartTheme(
          gradient: PieGradientStyle(type: PieGradientType.radial),
        ),
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(100),
        theme: theme,
      );
      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(100));
      final image = await recorder.endRecording().toImage(100, 100);
      addTearDown(image.dispose);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);
      final offset = (50 * 100 + 50) * 4;
      final center = Color.fromARGB(
        bytes!.getUint8(offset + 3),
        bytes.getUint8(offset),
        bytes.getUint8(offset + 1),
        bytes.getUint8(offset + 2),
      );

      expect(center, solid);
    });

    test('theme opacity is applied to slice pixels', () async {
      final series = PieChartSeries.fromMap(
        id: 'transparent',
        values: const {'Only': 1},
        pieStyle: const PieChartStyle(
          radiusFactor: 1,
          sliceGap: 0,
          borderWidth: 0,
          animationMode: PieAnimationMode.none,
        ),
        dataLabels: const PieDataLabelConfig(isVisible: false),
      );
      final theme = ChartTheme.light.copyWith(
        pieChartTheme: const PieChartTheme(
          opacity: 0.5,
          animationMode: PieAnimationMode.none,
        ),
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size.square(100),
        theme: theme,
      );
      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(100));
      final image = await recorder.endRecording().toImage(100, 100);
      addTearDown(image.dispose);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);
      final centerOffset = (50 * 100 + 50) * 4;

      expect(bytes!.getUint8(centerOffset + 3), closeTo(128, 2));
    });

    test(
      'fade entrance multiplies slice opacity without scaling geometry',
      () async {
        final series = DonutChartSeries.fromMap(
          id: 'fade-donut',
          values: const {'Only': 1},
          donutStyle: const DonutChartStyle(
            innerRadiusFactor: 0.5,
            radiusFactor: 1,
            sliceGap: 0,
            borderWidth: 0,
            animationMode: PieAnimationMode.fade,
          ),
          centerContent: DonutCenterContent.hidden,
          dataLabels: const PieDataLabelConfig(isVisible: false),
        );
        final element = PieSeriesElement(
          series: series,
          size: const Size.square(100),
          theme: ChartTheme.light,
          animationProgress: 0.5,
          isEntranceAnimationComplete: false,
        );
        final finalElement = PieSeriesElement(
          series: series,
          size: const Size.square(100),
          theme: ChartTheme.light,
        );
        final recorder = PictureRecorder();
        element.paint(Canvas(recorder), const Size.square(100));
        final image = await recorder.endRecording().toImage(100, 100);
        addTearDown(image.dispose);
        final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
        expect(bytes, isNotNull);

        final ringOffset = (50 * 100 + 80) * 4;
        expect(bytes!.getUint8(ringOffset + 3), closeTo(128, 2));
        expect(element.geometry.outerRadius, finalElement.geometry.outerRadius);
        expect(element.geometry.innerRadius, finalElement.geometry.innerRadius);
        expect(element.geometry.slices, hasLength(1));
      },
    );

    test(
      'callout and selected elevation styles paint without changing hits',
      () {
        final series = PieChartSeries.fromMap(
          id: 'styled',
          values: const {'A': 2, 'B': 1},
          pieStyle: const PieChartStyle(cornerRadius: 10),
          dataLabels: const PieDataLabelConfig(
            calloutStyle: LabelStyle(
              textStyle: TextStyle(color: Color(0xFF111827), fontSize: 12),
              backgroundColor: Color(0xF2FFFFFF),
              borderColor: Color(0xFF64748B),
              borderWidth: 1,
              borderRadius: 8,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              shadowColor: Color(0x33000000),
              shadowBlurRadius: 5,
            ),
          ),
        );
        final element = PieSeriesElement(
          series: series,
          size: const Size(320, 240),
          theme: ChartTheme.light,
          selectedPointIndices: const {0},
        );
        final recorder = PictureRecorder();

        element.paint(Canvas(recorder), const Size(320, 240));

        expect(element.dataHitForPointIndex(0), isNotNull);
        expect(element.geometry.slices.first.path, isNotNull);
        recorder.endRecording().dispose();
      },
    );

    test(
      'outside label offset moves a compact lane away from the pie',
      () async {
        Future<({double labelLeft, double pieRight})> paintAt(
          double outsideOffset,
        ) async {
          final series = PieChartSeries.fromMap(
            id: 'label-offset',
            values: const {'Right': 1, 'Left': 1},
            pieStyle: const PieChartStyle(
              startAngleDegrees: -90,
              radiusFactor: 0.7,
              sliceGap: 0,
              borderWidth: 0,
              animationMode: PieAnimationMode.none,
            ),
            dataLabels: PieDataLabelConfig(
              content: PieDataLabelContent.category,
              minimumShare: 0,
              minimumSweepDegrees: 0,
              outsideOffset: outsideOffset,
              calloutStyle: const LabelStyle(
                textStyle: TextStyle(color: Color(0xFF000000), fontSize: 10),
                backgroundColor: Color(0xFFFF00FF),
                borderColor: Color(0x00000000),
                borderWidth: 0,
                borderRadius: 0,
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
            ),
          );
          final element = PieSeriesElement(
            series: series,
            size: const Size(400, 240),
            theme: ChartTheme.light,
          );
          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size(400, 240));
          final image = await recorder.endRecording().toImage(400, 240);
          addTearDown(image.dispose);
          final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
          expect(bytes, isNotNull);

          var labelLeft = double.infinity;
          for (var y = 0; y < 240; y++) {
            for (var x = 200; x < 400; x++) {
              final byteOffset = (y * 400 + x) * 4;
              if (bytes!.getUint8(byteOffset) == 255 &&
                  bytes.getUint8(byteOffset + 1) == 0 &&
                  bytes.getUint8(byteOffset + 2) == 255 &&
                  bytes.getUint8(byteOffset + 3) == 255) {
                labelLeft = math.min(labelLeft, x.toDouble());
              }
            }
          }

          expect(labelLeft.isFinite, isTrue);
          final pieRight = element.geometry.slices
              .map((slice) => slice.bounds.right)
              .reduce(math.max);
          return (labelLeft: labelLeft, pieRight: pieRight);
        }

        final compact = await paintAt(0);
        final offset = await paintAt(24);

        expect(compact.labelLeft, closeTo(compact.pieRight, 1.5));
        expect(offset.labelLeft - compact.labelLeft, closeTo(24, 1.5));
      },
    );

    test(
      'selected explode, border, focus, and glow stay inside the canvas',
      () {
        const glow = PieElevationStyle(
          blurRadius: 24,
          spreadRadius: 6,
          offset: Offset(-3, -5),
          opacity: 0.8,
        );
        final series = PieChartSeries.fromMap(
          id: 'contained-selection',
          values: const {'Top': 1, 'Right': 1, 'Bottom': 1, 'Left': 1},
          pieStyle: const PieChartStyle(
            startAngleDegrees: -135,
            radiusFactor: 1,
            sliceGap: 8,
            borderWidth: 4,
            selectionExplodeOffset: 24,
            selectedElevation: glow,
            animationMode: PieAnimationMode.none,
          ),
          dataLabels: const PieDataLabelConfig(
            isVisible: true,
            position: PieDataLabelPosition.inside,
          ),
        );
        final glowExtent = glow.spreadRadius + glow.blurRadius * 0.65;
        for (final selectedIndex in List<int>.generate(4, (index) => index)) {
          final element = PieSeriesElement(
            series: series,
            size: const Size.square(260),
            theme: ChartTheme.light.copyWith(focusBorderWidth: 6),
            selectedPointIndices: {selectedIndex},
          );
          final selectedSlice = element.geometry.slices[selectedIndex];
          final outerArcCenter =
              selectedSlice.connectorOrigin -
              Offset.fromDirection(
                selectedSlice.midAngle,
                element.geometry.outerRadius,
              );
          final paintedBounds = Rect.fromCircle(
            center: outerArcCenter,
            radius: element.geometry.outerRadius,
          ).shift(glow.offset).inflate(glowExtent);

          expect(
            paintedBounds.left,
            greaterThanOrEqualTo(0),
            reason: selectedSlice.point.label,
          );
          expect(
            paintedBounds.top,
            greaterThanOrEqualTo(0),
            reason: selectedSlice.point.label,
          );
          expect(
            paintedBounds.right,
            lessThanOrEqualTo(element.size.width),
            reason: selectedSlice.point.label,
          );
          expect(
            paintedBounds.bottom,
            lessThanOrEqualTo(element.size.height),
            reason: selectedSlice.point.label,
          );
        }
      },
    );

    test(
      'selection adds no global outline while explicit focus keeps its ring',
      () async {
        final series = PieChartSeries.fromMap(
          id: 'selection-treatment',
          values: const {'A': 2, 'B': 1},
          pieStyle: const PieChartStyle(
            radiusFactor: 0.8,
            sliceGap: 0,
            borderWidth: 0,
            selectionExplodeOffset: 0,
            selectedElevation: PieElevationStyle(),
            animationMode: PieAnimationMode.none,
          ),
          dataLabels: const PieDataLabelConfig(isVisible: false),
        );
        final theme = ChartTheme.light.copyWith(
          focusBorderColor: const Color(0xFF00FFFF),
          interactionTheme: ChartTheme.light.interactionTheme.copyWith(
            selectionColor: const Color(0xFFFF00FF),
          ),
        );

        Future<List<int>> paint(PieSeriesElement element) async {
          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size.square(200));
          final image = await recorder.endRecording().toImage(200, 200);
          final data = await image.toByteData(format: ImageByteFormat.rawRgba);
          image.dispose();
          return List<int>.of(data!.buffer.asUint8List());
        }

        final base = await paint(
          PieSeriesElement(
            series: series,
            size: const Size.square(200),
            theme: theme,
          ),
        );
        final selected = await paint(
          PieSeriesElement(
            series: series,
            size: const Size.square(200),
            theme: theme,
            selectedPointIndices: const {0},
          ),
        );
        final focused = await paint(
          PieSeriesElement(
            series: series,
            size: const Size.square(200),
            theme: theme,
            focusedPointIndices: const {0},
          ),
        );

        expect(selected, base);
        expect(focused, isNot(base));
      },
    );

    test('copyWith preserves geometry inputs and updates element state', () {
      final element = PieSeriesElement(
        series: PieChartSeries.fromMap(id: 'copy', values: const {'A': 1}),
        size: const Size.square(200),
        theme: ChartTheme.dark,
        selectedPointIndices: const {0},
      );

      final copied = element.copyWith(isHovered: true, isSelected: true);
      expect(copied.isHovered, isTrue);
      expect(copied.isSelected, isTrue);
      expect(copied.geometry.slices.single.explodeOffset.distance, 8);
      expect(copied.theme, same(ChartTheme.dark));
    });

    test('returns a complete slice data-hit payload', () {
      final series = PieChartSeries.fromMap(
        id: 'share',
        unit: 'USD',
        values: const {'Subscriptions': 42, 'Services': 58},
        radiusValues: const {'Subscriptions': 120, 'Services': 80},
        sliceRadiusConfig: const PieSliceRadiusConfig(
          label: 'Total area',
          unit: 'km²',
        ),
      );
      final element = PieSeriesElement(
        series: series,
        size: const Size(320, 240),
        theme: ChartTheme.light,
        selectedPointIndices: const {0},
        focusedPointIndices: const {0},
      );

      final firstSlice = element.geometry.slices.first;
      final hit = element.dataHitAt(firstSlice.insideLabelAnchor);

      expect(hit, isNotNull);
      expect(hit!.seriesId, 'share');
      expect(hit.pointIndex, 0);
      expect(hit.category, 'Subscriptions');
      expect(hit.formattedValue, '42.00 USD');
      expect(hit.total, 100);
      expect(hit.share, 0.42);
      expect(hit.radiusValue, 120);
      expect(hit.formattedRadiusValue, '120.00 km²');
      expect(hit.radiusLabel, 'Total area');
      expect(hit.ordinal, 1);
      expect(hit.count, 2);
      expect(hit.isSelected, isTrue);
      expect(hit.isFocused, isTrue);
      expect(hit.semanticLabel, contains('slice 1 of 2, selected'));
      expect(hit.semanticLabel, contains('Total area 120.00 km²'));
    });
  });
}
