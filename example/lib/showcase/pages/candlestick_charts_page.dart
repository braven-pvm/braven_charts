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
    const ChartOptions(showLegend: true),
  );
  final BravenChartController _chartController = BravenChartController();
  final ChartInteractionGroupController _stockGroupController =
      ChartInteractionGroupController();
  late final AnnotationController _stockNavigatorAnnotationController;
  late List<CandlestickDataPoint> _candles;
  late FinancialTimeDomain _timeDomain;
  late final List<CandlestickDataPoint> _densityCandles;
  late final FinancialTimeDomain _densityTimeDomain;
  late final List<CandlestickDataPoint> _stockCandles;
  late final FinancialTimeDomain _stockTimeDomain;

  CandlestickBodyFillMode _bodyFillMode = CandlestickBodyFillMode.hollowRising;
  double _bodyWidthFactor = 0.7;
  double _minBodyWidth = 1;
  double _maxBodyWidth = 18;
  double _bodyBorderWidth = 1;
  double _wickWidth = 1;
  double _cornerRadius = 1;
  double _minimumBodyHeight = 1;
  bool _showBodyBorder = true;
  bool _showWicks = true;
  bool _showCloseAverage = true;
  bool _showDirectionLegend = true;
  int _averageWindow = 5;
  double _averageStrokeWidth = 1.6;
  Color _averageColor = const Color(0xFF6366F1);
  bool _trackingEnabled = true;
  bool _showTrackingTooltip = true;
  bool _showPointTooltip = true;
  bool _showCoordinateLabels = true;
  bool _showIntersectionMarkers = true;
  double _intersectionMarkerRadius = 4;
  double _crosshairLineWidth = 1;
  bool _crosshairDashed = false;
  bool _selectionEnabled = true;
  bool _keyboardEnabled = true;
  bool _showFocusBorder = true;
  bool _animateUpdates = true;
  bool _animateEntrance = true;
  double _entranceStagger = .85;
  bool _useDensityStressData = false;
  bool _densityGroupingEnabled = false;
  double _targetGroupWidth = 5;
  int _minimumPointsPerGroup = 2;
  FinancialTimeSpacing _timeSpacing = FinancialTimeSpacing.ordinal;
  _CandlestickExample _selectedExample = _CandlestickExample.priceAction;
  _CandlestickPalette _candlePalette = _CandlestickPalette.theme;
  _GapFrequency _gapFrequency = _GapFrequency.occasional;
  int _sessionCount = 32;
  double _rangeScale = 1;
  double _trendBias = 0;
  LegendPosition _legendPosition = LegendPosition.topRight;
  bool _legendDraggable = true;
  YAxisPosition _yAxisPosition = YAxisPosition.left;
  int _xTickCount = 8;
  bool _showXAxisLabels = true;
  bool _showYAxisLabels = true;
  int _revisionStep = 0;
  int? _activeCandleIndex;
  _CandlestickShowcaseMode _showcaseMode = _CandlestickShowcaseMode.workbench;
  _StockRangePreset _stockRange = _StockRangePreset.threeMonths;
  FinancialTimeSpacing _stockTimeSpacing = FinancialTimeSpacing.ordinal;
  bool _showVolumePane = true;
  bool _applyingStockNavigatorPreview = false;

  @override
  void initState() {
    super.initState();
    _candles = _buildCandles();
    _timeDomain = FinancialTimeDomain(
      _candles.map((point) => point.timestamp!),
    );
    _densityCandles = _buildDensityCandles();
    _densityTimeDomain = FinancialTimeDomain(
      _densityCandles.map((point) => point.timestamp!),
    );
    _stockCandles = _buildStockCandles();
    _stockTimeDomain = FinancialTimeDomain(
      _stockCandles.map((point) => point.timestamp!),
    );
    final initialStockViewport = _stockViewportFor(_stockRange);
    _stockNavigatorAnnotationController = AnnotationController(
      initialAnnotations: [_stockNavigatorWindow(initialStockViewport)],
    )..selectAnnotation(_stockNavigatorWindowId);
    _stockGroupController.viewportListenable.addListener(
      _syncStockNavigatorWindow,
    );
    _stockGroupController.setViewport(initialStockViewport);
  }

  @override
  void dispose() {
    _stockGroupController.viewportListenable.removeListener(
      _syncStockNavigatorWindow,
    );
    _stockNavigatorAnnotationController.dispose();
    _optionsController.dispose();
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
          if (!_useDensityStressData)
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
                ? (compact ? 2060.0 : 1360.0)
                : (compact ? 1320.0 : 960.0),
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
                if (_showcaseMode == _CandlestickShowcaseMode.workbench &&
                    _showDirectionLegend) ...[
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
        : _activeWorkbenchCandles;
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
                    'Choose a candlestick example',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _FamilyBadge(compact: compact),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              key: const ValueKey('candlestick-surface-selector'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final example in _CandlestickExample.values)
                  ChoiceChip(
                    key: ValueKey('candlestick-example-${example.name}'),
                    avatar: Icon(_exampleIcon(example), size: 18),
                    label: Text(_exampleLabel(example)),
                    selected: _selectedExample == example,
                    onSelected: (_) => _applyExample(example),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _exampleDescription,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildStockComposition({required bool compact}) => ListenableBuilder(
    listenable: _optionsController,
    builder: (context, _) {
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
    },
  );

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
        densityGrouping: _densityGrouping,
      ),
      if (_showCloseAverage)
        LineChartSeries(
          id: 'market-average',
          name: '$_averageWindow-session average',
          points: _movingAverage(candles, _averageWindow),
          color: _averageColor,
          interpolation: LineInterpolation.monotone,
          strokeWidth: _averageStrokeWidth,
        ),
    ],
    theme: _effectiveChartTheme(),
    showLegend: _optionsController.options.showLegend,
    legendStyle: _effectiveChartTheme().legendStyle,
    showXScrollbar: _optionsController.options.showXScrollbar,
    showYScrollbar: _optionsController.options.showYScrollbar,
    grid: GridConfig(
      horizontal: _optionsController.options.showGrid,
      vertical: false,
    ),
    xAxisConfig: XAxisConfig(
      showAxisLine: _optionsController.options.showAxisLines,
      tickCount: compact ? 4 : 8,
      labelFormatter: (value) => _formatStockSession(value, candles),
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.right,
      label: 'Price',
      unit: 'USD',
    ),
    interactionConfig: InteractionConfig(
      enableZoom: _optionsController.options.enableZoom,
      enablePan: _optionsController.options.enablePan,
      showXScrollbar: _optionsController.options.showXScrollbar,
      showYScrollbar: _optionsController.options.showYScrollbar,
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
                    ? _effectiveChartTheme()
                          .candlestickTheme
                          .fallingBodyFillColor
                    : _effectiveChartTheme().candlestickTheme.risingBorderColor,
              ),
            ),
        ],
        barWidthPercent: .72,
        barStyle: const BarChartStyle(cornerRadius: 1),
      ),
    ],
    theme: _effectiveChartTheme(),
    showLegend: false,
    grid: GridConfig(
      horizontal: _optionsController.options.showGrid,
      vertical: false,
    ),
    xAxisConfig: XAxisConfig(
      showAxisLine: _optionsController.options.showAxisLines,
      showTickLabels: false,
      tickCount: compact ? 4 : 8,
    ),
    yAxis: YAxisConfig(
      position: YAxisPosition.right,
      label: 'Volume',
      unit: 'M',
      tickCount: 3,
    ),
    interactionConfig: InteractionConfig(
      enableZoom: _optionsController.options.enableZoom,
      enablePan: _optionsController.options.enablePan,
      crosshair: CrosshairConfig(
        enabled: _trackingEnabled,
        mode: CrosshairMode.vertical,
        displayMode: CrosshairDisplayMode.tracking,
        showTrackingTooltip: _showTrackingTooltip,
      ),
      tooltip: const TooltipConfig(enabled: true),
    ),
  );

  Widget _buildStockNavigator(
    List<CandlestickDataPoint> candles, {
    required bool compact,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: BravenChartPlus(
          key: const ValueKey('candlestick-stock-navigator'),
          interactionGroupController: _stockGroupController,
          interactionGroupOptions: const ChartInteractionGroupOptions(
            synchronizeCursor: false,
            synchronizeViewport: false,
          ),
          annotationController: _stockNavigatorAnnotationController,
          persistentRangeAnnotationHandles: true,
          onAnnotationDragUpdate: _handleStockNavigatorWindowPreview,
          onAnnotationDragged: _handleStockNavigatorWindowChanged,
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
          theme: _effectiveChartTheme(),
          showLegend: false,
          grid: const GridConfig(horizontal: false, vertical: false),
          xAxisConfig: XAxisConfig(
            showAxisLine: _optionsController.options.showAxisLines,
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
            crosshair: CrosshairConfig(enabled: false),
            tooltip: TooltipConfig(enabled: false),
          ),
        ),
      ),
      const SizedBox(height: 4),
      const Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.drag_indicator, size: 14),
          SizedBox(width: 4),
          Text('Drag window to pan · drag either edge to zoom'),
        ],
      ),
    ],
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

  RangeAnnotation _stockNavigatorWindow(ChartXViewport viewport) =>
      RangeAnnotation(
        id: _stockNavigatorWindowId,
        startX: viewport.min,
        endX: viewport.max,
        fillColor: const Color(0x243B82F6),
        borderColor: const Color(0xCC3B82F6),
        allowDragging: true,
        allowEditing: false,
        snapToValue: true,
        snapTolerance: .02,
      );

  void _syncStockNavigatorWindow() {
    if (_applyingStockNavigatorPreview) return;
    final viewport = _stockGroupController.viewport;
    if (viewport == null) return;
    final current = _stockNavigatorAnnotationController.getAnnotation(
      _stockNavigatorWindowId,
    );
    if (current is RangeAnnotation &&
        current.startX == viewport.min &&
        current.endX == viewport.max) {
      return;
    }
    _stockNavigatorAnnotationController.updateAnnotation(
      _stockNavigatorWindowId,
      _stockNavigatorWindow(viewport),
    );
    if (_stockNavigatorAnnotationController.selectedAnnotationId !=
        _stockNavigatorWindowId) {
      _stockNavigatorAnnotationController.selectAnnotation(
        _stockNavigatorWindowId,
      );
    }
  }

  void _handleStockNavigatorWindowChanged(
    ChartAnnotation annotation,
    Offset _,
  ) {
    _applyStockNavigatorWindow(annotation, commitPresetState: true);
    // The final snapped viewport can equal the latest live preview, in which
    // case the group does not notify its listeners again. Commit the window
    // annotation explicitly once the gesture ends.
    _syncStockNavigatorWindow();
  }

  void _handleStockNavigatorWindowPreview(
    ChartAnnotation annotation,
    Offset _,
  ) {
    _applyingStockNavigatorPreview = true;
    try {
      _applyStockNavigatorWindow(annotation, commitPresetState: false);
    } finally {
      _applyingStockNavigatorPreview = false;
    }
  }

  void _applyStockNavigatorWindow(
    ChartAnnotation annotation, {
    required bool commitPresetState,
  }) {
    if (annotation is! RangeAnnotation ||
        annotation.id != _stockNavigatorWindowId ||
        annotation.startX == null ||
        annotation.endX == null) {
      return;
    }
    final domainMin = _stockTimeDomain.xAt(0, _stockTimeSpacing);
    final domainMax = _stockTimeDomain.xAt(
      _stockCandles.length - 1,
      _stockTimeSpacing,
    );
    var proposedMin = annotation.startX!.clamp(domainMin, domainMax).toDouble();
    var proposedMax = annotation.endX!.clamp(domainMin, domainMax).toDouble();
    final current = _stockGroupController.viewport;
    if (current != null) {
      final currentWidth = current.max - current.min;
      final proposedWidth = annotation.endX! - annotation.startX!;
      final isWindowMove =
          (proposedWidth - currentWidth).abs() <= currentWidth * .01;
      if (isWindowMove && annotation.startX! < domainMin) {
        proposedMin = domainMin;
        proposedMax = math.min(domainMax, domainMin + currentWidth);
      } else if (isWindowMove && annotation.endX! > domainMax) {
        proposedMax = domainMax;
        proposedMin = math.max(domainMin, domainMax - currentWidth);
      }
    }
    var start = _stockTimeDomain.nearestIndex(
      math.min(proposedMin, proposedMax),
      _stockTimeSpacing,
    );
    var end = _stockTimeDomain.nearestIndex(
      math.max(proposedMin, proposedMax),
      _stockTimeSpacing,
    );
    if (start == end) {
      if (end < _stockCandles.length - 1) {
        end++;
      } else {
        start--;
      }
    }
    if (commitPresetState && _stockRange != _StockRangePreset.custom) {
      setState(() => _stockRange = _StockRangePreset.custom);
    }
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
          title: _useDensityStressData
              ? '2,000-session density stress'
              : _exampleChartTitle,
          subtitle: active == null
              ? _useDensityStressData
                    ? '${_densityGroupingEnabled ? 'Grouped render' : 'Raw render'} · Data and CSV retain 2,000 source candles'
                    : '${displayCandles.length} sessions · ${_gapFrequency.label.toLowerCase()} gaps · ${_rangeScale.toStringAsFixed(1)}× range'
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
    theme: _effectiveChartTheme(options),
    showLegend: options.showLegend,
    legendStyle: _effectiveChartTheme(options).legendStyle.copyWith(
      position: _legendPosition,
      allowDragging: _legendDraggable,
    ),
    showXScrollbar: options.showXScrollbar,
    showYScrollbar: options.showYScrollbar,
    grid: GridConfig(horizontal: options.showGrid, vertical: options.showGrid),
    xAxisConfig: XAxisConfig(
      label: _timeSpacing == FinancialTimeSpacing.ordinal
          ? 'Trading session'
          : 'Elapsed date',
      showAxisLine: options.showAxisLines,
      tickCount: compact ? math.min(5, _xTickCount) : _xTickCount,
      showTickLabels: _showXAxisLabels,
      labelFormatter: (value) => _formatSession(value, displayCandles),
    ),
    yAxis: YAxisConfig(
      position: _yAxisPosition,
      label: 'Price',
      unit: 'USD',
      showAxisLine: options.showAxisLines,
      showTickLabels: _showYAxisLabels,
    ),
    interactionConfig: InteractionConfig(
      enableZoom: options.enableZoom,
      enablePan: options.enablePan,
      enableSelection: _selectionEnabled,
      showFocusBorder: _showFocusBorder,
      showXScrollbar: options.showXScrollbar,
      showYScrollbar: options.showYScrollbar,
      crosshair: CrosshairConfig(
        enabled: _trackingEnabled,
        mode: CrosshairMode.vertical,
        displayMode: CrosshairDisplayMode.tracking,
        interpolateValues: false,
        showTrackingTooltip: _showTrackingTooltip,
        showIntersectionMarkers: _showIntersectionMarkers,
        intersectionMarkerRadius: _intersectionMarkerRadius,
        showCoordinateLabels: _showCoordinateLabels,
        style: CrosshairStyle(
          lineWidth: _crosshairLineWidth,
          dashPattern: _crosshairDashed ? const [6, 4] : null,
        ),
      ),
      tooltip: TooltipConfig(enabled: _showPointTooltip),
      keyboard: KeyboardConfig(enabled: _keyboardEnabled),
    ),
  );

  ChartTheme _effectiveChartTheme([ChartOptions? options]) {
    final base =
        options?.theme ?? _optionsController.options.theme ?? ChartTheme.light;
    final candlestickTheme = switch (_candlePalette) {
      _CandlestickPalette.theme => base.candlestickTheme,
      _CandlestickPalette.market =>
        base.backgroundColor.computeLuminance() < .3
            ? CandlestickTheme.dark
            : CandlestickTheme.light,
      _CandlestickPalette.blueOrange => CandlestickTheme.colorblindFriendly,
      _CandlestickPalette.monochrome => CandlestickTheme.highContrast,
    };
    return base.copyWith(
      candlestickTheme: candlestickTheme,
      legendStyle: base.legendStyle.copyWith(
        position: _legendPosition,
        allowDragging: _legendDraggable,
      ),
    );
  }

  List<CandlestickDataPoint> get _displayCandles => [
    for (var index = 0; index < _activeWorkbenchCandles.length; index++)
      _activeWorkbenchCandles[index].copyWith(
        x: _activeWorkbenchTimeDomain.xAt(index, _timeSpacing),
      ),
  ];

  List<CandlestickDataPoint> get _activeWorkbenchCandles =>
      _useDensityStressData ? _densityCandles : _candles;

  FinancialTimeDomain get _activeWorkbenchTimeDomain =>
      _useDensityStressData ? _densityTimeDomain : _timeDomain;

  CandlestickDensityGrouping get _densityGrouping => CandlestickDensityGrouping(
    enabled: _densityGroupingEnabled,
    targetGroupWidth: _targetGroupWidth,
    minimumPointsPerGroup: _minimumPointsPerGroup,
  );

  List<ChartSeries> _buildSeries(List<CandlestickDataPoint> candles) {
    final averageWindow = math.min(_averageWindow, candles.length);
    return [
      CandlestickChartSeries(
        id: 'reference-ohlc',
        name: 'Price',
        unit: 'USD',
        points: candles,
        candlestickStyle: CandlestickChartStyle(
          bodyFillMode: _bodyFillMode,
          bodyWidthFactor: _bodyWidthFactor,
          minBodyWidth: _minBodyWidth,
          maxBodyWidth: _maxBodyWidth,
          bodyBorderWidth: _bodyBorderWidth,
          wickWidth: _wickWidth,
          showBodyBorder: _showBodyBorder,
          showWicks: _showWicks,
          bodyCornerRadius: _cornerRadius,
          minimumBodyHeight: _minimumBodyHeight,
        ),
        animation: CandlestickAnimationStyle(
          mode: _animateEntrance
              ? CandlestickAnimationMode.reveal
              : CandlestickAnimationMode.none,
          staggerFraction: _entranceStagger,
          dataUpdateMode: _animateUpdates
              ? CandlestickDataUpdateAnimationMode.interpolate
              : CandlestickDataUpdateAnimationMode.none,
        ),
        densityGrouping: _densityGrouping,
      ),
      if (_showCloseAverage)
        LineChartSeries(
          id: 'close-average',
          name: '$averageWindow-session close average',
          points: _movingAverage(candles, averageWindow),
          color: _averageColor,
          interpolation: LineInterpolation.monotone,
          strokeWidth: _averageStrokeWidth,
        ),
    ];
  }

  List<Widget> _buildOptions() => [
    if (_showcaseMode == _CandlestickShowcaseMode.workbench)
      OptionSection(
        title: 'Example data',
        icon: Icons.dataset_outlined,
        children: [
          if (!_useDensityStressData) ...[
            IntSliderOption(
              key: const ValueKey('candlestick-session-count'),
              label: 'Visible sessions',
              value: _sessionCount,
              min: 12,
              max: 120,
              suffix: 'candles',
              onChanged: (value) => setState(() {
                _sessionCount = value;
                _regenerateWorkbenchData();
              }),
            ),
            SliderOption(
              key: const ValueKey('candlestick-range-scale'),
              label: 'Price range',
              value: _rangeScale,
              min: .4,
              max: 2.8,
              divisions: 24,
              suffix: '×',
              onChanged: (value) => setState(() {
                _rangeScale = value;
                _regenerateWorkbenchData();
              }),
            ),
            SliderOption(
              key: const ValueKey('candlestick-trend-bias'),
              label: 'Trend bias',
              value: _trendBias,
              min: -1.2,
              max: 1.2,
              divisions: 24,
              suffix: 'USD/session',
              onChanged: (value) => setState(() {
                _trendBias = value;
                _regenerateWorkbenchData();
              }),
            ),
            EnumOption<_GapFrequency>(
              key: const ValueKey('candlestick-gap-frequency'),
              label: 'Opening gaps',
              subtitle: 'Vary discontinuities between consecutive sessions',
              value: _gapFrequency,
              values: _GapFrequency.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) => setState(() {
                _gapFrequency = value;
                _regenerateWorkbenchData();
              }),
            ),
          ],
          BoolOption(
            key: const ValueKey('candlestick-density-stress-data'),
            label: 'Use 2,000 source candles',
            subtitle: 'Stress the renderer while Data and CSV stay raw',
            value: _useDensityStressData,
            onChanged: (value) => setState(() {
              _useDensityStressData = value;
              _activeCandleIndex = null;
              if (value) _densityGroupingEnabled = true;
            }),
          ),
        ],
      ),
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
        BoolOption(
          key: const ValueKey('candlestick-point-tooltip'),
          label: 'Show point tooltip',
          subtitle: 'Display one candle tooltip on hover or selection',
          value: _showPointTooltip,
          onChanged: (value) => setState(() => _showPointTooltip = value),
        ),
        if (_showcaseMode == _CandlestickShowcaseMode.workbench) ...[
          EnumOption<FinancialTimeSpacing>(
            key: const ValueKey('candlestick-time-spacing'),
            label: 'Time spacing',
            subtitle:
                'Compare equal sessions with real weekend and holiday gaps',
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
          BoolOption(
            key: const ValueKey('candlestick-animate-entrance'),
            label: 'Animate entrance',
            subtitle: 'Reveal candles in session order',
            value: _animateEntrance,
            onChanged: (value) => setState(() => _animateEntrance = value),
          ),
          if (_animateEntrance)
            SliderOption(
              key: const ValueKey('candlestick-entrance-stagger'),
              label: 'Entrance stagger',
              value: _entranceStagger,
              min: 0,
              max: 1,
              divisions: 20,
              suffix: 'timeline',
              onChanged: (value) => setState(() => _entranceStagger = value),
            ),
        ],
      ],
    ),
    OptionSection(
      title: 'Interaction detail',
      icon: Icons.ads_click_outlined,
      children: [
        BoolOption(
          key: const ValueKey('candlestick-coordinate-labels'),
          label: 'Show axis values',
          value: _showCoordinateLabels,
          onChanged: (value) => setState(() => _showCoordinateLabels = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-intersection-markers'),
          label: 'Show tracking marker',
          value: _showIntersectionMarkers,
          onChanged: (value) =>
              setState(() => _showIntersectionMarkers = value),
        ),
        if (_showIntersectionMarkers)
          SliderOption(
            key: const ValueKey('candlestick-marker-radius'),
            label: 'Tracking marker radius',
            value: _intersectionMarkerRadius,
            min: 2,
            max: 10,
            divisions: 8,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _intersectionMarkerRadius = value),
          ),
        SliderOption(
          key: const ValueKey('candlestick-crosshair-width'),
          label: 'Crosshair width',
          value: _crosshairLineWidth,
          min: .5,
          max: 4,
          divisions: 14,
          suffix: 'px',
          onChanged: (value) => setState(() => _crosshairLineWidth = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-crosshair-dashed'),
          label: 'Use dashed crosshair',
          value: _crosshairDashed,
          onChanged: (value) => setState(() => _crosshairDashed = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-selection-enabled'),
          label: 'Enable candle selection',
          value: _selectionEnabled,
          onChanged: (value) => setState(() => _selectionEnabled = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-keyboard-enabled'),
          label: 'Enable keyboard navigation',
          value: _keyboardEnabled,
          onChanged: (value) => setState(() => _keyboardEnabled = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-focus-border'),
          label: 'Show keyboard focus border',
          value: _showFocusBorder,
          onChanged: (value) => setState(() => _showFocusBorder = value),
        ),
      ],
    ),
    if (_showcaseMode == _CandlestickShowcaseMode.workbench)
      OptionSection(
        title: 'Data density',
        icon: Icons.density_medium,
        children: [
          BoolOption(
            key: const ValueKey('candlestick-density-grouping'),
            label: 'Group dense candles',
            subtitle: 'First open, maximum high, minimum low, and last close',
            value: _densityGroupingEnabled,
            onChanged: (value) =>
                setState(() => _densityGroupingEnabled = value),
          ),
          if (_densityGroupingEnabled) ...[
            SliderOption(
              key: const ValueKey('candlestick-target-group-width'),
              label: 'Target group width',
              value: _targetGroupWidth,
              min: 3,
              max: 12,
              divisions: 18,
              suffix: 'px',
              onChanged: (value) => setState(() => _targetGroupWidth = value),
            ),
            SliderOption(
              key: const ValueKey('candlestick-minimum-group-size'),
              label: 'Minimum group size',
              value: _minimumPointsPerGroup.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              suffix: ' candles',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _minimumPointsPerGroup = value.round()),
            ),
          ],
        ],
      ),
    OptionSection(
      title: 'Candle geometry',
      icon: Icons.candlestick_chart,
      children: [
        EnumOption<_CandlestickPalette>(
          key: const ValueKey('candlestick-palette'),
          label: 'Candle palette',
          subtitle: 'Theme defaults, market hues, accessible hues, or mono',
          value: _candlePalette,
          values: _CandlestickPalette.values,
          labelBuilder: (value) => value.label,
          onChanged: (value) => setState(() => _candlePalette = value),
        ),
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
          key: const ValueKey('candlestick-min-width'),
          label: 'Minimum body width',
          value: _minBodyWidth,
          min: .5,
          max: 6,
          divisions: 11,
          suffix: 'px',
          onChanged: (value) => setState(() => _minBodyWidth = value),
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
      title: 'Axes and labels',
      icon: Icons.straighten_outlined,
      children: [
        EnumOption<YAxisPosition>(
          key: const ValueKey('candlestick-y-axis-position'),
          label: 'Price axis position',
          value: _yAxisPosition,
          values: const [
            YAxisPosition.left,
            YAxisPosition.right,
            YAxisPosition.hidden,
          ],
          labelBuilder: (value) {
            if (value == YAxisPosition.left) return 'Left';
            if (value == YAxisPosition.hidden) return 'Hidden';
            return 'Right';
          },
          onChanged: (value) => setState(() => _yAxisPosition = value),
        ),
        IntSliderOption(
          key: const ValueKey('candlestick-x-tick-count'),
          label: 'X-axis tick count',
          value: _xTickCount,
          min: 3,
          max: 12,
          suffix: 'ticks',
          onChanged: (value) => setState(() => _xTickCount = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-x-labels'),
          label: 'Show X-axis labels',
          value: _showXAxisLabels,
          onChanged: (value) => setState(() => _showXAxisLabels = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-y-labels'),
          label: 'Show Y-axis labels',
          value: _showYAxisLabels,
          onChanged: (value) => setState(() => _showYAxisLabels = value),
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
        if (_showCloseAverage) ...[
          SliderOption(
            key: const ValueKey('candlestick-average-window'),
            label: 'Average window',
            value: _averageWindow.toDouble(),
            min: 3,
            max: 24,
            divisions: 21,
            suffix: 'sessions',
            decimalPlaces: 0,
            onChanged: (value) =>
                setState(() => _averageWindow = value.round()),
          ),
          SliderOption(
            key: const ValueKey('candlestick-average-width'),
            label: 'Average stroke width',
            value: _averageStrokeWidth,
            min: .8,
            max: 4,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) => setState(() => _averageStrokeWidth = value),
          ),
          ColorOption(
            key: const ValueKey('candlestick-average-color'),
            label: 'Average colour',
            value: _averageColor,
            colors: const [
              Color(0xFF6366F1),
              Color(0xFF0EA5E9),
              Color(0xFFF59E0B),
              Color(0xFFEC4899),
              Color(0xFF111827),
            ],
            onChanged: (value) => setState(() => _averageColor = value),
          ),
        ],
      ],
    ),
    OptionSection(
      title: 'Legends',
      icon: Icons.view_list_outlined,
      children: [
        BoolOption(
          key: const ValueKey('candlestick-series-legend'),
          label: 'Show series legend',
          subtitle: 'Identify the OHLC series and optional moving average',
          value: _optionsController.showLegend,
          onChanged: (value) {
            _optionsController.showLegend = value;
            setState(() {});
          },
        ),
        BoolOption(
          key: const ValueKey('candlestick-direction-key'),
          label: 'Show direction key',
          subtitle: 'Explain rising, falling, doji, and overlay marks',
          value: _showDirectionLegend,
          onChanged: (value) => setState(() => _showDirectionLegend = value),
        ),
        EnumOption<LegendPosition>(
          key: const ValueKey('candlestick-legend-position'),
          label: 'Series legend position',
          value: _legendPosition,
          values: LegendPosition.values,
          labelBuilder: _legendPositionLabel,
          onChanged: (value) => setState(() => _legendPosition = value),
        ),
        BoolOption(
          key: const ValueKey('candlestick-legend-draggable'),
          label: 'Allow legend dragging',
          value: _legendDraggable,
          onChanged: (value) => setState(() => _legendDraggable = value),
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
    final candleTheme = _effectiveChartTheme().candlestickTheme;
    return Container(
      key: const ValueKey('candlestick-direction-legend'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _DirectionLegendItem(
            label: 'Rising',
            description: _bodyFillMode == CandlestickBodyFillMode.hollowRising
                ? 'Hollow body'
                : 'Filled body',
            kind: _DirectionLegendKind.hollow,
            color: candleTheme.risingBorderColor,
            fillBody: _bodyFillMode == CandlestickBodyFillMode.filled,
          ),
          _DirectionLegendItem(
            label: 'Falling',
            description: 'Filled body',
            kind: _DirectionLegendKind.filled,
            color: candleTheme.fallingBodyFillColor,
            fillBody: true,
          ),
          _DirectionLegendItem(
            label: 'Doji',
            description: 'Open equals close',
            kind: _DirectionLegendKind.doji,
            color: candleTheme.dojiBodyFillColor,
            fillBody: true,
          ),
          if (_showCloseAverage)
            _DirectionLegendItem(
              label: 'Close average',
              description: '$_averageWindow sessions',
              kind: _DirectionLegendKind.average,
              color: _averageColor,
              fillBody: false,
            ),
        ],
      ),
    );
  }

  String _formatSession(
    double value,
    List<CandlestickDataPoint> displayCandles,
  ) {
    final index = _activeWorkbenchTimeDomain.nearestIndex(value, _timeSpacing);
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

  void _applyExample(_CandlestickExample example) {
    setState(() {
      _selectedExample = example;
      _showcaseMode = example == _CandlestickExample.stockComposition
          ? _CandlestickShowcaseMode.stock
          : _CandlestickShowcaseMode.workbench;
      _activeCandleIndex = null;

      switch (example) {
        case _CandlestickExample.priceAction:
          _sessionCount = 32;
          _rangeScale = 1;
          _trendBias = 0;
          _gapFrequency = _GapFrequency.occasional;
          _useDensityStressData = false;
          _densityGroupingEnabled = false;
          _showCloseAverage = true;
          _averageWindow = 5;
          break;
        case _CandlestickExample.trend:
          _sessionCount = 64;
          _rangeScale = .7;
          _trendBias = .45;
          _gapFrequency = _GapFrequency.none;
          _useDensityStressData = false;
          _densityGroupingEnabled = false;
          _showCloseAverage = true;
          _averageWindow = 10;
          break;
        case _CandlestickExample.volatility:
          _sessionCount = 72;
          _rangeScale = 2.2;
          _trendBias = 0;
          _gapFrequency = _GapFrequency.frequent;
          _useDensityStressData = false;
          _densityGroupingEnabled = false;
          _showCloseAverage = true;
          _averageWindow = 8;
          break;
        case _CandlestickExample.gapsAndDoji:
          _sessionCount = 48;
          _rangeScale = 1.25;
          _trendBias = -.08;
          _gapFrequency = _GapFrequency.frequent;
          _useDensityStressData = false;
          _densityGroupingEnabled = false;
          _showCloseAverage = false;
          break;
        case _CandlestickExample.accessible:
          _sessionCount = 40;
          _rangeScale = 1.15;
          _trendBias = .08;
          _gapFrequency = _GapFrequency.occasional;
          _useDensityStressData = false;
          _densityGroupingEnabled = false;
          _candlePalette = _CandlestickPalette.blueOrange;
          _bodyFillMode = CandlestickBodyFillMode.hollowRising;
          _bodyBorderWidth = 1.8;
          _wickWidth = 1.6;
          _minimumBodyHeight = 2;
          _showCloseAverage = true;
          _averageWindow = 8;
          _showDirectionLegend = true;
          break;
        case _CandlestickExample.density:
          _useDensityStressData = true;
          _densityGroupingEnabled = true;
          _showCloseAverage = false;
          break;
        case _CandlestickExample.stockComposition:
          _showCloseAverage = true;
          _averageWindow = 20;
          break;
      }
      if (example != _CandlestickExample.density &&
          example != _CandlestickExample.stockComposition) {
        _regenerateWorkbenchData();
      }
    });
    if (example == _CandlestickExample.stockComposition) {
      _stockGroupController.setViewport(_stockViewportFor(_stockRange));
    }
  }

  void _regenerateWorkbenchData() {
    final dataProfile = switch (_selectedExample) {
      _CandlestickExample.trend => _CandlestickDataProfile.trend,
      _CandlestickExample.volatility => _CandlestickDataProfile.volatility,
      _CandlestickExample.gapsAndDoji => _CandlestickDataProfile.gapsAndDoji,
      _ => _CandlestickDataProfile.priceAction,
    };
    _candles = _buildScenarioCandles(
      profile: dataProfile,
      count: _sessionCount,
      rangeScale: _rangeScale,
      trendBias: _trendBias,
      gapFrequency: _gapFrequency,
    );
    _timeDomain = FinancialTimeDomain(
      _candles.map((point) => point.timestamp!),
    );
    _activeCandleIndex = null;
  }

  String get _exampleDescription => switch (_selectedExample) {
    _CandlestickExample.priceAction =>
      'Balanced market action with rising, falling, and doji candles.',
    _CandlestickExample.trend =>
      'A sustained advance tests dense bodies and a longer moving average.',
    _CandlestickExample.volatility =>
      'Wide bodies, long wicks, and frequent gaps stress price-range handling.',
    _CandlestickExample.gapsAndDoji =>
      'Discontinuous opens and repeated doji make direction cues explicit.',
    _CandlestickExample.accessible =>
      'Blue/orange hues, hollow rising bodies, stronger strokes, and a direction key avoid colour-only meaning.',
    _CandlestickExample.density =>
      '2,000 raw sessions demonstrate opt-in OHLC density grouping.',
    _CandlestickExample.stockComposition =>
      'Price, volume, and navigator charts share one financial time viewport.',
  };

  String get _exampleChartTitle => switch (_selectedExample) {
    _CandlestickExample.priceAction => 'Balanced price action',
    _CandlestickExample.trend => 'Advancing market trend',
    _CandlestickExample.volatility => 'High-volatility sessions',
    _CandlestickExample.gapsAndDoji => 'Opening gaps and doji',
    _CandlestickExample.accessible => 'Accessible direction cues',
    _ => 'Candlestick price action',
  };

  String _exampleLabel(_CandlestickExample example) => switch (example) {
    _CandlestickExample.priceAction => 'Price action',
    _CandlestickExample.trend => 'Trend',
    _CandlestickExample.volatility => 'Volatility',
    _CandlestickExample.gapsAndDoji => 'Gaps & doji',
    _CandlestickExample.accessible => 'Accessible',
    _CandlestickExample.density => 'Density',
    _CandlestickExample.stockComposition => 'Stock composition',
  };

  IconData _exampleIcon(_CandlestickExample example) => switch (example) {
    _CandlestickExample.priceAction => Icons.candlestick_chart,
    _CandlestickExample.trend => Icons.trending_up,
    _CandlestickExample.volatility => Icons.show_chart,
    _CandlestickExample.gapsAndDoji => Icons.space_bar,
    _CandlestickExample.accessible => Icons.accessibility_new,
    _CandlestickExample.density => Icons.density_medium,
    _CandlestickExample.stockComposition => Icons.monitor_heart_outlined,
  };

  String _legendPositionLabel(LegendPosition position) => switch (position) {
    LegendPosition.topLeft => 'Top left',
    LegendPosition.topCenter => 'Top centre',
    LegendPosition.topRight => 'Top right',
    LegendPosition.centerLeft => 'Centre left',
    LegendPosition.center => 'Centre',
    LegendPosition.centerRight => 'Centre right',
    LegendPosition.bottomLeft => 'Bottom left',
    LegendPosition.bottomCenter => 'Bottom centre',
    LegendPosition.bottomRight => 'Bottom right',
  };

  void _reset() {
    setState(() {
      _bodyFillMode = CandlestickBodyFillMode.hollowRising;
      _bodyWidthFactor = 0.7;
      _minBodyWidth = 1;
      _maxBodyWidth = 18;
      _bodyBorderWidth = 1;
      _wickWidth = 1;
      _cornerRadius = 1;
      _minimumBodyHeight = 1;
      _showBodyBorder = true;
      _showWicks = true;
      _showCloseAverage = true;
      _showDirectionLegend = true;
      _averageWindow = 5;
      _averageStrokeWidth = 1.6;
      _averageColor = const Color(0xFF6366F1);
      _trackingEnabled = true;
      _showTrackingTooltip = true;
      _showPointTooltip = true;
      _showCoordinateLabels = true;
      _showIntersectionMarkers = true;
      _intersectionMarkerRadius = 4;
      _crosshairLineWidth = 1;
      _crosshairDashed = false;
      _selectionEnabled = true;
      _keyboardEnabled = true;
      _showFocusBorder = true;
      _animateUpdates = true;
      _animateEntrance = true;
      _entranceStagger = .85;
      _useDensityStressData = false;
      _densityGroupingEnabled = false;
      _targetGroupWidth = 5;
      _minimumPointsPerGroup = 2;
      _timeSpacing = FinancialTimeSpacing.ordinal;
      _selectedExample = _CandlestickExample.priceAction;
      _candlePalette = _CandlestickPalette.theme;
      _gapFrequency = _GapFrequency.occasional;
      _sessionCount = 32;
      _rangeScale = 1;
      _trendBias = 0;
      _legendPosition = LegendPosition.topRight;
      _legendDraggable = true;
      _yAxisPosition = YAxisPosition.left;
      _xTickCount = 8;
      _showXAxisLabels = true;
      _showYAxisLabels = true;
      _showcaseMode = _CandlestickShowcaseMode.workbench;
      _stockTimeSpacing = FinancialTimeSpacing.ordinal;
      _stockRange = _StockRangePreset.threeMonths;
      _showVolumePane = true;
      _regenerateWorkbenchData();
      _revisionStep = 0;
      _activeCandleIndex = null;
    });
    _stockGroupController.setViewport(_stockViewportFor(_stockRange));
    _optionsController.update(const ChartOptions(showLegend: true));
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
    required this.color,
    required this.fillBody,
  });

  final String label;
  final String description;
  final _DirectionLegendKind kind;
  final Color color;
  final bool fillBody;

  @override
  Widget build(BuildContext context) {
    final symbol = CustomPaint(
      size: const Size(24, 24),
      painter: _DirectionLegendPainter(
        kind: kind,
        color: color,
        fillBody: fillBody,
      ),
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
  const _DirectionLegendPainter({
    required this.kind,
    required this.color,
    required this.fillBody,
  });

  final _DirectionLegendKind kind;
  final Color color;
  final bool fillBody;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    if (kind == _DirectionLegendKind.average) {
      canvas.drawLine(
        Offset(2, center.dy),
        Offset(size.width - 2, center.dy),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      return;
    }
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
    if (fillBody) {
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
      oldDelegate.kind != kind ||
      oldDelegate.color != color ||
      oldDelegate.fillBody != fillBody;
}

enum _CandlestickShowcaseMode { workbench, stock }

enum _CandlestickExample {
  priceAction,
  trend,
  volatility,
  gapsAndDoji,
  accessible,
  density,
  stockComposition,
}

enum _CandlestickDataProfile { priceAction, trend, volatility, gapsAndDoji }

enum _CandlestickPalette {
  theme('Theme default'),
  market('Market green / red'),
  blueOrange('Blue / orange'),
  monochrome('High-contrast mono');

  const _CandlestickPalette(this.label);

  final String label;
}

enum _GapFrequency {
  none('None'),
  occasional('Occasional'),
  frequent('Frequent');

  const _GapFrequency(this.label);

  final String label;
}

enum _StockRangePreset {
  oneMonth,
  threeMonths,
  sixMonths,
  yearToDate,
  oneYear,
  all,
  custom,
}

List<CandlestickDataPoint> _buildDensityCandles() {
  final candles = <CandlestickDataPoint>[];
  final start = DateTime.utc(2026, 1, 5, 9, 30);
  var previousClose = 132.0;
  for (var index = 0; index < 2000; index++) {
    final open = previousClose;
    final movement =
        math.sin(index * .17) * .72 +
        math.cos(index * .043) * .38 +
        math.sin(index * .011) * .24;
    final close = open + movement;
    final high = math.max(open, close) + .35 + (index % 5) * .08;
    final low = math.min(open, close) - .3 - (index % 4) * .07;
    candles.add(
      CandlestickDataPoint.atTime(
        timestamp: start.add(Duration(minutes: index * 5)),
        open: open,
        high: high,
        low: low,
        close: close,
        label: index % 250 == 0 ? 'Sample ${index + 1}' : null,
      ),
    );
    previousClose = close;
  }
  return List<CandlestickDataPoint>.unmodifiable(candles);
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
  return _buildScenarioCandles(
    profile: _CandlestickDataProfile.priceAction,
    count: 32,
    rangeScale: 1,
    trendBias: 0,
    gapFrequency: _GapFrequency.occasional,
  );
}

List<CandlestickDataPoint> _buildScenarioCandles({
  required _CandlestickDataProfile profile,
  required int count,
  required double rangeScale,
  required double trendBias,
  required _GapFrequency gapFrequency,
}) {
  final start = DateTime.utc(2026, 5, 4);
  var previousClose = 228.0;
  return List<CandlestickDataPoint>.generate(count, (index) {
    final movement = switch (profile) {
      _CandlestickDataProfile.priceAction =>
        math.sin(index * .62) * 3.6 + math.cos(index * .19) * 1.8,
      _CandlestickDataProfile.trend =>
        1.05 + math.sin(index * .41) * 1.7 + math.cos(index * .13) * .7,
      _CandlestickDataProfile.volatility =>
        math.sin(index * .83) * 4.8 + math.cos(index * .27) * 3.2,
      _CandlestickDataProfile.gapsAndDoji =>
        math.sin(index * .54) * 2.8 + math.cos(index * .21) * 1.4,
    };
    final gap = switch (gapFrequency) {
      _GapFrequency.none => 0.0,
      _GapFrequency.occasional =>
        index > 0 && index % 11 == 0
            ? math.sin(index * .71) * 4.2 * rangeScale
            : 0.0,
      _GapFrequency.frequent =>
        index > 0 && index % 5 == 0
            ? math.cos(index * .63) * 5.6 * rangeScale
            : 0.0,
    };
    final open = previousClose + gap;
    var close = open + movement * rangeScale + trendBias;
    final isDoji = switch (profile) {
      _CandlestickDataProfile.priceAction => index == 14 || index == 25,
      _CandlestickDataProfile.trend => index > 0 && index % 23 == 0,
      _CandlestickDataProfile.volatility => index > 0 && index % 29 == 0,
      _CandlestickDataProfile.gapsAndDoji => index > 0 && index % 7 == 0,
    };
    if (isDoji) close = open;
    final high = math.max(open, close) + (1.6 + (index % 4) * .55) * rangeScale;
    final low = math.min(open, close) - (1.4 + (index % 3) * .65) * rangeScale;
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
final navigatorWindow = AnnotationController(
  initialAnnotations: [
    RangeAnnotation(id: 'navigator-window', startX: rangeStart, endX: rangeEnd),
  ],
)..selectAnnotation('navigator-window');

// Period buttons and main-chart pan/zoom update the same selected window.
viewport.viewportListenable.addListener(() {
  final visible = viewport.viewport;
  if (visible == null) return;
  navigatorWindow.updateAnnotation(
    'navigator-window',
    RangeAnnotation(
      id: 'navigator-window',
      startX: visible.min,
      endX: visible.max,
    ),
  );
});

// Period buttons and navigator handles issue one host-owned command.
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

BravenChartPlus(
  interactionGroupController: viewport,
  interactionGroupOptions: const ChartInteractionGroupOptions(
    synchronizeCursor: false,
    synchronizeViewport: false,
  ),
  annotationController: navigatorWindow,
  persistentRangeAnnotationHandles: true,
  onAnnotationDragUpdate: (annotation, _) {
    if (annotation case RangeAnnotation(startX: final min?, endX: final max?)) {
      // Preview the shared viewport continuously without replacing the
      // controller-owned annotation during the active pointer gesture.
      viewport.setViewport(ChartXViewport(min: min, max: max));
    }
  },
  onAnnotationDragged: (annotation, _) {
    if (annotation case RangeAnnotation(startX: final min?, endX: final max?)) {
      viewport.setViewport(ChartXViewport(min: min, max: max));
    }
  },
  series: [AreaChartSeries(id: 'navigator', points: closes)],
);
''';

const _stockNavigatorWindowId = 'navigator-window';
