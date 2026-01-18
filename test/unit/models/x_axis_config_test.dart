library;

import 'dart:ui' show Color;

import 'package:braven_charts/src/models/data_range.dart';
import 'package:braven_charts/src/models/x_axis_config.dart';
import 'package:braven_charts/src/models/y_axis_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XAxisConfig', () {
    group('construction', () {
      test('creates with required parameters only (all defaults)', () {
        const config = XAxisConfig();

        expect(config.color, isNull);
        expect(config.label, isNull);
        expect(config.unit, isNull);
        expect(config.min, isNull);
        expect(config.max, isNull);
        expect(config.visible, isTrue);
        expect(config.showAxisLine, isTrue);
        expect(config.showTicks, isTrue);
        expect(config.showCrosshairLabel, isTrue);
        expect(config.labelDisplay, equals(AxisLabelDisplay.labelWithUnit));
        expect(config.minHeight, equals(0.0));
        expect(config.maxHeight, equals(60.0));
        expect(config.tickLabelPadding, equals(4.0));
        expect(config.axisLabelPadding, equals(5.0));
        expect(config.axisMargin, equals(8.0));
        expect(config.tickCount, isNull);
        expect(config.labelFormatter, isNull);
      });

      test('creates with all parameters specified', () {
        String formatter(double v) => '${v.toInt()}s';

        final config = XAxisConfig(
          color: const Color(0xFF00FF00),
          label: 'Time',
          unit: 's',
          min: 0.0,
          max: 100.0,
          visible: false,
          showAxisLine: false,
          showTicks: false,
          showCrosshairLabel: false,
          labelDisplay: AxisLabelDisplay.none,
          minHeight: 30.0,
          maxHeight: 80.0,
          tickLabelPadding: 8.0,
          axisLabelPadding: 10.0,
          axisMargin: 12.0,
          tickCount: 11,
          labelFormatter: formatter,
        );

        expect(config.color, equals(const Color(0xFF00FF00)));
        expect(config.label, equals('Time'));
        expect(config.unit, equals('s'));
        expect(config.min, equals(0.0));
        expect(config.max, equals(100.0));
        expect(config.visible, isFalse);
        expect(config.showAxisLine, isFalse);
        expect(config.showTicks, isFalse);
        expect(config.showCrosshairLabel, isFalse);
        expect(config.labelDisplay, equals(AxisLabelDisplay.none));
        expect(config.minHeight, equals(30.0));
        expect(config.maxHeight, equals(80.0));
        expect(config.tickLabelPadding, equals(8.0));
        expect(config.axisLabelPadding, equals(10.0));
        expect(config.axisMargin, equals(12.0));
        expect(config.tickCount, equals(11));
        expect(config.labelFormatter, equals(formatter));
      });

      test('has correct default values', () {
        const config = XAxisConfig();

        expect(config.color, isNull);
        expect(config.label, isNull);
        expect(config.unit, isNull);
        expect(config.min, isNull);
        expect(config.max, isNull);
        expect(config.visible, isTrue);
        expect(config.showAxisLine, isTrue);
        expect(config.showTicks, isTrue);
        expect(config.showCrosshairLabel, isTrue);
        expect(config.labelDisplay, equals(AxisLabelDisplay.labelWithUnit));
        expect(config.minHeight, equals(0.0));
        expect(config.maxHeight, equals(60.0));
        expect(config.tickLabelPadding, equals(4.0));
        expect(config.axisLabelPadding, equals(5.0));
        expect(config.axisMargin, equals(8.0));
        expect(config.tickCount, isNull);
        expect(config.labelFormatter, isNull);
      });
    });

    group('validation', () {
      test('throws assertion error for negative minHeight', () {
        expect(
          () => XAxisConfig(
            minHeight: -10.0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for maxHeight < minHeight', () {
        expect(
          () => XAxisConfig(
            minHeight: 50.0,
            maxHeight: 40.0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for min >= max when both specified', () {
        expect(
          () => XAxisConfig(
            min: 100.0,
            max: 50.0,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => XAxisConfig(
            min: 50.0,
            max: 50.0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for tickCount < 2', () {
        expect(
          () => XAxisConfig(
            tickCount: 1,
          ),
          throwsA(isA<AssertionError>()),
        );

        expect(
          () => XAxisConfig(
            tickCount: 0,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('allows null min or max independently', () {
        // Only min specified
        expect(
          () => const XAxisConfig(
            min: 0.0,
          ),
          returnsNormally,
        );

        // Only max specified
        expect(
          () => const XAxisConfig(
            max: 100.0,
          ),
          returnsNormally,
        );
      });

      test('allows tickCount >= 2', () {
        expect(
          () => const XAxisConfig(
            tickCount: 2,
          ),
          returnsNormally,
        );

        expect(
          () => const XAxisConfig(
            tickCount: 20,
          ),
          returnsNormally,
        );
      });

      test('allows maxHeight == minHeight', () {
        expect(
          () => const XAxisConfig(
            minHeight: 50.0,
            maxHeight: 50.0,
          ),
          returnsNormally,
        );
      });
    });

    group('computed properties', () {
      test('shouldShowAxisLabel is true for labelOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelOnly,
        );
        expect(config.shouldShowAxisLabel, isTrue);
      });

      test('shouldShowAxisLabel is true for labelWithUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
        expect(config.shouldShowAxisLabel, isTrue);
      });

      test('shouldShowAxisLabel is true for labelAndTickUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelAndTickUnit,
        );
        expect(config.shouldShowAxisLabel, isTrue);
      });

      test('shouldShowAxisLabel is true for labelWithUnitAndTickUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
        );
        expect(config.shouldShowAxisLabel, isTrue);
      });

      test('shouldShowAxisLabel is false for tickUnitOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
        );
        expect(config.shouldShowAxisLabel, isFalse);
      });

      test('shouldShowAxisLabel is false for tickOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.tickOnly,
        );
        expect(config.shouldShowAxisLabel, isFalse);
      });

      test('shouldShowAxisLabel is false for none', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.none,
        );
        expect(config.shouldShowAxisLabel, isFalse);
      });

      test('shouldAppendUnitToLabel is true for labelWithUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
        expect(config.shouldAppendUnitToLabel, isTrue);
      });

      test('shouldAppendUnitToLabel is true for labelWithUnitAndTickUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
        );
        expect(config.shouldAppendUnitToLabel, isTrue);
      });

      test('shouldAppendUnitToLabel is false for labelOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelOnly,
        );
        expect(config.shouldAppendUnitToLabel, isFalse);
      });

      test('shouldAppendUnitToLabel is false for labelAndTickUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelAndTickUnit,
        );
        expect(config.shouldAppendUnitToLabel, isFalse);
      });

      test('shouldAppendUnitToLabel is false for tickUnitOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
        );
        expect(config.shouldAppendUnitToLabel, isFalse);
      });

      test('shouldAppendUnitToLabel is false for tickOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.tickOnly,
        );
        expect(config.shouldAppendUnitToLabel, isFalse);
      });

      test('shouldAppendUnitToLabel is false for none', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.none,
        );
        expect(config.shouldAppendUnitToLabel, isFalse);
      });

      test('shouldShowTickUnit is true for labelAndTickUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelAndTickUnit,
        );
        expect(config.shouldShowTickUnit, isTrue);
      });

      test('shouldShowTickUnit is true for labelWithUnitAndTickUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
        );
        expect(config.shouldShowTickUnit, isTrue);
      });

      test('shouldShowTickUnit is true for tickUnitOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.tickUnitOnly,
        );
        expect(config.shouldShowTickUnit, isTrue);
      });

      test('shouldShowTickUnit is false for labelOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelOnly,
        );
        expect(config.shouldShowTickUnit, isFalse);
      });

      test('shouldShowTickUnit is false for labelWithUnit', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelWithUnit,
        );
        expect(config.shouldShowTickUnit, isFalse);
      });

      test('shouldShowTickUnit is false for tickOnly', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.tickOnly,
        );
        expect(config.shouldShowTickUnit, isFalse);
      });

      test('shouldShowTickUnit is false for none', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.none,
        );
        expect(config.shouldShowTickUnit, isFalse);
      });

      test('shouldShowTickLabels is true for all modes except none', () {
        const modes = [
          AxisLabelDisplay.labelOnly,
          AxisLabelDisplay.labelWithUnit,
          AxisLabelDisplay.labelAndTickUnit,
          AxisLabelDisplay.labelWithUnitAndTickUnit,
          AxisLabelDisplay.tickUnitOnly,
          AxisLabelDisplay.tickOnly,
        ];

        for (final mode in modes) {
          final config = XAxisConfig(labelDisplay: mode);
          expect(config.shouldShowTickLabels, isTrue,
              reason: 'shouldShowTickLabels should be true for $mode');
        }
      });

      test('shouldShowTickLabels is false for none', () {
        const config = XAxisConfig(
          labelDisplay: AxisLabelDisplay.none,
        );
        expect(config.shouldShowTickLabels, isFalse);
      });
    });

    group('copyWith', () {
      test('returns new instance (not same reference)', () {
        const original = XAxisConfig();
        final copy = original.copyWith();

        expect(identical(original, copy), isFalse);
      });

      test('changes specified values', () {
        const original = XAxisConfig(
          label: 'Original',
          unit: 'ms',
          visible: true,
        );

        final copy = original.copyWith(
          label: 'Changed',
          visible: false,
        );

        expect(copy.label, equals('Changed')); // Changed
        expect(copy.unit, equals('ms')); // Unchanged
        expect(copy.visible, isFalse); // Changed
      });

      test('preserves unchanged values', () {
        String formatter(double v) => '${v.toInt()}';

        final original = XAxisConfig(
          color: const Color(0xFFFF0000),
          label: 'Time',
          unit: 's',
          min: 0.0,
          max: 100.0,
          visible: false,
          showAxisLine: false,
          showTicks: false,
          showCrosshairLabel: false,
          labelDisplay: AxisLabelDisplay.none,
          minHeight: 30.0,
          maxHeight: 80.0,
          tickLabelPadding: 8.0,
          axisLabelPadding: 10.0,
          axisMargin: 12.0,
          tickCount: 11,
          labelFormatter: formatter,
        );

        final copy = original.copyWith(label: 'New Label');

        expect(copy.color, equals(const Color(0xFFFF0000)));
        expect(copy.label, equals('New Label')); // Changed
        expect(copy.unit, equals('s'));
        expect(copy.min, equals(0.0));
        expect(copy.max, equals(100.0));
        expect(copy.visible, isFalse);
        expect(copy.showAxisLine, isFalse);
        expect(copy.showTicks, isFalse);
        expect(copy.showCrosshairLabel, isFalse);
        expect(copy.labelDisplay, equals(AxisLabelDisplay.none));
        expect(copy.minHeight, equals(30.0));
        expect(copy.maxHeight, equals(80.0));
        expect(copy.tickLabelPadding, equals(8.0));
        expect(copy.axisLabelPadding, equals(10.0));
        expect(copy.axisMargin, equals(12.0));
        expect(copy.tickCount, equals(11));
        expect(copy.labelFormatter, equals(formatter));
      });

      test('can change multiple values at once', () {
        const original = XAxisConfig(
          label: 'Original',
          unit: 'ms',
          minHeight: 20.0,
          maxHeight: 50.0,
        );

        final copy = original.copyWith(
          label: 'Modified',
          minHeight: 25.0,
          visible: false,
        );

        expect(copy.label, equals('Modified'));
        expect(copy.unit, equals('ms')); // Unchanged
        expect(copy.minHeight, equals(25.0));
        expect(copy.maxHeight, equals(50.0)); // Unchanged
        expect(copy.visible, isFalse);
      });
    });

    group('equality', () {
      test('same values are equal', () {
        const config1 = XAxisConfig(
          label: 'Time',
          unit: 's',
          visible: true,
        );

        const config2 = XAxisConfig(
          label: 'Time',
          unit: 's',
          visible: true,
        );

        expect(config1, equals(config2));
      });

      test('different label values are not equal', () {
        const config1 = XAxisConfig(label: 'Time');
        const config2 = XAxisConfig(label: 'Distance');

        expect(config1, isNot(equals(config2)));
      });

      test('different unit values are not equal', () {
        const config1 = XAxisConfig(unit: 's');
        const config2 = XAxisConfig(unit: 'ms');

        expect(config1, isNot(equals(config2)));
      });

      test('different visible values are not equal', () {
        const config1 = XAxisConfig(visible: true);
        const config2 = XAxisConfig(visible: false);

        expect(config1, isNot(equals(config2)));
      });

      test('different min values are not equal', () {
        const config1 = XAxisConfig(min: 0.0);
        const config2 = XAxisConfig(min: 10.0);

        expect(config1, isNot(equals(config2)));
      });

      test('different max values are not equal', () {
        const config1 = XAxisConfig(max: 100.0);
        const config2 = XAxisConfig(max: 200.0);

        expect(config1, isNot(equals(config2)));
      });

      test('different labelDisplay values are not equal', () {
        const config1 = XAxisConfig(
          labelDisplay: AxisLabelDisplay.labelOnly,
        );
        const config2 = XAxisConfig(
          labelDisplay: AxisLabelDisplay.none,
        );

        expect(config1, isNot(equals(config2)));
      });

      test('different minHeight values are not equal', () {
        const config1 = XAxisConfig(minHeight: 20.0);
        const config2 = XAxisConfig(minHeight: 30.0);

        expect(config1, isNot(equals(config2)));
      });

      test('hashCode is consistent with equality', () {
        const config1 = XAxisConfig(
          label: 'Time',
          unit: 's',
          visible: true,
        );

        const config2 = XAxisConfig(
          label: 'Time',
          unit: 's',
          visible: true,
        );

        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('identical objects are equal', () {
        const config = XAxisConfig(label: 'Test');
        expect(config, equals(config));
      });

      test('different color values are not equal', () {
        const config1 = XAxisConfig(color: Color(0xFF0000FF));
        const config2 = XAxisConfig(color: Color(0xFF00FF00));

        expect(config1, isNot(equals(config2)));
      });

      test('different showAxisLine values are not equal', () {
        const config1 = XAxisConfig(showAxisLine: true);
        const config2 = XAxisConfig(showAxisLine: false);

        expect(config1, isNot(equals(config2)));
      });

      test('different showTicks values are not equal', () {
        const config1 = XAxisConfig(showTicks: true);
        const config2 = XAxisConfig(showTicks: false);

        expect(config1, isNot(equals(config2)));
      });

      test('different showCrosshairLabel values are not equal', () {
        const config1 = XAxisConfig(showCrosshairLabel: true);
        const config2 = XAxisConfig(showCrosshairLabel: false);

        expect(config1, isNot(equals(config2)));
      });

      test('different maxHeight values are not equal', () {
        const config1 = XAxisConfig(maxHeight: 60.0);
        const config2 = XAxisConfig(maxHeight: 80.0);

        expect(config1, isNot(equals(config2)));
      });

      test('different tickLabelPadding values are not equal', () {
        const config1 = XAxisConfig(tickLabelPadding: 4.0);
        const config2 = XAxisConfig(tickLabelPadding: 8.0);

        expect(config1, isNot(equals(config2)));
      });

      test('different axisLabelPadding values are not equal', () {
        const config1 = XAxisConfig(axisLabelPadding: 5.0);
        const config2 = XAxisConfig(axisLabelPadding: 10.0);

        expect(config1, isNot(equals(config2)));
      });

      test('different axisMargin values are not equal', () {
        const config1 = XAxisConfig(axisMargin: 8.0);
        const config2 = XAxisConfig(axisMargin: 12.0);

        expect(config1, isNot(equals(config2)));
      });

      test('different tickCount values are not equal', () {
        const config1 = XAxisConfig(tickCount: 10);
        const config2 = XAxisConfig(tickCount: 20);

        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('returns readable debug string', () {
        const config = XAxisConfig(
          label: 'Time',
          unit: 's',
          visible: true,
        );

        final str = config.toString();

        // Should not be default Object.toString() (e.g., "Instance of 'XAxisConfig'")
        expect(str, isNot(contains('Instance of')));
        // Should contain class name
        expect(str, contains('XAxisConfig'));
      });

      test('toString contains relevant property information', () {
        const config = XAxisConfig(
          label: 'Power',
          unit: 'W',
          min: 0.0,
          max: 400.0,
        );

        final str = config.toString();

        // Should contain some property values for debugging
        expect(str, isNotEmpty);
        expect(str.length, greaterThan(10));
      });
    });

    group('XAxisLabelFormatter typedef', () {
      test('formatter accepts double and returns String', () {
        String formatter(double value) => '${value.toInt()} sec';

        expect(formatter(45.7), equals('45 sec'));
        expect(formatter(100.0), equals('100 sec'));
      });

      test('formatter can be assigned to XAxisConfig', () {
        String formatter(double value) => value.toStringAsFixed(1);

        final config = XAxisConfig(
          labelFormatter: formatter,
        );

        expect(config.labelFormatter, equals(formatter));
        expect(config.labelFormatter!(42.567), equals('42.6'));
      });

      test('formatter can handle various numeric formats', () {
        String scientificFormatter(double value) {
          return value.toStringAsExponential(2);
        }

        expect(scientificFormatter(1234.5), contains('e'));
      });
    });
  });
}
