// @orchestra-task: 3
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/analysis/region_analyzer.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = RegionAnalyzer();

  // ===========================================================================
  // filterPointsInRange() Tests
  // ===========================================================================
  group('RegionAnalyzer.filterPointsInRange', () {
    // -------------------------------------------------------------------------
    // Sorted data — binary-search fast-path (isSorted: true, the default)
    // -------------------------------------------------------------------------
    group('sorted data (binary search path, isSorted: true)', () {
      test('returns points within range for sorted ascending data', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
          const ChartDataPoint(x: 8.0, y: 80.0),
          const ChartDataPoint(x: 9.0, y: 90.0),
          const ChartDataPoint(x: 10.0, y: 100.0),
        ];

        // Act — isSorted defaults to true, uses binary search
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 7.0,
        );

        // Assert
        expect(result, hasLength(5));
        expect(
          result.map((p) => p.x),
          containsAllInOrder([3.0, 4.0, 5.0, 6.0, 7.0]),
        );
      });

      test('returns correct Y values for filtered range', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 100.0),
          const ChartDataPoint(x: 2.0, y: 200.0),
          const ChartDataPoint(x: 3.0, y: 300.0),
          const ChartDataPoint(x: 4.0, y: 400.0),
          const ChartDataPoint(x: 5.0, y: 500.0),
        ];

        // Act — explicit isSorted: true
        final result = analyzer.filterPointsInRange(
          points,
          startX: 2.0,
          endX: 4.0,
          isSorted: true,
        );

        // Assert
        expect(result, hasLength(3));
        expect(result[0].y, equals(200.0));
        expect(result[1].y, equals(300.0));
        expect(result[2].y, equals(400.0));
      });
    });

    // -------------------------------------------------------------------------
    // Unsorted data — linear-scan fallback (isSorted: false)
    // -------------------------------------------------------------------------
    group('unsorted data (linear scan fallback, isSorted: false)', () {
      test('returns points within range for unsorted data', () {
        // Arrange — data intentionally out of order
        final points = [
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 8.0, y: 80.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 9.0, y: 90.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
          const ChartDataPoint(x: 10.0, y: 100.0),
        ];

        // Act — explicit isSorted: false forces linear scan
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 7.0,
          isSorted: false,
        );

        // Assert — should contain same 5 points regardless of order
        expect(result, hasLength(5));
        expect(
          result.map((p) => p.x).toSet(),
          equals({3.0, 4.0, 5.0, 6.0, 7.0}),
        );
      });

      test('returns same results as sorted path for equivalent data', () {
        // Arrange — descending order, must use isSorted: false
        final unsortedPoints = [
          const ChartDataPoint(x: 10.0, y: 100.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          unsortedPoints,
          startX: 3.0,
          endX: 7.0,
          isSorted: false,
        );

        // Assert — all points with x in [3.0, 7.0]
        expect(result, hasLength(3));
        expect(result.map((p) => p.x).toSet(), equals({3.0, 5.0, 7.0}));
      });
    });

    // -------------------------------------------------------------------------
    // Inclusive boundaries
    // -------------------------------------------------------------------------
    group('inclusive boundaries', () {
      test('includes points exactly at startX boundary', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 2.0,
          endX: 5.0,
        );

        // Assert
        expect(result.any((p) => p.x == 2.0), isTrue);
      });

      test('includes points exactly at endX boundary', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 0.0,
          endX: 2.0,
        );

        // Assert
        expect(result.any((p) => p.x == 2.0), isTrue);
      });

      test(
        'includes points at both startX and endX boundaries simultaneously',
        () {
          // Arrange
          final points = [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 2.0, y: 20.0),
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 4.0, y: 40.0),
            const ChartDataPoint(x: 5.0, y: 50.0),
          ];

          // Act
          final result = analyzer.filterPointsInRange(
            points,
            startX: 2.0,
            endX: 4.0,
          );

          // Assert
          expect(result, hasLength(3));
          expect(result.first.x, equals(2.0));
          expect(result.last.x, equals(4.0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Empty input
    // -------------------------------------------------------------------------
    group('empty input', () {
      test('returns empty list when input points list is empty', () {
        // Arrange
        final points = <ChartDataPoint>[];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 0.0,
          endX: 10.0,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Boundary duplicates
    // -------------------------------------------------------------------------
    group('boundary duplicates', () {
      test('includes all duplicate points at the startX boundary', () {
        // Arrange — three points share x=3.0
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 3.0, y: 35.0),
          const ChartDataPoint(x: 3.0, y: 38.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 5.0,
        );

        // Assert — all three x=3.0 points plus x=4.0 and x=5.0
        expect(result, hasLength(5));
        expect(result.where((p) => p.x == 3.0), hasLength(3));
      });

      test('includes all duplicate points at the endX boundary', () {
        // Arrange — multiple points at x=5.0
        final points = [
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 5.0, y: 55.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 5.0,
        );

        // Assert
        expect(result, hasLength(4));
        expect(result.where((p) => p.x == 5.0), hasLength(2));
      });
    });

    // -------------------------------------------------------------------------
    // Single-point match (startX == endX)
    // -------------------------------------------------------------------------
    group('single-point match', () {
      test('returns matching point when startX equals endX', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 3.0,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.x, equals(3.0));
        expect(result.first.y, equals(30.0));
      });

      test('returns empty when no point matches single-point query', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act — query at x=2.0 where no point exists
        final result = analyzer.filterPointsInRange(
          points,
          startX: 2.0,
          endX: 2.0,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Range outside data
    // -------------------------------------------------------------------------
    group('range outside data', () {
      test('returns empty when range is entirely before all data points', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 1.0,
          endX: 4.0,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('returns empty when range is entirely after all data points', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 10.0,
          endX: 20.0,
        );

        // Assert
        expect(result, isEmpty);
      });

      test(
        'returns empty when range falls between non-contiguous data points',
        () {
          // Arrange — gap between x=3.0 and x=7.0
          final points = [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 7.0, y: 70.0),
            const ChartDataPoint(x: 9.0, y: 90.0),
          ];

          // Act — query x=4.0 to x=6.0 falls in the gap
          final result = analyzer.filterPointsInRange(
            points,
            startX: 4.0,
            endX: 6.0,
          );

          // Assert
          expect(result, isEmpty);
        },
      );
    });
  });

  // ===========================================================================
  // regionFromAnnotation() Tests
  // ===========================================================================
  group('RegionAnalyzer.regionFromAnnotation', () {
    group('builds DataRegion from RangeAnnotation and multi-series data', () {
      test('creates DataRegion with correct source and X-range', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'test-range',
          startX: 2.0,
          endX: 8.0,
          label: 'Test Range',
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'series-a': [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 5.0, y: 50.0),
            const ChartDataPoint(x: 7.0, y: 70.0),
            const ChartDataPoint(x: 9.0, y: 90.0),
          ],
        };

        // Act — positional args per spec contract
        final region = analyzer.regionFromAnnotation(
          annotation,
          allSeriesData,
        );

        // Assert
        expect(region.source, equals(DataRegionSource.rangeAnnotation));
        expect(region.startX, equals(2.0));
        expect(region.endX, equals(8.0));
        expect(region.id, isNotEmpty);
      });

      test('maps filtered points correctly per series', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'multi-series-range',
          startX: 3.0,
          endX: 7.0,
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'power': [
            const ChartDataPoint(x: 1.0, y: 100.0),
            const ChartDataPoint(x: 3.0, y: 300.0),
            const ChartDataPoint(x: 5.0, y: 500.0),
            const ChartDataPoint(x: 7.0, y: 700.0),
            const ChartDataPoint(x: 9.0, y: 900.0),
          ],
          'heartrate': [
            const ChartDataPoint(x: 1.0, y: 70.0),
            const ChartDataPoint(x: 4.0, y: 120.0),
            const ChartDataPoint(x: 6.0, y: 150.0),
            const ChartDataPoint(x: 10.0, y: 80.0),
          ],
        };

        // Act
        final region = analyzer.regionFromAnnotation(
          annotation,
          allSeriesData,
        );

        // Assert — power series: x=3,5,7 (3 points in range)
        expect(region.seriesData['power'], hasLength(3));
        expect(
          region.seriesData['power']!.map((p) => p.x).toList(),
          equals([3.0, 5.0, 7.0]),
        );

        // Assert — heartrate series: x=4,6 (2 points in range)
        expect(region.seriesData['heartrate'], hasLength(2));
        expect(
          region.seriesData['heartrate']!.map((p) => p.x).toList(),
          equals([4.0, 6.0]),
        );
      });
    });

    group('excludes series with no matching points', () {
      test('omits series with zero points in range from seriesData', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'partial-range',
          startX: 3.0,
          endX: 5.0,
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'in-range': [
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 4.0, y: 40.0),
          ],
          'out-of-range': [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 2.0, y: 20.0),
            const ChartDataPoint(x: 6.0, y: 60.0),
          ],
        };

        // Act
        final region = analyzer.regionFromAnnotation(
          annotation,
          allSeriesData,
        );

        // Assert — only 'in-range' series should be in result
        expect(region.seriesData.containsKey('in-range'), isTrue);
        expect(region.seriesData.containsKey('out-of-range'), isFalse);
        expect(region.seriesData['in-range'], hasLength(2));
      });
    });

    group('handles empty series gracefully', () {
      test(
        'returns DataRegion with empty seriesData when no series provided',
        () {
          // Arrange
          final annotation = RangeAnnotation(
            id: 'empty-range',
            startX: 3.0,
            endX: 5.0,
          );
          final allSeriesData = <String, List<ChartDataPoint>>{};

          // Act
          final region = analyzer.regionFromAnnotation(
            annotation,
            allSeriesData,
          );

          // Assert
          expect(region.seriesData, isEmpty);
          expect(region.source, equals(DataRegionSource.rangeAnnotation));
        },
      );

      test(
        'returns DataRegion with empty seriesData when series have empty point lists',
        () {
          // Arrange
          final annotation = RangeAnnotation(
            id: 'empty-points-range',
            startX: 1.0,
            endX: 10.0,
          );
          final allSeriesData = <String, List<ChartDataPoint>>{
            'empty-series': <ChartDataPoint>[],
          };

          // Act
          final region = analyzer.regionFromAnnotation(
            annotation,
            allSeriesData,
          );

          // Assert — empty series should be excluded from result
          expect(region.seriesData, isEmpty);
        },
      );

      test('handles mix of populated and empty series', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'mix-range',
          startX: 2.0,
          endX: 6.0,
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'has-data': [
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 5.0, y: 50.0),
          ],
          'empty': <ChartDataPoint>[],
          'none-in-range': [const ChartDataPoint(x: 10.0, y: 100.0)],
        };

        // Act
        final region = analyzer.regionFromAnnotation(
          annotation,
          allSeriesData,
        );

        // Assert — only 'has-data' should remain
        expect(region.seriesData.keys, equals(['has-data']));
        expect(region.seriesData['has-data'], hasLength(2));
      });
    });
  });
}
