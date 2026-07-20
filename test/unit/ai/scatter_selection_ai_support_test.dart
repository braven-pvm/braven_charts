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
            {'x': 2, 'y': 3, 'label': 'Atlas'},
            {'x': 8, 'y': 7, 'label': 'Beacon'},
          ],
        },
      ],
      'interactions': {
        'enable_selection': true,
        'selection_operation': 'toggle',
        'selection_drag_activation': 'shift_primary',
        'selection_clear_on_background_tap': false,
        'selection_use_modifier_keys': false,
      },
    });

    final interaction = result.interactionConfig!;
    expect(interaction.enableSelection, isTrue);
    expect(interaction.selection.mode, ChartSelectionMode.point);
    expect(interaction.selection.operation, ChartSelectionOperation.toggle);
    expect(
      interaction.selection.dragActivation,
      ChartSelectionDragActivation.shiftPrimary,
    );
    expect(interaction.selection.clearOnBackgroundTap, isFalse);
    expect(interaction.selection.useModifierKeys, isFalse);
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
