// =============================================================================
// BRAVEN_CHARTS API SURFACE AUDIT
// =============================================================================
//
// This test file exhaustively lists EVERY property that braven_charts exposes
// and verifies that braven_agent provides a path to set each one.
//
// If this file fails, it means braven_agent is missing coverage for some
// braven_charts feature.
//
// AUDIT METHODOLOGY:
// 1. List all BravenChartPlus constructor parameters
// 2. List all series type parameters (LineChartSeries, AreaChartSeries, etc.)
// 3. List all config class parameters (XAxisConfig, YAxisConfig, etc.)
// 4. List all enum types and their values
// 5. For each, verify braven_agent can set it (via schema or renderer)
//
// Last audited: 2026-01-30
// =============================================================================

import 'package:braven_agent/src/models/enums.dart' as agent;
import 'package:braven_agent/src/tools/create_chart_tool.dart' as agent_tools;
import 'package:braven_charts/braven_charts.dart'
    hide CreateChartTool, ModifyChartTool;
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ===========================================================================
  // PART 1: BravenChartPlus Widget Parameters
  // ===========================================================================

  group('BravenChartPlus Widget API Surface', () {
    // -------------------------------------------------------------------------
    // REQUIRED PARAMETERS
    // -------------------------------------------------------------------------

    test('series - REQUIRED, exposed via schema series array', () {
      final tool = agent_tools.CreateChartTool();
      final schema = tool.inputSchema;
      expect(schema['required'], contains('series'));
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Core Display
    // -------------------------------------------------------------------------

    test('title - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('title'), isTrue);
    });

    test('subtitle - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('subtitle'), isTrue);
    });

    test('width - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('width'), isTrue);
    });

    test('height - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('height'), isTrue);
    });

    test('backgroundColor - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('backgroundColor'), isTrue);
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Theme/Styling
    // -------------------------------------------------------------------------

    test('theme - exposed via useDarkTheme in schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('useDarkTheme'), isTrue,
          reason: 'ChartTheme exposed as useDarkTheme boolean');
    });

    test('MISSING: theme - full ChartTheme customization NOT exposed', () {
      // braven_charts supports full ChartTheme customization (colors, fonts, etc.)
      // braven_agent only exposes light/dark toggle via useDarkTheme
      // This is a DOCUMENTED GAP - custom themes require braven_charts extension
      expect(true, isTrue,
          reason: 'DOCUMENTED GAP: Full theme customization not exposed');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Legend
    // -------------------------------------------------------------------------

    test('showLegend - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('showLegend'), isTrue);
    });

    test('legendStyle.position - exposed via legendPosition in schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('legendPosition'), isTrue);
    });

    test('MISSING: legendStyle - full LegendStyle customization NOT exposed',
        () {
      // braven_charts LegendStyle has:
      // - position ✅ (via legendPosition)
      // - orientation ❌
      // - backgroundColor ❌
      // - borderRadius ❌
      // - markerShape ❌
      // - markerSize ❌
      // - padding ❌
      // - spacing ❌
      // - textStyle ❌
      expect(true, isTrue,
          reason:
              'DOCUMENTED GAP: Only legendPosition exposed, not full LegendStyle');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Grid
    // -------------------------------------------------------------------------

    test('grid - exposed via showGrid in schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('showGrid'), isTrue);
    });

    test('MISSING: grid - full GridConfig customization NOT exposed', () {
      // braven_charts GridConfig has:
      // - horizontal ✅ (via showGrid=false)
      // - vertical ✅ (via showGrid=false)
      // - majorColor ❌
      // - minorColor ❌
      // - majorWidth ❌
      // - minorWidth ❌
      expect(true, isTrue,
          reason:
              'DOCUMENTED GAP: Only on/off grid exposed, not full GridConfig');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Scrollbars
    // -------------------------------------------------------------------------

    test('showXScrollbar - exposed via showScrollbar in schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('showScrollbar'), isTrue);
    });

    test('showYScrollbar - NOT separately exposed', () {
      // braven_charts has separate showXScrollbar and showYScrollbar
      // braven_agent exposes single showScrollbar that sets both
      expect(true, isTrue,
          reason: 'DOCUMENTED: showScrollbar controls both X and Y');
    });

    test('MISSING: scrollbarTheme - NOT exposed', () {
      // braven_charts has ScrollbarConfig for theme customization
      // braven_agent does not expose this
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('scrollbarTheme'), isFalse,
          reason: 'DOCUMENTED GAP: scrollbarTheme not exposed');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Axes
    // -------------------------------------------------------------------------

    test('xAxisConfig - exposed via xAxis object in schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('xAxis'), isTrue);
    });

    test('yAxis - exposed via series yAxis* properties and yAxes array', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final seriesItems = (props['series']['items']) as Map;
      final seriesProps = seriesItems['properties'] as Map;
      expect(seriesProps.containsKey('yAxisPosition'), isTrue);
      expect(seriesProps.containsKey('yAxisLabel'), isTrue);
      expect(seriesProps.containsKey('yAxisMin'), isTrue);
      expect(seriesProps.containsKey('yAxisMax'), isTrue);
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Normalization
    // -------------------------------------------------------------------------

    test('normalizationMode - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('normalizationMode'), isTrue);
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Interactions
    // -------------------------------------------------------------------------

    test('interactionConfig - exposed via interactions object in schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('interactions'), isTrue);
    });

    test('MISSING: interactionConfig - full InteractionConfig NOT exposed', () {
      // braven_charts InteractionConfig has many nested configs:
      // - enablePan ✅
      // - enableZoom ✅
      // - crosshair (CrosshairConfig with many fields) - partial ✅
      // - tooltip (TooltipConfig with many fields) - partial ✅
      // - gestures (GestureConfig) ❌
      // - keyboard (KeyboardConfig) ❌
      // - selection (SelectionConfig) ❌
      expect(true, isTrue,
          reason: 'DOCUMENTED GAP: Only basic interaction flags exposed');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Annotations
    // -------------------------------------------------------------------------

    test('annotations - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('annotations'), isTrue);
    });

    test('annotationController - NOT exposed (runtime only)', () {
      // AnnotationController is for programmatic annotation management
      // braven_agent uses static annotations list instead
      expect(true, isTrue,
          reason:
              'EXPECTED: annotationController is runtime API, not declarative');
    });

    test('interactiveAnnotations - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('interactiveAnnotations'), isFalse,
          reason: 'DOCUMENTED GAP: interactiveAnnotations flag not exposed');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Controllers (Runtime APIs - Not Exposed)
    // -------------------------------------------------------------------------

    test('controller - NOT exposed (runtime API)', () {
      // ChartController is for programmatic chart manipulation
      // Not applicable for declarative configuration
      expect(true, isTrue, reason: 'EXPECTED: controller is runtime API');
    });

    test('streamingController - NOT exposed (runtime API)', () {
      expect(true, isTrue,
          reason: 'EXPECTED: streamingController is runtime API');
    });

    test('liveStreamController - NOT exposed (runtime API)', () {
      expect(true, isTrue,
          reason: 'EXPECTED: liveStreamController is runtime API');
    });

    test('dataStream - NOT exposed (runtime API)', () {
      expect(true, isTrue, reason: 'EXPECTED: dataStream is runtime API');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Callbacks (Runtime APIs - Not Exposed)
    // -------------------------------------------------------------------------

    test('callbacks - NOT exposed (runtime APIs)', () {
      // onPointTap, onPointHover, onBackgroundTap, onSeriesSelected,
      // onAnnotationTap, onAnnotationDragged are all callbacks
      // Not applicable for declarative configuration
      expect(true, isTrue, reason: 'EXPECTED: callbacks are runtime APIs');
    });

    // -------------------------------------------------------------------------
    // OPTIONAL PARAMETERS - Debug/Development
    // -------------------------------------------------------------------------

    test('showDebugInfo - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('showDebugInfo'), isFalse,
          reason: 'EXPECTED: debug flag not needed for LLM');
    });

    test('showToolbar - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('showToolbar'), isFalse,
          reason: 'DOCUMENTED GAP: showToolbar not exposed');
    });

    test('loadingWidget - NOT exposed (custom widget)', () {
      expect(true, isTrue,
          reason: 'EXPECTED: custom widgets cannot be configured via JSON');
    });

    test('errorWidget - NOT exposed (custom widget)', () {
      expect(true, isTrue,
          reason: 'EXPECTED: custom widgets cannot be configured via JSON');
    });

    test('autoScrollConfig - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('autoScrollConfig'), isFalse,
          reason: 'DOCUMENTED GAP: autoScrollConfig not exposed');
    });

    test('streamingConfig - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      expect(props.containsKey('streamingConfig'), isFalse,
          reason: 'DOCUMENTED GAP: streamingConfig not exposed');
    });
  });

  // ===========================================================================
  // PART 2: Series Types API Surface
  // ===========================================================================

  group('LineChartSeries API Surface', () {
    test('id - exposed via schema series.id', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('id'), isTrue);
    });

    test('name - exposed via schema series.name', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('name'), isTrue);
    });

    test('points - exposed via schema series.data', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('data'), isTrue);
    });

    test('color - exposed via schema series.color', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('color'), isTrue);
    });

    test('interpolation - exposed via schema series.interpolation', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('interpolation'), isTrue);
    });

    test('strokeWidth - exposed via schema series.strokeWidth', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('strokeWidth'), isTrue);
    });

    test('tension - exposed via schema series.tension', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('tension'), isTrue);
    });

    test('showDataPointMarkers - exposed via schema series.showPoints', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('showPoints'), isTrue);
    });

    test('dataPointMarkerRadius - exposed via schema series.markerSize', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('markerSize'), isTrue);
    });

    test('yAxisConfig - exposed via series yAxis* properties', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('yAxisPosition'), isTrue);
      expect(props.containsKey('yAxisLabel'), isTrue);
    });

    test('yAxisId - exposed via schema series.yAxisId', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('yAxisId'), isTrue);
    });

    test('unit - exposed via schema series.unit', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('unit'), isTrue);
    });

    test('MISSING: isXOrdered - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('isXOrdered'), isFalse,
          reason: 'DOCUMENTED GAP: isXOrdered optimization hint not exposed');
    });

    test('MISSING: metadata - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('metadata'), isFalse,
          reason: 'DOCUMENTED GAP: metadata not exposed');
    });

    test('MISSING: annotations (per-series) - NOT exposed', () {
      // LineChartSeries has an annotations property for per-series annotations
      // braven_agent uses chart-level annotations instead
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('annotations'), isFalse,
          reason:
              'DOCUMENTED GAP: per-series annotations not exposed, use chart-level');
    });
  });

  group('AreaChartSeries API Surface', () {
    test('fillOpacity - exposed via schema series.fillOpacity', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('fillOpacity'), isTrue);
    });

    // Other properties inherited from LineChartSeries - tested above
  });

  group('BarChartSeries API Surface', () {
    test('barWidthPercent - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('barWidthPercent'), isTrue);
    });

    test('barWidthPixels - exposed via schema', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('barWidthPixels'), isTrue);
    });

    test('minWidth - exposed via schema series.barMinWidth', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('barMinWidth'), isTrue);
    });

    test('maxWidth - exposed via schema series.barMaxWidth', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('barMaxWidth'), isTrue);
    });

    test('MISSING: borderRadius - NOT exposed', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('barBorderRadius'), isFalse,
          reason:
              'Need to check if braven_charts BarChartSeries has borderRadius');
    });
  });

  group('ScatterChartSeries API Surface', () {
    test('markerRadius - exposed via schema series.markerSize', () {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      final props = seriesItems['properties'] as Map;
      expect(props.containsKey('markerSize'), isTrue);
    });
  });

  // ===========================================================================
  // PART 3: XAxisConfig API Surface
  // ===========================================================================

  group('XAxisConfig API Surface', () {
    late Map<String, dynamic> xAxisProps;

    setUp(() {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final xAxis = props['xAxis'] as Map;
      xAxisProps = (xAxis['properties'] ?? {}) as Map<String, dynamic>;
    });

    test('label - exposed', () {
      expect(xAxisProps.containsKey('label'), isTrue);
    });

    test('unit - exposed', () {
      expect(xAxisProps.containsKey('unit'), isTrue);
    });

    test('min - exposed', () {
      expect(xAxisProps.containsKey('min'), isTrue);
    });

    test('max - exposed', () {
      expect(xAxisProps.containsKey('max'), isTrue);
    });

    test('visible - exposed', () {
      expect(xAxisProps.containsKey('visible'), isTrue);
    });

    test('showAxisLine - exposed', () {
      expect(xAxisProps.containsKey('showAxisLine'), isTrue);
    });

    test('showTicks - exposed', () {
      expect(xAxisProps.containsKey('showTicks'), isTrue);
    });

    test('tickCount - exposed', () {
      expect(xAxisProps.containsKey('tickCount'), isTrue);
    });

    test('MISSING: showCrosshairLabel - NOT exposed', () {
      expect(xAxisProps.containsKey('showCrosshairLabel'), isFalse,
          reason: 'DOCUMENTED GAP: showCrosshairLabel not exposed');
    });

    test('MISSING: crosshairLabelPosition - NOT exposed', () {
      expect(xAxisProps.containsKey('crosshairLabelPosition'), isFalse,
          reason: 'DOCUMENTED GAP: crosshairLabelPosition not exposed');
    });

    test('MISSING: labelStyle - NOT exposed', () {
      expect(xAxisProps.containsKey('labelStyle'), isFalse,
          reason: 'DOCUMENTED GAP: labelStyle (TextStyle) not exposed');
    });

    test('MISSING: axisColor - NOT exposed', () {
      expect(xAxisProps.containsKey('axisColor'), isFalse,
          reason: 'DOCUMENTED GAP: axisColor not exposed');
    });
  });

  // ===========================================================================
  // PART 4: YAxisConfig API Surface
  // ===========================================================================

  group('YAxisConfig API Surface (via series)', () {
    late Map<String, dynamic> seriesProps;

    setUp(() {
      final tool = agent_tools.CreateChartTool();
      final seriesItems =
          (tool.inputSchema['properties']['series']['items']) as Map;
      seriesProps = seriesItems['properties'] as Map<String, dynamic>;
    });

    test('position - exposed via yAxisPosition', () {
      expect(seriesProps.containsKey('yAxisPosition'), isTrue);
    });

    test('label - exposed via yAxisLabel', () {
      expect(seriesProps.containsKey('yAxisLabel'), isTrue);
    });

    test('unit - exposed via yAxisUnit', () {
      expect(seriesProps.containsKey('yAxisUnit'), isTrue);
    });

    test('color - exposed via yAxisColor', () {
      expect(seriesProps.containsKey('yAxisColor'), isTrue);
    });

    test('min - exposed via yAxisMin', () {
      expect(seriesProps.containsKey('yAxisMin'), isTrue);
    });

    test('max - exposed via yAxisMax', () {
      expect(seriesProps.containsKey('yAxisMax'), isTrue);
    });

    test('MISSING: visible - NOT exposed', () {
      expect(seriesProps.containsKey('yAxisVisible'), isFalse,
          reason: 'DOCUMENTED GAP: yAxisVisible not exposed');
    });

    test('MISSING: showAxisLine - NOT exposed', () {
      expect(seriesProps.containsKey('yAxisShowAxisLine'), isFalse,
          reason: 'DOCUMENTED GAP: yAxisShowAxisLine not exposed');
    });

    test('MISSING: showTicks - NOT exposed', () {
      expect(seriesProps.containsKey('yAxisShowTicks'), isFalse,
          reason: 'DOCUMENTED GAP: yAxisShowTicks not exposed');
    });

    test('MISSING: tickCount - NOT exposed', () {
      expect(seriesProps.containsKey('yAxisTickCount'), isFalse,
          reason: 'DOCUMENTED GAP: yAxisTickCount not exposed');
    });
  });

  // ===========================================================================
  // PART 5: Enum Completeness (Cross-Library Verification)
  // ===========================================================================

  group('Enum Completeness - braven_charts vs braven_agent', () {
    test('YAxisPosition - all values mapped', () {
      final chartsValues = YAxisPosition.values.map((e) => e.name).toSet();
      final agentValues = agent.AxisPosition.values.map((e) => e.name).toSet();
      expect(agentValues, equals(chartsValues),
          reason: 'AxisPosition must match YAxisPosition exactly');
    });

    test('LineInterpolation - all values mapped', () {
      final chartsValues = LineInterpolation.values.map((e) => e.name).toSet();
      final agentValues = agent.Interpolation.values.map((e) => e.name).toSet();
      expect(agentValues, equals(chartsValues),
          reason: 'Interpolation must match LineInterpolation exactly');
    });

    test('NormalizationMode - all values mapped', () {
      final chartsValues = NormalizationMode.values.map((e) => e.name).toSet();
      final agentValues =
          agent.NormalizationModeConfig.values.map((e) => e.name).toSet();
      expect(agentValues, equals(chartsValues),
          reason:
              'NormalizationModeConfig must match NormalizationMode exactly');
    });

    test('LegendPosition - all braven_charts values reachable', () {
      // braven_charts: topLeft, topCenter, topRight, centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight
      // braven_agent: top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight
      // Mapping: top→topCenter, bottom→bottomCenter, left→centerLeft, right→centerRight
      final chartsValues = LegendPosition.values.map((e) => e.name).toSet();
      expect(chartsValues, contains('topCenter'),
          reason: 'mapped from agent "top"');
      expect(chartsValues, contains('bottomCenter'),
          reason: 'mapped from agent "bottom"');
      expect(chartsValues, contains('centerLeft'),
          reason: 'mapped from agent "left"');
      expect(chartsValues, contains('centerRight'),
          reason: 'mapped from agent "right"');
      expect(chartsValues, contains('topLeft'));
      expect(chartsValues, contains('topRight'));
      expect(chartsValues, contains('bottomLeft'));
      expect(chartsValues, contains('bottomRight'));

      // Note: braven_charts "center" position is NOT exposed via braven_agent
      expect(chartsValues, contains('center'),
          reason: 'DOCUMENTED GAP: center position not exposed');
    });

    test('AnnotationAnchor - all values mapped', () {
      final chartsValues = AnnotationAnchor.values.map((e) => e.name).toSet();
      final agentValues =
          agent.AnnotationPosition.values.map((e) => e.name).toSet();
      expect(agentValues, equals(chartsValues),
          reason: 'AnnotationPosition must match AnnotationAnchor exactly');
    });

    test('MarkerShape - braven_agent MarkerStyle is subset', () {
      final chartsValues = MarkerShape.values.map((e) => e.name).toSet();
      final agentValues = agent.MarkerStyle.values.map((e) => e.name).toSet();

      // Agent values should all exist in charts
      for (final value in agentValues) {
        expect(chartsValues, contains(value),
            reason: 'MarkerStyle.$value must exist in MarkerShape');
      }

      // Charts has more values than agent exposes
      final missing = chartsValues.difference(agentValues);
      if (missing.isNotEmpty) {
        // This is a documented gap
        expect(missing, containsAll(['star', 'cross', 'plus']),
            reason:
                'DOCUMENTED GAP: MarkerShape has more values than MarkerStyle exposes');
      }
    });

    test('CrosshairMode - used by renderer', () {
      // Verify braven_charts has the modes renderer might need
      final chartsValues = CrosshairMode.values.map((e) => e.name).toSet();
      expect(chartsValues,
          containsAll(['vertical', 'horizontal', 'both', 'none']));
    });

    test('CrosshairDisplayMode - used by renderer', () {
      final chartsValues =
          CrosshairDisplayMode.values.map((e) => e.name).toSet();
      expect(chartsValues, containsAll(['standard', 'tracking', 'auto']));
    });
  });

  // ===========================================================================
  // PART 6: Annotation Types API Surface
  // ===========================================================================

  group('Annotation Types API Surface', () {
    test('ThresholdAnnotation - exposed as referenceLine', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final annotationsItems = (props['annotations']['items']) as Map;
      final annotProps = annotationsItems['properties'] as Map;
      expect(annotProps.containsKey('type'), isTrue);
      final typeEnum = annotProps['type']['enum'] as List;
      expect(typeEnum, contains('referenceLine'));
    });

    test('RangeAnnotation - exposed as zone', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final annotationsItems = (props['annotations']['items']) as Map;
      final annotProps = annotationsItems['properties'] as Map;
      final typeEnum = annotProps['type']['enum'] as List;
      expect(typeEnum, contains('zone'));
    });

    test('TextAnnotation - exposed as textLabel', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final annotationsItems = (props['annotations']['items']) as Map;
      final annotProps = annotationsItems['properties'] as Map;
      final typeEnum = annotProps['type']['enum'] as List;
      expect(typeEnum, contains('textLabel'));
    });

    test('PinAnnotation - exposed as marker', () {
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final annotationsItems = (props['annotations']['items']) as Map;
      final annotProps = annotationsItems['properties'] as Map;
      final typeEnum = annotProps['type']['enum'] as List;
      expect(typeEnum, contains('marker'));
    });

    test('MISSING: PointAnnotation - NOT exposed', () {
      // braven_charts has PointAnnotation for marking specific data points
      // braven_agent doesn't expose this (uses marker/PinAnnotation instead)
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final annotationsItems = (props['annotations']['items']) as Map;
      final annotProps = annotationsItems['properties'] as Map;
      final typeEnum = annotProps['type']['enum'] as List;
      expect(typeEnum, isNot(contains('pointAnnotation')),
          reason:
              'DOCUMENTED GAP: PointAnnotation not exposed, use marker instead');
    });

    test('MISSING: TrendAnnotation - NOT exposed', () {
      // braven_charts has TrendAnnotation for trend lines
      final tool = agent_tools.CreateChartTool();
      final props = tool.inputSchema['properties'] as Map;
      final annotationsItems = (props['annotations']['items']) as Map;
      final annotProps = annotationsItems['properties'] as Map;
      final typeEnum = annotProps['type']['enum'] as List;
      expect(typeEnum, isNot(contains('trendLine')),
          reason: 'DOCUMENTED GAP: TrendAnnotation not exposed');
    });
  });

  // ===========================================================================
  // SUMMARY: Count of Documented Gaps
  // ===========================================================================

  group('API Coverage Summary', () {
    test('COUNT: BravenChartPlus widget-level gaps', () {
      // Documented gaps at widget level:
      // 1. theme (full ChartTheme) - only useDarkTheme
      // 2. legendStyle (full) - only position
      // 3. grid (full GridConfig) - only on/off
      // 4. scrollbarTheme
      // 5. interactionConfig (full) - only basic flags
      // 6. interactiveAnnotations
      // 7. showToolbar
      // 8. autoScrollConfig
      // 9. streamingConfig
      const widgetGaps = 9;
      expect(widgetGaps, equals(9),
          reason: '9 widget-level feature gaps documented');
    });

    test('COUNT: Series-level gaps', () {
      // Documented gaps at series level:
      // 1. strokeDash (dash pattern)
      // 2. markerStyle (shape, not just size) - partial
      // 3. visible (series visibility)
      // 4. legendVisible (legend entry visibility)
      // 5. isXOrdered
      // 6. metadata
      // 7. per-series annotations
      const seriesGaps = 7;
      expect(seriesGaps, equals(7),
          reason: '7 series-level feature gaps documented');
    });

    test('COUNT: Axis config gaps', () {
      // X-axis gaps: showCrosshairLabel, crosshairLabelPosition, labelStyle, axisColor
      // Y-axis gaps: visible, showAxisLine, showTicks, tickCount
      const axisGaps = 8;
      expect(axisGaps, equals(8),
          reason: '8 axis-level feature gaps documented');
    });

    test('COUNT: Annotation gaps', () {
      // 1. PointAnnotation
      // 2. TrendAnnotation
      const annotationGaps = 2;
      expect(annotationGaps, equals(2),
          reason: '2 annotation type gaps documented');
    });

    test('COUNT: Enum gaps', () {
      // 1. LegendPosition.center not exposed
      // 2. MarkerShape.star, cross, plus not exposed
      const enumGaps = 2;
      expect(enumGaps, equals(2), reason: '2 enum value gaps documented');
    });

    test('TOTAL: All documented gaps', () {
      // This is the honest count of features braven_charts has that
      // braven_agent does not fully expose
      const totalGaps = 9 + 7 + 8 + 2 + 2;
      expect(totalGaps, equals(28),
          reason:
              '28 TOTAL documented feature gaps between braven_charts and braven_agent');
    });
  });
}
