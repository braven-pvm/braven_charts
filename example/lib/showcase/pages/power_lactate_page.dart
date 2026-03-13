// Copyright 2025 Braven Charts - Power + Lactate Page
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:math';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Mixed real-time scenario for reproducing sparse-vs-continuous streaming bugs.
class PowerLactatePage extends StatefulWidget {
  const PowerLactatePage({super.key});

  @override
  State<PowerLactatePage> createState() => _PowerLactatePageState();
}

class _PowerLactatePageState extends State<PowerLactatePage> {
  static const int _seedHistorySeconds = 45;
  static const int _maxPowerPoints = 240;
  static const int _maxLactatePoints = 48;

  final ChartOptionsController _optionsController = ChartOptionsController();
  final ChartController _chartController = ChartController();
  final StreamingController _streamingController = StreamingController();
  final List<ChartDataPoint> _powerPoints = <ChartDataPoint>[];
  final List<ChartDataPoint> _lactatePoints = <ChartDataPoint>[];

  Timer? _powerTimer;

  bool _isStreaming = false;
  bool _showTrackingTooltip = true;
  bool _showTrackingMarkers = true;

  int _lactateDelaySeconds = 4;
  int _visibleWindowSeconds = 60;
  int _manualSampleCount = 0;
  int _nextSecond = 0;
  double _currentPower = 185.0;

  @override
  void initState() {
    super.initState();
    _optionsController.showLegend = true;
    _optionsController.showAxisLines = true;
    _optionsController.showGrid = true;
    _optionsController.showXScrollbar = true;
    _optionsController.showYScrollbar = false;
    _optionsController.enableZoom = true;
    _optionsController.enablePan = true;
    _streamingController.addListener(_onStreamingViewportChanged);
    _seedScenario();
    _startStreaming(rebuild: false);
  }

  void _onStreamingViewportChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _powerTimer?.cancel();
    _streamingController.removeListener(_onStreamingViewportChanged);
    _streamingController.dispose();
    _chartController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _seedScenario() {
    _powerPoints.clear();
    _lactatePoints.clear();
    _chartController.clearSeries('power');
    _chartController.clearSeries('lactate');
    _manualSampleCount = 0;
    _nextSecond = 0;
    _currentPower = 185.0;

    for (var second = 0; second < _seedHistorySeconds; second++) {
      _appendPowerPoint(second: second);
    }

    for (final second in <int>[6, 17, 28, 38]) {
      _appendLactateSample(sampleSecond: second);
    }
  }

  void _startStreaming({bool rebuild = true}) {
    if (_isStreaming) {
      return;
    }

    _isStreaming = true;
    _powerTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickPowerStream(),
    );

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _stopStreaming({bool rebuild = true}) {
    _powerTimer?.cancel();
    _powerTimer = null;
    _isStreaming = false;

    if (rebuild && mounted) {
      setState(() {});
    }
  }

  void _tickPowerStream() {
    if (!mounted) {
      return;
    }

    setState(() {
      _appendPowerPoint();
    });
  }

  void _appendPowerPoint({int? second}) {
    final secondIndex = second ?? _nextSecond;
    final baseline = 205 + 38 * sin(secondIndex / 5.0);
    final surge = secondIndex % 18 >= 12 && secondIndex % 18 <= 15 ? 72.0 : 0.0;
    final recovery = secondIndex % 24 >= 19 && secondIndex % 24 <= 21
        ? -42.0
        : 0.0;
    final targetPower =
        baseline + surge + recovery + 14 * cos(secondIndex / 9.0);

    _currentPower = (_currentPower * 0.58 + targetPower * 0.42)
        .clamp(120.0, 430.0)
        .toDouble();

    _powerPoints.add(
      ChartDataPoint(x: secondIndex.toDouble(), y: _currentPower),
    );
    _chartController.addPoint(
      'power',
      ChartDataPoint(x: secondIndex.toDouble(), y: _currentPower),
    );

    _nextSecond = secondIndex + 1;

    while (_powerPoints.length > _maxPowerPoints) {
      _powerPoints.removeAt(0);
    }
  }

  void _takeLactateSample() {
    setState(() {
      final sampleAdded = _appendLactateSample();
      if (sampleAdded) {
        _manualSampleCount++;
      }
    });
  }

