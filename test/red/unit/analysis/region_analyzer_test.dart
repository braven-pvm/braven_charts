// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// @orchestra-task: 7

import 'dart:ui';

import 'package:braven_charts/src/analysis/region_analyzer.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/segment_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = RegionAnalyzer();

  // ===========================================================================
  // detectSegmentGroups() Tests
  // ===========================================================================
  group('RegionAnalyzer.detectSegmentGroups', () {
    // -------------------------------------------------------------------------
    // Contiguous same-style groups
    // -------------------------------------------------------------------------
    group('contiguous same-style groups', () {
      test('detects a single contiguous group of same-style points', () {
        // Arrange — points 0-4 all styled blue
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 10.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(1));
        expect(groups.first.source, equals(DataRegionSource.segment));
        expect(groups.first.startX, equals(0.0));
        expect(groups.first.endX, equals(4.0));
      });

      test('detects two contiguous groups with different styles', () {
        // Arrange — points 0-4 styled blue, points 5-9 styled red
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(2));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(4.0));
        expect(groups[1].startX, equals(5.0));
        expect(groups[1].endX, equals(9.0));
      });

      test('groups three contiguous segments with alternating styles', () {
        // Arrange — blue 0-2, red 3-5, green 6-8
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));
        const greenStyle = SegmentStyle(color: Color(0xFF00FF00));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 3).toDouble(),
              y: (i + 3) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 6).toDouble(),
              y: (i + 6) * 10.0,
              segmentStyle: greenStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(3));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(2.0));
        expect(groups[1].startX, equals(3.0));
        expect(groups[1].endX, equals(5.0));
        expect(groups[2].startX, equals(6.0));
        expect(groups[2].endX, equals(8.0));
      });
    });

    // -------------------------------------------------------------------------
    // FR-017: Non-adjacent same-style treated as separate
    // -------------------------------------------------------------------------
    group('non-adjacent same-style groups (FR-017 contiguity)', () {
      test('non-adjacent same-style groups are separate DataRegions', () {
        // Arrange — blue 0-4, red 5-9, blue 10-14
        // Even though groups 1 and 3 share the same style,
        // they MUST be separate because they are non-adjacent.
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 10).toDouble(),
              y: (i + 10) * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — three separate groups, NOT two merged blue groups
        expect(groups, hasLength(3));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(4.0));
        expect(groups[1].startX, equals(5.0));
        expect(groups[1].endX, equals(9.0));
        expect(groups[2].startX, equals(10.0));
        expect(groups[2].endX, equals(14.0));
      });

      test(
        'non-adjacent same-style with unstyled gap produces separate groups',
        () {
          // Arrange — blue 0-2, unstyled 3-4, blue 5-7
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));

          final points = <ChartDataPoint>[
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            // Unstyled gap
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 4.0, y: 40.0),
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: (i + 5).toDouble(),
                y: (i + 5) * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
          ];

          // Act
          final groups = analyzer.detectSegmentGroups('series-a', points);

          // Assert — two separate blue groups, unstyled gap excluded
          expect(groups, hasLength(2));
          expect(groups[0].startX, equals(0.0));
          expect(groups[0].endX, equals(2.0));
          expect(groups[1].startX, equals(5.0));
          expect(groups[1].endX, equals(7.0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Unstyled points excluded
    // -------------------------------------------------------------------------
    group('unstyled points excluded', () {
      test('returns empty list when all points are unstyled', () {
        // Arrange — no segment styles
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0),
        );

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, isEmpty);
      });

      test('unstyled points between styled groups are excluded', () {
        // Arrange — styled 0-2, unstyled 3-6, styled 7-9
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          // Unstyled gap
          ...List.generate(
            4,
            (i) => ChartDataPoint(x: (i + 3).toDouble(), y: (i + 3) * 10.0),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 7).toDouble(),
              y: (i + 7) * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — two groups, unstyled points excluded
        expect(groups, hasLength(2));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(2.0));
        expect(groups[1].startX, equals(7.0));
        expect(groups[1].endX, equals(9.0));
      });
    });

    // -------------------------------------------------------------------------
    // Single-point segments
    // -------------------------------------------------------------------------
    group('single-point segments', () {
      test('single styled point creates a valid group with startX == endX', () {
        // Arrange — only one styled point among unstyled
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = <ChartDataPoint>[
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — single-point segment is valid
        expect(groups, hasLength(1));
        expect(groups.first.startX, equals(2.0));
        expect(groups.first.endX, equals(2.0));
        expect(groups.first.source, equals(DataRegionSource.segment));
      });

      test('multiple isolated styled points each create their own group', () {
        // Arrange — styled at index 1, 3, 5 with unstyled in between
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = <ChartDataPoint>[
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 10.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0, segmentStyle: blueStyle),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — three separate single-point groups
        expect(groups, hasLength(3));
        expect(groups[0].startX, equals(1.0));
        expect(groups[0].endX, equals(1.0));
        expect(groups[1].startX, equals(3.0));
        expect(groups[1].endX, equals(3.0));
        expect(groups[2].startX, equals(5.0));
        expect(groups[2].endX, equals(5.0));
      });
    });

    // -------------------------------------------------------------------------
    // All-same-style series
    // -------------------------------------------------------------------------
    group('all-same-style series', () {
      test('all points with same style form a single group', () {
        // Arrange
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          20,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 5.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(1));
        expect(groups.first.startX, equals(0.0));
        expect(groups.first.endX, equals(19.0));
        expect(groups.first.source, equals(DataRegionSource.segment));
      });
    });

    // -------------------------------------------------------------------------
    // ID format and source type
    // -------------------------------------------------------------------------
    group('segment ID format and source type', () {
      test(
        'segment group ID follows format segment_<seriesId>_<startIndex>',
        () {
          // Arrange
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
          const redStyle = SegmentStyle(color: Color(0xFFFF0000));

          final points = <ChartDataPoint>[
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: (i + 3).toDouble(),
                y: (i + 3) * 10.0,
                segmentStyle: redStyle,
              ),
            ),
          ];

          // Act
          final groups = analyzer.detectSegmentGroups('my-series', points);

          // Assert — verify ID format
          expect(groups, hasLength(2));
          expect(groups[0].id, equals('segment_my-series_0'));
          expect(groups[1].id, equals('segment_my-series_3'));
        },
      );

      test('all segment groups have source DataRegionSource.segment', () {
        // Arrange
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 3).toDouble(),
              y: (i + 3) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        for (final group in groups) {
          expect(group.source, equals(DataRegionSource.segment));
        }
      });
    });

    // -------------------------------------------------------------------------
    // startX/endX from group's first/last point X values
    // -------------------------------------------------------------------------
    group('startX/endX from group first/last point X values', () {
      test('startX and endX match the X values of grouped points', () {
        // Arrange — styled from x=2.5 to x=7.5
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = <ChartDataPoint>[
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.5, y: 25.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 5.0, y: 50.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 7.5, y: 75.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 9.0, y: 90.0),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(1));
        expect(groups.first.startX, equals(2.5));
        expect(groups.first.endX, equals(7.5));
      });
    });

    // -------------------------------------------------------------------------
    // Empty input
    // -------------------------------------------------------------------------
    group('empty input', () {
      test('returns empty list for empty points', () {
        final groups = analyzer.detectSegmentGroups(
          'series-a',
          <ChartDataPoint>[],
        );
        expect(groups, isEmpty);
      });
    });
  });

  // ===========================================================================
  // segmentGroupForPoint() Tests
  // ===========================================================================
  group('RegionAnalyzer.segmentGroupForPoint', () {
    // -------------------------------------------------------------------------
    // Point inside a group returns correct DataRegion
    // -------------------------------------------------------------------------
    group('point inside a group', () {
      test(
        'returns correct DataRegion for a point in the middle of a group',
        () {
          // Arrange — points 0-9 styled blue, 10-19 styled red
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
          const redStyle = SegmentStyle(color: Color(0xFFFF0000));

          final points = <ChartDataPoint>[
            ...List.generate(
              10,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            ...List.generate(
              10,
              (i) => ChartDataPoint(
                x: (i + 10).toDouble(),
                y: (i + 10) * 10.0,
                segmentStyle: redStyle,
              ),
            ),
          ];

          // Act — query point 5 which is in the blue group (0-9)
          final result = analyzer.segmentGroupForPoint('series-a', points, 5);

          // Assert
          expect(result, isNotNull);
          expect(result!.source, equals(DataRegionSource.segment));
          expect(result.startX, equals(0.0));
          expect(result.endX, equals(9.0));
        },
      );

      test('returns correct DataRegion for a point in the second group', () {
        // Arrange — points 0-4 styled blue, 5-9 styled red
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act — query point 7 which is in the red group (5-9)
        final result = analyzer.segmentGroupForPoint('series-a', points, 7);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(5.0));
        expect(result.endX, equals(9.0));
      });
    });

    // -------------------------------------------------------------------------
    // Point outside any group returns null
    // -------------------------------------------------------------------------
    group('point outside any group', () {
      test('returns null for an unstyled point', () {
        // Arrange — styled 0-4, unstyled 5-9
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(x: (i + 5).toDouble(), y: (i + 5) * 10.0),
          ),
        ];

        // Act — query point 7 which is unstyled
        final result = analyzer.segmentGroupForPoint('series-a', points, 7);

        // Assert
        expect(result, isNull);
      });

      test('returns null when all points are unstyled', () {
        // Arrange
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0),
        );

        // Act
        final result = analyzer.segmentGroupForPoint('series-a', points, 5);

        // Assert
        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Boundary points (first/last in group) included
    // -------------------------------------------------------------------------
    group('boundary points (first/last in group)', () {
      test('returns correct DataRegion for the first point in a group', () {
        // Arrange — blue 0-4
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 10.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act — query the first point (index 0)
        final result = analyzer.segmentGroupForPoint('series-a', points, 0);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(0.0));
        expect(result.endX, equals(4.0));
      });

      test('returns correct DataRegion for the last point in a group', () {
        // Arrange — blue 0-4
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 10.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act — query the last point (index 4)
        final result = analyzer.segmentGroupForPoint('series-a', points, 4);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(0.0));
        expect(result.endX, equals(4.0));
      });

      test('first point of second group returns second group, not first', () {
        // Arrange — blue 0-4, red 5-9
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act — query point 5 which is the first point of the red group
        final result = analyzer.segmentGroupForPoint('series-a', points, 5);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(5.0));
        expect(result.endX, equals(9.0));
      });
    });

    // -------------------------------------------------------------------------
    // Contiguity verification
    // -------------------------------------------------------------------------
    group('contiguity verification', () {
      test(
        'non-adjacent same-style: tap point 12 returns only group 10-14',
        () {
          // Arrange — blue 0-4, red 5-9, blue 10-14
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
          const redStyle = SegmentStyle(color: Color(0xFFFF0000));

          final points = <ChartDataPoint>[
            ...List.generate(
              5,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            ...List.generate(
              5,
              (i) => ChartDataPoint(
                x: (i + 5).toDouble(),
                y: (i + 5) * 10.0,
                segmentStyle: redStyle,
              ),
            ),
            ...List.generate(
              5,
              (i) => ChartDataPoint(
                x: (i + 10).toDouble(),
                y: (i + 10) * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
          ];

          // Act — query point 12 which is in the second blue group
          final result = analyzer.segmentGroupForPoint('series-a', points, 12);

          // Assert — must return the 10-14 group, NOT the 0-4 group
          expect(result, isNotNull);
          expect(result!.startX, equals(10.0));
          expect(result.endX, equals(14.0));
          expect(result.source, equals(DataRegionSource.segment));
        },
      );
    });
  });
}
