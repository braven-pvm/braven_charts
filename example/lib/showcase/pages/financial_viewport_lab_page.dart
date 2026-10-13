// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Reproducible host-controlled financial viewport for public issue #175.
/// Y fitting is computed by this host; it is not a native auto-fit API.
class FinancialViewportLabPage extends StatefulWidget {
  const FinancialViewportLabPage({super.key});

  @override
  State<FinancialViewportLabPage> createState() =>
      _FinancialViewportLabPageState();
}

class _FinancialViewportLabPageState extends State<FinancialViewportLabPage> {
  final _group = ChartInteractionGroupController();
  bool _fitVisibleY = true;
  bool _categorical = false;
  bool _showOscillator = true;
  int _revision = 0;
  int _events = 0;
  ChartXViewport _viewport = const ChartXViewport(min: 304, max: 404);
  double? _yMin;
  double? _yMax;
  late List<CandlestickDataPoint> _points;

  @override
  void initState() {
    super.initState();
    _points = _buildPoints();
    _fitY();
    _group.setViewport(_viewport);
  }

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  List<CandlestickDataPoint> _buildPoints() => [
    for (var i = 0; i < 400; i++)
      CandlestickDataPoint(
        x: i.toDouble(),
        open: 100 + i * 0.5 + math.sin(i * 0.2) * 6 + _revision * 0.1,
        close:
            100 +
            i * 0.5 +
            math.sin(i * 0.2) * 6 +
            math.cos(i) * 2 +
            _revision * 0.1,
        high: 104 + i * 0.5 + math.sin(i * 0.2) * 6 + _revision * 0.1,
        low: 96 + i * 0.5 + math.sin(i * 0.2) * 6 + _revision * 0.1,
        timestamp: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      ),
  ];

  void _fitY() {
    if (!_fitVisibleY) {
      _yMin = null;
      _yMax = null;
      return;
    }
    final visible = _points.where(
      (point) => point.x >= _viewport.min && point.x <= _viewport.max,
    );
    if (visible.isEmpty) return;
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (final point in visible) {
      low = math.min(low, point.low);
      high = math.max(high, point.high);
    }
    final margin = math.max((high - low) * 0.05, 0.01);
    _yMin = low - margin;
    _yMax = high + margin;
  }

  void _onViewportChanged(Map<String, double> bounds) {
    setState(() {
      _viewport = ChartXViewport(min: bounds['minX']!, max: bounds['maxX']!);
      _events++;
      _fitY();
    });
  }

  void _setWindow(ChartXViewport window) {
    setState(() {
      _viewport = window;
      _fitY();
    });
    _group.setViewport(window);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryAxis = _categorical
        ? CategoryAxisConfig(
            categories: [for (var i = 0; i < 400; i++) 'Session ${i + 1}'],
          )
        : null;
    final chartTheme = theme.brightness == Brightness.dark
        ? ChartTheme.dark
        : ChartTheme.light;
    final interaction = InteractionConfig(
      touch: const TouchInteractionConfig(
        profile: TouchInteractionProfile.explore,
      ),
      onViewportChanged: _onViewportChanged,
    );
    return Material(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Financial viewport lab',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pan or pinch either pane. Y fitting is computed by the host from visible candle highs/lows, with 5% padding.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () =>
                      _setWindow(const ChartXViewport(min: 304, max: 404)),
                  child: const Text('Last 100 bars'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _setWindow(const ChartXViewport(min: -0.5, max: 99.5)),
                  child: const Text('First 100 bars'),
                ),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _revision++;
                    _points = _buildPoints();
                    _fitY();
                  }),
                  child: const Text('Refresh candles'),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fit Y to visible candles'),
              subtitle: const Text(
                'Host-computed bounds; both pan directions remain available',
              ),
              value: _fitVisibleY,
              onChanged: (value) => setState(() {
                _fitVisibleY = value;
                _fitY();
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Categorical X labels'),
              value: _categorical,
              onChanged: (value) => setState(() => _categorical = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Synchronized oscillator'),
              value: _showOscillator,
              onChanged: (value) => setState(() => _showOscillator = value),
            ),
            const SizedBox(height: 8),
            Text(
              'X ${_viewport.min.toStringAsFixed(2)}–${_viewport.max.toStringAsFixed(2)} · '
              '${(_viewport.max - _viewport.min).toStringAsFixed(2)} bars · $_events viewport events',
              key: const ValueKey('financial-viewport-readout'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 320,
              child: BravenChartPlus(
                key: const ValueKey('financial-viewport-price'),
                series: [
                  CandlestickChartSeries(
                    id: 'price',
                    name: 'Price',
                    points: _points,
                  ),
                ],
                xAxisConfig: XAxisConfig(
                  min: -0.5,
                  max: 404,
                  tickCount: 5,
                  categoryAxis: categoryAxis,
                ),
                yAxis: YAxisConfig(
                  position: YAxisPosition.right,
                  min: _yMin,
                  max: _yMax,
                  minWidth: 64,
                  maxWidth: 64,
                  labelFormatter: (value) => value.toStringAsFixed(2),
                ),
                theme: chartTheme,
                interactionConfig: interaction,
                interactionGroupController: _group,
              ),
            ),
            if (_showOscillator) ...[
              const SizedBox(height: 16),
              Text('Oscillator', style: theme.textTheme.titleMedium),
              SizedBox(
                height: 180,
                child: BravenChartPlus(
                  key: const ValueKey('financial-viewport-oscillator'),
                  series: [
                    LineChartSeries(
                      id: 'oscillator',
                      name: 'Oscillator',
                      points: [
                        for (final point in _points)
                          ChartDataPoint(
                            x: point.x,
                            y: 50 + math.sin(point.x * 0.12) * 30,
                          ),
                      ],
                    ),
                  ],
                  xAxisConfig: XAxisConfig(
                    min: -0.5,
                    max: 404,
                    tickCount: 5,
                    categoryAxis: categoryAxis,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.right,
                    min: 0,
                    max: 100,
                    minWidth: 64,
                    maxWidth: 64,
                  ),
                  theme: chartTheme,
                  interactionConfig: interaction,
                  interactionGroupController: _group,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const ExpansionTile(
              title: Text('How this composition works'),
              childrenPadding: EdgeInsets.all(16),
              children: [
                SelectableText(
                  'One ChartInteractionGroupController shares X only.\n'
                  'Initialize it once with group.setViewport(ChartXViewport(...)).\n'
                  'onViewportChanged reports minX/maxX. This host selects visible source candles,\n'
                  'computes min(low)/max(high) plus padding, and rebuilds YAxisConfig(min/max).\n'
                  'The oscillator keeps its own fixed 0–100 Y scale.\n'
                  'No reject/restore workaround is used.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