  bool _appendLactateSample({int? sampleSecond}) {
    if (_powerPoints.isEmpty) {
      return false;
    }

    final latestPowerSecond = _powerPoints.last.x.round();
    final latestLactateSecond = _lactatePoints.isEmpty
        ? -1
        : _lactatePoints.last.x.round();

    final desiredSecond =
        sampleSecond ?? latestPowerSecond - _lactateDelaySeconds;
    final resolvedSecond = min(
      latestPowerSecond,
      max(0, max(desiredSecond, latestLactateSecond + 1)),
    );

    if (resolvedSecond <= latestLactateSecond) {
      return false;
    }

    final averagePower = _averagePowerUpTo(resolvedSecond, lookbackSeconds: 10);
    final lactate =
        (1.15 +
                (averagePower - 145.0) / 48.0 +
                sin(resolvedSecond / 13.0) * 0.18)
            .clamp(1.0, 8.6)
            .toDouble();

    _lactatePoints.add(
      ChartDataPoint(x: resolvedSecond.toDouble(), y: lactate),
    );
    _chartController.addPoint(
      'lactate',
      ChartDataPoint(x: resolvedSecond.toDouble(), y: lactate),
    );

    while (_lactatePoints.length > _maxLactatePoints) {
      _lactatePoints.removeAt(0);
    }

    return true;
  }

  double _averagePowerUpTo(int second, {required int lookbackSeconds}) {
    final startSecond = max(0, second - lookbackSeconds);
    final relevantPoints = _powerPoints.where(
      (point) => point.x >= startSecond && point.x <= second,
    );

    var total = 0.0;
    var count = 0;
    for (final point in relevantPoints) {
      total += point.y;
      count++;
    }

    if (count == 0) {
      return _currentPower;
    }

    return total / count;
  }

  void _resetScenario() {
    _stopStreaming(rebuild: false);
    setState(() {
      _seedScenario();
    });
    _streamingController.resumeStreaming();
    _startStreaming(rebuild: false);
    if (mounted) {
      setState(() {});
    }
  }

  int get _currentLagSeconds {
    if (_powerPoints.isEmpty || _lactatePoints.isEmpty) {
      return 0;
    }

    return (_powerPoints.last.x - _lactatePoints.last.x).round();
  }

  String get _viewportBadgeLabel {
    if (!_isStreaming) {
      return 'SOURCE STOPPED';
    }

    return _streamingController.viewportMode == ViewportMode.followLatest
        ? 'VIEW LIVE'
        : 'VIEW PAUSED';
  }

