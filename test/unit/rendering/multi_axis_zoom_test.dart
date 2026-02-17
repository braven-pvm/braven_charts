// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/chart_series.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisManager Y-Zoom with forPainting', () {
    late MultiAxisManager manager;

    setUp(() {
      manager = MultiAxisManager();
    });

    group('Mouse Wheel Y-Zoom with PerSeries Normalization', () {
      test('forPainting=true returns viewport-aware bounds during Y-zoom', () {
        // Setup multi-axis series with different ranges
        final series = [
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 100),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
            ),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 1000),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis2',
              position: YAxisPosition.right,
            ),
          ),
        ];

        manager.setSeries(series);
        manager.setNormalizationMode(NormalizationMode.perSeries);

        // Create original transform (full data range)
        final originalTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Create zoomed transform (Y-axis zoomed in 2x, showing middle 50%)
        final zoomedTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 25, // Zoomed in to middle 50%
          dataYMax: 75,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Get bounds for painting (should be viewport-aware when zoomed)
        final boundsForPainting = manager.computeAxisBounds(
          transform: zoomedTransform,
          originalTransform: originalTransform,
          forPainting: true,
        );

        // Get default bounds (should use full data range)
        final boundsDefault = manager.computeAxisBounds(
          transform: zoomedTransform,
          originalTransform: originalTransform,
          forPainting: false,
        );

        // Verify forPainting=true uses zoomed viewport bounds
        expect(
          boundsForPainting['axis1']!.min,
          greaterThan(0),
          reason: 'Zoomed axis should not start at 0 (original min)',
        );
        expect(
          boundsForPainting['axis1']!.max,
          lessThan(105),
          reason: 'Zoomed axis should not extend to full padded max',
        );

        // Verify forPainting=false uses full bounds
        expect(
          boundsDefault['axis1']!.min,
          closeTo(-5.0, 0.1),
          reason: 'Default bounds should include 5% padding from min (0)',
        );
        expect(
          boundsDefault['axis1']!.max,
          closeTo(105.0, 0.1),
          reason: 'Default bounds should include 5% padding from max (100)',
        );

        // Verify the bounds are different
        expect(
          boundsForPainting['axis1']!.max,
          isNot(equals(boundsDefault['axis1']!.max)),
          reason:
              'forPainting bounds should differ from default when viewport is zoomed',
        );
      });

      test('forPainting=true with no zoom returns full bounds', () {
        final series = [
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 100),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
            ),
          ),
        ];

        manager.setSeries(series);
        manager.setNormalizationMode(NormalizationMode.perSeries);

        // Create transform (NOT zoomed)
        final transform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Get bounds with forPainting=true (no zoom, so same as forPainting=false)
        final boundsForPainting = manager.computeAxisBounds(
          transform: transform,
          originalTransform: transform,
          forPainting: true,
        );

        final boundsDefault = manager.computeAxisBounds(
          transform: transform,
          originalTransform: transform,
          forPainting: false,
        );

        // Both should return same bounds (with 5% padding)
        expect(
          boundsForPainting['axis1']!.min,
          closeTo(boundsDefault['axis1']!.min, 0.1),
        );
        expect(
          boundsForPainting['axis1']!.max,
          closeTo(boundsDefault['axis1']!.max, 0.1),
        );
        expect(boundsForPainting['axis1']!.min, closeTo(-5.0, 0.1));
        expect(boundsForPainting['axis1']!.max, closeTo(105.0, 0.1));
      });

      test('forPainting=false always returns full bounds even when zoomed', () {
        final series = [
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 100),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
            ),
          ),
        ];

        manager.setSeries(series);
        manager.setNormalizationMode(NormalizationMode.perSeries);

        final originalTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Heavily zoomed transform
        final zoomedTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 40, // Showing only 40-60 range (20% of data)
          dataYMax: 60,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Get bounds with forPainting=false
        final bounds = manager.computeAxisBounds(
          transform: zoomedTransform,
          originalTransform: originalTransform,
          forPainting: false,
        );

        // Should return full bounds regardless of zoom
        expect(
          bounds['axis1']!.min,
          closeTo(-5.0, 0.1),
          reason: 'forPainting=false should always use full data range',
        );
        expect(
          bounds['axis1']!.max,
          closeTo(105.0, 0.1),
          reason: 'forPainting=false should always use full data range',
        );
      });
    });

    group('Y-Scrollbar Edge Drag Zoom', () {
      test('forPainting=true handles scrollbar-initiated Y-zoom correctly', () {
        final series = [
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 200),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
            ),
          ),
          ChartSeries(
            id: 's2',
            name: 'Series 2',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 500),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis2',
              position: YAxisPosition.right,
            ),
          ),
        ];

        manager.setSeries(series);
        manager.setNormalizationMode(NormalizationMode.perSeries);

        final originalTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 200,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Scrollbar zoom: viewing bottom 25% of data (0-50)
        final scrollbarZoomedTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 50,
          plotWidth: 400,
          plotHeight: 300,
        );

        final boundsForPainting = manager.computeAxisBounds(
          transform: scrollbarZoomedTransform,
          originalTransform: originalTransform,
          forPainting: true,
        );

        // Axis 1 bounds should reflect viewport (0-50 range, not full 0-200)
        expect(boundsForPainting['axis1']!.min, lessThanOrEqualTo(0));
        expect(
          boundsForPainting['axis1']!.max,
          lessThan(105),
          reason: 'Scrollbar zoom should show viewport-aware bounds',
        );

        // Axis 2 should also reflect proportional viewport
        expect(boundsForPainting['axis2']!.min, lessThanOrEqualTo(0));
        expect(
          boundsForPainting['axis2']!.max,
          lessThan(525),
          reason:
              'Second axis should also use viewport-aware bounds (500 * 0.25 = 125, plus padding)',
        );
      });
    });

    group('Zoom Center Point Preservation', () {
      test(
        'forPainting bounds update correctly when zooming around center',
        () {
          final series = [
            ChartSeries(
              id: 's1',
              name: 'Series 1',
              points: [
                const ChartDataPoint(x: 0, y: 0),
                const ChartDataPoint(x: 10, y: 100),
              ],
              yAxisConfig: YAxisConfig.withId(
                id: 'axis1',
                position: YAxisPosition.left,
              ),
            ),
          ];

          manager.setSeries(series);
          manager.setNormalizationMode(NormalizationMode.perSeries);

          final originalTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 400,
            plotHeight: 300,
          );

          // Zoom 2x centered at Y=50 (middle of range)
          // Result: viewing 25-75 range
          final centerZoomedTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 25,
            dataYMax: 75,
            plotWidth: 400,
            plotHeight: 300,
          );

          final boundsForPainting = manager.computeAxisBounds(
            transform: centerZoomedTransform,
            originalTransform: originalTransform,
            forPainting: true,
          );

          // Bounds should be roughly centered around 50
          final center =
              (boundsForPainting['axis1']!.min +
                  boundsForPainting['axis1']!.max) /
              2;
          expect(
            center,
            closeTo(50.0, 10.0),
            reason: 'Zoom centered at 50 should keep bounds centered near 50',
          );

          // Range should be roughly half of original (due to 2x zoom)
          final range =
              boundsForPainting['axis1']!.max - boundsForPainting['axis1']!.min;
          expect(
            range,
            lessThan(105 - (-5)),
            reason: 'Zoomed range should be smaller than full range',
          );
        },
      );

      test('forPainting bounds update correctly when zooming around top', () {
        final series = [
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 100),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
            ),
          ),
        ];

        manager.setSeries(series);
        manager.setNormalizationMode(NormalizationMode.perSeries);

        final originalTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Zoom 2x centered near top (Y=75)
        // Result: viewing 50-100 range
        final topZoomedTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 50,
          dataYMax: 100,
          plotWidth: 400,
          plotHeight: 300,
        );

        final boundsForPainting = manager.computeAxisBounds(
          transform: topZoomedTransform,
          originalTransform: originalTransform,
          forPainting: true,
        );

        // Max should be close to 100 (top of data)
        expect(
          boundsForPainting['axis1']!.max,
          greaterThanOrEqualTo(100),
          reason: 'Top-zoomed bounds should include top data value',
        );

        // Min should be around 50 (not at 0)
        expect(
          boundsForPainting['axis1']!.min,
          greaterThan(40),
          reason: 'Top-zoomed bounds should not start near bottom',
        );
      });
    });

    group('Per-Series Transform Viewport Awareness', () {
      test(
        'forPainting=true provides correct bounds for per-series transform during zoom',
        () {
          final series = [
            ChartSeries(
              id: 's1',
              name: 'Series 1',
              points: [
                const ChartDataPoint(x: 0, y: 10),
                const ChartDataPoint(x: 5, y: 50),
                const ChartDataPoint(x: 10, y: 90),
              ],
              yAxisConfig: YAxisConfig.withId(
                id: 'axis1',
                position: YAxisPosition.left,
              ),
            ),
          ];

          manager.setSeries(series);
          manager.setNormalizationMode(NormalizationMode.perSeries);

          final originalTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 10,
            dataYMax: 90,
            plotWidth: 400,
            plotHeight: 300,
          );

          // Zoom to show only middle section (30-70)
          final zoomedTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 30,
            dataYMax: 70,
            plotWidth: 400,
            plotHeight: 300,
          );

          final boundsForPainting = manager.computeAxisBounds(
            transform: zoomedTransform,
            originalTransform: originalTransform,
            forPainting: true,
          );

          // Bounds should reflect viewport (30-70 range), not full range (10-90)
          expect(
            boundsForPainting['axis1']!.min,
            lessThan(30),
            reason:
                'Min should include padding below viewport min (30), but not extend to full data min (10)',
          );
          expect(
            boundsForPainting['axis1']!.min,
            greaterThan(10),
            reason:
                'Min should not extend to full data range min when viewport is zoomed',
          );

          expect(
            boundsForPainting['axis1']!.max,
            greaterThan(70),
            reason:
                'Max should include padding above viewport max (70), but not extend to full data max (90)',
          );
          expect(
            boundsForPainting['axis1']!.max,
            lessThan(90),
            reason:
                'Max should not extend to full data range max when viewport is zoomed',
          );
        },
      );

      test(
        'multiple axes all get viewport-aware bounds with forPainting=true',
        () {
          final series = [
            ChartSeries(
              id: 's1',
              name: 'Series 1',
              points: [
                const ChartDataPoint(x: 0, y: 0),
                const ChartDataPoint(x: 10, y: 100),
              ],
              yAxisConfig: YAxisConfig.withId(
                id: 'axis1',
                position: YAxisPosition.left,
              ),
            ),
            ChartSeries(
              id: 's2',
              name: 'Series 2',
              points: [
                const ChartDataPoint(x: 0, y: 0),
                const ChartDataPoint(x: 10, y: 500),
              ],
              yAxisConfig: YAxisConfig.withId(
                id: 'axis2',
                position: YAxisPosition.right,
              ),
            ),
            ChartSeries(
              id: 's3',
              name: 'Series 3',
              points: [
                const ChartDataPoint(x: 0, y: 0),
                const ChartDataPoint(x: 10, y: 1000),
              ],
              yAxisConfig: YAxisConfig.withId(
                id: 'axis3',
                position: YAxisPosition.left,
              ),
            ),
          ];

          manager.setSeries(series);
          manager.setNormalizationMode(NormalizationMode.perSeries);

          final originalTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 400,
            plotHeight: 300,
          );

          // Zoom to middle 50%
          final zoomedTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 25,
            dataYMax: 75,
            plotWidth: 400,
            plotHeight: 300,
          );

          final boundsForPainting = manager.computeAxisBounds(
            transform: zoomedTransform,
            originalTransform: originalTransform,
            forPainting: true,
          );

          final boundsDefault = manager.computeAxisBounds(
            transform: zoomedTransform,
            originalTransform: originalTransform,
            forPainting: false,
          );

          // All three axes should have viewport-aware bounds
          expect(
            boundsForPainting['axis1']!.max,
            lessThan(boundsDefault['axis1']!.max),
          );
          expect(
            boundsForPainting['axis2']!.max,
            lessThan(boundsDefault['axis2']!.max),
          );
          expect(
            boundsForPainting['axis3']!.max,
            lessThan(boundsDefault['axis3']!.max),
          );

          // Each axis should reflect its own series' proportional zoom
          // Viewing middle 50% (25-75 of 0-100 range) means showing Y from 25% to 75%
          // Axis 1: 100 data, 25-75 visible → bounds ~22.5 to ~77.5 with padding
          // Axis 2: 500 data, same proportional zoom → bounds ~112.5 to ~387.5
          // Axis 3: 1000 data, same proportional zoom → bounds ~225 to ~775
          expect(
            boundsForPainting['axis1']!.max,
            lessThan(85),
            reason: 'Axis 1 max should reflect 75% point of padded range',
          );
          expect(
            boundsForPainting['axis2']!.max,
            lessThan(420),
            reason: 'Axis 2 max should reflect 75% point of padded range',
          );
          expect(
            boundsForPainting['axis3']!.max,
            lessThan(840),
            reason: 'Axis 3 max should reflect 75% point of padded range',
          );
        },
      );
    });

    group('Edge Cases', () {
      test('forPainting=true with extreme zoom (viewing 1% of data)', () {
        final series = [
          ChartSeries(
            id: 's1',
            name: 'Series 1',
            points: [
              const ChartDataPoint(x: 0, y: 0),
              const ChartDataPoint(x: 10, y: 1000),
            ],
            yAxisConfig: YAxisConfig.withId(
              id: 'axis1',
              position: YAxisPosition.left,
            ),
          ),
        ];

        manager.setSeries(series);
        manager.setNormalizationMode(NormalizationMode.perSeries);

        final originalTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 0,
          dataYMax: 1000,
          plotWidth: 400,
          plotHeight: 300,
        );

        // Extreme zoom: viewing only 495-505 (1% of range)
        final extremeZoomTransform = const ChartTransform(
          dataXMin: 0,
          dataXMax: 10,
          dataYMin: 495,
          dataYMax: 505,
          plotWidth: 400,
          plotHeight: 300,
        );

        final boundsForPainting = manager.computeAxisBounds(
          transform: extremeZoomTransform,
          originalTransform: originalTransform,
          forPainting: true,
        );

        // Bounds should be very narrow (around 495-505, plus 5% padding)
        final range =
            boundsForPainting['axis1']!.max - boundsForPainting['axis1']!.min;
        expect(
          range,
          lessThan(50),
          reason: 'Extreme zoom should produce narrow bounds',
        );

        // Center should be around 500
        final center =
            (boundsForPainting['axis1']!.min +
                boundsForPainting['axis1']!.max) /
            2;
        expect(
          center,
          closeTo(500.0, 10.0),
          reason: 'Extreme zoom should center around viewport center',
        );
      });

      test(
        'forPainting=true with no perSeries normalization has no effect',
        () {
          final series = [
            ChartSeries(
              id: 's1',
              name: 'Series 1',
              points: [
                const ChartDataPoint(x: 0, y: 0),
                const ChartDataPoint(x: 10, y: 100),
              ],
              yAxisConfig: YAxisConfig.withId(
                id: 'axis1',
                position: YAxisPosition.left,
              ),
            ),
          ];

          manager.setSeries(series);
          // NO perSeries normalization
          manager.setNormalizationMode(null);

          final originalTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 0,
            dataYMax: 100,
            plotWidth: 400,
            plotHeight: 300,
          );

          final zoomedTransform = const ChartTransform(
            dataXMin: 0,
            dataXMax: 10,
            dataYMin: 25,
            dataYMax: 75,
            plotWidth: 400,
            plotHeight: 300,
          );

          final boundsForPainting = manager.computeAxisBounds(
            transform: zoomedTransform,
            originalTransform: originalTransform,
            forPainting: true,
          );

          final boundsDefault = manager.computeAxisBounds(
            transform: zoomedTransform,
            originalTransform: originalTransform,
            forPainting: false,
          );

          // Without perSeries normalization, forPainting should have no effect
          expect(
            boundsForPainting['axis1']!.min,
            closeTo(boundsDefault['axis1']!.min, 0.1),
          );
          expect(
            boundsForPainting['axis1']!.max,
            closeTo(boundsDefault['axis1']!.max, 0.1),
          );
        },
      );
    });
  });
}
