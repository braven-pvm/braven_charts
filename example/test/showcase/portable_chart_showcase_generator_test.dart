import 'package:braven_charts_example/showcase/data/portable_chart_showcase_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'produces every portable showcase family through public chart series',
    () {
      for (final kind in PortableShowcaseChartKind.values) {
        final story = PortableChartShowcaseGenerator.generate(4200, kind: kind);

        expect(story.kind, kind);
        expect(story.series, isNotEmpty);
        expect(story.pointCount, greaterThan(0));
        expect(story.title, isNotEmpty);
        expect(story.explanation, isNotEmpty);
        expect(
          story.series.every((series) => series.points.isNotEmpty),
          isTrue,
        );
      }
    },
  );

  test('replays a generated story exactly from its seed', () {
    final first = PortableChartShowcaseGenerator.generate(7162026);
    final replay = PortableChartShowcaseGenerator.generate(7162026);

    expect(replay.kind, first.kind);
    expect(replay.title, first.title);
    expect(replay.series.length, first.series.length);
    expect(replay.series.first.runtimeType, first.series.first.runtimeType);
    expect(replay.series.first.color, first.series.first.color);
    expect(
      replay.series.first.points.map((point) => (point.x, point.y)),
      first.series.first.points.map((point) => (point.x, point.y)),
    );
  });
}