  Color get _viewportBadgeColor {
    if (!_isStreaming) {
      return Colors.grey;
    }

    return _streamingController.viewportMode == ViewportMode.followLatest
        ? const Color(0xFF2F855A)
        : const Color(0xFFB7791F);
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Power + Lactate',
      subtitle:
          'Continuous 1 Hz power area plus delayed ad-hoc lactate samples on separate normalized axes',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Scenario',
        icon: Icons.directions_bike_outlined,
        children: [
          IntSliderOption(
            label: 'Lactate Delay',
            value: _lactateDelaySeconds,
            min: 1,
            max: 12,
            suffix: 's',
            onChanged: (value) => setState(() => _lactateDelaySeconds = value),
          ),
          IntSliderOption(
            label: 'Visible Window',
            value: _visibleWindowSeconds,
            min: 20,
            max: 120,
            suffix: 's',
            onChanged: (value) => setState(() => _visibleWindowSeconds = value),
          ),
          BoolOption(
            label: 'Show tracking tooltip',
            value: _showTrackingTooltip,
            onChanged: (value) => setState(() => _showTrackingTooltip = value),
          ),
          BoolOption(
            label: 'Show tracking markers',
            value: _showTrackingMarkers,
            onChanged: (value) => setState(() => _showTrackingMarkers = value),
          ),
        ],
      ),
      OptionSection(
        title: 'Controls',
        icon: Icons.tune,
        children: [
          ActionButton(
            label: _isStreaming ? 'Stop Power Stream' : 'Start Power Stream',
            icon: _isStreaming ? Icons.pause : Icons.play_arrow,
            isPrimary: !_isStreaming,
            isDestructive: _isStreaming,
            onPressed: _isStreaming ? _stopStreaming : _startStreaming,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Take Lactate Sample',
            icon: Icons.bloodtype_outlined,
            isPrimary: true,
            onPressed: _takeLactateSample,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: 'Reset Scenario',
            icon: Icons.refresh,
            onPressed: _resetScenario,
          ),
        ],
      ),
      const OptionSection(
        title: 'Test Notes',
        icon: Icons.fact_check_outlined,
        children: [
          InfoBox(
            message:
                'The amber area simulates live power at 1 Hz. The red line simulates sparse lactate samples that only appear when you press the sample button and are intentionally plotted a few seconds behind the newest power point.',
          ),
        ],
      ),
      InfoBox(
        message: _currentLagSeconds > 0
            ? 'Latest lactate point trails the live power stream by $_currentLagSeconds seconds.'
            : 'Lactate is caught up with the power stream.',
        type: _currentLagSeconds > 0
            ? InfoBoxType.warning
            : InfoBoxType.success,
      ),
    ];
  }

  Widget _buildChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: 'Cyclist Power vs Lactate',
          subtitle:
              'Area stream updates every second while manual lactate samples stay sparse and delayed',
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _viewportBadgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _viewportBadgeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          child: BravenChartPlus(
            key: const ValueKey('power_lactate_chart'),
            series: [_buildPowerSeries(), _buildLactateSeries()],
            controller: _chartController,
            streamingController: _streamingController,
            theme: _optionsController.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
              autoHide: false,
            ),
            xAxisConfig: XAxisConfig(
              label: 'Elapsed',
              unit: 's',
              showAxisLine: _optionsController.showAxisLines,
              labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Power',
              unit: 'W',
              showAxisLine: _optionsController.showAxisLines,
              showCrosshairLabel: true,
              labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
            ),
            normalizationMode: NormalizationMode.perSeries,
            autoScrollConfig: AutoScrollConfig(
              enabled: true,
              maxVisiblePoints: _visibleWindowSeconds,
              resumeOnNewData: false,
              pauseOnUserInteraction: true,
              resumeAfterInteractionDelay: const Duration(seconds: 5),
              animateIncomingData: true,
              incomingDataAnimationDuration: const Duration(milliseconds: 280),
              animateScroll: true,
              scrollAnimationDuration: const Duration(milliseconds: 200),
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
              crosshair: CrosshairConfig.tracking(
                interpolate: true,
                showTooltip: _showTrackingTooltip,
                showMarkers: _showTrackingMarkers,
              ),
              tooltip: const TooltipConfig(enabled: false),
            ),
          ),
        );
      },
    );
  }

  AreaChartSeries _buildPowerSeries() {
    return AreaChartSeries(
      id: 'power',
      name: 'Power [W]',
      points: const <ChartDataPoint>[],
      color: const Color(0xFFC05621),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.0,
      fillOpacity: 0.26,
      isXOrdered: true,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Power',
        unit: 'W',
        showAxisLine: _optionsController.showAxisLines,
        showCrosshairLabel: true,
        labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
      ),
    );
  }

  LineChartSeries _buildLactateSeries() {
    return LineChartSeries(
      id: 'lactate',
      name: 'Lactate [mmol/L]',
      points: const <ChartDataPoint>[],
      color: const Color(0xFF9B2C2C),
      interpolation: LineInterpolation.linear,
      strokeWidth: 2.8,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 4.0,
      isXOrdered: true,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.right,
        label: 'Lactate',
        unit: 'mmol/L',
        showAxisLine: _optionsController.showAxisLines,
        showCrosshairLabel: true,
        labelDisplay: AxisLabelDisplay.labelWithUnitAndTickUnit,
      ),
    );
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      highlighted: true,
      color: const Color(0xFFFFF4E6),
      items: [
        const StatusItem(
          label: 'Power',
          value: '1 Hz',
          color: Color(0xFFC05621),
        ),
        const StatusItem(label: 'Axes', value: '2', color: Color(0xFF1F4E79)),
        StatusItem(
          label: 'Lag',
          value: '${_currentLagSeconds}s',
          color: const Color(0xFF9B2C2C),
        ),
        StatusItem(
          label: 'Samples',
          value: _manualSampleCount.toString(),
          color: const Color(0xFF8B2C2C),
        ),
        StatusItem(
          label: 'View',
          value: _streamingController.viewportMode == ViewportMode.followLatest
              ? 'Live'
              : 'Paused',
          color: const Color(0xFF2F855A),
        ),
      ],
    );
  }
}
