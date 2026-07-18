import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds and persists a fully configured analytical bar chart', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'bar',
      'title': 'Operating range',
      'x_axis': {
        'label': 'Channel',
        'categories': ['Enterprise', 'Online'],
        'category_label_density': 'show_all',
        'category_label_overflow': 'ellipsis',
        'category_minimum_extent': 72,
        'category_maximum_label_extent': 120,
        'category_max_label_lines': 1,
        'category_label_rotation': -15,
        'category_auto_viewport': false,
      },
      'series': [
        {
          'id': 'current',
          'name': 'Current',
          'unit': 'kWh',
          'color': '#168AAD',
          'bar_group_id': 'actual',
          'bar_overlay_width_factor': 0.72,
          'bar_overlay_offset_factor': -0.1,
          'data': [
            {
              'x': 0,
              'y': 88,
              'label': 'Enterprise',
              'bar_start': 42,
              'bar_target': 92,
              'bar_error_lower': 82,
              'bar_error_upper': 94,
            },
            {
              'x': 1,
              'y': 76,
              'label': 'Online',
              'bar_start': 35,
              'bar_target': 80,
              'bar_error_lower': 70,
              'bar_error_upper': 83,
            },
          ],
        },
      ],
      'style': {
        'bar_layout': 'overlaid',
        'bar_orientation': 'horizontal',
        'bar_width_percent': 0.74,
        'bar_min_width': 6,
        'bar_max_width': 48,
        'bar_gap': 5,
        'bar_baseline': 10,
        'bar_minimum_length': 4,
        'bar_corner_radius': 8,
        'bar_corner_policy': 'all',
        'bar_opacity': 0.9,
        'bar_animation_mode': 'none',
        'bar_animation_order': 'center_out',
        'bar_animation_stagger': 0.4,
        'bar_gradient_colors': ['#D9F3F7', '#168AAD'],
        'bar_gradient_stops': [0, 1],
        'bar_pattern': 'crosshatch',
        'bar_pattern_color': '#FFFFFFFF',
        'bar_pattern_spacing': 7,
        'bar_pattern_stroke_width': 1.25,
        'bar_pattern_opacity': 0.65,
        'bar_border_color': '#0F5F73',
        'bar_border_width': 1.5,
        'bar_track_enabled': true,
        'bar_track_color': '#E5E7EB',
        'bar_track_value': 100,
        'bar_track_opacity': 0.7,
        'bar_track_corner_radius': 9,
        'bar_target_color': '#334155',
        'bar_target_width': 2.5,
        'bar_target_length_factor': 1.4,
        'bar_target_opacity': 0.85,
        'bar_error_color': '#475569',
        'bar_error_width': 1.75,
        'bar_error_cap_length_factor': 0.7,
        'bar_error_opacity': 0.8,
        'bar_hover_color': '#FFFFFF',
        'bar_hover_opacity': 0.2,
        'bar_hover_border_width': 3,
        'bar_pressed_color': '#111827',
        'bar_pressed_opacity': 0.24,
        'bar_selection_color': '#2563EB',
        'bar_selection_opacity': 0.18,
        'bar_selection_border_width': 4,
        'bar_focus_color': '#F59E0B',
        'bar_focus_border_width': 3,
        'bar_focus_gap': 5,
        'bar_dimmed_opacity': 0.3,
        'bar_labels_show': true,
        'bar_label_position': 'range_ends',
        'bar_label_value_mode': 'range',
        'bar_label_color': '#1F2937',
        'bar_label_font_size': 12,
        'bar_label_font_weight': 700,
        'bar_label_show_unit': true,
        'bar_label_padding': 6,
        'bar_label_collision': 'reposition',
        'bar_label_plot_edge_aware': true,
        'bar_label_collision_padding': 4,
        'bar_label_background_color': '#EEFFFFFF',
        'bar_label_border_color': '#66334155',
        'bar_label_border_width': 1,
        'bar_label_border_radius': 5,
        'bar_label_background_padding': 3,
        'bar_label_callout_show': true,
        'bar_label_callout_color': '#475569',
        'bar_label_callout_width': 1.25,
        'bar_label_callout_minimum_length': 6,
        'bar_label_show_stack_total': true,
      },
    });

    final xAxis = result.xAxisConfig!;
    expect(xAxis.categoryAxis?.categories, ['Enterprise', 'Online']);
    expect(xAxis.categoryAxis?.labelDensity, CategoryLabelDensity.showAll);
    expect(xAxis.categoryAxis?.labelOverflow, CategoryLabelOverflow.ellipsis);
    expect(xAxis.categoryAxis?.minimumCategoryExtent, 72);
    expect(xAxis.categoryAxis?.maximumLabelExtent, 120);
    expect(xAxis.categoryAxis?.maxLabelLines, 1);
    expect(xAxis.categoryAxis?.labelRotationDegrees, -15);
    expect(xAxis.categoryAxis?.autoViewport, isFalse);

    final series = result.series.single as BarChartSeries;
    expect(series.layoutMode, BarLayoutMode.overlaid);
    expect(series.orientation, BarOrientation.horizontal);
    expect(series.groupId, 'actual');
    expect(series.overlayWidthFactor, 0.72);
    expect(series.overlayOffsetFactor, -0.1);
    expect(series.rangeStartValues, [42, 35]);
    expect(series.targetValues, [92, 80]);
    expect(series.errorLowerValues, [82, 70]);
    expect(series.errorUpperValues, [94, 83]);
    expect(series.barStyle.cornerRadius, 8);
    expect(series.barStyle.cornerRadiusPolicy, BarCornerRadiusPolicy.all);
    expect(series.barStyle.opacity, 0.9);
    expect(series.barStyle.animationMode, BarAnimationMode.none);
    expect(series.barStyle.motion.order, BarAnimationOrder.centerOut);
    expect(series.barStyle.motion.staggerFraction, 0.4);
    expect(series.barStyle.gradient?.colors, const [
      Color(0xFFD9F3F7),
      Color(0xFF168AAD),
    ]);
    expect(series.barStyle.pattern?.pattern, BarFillPattern.crosshatch);
    expect(series.barStyle.pattern?.color, const Color(0xFFFFFFFF));
    expect(series.barStyle.pattern?.spacing, 7);
    expect(series.barStyle.pattern?.strokeWidth, 1.25);
    expect(series.barStyle.pattern?.opacity, 0.65);
    expect(series.barStyle.border?.width, 1.5);
    expect(series.barStyle.interaction.dimmedOpacity, 0.3);
    expect(series.trackStyle?.value, 100);
    expect(series.targetMarkerStyle.lengthFactor, 1.4);
    expect(series.errorBarStyle.capLengthFactor, 0.7);
    expect(series.labelStyle.position, BarLabelPosition.rangeEnds);
    expect(series.labelStyle.valueMode, BarLabelValueMode.range);
    expect(series.labelStyle.fontWeight, FontWeight.w700);
    expect(
      series.labelStyle.collisionPolicy,
      BarLabelCollisionPolicy.reposition,
    );
    expect(series.labelStyle.backgroundColor, const Color(0xEEFFFFFF));
    expect(series.labelStyle.callout.show, isTrue);
    expect(series.labelStyle.showStackTotal, isTrue);

    final encoded = ChartSeriesDocumentCodec.encode(series);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    expect(document.requiredCapabilities, contains('series.bar.pattern.v1'));
    final decoded = ChartSeriesDocumentCodec.decode(document);
    expect((decoded as ChartArtifactSuccess<ChartSeries>).value, series);

    final encodedAxis = ChartAxisDocumentCodec.encodeXAxis(xAxis);
    final axisDocument =
        (encodedAxis as ChartArtifactSuccess<ChartAxisDocument>).value;
    final decodedAxis = ChartAxisDocumentCodec.decodeXAxis(axisDocument);
    expect((decodedAxis as ChartArtifactSuccess<XAxisConfig>).value, xAxis);
  });

  test('builds normalized named stacks and waterfall totals', () {
    final normalized = ChartConfigBuilder.fromJson({
      'chart_type': 'bar',
      'series': [
        {
          'id': 'product',
          'bar_group_id': 'mix',
          'data': [
            {'x': 0, 'y': 30},
          ],
        },
        {
          'id': 'services',
          'bar_group_id': 'mix',
          'data': [
            {'x': 0, 'y': 70},
          ],
        },
      ],
      'style': {
        'bar_layout': 'normalized_stacked',
        'bar_labels_show': true,
        'bar_label_value_mode': 'percentage',
        'bar_label_show_stack_total': true,
      },
    });
    final stacks = normalized.series.cast<BarChartSeries>();
    expect(stacks.every((series) => series.groupId == 'mix'), isTrue);
    expect(
      stacks.every(
        (series) =>
            series.layoutMode == BarLayoutMode.normalizedStacked &&
            series.labelStyle.valueMode == BarLabelValueMode.percentage &&
            series.labelStyle.showStackTotal,
      ),
      isTrue,
    );

    final waterfall =
        ChartConfigBuilder.fromJson({
              'chart_type': 'bar',
              'series': [
                {
                  'id': 'cashflow',
                  'data': [
                    {'x': 0, 'y': 82},
                    {'x': 1, 'y': -18},
                    {'x': 2, 'y': 0, 'bar_total': true},
                  ],
                },
              ],
              'style': {
                'bar_layout': 'waterfall',
                'bar_waterfall_increase_color': '#168AAD',
                'bar_waterfall_decrease_color': '#E15B64',
                'bar_waterfall_total_color': '#5149C6',
                'bar_waterfall_connector_show': true,
                'bar_waterfall_connector_color': '#9CA3AF',
                'bar_waterfall_connector_width': 1.25,
                'bar_labels_show': true,
                'bar_label_value_mode': 'waterfall',
              },
            }).series.single
            as BarChartSeries;

    expect(waterfall.layoutMode, BarLayoutMode.waterfall);
    expect(waterfall.waterfallTotalIndices, {2});
    expect(waterfall.waterfallDisplayValueFor(2), 64);
    expect(waterfall.waterfallStyle.increaseColor, const Color(0xFF168AAD));
    expect(waterfall.waterfallStyle.decreaseColor, const Color(0xFFE15B64));
    expect(waterfall.waterfallStyle.totalColor, const Color(0xFF5149C6));
    expect(waterfall.waterfallStyle.connector.width, 1.25);
  });

  test('builds and persists first-class bullet ranges', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'bar',
      'series': [
        {
          'id': 'delivery',
          'data': [
            {'x': 0, 'y': 82, 'bar_target': 88},
          ],
        },
      ],
      'style': {
        'bar_orientation': 'horizontal',
        'bar_bullet_ranges': [
          {'end': 55, 'color': '#E2E8F0', 'label': 'Needs attention'},
          {'end': 100, 'color': '#94A3B8', 'label': 'On track'},
        ],
        'bar_bullet_measure_thickness': 0.42,
        'bar_bullet_corner_radius': 4,
      },
    });

    final series = result.series.single as BarChartSeries;
    expect(series.bulletStyle?.ranges, hasLength(2));
    expect(series.bulletStyle?.ranges.first.endValue, 55);
    expect(series.bulletStyle?.ranges.last.label, 'On track');
    expect(series.bulletStyle?.measureThicknessFactor, 0.42);
    expect(series.bulletStyle?.cornerRadius, 4);
    expect(series.targetValues, [88]);

    final encoded = ChartSeriesDocumentCodec.encode(series);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    expect(document.requiredCapabilities, contains('series.bar.bullet.v1'));
  });

  test('builds and persists diverging Likert roles', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'bar',
      'series': [
        {
          'id': 'disagree',
          'bar_diverging_role': 'negative',
          'data': [
            {'x': 0, 'y': 35},
          ],
        },
        {
          'id': 'agree',
          'bar_diverging_role': 'positive',
          'data': [
            {'x': 0, 'y': 65},
          ],
        },
      ],
      'style': {
        'bar_layout': 'diverging_stacked',
        'bar_orientation': 'horizontal',
        'bar_diverging_center_line_color': '#334155',
        'bar_diverging_center_line_width': 2,
        'bar_diverging_center_line_opacity': 0.6,
      },
    });

    final series = result.series.cast<BarChartSeries>();
    expect(
      series.every(
        (current) => current.layoutMode == BarLayoutMode.divergingStacked,
      ),
      isTrue,
    );
    expect(series.first.divergingRole, BarDivergingRole.negative);
    expect(series.last.divergingRole, BarDivergingRole.positive);
    expect(
      series.first.divergingStyle.centerLineColor,
      const Color(0xFF334155),
    );
    expect(series.first.divergingStyle.centerLineWidth, 2);
    expect(series.first.divergingStyle.centerLineOpacity, 0.6);

    final encoded = ChartSeriesDocumentCodec.encode(series.first);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    expect(document.requiredCapabilities, contains('series.bar.diverging.v1'));
  });

  test('builds and persists lollipop marks', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'bar',
      'series': [
        {
          'id': 'retention',
          'color': '#168AAD',
          'data': [
            {'x': 0, 'y': 74},
          ],
        },
      ],
      'style': {
        'bar_orientation': 'horizontal',
        'bar_lollipop_enabled': true,
        'bar_lollipop_stem_width': 4,
        'bar_lollipop_head_radius': 9,
        'bar_lollipop_stem_color': '#64748B',
        'bar_lollipop_head_color': '#168AAD',
        'bar_lollipop_head_border_color': '#0F5F73',
        'bar_lollipop_head_border_width': 2,
      },
    });

    final series = result.series.single as BarChartSeries;
    expect(series.orientation, BarOrientation.horizontal);
    expect(series.lollipopStyle?.stemWidth, 4);
    expect(series.lollipopStyle?.headRadius, 9);
    expect(series.lollipopStyle?.stemColor, const Color(0xFF64748B));
    expect(series.lollipopStyle?.headColor, const Color(0xFF168AAD));
    expect(series.lollipopStyle?.headBorder?.width, 2);

    final encoded = ChartSeriesDocumentCodec.encode(series);
    final document =
        (encoded as ChartArtifactSuccess<ChartSeriesDocument>).value;
    expect(document.requiredCapabilities, contains('series.bar.lollipop.v1'));
    final decoded = ChartSeriesDocumentCodec.decode(document);
    expect((decoded as ChartArtifactSuccess<ChartSeries>).value, series);
  });

  test('rejects inconsistent analytical bar input', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'series': [
          {
            'id': 'invalid-errors',
            'data': [
              {'x': 0, 'y': 10, 'bar_error_lower': 8},
            ],
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'series': [
          {
            'id': 'invalid-range-stack',
            'data': [
              {'x': 0, 'y': 10, 'bar_start': 3},
            ],
          },
        ],
        'style': {'bar_layout': 'stacked'},
      }),
      throwsFormatException,
    );
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'x_axis': {
          'categories': ['Valid', ''],
        },
        'series': [
          {
            'id': 'invalid-categories',
            'data': [
              {'x': 0, 'y': 10},
            ],
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'x_axis': {
          'categories': ['Only category'],
        },
        'series': [
          {
            'id': 'invalid-category-coordinate',
            'data': [
              {'x': 1, 'y': 10},
            ],
          },
        ],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('does not map to a configured category index'),
        ),
      ),
    );
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'series': [
          {
            'id': 'invalid-pattern',
            'data': [
              {'x': 0, 'y': 10},
            ],
          },
        ],
        'style': {'bar_pattern': 'dots'},
      }),
      throwsFormatException,
    );
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'series': [
          {
            'id': 'invalid-pattern-spacing',
            'data': [
              {'x': 0, 'y': 10},
            ],
          },
        ],
        'style': {'bar_pattern': 'vertical', 'bar_pattern_spacing': 0},
      }),
      throwsFormatException,
    );
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'bar',
        'series': [
          {
            'id': 'invalid-stagger',
            'data': [
              {'x': 0, 'y': 10},
            ],
          },
        ],
        'style': {'bar_animation_stagger': 1},
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('at least 0 and less than 1'),
        ),
      ),
    );
  });

  test('tool schema advertises the advanced bar contract', () {
    final tool = ChartToolSchema.createChartTool;
    final input = tool['input_schema'] as Map<String, dynamic>;
    final properties = input['properties'] as Map<String, dynamic>;
    final seriesProperties =
        (((properties['series'] as Map<String, dynamic>)['items']
                as Map<String, dynamic>)['properties']
            as Map<String, dynamic>);
    final pointProperties =
        ((((seriesProperties['data'] as Map<String, dynamic>)['items']
                as Map<String, dynamic>)['properties'])
            as Map<String, dynamic>);
    final xAxisProperties =
        ((properties['x_axis'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>);
    final styleProperties =
        ((properties['style'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>);

    expect(tool['description'], contains('collision-aware label models'));
    expect(seriesProperties, contains('bar_group_id'));
    expect(seriesProperties, contains('bar_diverging_role'));
    expect(seriesProperties, contains('bar_overlay_width_factor'));
    expect(seriesProperties, contains('bar_gradient_colors'));
    expect(seriesProperties, contains('bar_pattern'));
    expect(seriesProperties, contains('bar_pattern_spacing'));
    expect(seriesProperties, contains('bar_bullet_ranges'));
    expect(seriesProperties, contains('bar_animation_order'));
    expect(seriesProperties, contains('bar_animation_stagger'));
    expect(pointProperties, contains('bar_start'));
    expect(pointProperties, contains('bar_target'));
    expect(pointProperties, contains('bar_error_lower'));
    expect(pointProperties, contains('bar_total'));
    expect(xAxisProperties, contains('categories'));
    expect(xAxisProperties, contains('category_auto_viewport'));
    expect(styleProperties, contains('bar_layout'));
    expect(styleProperties, contains('bar_orientation'));
    expect(styleProperties, contains('bar_animation_order'));
    expect(styleProperties, contains('bar_animation_stagger'));
    expect(styleProperties, contains('bar_gradient_colors'));
    expect(styleProperties, contains('bar_pattern'));
    expect(styleProperties, contains('bar_pattern_color'));
    expect(styleProperties, contains('bar_pattern_opacity'));
    expect(styleProperties, contains('bar_track_enabled'));
    expect(styleProperties, contains('bar_lollipop_enabled'));
    expect(styleProperties, contains('bar_lollipop_stem_width'));
    expect(styleProperties, contains('bar_lollipop_head_radius'));
    expect(styleProperties, contains('bar_bullet_ranges'));
    expect(styleProperties, contains('bar_bullet_measure_thickness'));
    expect(styleProperties, contains('bar_diverging_center_line_show'));
    expect(styleProperties, contains('bar_diverging_center_line_width'));
    expect(styleProperties, contains('bar_waterfall_connector_show'));
    expect(styleProperties, contains('bar_label_collision'));
    expect(styleProperties, contains('bar_label_callout_show'));
    expect(styleProperties, contains('bar_label_show_stack_total'));

    final openAiCreate = ChartToolSchema.toOpenAIFormat().first;
    final function = openAiCreate['function'] as Map<String, dynamic>;
    expect(function['parameters'], same(input));
  });
}
