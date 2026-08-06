import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bar-race config round-trips every portable property', () {
    final source = BarRaceConfig(
      categories: const [
        BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
        BarRaceCategory(id: 'b', label: 'Beta', color: Colors.red),
      ],
      frames: [
        BarRaceFrame(
          id: '2025',
          label: 'FY 2025',
          timestamp: DateTime(2025, 1, 15),
          values: {'a': 12.5, 'b': 8},
          total: 20.5,
        ),
        BarRaceFrame(
          id: '2026',
          label: 'FY 2026',
          values: {'a': 13, 'b': 15},
          total: 28,
        ),
      ],
      topCount: 2,
      durationPerFrame: Duration(milliseconds: 1250),
      axisRange: BarRaceAxisRange.fixed,
      sort: BarRaceSort.ascending,
      loop: true,
      showPeriod: false,
      showTotal: true,
      periodStyle: const BarRacePeriodStyle(
        position: BarRacePeriodPosition.topLeft,
        fontSize: 72,
        color: Colors.purple,
        fontWeight: FontWeight.w400,
        opacity: 0.6,
        inset: 18,
        supportingTextSize: 14,
      ),
      periodFormat: const BarRacePeriodFormat(pattern: '{MMM} {yyyy}'),
      valueFormat: const BarRaceValueFormat(
        pattern: r'$ {value}M',
        notation: BarRaceValueNotation.standard,
        decimalPlaces: 2,
        useGrouping: false,
        trimTrailingZeros: false,
        scale: 1000,
      ),
      totalFormat: const BarRaceValueFormat(
        pattern: '{value} combined',
        notation: BarRaceValueNotation.scientific,
        decimalPlaces: 3,
      ),
    );

    final encoded = BarRaceConfigCodec.encode(source);
    expect(encoded, isA<ChartArtifactSuccess<Map<String, Object?>>>());
    final document =
        (encoded as ChartArtifactSuccess<Map<String, Object?>>).value;
    final decoded = BarRaceConfigCodec.decode(document);

    expect(decoded, isA<ChartArtifactSuccess<BarRaceConfig>>());
    expect((decoded as ChartArtifactSuccess<BarRaceConfig>).value, source);
  });

  test('bar-race config rejects unknown frame categories', () {
    final result = BarRaceConfigCodec.decode({
      'type': 'barRace',
      'schemaVersion': 1,
      'categories': [
        {'id': 'known', 'label': 'Known', 'color': 0xFF000000},
      ],
      'frames': [
        {
          'id': 'one',
          'label': 'One',
          'values': {'unknown': 1},
        },
      ],
      'topCount': 1,
      'durationPerFrameMs': 800,
      'axisRange': 'dynamic',
      'sort': 'descending',
      'loop': false,
      'showPeriod': true,
      'showTotal': false,
    });

    expect(result, isA<ChartArtifactFailure<BarRaceConfig>>());
  });

  test('legacy schema defaults new portable format descriptors', () {
    final result = BarRaceConfigCodec.decode({
      'type': 'barRace',
      'schemaVersion': 1,
      'categories': [
        {'id': 'a', 'label': 'Alpha', 'color': 0xFF000000},
      ],
      'frames': [
        {
          'id': 'one',
          'label': 'One',
          'values': {'a': 1},
        },
      ],
      'topCount': 1,
      'durationPerFrameMs': 800,
      'axisRange': 'dynamic',
      'sort': 'descending',
      'loop': false,
      'showPeriod': true,
      'showTotal': false,
    });

    expect(result, isA<ChartArtifactSuccess<BarRaceConfig>>());
    final config = (result as ChartArtifactSuccess<BarRaceConfig>).value;
    expect(config.periodFormat.pattern, '{label}');
    expect(config.valueFormat.pattern, '{value}');
    expect(config.totalFormat.notation, BarRaceValueNotation.compact);
  });

  test('rejects value patterns without the portable placeholder', () {
    const source = BarRaceConfig(
      categories: [
        BarRaceCategory(id: 'a', label: 'Alpha', color: Colors.blue),
      ],
      frames: [
        BarRaceFrame(id: 'one', label: 'One', values: {'a': 1}),
      ],
      topCount: 1,
      valueFormat: BarRaceValueFormat(pattern: 'missing token'),
    );

    expect(
      BarRaceConfigCodec.encode(source),
      isA<ChartArtifactFailure<Map<String, Object?>>>(),
    );
  });
}
