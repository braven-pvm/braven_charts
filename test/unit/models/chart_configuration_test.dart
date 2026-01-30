// @orchestra-task: 2
@Tags(['tdd-red'])
library;

// Import the ACTUAL agentic ChartConfiguration, not a placeholder
import 'package:braven_charts/src/agentic/models/axis_config.dart'
    show YAxisConfig, AxisPosition;
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart'
    show SeriesConfig;
import 'package:flutter_test/flutter_test.dart';

/// T007: TDD Red Phase - Agentic ChartConfiguration yAxes[] prohibition tests.
///
/// According to FR-003, the agentic schema should NOT have a top-level yAxes[]
/// array. Y-axis configuration should be done inline per-series via yAxisConfig.
///
/// Tests FAIL because:
/// - The current ChartConfiguration still has yAxes[] field
/// - The toJson() still outputs yAxes[] in serialization
/// - Need to remove yAxes[] per FR-003
void main() {
  // Helper to create a minimal valid series
  SeriesConfig minimalSeries() =>
      SeriesConfig(id: 'test-series', data: const []);

  group('ChartConfiguration yAxes prohibition (FR-003)', () {
    group('yAxes field should not exist', () {
      test('ChartConfiguration toJson() should NOT output yAxes array', () {
        // Arrange: Create a chart configuration with minimal series
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [minimalSeries()],
        );

        // Act: Serialize to JSON
        final json = config.toJson();

        // Assert: yAxes should NOT appear in serialization per FR-003
        // This test FAILS because current implementation includes yAxes
        expect(json.containsKey('yAxes'), isFalse,
            reason: 'FR-003: yAxes[] array must not appear in serialization');
      });

      test('ChartConfiguration with yAxes should not serialize yAxes', () {
        // Arrange: Create configuration with yAxes (legacy pattern)
        final config = ChartConfiguration(
          type: ChartType.line,
          series: [minimalSeries()],
          yAxes: [
            YAxisConfig(
              id: 'left-axis',
              position: AxisPosition.left,
              label: 'Values',
            ),
          ],
        );

        // Act: Serialize
        final json = config.toJson();

        // Assert: Even if constructor accepts yAxes, it should not serialize
        // This test FAILS because yAxes is serialized
        expect(json.containsKey('yAxes'), isFalse,
            reason: 'FR-003: yAxes[] must be ignored during serialization');
      });
    });

    group('fromJson should ignore/reject yAxes', () {
      test('fromJson should ignore yAxes array in input', () {
        // Arrange: JSON with yAxes array (legacy format)
        final legacyJson = {
          'type': 'line',
          'series': [
            {'id': 'test-series', 'data': []}
          ],
          'yAxes': [
            {'id': 'axis1', 'position': 'left', 'label': 'Values'},
          ],
        };

        // Act: Parse from JSON
        final config = ChartConfiguration.fromJson(legacyJson);

        // Assert: yAxes should be empty/ignored
        // This test FAILS because fromJson parses yAxes
        expect(config.yAxes.isEmpty, isTrue,
            reason: 'FR-003: yAxes[] in input should be ignored');
      });

      test('round-trip should not preserve yAxes array', () {
        // Arrange: Create config with yAxes
        final original = ChartConfiguration(
          type: ChartType.bar,
          series: [minimalSeries()],
          yAxes: [
            YAxisConfig(id: 'test-axis', position: AxisPosition.left),
          ],
        );

        // Act: Round-trip through JSON
        final json = original.toJson();
        final restored = ChartConfiguration.fromJson(json);

        // Assert: yAxes should not survive round-trip
        // This test FAILS because yAxes is preserved
        expect(restored.yAxes.isEmpty, isTrue,
            reason:
                'FR-003: yAxes[] must not survive serialization round-trip');
      });
    });

    group('series-level yAxisConfig pattern', () {
      test('series should define y-axis via yAxisConfig not yAxisId', () {
        // This test verifies the NEW pattern where series have inline yAxisConfig
        // rather than referencing shared yAxes via yAxisId

        // Arrange: JSON with series using inline yAxisConfig
        final json = {
          'type': 'line',
          'series': [
            {
              'id': 'power',
              'yAxisConfig': {
                'position': 'left',
                'label': 'Power',
                'unit': 'W',
              },
              'data': [],
            },
          ],
        };

        // Act & Assert: Try to parse and verify behavior
        // This test documents that fromJson needs to properly handle the series
        // with nested yAxisConfig (FR-001)
        late ChartConfiguration config;
        try {
          config = ChartConfiguration.fromJson(json);
        } catch (e) {
          // If parsing fails, that itself is a failure - need to support new format
          fail(
              'FR-001: ChartConfiguration.fromJson must support series with nested yAxisConfig. Error: $e');
        }

        // Assert: Series should have yAxisConfig parsed
        expect(config.series.length, equals(1),
            reason: 'Should parse series correctly');

        // Series should have access to its y-axis config via nested object
        // This test will FAIL if SeriesConfig doesn't support nested yAxisConfig
        final seriesJson = config.series[0].toJson();
        expect(seriesJson.containsKey('yAxisConfig'), isTrue,
            reason:
                'FR-001: Series should have nested yAxisConfig, not flat fields');
      });
    });
  });
}
