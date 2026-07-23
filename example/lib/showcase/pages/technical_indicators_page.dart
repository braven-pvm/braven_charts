// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Financial composition proving native mixed-series and synchronized panes.
class TechnicalIndicatorsPage extends StatefulWidget {
  const TechnicalIndicatorsPage({super.key, this.mediaCapture = false});

  /// Removes showcase chrome while retaining the real synchronized study stack.
  final bool mediaCapture;

  @override
  State<TechnicalIndicatorsPage> createState() =>
      _TechnicalIndicatorsPageState();
}

class _TechnicalIndicatorsPageState extends State<TechnicalIndicatorsPage> {
  static const _axisGutter = 64.0;
  static const _axislessInset = 10.0;
  static const _oppositeGutter = _axisGutter - _axislessInset;

  final _interactionGroup = ChartInteractionGroupController();
  final _options = ChartOptionsController(const ChartOptions(showLegend: true));

  late final List<CandlestickDataPoint> _candles;
  late final List<double> _fastEma;
  late final List<double> _slowEma;
  late final List<RangeAreaDataPoint> _volatilityBand;
  late final List<double> _macd;
  late final List<double> _macdSignal;
  late final List<double> _macdHistogram;
  late final List<double> _smi;
  late final List<double> _smiSignal;

  _FinancialStudyPreset _preset = _FinancialStudyPreset.overview;
  _FinancialRange _range = _FinancialRange.threeMonths;
  bool _showVolatilityBand = true;
  bool _showFastAverage = true;
  bool _showSlowAverage = true;
  bool _showVolume = true;
  bool _showMacd = true;
  bool _showMomentum = true;
  bool _showNavigator = true;
  bool _showTerminalDateAxis = true;
  bool _synchronizeCursor = true;
  bool _synchronizeViewport = true;
  bool _showTrackingTooltip = true;
  bool _showIntersections = true;
  double _indicatorStrokeWidth = 1.6;
  double _volatilityFillOpacity = .16;

  @override
  void initState() {
    super.initState();
    _candles = _buildMarketSessions(180);
    final closes = _candles.map((candle) => candle.close).toList();
    _fastEma = _ema(closes, 12);
    _slowEma = _ema(closes, 26);
    _volatilityBand = _rollingVolatilityBand(
      _candles,
      window: 20,
      deviations: 2,
    );
    _macd = List<double>.generate(
      closes.length,
      (index) => _fastEma[index] - _slowEma[index],
      growable: false,
    );
    _macdSignal = _ema(_macd, 9);
    _macdHistogram = List<double>.generate(
      closes.length,
      (index) => _macd[index] - _macdSignal[index],
      growable: false,
    );
    final smiResult = _buildSmi(_candles);
    _smi = smiResult.$1;
    _smiSignal = smiResult.$2;
    final requestedPreset = Uri.base.queryParameters['preset']?.toLowerCase();
    for (final preset in _FinancialStudyPreset.values) {
      if (preset.name.toLowerCase() == requestedPreset ||
          preset.label.toLowerCase() == requestedPreset) {
        _configurePreset(preset);
        break;
      }
    }
    if (widget.mediaCapture) {
      _configurePreset(_FinancialStudyPreset.terminal);
    }
    _applyRange(_range, rebuild: false);
  }

