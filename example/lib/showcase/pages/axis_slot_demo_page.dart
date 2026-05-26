// Copyright 2025 Braven Charts - Y-Axis Slot System Demo Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/standard_options.dart';

/// Demonstrates the Y-axis slot system.
///
/// 5 series all request [YAxisPosition.right], but [BravenChartPlus.maxAxesPerSide]
/// is capped at 3 — so only 3 axes render at a time. The remaining 2 are in
/// overflow. Tapping a legend item drives [BravenChartController.selectSeries],
/// which swaps that series' axis into a visible slot.
class AxisSlotDemoPage extends StatefulWidget {
  const AxisSlotDemoPage({super.key});

  @override
  State<AxisSlotDemoPage> createState() => _AxisSlotDemoPageState();
}

class _AxisSlotDemoPageState extends State<AxisSlotDemoPage> {
  final _controller = BravenChartController();
  final Set<String> _hiddenSeriesIds = {};
  String? _statusMessage;

  // 5 series all competing for the right axis — only 3 slots available.
  late final List<LineChartSeries> _series;

  @override
  void initState() {
    super.initState();
    _series = [
      LineChartSeries(
        id: 'lactate',
        name: 'Lactate',
        color: const Color(0xFFE53935),
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: 0.5 + i * 0.08),
        ),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Lactate',
          unit: 'mmol/L',
        ),
      ),
      LineChartSeries(
        id: 'vo2',
        name: 'VO₂ Avg',
        color: const Color(0xFF1E88E5),
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: 20.0 + i * 0.8),
        ),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'VO₂',
          unit: 'mL/min/kg',
        ),
      ),
      LineChartSeries(
        id: 'rf',
        name: 'Avg RF',
        color: const Color(0xFF43A047),
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: 12.0 + i * 0.3),
        ),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'RF',
          unit: 'br/min',
        ),
      ),
      LineChartSeries(
        id: 'heat',
        name: 'Heat Strain',
        color: const Color(0xFFFF9800),
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: 0.8 + i * 0.04),
        ),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Heat Strain',
          unit: 'HSI',
        ),
      ),
      LineChartSeries(
        id: 'tidal',
        name: 'Tidal Volume',
        color: const Color(0xFF8E24AA),
        points: List.generate(
          20,
          (i) => ChartDataPoint(x: i.toDouble(), y: 0.3 + i * 0.02),
        ),
        yAxisConfig: YAxisConfig(
          position: YAxisPosition.right,
          label: 'Tidal Vol',
          unit: 'L',
        ),
      ),
    ];

    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {
      final visible = _controller.visibleAxisIds.join(', ');
      final overflow = _controller.overflowAxisIds.join(', ');
      _statusMessage = 'Visible: $visible\nOverflow: $overflow';
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleSeries = _series
        .where((s) => !_hiddenSeriesIds.contains(s.id))
        .toList();

    return ChartPageLayout(
      title: 'Y-Axis Slot System',
      subtitle: 'maxAxesPerSide: 3 — 5 series compete for right axis',
      chart: ChartCard(
        title: 'Axis Slot Demo',
        subtitle: 'Tap a legend item to swap its axis in',
        child: Column(
          children: [
            Expanded(
              child: BravenChartPlus(
                series: visibleSeries,
                maxAxesPerSide: 3,
                axisSwapMode: AxisSwapMode.sticky,
                bravenChartController: _controller,
                xAxisConfig: const XAxisConfig(
                  label: 'Time',
                  showAxisLine: true,
                ),
                onAxisSwapped: ({
                  required String promotedAxisId,
                  required String demotedAxisId,
                }) {
                  setState(() {
                    _statusMessage =
                        'Swapped in: $promotedAxisId\nDemoted: $demotedAxisId';
                  });
                },
              ),
            ),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Text(
                  _statusMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.blueGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ChartLegend(
                series: _series,
                hiddenSeriesIds: _hiddenSeriesIds,
                onSeriesToggle: (id) {
                  setState(() {
                    if (_hiddenSeriesIds.contains(id)) {
                      _hiddenSeriesIds.remove(id);
                    } else {
                      _hiddenSeriesIds.add(id);
                    }
                  });
                },
                onSeriesTap: (id) => _controller.selectSeries(id),
              ),
            ),
          ],
        ),
      ),
      bottomPanel: StatusPanel(
        items: [
          StatusItem(
            label: 'Total Series',
            value: '${_series.length}',
          ),
          StatusItem(
            label: 'Visible',
            value:
                '${_series.length - _hiddenSeriesIds.length}',
          ),
          StatusItem(
            label: 'Axis Slots',
            value: '3 / side',
            color: Theme.of(context).colorScheme.primary,
          ),
          StatusItem(
            label: 'Overflow',
            value:
                '${(_series.length - _hiddenSeriesIds.length - 3).clamp(0, _series.length)}',
          ),
        ],
      ),
    );
  }
}
