import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapContourData', () {
    test('interpolates a deterministic open contour', () {
      final data = HeatmapContourData(
        xCellCount: 2,
        yCellCount: 2,
        levels: const [0.5],
        samples: [
          HeatmapContourSample(
            xIndex: 0,
            yIndex: 0,
            value: 0,
            sourceIndices: const [0],
            sourcePointKeys: const ['bottom-left'],
          ),
          HeatmapContourSample(
            xIndex: 1,
            yIndex: 0,
            value: 1,
            sourceIndices: const [1],
            sourcePointKeys: const ['bottom-right'],
          ),
          HeatmapContourSample(
            xIndex: 0,
            yIndex: 1,
            value: 0,
            sourceIndices: const [2],
            sourcePointKeys: const ['top-left'],
          ),
          HeatmapContourSample(
            xIndex: 1,
            yIndex: 1,
            value: 1,
            sourceIndices: const [3],
            sourcePointKeys: const ['top-right'],
          ),
        ],
      );

      expect(data.paths, hasLength(1));
      final path = data.paths.single;
      expect(path.id, 'contour-0-path-0');
      expect(path.isClosed, isFalse);
      expect(path.points, hasLength(2));
      expect(path.points.map((point) => point.x), everyElement(0.5));
      expect(path.points.map((point) => point.y), containsAll([0, 1]));
      expect(path.sourceIndices, [0, 1, 2, 3]);
      expect(path.sourcePointKeys, [
        'bottom-left',
        'bottom-right',
        'top-left',
        'top-right',
      ]);
    });

    test('resolves saddle cells deterministically', () {
      HeatmapContourData extract() => HeatmapContourData(
        xCellCount: 2,
        yCellCount: 2,
        levels: const [0.5],
        samples: [
          HeatmapContourSample(xIndex: 0, yIndex: 0, value: 1),
          HeatmapContourSample(xIndex: 1, yIndex: 0, value: 0),
          HeatmapContourSample(xIndex: 0, yIndex: 1, value: 0),
          HeatmapContourSample(xIndex: 1, yIndex: 1, value: 1),
        ],
      );

      final first = extract();
      final second = extract();
      expect(first.paths, hasLength(2));
      expect(
        [
          for (final path in first.paths)
            [for (final point in path.points) (point.x, point.y)],
        ],
        [
          for (final path in second.paths)
            [for (final point in path.points) (point.x, point.y)],
        ],
      );
    });

    test('extracts closed loops and stable chart point metadata', () {
      final values = [
        [0.0, 0, 0],
        [0.0, 1, 0],
        [0.0, 0, 0],
      ];
      final data = HeatmapContourData(
        xCellCount: 3,
        yCellCount: 3,
        levels: const [0.5],
        samples: [
          for (var y = 0; y < 3; y++)
            for (var x = 0; x < 3; x++)
              HeatmapContourSample(
                xIndex: x,
                yIndex: y,
                value: values[y][x].toDouble(),
                sourceIndices: [y * 3 + x],
                sourcePointKeys: ['sample-$y-$x'],
              ),
        ],
      );

      expect(data.paths, hasLength(1));
      final path = data.paths.single;
      expect(path.isClosed, isTrue);
      expect(path.points.first.x, path.points.last.x);
      expect(path.points.first.y, path.points.last.y);
      final points = data.chartPointsFor(path);
      expect(points.first.pointKey, 'contour-0-path-0-point-0');
      expect(points.first.metadata?['densityContourLevel'], 0.5);
      expect(points.first.metadata?['densityContourClosed'], isTrue);
      expect(
        points.first.metadata?['densityContourSourcePointKeys'],
        isNotEmpty,
      );
    });

    test('extracts from density using absolute or relative values', () {
      final density = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(minimum: -2, maximum: 2, cellCount: 5),
        yAxis: HeatmapDensityAxis(minimum: -2, maximum: 2, cellCount: 5),
        bandwidthX: 1,
        bandwidthY: 1,
        observations: [
          HeatmapDensityObservation(x: 0, y: 0, pointKey: 'centre'),
        ],
      );

      final relative = HeatmapContourData.fromDensity(
        density,
        levels: const [0.5],
      );
      final absolute = HeatmapContourData.fromDensity(
        density,
        levels: [density.maximumDensity * 0.5],
        valueMode: HeatmapDensityValueMode.density,
      );
      expect(relative.paths, isNotEmpty);
      expect(absolute.paths.length, relative.paths.length);
      expect(relative.paths.first.sourcePointKeys, contains('centre'));
    });

    test('validates complete grids and strictly increasing levels', () {
      expect(
        () => HeatmapContourData(
          xCellCount: 1,
          yCellCount: 2,
          levels: const [0.5],
          samples: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapContourData(
          xCellCount: 2,
          yCellCount: 2,
          levels: const [0.5, 0.5],
          samples: [
            HeatmapContourSample(xIndex: 0, yIndex: 0, value: 0),
            HeatmapContourSample(xIndex: 1, yIndex: 0, value: 0),
            HeatmapContourSample(xIndex: 0, yIndex: 1, value: 0),
            HeatmapContourSample(xIndex: 1, yIndex: 1, value: 0),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
