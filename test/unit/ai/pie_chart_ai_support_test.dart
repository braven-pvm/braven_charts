import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pie AI builder', () {
    test('builds one styled categorical pie with radial interactions', () {
      final result = ChartConfigBuilder.fromJson({
        'title': 'Revenue mix',
        'chart_type': 'pie',
        'series': [
          {
            'id': 'revenue',
            'name': 'Revenue',
            'unit': 'USD',
            'radius_label': 'Total area',
            'radius_unit': 'km²',
            'data': [
              {
                'x': 0,
                'y': 42,
                'label': 'Subscriptions',
                'color': '#6750A4',
                'radius': 120,
              },
              {'x': 1, 'y': 58, 'label': 'Services', 'radius': 80},
            ],
          },
        ],
        'interactions': {
          'enable_pan': true,
          'enable_zoom': true,
          'show_crosshair': true,
          'show_tooltip': false,
        },
        'style': {
          'show_legend': true,
          'pie_start_angle': 25,
          'pie_clockwise': false,
          'pie_radius_factor': 0.8,
          'pie_radius_minimum_factor': 0.4,
          'pie_radius_scale': 'linear',
          'pie_slice_gap': 4,
          'pie_border_width': 2,
          'pie_border_color': '#223344',
          'pie_border_color_mode': 'slice',
          'pie_border_hue_shift': 20,
          'pie_border_saturation_shift': -0.1,
          'pie_border_lightness_shift': -0.2,
          'pie_gradient_enabled': true,
          'pie_gradient_type': 'radial',
          'pie_gradient_start_color': '#E8F1FF',
          'pie_gradient_end_color': '#123456',
          'pie_gradient_start_lightness_shift': 0.22,
          'pie_gradient_end_lightness_shift': -0.16,
          'pie_gradient_angle': 35,
          'pie_selection_explode_offset': 12,
          'pie_selection_effect': 'lift',
          'pie_selection_lift_scale': 1.12,
          'pie_selection_lift_offset': 8,
          'pie_selection_backdrop_blur': 1.5,
          'pie_opacity': 0.78,
          'pie_corner_radius': 10,
          'pie_corner_treatment': 'circular_center',
          'pie_shadow_color': '#33000000',
          'pie_shadow_blur': 8,
          'pie_shadow_spread': 1,
          'pie_shadow_offset_y': 3,
          'pie_shadow_opacity': 0.7,
          'pie_selected_glow_color': '#556677',
          'pie_selected_glow_blur': 12,
          'pie_selected_glow_spread': 2,
          'pie_selected_glow_offset_x': 1,
          'pie_selected_glow_opacity': 0.6,
          'pie_animation_mode': 'sweep',
          'show_data_labels': true,
          'pie_label_position': 'inside',
          'pie_label_content': 'category_value_and_percentage',
          'pie_secondary_label_content': 'category',
          'pie_secondary_label_position': 'outside',
          'pie_label_minimum_share': 0.05,
          'pie_label_minimum_sweep': 10,
          'pie_inside_label_offset': -12,
          'pie_label_offset': 24,
        },
      });

      expect(result.chartType, ChartType.pie);
      expect(result.title, 'Revenue mix');
      expect(result.xAxisConfig, isNull);
      expect(result.yAxisConfig, isNull);
      expect(result.yAxes, isNull);
      expect(result.gridConfig?.horizontal, isFalse);
      expect(result.gridConfig?.vertical, isFalse);
      expect(result.interactionConfig?.enablePan, isFalse);
      expect(result.interactionConfig?.enableZoom, isFalse);
      expect(result.interactionConfig?.crosshair.enabled, isFalse);
      expect(result.interactionConfig?.tooltip.enabled, isFalse);

      final series = result.series.single as PieChartSeries;
      expect(series.unit, 'USD');
      expect(series.points.first.label, 'Subscriptions');
      expect(series.points.first.pointStyle?.color, const Color(0xFF6750A4));
      expect(series.points.first.pointStyle?.size, 120);
      expect(series.sliceRadiusConfig?.minimumFactor, 0.4);
      expect(series.sliceRadiusConfig?.scale, PieSliceRadiusScale.linear);
      expect(series.sliceRadiusConfig?.label, 'Total area');
      expect(series.sliceRadiusConfig?.unit, 'km²');
      expect(series.pieStyle.startAngleDegrees, 25);
      expect(series.pieStyle.clockwise, isFalse);
      expect(series.pieStyle.radiusFactor, 0.8);
      expect(series.pieStyle.sliceGap, 4);
      expect(series.pieStyle.borderWidth, 2);
      expect(series.pieStyle.borderColor, const Color(0xFF223344));
      expect(series.pieStyle.borderColorMode, PieBorderColorMode.slice);
      expect(series.pieStyle.borderHueShiftDegrees, 20);
      expect(series.pieStyle.borderSaturationShift, -0.1);
      expect(series.pieStyle.borderLightnessShift, -0.2);
      expect(series.pieStyle.gradient?.enabled, isTrue);
      expect(series.pieStyle.gradient?.type, PieGradientType.radial);
      expect(series.pieStyle.gradient?.startColor, const Color(0xFFE8F1FF));
      expect(series.pieStyle.gradient?.endColor, const Color(0xFF123456));
      expect(series.pieStyle.gradient?.startLightnessShift, 0.22);
      expect(series.pieStyle.gradient?.endLightnessShift, -0.16);
      expect(series.pieStyle.gradient?.angleDegrees, 35);
      expect(series.pieStyle.selectionExplodeOffset, 12);
      expect(series.selectionStyle.effect, RadialSelectionEffect.lift);
      expect(series.selectionStyle.liftScale, 1.12);
      expect(series.selectionStyle.liftOffset, 8);
      expect(series.selectionStyle.backdropBlur, 1.5);
      expect(series.pieStyle.opacity, 0.78);
      expect(series.pieStyle.cornerRadius, 10);
      expect(
        series.pieStyle.cornerTreatment,
        PieCornerTreatment.circularCenter,
      );
      expect(series.pieStyle.shadow?.color, const Color(0x33000000));
      expect(series.pieStyle.shadow?.blurRadius, 8);
      expect(series.pieStyle.shadow?.spreadRadius, 1);
      expect(series.pieStyle.shadow?.offset, const Offset(0, 3));
      expect(series.pieStyle.shadow?.opacity, 0.7);
      expect(series.pieStyle.selectedElevation?.color, const Color(0xFF556677));
      expect(series.pieStyle.selectedElevation?.blurRadius, 12);
      expect(series.pieStyle.selectedElevation?.spreadRadius, 2);
      expect(series.pieStyle.selectedElevation?.offset, const Offset(1, 0));
      expect(series.pieStyle.selectedElevation?.opacity, 0.6);
      expect(series.pieStyle.animationMode, PieAnimationMode.sweep);
      expect(series.dataLabels.position, PieDataLabelPosition.inside);
      expect(
        series.dataLabels.content,
        PieDataLabelContent.categoryValueAndPercentage,
      );
      expect(series.dataLabels.secondaryContent, PieDataLabelContent.category);
      expect(series.dataLabels.secondaryPosition, PieDataLabelPosition.outside);
      expect(series.dataLabels.minimumShare, 0.05);
      expect(series.dataLabels.minimumSweepDegrees, 10);
      expect(series.dataLabels.insideOffset, -12);
      expect(series.dataLabels.outsideOffset, 24);
    });

    test('rejects invalid pie cardinality, data, axes, and mixed styles', () {
      Map<String, dynamic> config({
        required List<Map<String, dynamic>> series,
        Map<String, dynamic>? xAxis,
      }) {
        final result = <String, dynamic>{'chart_type': 'pie', 'series': series};
        if (xAxis != null) result['x_axis'] = xAxis;
        return result;
      }

      final validSeries = <String, dynamic>{
        'id': 'pie',
        'data': [
          {'x': 0, 'y': 1, 'label': 'A'},
        ],
      };

      expect(
        () => ChartConfigBuilder.fromJson(
          config(
            series: [
              {
                'id': 'pie',
                'data': [
                  {'x': 0, 'y': 1, 'label': 'A', 'radius': 10},
                  {'x': 1, 'y': 2, 'label': 'B'},
                ],
              },
            ],
          ),
        ),
        throwsFormatException,
      );

      expect(
        () => ChartConfigBuilder.fromJson(
          config(
            series: [
              validSeries,
              {...validSeries, 'id': 'pie-2'},
            ],
          ),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => ChartConfigBuilder.fromJson(
          config(
            series: [
              {
                'id': 'missing-label',
                'data': [
                  {'x': 0, 'y': 1},
                ],
              },
            ],
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('non-empty category label'),
          ),
        ),
      );
      expect(
        () => ChartConfigBuilder.fromJson(
          config(
            series: [
              {
                'id': 'negative',
                'data': [
                  {'x': 0, 'y': -1, 'label': 'A'},
                ],
              },
            ],
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('non-negative'),
          ),
        ),
      );
      expect(
        () => ChartConfigBuilder.fromJson(
          config(series: [validSeries], xAxis: {'label': 'Not valid'}),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('do not use x_axis'),
          ),
        ),
      );
      expect(
        () => ChartConfigBuilder.fromJson(
          config(
            series: [
              {...validSeries, 'style': 'line'},
            ],
          ),
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Donut AI builder', () {
    test('builds first-class Donut geometry from the radial schema', () {
      final result = ChartConfigBuilder.fromJson({
        'chart_type': 'donut',
        'series': [
          {
            'id': 'registrations',
            'data': [
              {'x': 0, 'y': 24, 'label': 'EV'},
              {'x': 1, 'y': 76, 'label': 'Other'},
            ],
          },
        ],
        'style': {
          'donut_inner_radius_factor': 0.64,
          'donut_sweep_angle': 270,
          'pie_start_angle': -135,
          'pie_slice_gap': 4,
          'pie_corner_radius': 6,
          'pie_selection_effect': 'lift',
          'pie_selection_lift_scale': 1.12,
          'pie_selection_lift_offset': 8,
          'pie_selection_backdrop_blur': 1.5,
          'donut_center_visible': true,
          'donut_center_value_mode': 'selected_or_total',
          'donut_center_label': 'Registrations',
        },
      });

      expect(result.chartType, ChartType.donut);
      expect(result.xAxisConfig, isNull);
      expect(result.yAxisConfig, isNull);
      final series = result.series.single as DonutChartSeries;
      expect(series.donutStyle.innerRadiusFactor, 0.64);
      expect(series.donutStyle.sweepAngleDegrees, 270);
      expect(series.donutStyle.startAngleDegrees, -135);
      expect(series.donutStyle.sliceGap, 4);
      expect(series.donutStyle.cornerRadius, 6);
      expect(series.selectionStyle.effect, RadialSelectionEffect.lift);
      expect(series.selectionStyle.liftScale, 1.12);
      expect(series.selectionStyle.liftOffset, 8);
      expect(series.selectionStyle.backdropBlur, 1.5);
      expect(series.centerContent.isVisible, isTrue);
      expect(series.centerContent.label, 'Registrations');
      expect(
        series.centerContent.valueMode,
        DonutCenterValueMode.selectedOrTotal,
      );
    });

    test('builds a source-preserving grouped radial projection', () {
      final result = ChartConfigBuilder.fromJson({
        'chart_type': 'donut',
        'series': [
          {
            'id': 'requests',
            'data': [
              {'x': 0, 'y': 80, 'label': 'Core'},
              {'x': 1, 'y': 8, 'label': 'Email'},
              {'x': 2, 'y': 7, 'label': 'Chat'},
              {'x': 3, 'y': 5, 'label': 'Other source'},
            ],
          },
        ],
        'style': {
          'pie_grouping_minimum_share': 0.1,
          'pie_grouping_minimum_source_count': 2,
          'pie_grouping_label': 'Smaller channels',
          'pie_grouping_color': '#6750A4',
        },
      });

      final series = result.series.single as DonutChartSeries;
      expect(series.points, hasLength(4));
      expect(series.visibleSlices, hasLength(2));
      expect(series.visibleSlices.last.point.label, 'Smaller channels');
      expect(
        series.visibleSlices.last.point.pointStyle?.color,
        const Color(0xFF6750A4),
      );
      expect(series.visibleSlices.last.sourcePointIndices, <int>[1, 2, 3]);
    });
  });

  test('tool schema advertises the renderer-aware pie contract', () {
    final tool = ChartToolSchema.createChartTool;
    final input = tool['input_schema'] as Map<String, dynamic>;
    final properties = input['properties'] as Map<String, dynamic>;
    final chartType = properties['chart_type'] as Map<String, dynamic>;
    final dataPoint =
        ((((properties['series'] as Map<String, dynamic>)['items']
                        as Map<String, dynamic>)['properties']
                    as Map<String, dynamic>)['data']
                as Map<String, dynamic>)['items']
            as Map<String, dynamic>;
    final pointProperties = dataPoint['properties'] as Map<String, dynamic>;
    final styleProperties =
        ((properties['style'] as Map<String, dynamic>)['properties']
            as Map<String, dynamic>);

    expect(chartType['enum'], contains('pie'));
    expect(chartType['enum'], contains('donut'));
    expect(input['required'], contains('series'));
    expect(tool['description'], contains('Pie charts do not use axes'));
    expect(
      (properties['series'] as Map<String, dynamic>)['description'],
      contains('exactly one'),
    );
    expect(pointProperties, containsPair('color', isA<Map<String, dynamic>>()));
    expect(
      pointProperties,
      containsPair('radius', isA<Map<String, dynamic>>()),
    );
    expect(
      ((properties['series'] as Map<String, dynamic>)['items']
          as Map<String, dynamic>)['properties'],
      containsPair('radius_label', isA<Map<String, dynamic>>()),
    );
    expect(
      (pointProperties['label'] as Map<String, dynamic>)['description'],
      contains('Required'),
    );
    expect(styleProperties.keys, contains('pie_start_angle'));
    expect(styleProperties.keys, contains('donut_inner_radius_factor'));
    expect(styleProperties.keys, contains('donut_sweep_angle'));
    expect(styleProperties.keys, contains('donut_center_visible'));
    expect(styleProperties.keys, contains('donut_center_value_mode'));
    expect(styleProperties.keys, contains('donut_center_label'));
    expect(styleProperties.keys, contains('donut_center_custom_value'));
    expect(styleProperties.keys, contains('pie_radius_minimum_factor'));
    expect(styleProperties.keys, contains('pie_radius_scale'));
    expect(styleProperties.keys, contains('pie_corner_radius'));
    expect(styleProperties.keys, contains('pie_corner_treatment'));
    expect(styleProperties.keys, contains('pie_gradient_type'));
    expect(styleProperties.keys, contains('pie_gradient_angle'));
    expect(styleProperties.keys, contains('pie_selection_lift_offset'));
    expect(styleProperties.keys, contains('pie_selected_glow_blur'));
    expect(styleProperties.keys, contains('pie_grouping_minimum_share'));
    expect(styleProperties.keys, contains('pie_grouping_minimum_source_count'));
    expect(styleProperties.keys, contains('pie_grouping_label'));
    expect(styleProperties.keys, contains('pie_grouping_color'));
    expect(styleProperties.keys, contains('pie_label_content'));
    expect(styleProperties.keys, contains('pie_secondary_label_content'));
    expect(styleProperties.keys, contains('pie_secondary_label_position'));
    expect(styleProperties.keys, contains('pie_inside_label_offset'));
    expect(styleProperties.keys, contains('pie_label_offset'));
    expect(
      (properties['x_axis'] as Map<String, dynamic>)['description'],
      contains('Omit when chart_type is pie'),
    );

    final openAiCreate = ChartToolSchema.toOpenAIFormat().first;
    final function = openAiCreate['function'] as Map<String, dynamic>;
    expect(function['parameters'], same(input));
  });
}