  @override
  void dispose() {
    _options.dispose();
    _interactionGroup.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaCapture) {
      return _buildMediaCapture();
    }
    return ChartPageLayout(
      title: 'Technical Indicators',
      subtitle:
          'Compose price, volume, trend, and momentum studies on one synchronized financial timeline',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('financial-reset'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset studies'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: ListenableBuilder(
        listenable: _options,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPresetHeader(compact: compact),
                  const SizedBox(height: 16),
                  _buildCapabilityNote(),
                  const SizedBox(height: 16),
                  _buildStudyCard(compact: compact),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMediaCapture() {
    final latest = _candles.last;
    return ColoredBox(
      color: _chartTheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMarketSummary(latest),
            const SizedBox(height: 8),
            Expanded(
              flex: 12,
              child: _alignAxisPane(_buildPriceChart(compact: false)),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 5,
              child: _alignAxisPane(_buildMacdChart(compact: false)),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 5,
              child: _alignAxisPane(_buildMomentumChart(compact: false)),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 80,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _oppositeGutter,
                ),
                child: CartesianNavigator(
                  key: const ValueKey('financial-media-navigator'),
                  height: 72,
                  interactionGroupController: _interactionGroup,
                  fullDomain: ChartXViewport(
                    min: _candles.first.x,
                    max: _candles.last.x,
                  ),
                  snapPolicy: CartesianNavigatorSnapPolicy.values(
                    _candles.map((candle) => candle.x),
                  ),
                  behavior: const CartesianNavigatorBehavior(minimumSpan: 10),
                  overviewSeries: AreaChartSeries(
                    id: 'financial-media-close',
                    name: 'Close',
                    points: _closePoints,
                    color: const Color(0xFF0EA5E9),
                    interpolation: LineInterpolation.monotone,
                    strokeWidth: 1.2,
                    fillOpacity: .14,
                  ),
                  theme: _chartTheme,
                  style: const CartesianNavigatorStyle(
                    borderRadius: 6,
                    handleVisualHeight: 24,
                  ),
                  semanticLabel: 'Technical indicator session range',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetHeader({required bool compact}) {
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('financial-study-selector'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose a financial study composition',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _FinancialBadge(compact: compact),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _FinancialStudyPreset.values)
                  ShowcaseExampleChoiceChip(
                    key: ValueKey('financial-preset-${preset.name}'),
                    label: preset.label,
                    icon: preset.icon,
                    selected: _preset == preset,
                    onSelected: () => _applyPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _preset.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Range', style: theme.textTheme.labelLarge),
                for (final range in _FinancialRange.values)
                  if (range != _FinancialRange.custom)
                    ChoiceChip(
                      key: ValueKey('financial-range-${range.name}'),
                      label: Text(range.label),
                      selected: _range == range,
                      onSelected: (_) => _applyRange(range),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityNote() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('financial-capability-note'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Native now: Candlestick + Range Area volatility + Line overlays, Bar + Line MACD, synchronized panes, and one shared navigator.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyCard({required bool compact}) {
    final terminal = _isTerminal;
    const terminalDateAxisHeight = 50.0;
    final priceHeight =
        (compact ? 360.0 : 420.0) +
        (_showsTerminalDateAxis(_FinancialStudyPane.price)
            ? terminalDateAxisHeight
            : 0);
    final volumeHeight =
        (compact ? 190.0 : 170.0) +
        (_showsTerminalDateAxis(_FinancialStudyPane.volume)
            ? terminalDateAxisHeight
            : 0);
    final macdHeight =
        (compact ? 202.0 : (terminal ? 156.0 : 180.0)) +
        (_showsTerminalDateAxis(_FinancialStudyPane.macd)
            ? terminalDateAxisHeight
            : 0);
    final momentumHeight =
        (compact ? 202.0 : (terminal ? 156.0 : 180.0)) +
        (_showsTerminalDateAxis(_FinancialStudyPane.momentum)
            ? terminalDateAxisHeight
            : 0);
    final navigatorHeight = compact ? 124.0 : 104.0;
    final paneSpacing = terminal ? 1.0 : 8.0;
    final height =
        priceHeight +
        (_showVolume ? volumeHeight + paneSpacing : 0) +
        (_showMacd ? macdHeight + paneSpacing : 0) +
        (_showMomentum ? momentumHeight + paneSpacing : 0) +
        (_showNavigator ? navigatorHeight + paneSpacing : 0) +
        (compact ? 224 : 192);
    final latest = _candles.last;
    return SizedBox(
      height: height,
      child: ChartCard(
        key: const ValueKey('financial-technical-stack'),
        title: 'Synchronized technical stack',
        subtitle:
            '${_candles.length} source sessions · shared cursor and X viewport · independent Y scales',
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMarketSummary(latest),
            const SizedBox(height: 8),
            SizedBox(
              height: priceHeight,
              child: _StudyPane(
                title: 'Price and trend',
                value: '\$${latest.close.toStringAsFixed(2)}',
                showHeader: !terminal,
                child: _alignAxisPane(_buildPriceChart(compact: compact)),
              ),
            ),
            if (_showVolume) ...[
              Divider(height: terminal ? 1 : 16),
              SizedBox(
                height: volumeHeight,
                child: _StudyPane(
                  title: 'Volume',
                  value:
                      '${(latest.metadata!['volumeMillions'] as num).toStringAsFixed(2)}M',
                  showHeader: !terminal,
                  child: _alignAxisPane(_buildVolumeChart(compact: compact)),
                ),
              ),
            ],
            if (_showMacd) ...[
              Divider(height: terminal ? 1 : 16),
              SizedBox(
                height: macdHeight,
                child: _StudyPane(
                  title: 'MACD (12, 26, 9)',
                  value: _macd.last.toStringAsFixed(2),
                  showHeader: !terminal,
                  child: _alignAxisPane(_buildMacdChart(compact: compact)),
                ),
              ),
            ],
            if (_showMomentum) ...[
              Divider(height: terminal ? 1 : 16),
              SizedBox(
                height: momentumHeight,
                child: _StudyPane(
                  title: 'Stochastic momentum (14, 3, 3)',
                  value: _smi.last.toStringAsFixed(2),
                  showHeader: !terminal,
                  child: _alignAxisPane(_buildMomentumChart(compact: compact)),
                ),
              ),
            ],
            if (_showNavigator) ...[
              Divider(height: terminal ? 1 : 16),
              SizedBox(
                height: navigatorHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: terminal ? 0 : _oppositeGutter,
                  ),
                  child: CartesianNavigator(
                    key: const ValueKey('financial-navigator'),
                    height: compact ? 96 : 80,
                    interactionGroupController: _interactionGroup,
                    fullDomain: ChartXViewport(
                      min: _candles.first.x,
                      max: _candles.last.x,
                    ),
                    snapPolicy: CartesianNavigatorSnapPolicy.values(
                      _candles.map((candle) => candle.x),
                    ),
                    behavior: const CartesianNavigatorBehavior(minimumSpan: 10),
                    overviewSeries: AreaChartSeries(
                      id: 'financial-navigator-close',
                      name: 'Close',
                      points: _closePoints,
                      color: const Color(0xFF0EA5E9),
                      interpolation: LineInterpolation.monotone,
                      strokeWidth: 1.2,
                      fillOpacity: .14,
                    ),
                    theme: _chartTheme,
                    style: const CartesianNavigatorStyle(
                      borderRadius: 6,
                      handleVisualHeight: 24,
                    ),
                    semanticLabel: 'Technical indicator session range',
                    onViewportChanged: (_) {
                      if (_range != _FinancialRange.custom) {
                        setState(() => _range = _FinancialRange.custom);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarketSummary(CandlestickDataPoint latest) {
    final theme = Theme.of(context);
    final previous = _candles[_candles.length - 2].close;
    final change = latest.close - previous;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StudyMetric(
          label: 'Close',
          value: '\$${latest.close.toStringAsFixed(2)}',
        ),
        _StudyMetric(
          label: 'Session',
          value: '${change >= 0 ? '+' : ''}\$${change.toStringAsFixed(2)}',
          valueColor: change >= 0
              ? const Color(0xFF0F766E)
              : theme.colorScheme.error,
        ),
        _StudyMetric(label: 'MACD', value: _macd.last.toStringAsFixed(2)),
        _StudyMetric(label: 'SMI', value: _smi.last.toStringAsFixed(2)),
      ],
    );
  }

  Widget _buildPriceChart({required bool compact}) => BravenChartPlus(
    key: const ValueKey('financial-price-chart'),
    interactionGroupController: _interactionGroup,
    interactionGroupOptions: _groupOptions,
    axislessPlotInsets: _financialPlotInsets,
    series: [
      if (_showVolatilityBand)
        RangeAreaChartSeries(
          id: 'financial-volatility-band',
          name: '20-session volatility',
          unit: 'USD',
          points: _volatilityBand,
          color: const Color(0xFF0F766E),
          interpolation: LineInterpolation.monotone,
          fillOpacity: _volatilityFillOpacity,
          borderMode: RangeAreaBorderMode.boundaries,
          upperBoundaryStyle: RangeAreaBoundaryStyle(
            color: const Color(0xFF0F766E),
            strokeWidth: _indicatorStrokeWidth * .72,
          ),
          lowerBoundaryStyle: RangeAreaBoundaryStyle(
            color: const Color(0xFF0F766E),
            strokeWidth: _indicatorStrokeWidth * .72,
          ),
          hitTestMode: RangeAreaHitTestMode.band,
        ),
      CandlestickChartSeries(
        id: 'financial-price',
        name: 'Price',
        unit: 'USD',
        points: _candles,
        candlestickStyle: const CandlestickChartStyle(
          bodyFillMode: CandlestickBodyFillMode.hollowRising,
          bodyWidthFactor: .66,
          maxBodyWidth: 14,
        ),
      ),
      if (_showFastAverage)
        LineChartSeries(
          id: 'financial-fast-ema',
          name: '12-session EMA',
          points: _pointsFor(_fastEma),
          color: const Color(0xFFF59E0B),
          interpolation: LineInterpolation.monotone,
          strokeWidth: _indicatorStrokeWidth,
        ),
      if (_showSlowAverage)
        LineChartSeries(
          id: 'financial-slow-ema',
          name: '26-session EMA',
          points: _pointsFor(_slowEma),
          color: const Color(0xFF6366F1),
          interpolation: LineInterpolation.monotone,
          strokeWidth: _indicatorStrokeWidth,
        ),
    ],
    annotations: _terminalStudyIdentity(
      id: 'financial-price-identity',
      title: 'Price and trend',
      value: '\$${_candles.last.close.toStringAsFixed(2)}',
    ),
    theme: _chartTheme,
    showLegend: !_isTerminal && _options.showLegend,
    grid: _grid,
    xAxisConfig: _xAxis(
      compact: compact,
      showLabels: false,
      pane: _FinancialStudyPane.price,
    ),
    yAxis: _yAxis(label: 'Price', unit: 'USD'),
    interactionConfig: _interactionConfig,
  );

  Widget _buildVolumeChart({required bool compact}) => BravenChartPlus(
    key: const ValueKey('financial-volume-chart'),
    interactionGroupController: _interactionGroup,
    interactionGroupOptions: _groupOptions,
    axislessPlotInsets: _financialPlotInsets,
    series: [
      BarChartSeries(
        id: 'financial-volume',
        name: 'Volume',
        unit: 'M',
        points: [
          for (final candle in _candles)
            ChartDataPoint(
              x: candle.x,
              y: (candle.metadata!['volumeMillions'] as num).toDouble(),
              timestamp: candle.timestamp,
              pointStyle: PointStyle(
                color: candle.direction == CandlestickDirection.falling
                    ? const Color(0xFFF87171)
                    : const Color(0xFF14B8A6),
              ),
            ),
        ],
        barWidthPercent: .68,
        minWidth: 1,
        maxWidth: 10,
        barStyle: const BarChartStyle(cornerRadius: 1),
      ),
    ],
    annotations: _terminalStudyIdentity(
      id: 'financial-volume-identity',
      title: 'Volume',
      value:
          '${(_candles.last.metadata!['volumeMillions'] as num).toStringAsFixed(2)}M',
    ),
    theme: _chartTheme,
    showLegend: false,
    grid: _grid,
    xAxisConfig: _xAxis(
      compact: compact,
      showLabels: false,
      pane: _FinancialStudyPane.volume,
    ),
    yAxis: _yAxis(label: 'Volume', unit: 'M', tickCount: 3),
    interactionConfig: _interactionConfig,
  );

  Widget _buildMacdChart({required bool compact}) => BravenChartPlus(
    key: const ValueKey('financial-macd-chart'),
    interactionGroupController: _interactionGroup,
    interactionGroupOptions: _groupOptions,
    axislessPlotInsets: _financialPlotInsets,
    series: [
      BarChartSeries(
        id: 'financial-macd-histogram',
        name: 'Histogram',
        points: [
          for (var index = 0; index < _candles.length; index++)
            ChartDataPoint(
              x: _candles[index].x,
              y: _macdHistogram[index],
              timestamp: _candles[index].timestamp,
              pointStyle: PointStyle(
                color: _macdHistogram[index] >= 0
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEC4899),
              ),
            ),
        ],
        barWidthPercent: .64,
        minWidth: 1,
        maxWidth: 9,
      ),
      LineChartSeries(
        id: 'financial-macd',
        name: 'MACD',
        points: _pointsFor(_macd),
        color: const Color(0xFF2563EB),
        interpolation: LineInterpolation.monotone,
        strokeWidth: _indicatorStrokeWidth,
      ),
      LineChartSeries(
        id: 'financial-macd-signal',
        name: 'Signal',
        points: _pointsFor(_macdSignal),
        color: const Color(0xFFEF4444),
        interpolation: LineInterpolation.monotone,
        strokeWidth: _indicatorStrokeWidth,
      ),
    ],
    annotations: [
      _zeroLine('macd-zero'),
      ..._terminalStudyIdentity(
        id: 'financial-macd-identity',
        title: 'MACD (12, 26, 9)',
        value: _macd.last.toStringAsFixed(2),
      ),
    ],
    theme: _chartTheme,
    showLegend: !_isTerminal && _options.showLegend,
    grid: _grid,
    xAxisConfig: _xAxis(
      compact: compact,
      showLabels: false,
      pane: _FinancialStudyPane.macd,
    ),
    yAxis: _yAxis(label: 'MACD', tickCount: 3),
    interactionConfig: _interactionConfig,
  );

  Widget _buildMomentumChart({required bool compact}) => BravenChartPlus(
    key: const ValueKey('financial-momentum-chart'),
    interactionGroupController: _interactionGroup,
    interactionGroupOptions: _groupOptions,
    axislessPlotInsets: _financialPlotInsets,
    series: [
      LineChartSeries(
        id: 'financial-smi',
        name: 'SMI',
        points: _pointsFor(_smi),
        color: const Color(0xFF0891B2),
        interpolation: LineInterpolation.monotone,
        strokeWidth: _indicatorStrokeWidth,
      ),
      LineChartSeries(
        id: 'financial-smi-signal',
        name: 'Signal',
        points: _pointsFor(_smiSignal),
        color: const Color(0xFFEF4444),
        interpolation: LineInterpolation.monotone,
        strokeWidth: _indicatorStrokeWidth,
      ),
    ],
    annotations: [
      _zeroLine('smi-zero'),
      _momentumLevel('smi-overbought', 40),
      _momentumLevel('smi-oversold', -40),
      ..._terminalStudyIdentity(
        id: 'financial-momentum-identity',
        title: 'Stochastic momentum (14, 3, 3)',
        value: _smi.last.toStringAsFixed(2),
      ),
    ],
    theme: _chartTheme,
    showLegend: !_isTerminal && _options.showLegend,
    grid: _grid,
    xAxisConfig: _xAxis(
      compact: compact,
      showLabels: true,
      pane: _FinancialStudyPane.momentum,
    ),
    yAxis: _yAxis(label: 'SMI', tickCount: 5),
    interactionConfig: _interactionConfig,
  );

  Widget _alignAxisPane(Widget child) => Padding(
    padding: EdgeInsets.only(left: _isTerminal ? 0 : _oppositeGutter),
    child: child,
  );

  ChartInteractionGroupOptions get _groupOptions =>
      ChartInteractionGroupOptions(
        synchronizeCursor: _synchronizeCursor,
        synchronizeViewport: _synchronizeViewport,
      );

  ChartTheme get _chartTheme => _options.options.theme ?? ChartTheme.light;

  GridConfig get _grid =>
      GridConfig(horizontal: _options.showGrid, vertical: false);

  XAxisConfig _xAxis({
    required bool compact,
    required bool showLabels,
    required _FinancialStudyPane pane,
  }) {
    final terminalDateAxis = _showsTerminalDateAxis(pane);
    return XAxisConfig(
      min: _candles.first.x,
      max: _candles.last.x,
      visible: !_isTerminal || terminalDateAxis,
      showAxisLine: _options.showAxisLines,
      showTicks: !_isTerminal || terminalDateAxis,
      showTickLabels: terminalDateAxis || showLabels,
      showCrosshairLabel: terminalDateAxis || !_isTerminal,
      tickCount: compact ? 4 : 8,
      labelFormatter: _formatSession,
    );
  }

  YAxisConfig _yAxis({
    required String label,
    String? unit,
    int tickCount = 5,
  }) => YAxisConfig(
    position: _isTerminal ? YAxisPosition.hidden : YAxisPosition.right,
    label: label,
    unit: unit,
    tickCount: tickCount,
    minWidth: _isTerminal ? 0 : _axisGutter,
    maxWidth: _isTerminal ? 0 : _axisGutter,
    showAxisLine: _options.showAxisLines,
    labelFormatter: (value) => value.toStringAsFixed(2),
  );

  InteractionConfig get _interactionConfig => InteractionConfig(
    enableZoom: _options.enableZoom,
    enablePan: _options.enablePan,
    enableSelection: false,
    enableFocusOnHover: false,
    crosshair: CrosshairConfig(
      enabled: _synchronizeCursor,
      mode: CrosshairMode.vertical,
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: true,
      showTrackingTooltip: _showTrackingTooltip,
      showIntersectionMarkers: _showIntersections,
      showCoordinateLabels: true,
    ),
    tooltip: const TooltipConfig(enabled: false),
  );

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Study composition',
      icon: Icons.layers_outlined,
      children: [
        BoolOption(
          key: const ValueKey('financial-show-volatility-band'),
          label: 'Show volatility band',
          subtitle: '20-session average with paired 2σ low/high bounds',
          value: _showVolatilityBand,
          onChanged: (value) => setState(() => _showVolatilityBand = value),
        ),
        BoolOption(
          key: const ValueKey('financial-show-fast-average'),
          label: 'Show fast EMA',
          value: _showFastAverage,
          onChanged: (value) => setState(() => _showFastAverage = value),
        ),
        BoolOption(
          key: const ValueKey('financial-show-slow-average'),
          label: 'Show slow EMA',
          value: _showSlowAverage,
          onChanged: (value) => setState(() => _showSlowAverage = value),
        ),
        BoolOption(
          key: const ValueKey('financial-show-volume'),
          label: 'Show volume pane',
          value: _showVolume,
          onChanged: (value) => setState(() => _showVolume = value),
        ),
        BoolOption(
          key: const ValueKey('financial-show-macd'),
          label: 'Show MACD pane',
          value: _showMacd,
          onChanged: (value) => setState(() => _showMacd = value),
        ),
        BoolOption(
          key: const ValueKey('financial-show-momentum'),
          label: 'Show momentum pane',
          value: _showMomentum,
          onChanged: (value) => setState(() => _showMomentum = value),
        ),
        BoolOption(
          key: const ValueKey('financial-show-navigator'),
          label: 'Show range navigator',
          value: _showNavigator,
          onChanged: (value) => setState(() => _showNavigator = value),
        ),
        if (_isTerminal)
          BoolOption(
            key: const ValueKey('financial-show-terminal-date-axis'),
            label: 'Show bottom date axis',
            subtitle: 'Attach one shared timeline to the last visible study',
            value: _showTerminalDateAxis,
            onChanged: (value) => setState(() => _showTerminalDateAxis = value),
          ),
      ],
    ),
    OptionSection(
      title: 'Synchronization',
      icon: Icons.sync_alt,
      children: [
        BoolOption(
          key: const ValueKey('financial-sync-cursor'),
          label: 'Synchronize cursor',
          subtitle: 'Share one data-X crosshair across every visible study',
          value: _synchronizeCursor,
          onChanged: (value) => setState(() => _synchronizeCursor = value),
        ),
        BoolOption(
          key: const ValueKey('financial-sync-viewport'),
          label: 'Synchronize viewport',
          subtitle: 'Share horizontal pan, zoom, and navigator changes',
          value: _synchronizeViewport,
          onChanged: (value) => setState(() => _synchronizeViewport = value),
        ),
        BoolOption(
          label: 'Show tracking tooltip',
          value: _showTrackingTooltip,
          onChanged: (value) => setState(() => _showTrackingTooltip = value),
        ),
        BoolOption(
          label: 'Show intersections',
          value: _showIntersections,
          onChanged: (value) => setState(() => _showIntersections = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Indicator appearance',
      icon: Icons.tune,
      children: [
        if (_showVolatilityBand)
          SliderOption(
            key: const ValueKey('financial-volatility-opacity'),
            label: 'Volatility fill opacity',
            value: _volatilityFillOpacity,
            min: .06,
            max: .34,
            divisions: 14,
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _volatilityFillOpacity = value),
          ),
        SliderOption(
          key: const ValueKey('financial-indicator-width'),
          label: 'Indicator stroke width',
          value: _indicatorStrokeWidth,
          min: .8,
          max: 4,
          divisions: 16,
          suffix: 'px',
          onChanged: (value) => setState(() => _indicatorStrokeWidth = value),
        ),
      ],
    ),
    StandardChartOptions(
      controller: _options,
      showMarkerOption: false,
      showScrollbarOptions: false,
      showLineStyleOption: false,
      sectionTitle: 'Chart appearance',
    ),
  ];

  void _applyPreset(_FinancialStudyPreset preset) {
    setState(() => _configurePreset(preset));
  }

  void _configurePreset(_FinancialStudyPreset preset) {
    _preset = preset;
    switch (preset) {
      case _FinancialStudyPreset.overview:
        _showVolatilityBand = true;
        _showFastAverage = true;
        _showSlowAverage = true;
        _showVolume = true;
        _showMacd = true;
        _showMomentum = true;
      case _FinancialStudyPreset.trendAndVolume:
        _showVolatilityBand = false;
        _showFastAverage = true;
        _showSlowAverage = true;
        _showVolume = true;
        _showMacd = false;
        _showMomentum = false;
      case _FinancialStudyPreset.volatility:
        _showVolatilityBand = true;
        _showFastAverage = false;
        _showSlowAverage = true;
        _showVolume = true;
        _showMacd = false;
        _showMomentum = false;
      case _FinancialStudyPreset.momentum:
      case _FinancialStudyPreset.terminal:
        _showVolatilityBand = false;
        _showFastAverage = false;
        _showSlowAverage = true;
        _showVolume = false;
        _showMacd = true;
        _showMomentum = true;
        _showTerminalDateAxis = true;
    }
  }

  bool get _isTerminal => _preset == _FinancialStudyPreset.terminal;

  _FinancialStudyPane get _lastVisiblePane {
    if (_showMomentum) return _FinancialStudyPane.momentum;
    if (_showMacd) return _FinancialStudyPane.macd;
    if (_showVolume) return _FinancialStudyPane.volume;
    return _FinancialStudyPane.price;
  }

  bool _showsTerminalDateAxis(_FinancialStudyPane pane) =>
      _isTerminal && _showTerminalDateAxis && _lastVisiblePane == pane;

  EdgeInsets get _financialPlotInsets => _isTerminal
      ? const EdgeInsets.symmetric(horizontal: _axislessInset)
      : const EdgeInsets.all(_axislessInset);

  List<ChartAnnotation> _terminalStudyIdentity({
    required String id,
    required String title,
    required String value,
  }) {
    if (!_isTerminal) return const [];
    return [
      TextAnnotation(
        id: id,
        text: '$title  ·  $value',
        position: const Offset(8, 8),
        style: AnnotationStyle(
          textStyle: TextStyle(
            color: _chartTheme.axisStyle.labelStyle.color ?? Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: widget.mediaCapture ? 'Roboto' : null,
          ),
          borderWidth: 0,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        ),
        backgroundColor: _chartTheme.backgroundColor.withValues(
          alpha: widget.mediaCapture ? 1 : .88,
        ),
        zIndex: 20,
      ),
    ];
  }

  void _applyRange(_FinancialRange range, {bool rebuild = true}) {
    final visible = math.min(
      range.sessions ?? _candles.length,
      _candles.length,
    );
    final last = _candles.last.x;
    final first = _candles[_candles.length - visible].x;
    _interactionGroup.setViewport(ChartXViewport(min: first, max: last));
    if (rebuild) setState(() => _range = range);
  }

  void _reset() {
    _options.update(const ChartOptions(showLegend: true));
    setState(() {
      _preset = _FinancialStudyPreset.overview;
      _showVolatilityBand = true;
      _showFastAverage = true;
      _showSlowAverage = true;
      _showVolume = true;
      _showMacd = true;
      _showMomentum = true;
      _showNavigator = true;
      _showTerminalDateAxis = true;
      _synchronizeCursor = true;
      _synchronizeViewport = true;
      _showTrackingTooltip = true;
      _showIntersections = true;
      _indicatorStrokeWidth = 1.6;
      _volatilityFillOpacity = .16;
      _range = _FinancialRange.threeMonths;
    });
    _applyRange(_FinancialRange.threeMonths);
  }

  String _formatSession(double value) {
    final index = value.round().clamp(0, _candles.length - 1);
    final date = _candles[index].timestamp!.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  List<ChartDataPoint> get _closePoints => [
    for (final candle in _candles)
      ChartDataPoint(x: candle.x, y: candle.close, timestamp: candle.timestamp),
  ];

  List<ChartDataPoint> _pointsFor(List<double> values) => [
    for (var index = 0; index < values.length; index++)
      ChartDataPoint(
        x: _candles[index].x,
        y: values[index],
        timestamp: _candles[index].timestamp,
      ),
  ];

  ThresholdAnnotation _zeroLine(String id) => ThresholdAnnotation(
    id: id,
    axis: AnnotationAxis.y,
    value: 0,
    lineColor: const Color(0xFF94A3B8),
    lineWidth: 1,
    dashPattern: const [4, 4],
  );

  ThresholdAnnotation _momentumLevel(String id, double value) =>
      ThresholdAnnotation(
        id: id,
        axis: AnnotationAxis.y,
        value: value,
        lineColor: const Color(0xFFCBD5E1),
        lineWidth: 1,
        dashPattern: const [3, 5],
      );
}

enum _FinancialStudyPane { price, volume, macd, momentum }

enum _FinancialStudyPreset {
  overview(
    'Full stack',
    Icons.stacked_line_chart,
    'Price and moving averages lead a synchronized volume, MACD, and stochastic-momentum stack.',
  ),
  trendAndVolume(
    'Trend + volume',
    Icons.show_chart,
    'A quieter composition for validating Candlestick overlays against an independent volume scale.',
  ),
  volatility(
    'Volatility band',
    Icons.area_chart_outlined,
    'A typed 20-session 2σ Range Area envelope sits behind price while preserving one low/high interval per session.',
  ),
  momentum(
    'Momentum stack',
    Icons.multiline_chart,
    'MACD and stochastic momentum share the price timeline without sharing their Y domains.',
  ),
  terminal(
    'Terminal',
    Icons.space_dashboard_outlined,
    'Axisless native canvases reclaim the panel chrome, with study identities embedded as screen-positioned text annotations.',
  );

  const _FinancialStudyPreset(this.label, this.icon, this.description);

  final String label;
  final IconData icon;
  final String description;
}

enum _FinancialRange {
  oneMonth('1m', 22),
  threeMonths('3m', 66),
  sixMonths('6m', 132),
  all('All', null),
  custom('Custom', null);

  const _FinancialRange(this.label, this.sessions);

  final String label;
  final int? sessions;
}

class _StudyPane extends StatelessWidget {
  const _StudyPane({
    required this.title,
    required this.value,
    required this.child,
    this.showHeader = true,
  });

  final String title;
  final String value;
  final Widget child;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    if (!showHeader) return child;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(child: child),
      ],
    );
  }
}

class _StudyMetric extends StatelessWidget {
  const _StudyMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label  ',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialBadge extends StatelessWidget {
  const _FinancialBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        compact ? 'FINANCIAL' : 'NATIVE CARTESIAN',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          letterSpacing: .35,
        ),
      ),
    );
  }
}

List<CandlestickDataPoint> _buildMarketSessions(int count) {
  final random = math.Random(60721);
  final sessions = <CandlestickDataPoint>[];
  var date = DateTime.utc(2025, 10, 1);
  var previousClose = 214.0;
  for (var index = 0; index < count; index++) {
    while (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    final structuralTrend = index * .075;
    final cycle = math.sin(index / 8.5) * 5.8 + math.sin(index / 23) * 3.2;
    final shock = switch (index) {
      >= 108 && <= 116 => -(index - 107) * .72,
      >= 117 && <= 126 => -(127 - index) * .58,
      _ => 0.0,
    };
    final target = 214 + structuralTrend + cycle + shock;
    final open = previousClose + (random.nextDouble() - .5) * 1.8;
    final close =
        open + (target - open) * .42 + (random.nextDouble() - .5) * 2.4;
    final high = math.max(open, close) + .7 + random.nextDouble() * 2.3;
    final low = math.min(open, close) - .7 - random.nextDouble() * 2.2;
    final volume =
        18 +
        random.nextDouble() * 18 +
        (close - open).abs() * 5.5 +
        ((index >= 108 && index <= 126) ? 20 : 0);
    sessions.add(
      CandlestickDataPoint(
        x: index.toDouble(),
        open: open,
        high: high,
        low: low,
        close: close,
        timestamp: date,
        label: 'Session ${index + 1}',
        metadata: {'volumeMillions': volume},
      ),
    );
    previousClose = close;
    date = date.add(const Duration(days: 1));
  }
  return List.unmodifiable(sessions);
}

List<RangeAreaDataPoint> _rollingVolatilityBand(
  List<CandlestickDataPoint> candles, {
  required int window,
  required double deviations,
}) {
  assert(window > 1);
  assert(deviations > 0);
  return List<RangeAreaDataPoint>.unmodifiable([
    for (var index = 0; index < candles.length; index++)
      if (index < window - 1)
        RangeAreaDataPoint.gap(
          x: candles[index].x,
          timestamp: candles[index].timestamp,
          label: candles[index].label,
          metadata: const {'state': 'warmup'},
        )
      else
        _volatilityInterval(
          candles: candles,
          index: index,
          window: window,
          deviations: deviations,
        ),
  ]);
}

RangeAreaDataPoint _volatilityInterval({
  required List<CandlestickDataPoint> candles,
  required int index,
  required int window,
  required double deviations,
}) {
  final start = index - window + 1;
  var total = 0.0;
  for (var cursor = start; cursor <= index; cursor++) {
    total += candles[cursor].close;
  }
  final mean = total / window;
  var squaredDeviation = 0.0;
  for (var cursor = start; cursor <= index; cursor++) {
    final difference = candles[cursor].close - mean;
    squaredDeviation += difference * difference;
  }
  final standardDeviation = math.sqrt(squaredDeviation / window);
  final spread = standardDeviation * deviations;
  final candle = candles[index];
  return RangeAreaDataPoint(
    x: candle.x,
    low: mean - spread,
    high: mean + spread,
    timestamp: candle.timestamp,
    label: candle.label,
    metadata: {'window': window, 'deviations': deviations, 'mean': mean},
  );
}

List<double> _ema(List<double> values, int period) {
  if (values.isEmpty) return const [];
  final alpha = 2 / (period + 1);
  final result = List<double>.filled(values.length, values.first);
  for (var index = 1; index < values.length; index++) {
    result[index] = values[index] * alpha + result[index - 1] * (1 - alpha);
  }
  return List.unmodifiable(result);
}

(List<double>, List<double>) _buildSmi(List<CandlestickDataPoint> candles) {
  const lookback = 14;
  final relative = <double>[];
  final halfRange = <double>[];
  for (var index = 0; index < candles.length; index++) {
    final start = math.max(0, index - lookback + 1);
    var highest = double.negativeInfinity;
    var lowest = double.infinity;
    for (var cursor = start; cursor <= index; cursor++) {
      highest = math.max(highest, candles[cursor].high);
      lowest = math.min(lowest, candles[cursor].low);
    }
    relative.add(candles[index].close - ((highest + lowest) / 2));
    halfRange.add((highest - lowest) / 2);
  }
  final smoothRelative = _ema(_ema(relative, 3), 3);
  final smoothRange = _ema(_ema(halfRange, 3), 3);
  final smi = List<double>.generate(
    candles.length,
    (index) => smoothRange[index].abs() < 1e-9
        ? 0
        : 100 * smoothRelative[index] / smoothRange[index],
    growable: false,
  );
  return (List.unmodifiable(smi), _ema(smi, 3));
}
