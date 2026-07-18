import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadialSliceGroupingConfig', () {
    test(
      'projects qualifying points into one aggregate without changing data',
      () {
        final source = <ChartDataPoint>[
          const ChartDataPoint(x: 0, y: 70, label: 'Core'),
          const ChartDataPoint(x: 1, y: 20, label: 'Growth'),
          const ChartDataPoint(x: 2, y: 4, label: 'Email'),
          const ChartDataPoint(x: 3, y: 3, label: 'Chat'),
          const ChartDataPoint(x: 4, y: 3, label: 'Other source'),
        ];
        final series = DonutChartSeries(
          id: 'requests',
          points: source,
          sliceGroupingConfig: const RadialSliceGroupingConfig(
            minimumShare: 0.05,
            label: 'Other',
            color: Color(0xff6750a4),
          ),
        );

        expect(series.points, orderedEquals(source));
        expect(series.visibleSlices, hasLength(3));
        expect(
          series.visibleSlices.map((slice) => slice.point.label),
          orderedEquals(<String?>['Core', 'Growth', 'Other']),
        );
        final grouped = series.visibleSlices.last;
        expect(grouped.isGrouped, isTrue);
        expect(grouped.point.y, 10);
        expect(grouped.point.pointStyle?.color, const Color(0xff6750a4));
        expect(grouped.sourcePointIndices, orderedEquals(<int>[2, 3, 4]));
        expect(series.visiblePointIndices, orderedEquals(<int>[0, 1, 2]));
        expect(
          series.visibleSliceForSourcePointIndex(4)?.sourcePointIndices,
          orderedEquals(<int>[2, 3, 4]),
        );
      },
    );

    test('does not create a group until enough source points qualify', () {
      final series = PieChartSeries.fromMap(
        id: 'share',
        values: const {'Primary': 96, 'Small': 4},
        sliceGroupingConfig: const RadialSliceGroupingConfig(
          minimumShare: 0.05,
        ),
      );

      expect(series.visibleSlices, hasLength(2));
      expect(series.visibleSlices.last.isGrouped, isFalse);
      expect(series.visibleSlices.last.point.label, 'Small');
    });

    test('validates threshold, source count, label, and radius ambiguity', () {
      expect(
        () => DonutChartSeries.fromMap(
          id: 'bad-threshold',
          values: const {'A': 1, 'B': 1},
          sliceGroupingConfig: const RadialSliceGroupingConfig(minimumShare: 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => DonutChartSeries.fromMap(
          id: 'bad-count',
          values: const {'A': 1, 'B': 1},
          sliceGroupingConfig: const RadialSliceGroupingConfig(
            minimumSourceCount: 1,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => DonutChartSeries.fromMap(
          id: 'bad-label',
          values: const {'A': 1, 'B': 1},
          sliceGroupingConfig: const RadialSliceGroupingConfig(label: '  '),
        ),
        throwsArgumentError,
      );
      expect(
        () => DonutChartSeries.fromMap(
          id: 'ambiguous-radius',
          values: const {'A': 8, 'B': 1, 'C': 1},
          radiusValues: const {'A': 3, 'B': 2, 'C': 1},
          sliceGroupingConfig: const RadialSliceGroupingConfig(),
        ),
        throwsArgumentError,
      );
    });
  });
}
