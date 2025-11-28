import 'package:braven_charts/src/models/multi_axis_config.dart';
import 'package:braven_charts/src/models/normalization_mode.dart';
import 'package:braven_charts/src/models/series_axis_binding.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiAxisConfig', () {
    group('construction', () {
      test('creates with defaults', () {
        const config = MultiAxisConfig();

        expect(config.axes, isEmpty);
        expect(config.bindings, isEmpty);
        expect(config.mode, equals(NormalizationMode.auto));
      });

      test('creates with all parameters', () {
        final axes = [
          YAxisConfig(id: 'power', position: YAxisPosition.left),
          YAxisConfig(id: 'hr', position: YAxisPosition.right),
        ];
        const bindings = [
          SeriesAxisBinding(seriesId: 'power-series', yAxisId: 'power'),
          SeriesAxisBinding(seriesId: 'hr-series', yAxisId: 'hr'),
        ];

        final config = MultiAxisConfig(
          axes: axes,
          bindings: bindings,
          mode: NormalizationMode.always,
        );

        expect(config.axes.length, equals(2));
        expect(config.bindings.length, equals(2));
        expect(config.mode, equals(NormalizationMode.always));
      });

      test('is const-constructible with empty lists', () {
        const config = MultiAxisConfig(
          axes: [],
          bindings: [],
          mode: NormalizationMode.disabled,
        );

        expect(config.axes, isEmpty);
        expect(config.mode, equals(NormalizationMode.disabled));
      });
    });

    group('getAxisById', () {
      test('returns axis when found', () {
        final powerAxis = YAxisConfig(id: 'power', position: YAxisPosition.left);
        final config = MultiAxisConfig(axes: [powerAxis]);

        final result = config.getAxisById('power');

        expect(result, isNotNull);
        expect(result!.id, equals('power'));
      });

      test('returns null when not found', () {
        final config = MultiAxisConfig(
          axes: [YAxisConfig(id: 'power', position: YAxisPosition.left)],
        );

        final result = config.getAxisById('nonexistent');

        expect(result, isNull);
      });

      test('works with multiple axes', () {
        final config = MultiAxisConfig(
          axes: [
            YAxisConfig(id: 'power', position: YAxisPosition.left),
            YAxisConfig(id: 'hr', position: YAxisPosition.right),
            YAxisConfig(id: 'cadence', position: YAxisPosition.outerRight),
          ],
        );

        expect(config.getAxisById('power')?.id, equals('power'));
        expect(config.getAxisById('hr')?.id, equals('hr'));
        expect(config.getAxisById('cadence')?.id, equals('cadence'));
        expect(config.getAxisById('speed'), isNull);
      });

      test('returns null for empty axes list', () {
        const config = MultiAxisConfig();

        expect(config.getAxisById('any'), isNull);
      });
    });

    group('getAxisForSeries', () {
      test('returns axis when binding exists', () {
        final config = MultiAxisConfig(
          axes: [
            YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
          ],
          bindings: [
            const SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
          ],
        );

        final result = config.getAxisForSeries('power');

        expect(result, isNotNull);
        expect(result!.id, equals('power-axis'));
      });

      test('returns null when no binding', () {
        final config = MultiAxisConfig(
          axes: [
            YAxisConfig(id: 'power-axis', position: YAxisPosition.left),
          ],
          bindings: [
            const SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
          ],
        );

        final result = config.getAxisForSeries('unknown-series');

        expect(result, isNull);
      });

      test('returns null when axis not found (binding exists but axis missing)', () {
        const config = MultiAxisConfig(
          axes: [], // No axes defined
          bindings: [
            SeriesAxisBinding(seriesId: 'power', yAxisId: 'power-axis'),
          ],
        );

        final result = config.getAxisForSeries('power');

        expect(result, isNull);
      });

      test('returns correct axis when multiple bindings exist', () {
        final config = MultiAxisConfig(
          axes: [
            YAxisConfig(id: 'left-axis', position: YAxisPosition.left),
            YAxisConfig(id: 'right-axis', position: YAxisPosition.right),
          ],
          bindings: [
            const SeriesAxisBinding(seriesId: 'power', yAxisId: 'left-axis'),
            const SeriesAxisBinding(seriesId: 'hr', yAxisId: 'right-axis'),
          ],
        );

        expect(config.getAxisForSeries('power')?.id, equals('left-axis'));
        expect(config.getAxisForSeries('hr')?.id, equals('right-axis'));
      });
    });

    group('getBindingsForAxis', () {
      test('returns empty list when no bindings', () {
        final config = MultiAxisConfig(
          axes: [YAxisConfig(id: 'power', position: YAxisPosition.left)],
          bindings: [],
        );

        final result = config.getBindingsForAxis('power');

        expect(result, isEmpty);
      });

      test('returns matching bindings', () {
        const config = MultiAxisConfig(
          bindings: [
            SeriesAxisBinding(seriesId: 'power', yAxisId: 'left-axis'),
            SeriesAxisBinding(seriesId: 'hr', yAxisId: 'right-axis'),
          ],
        );

        final result = config.getBindingsForAxis('left-axis');

        expect(result.length, equals(1));
        expect(result.first.seriesId, equals('power'));
      });

      test('returns multiple bindings for shared axis', () {
        const config = MultiAxisConfig(
          bindings: [
            SeriesAxisBinding(seriesId: 'power', yAxisId: 'shared-axis'),
            SeriesAxisBinding(seriesId: 'cadence', yAxisId: 'shared-axis'),
            SeriesAxisBinding(seriesId: 'hr', yAxisId: 'other-axis'),
          ],
        );

        final result = config.getBindingsForAxis('shared-axis');

        expect(result.length, equals(2));
        expect(result.map((b) => b.seriesId).toList(), containsAll(['power', 'cadence']));
      });

      test('returns empty list for non-existent axis', () {
        const config = MultiAxisConfig(
          bindings: [
            SeriesAxisBinding(seriesId: 'power', yAxisId: 'left-axis'),
          ],
        );

        final result = config.getBindingsForAxis('nonexistent');

        expect(result, isEmpty);
      });
    });

    group('copyWith', () {
      test('changes specified values', () {
        final original = MultiAxisConfig(
          axes: [YAxisConfig(id: 'power', position: YAxisPosition.left)],
          bindings: [const SeriesAxisBinding(seriesId: 'p', yAxisId: 'power')],
          mode: NormalizationMode.auto,
        );

        final modified = original.copyWith(
          mode: NormalizationMode.always,
        );

        expect(modified.mode, equals(NormalizationMode.always));
        expect(modified.axes.length, equals(1)); // Unchanged
        expect(modified.bindings.length, equals(1)); // Unchanged
      });

      test('preserves unchanged values', () {
        final original = MultiAxisConfig(
          axes: [
            YAxisConfig(id: 'power', position: YAxisPosition.left),
            YAxisConfig(id: 'hr', position: YAxisPosition.right),
          ],
          bindings: [
            const SeriesAxisBinding(seriesId: 'p', yAxisId: 'power'),
          ],
          mode: NormalizationMode.disabled,
        );

        final modified = original.copyWith(
          axes: [YAxisConfig(id: 'new-axis', position: YAxisPosition.outerLeft)],
        );

        expect(modified.axes.length, equals(1));
        expect(modified.axes.first.id, equals('new-axis'));
        expect(modified.bindings.length, equals(1)); // Preserved
        expect(modified.mode, equals(NormalizationMode.disabled)); // Preserved
      });

      test('returns new instance', () {
        const original = MultiAxisConfig();
        final copy = original.copyWith();

        expect(identical(original, copy), isFalse);
      });
    });

    group('equality', () {
      test('same config is equal', () {
        final axes = [YAxisConfig(id: 'power', position: YAxisPosition.left)];
        const bindings = [SeriesAxisBinding(seriesId: 'p', yAxisId: 'power')];

        final config1 = MultiAxisConfig(
          axes: axes,
          bindings: bindings,
          mode: NormalizationMode.auto,
        );

        final config2 = MultiAxisConfig(
          axes: axes,
          bindings: bindings,
          mode: NormalizationMode.auto,
        );

        expect(config1, equals(config2));
      });

      test('different mode is not equal', () {
        const config1 = MultiAxisConfig(mode: NormalizationMode.auto);
        const config2 = MultiAxisConfig(mode: NormalizationMode.always);

        expect(config1, isNot(equals(config2)));
      });

      test('different axes is not equal', () {
        final config1 = MultiAxisConfig(
          axes: [YAxisConfig(id: 'a', position: YAxisPosition.left)],
        );
        final config2 = MultiAxisConfig(
          axes: [YAxisConfig(id: 'b', position: YAxisPosition.left)],
        );

        expect(config1, isNot(equals(config2)));
      });

      test('hashCode is consistent with equality', () {
        const config1 = MultiAxisConfig(mode: NormalizationMode.auto);
        const config2 = MultiAxisConfig(mode: NormalizationMode.auto);

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('identical objects are equal', () {
        const config = MultiAxisConfig();

        expect(config, equals(config));
      });
    });
  });
}
