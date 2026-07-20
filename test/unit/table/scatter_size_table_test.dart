import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scatter quantitative encodings survive Data and Split projection', () {
    const source = ScatterChartSeries(
      id: 'markets',
      name: 'Markets',
      points: [
        ChartDataPoint(
          x: 8,
          y: 92,
          magnitude: 340,
          colorValue: 78,
          opacityValue: 86,
          categoryValue: 'enterprise',
        ),
      ],
      sizeEncoding: ScatterSizeEncoding(label: 'Accounts', unit: 'k'),
      colorEncoding: ScatterColorEncoding(
        colors: [Color(0xFFDC2626), Color(0xFF16A34A)],
        label: 'Readiness',
        unit: '%',
      ),
      opacityEncoding: ScatterOpacityEncoding(label: 'Confidence', unit: '%'),
      categoryEncoding: ScatterCategoryEncoding(
        label: 'Segment',
        categories: [
          ScatterCategoryStyle(
            key: 'enterprise',
            label: 'Enterprise',
            color: Color(0xFF2563EB),
            shape: SeriesMarkerShape.diamond,
          ),
        ],
      ),
    );
    final encoded =
        ChartSeriesDocumentCodec.encode(source)
            as ChartArtifactSuccess<ChartSeriesDocument>;
    final document = ChartDocument(
      documentId: 'scatter-table',
      revision: 1,
      series: [encoded.value],
      xAxis: ChartAxisDocument(id: 'x', position: 'bottom'),
      axes: const [],
      theme: ChartThemeDocument(),
      interaction: ChartInteractionDocument(),
    );

    final model = ChartTableModel.fromDocument(document);
    final magnitude = model
        .longRows
        .single
        .auxiliaryValues[ChartTableAuxiliaryField.magnitude];
    final colorValue = model
        .longRows
        .single
        .auxiliaryValues[ChartTableAuxiliaryField.colorValue];
    final opacityValue = model
        .longRows
        .single
        .auxiliaryValues[ChartTableAuxiliaryField.opacityValue];

    expect(model.series.single.auxiliaryFields, {
      ChartTableAuxiliaryField.magnitude,
      ChartTableAuxiliaryField.colorValue,
      ChartTableAuxiliaryField.opacityValue,
    });
    expect(magnitude?.raw, 340);
    expect(magnitude?.display, '340 k');
    expect(magnitude?.isValid, isTrue);
    expect(colorValue?.raw, 78);
    expect(colorValue?.display, '78 %');
    expect(colorValue?.isValid, isTrue);
    expect(opacityValue?.raw, 86);
    expect(opacityValue?.display, '86 %');
    expect(opacityValue?.isValid, isTrue);
    expect(model.series.single.categoryLabel, 'Segment');
    expect(model.hasCategoryValues, isTrue);
    expect(model.longRows.single.categoryValue, 'enterprise');
  });
}
