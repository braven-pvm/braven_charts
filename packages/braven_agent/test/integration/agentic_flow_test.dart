// @orchestra-task: 14

import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/tools/create_chart_tool.dart';
import 'package:braven_agent/src/tools/get_chart_tool.dart';
import 'package:braven_agent/src/tools/modify_chart_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Agentic Flow Integration Tests', () {
    // Helper to extract ChartConfiguration from ToolResult
    ChartConfiguration getChartFromOutput(dynamic data) {
      if (data is ChartConfiguration) {
        return data;
      }
      throw Exception('ToolResult data is not ChartConfiguration: $data');
    }

    group('Full Lifecycle: Create → Get → Modify → Remove', () {
      test('complete chart lifecycle with series operations', () async {
        // --- STEP 1: CREATE ---
        // Create a chart with initial configuration
        final createTool = CreateChartTool();
        final createResult = await createTool.execute({
          'prompt': 'Create a multi-series chart for lifecycle testing',
          'title': 'Lifecycle Test Chart',
          'series': [
            {
              'id': 'series1',
              'name': 'Original Series',
              'type': 'line',
              'color': '#FF0000',
              'data': [
                {'x': 0, 'y': 10},
                {'x': 1, 'y': 20},
                {'x': 2, 'y': 30},
              ],
            },
            {
              'id': 'series2',
              'name': 'Secondary Series',
              'type': 'bar',
              'color': '#00FF00',
              'data': [
                {'x': 0, 'y': 15},
                {'x': 1, 'y': 25},
              ],
            },
          ],
        });

        expect(createResult.isError, isFalse, reason: 'Create chart failed');
        var activeChart = getChartFromOutput(createResult.data);

        // Verify initial creation
        expect(activeChart.id, isNotNull, reason: 'Chart should have an ID');
        expect(activeChart.title, equals('Lifecycle Test Chart'));
        expect(activeChart.series.length, equals(2));
        expect(
          activeChart.series.map((s) => s.id),
          containsAll(['series1', 'series2']),
        );

        final chartId = activeChart.id!;

        // Maintain a chart registry for GetChartTool
        final chartRegistry = <String, ChartConfiguration>{
          chartId: activeChart
        };

        // --- STEP 2: GET ---
        // Retrieve the chart to verify state
        final getTool = GetChartTool(
          getChartById: (id) => chartRegistry[id],
        );

        final getResult = await getTool.execute({
          'chartId': chartId,
          'includeData': true,
        });

        expect(getResult.isError, isFalse, reason: 'Get chart failed');
        final retrievedChart = getChartFromOutput(getResult.data);

        // Verify retrieved chart matches created chart
        expect(retrievedChart.id, equals(chartId));
        expect(retrievedChart.title, equals('Lifecycle Test Chart'));
        expect(retrievedChart.series.length, equals(2));

        // --- STEP 3: MODIFY ---
        // Update the chart: change title, add series, update series
        final modifyTool = ModifyChartTool(
          getActiveChart: () => chartRegistry[chartId],
        );

        final modifyResult = await modifyTool.execute({
          'modifications': {
            'title': 'Updated Lifecycle Chart',
            'add': {
              'series': [
                {
                  'id': 'series3',
                  'name': 'Added Series',
                  'type': 'scatter',
                  'data': [
                    {'x': 0, 'y': 5},
                  ],
                },
              ],
            },
            'update': {
              'series': [
                {
                  'id': 'series1',
                  'color': '#0000FF', // Change color from red to blue
                },
              ],
            },
          },
        });

        expect(modifyResult.isError, isFalse, reason: 'Modify chart failed');
        activeChart = getChartFromOutput(modifyResult.data);
        chartRegistry[chartId] = activeChart;

        // Verify modifications
        expect(activeChart.title, equals('Updated Lifecycle Chart'));
        expect(activeChart.series.length, equals(3));

        final series1 = activeChart.series.firstWhere((s) => s.id == 'series1');
        expect(series1.color, equals('#0000FF'));
        expect(series1.name, equals('Original Series')); // Name preserved

        final series3 = activeChart.series.firstWhere((s) => s.id == 'series3');
        expect(series3.type, equals(ChartType.scatter));

        // --- STEP 4: REMOVE ---
        // Remove a series
        final removeResult = await modifyTool.execute({
          'modifications': {
            'remove': {
              'series': ['series2'],
            },
          },
        });

        expect(removeResult.isError, isFalse, reason: 'Remove series failed');
        activeChart = getChartFromOutput(removeResult.data);
        chartRegistry[chartId] = activeChart;

        // Verify removal
        expect(activeChart.series.length, equals(2));
        expect(
          activeChart.series.map((s) => s.id),
          containsAll(['series1', 'series3']),
        );
        expect(
          activeChart.series.map((s) => s.id),
          isNot(contains('series2')),
        );

        // Verify chart ID is preserved through all operations
        expect(activeChart.id, equals(chartId));

        // Final GET to verify complete state
        final finalGetResult = await getTool.execute({
          'chartId': chartId,
          'includeData': true,
        });

        expect(finalGetResult.isError, isFalse);
        final finalChart = getChartFromOutput(finalGetResult.data);
        expect(finalChart.series.length, equals(2));
        expect(finalChart.title, equals('Updated Lifecycle Chart'));
      });

      test('GetChartTool includeData parameter controls data output', () async {
        // Create chart with multiple data points
        final createTool = CreateChartTool();
        final createResult = await createTool.execute({
          'prompt': 'Chart for data inclusion test',
          'series': [
            {
              'id': 'dataSeries',
              'data': [
                {'x': 0, 'y': 1},
                {'x': 1, 'y': 2},
                {'x': 2, 'y': 3},
                {'x': 3, 'y': 4},
                {'x': 4, 'y': 5},
              ],
            },
          ],
        });

        expect(createResult.isError, isFalse);
        final chart = getChartFromOutput(createResult.data);
        final chartId = chart.id!;

        final chartRegistry = <String, ChartConfiguration>{chartId: chart};
        final getTool = GetChartTool(getChartById: (id) => chartRegistry[id]);

        // Test with includeData = false (default)
        final summaryResult = await getTool.execute({
          'chartId': chartId,
          'includeData': false,
        });

        expect(summaryResult.isError, isFalse);
        // The output JSON should have data summarized
        expect(summaryResult.output, contains('"count"'));
        expect(summaryResult.output, contains('5'));

        // Test with includeData = true
        final fullResult = await getTool.execute({
          'chartId': chartId,
          'includeData': true,
        });

        expect(fullResult.isError, isFalse);
        // The output JSON should have full data arrays
        final fullChart = getChartFromOutput(fullResult.data);
        expect(fullChart.series.first.data.length, equals(5));
      });
    });

    group('Annotation Lifecycle: Add → Get → Update → Remove', () {
      test('complete annotation lifecycle with system-generated IDs', () async {
        // --- STEP 1: CREATE chart with initial annotation ---
        final createTool = CreateChartTool();
        final createResult = await createTool.execute({
          'prompt': 'Chart for annotation lifecycle testing',
          'title': 'Annotation Test Chart',
          'series': [
            {
              'id': 'mainSeries',
              'data': [
                {'x': 0, 'y': 0},
                {'x': 100, 'y': 100},
              ],
            },
          ],
          'annotations': [
            {
              'type': 'referenceLine',
              'orientation': 'horizontal',
              'value': 50.0,
              'label': 'Initial Threshold',
              'color': '#FF0000',
            },
          ],
        });

        expect(createResult.isError, isFalse,
            reason: 'Create chart with annotation failed');
        var activeChart = getChartFromOutput(createResult.data);
        final chartId = activeChart.id!;

        // Verify initial annotation has system-generated ID
        expect(activeChart.annotations.length, equals(1));
        final initialAnnotation = activeChart.annotations.first;
        expect(initialAnnotation.id, isNotNull,
            reason: 'Annotation should have system-generated ID');
        expect(initialAnnotation.id, isNotEmpty);
        expect(initialAnnotation.type, equals(AnnotationType.referenceLine));
        expect(initialAnnotation.label, equals('Initial Threshold'));

        final initialAnnotationId = initialAnnotation.id!;

        // Maintain chart registry
        final chartRegistry = <String, ChartConfiguration>{
          chartId: activeChart
        };

        // --- STEP 2: GET to verify annotation state ---
        final getTool = GetChartTool(getChartById: (id) => chartRegistry[id]);
        final getResult =
            await getTool.execute({'chartId': chartId, 'includeData': true});

        expect(getResult.isError, isFalse, reason: 'Get chart failed');
        final retrievedChart = getChartFromOutput(getResult.data);

        // Verify annotation ID persists through get operation
        expect(retrievedChart.annotations.length, equals(1));
        expect(
            retrievedChart.annotations.first.id, equals(initialAnnotationId));

        // --- STEP 3: ADD more annotations ---
        final modifyTool =
            ModifyChartTool(getActiveChart: () => chartRegistry[chartId]);

        final addAnnotationsResult = await modifyTool.execute({
          'modifications': {
            'add': {
              'annotations': [
                {
                  'type': 'zone',
                  'minValue': 20.0,
                  'maxValue': 40.0,
                  'color': '#00FF00',
                  'opacity': 0.3,
                  'label': 'Safe Zone',
                },
                {
                  'type': 'marker',
                  'x': 50.0,
                  'y': 50.0,
                  'label': 'Key Point',
                  'color': '#0000FF',
                },
              ],
            },
          },
        });

        expect(addAnnotationsResult.isError, isFalse,
            reason: 'Add annotations failed');
        activeChart = getChartFromOutput(addAnnotationsResult.data);
        chartRegistry[chartId] = activeChart;

        // Verify new annotations received system-generated IDs
        expect(activeChart.annotations.length, equals(3));

        // Original annotation ID should be preserved
        final originalAnnotation = activeChart.annotations.firstWhere(
          (a) => a.id == initialAnnotationId,
        );
        expect(originalAnnotation.label, equals('Initial Threshold'));

        // New annotations should have unique IDs
        final zoneAnnotation = activeChart.annotations.firstWhere(
          (a) => a.type == AnnotationType.zone,
        );
        expect(zoneAnnotation.id, isNotNull);
        expect(zoneAnnotation.id, isNot(equals(initialAnnotationId)));
        final zoneId = zoneAnnotation.id!;

        final markerAnnotation = activeChart.annotations.firstWhere(
          (a) => a.type == AnnotationType.marker,
        );
        expect(markerAnnotation.id, isNotNull);
        expect(markerAnnotation.id, isNot(equals(initialAnnotationId)));
        expect(markerAnnotation.id, isNot(equals(zoneId)));
        final markerId = markerAnnotation.id!;

        // --- STEP 4: UPDATE annotations by ID ---
        final updateAnnotationsResult = await modifyTool.execute({
          'modifications': {
            'update': {
              'annotations': [
                {
                  'id': initialAnnotationId,
                  'label': 'Updated Threshold',
                  'value': 60.0,
                },
                {
                  'id': zoneId,
                  'color': '#FFFF00', // Change to yellow
                },
              ],
            },
          },
        });

        expect(updateAnnotationsResult.isError, isFalse,
            reason: 'Update annotations failed');
        activeChart = getChartFromOutput(updateAnnotationsResult.data);
        chartRegistry[chartId] = activeChart;

        // Verify updates
        final updatedThreshold = activeChart.annotations.firstWhere(
          (a) => a.id == initialAnnotationId,
        );
        expect(updatedThreshold.label, equals('Updated Threshold'));
        expect(updatedThreshold.value, equals(60.0));

        final updatedZone = activeChart.annotations.firstWhere(
          (a) => a.id == zoneId,
        );
        expect(updatedZone.color, equals('#FFFF00'));
        expect(
            updatedZone.minValue, equals(20.0)); // Other properties preserved

        // Marker should be unchanged
        final unchangedMarker = activeChart.annotations.firstWhere(
          (a) => a.id == markerId,
        );
        expect(unchangedMarker.label, equals('Key Point'));

        // --- STEP 5: REMOVE annotations by ID ---
        final removeAnnotationsResult = await modifyTool.execute({
          'modifications': {
            'remove': {
              'annotations': [markerId],
            },
          },
        });

        expect(removeAnnotationsResult.isError, isFalse,
            reason: 'Remove annotations failed');
        activeChart = getChartFromOutput(removeAnnotationsResult.data);
        chartRegistry[chartId] = activeChart;

        // Verify removal
        expect(activeChart.annotations.length, equals(2));
        expect(
          activeChart.annotations.map((a) => a.id),
          containsAll([initialAnnotationId, zoneId]),
        );
        expect(
          activeChart.annotations.map((a) => a.id),
          isNot(contains(markerId)),
        );

        // Final verification - IDs persist through entire lifecycle
        expect(activeChart.id, equals(chartId));
        expect(
          activeChart.annotations
              .firstWhere((a) => a.id == initialAnnotationId)
              .label,
          equals('Updated Threshold'),
        );
      });

      test('annotation IDs are unique UUIDs', () async {
        // Create chart with multiple annotations
        final createTool = CreateChartTool();
        final createResult = await createTool.execute({
          'prompt': 'Multi-annotation chart',
          'series': [
            {
              'id': 's1',
              'data': [
                {'x': 0, 'y': 0}
              ],
            },
          ],
          'annotations': [
            {'type': 'referenceLine', 'orientation': 'vertical', 'value': 10.0},
            {'type': 'referenceLine', 'orientation': 'vertical', 'value': 20.0},
            {'type': 'referenceLine', 'orientation': 'vertical', 'value': 30.0},
          ],
        });

        expect(createResult.isError, isFalse);
        final chart = getChartFromOutput(createResult.data);

        // Collect all annotation IDs
        final annotationIds = chart.annotations.map((a) => a.id).toSet();

        // All IDs should be unique
        expect(annotationIds.length, equals(3));

        // All IDs should be non-empty UUIDs (have expected format)
        for (final annotation in chart.annotations) {
          expect(annotation.id, isNotNull);
          expect(
              annotation.id!.length, greaterThanOrEqualTo(32)); // UUID length
        }
      });
    });

    group('Series yAxis Configuration - Deep Merge', () {
      test('series yAxis properties persist through modify operations',
          () async {
        // --- STEP 1: CREATE chart with series having yAxis config ---
        final createTool = CreateChartTool();
        final createResult = await createTool.execute({
          'prompt': 'Chart for yAxis deep merge testing',
          'series': [
            {
              'id': 'powerSeries',
              'name': 'Power Output',
              'data': [
                {'x': 0, 'y': 100},
                {'x': 1, 'y': 200},
              ],
              'yAxis': {
                'id': 'powerAxis',
                'label': 'Power',
                'unit': 'W',
                'position': 'left',
                'min': 0.0,
                'max': 500.0,
                'color': '#FF5500',
              },
            },
          ],
        });

        expect(createResult.isError, isFalse, reason: 'Create chart failed');
        var activeChart = getChartFromOutput(createResult.data);
        final chartId = activeChart.id!;

        // Verify initial yAxis configuration
        final initialSeries =
            activeChart.series.firstWhere((s) => s.id == 'powerSeries');
        expect(initialSeries.yAxis, isNotNull);
        expect(initialSeries.yAxis!.label, equals('Power'));
        expect(initialSeries.yAxis!.unit, equals('W'));
        expect(initialSeries.yAxis!.position, equals(AxisPosition.left));
        expect(initialSeries.yAxis!.min, equals(0.0));
        expect(initialSeries.yAxis!.max, equals(500.0));
        expect(initialSeries.yAxis!.color, equals('#FF5500'));

        // Chart registry for GetChartTool
        final chartRegistry = <String, ChartConfiguration>{
          chartId: activeChart
        };

        // --- STEP 2: MODIFY series - only update label (other properties should be preserved via deep merge) ---
        final modifyTool =
            ModifyChartTool(getActiveChart: () => chartRegistry[chartId]);

        final updateResult = await modifyTool.execute({
          'modifications': {
            'update': {
              'series': [
                {
                  'id': 'powerSeries',
                  'yAxis': {
                    'label': 'Power Output (Updated)',
                    // NOT specifying: unit, position, min, max, color
                    // These should be preserved via deep merge
                  },
                },
              ],
            },
          },
        });

        expect(updateResult.isError, isFalse,
            reason: 'Update series yAxis failed');
        activeChart = getChartFromOutput(updateResult.data);
        chartRegistry[chartId] = activeChart;

        // Verify deep merge preserved unspecified properties
        final updatedSeries =
            activeChart.series.firstWhere((s) => s.id == 'powerSeries');
        expect(updatedSeries.yAxis, isNotNull);

        // Updated property
        expect(
          updatedSeries.yAxis!.label,
          equals('Power Output (Updated)'),
          reason: 'Label should be updated',
        );

        // Preserved properties via deep merge
        expect(
          updatedSeries.yAxis!.unit,
          equals('W'),
          reason: 'Deep merge should preserve unit',
        );
        expect(
          updatedSeries.yAxis!.position,
          equals(AxisPosition.left),
          reason: 'Deep merge should preserve position',
        );
        expect(
          updatedSeries.yAxis!.min,
          equals(0.0),
          reason: 'Deep merge should preserve min',
        );
        expect(
          updatedSeries.yAxis!.max,
          equals(500.0),
          reason: 'Deep merge should preserve max',
        );
        expect(
          updatedSeries.yAxis!.color,
          equals('#FF5500'),
          reason: 'Deep merge should preserve color',
        );

        // --- STEP 3: MODIFY again - update different properties ---
        final updateResult2 = await modifyTool.execute({
          'modifications': {
            'update': {
              'series': [
                {
                  'id': 'powerSeries',
                  'yAxis': {
                    'max': 1000.0, // Update max
                    'color': '#00FF00', // Update color
                    // NOT specifying: label, unit, position, min
                  },
                },
              ],
            },
          },
        });

        expect(updateResult2.isError, isFalse, reason: 'Second update failed');
        activeChart = getChartFromOutput(updateResult2.data);

        final finalSeries =
            activeChart.series.firstWhere((s) => s.id == 'powerSeries');

        // Updated properties
        expect(finalSeries.yAxis!.max, equals(1000.0));
        expect(finalSeries.yAxis!.color, equals('#00FF00'));

        // Still preserved from previous state
        expect(finalSeries.yAxis!.label, equals('Power Output (Updated)'));
        expect(finalSeries.yAxis!.unit, equals('W'));
        expect(finalSeries.yAxis!.position, equals(AxisPosition.left));
        expect(finalSeries.yAxis!.min, equals(0.0));
      });

      test('deep merge works across multiple series', () async {
        final createTool = CreateChartTool();
        final createResult = await createTool.execute({
          'prompt': 'Multi-series chart for deep merge',
          'series': [
            {
              'id': 'seriesA',
              'data': [
                {'x': 0, 'y': 10}
              ],
              'yAxis': {
                'label': 'Series A Axis',
                'unit': 'kg',
                'min': 0.0,
                'max': 100.0,
              },
            },
            {
              'id': 'seriesB',
              'data': [
                {'x': 0, 'y': 20}
              ],
              'yAxis': {
                'label': 'Series B Axis',
                'unit': 'km',
                'min': 0.0,
                'max': 200.0,
              },
            },
          ],
        });

        expect(createResult.isError, isFalse);
        var activeChart = getChartFromOutput(createResult.data);

        final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);

        // Update both series with partial yAxis updates
        final updateResult = await modifyTool.execute({
          'modifications': {
            'update': {
              'series': [
                {
                  'id': 'seriesA',
                  'yAxis': {'label': 'Updated A'}, // Only label
                },
                {
                  'id': 'seriesB',
                  'yAxis': {'max': 300.0}, // Only max
                },
              ],
            },
          },
        });

        expect(updateResult.isError, isFalse);
        activeChart = getChartFromOutput(updateResult.data);

        // Verify seriesA
        final seriesA = activeChart.series.firstWhere((s) => s.id == 'seriesA');
        expect(seriesA.yAxis!.label, equals('Updated A'));
        expect(seriesA.yAxis!.unit, equals('kg')); // Preserved
        expect(seriesA.yAxis!.max, equals(100.0)); // Preserved

        // Verify seriesB
        final seriesB = activeChart.series.firstWhere((s) => s.id == 'seriesB');
        expect(seriesB.yAxis!.label, equals('Series B Axis')); // Preserved
        expect(seriesB.yAxis!.unit, equals('km')); // Preserved
        expect(seriesB.yAxis!.max, equals(300.0)); // Updated
      });
    });

    group('Error Handling', () {
      test('GetChartTool returns error for non-existent chart', () async {
        final getTool = GetChartTool(getChartById: (id) => null);

        final result = await getTool.execute({
          'chartId': 'non-existent-id',
        });

        expect(result.isError, isTrue);
        expect(result.output, contains('not found'));
      });

      test('ModifyChartTool returns error when no active chart', () async {
        final modifyTool = ModifyChartTool(getActiveChart: () => null);

        final result = await modifyTool.execute({
          'modifications': {'title': 'New Title'},
        });

        expect(result.isError, isTrue);
        expect(result.output, contains('No active chart'));
      });

      test('CreateChartTool validates required fields', () async {
        final createTool = CreateChartTool();

        // Missing series
        final noSeriesResult = await createTool.execute({
          'prompt': 'Chart without series',
        });

        expect(noSeriesResult.isError, isTrue);
        expect(noSeriesResult.output, contains('series'));

        // Missing prompt
        final noPromptResult = await createTool.execute({
          'series': [
            {
              'id': 's1',
              'data': [
                {'x': 0, 'y': 0}
              ]
            },
          ],
        });

        expect(noPromptResult.isError, isTrue);
        expect(noPromptResult.output, contains('prompt'));
      });
    });
  });
}
