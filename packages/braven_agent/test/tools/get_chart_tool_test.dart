// @orchestra-task: 8
@Tags(['tdd-red'])
library;

import 'package:braven_agent/src/models/annotation_config.dart';
import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/data_point.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/models/series_config.dart';
import 'package:braven_agent/src/tools/tools.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chart registry for testing - simulates chart storage
final Map<String, ChartConfiguration> _chartRegistry = {};

void main() {
  // ============================================================
  // GetChartTool Tests (TDD Red Phase - US3)
  // ============================================================
  group('GetChartTool', () {
    late GetChartTool tool;

    setUp(() {
      // Clear registry before each test for isolation
      _chartRegistry.clear();

      // Populate with test charts
      _chartRegistry['chart-with-annotations'] = _createChartWithAnnotations();
      _chartRegistry['chart-with-data'] = _createChartWithData();

      // Create tool with callback that returns chart by ID
      tool = GetChartTool(
        getChartById: (id) => _chartRegistry[id],
      );
    });

    // ==========================================================
    // Properties Tests
    // ==========================================================
    group('properties', () {
      test('name returns "get_chart"', () {
        expect(tool.name, equals('get_chart'));
      });

      test('description is non-empty and descriptive', () {
        expect(tool.description, isNotEmpty);
        expect(tool.description.length, greaterThan(20));
      });

      test('description mentions chart retrieval', () {
        expect(tool.description.toLowerCase(), contains('retriev'));
      });

      test('description mentions annotation IDs', () {
        expect(tool.description.toLowerCase(), contains('annotation'));
      });

      test('implements AgentTool interface', () {
        expect(tool, isA<AgentTool>());
      });
    });

    // ==========================================================
    // Input Schema Structure Tests
    // ==========================================================
    group('inputSchema structure', () {
      test('has type: object', () {
        expect(tool.inputSchema['type'], equals('object'));
      });

      test('has properties object', () {
        expect(tool.inputSchema['properties'], isA<Map<String, dynamic>>());
      });

      test('has required array', () {
        expect(tool.inputSchema['required'], isA<List>());
      });

      test('required includes "chartId"', () {
        final required = tool.inputSchema['required'] as List;
        expect(required, contains('chartId'));
      });

      test('required does NOT include "includeData" (optional)', () {
        final required = tool.inputSchema['required'] as List;
        expect(required, isNot(contains('includeData')));
      });

      group('properties content', () {
        test('has chartId property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('chartId'));
          expect(properties['chartId']['type'], equals('string'));
        });

        test('chartId has description', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties['chartId']['description'], isNotEmpty);
        });

        test('has includeData property', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties, contains('includeData'));
          expect(properties['includeData']['type'], equals('boolean'));
        });

        test('includeData has default value false', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties['includeData']['default'], equals(false));
        });

        test('includeData has description', () {
          final properties =
              tool.inputSchema['properties'] as Map<String, dynamic>;
          expect(properties['includeData']['description'], isNotEmpty);
        });
      });
    });

    // ==========================================================
    // Execute Method Tests - Basic Retrieval (FR-012)
    // ==========================================================
    group('execute - basic retrieval', () {
      test('returns chart configuration when chart exists', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.isError, isFalse);
        expect(result.data, isA<ChartConfiguration>());
      });

      test('result output is properly formatted JSON', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.output, startsWith('{'));
        expect(result.output, endsWith('}'));
      });

      test('result includes chart id in output', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.output, contains('chart-with-annotations'));
      });

      test('returned chart includes all annotation IDs (US3 AC1)', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.isError, isFalse);
        final chart = result.data as ChartConfiguration;

        // Verify all annotations have IDs
        expect(chart.annotations, hasLength(3));
        for (final annotation in chart.annotations) {
          expect(annotation.id, isNotNull);
          expect(annotation.id, isNotEmpty);
        }
      });

      test('returned chart has all expected properties', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        final chart = result.data as ChartConfiguration;
        expect(chart.id, isNotNull);
        expect(chart.title, equals('Chart With Annotations'));
        expect(chart.series, isNotEmpty);
        expect(chart.annotations, isNotEmpty);
      });
    });

    // ==========================================================
    // Execute Method Tests - includeData:false (FR-013)
    // ==========================================================
    group('execute - includeData:false (default)', () {
      test('series data is summarized as count when includeData is false',
          () async {
        final result = await tool.execute({
          'chartId': 'chart-with-data',
          'includeData': false,
        });

        expect(result.isError, isFalse);
        // Output should contain data count summary, not full arrays
        expect(result.output, contains('count'));
        expect(result.output, contains('5')); // 5 data points
      });

      test('includeData defaults to false when not specified (US3 AC2)',
          () async {
        // Call without includeData parameter - should default to false
        final result = await tool.execute({
          'chartId': 'chart-with-data',
        });

        expect(result.isError, isFalse);
        // Output should summarize data as count, not include full arrays
        expect(result.output, contains('count'));
      });

      test('does not include full data arrays when includeData is false',
          () async {
        final result = await tool.execute({
          'chartId': 'chart-with-data',
          'includeData': false,
        });

        // The output should NOT contain the actual data point values
        // Our test data has points at x: 0, 1, 2, 3, 4 with y values
        // When summarized, we should see {count: 5} not the actual points
        expect(result.output, isNot(contains('"x": 0')));
        expect(result.output, isNot(contains('"y": 20')));
      });
    });

    // ==========================================================
    // Execute Method Tests - includeData:true (FR-013)
    // ==========================================================
    group('execute - includeData:true', () {
      test('full data arrays are included when includeData is true (US3 AC3)',
          () async {
        final result = await tool.execute({
          'chartId': 'chart-with-data',
          'includeData': true,
        });

        expect(result.isError, isFalse);

        // Should contain full data arrays with actual point values
        final chart = result.data as ChartConfiguration;
        expect(chart.series.first.data, hasLength(5));
      });

      test('output contains actual data point values when includeData is true',
          () async {
        final result = await tool.execute({
          'chartId': 'chart-with-data',
          'includeData': true,
        });

        // When includeData is true, output should have the actual data
        // The test chart has data points with specific x,y values
        expect(result.output, contains('"data"'));
        // Should have actual numeric values in the output
      });

      test('data array structure is preserved when included', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-data',
          'includeData': true,
        });

        final chart = result.data as ChartConfiguration;
        final data = chart.series.first.data;

        // Verify data points are in expected format
        expect(data, isA<List<DataPoint>>());
        expect(data.first.x, equals(0));
        expect(data.last.x, equals(4));
      });
    });

    // ==========================================================
    // Execute Method Tests - Error Handling
    // ==========================================================
    group('execute - error handling', () {
      test('returns error when chartId is missing', () async {
        final result = await tool.execute({});

        expect(result.isError, isTrue);
        expect(result.output.toLowerCase(), contains('chartid'));
      });

      test('returns error when chart does not exist', () async {
        final result = await tool.execute({
          'chartId': 'non-existent-chart',
        });

        expect(result.isError, isTrue);
        expect(result.output.toLowerCase(), contains('not found'));
      });

      test('error message includes the invalid chartId', () async {
        final result = await tool.execute({
          'chartId': 'invalid-chart-xyz',
        });

        expect(result.isError, isTrue);
        expect(result.output, contains('invalid-chart-xyz'));
      });

      test('data is null on error', () async {
        final result = await tool.execute({
          'chartId': 'non-existent-chart',
        });

        expect(result.data, isNull);
      });
    });

    // ==========================================================
    // Execute Method Tests - No Active Chart Callback
    // ==========================================================
    group('execute - no chart retrieval callback', () {
      late GetChartTool toolWithoutCallback;

      setUp(() {
        toolWithoutCallback = GetChartTool(getChartById: null);
      });

      test('returns error when getChartById is null', () async {
        final result = await toolWithoutCallback.execute({
          'chartId': 'any-chart',
        });

        expect(result.isError, isTrue);
      });

      test('error message indicates no chart retrieval available', () async {
        final result = await toolWithoutCallback.execute({
          'chartId': 'any-chart',
        });

        expect(result.output.toLowerCase(), contains('chart'));
      });
    });

    // ==========================================================
    // ChartConfiguration Output Tests
    // ==========================================================
    group('ChartConfiguration output', () {
      test('output is properly formatted JSON', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.output, startsWith('{'));
        expect(result.output, endsWith('}'));
      });

      test('output contains chart title', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.output, contains('Chart With Annotations'));
      });

      test('output contains annotation information', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        expect(result.output, contains('annotation'));
      });

      test('annotation IDs are present in output', () async {
        final result = await tool.execute({
          'chartId': 'chart-with-annotations',
        });

        // The output should include the annotation IDs
        expect(result.output, contains('ann-'));
      });
    });
  });
}

