// Property Wiring Tests for Agentic Charts
//
// BIDIRECTIONAL COVERAGE AUDIT:
// 1. Schema Coverage: Does CreateChartTool.inputSchema expose each BravenChartPlus property?
// 2. Renderer Wiring: Does ChartRenderer wire each property back to BravenChartPlus?
//
// PROPERTY COUNTS (from actual BravenChartPlus API):
// - BravenChartPlus widget: 36 constructor parameters
// - LineChartSeries: 12 properties (5 line-specific + 7 base)
// - AreaChartSeries: 13 properties (6 area-specific + 7 base)
// - ScatterChartSeries: 8 properties (1 scatter-specific + 7 base)
// - BarChartSeries: 11 properties (4 bar-specific + 7 base)
// - YAxisConfig: 18 properties
// - XAxisConfig: 14 properties
// - GridConfig: 6 properties
// - LegendStyle: 15 properties
// - InteractionConfig: 20+ properties (nested)
//
// Most of these will FAIL initially - that's TDD.
// As we fix the wiring, tests turn green.

import 'package:braven_agent/src/models/annotation_config.dart' as models;
import 'package:braven_agent/src/models/chart_configuration.dart' as models;
import 'package:braven_agent/src/models/data_point.dart' as models;
import 'package:braven_agent/src/models/enums.dart' as models;
import 'package:braven_agent/src/models/series_config.dart' as models;
import 'package:braven_agent/src/models/x_axis_config.dart' as models;
import 'package:braven_agent/src/renderer/chart_renderer.dart';
import 'package:braven_agent/src/tools/create_chart_tool.dart';
import 'package:braven_agent/src/tools/modify_chart_tool.dart';
import 'package:braven_charts/braven_charts.dart' hide CreateChartTool, ModifyChartTool;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ============================================================================
  // PART 1: SCHEMA COVERAGE TESTS
  // Tests that CreateChartTool.inputSchema exposes BravenChartPlus properties
  // ============================================================================

  group('Schema Coverage - Series Properties', () {
    late CreateChartTool tool;
    late Map<String, dynamic> seriesProperties;

    setUp(() {
      tool = CreateChartTool();
      final schema = tool.inputSchema;
      final seriesItems = (schema['properties']['series']['items']) as Map<String, dynamic>;
      seriesProperties = seriesItems['properties'] as Map<String, dynamic>;
    });

    // === Base ChartSeries properties (7) ===
    test('schema: series.id', () {
      expect(seriesProperties.containsKey('id'), isTrue);
    });

    test('schema: series.name', () {
      expect(seriesProperties.containsKey('name'), isTrue);
    });

    test('schema: series.data (points)', () {
      expect(seriesProperties.containsKey('data'), isTrue);
    });

    test('schema: series.color', () {
      expect(seriesProperties.containsKey('color'), isTrue);
    });

    test('schema: series.yAxisId', () {
      expect(seriesProperties.containsKey('yAxisId'), isTrue, reason: 'MISSING: yAxisId not in schema');
    });

    test('schema: series.unit', () {
      expect(seriesProperties.containsKey('unit'), isTrue, reason: 'MISSING: unit not in schema');
    });

    // === LineChartSeries specific (5) ===
    test('schema: series.interpolation', () {
      expect(seriesProperties.containsKey('interpolation'), isTrue, reason: 'MISSING: interpolation not in schema');
    });

    test('schema: series.strokeWidth', () {
      expect(seriesProperties.containsKey('strokeWidth'), isTrue, reason: 'MISSING: strokeWidth not in schema');
    });

    test('schema: series.tension', () {
      expect(seriesProperties.containsKey('tension'), isTrue, reason: 'MISSING: tension not in schema');
    });

    test('schema: series.showDataPointMarkers (showPoints)', () {
      expect(seriesProperties.containsKey('showPoints'), isTrue, reason: 'MISSING: showPoints not in schema');
    });

    // NOTE: dataPointMarkerRadius and markerRadius were REMOVED from schema
    // to avoid LLM confusion. markerSize is the single canonical property
    // that works for all chart types (line, area, scatter).

    // === AreaChartSeries specific (1 additional) ===
    test('schema: series.fillOpacity', () {
      expect(seriesProperties.containsKey('fillOpacity'), isTrue, reason: 'MISSING: fillOpacity not in schema');
    });

    // === BarChartSeries specific (4) ===
    test('schema: series.barWidthPercent', () {
      expect(seriesProperties.containsKey('barWidthPercent'), isTrue, reason: 'MISSING: barWidthPercent not in schema');
    });

    test('schema: series.barWidthPixels', () {
      expect(seriesProperties.containsKey('barWidthPixels'), isTrue, reason: 'MISSING: barWidthPixels not in schema');
    });

    test('schema: series.barMinWidth', () {
      expect(seriesProperties.containsKey('barMinWidth'), isTrue, reason: 'MISSING: barMinWidth not in schema');
    });

    test('schema: series.barMaxWidth', () {
      expect(seriesProperties.containsKey('barMaxWidth'), isTrue, reason: 'MISSING: barMaxWidth not in schema');
    });

    // === Per-series Y-axis config (6) ===
    test('schema: series.yAxisPosition', () {
      expect(seriesProperties.containsKey('yAxisPosition'), isTrue, reason: 'MISSING: yAxisPosition not in schema');
    });

    test('schema: series.yAxisLabel', () {
      expect(seriesProperties.containsKey('yAxisLabel'), isTrue, reason: 'MISSING: yAxisLabel not in schema');
    });

    test('schema: series.yAxisUnit', () {
      expect(seriesProperties.containsKey('yAxisUnit'), isTrue, reason: 'MISSING: yAxisUnit not in schema');
    });

    test('schema: series.yAxisColor', () {
      expect(seriesProperties.containsKey('yAxisColor'), isTrue, reason: 'MISSING: yAxisColor not in schema');
    });

    test('schema: series.yAxisMin', () {
      expect(seriesProperties.containsKey('yAxisMin'), isTrue, reason: 'MISSING: yAxisMin not in schema');
    });

    test('schema: series.yAxisMax', () {
      expect(seriesProperties.containsKey('yAxisMax'), isTrue, reason: 'MISSING: yAxisMax not in schema');
    });
  });

  group('Schema Coverage - Chart-Level Properties', () {
    late Map<String, dynamic> properties;

    setUp(() {
      final tool = CreateChartTool();
      properties = tool.inputSchema['properties'] as Map<String, dynamic>;
    });

    // === BravenChartPlus widget properties ===
    test('schema: title', () {
      expect(properties.containsKey('title'), isTrue, reason: 'MISSING: title not in schema');
    });

    test('schema: subtitle', () {
      expect(properties.containsKey('subtitle'), isTrue, reason: 'MISSING: subtitle not in schema');
    });

    test('schema: width', () {
      expect(properties.containsKey('width'), isTrue, reason: 'MISSING: width not in schema');
    });

    test('schema: height', () {
      expect(properties.containsKey('height'), isTrue, reason: 'MISSING: height not in schema');
    });

    test('schema: backgroundColor', () {
      expect(properties.containsKey('backgroundColor'), isTrue, reason: 'MISSING: backgroundColor not in schema');
    });

    test('schema: showGrid', () {
      expect(properties.containsKey('showGrid'), isTrue);
    });

    test('schema: showLegend', () {
      expect(properties.containsKey('showLegend'), isTrue);
    });

    test('schema: legendPosition', () {
      expect(properties.containsKey('legendPosition'), isTrue);
    });

    test('schema: normalizationMode', () {
      expect(properties.containsKey('normalizationMode'), isTrue);
    });

    test('schema: useDarkTheme', () {
      expect(properties.containsKey('useDarkTheme'), isTrue);
    });

    test('schema: showScrollbar (showXScrollbar)', () {
      expect(properties.containsKey('showScrollbar'), isTrue, reason: 'MISSING: showScrollbar not in schema');
    });

    test('schema: showYScrollbar', () {
      expect(properties.containsKey('showYScrollbar'), isTrue, reason: 'MISSING: showYScrollbar not in schema');
    });
  });

  group('Schema Coverage - X-Axis Properties', () {
    late Map<String, dynamic> properties;
    Map<String, dynamic>? xAxisProps;

    setUp(() {
      final tool = CreateChartTool();
      properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      if (properties.containsKey('xAxis')) {
        final xAxisSchema = properties['xAxis'] as Map<dynamic, dynamic>?;
        final nestedProps = xAxisSchema?['properties'];
        if (nestedProps != null) {
          xAxisProps = Map<String, dynamic>.from(nestedProps as Map);
        }
      }
    });

    test('schema: xAxis object exists', () {
      expect(properties.containsKey('xAxis'), isTrue, reason: 'MISSING: xAxis object not in schema');
    });

    test('schema: xAxis.label', () {
      expect(xAxisProps?.containsKey('label') ?? false, isTrue, reason: 'MISSING: xAxis.label not in schema');
    });

    test('schema: xAxis.unit', () {
      expect(xAxisProps?.containsKey('unit') ?? false, isTrue, reason: 'MISSING: xAxis.unit not in schema');
    });

    test('schema: xAxis.min', () {
      expect(xAxisProps?.containsKey('min') ?? false, isTrue, reason: 'MISSING: xAxis.min not in schema');
    });

    test('schema: xAxis.max', () {
      expect(xAxisProps?.containsKey('max') ?? false, isTrue, reason: 'MISSING: xAxis.max not in schema');
    });

    test('schema: xAxis.visible', () {
      expect(xAxisProps?.containsKey('visible') ?? false, isTrue, reason: 'MISSING: xAxis.visible not in schema');
    });

    test('schema: xAxis.showAxisLine', () {
      expect(xAxisProps?.containsKey('showAxisLine') ?? false, isTrue, reason: 'MISSING: xAxis.showAxisLine not in schema');
    });

    test('schema: xAxis.showTicks', () {
      expect(xAxisProps?.containsKey('showTicks') ?? false, isTrue, reason: 'MISSING: xAxis.showTicks not in schema');
    });

    test('schema: xAxis.tickCount', () {
      expect(xAxisProps?.containsKey('tickCount') ?? false, isTrue, reason: 'MISSING: xAxis.tickCount not in schema');
    });
  });

  group('Schema Coverage - Enum Values', () {
    late Map<String, dynamic> seriesProperties;
    late Map<String, dynamic> properties;

    setUp(() {
      final tool = CreateChartTool();
      final schema = tool.inputSchema;
      properties = schema['properties'] as Map<String, dynamic>;
      final seriesItems = (schema['properties']['series']['items']) as Map<String, dynamic>;
      seriesProperties = seriesItems['properties'] as Map<String, dynamic>;
    });

    // === LineInterpolation enum (4 values) ===
    test('schema: interpolation.linear', () {
      final interpolationProp = seriesProperties['interpolation'];
      expect(interpolationProp, isNotNull, reason: 'MISSING: interpolation property not in schema');
      if (interpolationProp == null) return;
      final enumValues = interpolationProp['enum'] as List?;
      expect(enumValues?.contains('linear') ?? false, isTrue);
    });

    test('schema: interpolation.bezier', () {
      final interpolationProp = seriesProperties['interpolation'];
      expect(interpolationProp, isNotNull, reason: 'MISSING: interpolation property not in schema');
      if (interpolationProp == null) return;
      final enumValues = interpolationProp['enum'] as List?;
      expect(enumValues?.contains('bezier') ?? false, isTrue);
    });

    test('schema: interpolation.stepped', () {
      final interpolationProp = seriesProperties['interpolation'];
      expect(interpolationProp, isNotNull, reason: 'MISSING: interpolation property not in schema');
      if (interpolationProp == null) return;
      final enumValues = interpolationProp['enum'] as List?;
      expect(enumValues?.contains('stepped') ?? false, isTrue);
    });

    test('schema: interpolation.monotone', () {
      final interpolationProp = seriesProperties['interpolation'];
      expect(interpolationProp, isNotNull, reason: 'MISSING: interpolation property not in schema');
      if (interpolationProp == null) return;
      final enumValues = interpolationProp['enum'] as List?;
      expect(enumValues?.contains('monotone') ?? false, isTrue, reason: 'MISSING: monotone not in interpolation enum');
    });

    // === YAxisPosition enum (4 values) ===
    test('schema: yAxisPosition.left', () {
      final yAxisPositionProp = seriesProperties['yAxisPosition'];
      expect(yAxisPositionProp, isNotNull, reason: 'MISSING: yAxisPosition property not in schema');
      if (yAxisPositionProp == null) return;
      final enumValues = yAxisPositionProp['enum'] as List?;
      expect(enumValues?.contains('left') ?? false, isTrue);
    });

    test('schema: yAxisPosition.right', () {
      final yAxisPositionProp = seriesProperties['yAxisPosition'];
      expect(yAxisPositionProp, isNotNull, reason: 'MISSING: yAxisPosition property not in schema');
      if (yAxisPositionProp == null) return;
      final enumValues = yAxisPositionProp['enum'] as List?;
      expect(enumValues?.contains('right') ?? false, isTrue);
    });

    test('schema: yAxisPosition.leftOuter', () {
      final yAxisPositionProp = seriesProperties['yAxisPosition'];
      expect(yAxisPositionProp, isNotNull, reason: 'MISSING: yAxisPosition property not in schema');
      if (yAxisPositionProp == null) return;
      final enumValues = yAxisPositionProp['enum'] as List?;
      expect(enumValues?.contains('leftOuter') ?? false, isTrue, reason: 'MISSING: leftOuter not in yAxisPosition enum');
    });

    test('schema: yAxisPosition.rightOuter', () {
      final yAxisPositionProp = seriesProperties['yAxisPosition'];
      expect(yAxisPositionProp, isNotNull, reason: 'MISSING: yAxisPosition property not in schema');
      if (yAxisPositionProp == null) return;
      final enumValues = yAxisPositionProp['enum'] as List?;
      expect(enumValues?.contains('rightOuter') ?? false, isTrue, reason: 'MISSING: rightOuter not in yAxisPosition enum');
    });

    // === LegendPosition enum (9 values in BravenChartPlus) ===
    test('schema: legendPosition.top', () {
      final enumValues = properties['legendPosition']['enum'] as List;
      expect(enumValues.contains('top') || enumValues.contains('topCenter'), isTrue);
    });

    test('schema: legendPosition.topLeft', () {
      final enumValues = properties['legendPosition']['enum'] as List;
      expect(enumValues.contains('topLeft'), isTrue, reason: 'MISSING: topLeft not in legendPosition enum');
    });

    test('schema: legendPosition.topRight', () {
      final enumValues = properties['legendPosition']['enum'] as List;
      expect(enumValues.contains('topRight'), isTrue, reason: 'MISSING: topRight not in legendPosition enum');
    });

    test('schema: legendPosition.bottom', () {
      final enumValues = properties['legendPosition']['enum'] as List;
      expect(enumValues.contains('bottom') || enumValues.contains('bottomCenter'), isTrue);
    });

    test('schema: legendPosition.bottomLeft', () {
      final enumValues = properties['legendPosition']['enum'] as List;
      expect(enumValues.contains('bottomLeft'), isTrue, reason: 'MISSING: bottomLeft not in legendPosition enum');
    });

    test('schema: legendPosition.bottomRight', () {
      final enumValues = properties['legendPosition']['enum'] as List;
      expect(enumValues.contains('bottomRight'), isTrue, reason: 'MISSING: bottomRight not in legendPosition enum');
    });

    // === NormalizationMode enum (3 values) ===
    test('schema: normalizationMode.none', () {
      final enumValues = properties['normalizationMode']['enum'] as List;
      expect(enumValues.contains('none'), isTrue);
    });

    test('schema: normalizationMode.perSeries', () {
      final enumValues = properties['normalizationMode']['enum'] as List;
      expect(enumValues.contains('perSeries'), isTrue);
    });

    test('schema: normalizationMode.auto', () {
      final enumValues = properties['normalizationMode']['enum'] as List;
      expect(enumValues.contains('auto'), isTrue);
    });
  });

  group('Schema Coverage - Interaction Properties', () {
    late Map<String, dynamic> properties;
    Map<String, dynamic>? interactionsProps;

    setUp(() {
      final tool = CreateChartTool();
      properties = tool.inputSchema['properties'] as Map<String, dynamic>;
      if (properties.containsKey('interactions')) {
        final interactionsSchema = properties['interactions'] as Map<dynamic, dynamic>?;
        final nestedProps = interactionsSchema?['properties'];
        if (nestedProps != null) {
          interactionsProps = Map<String, dynamic>.from(nestedProps as Map);
        }
      }
    });

    test('schema: interactions object exists', () {
      expect(properties.containsKey('interactions'), isTrue, reason: 'MISSING: interactions object not in schema');
    });

    test('schema: interactions.crosshairMode', () {
      expect(interactionsProps?.containsKey('crosshairMode') ?? false, isTrue, reason: 'MISSING: crosshairMode not in interactions schema');
    });

    test('schema: interactions.tooltipPosition', () {
      expect(interactionsProps?.containsKey('tooltipPosition') ?? false, isTrue, reason: 'MISSING: tooltipPosition not in interactions schema');
    });

    test('schema: interactions.enableZoom', () {
      expect(interactionsProps?.containsKey('enableZoom') ?? false, isTrue, reason: 'MISSING: enableZoom not in interactions schema');
    });

    test('schema: interactions.enablePan', () {
      expect(interactionsProps?.containsKey('enablePan') ?? false, isTrue, reason: 'MISSING: enablePan not in interactions schema');
    });
  });

  // ============================================================================
  // PART 1B: MODIFYCHARTOOL SCHEMA COVERAGE TESTS
  // Tests that ModifyChartTool.inputSchema exposes same series properties as CreateChartTool
  // ============================================================================

  group('ModifyChartTool Schema Coverage - addSeries Properties', () {
    late Map<String, dynamic> addSeriesProperties;

    setUp(() {
      final tool = ModifyChartTool(getActiveChart: () => null);
      final schema = tool.inputSchema;
      final modifications = schema['properties']['modifications'] as Map<String, dynamic>;
      final modProps = modifications['properties'] as Map<String, dynamic>;
      final addSeriesItems = (modProps['addSeries']['items']) as Map<String, dynamic>;
      addSeriesProperties = addSeriesItems['properties'] as Map<String, dynamic>;
    });

    // === Base ChartSeries properties ===
    test('addSeries schema: id', () {
      expect(addSeriesProperties.containsKey('id'), isTrue);
    });

    test('addSeries schema: name', () {
      expect(addSeriesProperties.containsKey('name'), isTrue);
    });

    test('addSeries schema: data', () {
      expect(addSeriesProperties.containsKey('data'), isTrue);
    });

    test('addSeries schema: color', () {
      expect(addSeriesProperties.containsKey('color'), isTrue);
    });

    test('addSeries schema: yAxisId', () {
      expect(addSeriesProperties.containsKey('yAxisId'), isTrue, reason: 'MISSING: yAxisId not in addSeries schema');
    });

    test('addSeries schema: unit', () {
      expect(addSeriesProperties.containsKey('unit'), isTrue, reason: 'MISSING: unit not in addSeries schema');
    });

    // === LineChartSeries specific ===
    test('addSeries schema: interpolation', () {
      expect(addSeriesProperties.containsKey('interpolation'), isTrue, reason: 'MISSING: interpolation not in addSeries schema');
    });

    test('addSeries schema: strokeWidth', () {
      expect(addSeriesProperties.containsKey('strokeWidth'), isTrue, reason: 'MISSING: strokeWidth not in addSeries schema');
    });

    test('addSeries schema: tension', () {
      expect(addSeriesProperties.containsKey('tension'), isTrue, reason: 'MISSING: tension not in addSeries schema');
    });

    test('addSeries schema: showPoints', () {
      expect(addSeriesProperties.containsKey('showPoints'), isTrue, reason: 'MISSING: showPoints not in addSeries schema');
    });

    test('addSeries schema: markerStyle', () {
      expect(addSeriesProperties.containsKey('markerStyle'), isTrue, reason: 'MISSING: markerStyle not in addSeries schema');
    });

    test('addSeries schema: markerSize', () {
      expect(addSeriesProperties.containsKey('markerSize'), isTrue, reason: 'MISSING: markerSize not in addSeries schema');
    });

    // === AreaChartSeries specific ===
    test('addSeries schema: fillOpacity', () {
      expect(addSeriesProperties.containsKey('fillOpacity'), isTrue, reason: 'MISSING: fillOpacity not in addSeries schema');
    });

    // === BarChartSeries specific ===
    test('addSeries schema: barWidthPercent', () {
      expect(addSeriesProperties.containsKey('barWidthPercent'), isTrue, reason: 'MISSING: barWidthPercent not in addSeries schema');
    });

    test('addSeries schema: barWidthPixels', () {
      expect(addSeriesProperties.containsKey('barWidthPixels'), isTrue, reason: 'MISSING: barWidthPixels not in addSeries schema');
    });

    test('addSeries schema: barMinWidth', () {
      expect(addSeriesProperties.containsKey('barMinWidth'), isTrue, reason: 'MISSING: barMinWidth not in addSeries schema');
    });

    test('addSeries schema: barMaxWidth', () {
      expect(addSeriesProperties.containsKey('barMaxWidth'), isTrue, reason: 'MISSING: barMaxWidth not in addSeries schema');
    });

    // === Per-series Y-axis config ===
    test('addSeries schema: yAxisPosition', () {
      expect(addSeriesProperties.containsKey('yAxisPosition'), isTrue, reason: 'MISSING: yAxisPosition not in addSeries schema');
    });

    test('addSeries schema: yAxisLabel', () {
      expect(addSeriesProperties.containsKey('yAxisLabel'), isTrue, reason: 'MISSING: yAxisLabel not in addSeries schema');
    });

    test('addSeries schema: yAxisUnit', () {
      expect(addSeriesProperties.containsKey('yAxisUnit'), isTrue, reason: 'MISSING: yAxisUnit not in addSeries schema');
    });

    test('addSeries schema: yAxisColor', () {
      expect(addSeriesProperties.containsKey('yAxisColor'), isTrue, reason: 'MISSING: yAxisColor not in addSeries schema');
    });

    test('addSeries schema: yAxisMin', () {
      expect(addSeriesProperties.containsKey('yAxisMin'), isTrue, reason: 'MISSING: yAxisMin not in addSeries schema');
    });

    test('addSeries schema: yAxisMax', () {
      expect(addSeriesProperties.containsKey('yAxisMax'), isTrue, reason: 'MISSING: yAxisMax not in addSeries schema');
    });

    // === Visibility ===
    test('addSeries schema: visible', () {
      expect(addSeriesProperties.containsKey('visible'), isTrue, reason: 'MISSING: visible not in addSeries schema');
    });

    test('addSeries schema: legendVisible', () {
      expect(addSeriesProperties.containsKey('legendVisible'), isTrue, reason: 'MISSING: legendVisible not in addSeries schema');
    });
  });

  group('ModifyChartTool Schema Coverage - updateSeries Properties', () {
    late Map<String, dynamic> updateSeriesProps;

    setUp(() {
      final tool = ModifyChartTool(getActiveChart: () => null);
      final schema = tool.inputSchema;
      final modifications = schema['properties']['modifications'] as Map<String, dynamic>;
      final modProps = modifications['properties'] as Map<String, dynamic>;
      final updateSeriesSchema = modProps['updateSeries'] as Map<String, dynamic>;
      updateSeriesProps = (updateSeriesSchema['additionalProperties']['properties']) as Map<String, dynamic>;
    });

    test('updateSeries schema: name', () {
      expect(updateSeriesProps.containsKey('name'), isTrue);
    });

    test('updateSeries schema: color', () {
      expect(updateSeriesProps.containsKey('color'), isTrue);
    });

    test('updateSeries schema: data', () {
      expect(updateSeriesProps.containsKey('data'), isTrue);
    });

    test('updateSeries schema: strokeWidth', () {
      expect(updateSeriesProps.containsKey('strokeWidth'), isTrue, reason: 'MISSING: strokeWidth not in updateSeries schema');
    });

    test('updateSeries schema: fillOpacity', () {
      expect(updateSeriesProps.containsKey('fillOpacity'), isTrue, reason: 'MISSING: fillOpacity not in updateSeries schema');
    });

    test('updateSeries schema: tension', () {
      expect(updateSeriesProps.containsKey('tension'), isTrue, reason: 'MISSING: tension not in updateSeries schema');
    });

    test('updateSeries schema: showPoints', () {
      expect(updateSeriesProps.containsKey('showPoints'), isTrue, reason: 'MISSING: showPoints not in updateSeries schema');
    });

    test('updateSeries schema: interpolation', () {
      expect(updateSeriesProps.containsKey('interpolation'), isTrue, reason: 'MISSING: interpolation not in updateSeries schema');
    });

    test('updateSeries schema: markerStyle', () {
      expect(updateSeriesProps.containsKey('markerStyle'), isTrue, reason: 'MISSING: markerStyle not in updateSeries schema');
    });

    test('updateSeries schema: markerSize', () {
      expect(updateSeriesProps.containsKey('markerSize'), isTrue, reason: 'MISSING: markerSize not in updateSeries schema');
    });

    test('updateSeries schema: yAxisId', () {
      expect(updateSeriesProps.containsKey('yAxisId'), isTrue, reason: 'MISSING: yAxisId not in updateSeries schema');
    });

    test('updateSeries schema: unit', () {
      expect(updateSeriesProps.containsKey('unit'), isTrue, reason: 'MISSING: unit not in updateSeries schema');
    });

    test('updateSeries schema: visible', () {
      expect(updateSeriesProps.containsKey('visible'), isTrue, reason: 'MISSING: visible not in updateSeries schema');
    });

    test('updateSeries schema: legendVisible', () {
      expect(updateSeriesProps.containsKey('legendVisible'), isTrue, reason: 'MISSING: legendVisible not in updateSeries schema');
    });
  });

  group('ModifyChartTool Schema Parity with CreateChartTool', () {
    late Map<String, dynamic> createSeriesProps;
    late Map<String, dynamic> modifyAddSeriesProps;

    setUp(() {
      // Get CreateChartTool series properties
      final createTool = CreateChartTool();
      final createSchema = createTool.inputSchema;
      final createSeriesItems = (createSchema['properties']['series']['items']) as Map<String, dynamic>;
      createSeriesProps = createSeriesItems['properties'] as Map<String, dynamic>;

      // Get ModifyChartTool addSeries properties
      final modifyTool = ModifyChartTool(getActiveChart: () => null);
      final modifySchema = modifyTool.inputSchema;
      final modifications = modifySchema['properties']['modifications'] as Map<String, dynamic>;
      final modProps = modifications['properties'] as Map<String, dynamic>;
      final addSeriesItems = (modProps['addSeries']['items']) as Map<String, dynamic>;
      modifyAddSeriesProps = addSeriesItems['properties'] as Map<String, dynamic>;
    });

    test('ModifyChartTool.addSeries has all CreateChartTool series properties', () {
      // Check that all properties in CreateChartTool's series schema
      // are also present in ModifyChartTool's addSeries schema
      for (final prop in createSeriesProps.keys) {
        expect(
          modifyAddSeriesProps.containsKey(prop),
          isTrue,
          reason: 'ModifyChartTool.addSeries missing property: $prop',
        );
      }
    });

    test('property count parity check', () {
      // ModifyChartTool should have at least as many series properties as CreateChartTool
      expect(
        modifyAddSeriesProps.length >= createSeriesProps.length,
        isTrue,
        reason: 'ModifyChartTool.addSeries has ${modifyAddSeriesProps.length} props, '
            'CreateChartTool.series has ${createSeriesProps.length} props',
      );
    });
  });

  // ============================================================================
  // PART 2: RENDERER WIRING TESTS
  // Tests that ChartRenderer wires properties back to BravenChartPlus
  // ============================================================================

  group('Renderer Wiring - LineChartSeries', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    LineChartSeries? extractLineSeriesFromWidget(Widget widget) {
      if (widget is SizedBox && widget.child is BravenChartPlus) {
        final chart = widget.child as BravenChartPlus;
        if (chart.series.isNotEmpty && chart.series.first is LineChartSeries) {
          return chart.series.first as LineChartSeries;
        }
      }
      return null;
    }

    test('wiring: color → LineChartSeries.color', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            color: '#FF0000',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.color, equals(const Color(0xFFFF0000)));
    });

    test('wiring: interpolation → LineChartSeries.interpolation', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            interpolation: models.Interpolation.bezier,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.interpolation, equals(LineInterpolation.bezier));
    });

    test('wiring: strokeWidth → LineChartSeries.strokeWidth', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            strokeWidth: 4.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.strokeWidth, equals(4.0));
    });

    test('wiring: tension → LineChartSeries.tension', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            tension: 0.8,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.tension, equals(0.8));
    });

    test('wiring: showPoints → LineChartSeries.showDataPointMarkers', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            showPoints: true,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.showDataPointMarkers, isTrue);
    });

    test('wiring: dataPointMarkerRadius → LineChartSeries.dataPointMarkerRadius', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            markerSize: 6.0, // Using markerSize which maps to dataPointMarkerRadius
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.dataPointMarkerRadius, equals(6.0), reason: 'MISSING: dataPointMarkerRadius not wired');
    });

    // CRITICAL: This tests the actual LLM use case - markerSize is what Claude sends
    test('wiring: markerSize → LineChartSeries.dataPointMarkerRadius (LLM fallback)', () {
      // This is the REAL user flow: LLM sends markerSize, not dataPointMarkerRadius
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            markerSize: 8.0, // What the LLM actually sends
            showPoints: true,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.dataPointMarkerRadius, equals(8.0),
          reason: 'CRITICAL: markerSize must fall back to dataPointMarkerRadius for line charts. '
              'The LLM sends markerSize, not dataPointMarkerRadius!');
    });

    // CRITICAL: markerSize should implicitly enable showDataPointMarkers
    test('wiring: markerSize implicitly enables showDataPointMarkers', () {
      // LLM sets markerSize but NOT showPoints - markers should still appear
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            markerSize: 8.0, // Non-default size should implicitly enable markers
            // showPoints NOT set - but markers should still show
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.showDataPointMarkers, isTrue,
          reason: 'CRITICAL: Setting markerSize to non-default should implicitly enable showDataPointMarkers. '
              'This ensures LLM setting markerSize sees markers without needing showPoints: true.');
    });

    test('wiring: unit → LineChartSeries.unit', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            unit: 'bpm',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.unit, equals('bpm'), reason: 'MISSING: unit not wired');
    });

    test('wiring: yAxisPosition → LineChartSeries.yAxisConfig.position', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'right',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.position, equals(YAxisPosition.right));
    });

    test('wiring: yAxisPosition=leftOuter → YAxisPosition.leftOuter', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'leftOuter',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.position, equals(YAxisPosition.leftOuter), reason: 'MISSING: leftOuter not supported in yAxisPosition mapping');
    });

    test('wiring: yAxisPosition=rightOuter → YAxisPosition.rightOuter', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'rightOuter',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.position, equals(YAxisPosition.rightOuter), reason: 'MISSING: rightOuter not supported in yAxisPosition mapping');
    });

    test('wiring: yAxisLabel → LineChartSeries.yAxisConfig.label', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'left',
            yAxisLabel: 'Power',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.label, equals('Power'));
    });

    test('wiring: yAxisUnit → LineChartSeries.yAxisConfig.unit', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'left',
            yAxisUnit: 'W',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.unit, equals('W'));
    });

    test('wiring: yAxisColor → LineChartSeries.yAxisConfig.color', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'left',
            yAxisColor: '#00FF00',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.color, equals(const Color(0xFF00FF00)), reason: 'MISSING: yAxisColor not wired');
    });

    test('wiring: yAxisMin → LineChartSeries.yAxisConfig.min', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'left',
            yAxisMin: 0.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.min, equals(0.0), reason: 'MISSING: yAxisMin not wired');
    });

    test('wiring: yAxisMax → LineChartSeries.yAxisConfig.max', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisPosition: 'left',
            yAxisMax: 100.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisConfig?.max, equals(100.0), reason: 'MISSING: yAxisMax not wired');
    });

    test('wiring: yAxisId → LineChartSeries.yAxisId', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisId: 'shared-axis',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractLineSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisId, equals('shared-axis'), reason: 'MISSING: yAxisId not wired to series');
    });
  });

  group('Renderer Wiring - AreaChartSeries', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    AreaChartSeries? extractAreaSeriesFromWidget(Widget widget) {
      if (widget is SizedBox && widget.child is BravenChartPlus) {
        final chart = widget.child as BravenChartPlus;
        if (chart.series.isNotEmpty && chart.series.first is AreaChartSeries) {
          return chart.series.first as AreaChartSeries;
        }
      }
      return null;
    }

    test('wiring: fillOpacity → AreaChartSeries.fillOpacity', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            fillOpacity: 0.7,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.fillOpacity, equals(0.7));
    });

    test('wiring: strokeWidth → AreaChartSeries.strokeWidth', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            strokeWidth: 3.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.strokeWidth, equals(3.0), reason: 'MISSING: strokeWidth not wired to AreaChartSeries');
    });

    test('wiring: interpolation → AreaChartSeries.interpolation', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            interpolation: models.Interpolation.stepped,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.interpolation, equals(LineInterpolation.stepped));
    });

    test('wiring: tension → AreaChartSeries.tension', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            tension: 0.6,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.tension, equals(0.6), reason: 'MISSING: tension not wired to AreaChartSeries');
    });

    test('wiring: showPoints → AreaChartSeries.showDataPointMarkers', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            showPoints: true,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.showDataPointMarkers, isTrue, reason: 'MISSING: showDataPointMarkers not wired to AreaChartSeries');
    });

    test('wiring: dataPointMarkerRadius → AreaChartSeries.dataPointMarkerRadius', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            markerSize: 5.0, // Using markerSize which maps to dataPointMarkerRadius
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.dataPointMarkerRadius, equals(5.0), reason: 'MISSING: dataPointMarkerRadius not wired to AreaChartSeries');
    });

    test('wiring: yAxisId → AreaChartSeries.yAxisId', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisId: 'shared-axis',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisId, equals('shared-axis'), reason: 'MISSING: yAxisId not wired to AreaChartSeries');
    });

    test('wiring: unit → AreaChartSeries.unit', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.area,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            unit: 'W',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractAreaSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.unit, equals('W'), reason: 'MISSING: unit not wired to AreaChartSeries');
    });
  });

  group('Renderer Wiring - ScatterChartSeries', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    ScatterChartSeries? extractScatterSeriesFromWidget(Widget widget) {
      if (widget is SizedBox && widget.child is BravenChartPlus) {
        final chart = widget.child as BravenChartPlus;
        if (chart.series.isNotEmpty && chart.series.first is ScatterChartSeries) {
          return chart.series.first as ScatterChartSeries;
        }
      }
      return null;
    }

    test('wiring: markerSize → ScatterChartSeries.markerRadius', () {
      // LLM sends markerSize, which is the canonical property
      const config = models.ChartConfiguration(
        type: models.ChartType.scatter,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            markerSize: 10.0, // What the LLM actually sends
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractScatterSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.markerRadius, equals(10.0));
    });

    test('wiring: yAxisId → ScatterChartSeries.yAxisId', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.scatter,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            yAxisId: 'shared-axis',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractScatterSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisId, equals('shared-axis'), reason: 'MISSING: yAxisId not wired to ScatterChartSeries');
    });

    test('wiring: unit → ScatterChartSeries.unit', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.scatter,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            unit: 'kg',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractScatterSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.unit, equals('kg'), reason: 'MISSING: unit not wired to ScatterChartSeries');
    });
  });

  group('Renderer Wiring - BarChartSeries', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    BarChartSeries? extractBarSeriesFromWidget(Widget widget) {
      if (widget is SizedBox && widget.child is BravenChartPlus) {
        final chart = widget.child as BravenChartPlus;
        if (chart.series.isNotEmpty && chart.series.first is BarChartSeries) {
          return chart.series.first as BarChartSeries;
        }
      }
      return null;
    }

    test('wiring: barWidthPercent → BarChartSeries.barWidthPercent', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.bar,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            barWidthPercent: 0.5,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractBarSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.barWidthPercent, equals(0.5), reason: 'MISSING: barWidthPercent not wired (hardcoded to 0.7)');
    });

    test('wiring: barWidthPixels → BarChartSeries.barWidthPixels', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.bar,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            barWidthPixels: 30.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractBarSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.barWidthPixels, equals(30.0), reason: 'MISSING: barWidthPixels not wired');
    });

    test('wiring: barMinWidth → BarChartSeries.minWidth', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.bar,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            barWidthPercent: 0.5,
            barMinWidth: 10.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractBarSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.minWidth, equals(10.0), reason: 'MISSING: barMinWidth not wired');
    });

    test('wiring: barMaxWidth → BarChartSeries.maxWidth', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.bar,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            barWidthPercent: 0.5,
            barMaxWidth: 50.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractBarSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.maxWidth, equals(50.0), reason: 'MISSING: barMaxWidth not wired');
    });

    test('wiring: yAxisId → BarChartSeries.yAxisId', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.bar,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            barWidthPercent: 0.5,
            yAxisId: 'shared-axis',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractBarSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.yAxisId, equals('shared-axis'), reason: 'MISSING: yAxisId not wired to BarChartSeries');
    });

    test('wiring: unit → BarChartSeries.unit', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.bar,
        series: [
          models.SeriesConfig(
            id: 'test',
            data: [
              models.DataPoint(x: 0, y: 1),
            ],
            barWidthPercent: 0.5,
            unit: 'count',
          ),
        ],
      );

      final widget = renderer.render(config);
      final series = extractBarSeriesFromWidget(widget);

      expect(series, isNotNull);
      expect(series!.unit, equals('count'), reason: 'MISSING: unit not wired to BarChartSeries');
    });
  });

  group('Renderer Wiring - BravenChartPlus Widget', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    BravenChartPlus? extractBravenChartPlus(Widget widget) {
      if (widget is SizedBox && widget.child is BravenChartPlus) {
        return widget.child as BravenChartPlus;
      }
      return null;
    }

    SizedBox? extractSizedBox(Widget widget) {
      if (widget is SizedBox) {
        return widget;
      }
      return null;
    }

    test('wiring: title → BravenChartPlus.title', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        title: 'Test Chart',
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.title, equals('Test Chart'), reason: 'MISSING: title not wired');
    });

    test('wiring: subtitle → BravenChartPlus.subtitle', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        subtitle: 'Subtitle here',
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.subtitle, equals('Subtitle here'), reason: 'MISSING: subtitle not wired');
    });

    test('wiring: width → SizedBox.width', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        width: 800.0,
      );

      final widget = renderer.render(config);
      final sizedBox = extractSizedBox(widget);

      expect(sizedBox, isNotNull);
      expect(sizedBox!.width, equals(800.0), reason: 'MISSING: width not wired');
    });

    test('wiring: height → SizedBox.height', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        height: 500.0,
      );

      final widget = renderer.render(config);
      final sizedBox = extractSizedBox(widget);

      expect(sizedBox, isNotNull);
      expect(sizedBox!.height, equals(500.0), reason: 'MISSING: height not wired');
    });

    test('wiring: showLegend → BravenChartPlus.showLegend', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        showLegend: false,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.showLegend, isFalse);
    });

    test('wiring: legendPosition → BravenChartPlus.legendStyle.position', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        legendPosition: models.LegendPosition.top,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.legendStyle?.position, equals(LegendPosition.topCenter));
    });

    test('wiring: normalizationMode → BravenChartPlus.normalizationMode', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        normalizationMode: models.NormalizationModeConfig.perSeries,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.normalizationMode, equals(NormalizationMode.perSeries));
    });

    test('wiring: showScrollbar → BravenChartPlus.showXScrollbar', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        showScrollbar: true,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.showXScrollbar, isTrue);
    });

    test('wiring: showScrollbar → BravenChartPlus.showYScrollbar', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        showScrollbar: true,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.showYScrollbar, isTrue, reason: 'MISSING: showScrollbar should also wire to showYScrollbar');
    });

    test('wiring: backgroundColor → BravenChartPlus.backgroundColor', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        backgroundColor: '#FF0000',
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.backgroundColor, equals(const Color(0xFFFF0000)), reason: 'MISSING: backgroundColor not wired');
    });

    test('wiring: useDarkTheme → BravenChartPlus.theme', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        useDarkTheme: true,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.theme, isNotNull);
      // Dark theme has dark background
      expect(chart.theme!.backgroundColor.computeLuminance() < 0.5, isTrue, reason: 'Dark theme should have dark background');
    });

    test('wiring: showGrid → BravenChartPlus.grid', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        showGrid: false,
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.grid?.horizontal ?? true, isFalse, reason: 'MISSING: showGrid=false should disable grid');
    });

    test('wiring: xAxis.label → BravenChartPlus.xAxisConfig.label', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        xAxis: models.XAxisConfig(label: 'Time', unit: 's'),
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.xAxisConfig?.label, equals('Time'), reason: 'MISSING: xAxis.label not wired (hardcoded to "X")');
    });

    test('wiring: xAxis.unit → BravenChartPlus.xAxisConfig.unit', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        xAxis: models.XAxisConfig(label: 'Time', unit: 'seconds'),
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.xAxisConfig?.unit, equals('seconds'), reason: 'MISSING: xAxis.unit not wired');
    });

    test('wiring: xAxis.min/max → BravenChartPlus.xAxisConfig.min/max', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        xAxis: models.XAxisConfig(min: 0.0, max: 100.0),
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.xAxisConfig?.min, equals(0.0), reason: 'MISSING: xAxis.min not wired');
      expect(chart.xAxisConfig?.max, equals(100.0), reason: 'MISSING: xAxis.max not wired');
    });

    // CRITICAL: Interaction config wiring tests
    test('wiring: interactions.tooltip → InteractionConfig.tooltip.enabled', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        interactions: {'tooltip': true},
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.interactionConfig?.tooltip.enabled, isTrue,
          reason: 'MISSING: interactions.tooltip not wired to InteractionConfig.tooltip.enabled');
    });

    test('wiring: interactions.crosshair → InteractionConfig.crosshair.enabled', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        interactions: {'crosshair': true},
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.interactionConfig?.crosshair.enabled, isTrue,
          reason: 'MISSING: interactions.crosshair not wired to InteractionConfig.crosshair.enabled');
    });

    // CRITICAL: Default behavior when interactions is partial
    test('wiring: partial interactions defaults unspecified to true', () {
      // If LLM sends only crosshair, tooltip should default to true (not false)
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        interactions: {'crosshair': true}, // No tooltip specified
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      // Tooltip should be enabled by default even though not specified
      expect(chart!.interactionConfig?.tooltip.enabled, isTrue,
          reason: 'CRITICAL: Unspecified interaction settings should default to true, not false');
    });

    test('wiring: interactions can explicitly disable tooltip', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        interactions: {'tooltip': false},
      );

      final widget = renderer.render(config);
      final chart = extractBravenChartPlus(widget);

      expect(chart, isNotNull);
      expect(chart!.interactionConfig?.tooltip.enabled, isFalse, reason: 'MISSING: interactions.tooltip=false should disable tooltip');
    });
  });

  // ============================================================================
  // PART 4: ANNOTATION WIRING TESTS
  // ============================================================================

  group('Renderer Wiring - Annotations', () {
    late ChartRenderer renderer;

    setUp(() {
      renderer = const ChartRenderer();
    });

    // Helper to extract BravenChartPlus from rendered widget
    BravenChartPlus? extractBravenChartPlusFromAnnotation(Widget widget) {
      if (widget is SizedBox && widget.child is BravenChartPlus) {
        return widget.child as BravenChartPlus;
      }
      return null;
    }

    // Helper to extract annotations from rendered widget
    // Supports both annotationController (preferred) and deprecated annotations list
    List<ChartAnnotation>? extractAnnotations(Widget widget) {
      final chart = extractBravenChartPlusFromAnnotation(widget);
      if (chart == null) return null;
      // Prefer annotationController (new approach) over deprecated annotations list
      if (chart.annotationController != null) {
        return chart.annotationController!.annotations;
      }
      return chart.annotations;
    }

    test('wiring: referenceLine annotation → ThresholdAnnotation', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.referenceLine,
            value: 50.0,
            label: 'Threshold',
            color: '#FF0000',
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);

      expect(annotations, isNotNull);
      expect(annotations, isNotEmpty, reason: 'MISSING: referenceLine annotation not wired');
      expect(annotations!.first, isA<ThresholdAnnotation>());
      final threshold = annotations.first as ThresholdAnnotation;
      expect(threshold.value, equals(50.0), reason: 'MISSING: referenceLine.value not wired');
      expect(threshold.label, equals('Threshold'), reason: 'MISSING: referenceLine.label not wired');
      expect(threshold.lineColor, equals(const Color(0xFFFF0000)), reason: 'MISSING: referenceLine.color not wired');
    });

    test('wiring: referenceLine.lineWidth → ThresholdAnnotation.lineWidth', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.referenceLine,
            value: 50.0,
            lineWidth: 3.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);
      final threshold = annotations!.first as ThresholdAnnotation;

      expect(threshold.lineWidth, equals(3.0), reason: 'MISSING: referenceLine.lineWidth not wired');
    });

    test('wiring: referenceLine.dashPattern → ThresholdAnnotation.dashPattern', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.referenceLine,
            value: 50.0,
            dashPattern: [5, 3],
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);
      final threshold = annotations!.first as ThresholdAnnotation;

      expect(threshold.dashPattern, equals([5, 3]), reason: 'MISSING: referenceLine.dashPattern not wired');
    });

    test('wiring: referenceLine.orientation=vertical → ThresholdAnnotation.axis=x', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.referenceLine,
            value: 5.0,
            orientation: models.Orientation.vertical,
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);
      final threshold = annotations!.first as ThresholdAnnotation;

      expect(threshold.axis, equals(AnnotationAxis.x), reason: 'MISSING: vertical orientation should map to x axis');
    });

    test('wiring: referenceLine.seriesId → ThresholdAnnotation.seriesId', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'power', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.referenceLine,
            value: 50.0,
            seriesId: 'power',
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);
      final threshold = annotations!.first as ThresholdAnnotation;

      expect(threshold.seriesId, equals('power'), reason: 'MISSING: referenceLine.seriesId not wired');
    });

    test('wiring: zone annotation → RangeAnnotation', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.zone,
            minValue: 50.0,
            maxValue: 100.0,
            label: 'Zone 2',
            color: '#00FF00',
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);

      expect(annotations, isNotNull);
      expect(annotations, isNotEmpty, reason: 'MISSING: zone annotation not wired');
      expect(annotations!.first, isA<RangeAnnotation>());
      final range = annotations.first as RangeAnnotation;
      expect(range.startY, equals(50.0), reason: 'MISSING: zone.minValue not wired to startY');
      expect(range.endY, equals(100.0), reason: 'MISSING: zone.maxValue not wired to endY');
      expect(range.label, equals('Zone 2'), reason: 'MISSING: zone.label not wired');
    });

    test('wiring: zone.opacity → RangeAnnotation.fillColor.opacity', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.zone,
            minValue: 50.0,
            maxValue: 100.0,
            color: '#FF0000',
            opacity: 0.5,
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);
      final range = annotations!.first as RangeAnnotation;

      expect(range.fillColor?.opacity, closeTo(0.5, 0.01), reason: 'MISSING: zone.opacity not wired');
    });

    test('wiring: textLabel annotation → TextAnnotation', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.textLabel,
            text: 'Peak Value',
            position: models.AnnotationPosition.topRight,
            color: '#0000FF',
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);

      expect(annotations, isNotNull);
      expect(annotations, isNotEmpty, reason: 'MISSING: textLabel annotation not wired');
      expect(annotations!.first, isA<TextAnnotation>());
      final text = annotations.first as TextAnnotation;
      expect(text.text, equals('Peak Value'), reason: 'MISSING: textLabel.text not wired');
    });

    test('wiring: textLabel.fontSize → TextAnnotation.style.textStyle.fontSize', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.textLabel,
            text: 'Label',
            fontSize: 16.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);
      final text = annotations!.first as TextAnnotation;

      expect(text.style.textStyle.fontSize, equals(16.0), reason: 'MISSING: textLabel.fontSize not wired');
    });

    test('wiring: marker annotation → PinAnnotation', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.marker,
            x: 5.0,
            y: 75.0,
            label: 'Max',
            color: '#FFFF00',
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);

      expect(annotations, isNotNull);
      expect(annotations, isNotEmpty, reason: 'MISSING: marker annotation not wired');
      expect(annotations!.first, isA<PinAnnotation>());
      final pin = annotations.first as PinAnnotation;
      expect(pin.x, equals(5.0), reason: 'MISSING: marker.x not wired');
      expect(pin.y, equals(75.0), reason: 'MISSING: marker.y not wired');
      expect(pin.label, equals('Max'), reason: 'MISSING: marker.label not wired');
      expect(pin.markerColor, equals(const Color(0xFFFFFF00)), reason: 'MISSING: marker.color not wired');
    });

    test('wiring: multiple annotations of different types', () {
      const config = models.ChartConfiguration(
        type: models.ChartType.line,
        series: [
          models.SeriesConfig(id: 'test', data: [
            models.DataPoint(x: 0, y: 1),
          ])
        ],
        annotations: [
          models.AnnotationConfig(
            type: models.AnnotationType.referenceLine,
            value: 50.0,
          ),
          models.AnnotationConfig(
            type: models.AnnotationType.zone,
            minValue: 60.0,
            maxValue: 80.0,
          ),
          models.AnnotationConfig(
            type: models.AnnotationType.marker,
            x: 10.0,
            y: 90.0,
          ),
        ],
      );

      final widget = renderer.render(config);
      final annotations = extractAnnotations(widget);

      expect(annotations, isNotNull);
      expect(annotations!.length, equals(3), reason: 'MISSING: not all annotations wired');
      expect(annotations[0], isA<ThresholdAnnotation>());
      expect(annotations[1], isA<RangeAnnotation>());
      expect(annotations[2], isA<PinAnnotation>());
    });
  });

  // ============================================================================
  // PART 5: SCHEMA COVERAGE - ANNOTATIONS
  // ============================================================================

  group('Schema Coverage - Annotations', () {
    late CreateChartTool tool;
    Map<String, dynamic>? annotationProperties;

    setUp(() {
      tool = CreateChartTool();
      final schema = tool.inputSchema;
      final annotationsSchema = schema['properties']['annotations'] as Map<String, dynamic>?;
      final annotationsItems = annotationsSchema?['items'] as Map<String, dynamic>?;
      annotationProperties = annotationsItems?['properties'] as Map<String, dynamic>?;
    });

    test('schema: annotations array has items definition', () {
      final schema = tool.inputSchema;
      final annotationsSchema = schema['properties']['annotations'] as Map<String, dynamic>?;
      expect(annotationsSchema, isNotNull, reason: 'MISSING: annotations not in schema');
      expect(annotationsSchema!.containsKey('items'), isTrue,
          reason: 'CRITICAL GAP: annotations schema has no items definition - LLM cannot know annotation structure');
    });

    test('schema: annotations.type (enum)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('type'), isTrue, reason: 'MISSING: annotations.type not in schema');
      final typeEnum = annotationProperties!['type']['enum'] as List;
      expect(typeEnum, contains('referenceLine'), reason: 'MISSING: referenceLine type');
      expect(typeEnum, contains('zone'), reason: 'MISSING: zone type');
      expect(typeEnum, contains('textLabel'), reason: 'MISSING: textLabel type');
      expect(typeEnum, contains('marker'), reason: 'MISSING: marker type');
    });

    test('schema: annotations.value (for referenceLine)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('value'), isTrue, reason: 'MISSING: annotations.value not in schema');
    });

    test('schema: annotations.minValue (for zone)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('minValue'), isTrue, reason: 'MISSING: annotations.minValue not in schema');
    });

    test('schema: annotations.maxValue (for zone)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('maxValue'), isTrue, reason: 'MISSING: annotations.maxValue not in schema');
    });

    test('schema: annotations.x (for marker)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('x'), isTrue, reason: 'MISSING: annotations.x not in schema');
    });

    test('schema: annotations.y (for marker)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('y'), isTrue, reason: 'MISSING: annotations.y not in schema');
    });

    test('schema: annotations.text (for textLabel)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('text'), isTrue, reason: 'MISSING: annotations.text not in schema');
    });

    test('schema: annotations.label', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('label'), isTrue, reason: 'MISSING: annotations.label not in schema');
    });

    test('schema: annotations.color', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('color'), isTrue, reason: 'MISSING: annotations.color not in schema');
    });

    test('schema: annotations.lineWidth', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('lineWidth'), isTrue, reason: 'MISSING: annotations.lineWidth not in schema');
    });

    test('schema: annotations.dashPattern', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('dashPattern'), isTrue, reason: 'MISSING: annotations.dashPattern not in schema');
    });

    test('schema: annotations.opacity', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('opacity'), isTrue, reason: 'MISSING: annotations.opacity not in schema');
    });

    test('schema: annotations.orientation', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('orientation'), isTrue, reason: 'MISSING: annotations.orientation not in schema');
    });

    test('schema: annotations.position (for textLabel)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('position'), isTrue, reason: 'MISSING: annotations.position not in schema');
    });

    test('schema: annotations.fontSize (for textLabel)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('fontSize'), isTrue, reason: 'MISSING: annotations.fontSize not in schema');
    });

    test('schema: annotations.seriesId (for perSeries normalization)', () {
      expect(annotationProperties, isNotNull, reason: 'MISSING: annotations.items.properties not defined');
      expect(annotationProperties!.containsKey('seriesId'), isTrue, reason: 'MISSING: annotations.seriesId not in schema');
    });
  });

  // ============================================================================
  // PROPERTY COUNT SUMMARY
  // ============================================================================
  //
  // Schema Coverage Tests: ~52 tests
  //   - Series properties: 22 (base + line + area + scatter + bar + yAxis)
  //   - Chart-level properties: 12
  //   - X-Axis properties: 9
  //   - Enum values: 16 (interpolation + yAxisPosition + legendPosition + normalizationMode)
  //   - Interaction properties: 5
  //
  // Renderer Wiring Tests: ~45 tests
  //   - LineChartSeries: 17
  //   - AreaChartSeries: 6
  //   - ScatterChartSeries: 1
  //   - BarChartSeries: 4
  //   - BravenChartPlus widget: 14
  //   - Interaction config: 4
  //
  // TOTAL: ~109 tests
  // ============================================================================
}
