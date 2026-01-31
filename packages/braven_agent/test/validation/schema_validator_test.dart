// @orchestra-task: 4
@Tags(['tdd-red'])
library;

import 'package:braven_agent/src/models/annotation_config.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/data_point.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/models/series_config.dart';
import 'package:braven_agent/src/models/y_axis_config.dart';
import 'package:braven_agent/src/validation/schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// T022-T025: TDD Red Phase - Schema Validator Tests for US1.
///
/// These tests verify the validation rules for ChartConfiguration:
/// - V001: Warning when perSeries mode has chart-level yAxis
/// - V002: Warning when perSeries mode has series without yAxis
/// - V003: Error when duplicate series IDs exist
/// - V004: Error when duplicate annotation IDs exist
///
/// Tests are expected to FAIL until SchemaValidator is implemented.
void main() {
  group('[tdd-red] SchemaValidator (US1)', () {
    // ==========================================================
    // [tdd-red] T022: V001 - perSeries + chart yAxis warning
    // ==========================================================
    group('[tdd-red] V001: perSeries mode with chart-level yAxis', () {
      test('[tdd-red] emits warning when perSeries mode has chart-level yAxis',
          () {
        // T022: Per spec, when normalizationMode is perSeries,
        // chart-level yAxis should trigger a warning and be ignored
        const chart = ChartConfiguration(
          normalizationMode: NormalizationModeConfig.perSeries,
          yAxes: [
            YAxisConfig(
              label: 'Chart Level Axis',
              position: AxisPosition.left,
            ),
          ],
          series: [
            SeriesConfig(
              id: 'power',
              data: [DataPoint(x: 0, y: 100)],
              yAxis: YAxisConfig(
                label: 'Power',
                position: AxisPosition.left,
              ),
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should have a V001 warning
        expect(result.warnings, isNotEmpty,
            reason:
                'V001: should emit warning for chart-level yAxis in perSeries mode');
        expect(
          result.warnings.any((w) => w.code == 'V001'),
          isTrue,
          reason: 'Warning should have code V001',
        );
        expect(
          result.warnings.any((w) => w.message.contains('yAxis')),
          isTrue,
          reason: 'Warning message should mention yAxis',
        );
      });

      test(
          '[tdd-red] does NOT emit warning when none mode has chart-level yAxis',
          () {
        // When normalizationMode is 'none', chart-level yAxis is valid
        const chart = ChartConfiguration(
          normalizationMode: NormalizationModeConfig.none,
          yAxes: [
            YAxisConfig(
              label: 'Shared Axis',
              position: AxisPosition.left,
            ),
          ],
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should NOT have V001 warning
        expect(
          result.warnings.any((w) => w.code == 'V001'),
          isFalse,
          reason: 'V001 should not trigger for none normalization mode',
        );
      });
    });

    // ==========================================================
    // [tdd-red] T023: V002 - perSeries mode with missing series yAxis
    // ==========================================================
    group('[tdd-red] V002: perSeries mode with missing series yAxis', () {
      test('[tdd-red] emits warning when series lacks yAxis in perSeries mode',
          () {
        // T023: In perSeries mode, series without yAxis get default axis,
        // but should emit a warning to alert the user
        const chart = ChartConfiguration(
          normalizationMode: NormalizationModeConfig.perSeries,
          series: [
            SeriesConfig(
              id: 'power',
              data: [DataPoint(x: 0, y: 100)],
              yAxis: YAxisConfig(
                label: 'Power',
                position: AxisPosition.left,
              ),
            ),
            SeriesConfig(
              id: 'heart-rate',
              data: [DataPoint(x: 0, y: 145)],
              // Missing yAxis - should trigger V002 warning
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should have a V002 warning
        expect(result.warnings, isNotEmpty,
            reason:
                'V002: should emit warning for series without yAxis in perSeries mode');
        expect(
          result.warnings.any((w) => w.code == 'V002'),
          isTrue,
          reason: 'Warning should have code V002',
        );
        expect(
          result.warnings.any((w) => w.message.contains('heart-rate')),
          isTrue,
          reason: 'Warning message should mention the series ID',
        );
      });

      test(
          '[tdd-red] does NOT emit warning when series has yAxis in perSeries mode',
          () {
        // All series have yAxis, no warning needed
        const chart = ChartConfiguration(
          normalizationMode: NormalizationModeConfig.perSeries,
          series: [
            SeriesConfig(
              id: 'power',
              data: [DataPoint(x: 0, y: 100)],
              yAxis: YAxisConfig(
                label: 'Power',
                position: AxisPosition.left,
              ),
            ),
            SeriesConfig(
              id: 'heart-rate',
              data: [DataPoint(x: 0, y: 145)],
              yAxis: YAxisConfig(
                label: 'Heart Rate',
                position: AxisPosition.right,
              ),
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should NOT have V002 warning
        expect(
          result.warnings.any((w) => w.code == 'V002'),
          isFalse,
          reason: 'V002 should not trigger when all series have yAxis',
        );
      });

      test('[tdd-red] does NOT emit warning for missing yAxis in none mode',
          () {
        // In 'none' mode, series without yAxis is normal
        const chart = ChartConfiguration(
          normalizationMode: NormalizationModeConfig.none,
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
              // No yAxis - fine in none mode
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should NOT have V002 warning
        expect(
          result.warnings.any((w) => w.code == 'V002'),
          isFalse,
          reason: 'V002 should not trigger in none normalization mode',
        );
      });
    });

    // ==========================================================
    // [tdd-red] T024: V003 - Duplicate series IDs error
    // ==========================================================
    group('[tdd-red] V003: duplicate series IDs', () {
      test('[tdd-red] returns error when duplicate series IDs exist', () {
        // T024: Per FR-020, all series IDs must be unique
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'power',
              data: [DataPoint(x: 0, y: 100)],
            ),
            SeriesConfig(
              id: 'power', // Duplicate ID!
              data: [DataPoint(x: 0, y: 200)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should have a V003 error
        expect(result.isValid, isFalse,
            reason: 'V003: duplicate series IDs should make chart invalid');
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.any((e) => e.code == 'V003'),
          isTrue,
          reason: 'Error should have code V003',
        );
        expect(
          result.errors.any((e) => e.message.contains('power')),
          isTrue,
          reason: 'Error message should mention the duplicate ID',
        );
      });

      test('[tdd-red] returns error with multiple duplicates', () {
        // Multiple duplicate groups should all be reported
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'power',
              data: [DataPoint(x: 0, y: 100)],
            ),
            SeriesConfig(
              id: 'power', // Duplicate
              data: [DataPoint(x: 0, y: 200)],
            ),
            SeriesConfig(
              id: 'hr',
              data: [DataPoint(x: 0, y: 145)],
            ),
            SeriesConfig(
              id: 'hr', // Another duplicate
              data: [DataPoint(x: 0, y: 150)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        expect(result.isValid, isFalse);
        // Should report both duplicates
        final v003Errors =
            result.errors.where((e) => e.code == 'V003').toList();
        expect(v003Errors.length, greaterThanOrEqualTo(2),
            reason: 'Should report all duplicate ID groups');
      });

      test('[tdd-red] passes validation with unique series IDs', () {
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'power',
              data: [DataPoint(x: 0, y: 100)],
            ),
            SeriesConfig(
              id: 'heart-rate',
              data: [DataPoint(x: 0, y: 145)],
            ),
            SeriesConfig(
              id: 'cadence',
              data: [DataPoint(x: 0, y: 90)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should NOT have V003 error
        expect(
          result.errors.any((e) => e.code == 'V003'),
          isFalse,
          reason: 'V003 should not trigger with unique series IDs',
        );
      });
    });

    // ==========================================================
    // [tdd-red] T025: V004 - Duplicate annotation IDs error
    // ==========================================================
    group('[tdd-red] V004: duplicate annotation IDs', () {
      test('[tdd-red] returns error when duplicate annotation IDs exist', () {
        // T025: Per FR-021, all annotation IDs must be unique
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
          annotations: [
            AnnotationConfig(
              id: 'ann-1',
              type: AnnotationType.referenceLine,
              orientation: Orientation.horizontal,
              value: 75,
            ),
            AnnotationConfig(
              id: 'ann-1', // Duplicate ID!
              type: AnnotationType.referenceLine,
              orientation: Orientation.horizontal,
              value: 125,
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should have a V004 error
        expect(result.isValid, isFalse,
            reason: 'V004: duplicate annotation IDs should make chart invalid');
        expect(result.errors, isNotEmpty);
        expect(
          result.errors.any((e) => e.code == 'V004'),
          isTrue,
          reason: 'Error should have code V004',
        );
        expect(
          result.errors.any((e) => e.message.contains('ann-1')),
          isTrue,
          reason: 'Error message should mention the duplicate ID',
        );
      });

      test('[tdd-red] passes validation with unique annotation IDs', () {
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
          annotations: [
            AnnotationConfig(
              id: 'ann-1',
              type: AnnotationType.referenceLine,
              orientation: Orientation.horizontal,
              value: 75,
            ),
            AnnotationConfig(
              id: 'ann-2',
              type: AnnotationType.referenceLine,
              orientation: Orientation.horizontal,
              value: 125,
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should NOT have V004 error
        expect(
          result.errors.any((e) => e.code == 'V004'),
          isFalse,
          reason: 'V004 should not trigger with unique annotation IDs',
        );
      });

      test('[tdd-red] allows annotations without IDs (system will generate)',
          () {
        // Annotations without IDs are fine during create - system generates them
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
          annotations: [
            AnnotationConfig(
              // No ID - will be generated
              type: AnnotationType.referenceLine,
              orientation: Orientation.horizontal,
              value: 75,
            ),
            AnnotationConfig(
              // No ID - will be generated
              type: AnnotationType.zone,
              orientation: Orientation.horizontal,
              minValue: 80,
              maxValue: 120,
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        // Should NOT have V004 error for null IDs
        expect(
          result.errors.any((e) => e.code == 'V004'),
          isFalse,
          reason: 'V004 should not trigger for annotations without IDs',
        );
      });
    });

    // ==========================================================
    // ValidationResult structure tests
    // ==========================================================
    group('[tdd-red] ValidationResult structure', () {
      test('[tdd-red] ValidationResult has isValid property', () {
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        expect(result.isValid, isA<bool>());
      });

      test('[tdd-red] ValidationResult has errors list', () {
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        expect(result.errors, isA<List<ValidationError>>());
      });

      test('[tdd-red] ValidationResult has warnings list', () {
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        expect(result.warnings, isA<List<ValidationWarning>>());
      });

      test('[tdd-red] ValidationError has code and message', () {
        const chart = ChartConfiguration(
          series: [
            SeriesConfig(
              id: 'dup',
              data: [DataPoint(x: 0, y: 100)],
            ),
            SeriesConfig(
              id: 'dup',
              data: [DataPoint(x: 0, y: 200)],
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        expect(result.errors, isNotEmpty);
        final error = result.errors.first;
        expect(error.code, isA<String>());
        expect(error.message, isA<String>());
        expect(error.code, isNotEmpty);
        expect(error.message, isNotEmpty);
      });

      test('[tdd-red] ValidationWarning has code and message', () {
        const chart = ChartConfiguration(
          normalizationMode: NormalizationModeConfig.perSeries,
          yAxes: [
            YAxisConfig(label: 'Ignored'),
          ],
          series: [
            SeriesConfig(
              id: 'data',
              data: [DataPoint(x: 0, y: 100)],
              yAxis: YAxisConfig(label: 'Series Axis'),
            ),
          ],
        );

        final result = SchemaValidator.validate(chart);

        expect(result.warnings, isNotEmpty);
        final warning = result.warnings.first;
        expect(warning.code, isA<String>());
        expect(warning.message, isA<String>());
        expect(warning.code, isNotEmpty);
        expect(warning.message, isNotEmpty);
      });
    });
  });
}
