import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scatter categorical values and styles round-trip portably', () {
    const source = ScatterChartSeries(
      id: 'vehicles',
      points: [
        ChartDataPoint(
          x: 1750,
          y: 5.8,
          label: 'Northstar E',
          categoryValue: 'electric',
        ),
      ],
      categoryEncoding: ScatterCategoryEncoding(
        label: 'Powertrain',
        categories: [
          ScatterCategoryStyle(
            key: 'electric',
            label: 'Electric',
            color: Color(0xFF2563EB),
            shape: SeriesMarkerShape.circle,
          ),
        ],
      ),
    );

    final encoded = ChartSeriesDocumentCodec.encode(source);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    expect(
      document.requiredCapabilities,
      contains('series.scatter.category-encoding.v1'),
    );
    expect(
      (document.data as InlineChartDataPayload).points.single.categoryValue,
      'electric',
    );

    final decoded = ChartSeriesDocumentCodec.decode(document);
    final series =
        (decoded as ChartArtifactSuccess<ChartSeries>).value
            as ScatterChartSeries;
    expect(series, source);
  });

  test('native category legends round-trip as annotations', () {
    final source = LegendAnnotation(
      id: 'category-key',
      categoryScale: const LegendCategoryScale(
        label: 'Powertrain',
        items: [
          LegendCategoryItem(
            label: 'Electric',
            color: Color(0xFF2563EB),
            shape: SeriesMarkerShape.circle,
          ),
        ],
      ),
    );
    final encoded = ChartAnnotationDocumentCodec.encode(source);
    final document =
        (encoded as ChartArtifactSuccess<ChartAnnotationDocument>).value;
    expect(
      document.requiredCapabilities,
      contains('annotation.legend.category-scale.v1'),
    );
    final decoded = ChartAnnotationDocumentCodec.decode(document);
    final annotation =
        (decoded as ChartArtifactSuccess<ChartAnnotation>).value
            as LegendAnnotation;
    expect(annotation.categoryScale, source.categoryScale);
  });
}
