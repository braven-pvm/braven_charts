// @orchestra-task: 6
library;

import 'package:braven_agent/src/models/annotation_config.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/data_point.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/models/series_config.dart';
import 'package:braven_agent/src/models/y_axis_config.dart';
import 'package:braven_agent/src/validation/schema_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// T022-T025: Schema Validator Tests for US1.
///
/// These tests verify the validation rules for ChartConfiguration:
/// - V001: Warning when perSeries mode has chart-level yAxis
/// - V002: Warning when perSeries mode has series without yAxis
/// - V003: Error when duplicate series IDs exist
/// - V004: Error when duplicate annotation IDs exist
void main() {
  group('SchemaValidator (US1)', () {
    // ==========================================================
    // T022: V001 - perSeries + chart yAxis warning
    // ==========================================================
    group('V001: perSeries mode with chart-level yAxis', () {
      test('emits warning when perSeries mode has chart-level yAxis', () {
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

      test('does NOT emit warning when none mode has chart-level yAxis', () {
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
    // T023: V002 - perSeries mode with missing series yAxis
    // ==========================================================
    group('V002: perSeries mode with missing series yAxis', () {
      test('emits warning when series lacks yAxis in perSeries mode', () {
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

      test('does NOT emit warning when series has yAxis in perSeries mode', () {
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

      test('does NOT emit warning for missing yAxis in none mode', () {
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
    // T024: V003 - Duplicate series IDs error
    // ==========================================================
    group('V003: duplicate series IDs', () {
      test('returns error when duplicate series IDs exist', () {
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

      test('returns error with multiple duplicates', () {
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

      test('passes validation with unique series IDs', () {
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
    // T025: V004 - Duplicate annotation IDs error
    // ==========================================================
    group('V004: duplicate annotation IDs', () {
      test('returns error when duplicate annotation IDs exist', () {
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

      test('passes validation with unique annotation IDs', () {
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

      test('allows annotations without IDs (system will generate)', () {
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
    group('ValidationResult structure', () {
      test('ValidationResult has isValid property', () {
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

      test('ValidationResult has errors list', () {
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

      test('ValidationResult has warnings list', () {
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

      test('ValidationError has code and message', () {
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

      test('ValidationWarning has code and message', () {
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

  // ============================================================
  // US2: TDD Red Phase Tests - Modification Validation V010-V022
  // @orchestra-task: 6
  // ============================================================
  group('SchemaValidator (US2 Modification Validation)', () {
    // ==========================================================
    // V010: Error when update.series[].id not found
    // ==========================================================
    group('V010: update non-existent series', () {
      test(
        'returns error when update.series references non-existent series ID',
        () {
          // V010: Error if update.series[].id not found in existing chart
          // This validation happens during modify_chart operation
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
          );

          // Validate modification operation
          final result = SchemaValidator.validateModification(
            chart,
            const ModificationRequest(
              update: UpdateOperation(
                series: [
                  SeriesModification(id: 'non-existent', color: '#FF0000'),
                ],
              ),
            ),
          );

          expect(result.isValid, isFalse);
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V010'),
            isTrue,
            reason: 'Should emit V010 error for non-existent series update',
          );
          expect(
            result.errors.any((e) => e.message.contains('non-existent')),
            isTrue,
            reason: 'Error message should include the missing series ID',
          );
        },
      );
    });

    // ==========================================================
    // V011: Error when remove.series contains non-existent ID
    // ==========================================================
    group('V011: remove non-existent series', () {
      test(
        'returns error when remove.series contains non-existent ID',
        () {
          // V011: Error if remove.series contains non-existent ID
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
          );

          final result = SchemaValidator.validateModification(
            chart,
            const ModificationRequest(
              remove: RemoveOperation(
                series: ['unknown-series'],
              ),
            ),
          );

          expect(result.isValid, isFalse);
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V011'),
            isTrue,
            reason: 'Should emit V011 error for non-existent series removal',
          );
          expect(
            result.errors.any((e) => e.message.contains('unknown-series')),
            isTrue,
            reason: 'Error message should include the missing series ID',
          );
        },
      );
    });

    // ==========================================================
    // V012: Error when add.series[].id already exists
    // ==========================================================
    group('V012: add duplicate series', () {
      test(
        'returns error when add.series[].id already exists in chart',
        () {
          // V012: Error if add.series[].id already exists
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
          );

          final result = SchemaValidator.validateModification(
            chart,
            const ModificationRequest(
              add: AddOperation(
                series: [
                  SeriesAddition(
                    id: 'power', // Already exists
                    data: [DataPoint(x: 1, y: 200)],
                  ),
                ],
              ),
            ),
          );

          expect(result.isValid, isFalse);
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V012'),
            isTrue,
            reason: 'Should emit V012 error for duplicate series ID on add',
          );
          expect(
            result.errors.any((e) => e.message.contains('power')),
            isTrue,
            reason: 'Error message should include the duplicate series ID',
          );
        },
      );
    });

    // ==========================================================
    // V020: Error when update.annotations[].id not found
    // ==========================================================
    group('V020: update non-existent annotation', () {
      test(
        'returns error when update.annotations references non-existent ID',
        () {
          // V020: Error if update.annotations[].id not found in chart
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'data',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                id: 'ann-001',
                type: AnnotationType.referenceLine,
                value: 100,
                orientation: Orientation.horizontal,
              ),
            ],
          );

          final result = SchemaValidator.validateModification(
            chart,
            const ModificationRequest(
              update: UpdateOperation(
                annotations: [
                  AnnotationModification(id: 'ann-999', label: 'New Label'),
                ],
              ),
            ),
          );

          expect(result.isValid, isFalse);
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V020'),
            isTrue,
            reason: 'Should emit V020 error for non-existent annotation update',
          );
          expect(
            result.errors.any((e) => e.message.contains('ann-999')),
            isTrue,
            reason: 'Error message should include the missing annotation ID',
          );
        },
      );
    });

    // ==========================================================
    // V021: Error when remove.annotations contains non-existent ID
    // ==========================================================
    group('V021: remove non-existent annotation', () {
      test(
        'returns error when remove.annotations contains non-existent ID',
        () {
          // V021: Error if remove.annotations contains non-existent ID
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'data',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                id: 'ann-001',
                type: AnnotationType.referenceLine,
                value: 100,
                orientation: Orientation.horizontal,
              ),
            ],
          );

          final result = SchemaValidator.validateModification(
            chart,
            const ModificationRequest(
              remove: RemoveOperation(
                annotations: ['unknown-annotation'],
              ),
            ),
          );

          expect(result.isValid, isFalse);
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V021'),
            isTrue,
            reason:
                'Should emit V021 error for non-existent annotation removal',
          );
          expect(
            result.errors.any((e) => e.message.contains('unknown-annotation')),
            isTrue,
            reason: 'Error message should include the missing annotation ID',
          );
        },
      );
    });

    // ==========================================================
    // V022: Warning when agent supplies id on add.annotations
    // ==========================================================
    group('V022: agent-supplied annotation ID ignored', () {
      test(
        'returns warning when add.annotations includes id field',
        () {
          // V022: Warning when agent supplies id on add - id is system-generated
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'data',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
          );

          final result = SchemaValidator.validateModification(
            chart,
            const ModificationRequest(
              add: AddOperation(
                annotations: [
                  AnnotationAddition(
                    id: 'user-supplied-id', // Should trigger warning
                    type: AnnotationType.referenceLine,
                    value: 200,
                    orientation: Orientation.horizontal,
                  ),
                ],
              ),
            ),
          );

          // Should be valid but with warning
          expect(result.isValid, isTrue);
          expect(result.warnings, isNotEmpty);
          expect(
            result.warnings.any((w) => w.code == 'V022'),
            isTrue,
            reason: 'Should emit V022 warning for agent-supplied annotation ID',
          );
          expect(
            result.warnings.any((w) =>
                w.message.contains('system-generated') ||
                w.message.contains('ignored')),
            isTrue,
            reason:
                'Warning message should mention that ID is system-generated or ignored',
          );
        },
      );
    });
  });
}
