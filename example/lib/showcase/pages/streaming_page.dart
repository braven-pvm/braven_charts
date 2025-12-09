// Copyright 2025 Braven Charts - Streaming Page
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Demonstrates real-time data streaming capabilities:
/// - Live data updates
/// - Auto-scrolling
/// - Buffer management
/// - Dual-mode (historical + streaming)
class StreamingPage extends StatefulWidget {
  const StreamingPage({super.key});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Streaming state
  bool _isStreaming = false;
  Timer? _streamTimer;
  final List<ChartDataPoint> _streamingData = [];
  int _pointCounter = 0;
  double _lastValue = 50.0;

  // Streaming options
  int _updateRateMs = 100;
  int _maxPoints = 200;
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _optionsController.showXScrollbar = true;
    // Initialize with some data
    _initializeData();
  }

  void _initializeData() {
    _streamingData.clear();
    final initialData = DataGenerator.generateRandomWalk(
      count: 50,
      startY: 50.0,
      stepSize: 5.0,
    );
    _streamingData.addAll(initialData);
    _pointCounter = initialData.length;
    _lastValue = initialData.last.y;
  }

  void _startStreaming() {
    setState(() => _isStreaming = true);
    _streamTimer = Timer.periodic(
      Duration(milliseconds: _updateRateMs),
      (_) => _addDataPoint(),
    );
  }

  void _stopStreaming() {
    _streamTimer?.cancel();
    _streamTimer = null;
    setState(() => _isStreaming = false);
  }

  void _addDataPoint() {
    if (!mounted) return;

    setState(() {
      // Random walk for realistic streaming data
      final change = (DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 1 : -1) * (1 + DateTime.now().millisecondsSinceEpoch % 5).toDouble();
      _lastValue = (_lastValue + change).clamp(10.0, 90.0);

      _streamingData.add(ChartDataPoint(
        x: _pointCounter.toDouble(),
        y: _lastValue,
      ));
      _pointCounter++;

      // Remove old points if over limit
      while (_streamingData.length > _maxPoints) {
        _streamingData.removeAt(0);
      }
    });
  }

  void _resetData() {
    _stopStreaming();
    setState(() {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Streaming Data',
      subtitle: 'Real-time data visualization',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options
      StandardChartOptions(controller: _optionsController),

      // Streaming controls
      OptionSection(
        title: 'Streaming',
        icon: Icons.stream,
        children: [
          IntSliderOption(
            label: 'Update Rate',
            value: _updateRateMs,
            min: 1,
            max: 1000,
            suffix: 'ms',
            onChanged: (v) {
              setState(() => _updateRateMs = v);
              if (_isStreaming) {
                _stopStreaming();
                _startStreaming();
              }
            },
          ),
          IntSliderOption(
            label: 'Max Points',
            value: _maxPoints,
            min: 50,
            max: 500,
            onChanged: (v) => setState(() => _maxPoints = v),
          ),
          BoolOption(
            label: 'Auto-scroll',
            value: _autoScroll,
            onChanged: (v) => setState(() => _autoScroll = v),
          ),
        ],
      ),

      // Streaming controls
      OptionSection(
        title: 'Controls',
        children: [
          ActionButton(
            label: _isStreaming ? 'Stop' : 'Start',
            icon: _isStreaming ? Icons.stop : Icons.play_arrow,
            isPrimary: !_isStreaming,
            isDestructive: _isStreaming,
            onPressed: _isStreaming ? _stopStreaming : _startStreaming,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Reset',
            icon: Icons.refresh,
            onPressed: _resetData,
          ),
        ],
      ),

      // Info
      InfoBox(
        message: 'Click Start to begin streaming live data. '
            'The chart will update in real-time.',
        type: _isStreaming ? InfoBoxType.success : InfoBoxType.info,
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Live Data Stream',
          subtitle: _isStreaming ? 'Streaming...' : 'Paused',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isStreaming ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isStreaming ? Icons.fiber_manual_record : Icons.pause,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isStreaming ? 'LIVE' : 'PAUSED',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'stream',
                name: 'Live Data',
                points: List.from(_streamingData),
                color: _isStreaming ? Colors.green : Colors.blue,
                interpolation: LineInterpolation.bezier,
                strokeWidth: 2.0,
                showDataPointMarkers: false,
              ),
            ],
            theme: _optionsController.theme,
            showLegend: false,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
            xAxis: AxisConfig(
              showGrid: _optionsController.showGrid,
              showAxis: _optionsController.showAxisLines,
            ),
            yAxis: AxisConfig(
              showGrid: _optionsController.showGrid,
              showAxis: _optionsController.showAxisLines,
            ),
            autoScrollConfig: _autoScroll
                ? const AutoScrollConfig(
                    enabled: true,
                    maxVisiblePoints: 100,
                  )
                : null,
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      highlighted: _isStreaming,
      items: [
        StatusItem(
          label: 'Status',
          value: _isStreaming ? 'Streaming' : 'Paused',
          color: _isStreaming ? Colors.green : Colors.grey,
        ),
        StatusItem(
          label: 'Points',
          value: '${_streamingData.length}',
        ),
        StatusItem(
          label: 'Rate',
          value: '${1000 ~/ _updateRateMs} Hz',
        ),
        StatusItem(
          label: 'Latest',
          value: _lastValue.toStringAsFixed(1),
        ),
      ],
    );
  }
}
