// Copyright 2025 Braven Charts - Interaction Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates chart interaction features:
/// - Zoom and pan
/// - Crosshair
/// - Tooltips
/// - Point selection
class InteractionPage extends StatefulWidget {
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Interaction options
  bool _enableCrosshair = true;
  bool _enableTooltips = true;

  // State
  ChartDataPoint? _hoveredPoint;
  ChartDataPoint? _tappedPoint;

  // Generated data
  late List<ChartDataPoint> _data;

  @override
  void initState() {
    super.initState();
    _optionsController.enableZoom = true;
    _optionsController.enablePan = true;
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      _data = DataGenerator.generateRandomWalk(
        count: 100,
        startY: 50.0,
        stepSize: 8.0,
      );
    });
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Interaction',
      subtitle: 'Explore zoom, pan, crosshair and tooltips',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Interaction options
      OptionSection(
        title: 'Interactions',
        icon: Icons.touch_app,
        children: [
          BoolOption(
            label: 'Enable Crosshair',
            value: _enableCrosshair,
            onChanged: (v) => setState(() => _enableCrosshair = v),
          ),
          BoolOption(
            label: 'Enable Tooltips',
            value: _enableTooltips,
            onChanged: (v) => setState(() => _enableTooltips = v),
          ),
        ],
      ),

      // Actions
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Regenerate Data',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Clear Selection',
            icon: Icons.clear,
            onPressed: () => setState(() {
              _tappedPoint = null;
              _hoveredPoint = null;
            }),
          ),
        ],
      ),

      // Info
      const InfoBox(
        message: 'Try zooming with scroll wheel, panning by dragging, '
            'hovering for crosshair, and clicking on data points.',
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Interactive Line Chart',
          subtitle: 'Random walk data',
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'random_walk',
                name: 'Random Walk',
                points: _data,
                color: Colors.blue,
                interpolation: LineInterpolation.bezier,
                strokeWidth: 2.0,
                showDataPointMarkers: _optionsController.showDataMarkers,
              ),
            ],
            theme: _optionsController.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme:
                ScrollbarConfig.defaultLight.copyWith(autoHide: false),
            xAxisConfig: XAxisConfig(
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              showAxisLine: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
              crosshair: _enableCrosshair
                  ? const CrosshairConfig(enabled: true)
                  : const CrosshairConfig(enabled: false),
              tooltip: _enableTooltips
                  ? const TooltipConfig(enabled: true)
                  : const TooltipConfig(enabled: false),
            ),
            onPointTap: (point, seriesId) {
              setState(() {
                _tappedPoint = point;
              });
            },
            onPointHover: (point, seriesId) {
              setState(() {
                _hoveredPoint = point;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    final items = <StatusItem>[
      StatusItem(
        label: 'Data Points',
        value: '${_data.length}',
      ),
      StatusItem(
        label: 'Zoom',
        value: _optionsController.enableZoom ? 'On' : 'Off',
      ),
      StatusItem(
        label: 'Pan',
        value: _optionsController.enablePan ? 'On' : 'Off',
      ),
    ];

    if (_hoveredPoint != null) {
      items.add(StatusItem(
        label: 'Hover',
        value:
            '(${_hoveredPoint!.x.toStringAsFixed(1)}, ${_hoveredPoint!.y.toStringAsFixed(1)})',
        color: Colors.blue,
      ));
    }

    if (_tappedPoint != null) {
      items.add(StatusItem(
        label: 'Selected',
        value:
            '(${_tappedPoint!.x.toStringAsFixed(1)}, ${_tappedPoint!.y.toStringAsFixed(1)})',
        color: Colors.green,
      ));
    }

    return StatusPanel(items: items);
  }
}
