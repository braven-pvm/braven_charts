import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radial_bar_series_element.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadialBarSeriesElement', () {
    test('shares geometry across paint, hit testing, and semantics', () {
      final element = RadialBarSeriesElement(
        series: RadialBarChartSeries.fromMap(
          id: 'delivery',
          unit: '%',
          values: const {'Discovery': 72, 'Build': 54, 'Launch': 31},
        ),
        config: const RadialBarChartConfig(
          thresholds: [RadialBarThreshold(value: 60, label: 'Target')],
        ),
        size: const Size(420, 320),
        theme: ChartTheme.light,
        selectedPointIndices: const {1},
      );

      expect(element.geometry.marks, hasLength(3));
      expect(element.semanticDataHits, hasLength(3));
      final hit = element.dataHitForPointIndex(1)!;
      expect(hit.category, 'Build');
      expect(hit.formattedValue, contains('54'));
      expect(hit.share, isNull);
      expect(hit.isSelected, isTrue);
      expect(element.dataHitAt(hit.plotPosition)?.pointIndex, 1);

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(420, 320));
      expect(recorder.endRecording(), isNotNull);
    });

    test('paints both gradient directions in either pane direction', () {
      for (final gradientType in RadialBarGradientType.values) {
        for (final clockwise in <bool>[true, false]) {
          final element = RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'gradient-${gradientType.name}-$clockwise',
              unit: '%',
              values: const {'Positive': 84, 'Negative': -36},
              minimum: -100,
              maximum: 100,
              baseline: 0,
              radialBarStyle: RadialBarStyle(
                showDataLabels: false,
                gradient: RadialBarGradientStyle(
                  type: gradientType,
                  startColor: const Color(0xFF67E8F9),
                  endColor: const Color(0xFF1D4ED8),
                ),
              ),
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(
                startAngleDegrees: 35,
                sweepAngleDegrees: 285,
                clockwise: clockwise,
              ),
              showCategoryLabels: false,
              showScaleLabels: false,
            ),
            size: const Size(520, 380),
            theme: ChartTheme.dark,
          );

          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size(520, 380));
          final picture = recorder.endRecording();
          expect(picture, isNotNull);
          picture.dispose();
        }
      }
    });

    test(
      'insets value labels inside marks and resolves effective contrast',
      () {
        const markColor = Color(0xFF2563EB);
        final element = RadialBarSeriesElement(
          series: RadialBarChartSeries.fromMap(
            id: 'delivery',
            unit: '%',
            values: const {'Activation': 94},
            barColors: const {'Activation': markColor},
            radialBarStyle: const RadialBarStyle(opacity: 0.3),
          ),
          config: const RadialBarChartConfig(showScaleLabels: false),
          size: const Size.square(420),
          theme: ChartTheme.light,
        );

        final mark = element.geometry.marks.single;
        final layout = element.debugValueLabelLayoutForPoint(0);
        expect(layout, isNotNull);
        expect(
          (layout!.anchor - mark.valueLabelAnchor).distance,
          greaterThan(1),
          reason: 'the label must be inset from the colored arc endpoint',
        );
        expect(layout.textSize.width, greaterThan(0));

        final effectiveFill = Color.alphaBlend(
          markColor.withValues(alpha: 0.3),
          ChartTheme.light.backgroundColor,
        );
        expect(
          _contrastRatio(layout.color, effectiveFill),
          greaterThanOrEqualTo(4.5),
        );
      },
    );

    test('omits a value label when the colored arc cannot contain it', () {
      final element = RadialBarSeriesElement(
        series: RadialBarChartSeries.fromMap(
          id: 'short',
          unit: '%',
          values: const {'Short': 1},
        ),
        config: const RadialBarChartConfig(showScaleLabels: false),
        size: const Size.square(240),
        theme: ChartTheme.light,
      );

      expect(element.debugValueLabelLayoutForPoint(0), isNull);
    });

    test('chooses accessible label colors for dark blue and light orange', () {
      const blue = Color(0xFF2563EB);
      const orange = Color(0xFFF59E0B);
      final element = RadialBarSeriesElement(
        series: RadialBarChartSeries.fromMap(
          id: 'contrast',
          unit: '%',
          values: const {'Activation': 92, 'Expansion': 57},
          barColors: const {'Activation': blue, 'Expansion': orange},
        ),
        config: const RadialBarChartConfig(showScaleLabels: false),
        size: const Size.square(520),
        theme: ChartTheme.light,
      );

      final blueLabel = element.debugValueLabelLayoutForPoint(0);
      final orangeLabel = element.debugValueLabelLayoutForPoint(1);
      expect(blueLabel, isNotNull);
      expect(orangeLabel, isNotNull);
      expect(blueLabel!.color, Colors.white);
      expect(orangeLabel!.color, Colors.black);
      expect(_contrastRatio(blueLabel.color, blue), greaterThanOrEqualTo(4.5));
      expect(
        _contrastRatio(orangeLabel.color, orange),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('fixed label color and end offset override automatic placement', () {
      const fixedColor = Color(0xFF7C2D12);
      RadialBarSeriesElement build(double offset) => RadialBarSeriesElement(
        series: RadialBarChartSeries.fromMap(
          id: 'fixed',
          unit: '%',
          values: const {'Activation': 92},
          radialBarStyle: RadialBarStyle(
            dataLabels: RadialBarDataLabelConfig(
              colorMode: RadialBarDataLabelColorMode.fixed,
              textStyle: PolarLabelStyle(
                color: fixedColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              offset: offset,
            ),
          ),
        ),
        config: const RadialBarChartConfig(showScaleLabels: false),
        size: const Size.square(520),
        theme: ChartTheme.light,
      );

      final defaultLayout = build(0).debugValueLabelLayoutForPoint(0)!;
      final insetLayout = build(18).debugValueLabelLayoutForPoint(0)!;
      expect(defaultLayout.color, fixedColor);
      expect(insetLayout.color, fixedColor);
      expect(insetLayout.textSize.height, greaterThan(10));
      expect(
        (insetLayout.anchor - const Offset(260, 260)).distance,
        closeTo((defaultLayout.anchor - const Offset(260, 260)).distance, 0.01),
      );
      expect(
        (insetLayout.anchor - defaultLayout.anchor).distance,
        greaterThan(12),
      );
    });

    test(
      'outside callouts retain short values and resolve label collisions',
      () {
        final element = RadialBarSeriesElement(
          series: RadialBarChartSeries.fromMap(
            id: 'callouts',
            unit: '%',
            values: const {
              'Activation': 1,
              'Retention': 2,
              'Adoption': 3,
              'Expansion': 4,
            },
            radialBarStyle: const RadialBarStyle(
              dataLabels: RadialBarDataLabelConfig(
                position: RadialBarDataLabelPosition.outsideCallout,
                content: RadialBarDataLabelContent.categoryAndValue,
                showPanel: true,
              ),
            ),
          ),
          config: const RadialBarChartConfig(showScaleLabels: false),
          size: const Size(520, 360),
          theme: ChartTheme.light,
        );

        final recorder = PictureRecorder();
        element.paint(Canvas(recorder), const Size(520, 360));
        recorder.endRecording();

        expect(element.debugValueLabelLayoutForPoint(0), isNull);
        expect(element.debugOutsideDataLabelRects, hasLength(4));
        expect(element.debugOutsideConnectorOrigins, hasLength(4));
        expect(element.debugOutsideConnectorRoutes, hasLength(4));
        for (var index = 0; index < element.geometry.marks.length; index++) {
          expect(
            element.debugOutsideConnectorOrigins[index],
            element.geometry.marks[index].valueLabelAnchor,
          );
          final route = element.debugOutsideConnectorRoutes[index];
          expect(route, hasLength(4));
          expect(route.first, element.debugOutsideConnectorOrigins[index]);
          expect(
            (route[1] - element.pane.center).distance,
            greaterThan(element.pane.outerRadius),
          );
          expect(route[1].dx, closeTo(route[2].dx, 0.01));
          expect(route[2].dy, closeTo(route[3].dy, 0.01));
          expect(
            route.last.dy,
            closeTo(element.debugOutsideDataLabelRects[index].center.dy, 0.01),
          );
          final labelRect = element.debugOutsideDataLabelRects[index];
          expect(
            route.last.dx,
            closeTo(
              labelRect.center.dx < element.pane.center.dx
                  ? labelRect.right
                  : labelRect.left,
              0.01,
            ),
          );
        }
        for (final rect in element.debugOutsideDataLabelRects) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(520));
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(360));
        }
        for (
          var first = 0;
          first < element.debugOutsideDataLabelRects.length;
          first++
        ) {
          for (
            var second = first + 1;
            second < element.debugOutsideDataLabelRects.length;
            second++
          ) {
            expect(
              element.debugOutsideDataLabelRects[first].overlaps(
                element.debugOutsideDataLabelRects[second],
              ),
              isFalse,
            );
          }
        }
      },
    );

    test(
      'dense large-text outside callouts thin without leaving the viewport',
      () {
        const size = Size(360, 280);
        final element = RadialBarSeriesElement(
          series: RadialBarChartSeries.fromMap(
            id: 'dense-callouts',
            unit: '%',
            values: {
              for (var index = 0; index < 24; index++)
                'Category ${index + 1}': 8 + index * 3.8,
            },
            radialBarStyle: const RadialBarStyle(
              dataLabels: RadialBarDataLabelConfig(
                position: RadialBarDataLabelPosition.outsideCallout,
                content: RadialBarDataLabelContent.categoryAndValue,
                showPanel: true,
              ),
            ),
          ),
          config: const RadialBarChartConfig(
            showCategoryLabels: false,
            showScaleLabels: false,
          ),
          size: size,
          theme: ChartTheme.light,
          textScaleFactor: 1.6,
        );
        final recorder = PictureRecorder();
        element.paint(Canvas(recorder), size);
        recorder.endRecording().dispose();

        final rects = element.debugOutsideDataLabelRects;
        expect(rects, isNotEmpty);
        expect(rects.length, lessThan(24));
        final viewport = Offset.zero & size;
        for (final rect in rects) {
          expect(viewport.contains(rect.topLeft), isTrue);
          expect(viewport.contains(rect.bottomRight), isTrue);
        }
        for (var index = 0; index < rects.length; index++) {
          for (var other = index + 1; other < rects.length; other++) {
            expect(rects[index].overlaps(rects[other]), isFalse);
          }
        }
        expect(element.semanticDataHits, hasLength(24));
      },
    );

    test(
      'category callouts use direct text color and resolve along any pane edge',
      () {
        const textColor = Color(0xFF7C2D12);
        for (final startAngle in <double>[-90, 0, 90, 180]) {
          final element = RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'categories-$startAngle',
              values: const {
                'Activation': 92,
                'Retention': 78,
                'Adoption': 66,
                'Expansion': 57,
              },
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(startAngleDegrees: startAngle),
              showScaleLabels: false,
              categoryLabels: const RadialBarCategoryLabelConfig(
                position: RadialBarCategoryLabelPosition.outsideCallout,
                connectorWidth: 1.5,
                textStyle: PolarLabelStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                showPanel: true,
              ),
            ),
            size: const Size(620, 440),
            theme: ChartTheme.light,
          );

          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size(620, 440));
          recorder.endRecording();

          expect(element.debugCategoryLabelTextColor, textColor);
          expect(element.debugCategoryLabelRects, hasLength(4));
          expect(element.debugCategoryConnectorOrigins, hasLength(4));
          expect(element.debugCategoryConnectorRoutes, hasLength(4));
          expect(element.debugCategoryLabelTrackAnchors, hasLength(4));
          expect(element.debugCategoryLabelAttachmentAnchors, hasLength(4));
          final firstRect = element.debugCategoryLabelRects.first;
          final sharesLeftEdge = element.debugCategoryLabelRects
              .skip(1)
              .every((rect) => (rect.left - firstRect.left).abs() < 0.001);
          final sharesRightEdge = element.debugCategoryLabelRects
              .skip(1)
              .every((rect) => (rect.right - firstRect.right).abs() < 0.001);
          expect(
            sharesLeftEdge || sharesRightEdge,
            isTrue,
            reason: 'all categories must share one vertical origin lane',
          );
          expect(
            element.debugCategoryConnectorOrigins.toSet(),
            hasLength(4),
            reason: 'each category retains its own track-start origin',
          );
          for (
            var index = 0;
            index < element.debugCategoryConnectorRoutes.length;
            index++
          ) {
            final route = element.debugCategoryConnectorRoutes[index];
            final trackAnchor = element.debugCategoryLabelTrackAnchors[index];
            final labelAnchor =
                element.debugCategoryLabelAttachmentAnchors[index];
            expect(route, hasLength(2));
            expect(
              route.first,
              trackAnchor,
              reason: 'the category leader begins at its owning track start',
            );
            expect(
              route.last,
              labelAnchor,
              reason: 'the category leader ends at its resolved label edge',
            );
          }
          for (final rect in element.debugCategoryLabelRects) {
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(620));
            expect(rect.top, greaterThanOrEqualTo(0));
            expect(rect.bottom, lessThanOrEqualTo(440));
          }
          for (
            var first = 0;
            first < element.debugCategoryLabelRects.length;
            first++
          ) {
            for (
              var second = first + 1;
              second < element.debugCategoryLabelRects.length;
              second++
            ) {
              expect(
                element.debugCategoryLabelRects[first].overlaps(
                  element.debugCategoryLabelRects[second],
                ),
                isFalse,
              );
            }
          }
        }
      },
    );

    test('partial start-gap labels thin in place while the pane rotates', () {
      RadialBarSeriesElement build(double sweep, double startAngle) =>
          RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'gap-$sweep',
              values: const {
                'Search': 92,
                'Social': 78,
                'Direct': 66,
                'Partner': 57,
                'Referral': 72,
              },
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(
                startAngleDegrees: startAngle,
                sweepAngleDegrees: sweep,
              ),
              showScaleLabels: false,
              categoryLabels: const RadialBarCategoryLabelConfig(
                position: RadialBarCategoryLabelPosition.startGap,
              ),
            ),
            size: const Size(620, 440),
            theme: ChartTheme.light,
          );

      for (var startAngle = -180; startAngle <= 180; startAngle += 15) {
        final partial = build(270, startAngle.toDouble());
        final partialRecorder = PictureRecorder();
        partial.paint(Canvas(partialRecorder), const Size(620, 440));
        partialRecorder.endRecording();
        expect(partial.debugCategoryLabelRects, isNotEmpty);
        expect(
          partial.debugCategoryLabelRects.length,
          lessThanOrEqualTo(5),
          reason: 'start angle $startAngle',
        );
        expect(
          partial.debugCategoryConnectorOrigins,
          isEmpty,
          reason: 'start angle $startAngle',
        );
        for (
          var first = 0;
          first < partial.debugCategoryLabelRects.length;
          first++
        ) {
          for (
            var second = first + 1;
            second < partial.debugCategoryLabelRects.length;
            second++
          ) {
            expect(
              partial.debugCategoryLabelRects[first].overlaps(
                partial.debugCategoryLabelRects[second],
              ),
              isFalse,
              reason: 'start angle $startAngle',
            );
          }
        }
      }

      final full = build(360, -90);
      final fullRecorder = PictureRecorder();
      full.paint(Canvas(fullRecorder), const Size(620, 440));
      fullRecorder.endRecording();
      expect(full.debugCategoryLabelRects, isNotEmpty);
      expect(full.debugCategoryLabelRects.length, lessThanOrEqualTo(5));
      expect(full.debugCategoryConnectorOrigins, isEmpty);
    });

    test('start-gap labels follow the start tangent and remain readable', () {
      RadialBarSeriesElement build(
        double startAngle, {
        RadialBarCategoryLabelOrientation orientation =
            RadialBarCategoryLabelOrientation.followStartAngle,
      }) => RadialBarSeriesElement(
        series: RadialBarChartSeries.fromMap(
          id: 'oriented-$startAngle-${orientation.name}',
          values: const {
            'Search': 92,
            'Social': 78,
            'Direct': 66,
            'Partner': 57,
            'Referral': 72,
          },
        ),
        config: RadialBarChartConfig(
          pane: PolarPaneConfig(startAngleDegrees: startAngle),
          showScaleLabels: false,
          categoryLabels: RadialBarCategoryLabelConfig(
            orientation: orientation,
          ),
        ),
        size: const Size(620, 440),
        theme: ChartTheme.light,
      );

      void paint(RadialBarSeriesElement element) {
        final recorder = PictureRecorder();
        element.paint(Canvas(recorder), const Size(620, 440));
        recorder.endRecording();
      }

      final top = build(-90);
      paint(top);
      expect(top.debugCategoryLabelRotations, everyElement(closeTo(0, 0.0001)));

      final right = build(0);
      paint(right);
      expect(
        right.debugCategoryLabelRotations,
        everyElement(closeTo(math.pi / 2, 0.0001)),
      );

      final bottom = build(90);
      paint(bottom);
      expect(
        bottom.debugCategoryLabelRotations,
        everyElement(closeTo(0, 0.0001)),
      );

      final left = build(180);
      paint(left);
      expect(
        left.debugCategoryLabelRotations,
        everyElement(closeTo(-math.pi / 2, 0.0001)),
      );

      final horizontal = build(
        0,
        orientation: RadialBarCategoryLabelOrientation.horizontal,
      );
      paint(horizontal);
      expect(
        horizontal.debugCategoryLabelRotations,
        everyElement(closeTo(0, 0.0001)),
      );

      final shallow = build(-60);
      paint(shallow);
      expect(
        shallow.debugCategoryLabelRotations,
        everyElement(closeTo(0, 0.0001)),
      );

      for (final startAngle in const <double>[-40, -20]) {
        final steep = build(startAngle);
        paint(steep);
        expect(
          steep.debugCategoryLabelRotations,
          everyElement(closeTo(math.pi / 2, 0.0001)),
          reason: 'start angle $startAngle',
        );
      }
    });

    test(
      'start-gap labels attach their track-facing edge to each track start',
      () {
        for (final startAngle in <double>[-90, -40, 25, 90]) {
          final element = RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'aligned-$startAngle',
              values: const {
                'Customer retention': 92,
                'Channel partners': 78,
                'Direct traffic': 66,
                'Paid acquisition': 57,
                'Organic search': 72,
              },
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(startAngleDegrees: startAngle),
              showScaleLabels: false,
              categoryLabels: const RadialBarCategoryLabelConfig(offset: 12),
            ),
            size: const Size(620, 440),
            theme: ChartTheme.light,
          );

          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size(620, 440));
          recorder.endRecording();

          expect(
            element.debugCategoryLabelTrackAnchors,
            hasLength(element.debugCategoryLabelRects.length),
          );
          expect(
            element.debugCategoryLabelAttachmentAnchors,
            hasLength(element.debugCategoryLabelRects.length),
          );
          final tangent = Offset.fromDirection(
            element.pane.startAngle -
                element.pane.signedSweepAngle.sign * math.pi / 2,
          );
          for (
            var index = 0;
            index < element.debugCategoryLabelTrackAnchors.length;
            index++
          ) {
            final delta =
                element.debugCategoryLabelAttachmentAnchors[index] -
                element.debugCategoryLabelTrackAnchors[index];
            final cross = delta.dx * tangent.dy - delta.dy * tangent.dx;
            final along = delta.dx * tangent.dx + delta.dy * tangent.dy;
            expect(cross.abs(), lessThan(0.001));
            expect(along, closeTo(14, 0.001));
          }
        }
      },
    );

    test('panel labels are only thinned for genuine label collisions', () {
      final element = RadialBarSeriesElement(
        series: RadialBarChartSeries.fromMap(
          id: 'panel-labels',
          values: const {
            'Discover': 96,
            'Evaluate': 84,
            'Adopt': 72,
            'Retain': 61,
            'Advocate': 49,
          },
        ),
        config: const RadialBarChartConfig(
          pane: PolarPaneConfig(
            startAngleDegrees: -90,
            innerRadiusFactor: 0.2,
            outerRadiusFactor: 0.82,
          ),
          trackGap: 8,
          showScaleLabels: false,
          categoryLabels: RadialBarCategoryLabelConfig(
            orientation: RadialBarCategoryLabelOrientation.horizontal,
            offset: 12,
            textStyle: PolarLabelStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            showPanel: true,
            panelStyle: LabelStyle(
              textStyle: TextStyle(),
              backgroundColor: Color(0xFF1E293B),
              borderColor: Color(0xFF64748B),
              borderWidth: 1,
              borderRadius: 6,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            ),
          ),
        ),
        size: const Size(620, 440),
        theme: ChartTheme.dark,
      );

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(620, 440));
      recorder.endRecording();

      expect(element.debugCategoryLabelRects, hasLength(5));
    });

    test(
      'scale labels clear category and threshold labels at shallow angles',
      () {
        for (final startAngle in const <double>[-30, 0, 30]) {
          final element = RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'label-clearance-$startAngle',
              unit: '%',
              values: const {
                'Activation': 92,
                'Retention': 78,
                'Adoption': 66,
                'Satisfaction': 84,
                'Expansion': 57,
              },
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(startAngleDegrees: startAngle),
              thresholds: const [
                RadialBarThreshold(value: 75, label: 'Target'),
              ],
            ),
            size: const Size(620, 440),
            theme: ChartTheme.light,
          );
          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size(620, 440));
          recorder.endRecording();

          expect(element.debugScaleLabelRects, hasLength(5));
          expect(element.debugThresholdLabelRects, hasLength(1));
          final nonScaleLabels = <Rect>[
            ...element.debugCategoryLabelRects,
            ...element.debugThresholdLabelRects,
          ];
          for (final scaleRect in element.debugScaleLabelRects) {
            expect(
              nonScaleLabels.any(
                (blocked) => scaleRect.inflate(1).overlaps(blocked),
              ),
              isFalse,
              reason: 'start angle $startAngle',
            );
          }
          for (
            var first = 0;
            first < element.debugScaleLabelRects.length;
            first++
          ) {
            for (
              var second = first + 1;
              second < element.debugScaleLabelRects.length;
              second++
            ) {
              expect(
                element.debugScaleLabelRects[first]
                    .inflate(1)
                    .overlaps(element.debugScaleLabelRects[second]),
                isFalse,
                reason: 'start angle $startAngle',
              );
            }
          }
        }
      },
    );

    test(
      'adaptive labels keep category, value, scale, and threshold lanes clear',
      () {
        for (final startAngle in const <double>[-60, -40, -20]) {
          final element = RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'adaptive-clearance-$startAngle',
              unit: '%',
              values: const {
                'Activation': 92,
                'Retention': 78,
                'Adoption': 66,
                'Satisfaction': 84,
                'Expansion': 57,
              },
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(startAngleDegrees: startAngle),
              thresholds: const [
                RadialBarThreshold(value: 75, label: 'Target'),
              ],
            ),
            size: const Size(900, 680),
            theme: ChartTheme.light,
          );
          final recorder = PictureRecorder();
          element.paint(Canvas(recorder), const Size(900, 680));
          recorder.endRecording();

          final categoryRects = element.debugCategoryLabelRects;
          final valueRects = element.debugInsideDataLabelRects;
          final scaleRects = element.debugScaleLabelRects;
          final thresholdRects = element.debugThresholdLabelRects;
          expect(categoryRects, isNotEmpty);
          expect(categoryRects.length, lessThanOrEqualTo(5));
          expect(valueRects, isNotEmpty);
          expect(scaleRects, hasLength(5));
          expect(thresholdRects, hasLength(1));

          for (final valueRect in valueRects) {
            expect(
              categoryRects.any(
                (category) => valueRect.inflate(2).overlaps(category),
              ),
              isFalse,
              reason: 'value/category at start angle $startAngle',
            );
          }
          for (final scaleRect in scaleRects) {
            expect(
              <Rect>[
                ...categoryRects,
                ...valueRects,
                ...thresholdRects,
              ].any((blocked) => scaleRect.inflate(4).overlaps(blocked)),
              isFalse,
              reason: 'scale lane at start angle $startAngle',
            );
          }
        }
      },
    );

    test(
      'dense start-gap labels thin in place instead of moving or calling out',
      () {
        final element = RadialBarSeriesElement(
          series: RadialBarChartSeries.fromMap(
            id: 'dense-category-labels',
            values: const {
              'North': 96,
              'North-east': 92,
              'East': 88,
              'South-east': 84,
              'South': 80,
              'South-west': 76,
              'West': 72,
              'North-west': 68,
              'Central': 64,
              'Remote': 60,
              'Partner': 56,
              'Direct': 52,
            },
          ),
          config: const RadialBarChartConfig(
            pane: PolarPaneConfig(
              startAngleDegrees: -90,
              innerRadiusFactor: 0.12,
              outerRadiusFactor: 0.9,
            ),
            trackGap: 3,
            showScaleLabels: false,
            categoryLabels: RadialBarCategoryLabelConfig(
              position: RadialBarCategoryLabelPosition.startGap,
            ),
          ),
          size: const Size(620, 440),
          theme: ChartTheme.light,
        );

        final recorder = PictureRecorder();
        element.paint(Canvas(recorder), const Size(620, 440));
        recorder.endRecording();

        final labels = element.debugCategoryLabelRects;
        expect(labels, isNotEmpty);
        expect(labels.length, lessThanOrEqualTo(element.geometry.marks.length));
        expect(
          element.debugCategoryConnectorOrigins,
          isEmpty,
          reason: 'start-gap collision handling must not create callouts',
        );
        for (var first = 0; first < labels.length; first++) {
          for (var second = first + 1; second < labels.length; second++) {
            expect(labels[first].overlaps(labels[second]), isFalse);
          }
        }
      },
    );

    test(
      'compact panes retain every track while reducing the requested gap',
      () {
        final element = RadialBarSeriesElement(
          series: RadialBarChartSeries.fromMap(
            id: 'dense',
            values: {
              for (var index = 0; index < 24; index++)
                'Item $index': 20 + index,
            },
          ),
          config: const RadialBarChartConfig(trackGap: 18),
          size: const Size.square(240),
          theme: ChartTheme.light,
        );

        expect(element.geometry.marks, hasLength(24));
        expect(element.semanticDataHits, hasLength(24));
        expect(element.geometry.effectiveTrackGap, lessThan(18));
        expect(element.geometry.trackThickness, greaterThan(0));
      },
    );

    test('pane clipping constrains lifted marks and their hit geometry', () {
      RadialBarSeriesElement build({required bool clipMarks}) =>
          RadialBarSeriesElement(
            series: RadialBarChartSeries.fromMap(
              id: 'clipped-selection',
              values: const {'Complete': 100},
              selectionStyle: const RadialSelectionStyle(
                effect: RadialSelectionEffect.lift,
                liftScale: 1.5,
                liftOffset: 40,
              ),
            ),
            config: RadialBarChartConfig(
              pane: PolarPaneConfig(
                innerRadiusFactor: 0.2,
                outerRadiusFactor: 0.7,
                clipMarks: clipMarks,
              ),
              showScaleLabels: false,
              showCategoryLabels: false,
            ),
            size: const Size.square(360),
            theme: ChartTheme.light,
            selectedPointIndices: const {0},
          );

      final clipped = build(clipMarks: true);
      final unclipped = build(clipMarks: false);
      final center = clipped.pane.center;
      final paneRadius = clipped.pane.outerRadius;
      var foundUnclippedOverflow = false;

      for (var y = 0.0; y <= 360; y += 2) {
        for (var x = 0.0; x <= 360; x += 2) {
          final point = Offset(x, y);
          if ((point - center).distance <= paneRadius + 0.5) continue;
          foundUnclippedOverflow =
              foundUnclippedOverflow || unclipped.hitTest(point);
          expect(clipped.hitTest(point), isFalse);
        }
      }

      expect(
        foundUnclippedOverflow,
        isTrue,
        reason: 'the control must prove the lifted path leaves the pane',
      );
      expect(
        clipped.semanticDataHits.single.semanticBounds,
        isNot(equals(unclipped.semanticDataHits.single.semanticBounds)),
      );
    });
  });
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}
