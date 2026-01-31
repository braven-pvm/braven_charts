// @orchestra-task: 10
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

/// US4: TDD Red Phase Tests - Annotation Validation V030-V044
///
/// These tests define the validation requirements for:
/// - V030-V034: seriesId reference validation
/// - V040-V044: Type-specific field validation
///
/// They will FAIL until the GREEN phase implementation is complete.
void main() {
  group('SchemaValidator (US4 Annotation Validation)', () {
    // ==========================================================
    // V030: Error when annotation's seriesId references non-existent series
    // ==========================================================
    group('V030: seriesId references non-existent series', () {
      test(
        'returns error when annotation seriesId references non-existent series',
        () {
          // V030: Per FR-022, system must validate seriesId references exist
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.horizontal,
                value: 50.0,
                seriesId: 'nonexistent', // This series doesn't exist
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V030: annotation referencing non-existent series should make chart invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V030'),
            isTrue,
            reason: 'Should emit V030 error for non-existent seriesId',
          );
          expect(
            result.errors.any((e) => e.message.contains('nonexistent')),
            isTrue,
            reason: 'Error message should include the non-existent series ID',
          );
        },
      );

      test(
        'passes validation when annotation seriesId references existing series',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.horizontal,
                value: 50.0,
                seriesId: 'power', // Valid series ID
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V030'),
            isFalse,
            reason: 'V030 should not trigger for valid seriesId reference',
          );
        },
      );
    });

    // ==========================================================
    // V031: Error when point annotation lacks seriesId
    // ==========================================================
    group('V031: point annotation requires seriesId', () {
      test(
        'returns error when marker annotation with dataPointIndex lacks seriesId',
        () {
          // V031: Per FR-023, point annotations (those using dataPointIndex)
          // always require seriesId to identify which series the point belongs to
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [
                  DataPoint(x: 0, y: 100),
                  DataPoint(x: 1, y: 200),
                ],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                dataPointIndex: 0, // Referencing a data point
                // Missing seriesId - should trigger V031
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V031: point annotation without seriesId should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V031'),
            isTrue,
            reason: 'Should emit V031 error for point annotation lacking seriesId',
          );
          expect(
            result.errors.any((e) => e.message.contains('seriesId') || e.message.contains('point') || e.message.contains('dataPointIndex')),
            isTrue,
            reason: 'Error message should explain why seriesId is required',
          );
        },
      );
    });

    // ==========================================================
    // V032: Error when marker annotation lacks seriesId
    // ==========================================================
    group('V032: marker annotation requires seriesId', () {
      test(
        'returns error when marker annotation lacks seriesId',
        () {
          // V032: Per FR-023, marker annotations always require seriesId
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                x: 0.5,
                y: 75.0,
                // Missing seriesId - should trigger V032
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V032: marker annotation without seriesId should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V032'),
            isTrue,
            reason: 'Should emit V032 error for marker lacking seriesId',
          );
          expect(
            result.errors.any((e) => e.message.contains('marker') || e.message.contains('seriesId')),
            isTrue,
            reason: 'Error message should mention marker and seriesId',
          );
        },
      );

      test(
        'passes validation when marker annotation has seriesId',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                x: 0.5,
                y: 75.0,
                seriesId: 'power', // Has seriesId
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V032'),
            isFalse,
            reason: 'V032 should not trigger when marker has seriesId',
          );
        },
      );
    });

    // ==========================================================
    // V033: Error when horizontal referenceLine in perSeries mode lacks seriesId
    // ==========================================================
    group('V033: horizontal referenceLine in perSeries requires seriesId', () {
      test(
        'returns error when horizontal referenceLine in perSeries mode lacks seriesId',
        () {
          // V033: Per FR-024, horizontal referenceLines need seriesId in perSeries
          // mode because the y-value depends on the series scale
          const chart = ChartConfiguration(
            normalizationMode: NormalizationModeConfig.perSeries,
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
                yAxis: YAxisConfig(label: 'Power', position: AxisPosition.left),
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.horizontal, // Horizontal in perSeries
                value: 75.0,
                // Missing seriesId - should trigger V033
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V033: horizontal referenceLine in perSeries without seriesId should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V033'),
            isTrue,
            reason: 'Should emit V033 error for horizontal referenceLine lacking seriesId in perSeries mode',
          );
        },
      );

      test(
        'does NOT error for vertical referenceLine in perSeries mode without seriesId',
        () {
          // Vertical referenceLines don't need seriesId even in perSeries mode
          // because x-axis is shared across all series
          const chart = ChartConfiguration(
            normalizationMode: NormalizationModeConfig.perSeries,
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
                yAxis: YAxisConfig(label: 'Power', position: AxisPosition.left),
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.vertical, // Vertical - no seriesId needed
                value: 0.5,
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V033'),
            isFalse,
            reason: 'V033 should not trigger for vertical referenceLines',
          );
        },
      );

      test(
        'does NOT error for horizontal referenceLine in none mode without seriesId',
        () {
          // In 'none' mode, all series share the same y-axis scale
          // so horizontal referenceLines don't require seriesId
          const chart = ChartConfiguration(
            normalizationMode: NormalizationModeConfig.none,
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.horizontal,
                value: 75.0,
                // No seriesId - OK in 'none' mode
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V033'),
            isFalse,
            reason: 'V033 should not trigger in none normalization mode',
          );
        },
      );
    });

    // ==========================================================
    // V034: Error when horizontal zone in perSeries mode lacks seriesId
    // ==========================================================
    group('V034: horizontal zone in perSeries requires seriesId', () {
      test(
        'returns error when horizontal zone in perSeries mode lacks seriesId',
        () {
          // V034: Per FR-024, horizontal zones need seriesId in perSeries mode
          const chart = ChartConfiguration(
            normalizationMode: NormalizationModeConfig.perSeries,
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
                yAxis: YAxisConfig(label: 'Power', position: AxisPosition.left),
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.zone,
                orientation: Orientation.horizontal, // Horizontal zone
                minValue: 50.0,
                maxValue: 100.0,
                // Missing seriesId - should trigger V034
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V034: horizontal zone in perSeries without seriesId should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V034'),
            isTrue,
            reason: 'Should emit V034 error for horizontal zone lacking seriesId in perSeries mode',
          );
        },
      );
    });

    // ==========================================================
    // V040: Error when referenceLine annotation lacks value
    // ==========================================================
    group('V040: referenceLine requires value', () {
      test(
        'returns error when referenceLine annotation lacks value',
        () {
          // V040: Per FR-026, referenceLine must have value field
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.horizontal,
                // Missing value - should trigger V040
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V040: referenceLine without value should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V040'),
            isTrue,
            reason: 'Should emit V040 error for referenceLine lacking value',
          );
          expect(
            result.errors.any((e) => e.message.contains('value') || e.message.contains('referenceLine')),
            isTrue,
            reason: 'Error message should mention value or referenceLine',
          );
        },
      );

      test(
        'passes validation when referenceLine has value',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.referenceLine,
                orientation: Orientation.horizontal,
                value: 75.0, // Has value
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V040'),
            isFalse,
            reason: 'V040 should not trigger when referenceLine has value',
          );
        },
      );
    });

    // ==========================================================
    // V041: Error when zone annotation lacks minValue or maxValue
    // ==========================================================
    group('V041: zone requires minValue and maxValue', () {
      test(
        'returns error when zone annotation lacks minValue',
        () {
          // V041: Per FR-026, zone must have both minValue and maxValue
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.zone,
                orientation: Orientation.horizontal,
                maxValue: 100.0,
                // Missing minValue - should trigger V041
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V041: zone without minValue should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V041'),
            isTrue,
            reason: 'Should emit V041 error for zone lacking minValue',
          );
        },
      );

      test(
        'returns error when zone annotation lacks maxValue',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.zone,
                orientation: Orientation.horizontal,
                minValue: 50.0,
                // Missing maxValue - should trigger V041
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V041: zone without maxValue should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V041'),
            isTrue,
            reason: 'Should emit V041 error for zone lacking maxValue',
          );
        },
      );

      test(
        'passes validation when zone has both minValue and maxValue',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.zone,
                orientation: Orientation.horizontal,
                minValue: 50.0,
                maxValue: 100.0, // Has both values
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V041'),
            isFalse,
            reason: 'V041 should not trigger when zone has both min and max',
          );
        },
      );
    });

    // ==========================================================
    // V042: Error when point-style annotation lacks dataPointIndex
    // ==========================================================
    group('V042: point annotations require dataPointIndex', () {
      test(
        'returns error when marker annotation with seriesId lacks dataPointIndex',
        () {
          // V042: Per FR-026, annotations referencing data points need dataPointIndex
          // Note: A marker with seriesId but no x/y coordinates implies it should
          // reference a specific data point via dataPointIndex
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100), DataPoint(x: 1, y: 200)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                seriesId: 'power',
                // Missing both x/y and dataPointIndex - needs one or the other
                // If using seriesId with marker type, should have dataPointIndex
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V042: marker referencing series without dataPointIndex or x/y should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V042'),
            isTrue,
            reason: 'Should emit V042 error for marker lacking dataPointIndex',
          );
        },
      );
    });

    // ==========================================================
    // V043: Error when dataPointIndex is out of range
    // ==========================================================
    group('V043: dataPointIndex must be in valid range', () {
      test(
        'returns error when dataPointIndex is negative',
        () {
          // V043: dataPointIndex must be >= 0
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100), DataPoint(x: 1, y: 200)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                seriesId: 'power',
                dataPointIndex: -1, // Invalid - negative index
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V043: negative dataPointIndex should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V043'),
            isTrue,
            reason: 'Should emit V043 error for negative dataPointIndex',
          );
        },
      );

      test(
        'returns error when dataPointIndex exceeds series data length',
        () {
          // V043: dataPointIndex must be < series.data.length
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [
                  DataPoint(x: 0, y: 100),
                  DataPoint(x: 1, y: 200),
                ], // 2 points, valid indices are 0 and 1
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                seriesId: 'power',
                dataPointIndex: 5, // Invalid - only 2 data points
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V043: dataPointIndex beyond series length should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V043'),
            isTrue,
            reason: 'Should emit V043 error for dataPointIndex exceeding series length',
          );
        },
      );

      test(
        'passes validation when dataPointIndex is within valid range',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [
                  DataPoint(x: 0, y: 100),
                  DataPoint(x: 1, y: 200),
                  DataPoint(x: 2, y: 300),
                ], // 3 points, valid indices are 0, 1, 2
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.marker,
                seriesId: 'power',
                dataPointIndex: 1, // Valid - within range
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V043'),
            isFalse,
            reason: 'V043 should not trigger for valid dataPointIndex',
          );
        },
      );
    });

    // ==========================================================
    // V044: Error when textLabel annotation lacks text
    // ==========================================================
    group('V044: textLabel requires text', () {
      test(
        'returns error when textLabel annotation lacks text',
        () {
          // V044: Per FR-026, textLabel must have text field
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.textLabel,
                position: AnnotationPosition.topRight,
                // Missing text - should trigger V044
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V044: textLabel without text should be invalid');
          expect(result.errors, isNotEmpty);
          expect(
            result.errors.any((e) => e.code == 'V044'),
            isTrue,
            reason: 'Should emit V044 error for textLabel lacking text',
          );
          expect(
            result.errors.any((e) => e.message.contains('text') || e.message.contains('textLabel')),
            isTrue,
            reason: 'Error message should mention text or textLabel',
          );
        },
      );

      test(
        'returns error when textLabel has empty text',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.textLabel,
                position: AnnotationPosition.topRight,
                text: '', // Empty string - should also trigger V044
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(result.isValid, isFalse, reason: 'V044: textLabel with empty text should be invalid');
          expect(
            result.errors.any((e) => e.code == 'V044'),
            isTrue,
            reason: 'Should emit V044 error for textLabel with empty text',
          );
        },
      );

      test(
        'passes validation when textLabel has text',
        () {
          const chart = ChartConfiguration(
            series: [
              SeriesConfig(
                id: 'power',
                data: [DataPoint(x: 0, y: 100)],
              ),
            ],
            annotations: [
              AnnotationConfig(
                type: AnnotationType.textLabel,
                position: AnnotationPosition.topRight,
                text: 'Important note', // Has text
              ),
            ],
          );

          final result = SchemaValidator.validate(chart);

          expect(
            result.errors.any((e) => e.code == 'V044'),
            isFalse,
            reason: 'V044 should not trigger when textLabel has text',
          );
        },
      );
    });
  });
}
