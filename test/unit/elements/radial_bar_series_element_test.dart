import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radial_bar_series_element.dart';
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
  });
}