/// Creates a chart configuration with annotations for testing.
ChartConfiguration _createChartWithAnnotations() {
  return const ChartConfiguration(
    id: 'chart-with-annotations',
    title: 'Chart With Annotations',
    series: [
      SeriesConfig(
        id: 'series-1',
        name: 'Test Series',
        type: ChartType.line,
        data: [
          DataPoint(x: 0, y: 10),
          DataPoint(x: 1, y: 20),
          DataPoint(x: 2, y: 15),
        ],
      ),
    ],
    annotations: [
      AnnotationConfig(
        id: 'ann-001',
        type: AnnotationType.referenceLine,
        orientation: Orientation.horizontal,
        value: 15.0,
        label: 'Threshold',
      ),
      AnnotationConfig(
        id: 'ann-002',
        type: AnnotationType.zone,
        minValue: 10.0,
        maxValue: 20.0,
        label: 'Target Zone',
      ),
      AnnotationConfig(
        id: 'ann-003',
        type: AnnotationType.textLabel,
        text: 'Important',
        x: 1.0,
        y: 20.0,
      ),
    ],
  );
}

/// Creates a chart configuration with data for includeData tests.
ChartConfiguration _createChartWithData() {
  return const ChartConfiguration(
    id: 'chart-with-data',
    title: 'Chart With Data',
    series: [
      SeriesConfig(
        id: 'data-series',
        name: 'Data Series',
        type: ChartType.line,
        data: [
          DataPoint(x: 0, y: 20),
          DataPoint(x: 1, y: 25),
          DataPoint(x: 2, y: 30),
          DataPoint(x: 3, y: 28),
          DataPoint(x: 4, y: 35),
        ],
      ),
    ],
  );
}
