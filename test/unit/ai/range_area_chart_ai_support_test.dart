import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI builder creates atomic Range Area intervals and gaps', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'line',
      'series': [
        {
          'id': 'forecast-band',
          'name': 'Forecast interval',
          'type': 'rangeArea',
          'unit': '°C',
          'data': [
            {
              'x': 1,
              'low': 8.5,
              'high': 13.5,
              'timestamp': '2026-07-21T09:30:00Z',
              'label': 'Morning',
            },
            {'x': 2, 'gap': true, 'label': 'Missing'},
            {'x': 3, 'low': 10, 'high': 16},
          ],
        },
        {
          'id': 'forecast',
          'type': 'line',
          'data': [
            {'x': 1, 'y': 11},
            {'x': 2, 'y': 12},
            {'x': 3, 'y': 13},
          ],
        },
      ],
    });

    final band = result.series.first as RangeAreaChartSeries;
    expect(band.intervals, hasLength(3));
    expect(band.intervals.first.low, 8.5);
    expect(band.intervals.first.high, 13.5);
    expect(band.intervals.first.midpoint, 11);
    expect(band.intervals.first.timestamp, DateTime.utc(2026, 7, 21, 9, 30));
    expect(band.intervals[1].isGap, isTrue);
    expect(band.intervals.last.span, 6);
    expect(result.series.last, isA<LineChartSeries>());
  });

  test('AI builder rejects generic x/y Range Area input', () {
    expect(
      () => _build([
        {'x': 1, 'y': 12},
      ]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('low and high'),
        ),
      ),
    );
  });

  test('AI builder rejects half intervals and malformed gaps', () {
    expect(
      () => _build([
        {'x': 1, 'low': 8},
      ]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('high'),
        ),
      ),
    );
    expect(
      () => _build([
        {'x': 1, 'gap': true, 'low': 8, 'high': 12},
      ]),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('cannot include low, high, or y'),
        ),
      ),
    );
  });

  test('AI builder shares direct model validation', () {
    expect(
      () => _build([
        {'x': 1, 'low': 12, 'high': 8},
      ]),
      throwsArgumentError,
    );
    expect(
      () => _build([
        {'x': 2, 'low': 8, 'high': 12},
        {'x': 1, 'low': 9, 'high': 13},
      ]),
      throwsArgumentError,
    );
  });

  test('AI builder rejects unknown explicit series types', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'series': [
          {
            'id': 'unknown',
            'type': 'mysteryBand',
            'data': [
              {'x': 1, 'y': 2},
            ],
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Unsupported series type'),
        ),
      ),
    );
  });

  test('tool schema advertises interval and explicit-gap contracts', () {
    final input =
        ChartToolSchema.createChartTool['input_schema']!
            as Map<String, dynamic>;
    final properties = input['properties']! as Map<String, dynamic>;
    final series = properties['series']! as Map<String, dynamic>;
    final seriesItem = series['items']! as Map<String, dynamic>;
    final seriesProperties = seriesItem['properties']! as Map<String, dynamic>;
    final type = seriesProperties['type']! as Map<String, dynamic>;
    final data = seriesProperties['data']! as Map<String, dynamic>;
    final point = data['items']! as Map<String, dynamic>;
    final pointProperties = point['properties']! as Map<String, dynamic>;
    final conditional =
        (input['allOf']! as List<dynamic>).single as Map<String, dynamic>;
    final otherwise = conditional['else']! as Map<String, dynamic>;
    final otherwiseSeries =
        (otherwise['properties']! as Map<String, dynamic>)['series']!
            as Map<String, dynamic>;
    final otherwisePoint =
        (((otherwiseSeries['items']! as Map<String, dynamic>)['properties']!
                    as Map<String, dynamic>)['data']!
                as Map<String, dynamic>)['items']!
            as Map<String, dynamic>;

    expect(type['enum'], contains('rangeArea'));
    expect(pointProperties.keys, containsAll(['low', 'high', 'gap']));
    expect(otherwisePoint['anyOf'], hasLength(3));
  });
}

ChartBuildResult _build(List<Map<String, dynamic>> data) =>
    ChartConfigBuilder.fromJson({
      'series': [
        {'id': 'range', 'type': 'rangeArea', 'data': data},
      ],
    });
