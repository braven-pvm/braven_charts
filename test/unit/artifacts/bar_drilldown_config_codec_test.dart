import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bar drill-down hierarchy round-trips series and runtime binding name',
    () {
      const child = BarDrillNode(
        id: 'child',
        label: 'Child',
        series: [
          BarChartSeries(
            id: 'child-series',
            points: [ChartDataPoint(x: 0, y: 42, pointKey: 'answer')],
            barWidthPercent: 0.7,
          ),
        ],
        metadata: {'unit': '%'},
        mayHaveLazyChildren: true,
      );
      const source = BarDrilldownConfig(
        root: BarDrillNode(
          id: 'root',
          label: 'Root',
          series: [
            BarChartSeries(
              id: 'root-series',
              points: [
                ChartDataPoint(
                  x: 0,
                  y: 10,
                  metadata: {barDrillNodeIdMetadataKey: 'child'},
                ),
              ],
              barWidthPercent: 0.7,
            ),
          ],
          children: [child],
        ),
        activation: BarDrillActivation.selection,
        transition: BarDrillTransition.none,
        showBreadcrumbs: false,
        selectionPolicy: BarDrillSelectionPolicy.preserveStableIdentities,
        lazyResolverBinding: 'host.drill.resolve',
      );

      final encoded = BarDrilldownConfigCodec.encode(source);
      expect(encoded, isA<ChartArtifactSuccess<Map<String, Object?>>>());
      final document =
          (encoded as ChartArtifactSuccess<Map<String, Object?>>).value;
      final decoded = BarDrilldownConfigCodec.decode(document);

      expect(decoded, isA<ChartArtifactSuccess<BarDrilldownConfig>>());
      expect(
        (decoded as ChartArtifactSuccess<BarDrilldownConfig>).value,
        source,
      );
    },
  );

  test('bar drill-down hierarchy rejects duplicate node identities', () {
    const duplicated = BarDrilldownConfig(
      root: BarDrillNode(
        id: 'same',
        label: 'Root',
        series: [],
        children: [BarDrillNode(id: 'same', label: 'Child', series: [])],
      ),
    );

    expect(
      BarDrilldownConfigCodec.encode(duplicated),
      isA<ChartArtifactFailure<Map<String, Object?>>>(),
    );
  });
}
