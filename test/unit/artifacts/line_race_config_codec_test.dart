import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('line-race config round-trips sparse portable frames', () {
    const source = LineRaceConfig(
      series: [
        LineRaceSeries(id: 'a', name: 'Alpha', color: Colors.blue),
        LineRaceSeries(id: 'b', name: 'Beta', color: Colors.red),
      ],
      frames: [
        LineRaceFrame(id: '1', label: 'Round 1', x: 1, values: {'a': 10}),
        LineRaceFrame(
          id: '2',
          label: 'Round 2',
          x: 2,
          values: {'a': 12.5, 'b': 8},
        ),
      ],
      durationPerFrame: Duration(milliseconds: 1250),
      loop: true,
    );

    final encoded = LineRaceConfigCodec.encode(source);
    expect(encoded, isA<ChartArtifactSuccess<Map<String, Object?>>>());
    final document =
        (encoded as ChartArtifactSuccess<Map<String, Object?>>).value;
    final decoded = LineRaceConfigCodec.decode(document);

    expect(decoded, isA<ChartArtifactSuccess<LineRaceConfig>>());
    expect((decoded as ChartArtifactSuccess<LineRaceConfig>).value, source);
  });

  test('line-race codec rejects unknown series identities', () {
    final result = LineRaceConfigCodec.decode({
      'type': 'lineRace',
      'schemaVersion': 1,
      'series': [
        {'id': 'known', 'name': 'Known', 'color': 0xFF000000},
      ],
      'frames': [
        {
          'id': 'one',
          'label': 'One',
          'x': 1,
          'values': {'unknown': 1},
        },
      ],
      'durationPerFrameMs': 800,
      'loop': false,
    });

    expect(result, isA<ChartArtifactFailure<LineRaceConfig>>());
  });
}
