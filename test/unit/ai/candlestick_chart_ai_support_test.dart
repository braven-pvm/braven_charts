import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AI builder creates a typed Candlestick series from explicit OHLC', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'candlestick',
      'series': [
        {
          'id': 'price',
          'name': 'Price',
          'unit': 'USD',
          'data': [
            {
              'x': 1,
              'open': 100,
              'high': 112,
              'low': 98,
              'close': 110,
              'timestamp': '2026-07-18T09:30:00Z',
              'label': 'Open',
            },
          ],
        },
      ],
      'style': {
        'candlestick_body_fill': 'filled',
        'candlestick_body_width_factor': .6,
        'candlestick_wick_width': 2,
        'candlestick_animation_stagger': .35,
      },
    });

    expect(result.chartType, ChartType.candlestick);
    final series = result.series.single as CandlestickChartSeries;
    final point = series.candles.single;
    expect(
      [point.open, point.high, point.low, point.close],
      [100, 112, 98, 110],
    );
    expect(point.timestamp, DateTime.utc(2026, 7, 18, 9, 30));
    expect(
      series.candlestickStyle.bodyFillMode,
      CandlestickBodyFillMode.filled,
    );
    expect(series.candlestickStyle.bodyWidthFactor, .6);
    expect(series.candlestickStyle.wickWidth, 2);
    expect(series.animation.staggerFraction, .35);
  });

  test('AI builder rejects generic x/y data for Candlestick', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'candlestick',
        'series': [
          {
            'id': 'price',
            'data': [
              {'x': 1, 'y': 110},
            ],
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('open'),
        ),
      ),
    );
  });

  test('AI builder rejects invalid OHLC ordering', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'candlestick',
        'series': [
          {
            'id': 'price',
            'data': [
              {'x': 1, 'open': 100, 'high': 99, 'low': 98, 'close': 110},
            ],
          },
        ],
      }),
      throwsArgumentError,
    );
  });

  test('tool schema advertises candlestick style keys at a discoverable path', () {
    final input =
        ChartToolSchema.createChartTool['input_schema']!
            as Map<String, dynamic>;
    final style =
        (input['properties']! as Map<String, dynamic>)['style']!
            as Map<String, dynamic>;
    final styleProperties = style['properties']! as Map<String, dynamic>;

    // An LLM reads style keys from `style.properties` — the same position
    // scatter_*/bar_*/pie_* use. All ten candlestick style keys must be here.
    expect(
      styleProperties.keys,
      containsAll(<String>[
        'candlestick_body_fill',
        'candlestick_body_width_factor',
        'candlestick_border_width',
        'candlestick_wick_width',
        'candlestick_corner_radius',
        'candlestick_animation_mode',
        'candlestick_animation_stagger',
        'candlestick_density_grouping',
        'candlestick_target_group_width',
        'candlestick_minimum_points_per_group',
      ]),
    );
  });

  test('tool schema advertises conditional OHLC requirements', () {
    final input =
        ChartToolSchema.createChartTool['input_schema']!
            as Map<String, dynamic>;
    final properties = input['properties']! as Map<String, dynamic>;
    final chartType = properties['chart_type']! as Map<String, dynamic>;
    final series = properties['series']! as Map<String, dynamic>;
    final seriesItem = series['items']! as Map<String, dynamic>;
    final data =
        (seriesItem['properties']! as Map<String, dynamic>)['data']!
            as Map<String, dynamic>;
    final point = data['items']! as Map<String, dynamic>;
    final pointProperties = point['properties']! as Map<String, dynamic>;
    final conditional =
        (input['allOf']! as List<dynamic>).single as Map<String, dynamic>;

    expect(chartType['enum'], contains('candlestick'));
    expect(pointProperties.keys, containsAll(['open', 'high', 'low', 'close']));
    expect(
      (((((conditional['then']! as Map<String, dynamic>)['properties']!
                      as Map<String, dynamic>)['series']!
                  as Map<String, dynamic>)['items']!
              as Map<String, dynamic>)['properties']!
          as Map<String, dynamic>)['data'],
      isA<Map<String, dynamic>>(),
    );
  });
}
