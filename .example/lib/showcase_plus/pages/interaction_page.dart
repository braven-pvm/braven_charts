import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/braven_charts.dart' as braven;
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/options_panel.dart';

class InteractionPage extends StatefulWidget {
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  // Interaction features
  bool _enableZoom = true;
  bool _enablePan = true;
  bool _enableCrosshair = true;
  bool _enableTooltip = true;
  bool _enableSelection = true;
  bool _showScrollbars = true;

  // Crosshair options
  braven.CrosshairMode _crosshairMode = braven.CrosshairMode.both;
  bool _snapToDataPoint = true;

  // Tooltip options
  braven.TooltipTriggerMode _tooltipTrigger = braven.TooltipTriggerMode.hover;
  braven.TooltipPosition _tooltipPosition = braven.TooltipPosition.auto;
  bool _tooltipFollowCursor = false;
  double _tooltipShowDelay = 100.0;
  double _tooltipHideDelay = 200.0;
  double _tooltipOffsetFromPoint = 8.0;

  // Data
  String _tappedPoint = 'None';
  String _hoveredPoint = 'None';
  String _selectedPoints = '0';

  @override
  Widget build(BuildContext context) {
    // Generate sample data
    final data1 = DataGenerator.generateSineWave(
      count: 50,
      amplitude: 50,
      frequency: 0.5,
      phase: 0,
      yOffset: 100,
    );
    final data2 = DataGenerator.generateSineWave(
      count: 50,
      amplitude: 30,
      frequency: 0.3,
      phase: 1.5,
      yOffset: 100,
    );

    // Create series
    final series = [
      LineChartSeries(
        id: 'sine-1',
        name: 'Primary Wave',
        points: data1,
        color: Colors.blue,
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: true,
      ),
      LineChartSeries(
        id: 'sine-2',
        name: 'Secondary Wave',
        points: data2,
        color: Colors.orange,
        interpolation: LineInterpolation.bezier,
        showDataPointMarkers: true,
      ),
    ];

    // Create interaction config
    final interactionConfig = braven.InteractionConfig(
      enabled: true,
      enableZoom: _enableZoom,
      enablePan: _enablePan,
      enableSelection: _enableSelection,
      showXScrollbar: _showScrollbars,
      showYScrollbar: _showScrollbars,
      crosshair: braven.CrosshairConfig(
        enabled: _enableCrosshair,
        mode: _crosshairMode,
        snapToDataPoint: _snapToDataPoint,
      ),
      tooltip: braven.TooltipConfig(
        enabled: _enableTooltip,
        triggerMode: _tooltipTrigger,
        preferredPosition: _tooltipPosition,
        followCursor: _tooltipFollowCursor,
        showDelay: Duration(milliseconds: _tooltipShowDelay.toInt()),
        hideDelay: Duration(milliseconds: _tooltipHideDelay.toInt()),
        offsetFromPoint: _tooltipOffsetFromPoint,
      ),
      onDataPointTap: (point, position) {
        setState(() {
          _tappedPoint = 'X: ${point.x.toStringAsFixed(1)}, Y: ${point.y.toStringAsFixed(1)}';
        });
      },
      onDataPointHover: (point, position) {
        setState(() {
          if (point != null) {
            _hoveredPoint = 'X: ${point.x.toStringAsFixed(1)}, Y: ${point.y.toStringAsFixed(1)}';
          } else {
            _hoveredPoint = 'None';
          }
        });
      },
      onSelectionChanged: (selectedPoints) {
        setState(() {
          _selectedPoints = '${selectedPoints.length}';
        });
      },
    );

    // Create axis configs
    final xAxis = const AxisConfig(
      orientation: AxisOrientation.horizontal,
      position: AxisPosition.bottom,
      showGrid: true,
      showAxisLine: true,
    );

    final yAxis = const AxisConfig(
      orientation: AxisOrientation.vertical,
      position: AxisPosition.left,
      showGrid: true,
      showAxisLine: true,
    );

    return Row(
      children: [
        // Chart
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Interactive Charts',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore pan, zoom, crosshair, tooltip, and selection interactions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: BravenChartPlus(
                    chartType: ChartType.line,
                    series: series,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    interactionConfig: interactionConfig.copyWith(
                      showFocusBorder: false,
                    ),
                    showLegend: true,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Interaction feedback
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interaction Feedback',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text('Tapped: $_tappedPoint'),
                      Text('Hovered: $_hoveredPoint'),
                      Text('Selected: $_selectedPoints points'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Options Panel
        SizedBox(
          width: 320,
          child: OptionsPanel(
            title: 'Interaction Options',
            children: [
              OptionSection(
                title: 'Gesture Controls',
                children: [
                  BoolOption(
                    label: 'Enable Zoom',
                    value: _enableZoom,
                    onChanged: (value) => setState(() => _enableZoom = value),
                  ),
                  BoolOption(
                    label: 'Enable Pan',
                    value: _enablePan,
                    onChanged: (value) => setState(() => _enablePan = value),
                  ),
                  BoolOption(
                    label: 'Enable Selection',
                    value: _enableSelection,
                    onChanged: (value) => setState(() => _enableSelection = value),
                  ),
                  BoolOption(
                    label: 'Show Scrollbars',
                    value: _showScrollbars,
                    onChanged: (value) => setState(() => _showScrollbars = value),
                  ),
                ],
              ),
              OptionSection(
                title: 'Crosshair',
                children: [
                  BoolOption(
                    label: 'Enable Crosshair',
                    value: _enableCrosshair,
                    onChanged: (value) => setState(() => _enableCrosshair = value),
                  ),
                  EnumOption<braven.CrosshairMode>(
                    label: 'Crosshair Mode',
                    value: _crosshairMode,
                    values: braven.CrosshairMode.values,
                    labelBuilder: (mode) => mode.toString().split('.').last,
                    onChanged: (value) => setState(() => _crosshairMode = value),
                  ),
                  BoolOption(
                    label: 'Snap to Data Point',
                    value: _snapToDataPoint,
                    onChanged: (value) => setState(() => _snapToDataPoint = value),
                  ),
                ],
              ),
              OptionSection(
                title: 'Tooltip',
                children: [
                  BoolOption(
                    label: 'Enable Tooltip',
                    value: _enableTooltip,
                    onChanged: (value) => setState(() => _enableTooltip = value),
                  ),
                  EnumOption<braven.TooltipTriggerMode>(
                    label: 'Tooltip Trigger',
                    value: _tooltipTrigger,
                    values: braven.TooltipTriggerMode.values,
                    labelBuilder: (trigger) => trigger.toString().split('.').last,
                    onChanged: (value) => setState(() => _tooltipTrigger = value),
                  ),
                  EnumOption<braven.TooltipPosition>(
                    label: 'Tooltip Position',
                    value: _tooltipPosition,
                    values: braven.TooltipPosition.values,
                    labelBuilder: (position) => position.toString().split('.').last,
                    onChanged: (value) => setState(() => _tooltipPosition = value),
                  ),
                  BoolOption(
                    label: 'Follow Cursor',
                    value: _tooltipFollowCursor,
                    onChanged: (value) => setState(() => _tooltipFollowCursor = value),
                  ),
                  SliderOption(
                    label: 'Show Delay (ms)',
                    value: _tooltipShowDelay,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    onChanged: (value) => setState(() => _tooltipShowDelay = value),
                  ),
                  SliderOption(
                    label: 'Hide Delay (ms)',
                    value: _tooltipHideDelay,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    onChanged: (value) => setState(() => _tooltipHideDelay = value),
                  ),
                  SliderOption(
                    label: 'Offset from Point (px)',
                    value: _tooltipOffsetFromPoint,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    onChanged: (value) => setState(() => _tooltipOffsetFromPoint = value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

