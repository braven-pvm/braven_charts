// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// First-class Candlestick chart-family Workbench surface.
class CandlestickChartsPage extends StatefulWidget {
  const CandlestickChartsPage({super.key});

  @override
  State<CandlestickChartsPage> createState() => _CandlestickChartsPageState();
}

class _CandlestickChartsPageState extends State<CandlestickChartsPage> {
  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showLegend: false),
  );
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final ChartInteractionGroupController _stockGroupController =
      ChartInteractionGroupController();
  late List<CandlestickDataPoint> _candles;
  late FinancialTimeDomain _timeDomain;
  late final List<CandlestickDataPoint> _stockCandles;
  late final FinancialTimeDomain _stockTimeDomain;

  CandlestickBodyFillMode _bodyFillMode = CandlestickBodyFillMode.hollowRising;
  double _bodyWidthFactor = 0.7;
  double _maxBodyWidth = 18;
  double _bodyBorderWidth = 1;
  double _wickWidth = 1;
  double _cornerRadius = 1;
  double _minimumBodyHeight = 1;
  bool _showBodyBorder = true;
  bool _showWicks = true;
  bool _showCloseAverage = true;
  bool _trackingEnabled = true;
  bool _showTrackingTooltip = true;
  bool _animateUpdates = true;
  FinancialTimeSpacing _timeSpacing = FinancialTimeSpacing.ordinal;
  int _revisionStep = 0;
  int? _activeCandleIndex;
  _CandlestickShowcaseMode _showcaseMode = _CandlestickShowcaseMode.workbench;
  _StockRangePreset _stockRange = _StockRangePreset.threeMonths;
  FinancialTimeSpacing _stockTimeSpacing = FinancialTimeSpacing.ordinal;
  bool _showVolumePane = true;

  @override
  void initState() {
    super.initState();
    _candles = _buildCandles();
    _timeDomain = FinancialTimeDomain(
      _candles.map((point) => point.timestamp!),
    );
    _stockCandles = _buildStockCandles();
    _stockTimeDomain = FinancialTimeDomain(
      _stockCandles.map((point) => point.timestamp!),
    );
    _stockGroupController.setViewport(_stockViewportFor(_stockRange));
  }

  @override
  void dispose() {
    _optionsController.dispose();
    _workbenchController.dispose();
    _chartController.dispose();
    _stockGroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Candlestick Charts',
      subtitle:
          'Inspect open, high, low, and close on the shared Cartesian coordinate system',
      actions: [
        if (_showcaseMode == _CandlestickShowcaseMode.workbench) ...[
          OutlinedButton.icon(
            key: const ValueKey('candlestick-replay-entrance'),
            onPressed: _chartController.replaySeriesEntrance,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Replay'),
          ),
          OutlinedButton.icon(
            key: const ValueKey('candlestick-revise-latest'),
            onPressed: _reviseLatest,
            icon: const Icon(Icons.update, size: 18),
            label: const Text('Revise latest'),
          ),
        ],
        OutlinedButton.icon(
          key: const ValueKey('candlestick-reset-example'),
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      optionsChildren: _buildOptions(),
      chart: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final contentHeight = math.max(
            constraints.maxHeight,
            _showcaseMode == _CandlestickShowcaseMode.stock
                ? (compact ? 1960.0 : 1360.0)
                : (compact ? 1100.0 : 860.0),
          );
          final content = SizedBox(
            height: contentHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildReviewHeader(compact: compact),
                const SizedBox(height: 16),
                Expanded(
                  child: _showcaseMode == _CandlestickShowcaseMode.stock
                      ? _buildStockComposition(compact: compact)
                      : _buildChartCard(compact: compact),
                ),
                if (_showcaseMode == _CandlestickShowcaseMode.workbench) ...[
                  const SizedBox(height: 16),
                  _buildDirectionLegend(),
                ],
              ],
            ),
          );
          if (contentHeight <= constraints.maxHeight) return content;
          return SingleChildScrollView(
            key: const ValueKey('candlestick-showcase-scroll'),
            primary: false,
            child: content,
          );
        },
      ),
    );
  }

  Widget _buildReviewHeader({required bool compact}) {
    final theme = Theme.of(context);
    final headerCandles = _showcaseMode == _CandlestickShowcaseMode.stock
        ? _stockCandles
        : _candles;
    final headerSpacing = _showcaseMode == _CandlestickShowcaseMode.stock
        ? _stockTimeSpacing
        : _timeSpacing;
    final latest = headerCandles.last;
    final first = headerCandles.first;
    final change = latest.close - first.open;
    final high = headerCandles.map((point) => point.high).reduce(math.max);
    final low = headerCandles.map((point) => point.low).reduce(math.min);
    return Card(
      key: const ValueKey('candlestick-review-header'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.candlestick_chart,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Financial chart workbench',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _FamilyBadge(compact: compact),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${headerSpacing == FinancialTimeSpacing.ordinal ? 'Equal session spacing' : 'Elapsed UTC spacing'} · ${headerCandles.length} candles · track or use arrow keys for complete OHLC',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricPill(
                  label: 'Close',
                  value: '\$${latest.close.toStringAsFixed(2)}',
                ),
                _MetricPill(
                  label: 'Period',
                  value:
                      '${change >= 0 ? '+' : ''}\$${change.toStringAsFixed(2)}',
                  valueColor: change >= 0
                      ? const Color(0xFF0F766E)
                      : const Color(0xFFB91C1C),
                ),
                _MetricPill(
                  label: 'High',
                  value: '\$${high.toStringAsFixed(2)}',
                ),
                _MetricPill(label: 'Low', value: '\$${low.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<_CandlestickShowcaseMode>(
              key: const ValueKey('candlestick-surface-selector'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _CandlestickShowcaseMode.workbench,
                  icon: Icon(Icons.data_object, size: 18),
                  label: Text('Chart family'),
                ),
                ButtonSegment(
                  value: _CandlestickShowcaseMode.stock,
                  icon: Icon(Icons.monitor_heart_outlined, size: 18),
                  label: Text('Stock composition'),
                ),
              ],
              selected: {_showcaseMode},
              onSelectionChanged: (selection) =>
                  setState(() => _showcaseMode = selection.single),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockComposition({required bool compact}) {
    final displayCandles = _stockDisplayCandles;
    final latest = displayCandles.last;
    return ChartCard(
      key: const ValueKey('candlestick-stock-composition'),
      title: 'Market session composition',
      subtitle:
          '${_stockCandles.length} source sessions · independent price and volume scales · full-domain navigator',
      padding: EdgeInsets.all(compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStockControls(latest: latest),
          const SizedBox(height: 8),
          Expanded(
            flex: 5,
            child: _buildStockPriceChart(displayCandles, compact: compact),
          ),
          if (_showVolumePane) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: compact ? 156 : 138,
              child: _buildStockVolumeChart(displayCandles, compact: compact),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: compact ? 230 : 190,
            child: _buildStockNavigator(displayCandles, compact: compact),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: compact ? 172 : 132,
            child: _StockPerformancePanel(
              activeChartCount: _showVolumePane ? 3 : 2,
              sourceSessionCount: _stockCandles.length,
              timeDomain: _stockTimeDomain,
              timeSpacing: _stockTimeSpacing,
              viewportListenable: _stockGroupController.viewportListenable,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 142, child: _buildStockCodeReference()),
        ],
      ),
    );
  }

  Widget _buildStockControls({required CandlestickDataPoint latest}) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<ChartXViewport?>(
      valueListenable: _stockGroupController.viewportListenable,
      builder: (context, viewport, _) {
        final bounds = viewport ?? _stockViewportFor(_stockRange);
        final startIndex = _stockTimeDomain.nearestIndex(
          bounds.min,
          _stockTimeSpacing,
        );
        final endIndex = _stockTimeDomain.nearestIndex(
          bounds.max,
          _stockTimeSpacing,
        );
        final start = _stockCandles[startIndex].timestamp!.toLocal();
        final end = _stockCandles[endIndex].timestamp!.toLocal();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Zoom', style: theme.textTheme.labelLarge),
                for (final preset in _StockRangePreset.values)
                  if (preset != _StockRangePreset.custom)
                    ChoiceChip(
                      key: ValueKey('candlestick-range-${preset.name}'),
                      label: Text(_stockRangeLabel(preset)),
                      selected: _stockRange == preset,
                      onSelected: (_) => _applyStockRange(preset),
                    ),
                FilterChip(
                  key: const ValueKey('candlestick-volume-pane'),
                  avatar: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Volume'),
                  selected: _showVolumePane,
                  onSelected: (value) =>
                      setState(() => _showVolumePane = value),
                ),
                FilterChip(
                  key: const ValueKey('candlestick-stock-time-spacing'),
                  avatar: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    _stockTimeSpacing == FinancialTimeSpacing.ordinal
                        ? 'Equal sessions'
                        : 'Elapsed UTC',
                  ),
                  selected: _stockTimeSpacing == FinancialTimeSpacing.elapsed,
                  onSelected: (_) => _toggleStockTimeSpacing(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(start)} — ${MaterialLocalizations.of(context).formatMediumDate(end)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '\$${latest.close.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockPriceChart(
    List<CandlestickDataPoint> candles, {
    required bool compact,
  }) => BravenChartPlus(
    key: const ValueKey('candlestick-stock-price-chart'),
    interactionGroupController: _stockGroupController,
    interactionGroupOptions: const ChartInteractionGroupOptions(),
    series: [
      CandlestickChartSeries(
        id: 'market-price',
        name: 'Price',
        unit: 'USD',
        points: candles,
        candlestickStyle: CandlestickChartStyle(
          bodyFillMode: _bodyFillMode,
          bodyWidthFactor: _bodyWidthFactor,
          maxBodyWidth: _maxBodyWidth,
          bodyBorderWidth: _bodyBorderWidth,
          wickWidth: _wickWidth,
          showBodyBorder: _showBodyBorder,
          showWicks: _showWicks,
          bodyCornerRadius: _cornerRadius,
          minimumBodyHeight: _minimumBodyHeight,
        ),
      ),
      LineChartSeries(
        id: 'market-average',
        name: '20-session average',
        points: _movingAverage(candles, 20),
        color: const Color(0xFF6366F1),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.5,
      ),
    ],
    theme: _optionsController.options.theme ?? ChartTheme.light,
    showLegend: false,
    grid: GridConfig(
      horizontal: _optionsController.options.showGrid,
      vertical: false,
    ),
    xAxisConfig: XAxisConfig(
      showAxisLine: true,
      tickCount: compact ? 4 : 8,
      labelFormatter: (value) => _formatStockSession(value, candles),
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.right,
      label: 'Price',
      unit: 'USD',
    ),
    interactionConfig: InteractionConfig(
      enableZoom: true,
      enablePan: true,
      crosshair: CrosshairConfig(
        enabled: _trackingEnabled,
        mode: CrosshairMode.vertical,
        displayMode: CrosshairDisplayMode.tracking,
        interpolateValues: false,
        showTrackingTooltip: _showTrackingTooltip,
        showIntersectionMarkers: true,
        showCoordinateLabels: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      keyboard: const KeyboardConfig(enabled: true),
    ),
  );

  Widget _buildStockVolumeChart(
    List<CandlestickDataPoint> candles, {
    required bool compact,
  }) => BravenChartPlus(
    key: const ValueKey('candlestick-stock-volume-chart'),
    interactionGroupController: _stockGroupController,
    interactionGroupOptions: const ChartInteractionGroupOptions(),
    series: [
      BarChartSeries(
        id: 'market-volume',
        name: 'Volume',
        unit: 'M',
        points: [
          for (var index = 0; index < candles.length; index++)
            ChartDataPoint(
              x: candles[index].x,
              y: (candles[index].metadata!['volumeMillions'] as num).toDouble(),
              timestamp: candles[index].timestamp,
              pointStyle: PointStyle(
                color: candles[index].direction == CandlestickDirection.falling
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF16A34A),
              ),
            ),
        ],
        barWidthPercent: .72,
        barStyle: const BarChartStyle(cornerRadius: 1),
      ),
    ],
    theme: _optionsController.options.theme ?? ChartTheme.light,
    showLegend: false,
    grid: const GridConfig(horizontal: true, vertical: false),
    xAxisConfig: XAxisConfig(
      showAxisLine: true,
      showTickLabels: false,
      tickCount: compact ? 4 : 8,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.right,
      label: 'Volume',
      unit: 'M',
      tickCount: 3,
    ),
    interactionConfig: const InteractionConfig(
      enableZoom: true,
      enablePan: true,
      crosshair: CrosshairConfig(
        enabled: true,
        mode: CrosshairMode.vertical,
        displayMode: CrosshairDisplayMode.tracking,
        showTrackingTooltip: true,
      ),
      tooltip: TooltipConfig(enabled: true),
    ),
  );

  Widget _buildStockNavigator(
    List<CandlestickDataPoint> candles, {
    required bool compact,
  }) => ValueListenableBuilder<ChartXViewport?>(
    valueListenable: _stockGroupController.viewportListenable,
    builder: (context, viewport, _) {
      final effective = viewport ?? _stockViewportFor(_stockRange);
      final startIndex = _stockTimeDomain.nearestIndex(
        effective.min,
        _stockTimeSpacing,
      );
      final endIndex = _stockTimeDomain.nearestIndex(
        effective.max,
        _stockTimeSpacing,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: BravenChartPlus(
              key: const ValueKey('candlestick-stock-navigator'),
              interactionGroupController: _stockGroupController,
              interactionGroupOptions: const ChartInteractionGroupOptions(
                synchronizeViewport: false,
              ),
              series: [
                AreaChartSeries(
                  id: 'market-navigator',
                  name: 'Close',
                  points: [
                    for (final candle in candles)
                      ChartDataPoint(
                        x: candle.x,
                        y: candle.close,
                        timestamp: candle.timestamp,
                      ),
                  ],
                  color: const Color(0xFF0EA5E9),
                  interpolation: LineInterpolation.monotone,
                  strokeWidth: 1.25,
                  fillOpacity: .12,
                ),
              ],
              annotations: [
                RangeAnnotation(
                  id: 'navigator-window',
                  startX: effective.min,
                  endX: effective.max,
                  fillColor: const Color(0x243B82F6),
                  borderColor: const Color(0x883B82F6),
                  allowDragging: false,
                  allowEditing: false,
                ),
              ],
              theme: _optionsController.options.theme ?? ChartTheme.light,
              showLegend: false,
              grid: const GridConfig(horizontal: false, vertical: false),
              xAxisConfig: XAxisConfig(
                showAxisLine: true,
                tickCount: compact ? 3 : 7,
                labelFormatter: (value) => _formatStockSession(value, candles),
              ),
              yAxis: YAxisConfig(
                position: YAxisPosition.right,
                visible: false,
                showAxisLine: false,
                showTicks: false,
                showTickLabels: false,
                showCrosshairLabel: false,
              ),
              interactionConfig: const InteractionConfig(
                enableZoom: false,
                enablePan: false,
                crosshair: CrosshairConfig(
                  enabled: true,
                  mode: CrosshairMode.vertical,
                  displayMode: CrosshairDisplayMode.tracking,
                  showTrackingTooltip: false,
                ),
                tooltip: TooltipConfig(enabled: false),
              ),
            ),
          ),
          RangeSlider(
            key: const ValueKey('candlestick-stock-navigator-range'),
            min: 0,
            max: (_stockCandles.length - 1).toDouble(),
            divisions: _stockCandles.length - 1,
            values: RangeValues(startIndex.toDouble(), endIndex.toDouble()),
            labels: RangeLabels(
              _stockCandles[startIndex].label ?? '$startIndex',
              _stockCandles[endIndex].label ?? '$endIndex',
            ),
            onChanged: _setStockNavigatorRange,
          ),
        ],
      );
    },
  );

  Widget _buildStockCodeReference() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('candlestick-stock-code-reference'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Composition code · shared X viewport, independent Y scales',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                IconButton(
                  key: const ValueKey('copy-candlestick-stock-code'),
                  tooltip: 'Copy stock composition code',
                  onPressed: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _stockCompositionSnippet),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      const SnackBar(content: Text('Composition code copied')),
                    );
                  },
                  icon: const Icon(Icons.copy_all_outlined, size: 18),
                ),
              ],
            ),
          ),
          const Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: SelectableText(
                _stockCompositionSnippet,
                style: TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CandlestickDataPoint> get _stockDisplayCandles => [
    for (var index = 0; index < _stockCandles.length; index++)
      _stockCandles[index].copyWith(
        x: _stockTimeDomain.xAt(index, _stockTimeSpacing),
      ),
  ];

  ChartXViewport _stockViewportFor(_StockRangePreset preset) {
    final end = _stockCandles.length - 1;
    final start = switch (preset) {
      _StockRangePreset.oneMonth => math.max(0, end - 21),
      _StockRangePreset.threeMonths => math.max(0, end - 65),
      _StockRangePreset.sixMonths => math.max(0, end - 131),
      _StockRangePreset.yearToDate => _stockCandles.indexWhere(
        (point) => point.timestamp!.year == _stockCandles.last.timestamp!.year,
      ),
      _StockRangePreset.oneYear => math.max(0, end - 251),
      _StockRangePreset.all => 0,
      _StockRangePreset.custom => math.max(0, end - 65),
    };
    return ChartXViewport(
      min: _stockTimeDomain.xAt(start, _stockTimeSpacing),
      max: _stockTimeDomain.xAt(end, _stockTimeSpacing),
    );
  }

  void _applyStockRange(_StockRangePreset preset) {
    setState(() => _stockRange = preset);
    _stockGroupController.setViewport(_stockViewportFor(preset));
  }

  void _setStockNavigatorRange(RangeValues values) {
    final start = values.start.round().clamp(0, _stockCandles.length - 2);
    final end = values.end.round().clamp(start + 1, _stockCandles.length - 1);
    setState(() => _stockRange = _StockRangePreset.custom);
    _stockGroupController.setViewport(
      ChartXViewport(
        min: _stockTimeDomain.xAt(start, _stockTimeSpacing),
        max: _stockTimeDomain.xAt(end, _stockTimeSpacing),
      ),
    );
  }

  void _toggleStockTimeSpacing() {
    final current = _stockGroupController.viewport;
    final start = current == null
        ? 0
        : _stockTimeDomain.nearestIndex(current.min, _stockTimeSpacing);
    final end = current == null
        ? _stockCandles.length - 1
        : _stockTimeDomain.nearestIndex(current.max, _stockTimeSpacing);
    setState(() {
      _stockTimeSpacing = _stockTimeSpacing == FinancialTimeSpacing.ordinal
          ? FinancialTimeSpacing.elapsed
          : FinancialTimeSpacing.ordinal;
    });
    _stockGroupController.setViewport(
      ChartXViewport(
        min: _stockTimeDomain.xAt(start, _stockTimeSpacing),
        max: _stockTimeDomain.xAt(end, _stockTimeSpacing),
      ),
    );
  }

  String _stockRangeLabel(_StockRangePreset preset) => switch (preset) {
    _StockRangePreset.oneMonth => '1m',
    _StockRangePreset.threeMonths => '3m',
    _StockRangePreset.sixMonths => '6m',
    _StockRangePreset.yearToDate => 'YTD',
    _StockRangePreset.oneYear => '1y',
    _StockRangePreset.all => 'All',
    _StockRangePreset.custom => 'Custom',
  };

  String _formatStockSession(double value, List<CandlestickDataPoint> candles) {
    final index = _stockTimeDomain.nearestIndex(value, _stockTimeSpacing);
    if (_stockTimeSpacing == FinancialTimeSpacing.ordinal &&
        (value - index).abs() > .4) {
      return '';
    }
    return candles[index].label ??
        MaterialLocalizations.of(
          context,
        ).formatShortDate(candles[index].timestamp!.toLocal());
  }

  Widget _buildChartCard({required bool compact}) {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        final options = _optionsController.options;
        final displayCandles = _displayCandles;
        final active = _activeCandleIndex == null
            ? null
            : _candles[_activeCandleIndex!];
        return ChartCard(
          key: const ValueKey('candlestick-reference-card'),
          title: 'Thirty-two session price action',
          subtitle: active == null
              ? 'Hollow rising · filled falling · visible doji'
              : '${active.label} · close \$${active.close.toStringAsFixed(2)}',
          padding: EdgeInsets.fromLTRB(
            compact ? 8 : 16,
            compact ? 12 : 16,
            compact ? 8 : 16,
            compact ? 8 : 12,
          ),
          child: BravenChartWorkbench(
            key: const ValueKey('candlestick-workbench'),
            chartController: _chartController,
            workbenchController: _workbenchController,
            availableDisplayModes: const {
              ChartDisplayMode.chart,
              ChartDisplayMode.data,
              ChartDisplayMode.split,
              ChartDisplayMode.source,
            },
            documentOptions: ChartDocumentExtractOptions(
              documentId: 'candlestick-showcase',
              includeViewState: true,
              dataStorage: ChartDataStorage.inlineColumns,
              xAxisFormatterDescriptor: _sessionFormatterDescriptor,
            ),
            tableOptions: ChartTableOptions(
              includeMetadata: true,
              formatters: ChartFormatterRegistry(
                customFormatters: {
                  'showcase.candlestick.session': (value, _) =>
                      _formatSession(value, displayCandles),
                },
              ),
            ),
            tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
            sourceOptions: const ChartDartSourceOptions(
              variableName: 'candlestickChart',
            ),
            splitBreakpoint: 1,
            splitAxis: compact ? Axis.vertical : Axis.horizontal,
            splitRatio: compact ? .52 : .58,
            minimumChartPaneExtent: compact ? 260 : 340,
            minimumTablePaneExtent: compact ? 260 : 420,
            maximumAutoTablePaneExtent: 680,
            autoFitTablePane: !compact,
            isSplitResizable: true,
            chartBuilder: (context, controller) => _buildLiveChart(
              controller,
              options,
              displayCandles,
              compact: compact,
            ),
          ),
        );
      },
    );
  }

  JsonObjectValue get _sessionFormatterDescriptor => ChartFormatterDescriptor(
    id: 'showcase.candlestick.session',
    fallbackPattern: 'Session {value}',
  ).toDocument();

  Widget _buildLiveChart(
    BravenChartController controller,
    ChartOptions options,
    List<CandlestickDataPoint> displayCandles, {
    required bool compact,
  }) => BravenChartPlus(
    key: const ValueKey('candlestick-reference-chart'),
    bravenChartController: controller,
    series: _buildSeries(displayCandles),
    theme: options.theme ?? ChartTheme.light,
    showLegend: false,
    showXScrollbar: options.showXScrollbar,
    showYScrollbar: options.showYScrollbar,
    grid: GridConfig(horizontal: options.showGrid, vertical: options.showGrid),
    xAxisConfig: XAxisConfig(
      label: _timeSpacing == FinancialTimeSpacing.ordinal
          ? 'Trading session'
          : 'Elapsed date',
      showAxisLine: options.showAxisLines,
      tickCount: compact ? 5 : 8,
      labelFormatter: (value) => _formatSession(value, displayCandles),
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.left,
      label: 'Price',
      unit: 'USD',
      showAxisLine: options.showAxisLines,
    ),
    interactionConfig: InteractionConfig(
      enableZoom: options.enableZoom,
      enablePan: options.enablePan,
      enableSelection: true,
      showFocusBorder: true,
      showXScrollbar: options.showXScrollbar,
      showYScrollbar: options.showYScrollbar,
      crosshair: CrosshairConfig(
        enabled: _trackingEnabled,
        mode: CrosshairMode.vertical,
        displayMode: CrosshairDisplayMode.tracking,
        interpolateValues: false,
        showTrackingTooltip: _showTrackingTooltip,
        showIntersectionMarkers: true,
        showCoordinateLabels: true,
      ),
      tooltip: const TooltipConfig(enabled: true),
      keyboard: const KeyboardConfig(enabled: true),
    ),
  );

  List<CandlestickDataPoint> get _displayCandles => [
    for (var index = 0; index < _candles.length; index++)
      _candles[index].copyWith(x: _timeDomain.xAt(index, _timeSpacing)),
  ];

  List<ChartSeries> _buildSeries(List<CandlestickDataPoint> candles) => [
    CandlestickChartSeries(
      id: 'reference-ohlc',
      name: 'Price',
      unit: 'USD',
      points: candles,
      candlestickStyle: CandlestickChartStyle(
        bodyFillMode: _bodyFillMode,
        bodyWidthFactor: _bodyWidthFactor,
        maxBodyWidth: _maxBodyWidth,
        bodyBorderWidth: _bodyBorderWidth,
        wickWidth: _wickWidth,
        showBodyBorder: _showBodyBorder,
        showWicks: _showWicks,
        bodyCornerRadius: _cornerRadius,
        minimumBodyHeight: _minimumBodyHeight,
      ),
      animation: CandlestickAnimationStyle(
        mode: CandlestickAnimationMode.reveal,
        staggerFraction: .85,
        dataUpdateMode: _animateUpdates
            ? CandlestickDataUpdateAnimationMode.interpolate
            : CandlestickDataUpdateAnimationMode.none,
      ),
    ),
    if (_showCloseAverage)
      LineChartSeries(
        id: 'close-average',
        name: '5-session close average',
        points: _movingAverage(candles, 5),
        color: const Color(0xFF6366F1),
        interpolation: LineInterpolation.monotone,
        strokeWidth: 1.6,
      ),
  ];

  List<Widget> _buildOptions() => [
    OptionSection(
      title: 'Tracking and time',
      icon: Icons.track_changes,
      children: [
        BoolOption(
          key: const ValueKey('candlestick-tracking-enabled'),
          label: 'Track OHLC samples',
          subtitle:
              'Nearest session only; financial values are never interpolated',
          value: _trackingEnabled,
          onChanged: (value) => setState(() => _trackingEnabled = value),
        ),
        if (_trackingEnabled)
          BoolOption(
            key: const ValueKey('candlestick-tracking-tooltip'),
            label: 'Show OHLC tooltip',
            subtitle: 'Open, high, low, close, change, and direction',
            value: _showTrackingTooltip,
            onChanged: (value) => setState(() => _showTrackingTooltip = value),
          ),
        EnumOption<FinancialTimeSpacing>(
          key: const ValueKey('candlestick-time-spacing'),
          label: 'Time spacing',
          subtitle: 'Compare equal sessions with real weekend and holiday gaps',
          value: _timeSpacing,
          values: FinancialTimeSpacing.values,
          labelBuilder: (value) => switch (value) {
            FinancialTimeSpacing.ordinal => 'Equal sessions',
            FinancialTimeSpacing.elapsed => 'Elapsed UTC',
          },
          onChanged: (value) => setState(() {
            _timeSpacing = value;
            _activeCandleIndex = null;
          }),
        ),
        BoolOption(
          key: const ValueKey('candlestick-animate-updates'),
          label: 'Animate OHLC revisions',
          subtitle: 'Preserves candle identity while values move',
          value: _animateUpdates,
          onChanged: (value) => setState(() => _animateUpdates = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Candle geometry',
      icon: Icons.candlestick_chart,
      children: [
        EnumOption<CandlestickBodyFillMode>(
          key: const ValueKey('candlestick-body-mode'),
          label: 'Body mode',
          subtitle: 'Hollow rising bodies add a non-colour direction cue',
          value: _bodyFillMode,
          values: CandlestickBodyFillMode.values,
          labelBuilder: (value) => switch (value) {
            CandlestickBodyFillMode.hollowRising => 'Hollow rising',
            CandlestickBodyFillMode.filled => 'Filled bodies',
          },
          onChanged: (value) => setState(() => _bodyFillMode = value),
        ),
        SliderOption(
          key: const ValueKey('candlestick-width-factor'),
          label: 'Body width',
          value: _bodyWidthFactor,
          min: 0.3,
          max: 1,
          divisions: 14,
          suffix: '× spacing',
          onChanged: (value) => setState(() => _bodyWidthFactor = value),
        ),
        SliderOption(
          key: const ValueKey('candlestick-max-width'),
          label: 'Maximum body width',
          value: _maxBodyWidth,
          min: 8,
          max: 30,
          divisions: 22,
          suffix: 'px',
          decimalPlaces: 0,
          onChanged: (value) => setState(() => _maxBodyWidth = value),
        ),
        SliderOption(
          key: const ValueKey('candlestick-corner-radius'),
          label: 'Body corner radius',
          value: _cornerRadius,
          min: 0,
          max: 6,
          divisions: 12,
          suffix: 'px',
          onChanged: (value) => setState(() => _cornerRadius = value),
        ),
        SliderOption(
          key: const ValueKey('candlestick-min-body-height'),
          label: 'Minimum doji height',
          value: _minimumBodyHeight,
          min: 1,
          max: 5,
          divisions: 8,
          suffix: 'px',
          onChanged: (value) => setState(() => _minimumBodyHeight = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Strokes and context',
      icon: Icons.tune,
      children: [
        BoolOption(
          key: const ValueKey('candlestick-show-border'),
          label: 'Show body borders',
          value: _showBodyBorder,
          onChanged: (value) => setState(() => _showBodyBorder = value),
        ),
        if (_showBodyBorder)
          SliderOption(
            key: const ValueKey('candlestick-border-width'),
            label: 'Border width',
            value: _bodyBorderWidth,
            min: 0.5,
            max: 3,
            divisions: 10,
            suffix: 'px',
            onChanged: (value) => setState(() => _bodyBorderWidth = value),
          ),
        BoolOption(
          key: const ValueKey('candlestick-show-wicks'),
          label: 'Show wicks',
          value: _showWicks,
          onChanged: (value) => setState(() => _showWicks = value),
        ),
        if (_showWicks)
          SliderOption(
            key: const ValueKey('candlestick-wick-width'),
            label: 'Wick width',
            value: _wickWidth,
            min: 0.5,
            max: 3,
            divisions: 10,
            suffix: 'px',
            onChanged: (value) => setState(() => _wickWidth = value),
          ),
        BoolOption(
          key: const ValueKey('candlestick-show-average'),
          label: 'Show close average',
          subtitle: 'Demonstrates a native Line overlay on the same plot',
          value: _showCloseAverage,
          onChanged: (value) => setState(() => _showCloseAverage = value),
        ),
      ],
    ),
    StandardChartOptions(
      controller: _optionsController,
      showMarkerOption: false,
      showLegendOption: false,
      showLineStyleOption: false,
      sectionTitle: 'Chart options',
      sectionIcon: Icons.settings,
      themeOptionKey: const ValueKey('candlestick-theme'),
    ),
  ];

  Widget _buildDirectionLegend() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('candlestick-direction-legend'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: const Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DirectionLegendItem(
            label: 'Rising',
            description: 'Hollow body',
            kind: _DirectionLegendKind.hollow,
          ),
          _DirectionLegendItem(
            label: 'Falling',
            description: 'Filled body',
            kind: _DirectionLegendKind.filled,
          ),
          _DirectionLegendItem(
            label: 'Doji',
            description: 'Open equals close',
            kind: _DirectionLegendKind.doji,
          ),
          _DirectionLegendItem(
            label: 'Close average',
            description: '5 sessions',
            kind: _DirectionLegendKind.average,
          ),
        ],
      ),
    );
  }

  String _formatSession(
    double value,
    List<CandlestickDataPoint> displayCandles,
  ) {
    final index = _timeDomain.nearestIndex(value, _timeSpacing);
    if (_timeSpacing == FinancialTimeSpacing.ordinal &&
        (value - index).abs() > 0.35) {
      return '';
    }
    final candle = displayCandles[index];
    return candle.label ??
        MaterialLocalizations.of(
          context,
        ).formatShortDate(candle.timestamp!.toLocal());
  }

  void _reviseLatest() {
    final latest = _candles.last;
    _revisionStep++;
    final closeDelta = _revisionStep.isEven ? -3.4 : 4.6;
    final close = latest.close + closeDelta;
    setState(() {
      _candles = [
        ..._candles.take(_candles.length - 1),
        latest.copyWith(
          high: math.max(latest.high, math.max(latest.open, close) + 1.2),
          low: math.min(latest.low, math.min(latest.open, close) - 1.2),
          close: close,
        ),
      ];
      _activeCandleIndex = _candles.length - 1;
    });
  }

  void _reset() {
    setState(() {
      _bodyFillMode = CandlestickBodyFillMode.hollowRising;
      _bodyWidthFactor = 0.7;
      _maxBodyWidth = 18;
      _bodyBorderWidth = 1;
      _wickWidth = 1;
      _cornerRadius = 1;
      _minimumBodyHeight = 1;
      _showBodyBorder = true;
      _showWicks = true;
      _showCloseAverage = true;
      _trackingEnabled = true;
      _showTrackingTooltip = true;
      _animateUpdates = true;
      _timeSpacing = FinancialTimeSpacing.ordinal;
      _stockTimeSpacing = FinancialTimeSpacing.ordinal;
      _stockRange = _StockRangePreset.threeMonths;
      _showVolumePane = true;
      _candles = _buildCandles();
      _revisionStep = 0;
      _activeCandleIndex = null;
    });
    _stockGroupController.setViewport(_stockViewportFor(_stockRange));
    _optionsController.update(const ChartOptions(showLegend: false));
  }
}

class _FamilyBadge extends StatelessWidget {
  const _FamilyBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      compact ? 'BUILT-IN' : 'BUILT-IN · OHLC WORKBENCH',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    ),
  );
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

enum _DirectionLegendKind { hollow, filled, doji, average }

class _DirectionLegendItem extends StatelessWidget {
  const _DirectionLegendItem({
    required this.label,
    required this.description,
    required this.kind,
  });

  final String label;
  final String description;
  final _DirectionLegendKind kind;

  @override
  Widget build(BuildContext context) {
    final symbol = CustomPaint(
      size: const Size(24, 24),
      painter: _DirectionLegendPainter(kind),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(label: '$label, $description', child: symbol),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Passive diagnostics for the stock composition.
///
/// The callback is isolated in this leaf widget and refreshes at most twice per
/// second, so collecting frame timings never rebuilds a chart participant.
class _StockPerformancePanel extends StatefulWidget {
  const _StockPerformancePanel({
    required this.activeChartCount,
    required this.sourceSessionCount,
    required this.timeDomain,
    required this.timeSpacing,
    required this.viewportListenable,
  });

  final int activeChartCount;
  final int sourceSessionCount;
  final FinancialTimeDomain timeDomain;
  final FinancialTimeSpacing timeSpacing;
  final ValueListenable<ChartXViewport?> viewportListenable;

  @override
  State<_StockPerformancePanel> createState() => _StockPerformancePanelState();
}

class _StockPerformancePanelState extends State<_StockPerformancePanel> {
  static const _sampleLimit = 180;
  static const _slowFrame = Duration(microseconds: 16667);

  final List<FrameTiming> _timings = [];
  DateTime _lastRefresh = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
  }

  void _recordTimings(List<FrameTiming> timings) {
    if (!mounted || timings.isEmpty) return;
    _timings.addAll(timings);
    if (_timings.length > _sampleLimit) {
      _timings.removeRange(0, _timings.length - _sampleLimit);
    }
    final now = DateTime.now();
    if (now.difference(_lastRefresh) >= const Duration(milliseconds: 500)) {
      _lastRefresh = now;
      setState(() {});
    }
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChartXViewport?>(
      valueListenable: widget.viewportListenable,
      builder: (context, viewport, _) {
        final visibleSessions = viewport == null
            ? widget.sourceSessionCount
            : widget.timeDomain.nearestIndex(viewport.max, widget.timeSpacing) -
                  widget.timeDomain.nearestIndex(
                    viewport.min,
                    widget.timeSpacing,
                  ) +
                  1;
        final slowFrames = _timings
            .where((timing) => timing.totalSpan > _slowFrame)
            .length;
        return Semantics(
          container: true,
          label:
              'Stock composition performance. ${widget.activeChartCount} active charts, '
              '$visibleSessions visible sessions, ${_timings.length} frame samples.',
          child: Card(
            key: const ValueKey('candlestick-stock-performance'),
            margin: EdgeInsets.zero,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.speed_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Live composition measurements',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      IconButton(
                        key: const ValueKey(
                          'reset-candlestick-stock-performance',
                        ),
                        tooltip: 'Reset frame samples',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(_timings.clear),
                        icon: const Icon(Icons.restart_alt, size: 18),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _PerformanceMetric(
                            label: 'Active charts',
                            value: '${widget.activeChartCount}',
                          ),
                          _PerformanceMetric(
                            label: 'Source sessions',
                            value: '${widget.sourceSessionCount}',
                          ),
                          _PerformanceMetric(
                            label: 'Visible sessions',
                            value: '$visibleSessions',
                          ),
                          _PerformanceMetric(
                            label: 'Frame samples',
                            value: '${_timings.length}',
                          ),
                          _PerformanceMetric(
                            label: 'p95 build',
                            value: _formatMs(
                              _percentile(
                                _timings.map((timing) => timing.buildDuration),
                              ),
                            ),
                          ),
                          _PerformanceMetric(
                            label: 'p95 raster',
                            value: _formatMs(
                              _percentile(
                                _timings.map((timing) => timing.rasterDuration),
                              ),
                            ),
                          ),
                          _PerformanceMetric(
                            label: 'Over 16.7ms',
                            value: '$slowFrames / ${_timings.length}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  double? _percentile(Iterable<Duration> durations) {
    final values = durations.map((value) => value.inMicroseconds).toList()
      ..sort();
    if (values.isEmpty) return null;
    return values[((values.length - 1) * .95).ceil()] / 1000;
  }

  String _formatMs(double? value) {
    if (value == null) return '—';
    if (value < .1) return '<0.1ms';
    return '${value.toStringAsFixed(1)}ms';
  }
}

class _PerformanceMetric extends StatelessWidget {
  const _PerformanceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value  ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: label),
          ],
        ),
        style: theme.textTheme.labelSmall,
      ),
    );
  }
}

class _DirectionLegendPainter extends CustomPainter {
  const _DirectionLegendPainter(this.kind);

  final _DirectionLegendKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (kind == _DirectionLegendKind.average) {
      canvas.drawLine(
        Offset(2, center.dy),
        Offset(size.width - 2, center.dy),
        Paint()
          ..color = const Color(0xFF6366F1)
          ..strokeWidth = 2,
      );
      return;
    }
    final color = switch (kind) {
      _DirectionLegendKind.hollow => const Color(0xFF0F766E),
      _DirectionLegendKind.filled => const Color(0xFFB91C1C),
      _DirectionLegendKind.doji => const Color(0xFF475569),
      _DirectionLegendKind.average => const Color(0xFF6366F1),
    };
    canvas.drawLine(
      Offset(center.dx, 2),
      Offset(center.dx, size.height - 2),
      Paint()
        ..color = color
        ..strokeWidth = 1,
    );
    final body = kind == _DirectionLegendKind.doji
        ? Rect.fromCenter(center: center, width: 14, height: 2)
        : Rect.fromCenter(center: center, width: 10, height: 14);
    if (kind == _DirectionLegendKind.filled ||
        kind == _DirectionLegendKind.doji) {
      canvas.drawRect(body, Paint()..color = color);
    } else {
      canvas.drawRect(
        body,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DirectionLegendPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

enum _CandlestickShowcaseMode { workbench, stock }

enum _StockRangePreset {
  oneMonth,
  threeMonths,
  sixMonths,
  yearToDate,
  oneYear,
  all,
  custom,
}

List<CandlestickDataPoint> _buildStockCandles() {
  final candles = <CandlestickDataPoint>[];
  var date = DateTime.utc(2024, 12, 2);
  var previousClose = 186.0;
  while (candles.length < 420) {
    if (date.weekday <= DateTime.friday) {
      final index = candles.length;
      final trend = index * .085;
      final cycle = math.sin(index * .081) * 9 + math.cos(index * .023) * 5;
      final open = previousClose + math.sin(index * .73) * 2.1;
      var close = 186 + trend + cycle + math.sin(index * .31) * 2.4;
      if (index % 67 == 0) close = open;
      final high = math.max(open, close) + 1.4 + (index % 5) * .45;
      final low = math.min(open, close) - 1.2 - (index % 4) * .4;
      candles.add(
        CandlestickDataPoint.atTime(
          timestamp: date,
          open: open,
          high: high,
          low: low,
          close: close,
          label: '${_monthNames[date.month - 1]} ${date.day}',
          metadata: {'volumeMillions': 18 + (index % 13) * 2.75},
        ),
      );
      previousClose = close;
    }
    date = date.add(const Duration(days: 1));
  }
  return List.unmodifiable(candles);
}

List<CandlestickDataPoint> _buildCandles() {
  final start = DateTime.utc(2026, 5, 4);
  var previousClose = 228.0;
  return List<CandlestickDataPoint>.generate(32, (index) {
    final drift = math.sin(index * 0.62) * 3.6 + math.cos(index * 0.19) * 1.8;
    final open = previousClose + math.sin(index * 1.13) * 1.7;
    var close = open + drift;
    if (index == 14 || index == 25) close = open;
    final high = math.max(open, close) + 2.2 + (index % 4) * 0.55;
    final low = math.min(open, close) - 1.8 - (index % 3) * 0.65;
    final timestamp = start.add(Duration(days: index + (index ~/ 5) * 2));
    previousClose = close;
    return CandlestickDataPoint(
      x: index.toDouble(),
      open: open,
      high: high,
      low: low,
      close: close,
      timestamp: timestamp,
      label: '${_monthNames[timestamp.month - 1]} ${timestamp.day}',
    );
  }, growable: false);
}

List<ChartDataPoint> _movingAverage(
  List<CandlestickDataPoint> candles,
  int window,
) => [
  for (var index = window - 1; index < candles.length; index++)
    ChartDataPoint(
      x: candles[index].x,
      y:
          candles
              .sublist(index - window + 1, index + 1)
              .fold<double>(0, (sum, point) => sum + point.close) /
          window,
    ),
];

const _monthNames = [
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

const _stockCompositionSnippet = '''
final viewport = ChartInteractionGroupController();

// Range buttons and navigator handles issue one host-owned command.
viewport.setViewport(ChartXViewport(min: rangeStart, max: rangeEnd));

BravenChartPlus(
  interactionGroupController: viewport,
  series: [CandlestickChartSeries(id: 'price', points: candles)],
);
BravenChartPlus(
  interactionGroupController: viewport,
  series: [
    BarChartSeries(id: 'volume', points: volume, barWidthPercent: .72),
  ],
);

ValueListenableBuilder<ChartXViewport?>(
  valueListenable: viewport.viewportListenable,
  builder: (context, visible, _) => BravenChartPlus(
    interactionGroupController: viewport,
    interactionGroupOptions: const ChartInteractionGroupOptions(
      synchronizeViewport: false,
    ),
    series: [AreaChartSeries(id: 'navigator', points: closes)],
    annotations: visible == null
        ? const []
        : [
            RangeAnnotation(
              id: 'navigator-window',
              startX: visible.min,
              endX: visible.max,
            ),
          ],
  ),
);
''';
