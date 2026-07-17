import 'package:braven_charts/src/coordinates/chart_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transposed ChartTransform', () {
    const transform = ChartTransform(
      dataXMin: 0,
      dataXMax: 4,
      dataYMin: -100,
      dataYMax: 100,
      plotWidth: 400,
      plotHeight: 200,
      transposed: true,
    );

    test('maps semantic categories vertically and values horizontally', () {
      expect(transform.dataToPlot(1, 50), const Offset(300, 50));
      expect(transform.plotToData(300, 50), const Offset(1, 50));
      expect(transform.pixelsPerDataX, 50);
      expect(transform.pixelsPerDataY, 2);
    });

    test('preserves transposition through copy, zoom, and pan', () {
      expect(transform.copyWith(plotWidth: 500).transposed, isTrue);
      expect(transform.zoom(2, const Offset(200, 100)).transposed, isTrue);
      final panned = transform.pan(20, 10);
      expect(panned.transposed, isTrue);
      expect(panned.dataXMin, closeTo(0.2, 0.0001));
      expect(panned.dataYMin, closeTo(-90, 0.0001));
    });
  });
}
