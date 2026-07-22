import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds portable Scatter point-selection operations', () {
    final result = ChartConfigBuilder.fromJson({
      'chart_type': 'scatter',
      'series': [
        {
          'id': 'accounts',
          'data': [
            {'x': 2, 'y': 3, 'point_key': 'account-atlas', 'label': 'Atlas'},
            {'x': 8, 'y': 7, 'label': 'Beacon'},
          ],
        },
      ],
      'interactions': {
        'enable_selection': true,
        'selection_scope': 'category',
        'selection_operation': 'toggle',
        'selection_drag_activation': 'shift_primary',
        'selection_clear_on_background_tap': false,
        'selection_use_modifier_keys': false,
      },
    });

    final interaction = result.interactionConfig!;
    expect(result.series.single.points.first.pointKey, 'account-atlas');
    expect(interaction.enableSelection, isTrue);
    expect(
      interaction.selection.acquisitionMode,
      ChartSelectionAcquisitionMode.point,
    );
    expect(interaction.selection.scope, ChartSelectionScope.category);
    expect(interaction.selection.operation, ChartSelectionOperation.toggle);
    expect(
      interaction.selection.dragActivation,
      ChartSelectionDragActivation.shiftPrimaryButton,
    );
    expect(interaction.selection.clearOnBackgroundTap, isFalse);
    expect(interaction.selection.useModifierKeys, isFalse);
  });

  test('tool schema advertises stable point identity', () {
    final input =
        ChartToolSchema.createChartTool['input_schema']!
            as Map<String, dynamic>;
    final properties = input['properties']! as Map<String, dynamic>;
    final series = properties['series']! as Map<String, dynamic>;
    final seriesItem = series['items']! as Map<String, dynamic>;
    final data =
        (seriesItem['properties']! as Map<String, dynamic>)['data']!
            as Map<String, dynamic>;
    final point = data['items']! as Map<String, dynamic>;
    final pointProperties = point['properties']! as Map<String, dynamic>;

    expect(pointProperties['point_key'], {
      'type': 'string',
      'minLength': 1,
      'description':
          'Optional stable point identity, unique within its series. '
          'Preserves selection across reorder or stream eviction.',
    });
  });

  test('rejects unknown selection operations', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'scatter',
        'series': [
          {
            'id': 'accounts',
            'data': [
              {'x': 2, 'y': 3},
            ],
          },
        ],
        'interactions': {'selection_operation': 'merge'},
      }),
      throwsFormatException,
    );
  });

  test('rejects unknown selection drag activation', () {
    expect(
      () => ChartConfigBuilder.fromJson({
        'chart_type': 'scatter',
        'series': [
          {
            'id': 'accounts',
            'data': [
              {'x': 2, 'y': 3},
            ],
          },
        ],
        'interactions': {'selection_drag_activation': 'middle'},
      }),
      throwsFormatException,
    );
  });
}
