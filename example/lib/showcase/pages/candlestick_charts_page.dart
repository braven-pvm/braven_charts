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
import '../widgets/persistent_resizable_chart_panel.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

/// First-class Candlestick chart-family Workbench surface.
class CandlestickChartsPage extends StatefulWidget {
  const CandlestickChartsPage({super.key});

  @override
  State<CandlestickChartsPage> createState() => _CandlestickChartsPageState();
}

class _CandlestickChartsPageState extends State<CandlestickChartsPage> {
  // Synchronized panes map shared data X independently, so visual crosshair
  // continuity additionally requires identical horizontal plot bounds. The
  // axisless renderer keeps 10 px per side; compensate it to the fixed 64 px
  // financial-axis gutter used by the price and volume panes.
  static const double _stockAxisGutter = 64;
  static const double _stockAxislessInset = 10;
  static const double _stockOppositeGutter =
      _stockAxisGutter - _stockAxislessInset;

  static final JsonObjectValue _twoDecimalFormatter = ChartFormatterDescriptor(
    id: 'braven.number.fixed',
    arguments: {'decimals': JsonNumberValue(2)},
  ).toDocument();

  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showLegend: true),
  );
  final BravenChartController _chartController = BravenChartController();
  final ValueNotifier<CandlestickDataPoint?> _pinnedSummaryCandle =
      ValueNotifier(null);
  final ChartInteractionGroupController _stockGroupController =
      ChartInteractionGroupController();
  late final ShowcaseRandomizerController<int> _showcaseRandomizer;
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
  Color? _averageColor = const Color(0xFF6366F1);
  bool _customDirectionColors = false;
  Color? _risingBodyColor = const Color(0xFFCCFBF1);
  Color? _fallingBodyColor = const Color(0xFFEF4444);
  Color? _dojiBodyColor = const Color(0xFF64748B);
  Color? _risingBorderColor = const Color(0xFF0F766E);
  Color? _fallingBorderColor = const Color(0xFFB91C1C);
  Color? _dojiBorderColor = const Color(0xFF475569);
  Color? _risingWickColor = const Color(0xFF0F766E);
  Color? _fallingWickColor = const Color(0xFFB91C1C);
  Color? _dojiWickColor = const Color(0xFF475569);
  bool _highlightLatestCandle = false;
  Color? _highlightBodyColor = const Color(0xFFFEF08A);
  Color? _highlightBorderColor = const Color(0xFFCA8A04);
  Color? _highlightWickColor = const Color(0xFFA16207);
  bool _trackingEnabled = true;
  bool _showTrackingTooltip = true;
  bool _showPointTooltip = false;
  bool _showPinnedSummary = false;
  _PinnedSummaryPresentation _pinnedSummaryPresentation =
      _PinnedSummaryPresentation.overlay;
  _PinnedSummaryCorner _pinnedSummaryCorner = _PinnedSummaryCorner.topLeft;
  bool _pinnedSummaryDraggable = true;
  Offset _pinnedSummaryAnnotationPosition = const Offset(96, 48);
  bool _pinnedSummaryBackgroundVisible = true;
  bool _pinnedSummaryBorderVisible = true;
  Color? _pinnedSummaryBackgroundColor;
  Color? _pinnedSummaryBorderColor;
  Color? _pinnedSummaryTextColor;
  Color? _pinnedSummaryAccentColor;
  double _pinnedSummaryBackgroundOpacity = .96;
  double _pinnedSummaryBorderWidth = 1;
  double _pinnedSummaryCornerRadius = 8;
  double _pinnedSummaryPadding = 8;
  double _pinnedSummaryFontSize = 11;
  bool _showCoordinateLabels = true;
  bool _showIntersectionMarkers = true;
  double _intersectionMarkerRadius = 4;
  double _crosshairLineWidth = 1;
  bool _crosshairDashed = false;
  bool _customTrackingTheme = false;
  Color? _crosshairColor = const Color(0xFF475569);
  Color? _coordinateLabelBackgroundColor = const Color(0xFF1F2937);
  Color? _coordinateLabelTextColor = const Color(0xFFFFFFFF);
  Color? _tooltipBackgroundColor = const Color(0xF2FFFFFF);
  Color? _tooltipBorderColor = const Color(0xFF94A3B8);
  Color? _tooltipTextColor = const Color(0xFF1F2937);
  Color? _selectionColor = const Color(0xFF2563EB);
  Color? _focusColor = const Color(0xFF475569);
  double _tooltipBorderWidth = 1;
  double _tooltipCornerRadius = 6;
  double _tooltipFontSize = 12;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowsCursor = false;
  bool _selectionEnabled = true;
  bool _keyboardEnabled = true;
  bool _showFocusBorder = false;
  CandlestickDataUpdateAnimationMode _dataUpdateAnimation =
      CandlestickDataUpdateAnimationMode.interpolate;
  CandlestickAnimationMode _entranceAnimation = CandlestickAnimationMode.reveal;
  double _entranceStagger = .85;
  int _animationDurationMs = 400;
  _CandlestickMotionCurve _motionCurve = _CandlestickMotionCurve.easeInOutCubic;
  double _revisionMagnitude = 4.6;
  bool _useDensityStressData = false;
  bool _densityGroupingEnabled = false;
  double _targetGroupWidth = 5;
  int _minimumPointsPerGroup = 2;
  FinancialTimeSpacing _timeSpacing = FinancialTimeSpacing.ordinal;
  _CandlestickExample _selectedExample = _CandlestickExample.priceAction;
  _CandlestickExample _authoredExample = _CandlestickExample.priceAction;
  bool _playgroundActive = false;
  _CandlestickPalette _candlePalette = _CandlestickPalette.theme;
  _CandlestickStyleRecipe _styleRecipe = _CandlestickStyleRecipe.balanced;
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
  bool _showMarketContext = false;
  Color? _contextThresholdColor = const Color(0xFFF59E0B);
  Color? _contextWindowColor = const Color(0xFF3B82F6);
  Color? _contextEventColor = const Color(0xFF7C3AED);
  double _contextLineWidth = 1.5;
  bool _contextLineDashed = true;
  int _revisionStep = 0;
  int? _activeCandleIndex;
  _CandlestickShowcaseMode _showcaseMode = _CandlestickShowcaseMode.workbench;
  _StockRangePreset _stockRange = _StockRangePreset.threeMonths;
  FinancialTimeSpacing _stockTimeSpacing = FinancialTimeSpacing.ordinal;
  bool _showVolumePane = true;

  @override
  void initState() {
    super.initState();
    _showcaseRandomizer = ShowcaseRandomizerController<int>(
      initialSeed: 211,
      generate: (seed) => seed,
      apply: _applyRandomSeed,
    );
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
    _stockGroupController.setViewport(initialStockViewport);
  }

  @override
  void dispose() {
    _pinnedSummaryCandle.dispose();
    _showcaseRandomizer.dispose();
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
      playground: ChartPlaygroundConfig(
        active: _playgroundActive,
        optionsChildren: _buildPlaygroundOptions(),
        randomizer: _showcaseRandomizer,
      ),
      randomizerKeyPrefix: 'candlestick-randomizer',
      chart: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 600;
          final stockMode = _showcaseMode == _CandlestickShowcaseMode.stock;
          return PersistentResizableChartPanelWorkspace(
            preferenceKey: showcaseChartPanelHeightKey(compact: compact),
            minimumPanelHeight: compact ? 620 : 420,
            maximumPanelHeight: compact ? 1800 : 1400,
            initialPanelHeight: stockMode
                ? (compact ? 1600 : 1050)
                : (compact ? 980 : 680),
            scrollViewKey: const ValueKey('candlestick-showcase-scroll'),
            leading: [
              _buildReviewHeader(compact: compact),
              const SizedBox(height: 16),
            ],
            panel: stockMode
                ? _buildStockComposition(compact: compact)
                : _buildChartCard(compact: compact),
            trailing: [
              if (!stockMode && _showDirectionLegend) _buildDirectionLegend(),
            ],
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
                  ShowcaseExampleChoiceChip(
                    key: ValueKey('candlestick-example-${example.name}'),
                    label: _exampleLabel(example),
                    icon: _exampleIcon(example),
                    selected: !_playgroundActive && _selectedExample == example,
                    onSelected: () => _applyExample(example),
                  ),
                PlaygroundChoiceChip(
                  key: const ValueKey('candlestick-playground'),
                  selected: _playgroundActive,
                  onSelected: () => _setPlaygroundActive(true),
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
              child: _buildStockAxisAlignedPane(
                key: const ValueKey('candlestick-stock-price-frame'),
                axisPosition: _yAxisPosition,
                child: _buildStockPriceChart(displayCandles, compact: compact),
              ),
            ),
            if (_showVolumePane) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: compact ? 156 : 138,
                child: _buildStockAxisAlignedPane(
                  key: const ValueKey('candlestick-stock-volume-frame'),
                  axisPosition: YAxisPosition.right,
                  child: _buildStockVolumeChart(
                    displayCandles,
                    compact: compact,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: compact ? 168 : 128,
              child: _buildStockAxisAlignedPane(
                key: const ValueKey('candlestick-stock-navigator-frame'),
                child: _buildStockNavigator(displayCandles, compact: compact),
              ),
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
  }) => _buildPinnedSummaryLayer(
    candles: candles,
    title: 'Market price',
    chart: BravenChartPlus(
      key: const ValueKey('candlestick-stock-price-chart'),
      onPointHover: _handlePinnedPointHover,
      onPointTap: _handlePinnedPointTap,
      onDataXCursorChanged: (dataX) =>
          _handlePinnedDataXCursorChanged(dataX, candles),
      onAnnotationDragged: _handlePinnedSummaryAnnotationDragged,
      interactionGroupController: _stockGroupController,
      interactionGroupOptions: const ChartInteractionGroupOptions(),
      series: [
        CandlestickChartSeries(
          id: 'market-price',
          name: 'Price',
          unit: 'USD',
          points: _styledCandles(candles),
          candlestickStyle: _candlestickStyle,
          animation: _candlestickAnimation,
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
      annotations: _buildPinnedSummaryAnnotations(
        candles,
        title: 'Market price',
      ),
      theme: _effectiveChartTheme(),
      showLegend: _optionsController.options.showLegend,
      legendStyle: _effectiveChartTheme().legendStyle.copyWith(
        position: _legendPosition,
        allowDragging: _legendDraggable,
      ),
      showXScrollbar: _optionsController.options.showXScrollbar,
      showYScrollbar: _optionsController.options.showYScrollbar,
      grid: GridConfig(
        horizontal: _optionsController.options.showGrid,
        vertical: false,
      ),
      xAxisConfig: XAxisConfig(
        showAxisLine: _optionsController.options.showAxisLines,
        tickCount: compact ? math.min(4, _xTickCount) : _xTickCount,
        showTickLabels: _showXAxisLabels,
        labelFormatter: (value) => _formatStockSession(value, candles),
      ),
      yAxis: YAxisConfig(
        position: _yAxisPosition,
        label: 'Price',
        unit: 'USD',
        minWidth: _stockAxisGutter,
        maxWidth: _stockAxisGutter,
        labelFormatter: _formatTwoDecimals,
        showAxisLine: _optionsController.options.showAxisLines,
        showTickLabels: _showYAxisLabels,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.options.enableZoom,
        enablePan: _optionsController.options.enablePan,
        enableSelection: _selectionEnabled,
        showFocusBorder: _showFocusBorder,
        enableFocusOnHover: false,
        showXScrollbar: _optionsController.options.showXScrollbar,
        showYScrollbar: _optionsController.options.showYScrollbar,
        crosshair: CrosshairConfig(
          enabled: _trackingEnabled,
          mode: CrosshairMode.vertical,
          displayMode: CrosshairDisplayMode.tracking,
          interpolateValues: false,
          showTrackingTooltip: _showTrackingTooltip,
          showIntersectionMarkers: _showIntersectionMarkers,
          intersectionMarkerRadius: _intersectionMarkerRadius,
          showCoordinateLabels: _showCoordinateLabels,
          style: _crosshairStyle,
        ),
        tooltip: _tooltipConfig,
        keyboard: KeyboardConfig(enabled: _keyboardEnabled),
      ),
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
      minWidth: _stockAxisGutter,
      maxWidth: _stockAxisGutter,
      labelFormatter: _formatTwoDecimals,
      tickCount: 3,
      showAxisLine: _optionsController.options.showAxisLines,
      showTickLabels: _showYAxisLabels,
    ),
    interactionConfig: InteractionConfig(
      enableZoom: _optionsController.options.enableZoom,
      enablePan: _optionsController.options.enablePan,
      enableSelection: _selectionEnabled,
      showFocusBorder: _showFocusBorder,
      enableFocusOnHover: false,
      crosshair: CrosshairConfig(
        enabled: _trackingEnabled,
        mode: CrosshairMode.vertical,
        displayMode: CrosshairDisplayMode.tracking,
        showTrackingTooltip: _showTrackingTooltip,
        showIntersectionMarkers: _showIntersectionMarkers,
        intersectionMarkerRadius: _intersectionMarkerRadius,
        showCoordinateLabels: _showCoordinateLabels,
        style: _crosshairStyle,
      ),
      tooltip: _tooltipConfig,
      keyboard: KeyboardConfig(enabled: _keyboardEnabled),
    ),
  );

  Widget _buildStockAxisAlignedPane({
    required Key key,
    required Widget child,
    YAxisPosition? axisPosition,
  }) {
    final padding = switch (axisPosition) {
      null => const EdgeInsets.symmetric(horizontal: _stockOppositeGutter),
      YAxisPosition.right => const EdgeInsets.only(left: _stockOppositeGutter),
      _ => const EdgeInsets.only(right: _stockOppositeGutter),
    };
    return Padding(key: key, padding: padding, child: child);
  }

  Widget _buildStockNavigator(
    List<CandlestickDataPoint> candles, {
    required bool compact,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: CartesianNavigator(
          key: const ValueKey('candlestick-stock-navigator'),
          interactionGroupController: _stockGroupController,
          fullDomain: ChartXViewport(min: candles.first.x, max: candles.last.x),
          behavior: CartesianNavigatorBehavior(
            minimumSpan: _stockNavigatorMinimumSpan(candles),
          ),
          snapPolicy: CartesianNavigatorSnapPolicy.values(
            candles.map((candle) => candle.x),
          ),
          overviewSeries: AreaChartSeries(
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
          theme: _effectiveChartTheme(),
          style: CartesianNavigatorStyle(
            borderRadius: 6,
            handleVisualHeight: compact ? 28 : 24,
          ),
          semanticLabel: 'Market session range',
          onViewportChanged: (_) {
            if (_stockRange != _StockRangePreset.custom) {
              setState(() => _stockRange = _StockRangePreset.custom);
            }
          },
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

  double _stockNavigatorMinimumSpan(List<CandlestickDataPoint> candles) {
    var minimum = double.infinity;
    for (var index = 1; index < candles.length; index += 1) {
      minimum = math.min(minimum, candles[index].x - candles[index - 1].x);
    }
    return minimum.isFinite && minimum > 0 ? minimum : 1;
  }

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
        final formatterRegistry = ChartFormatterRegistry(
          customFormatters: {
            'showcase.candlestick.session': (value, _) =>
                _formatSession(value, displayCandles),
          },
        );
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
              yAxisFormatterDescriptors: {'y': _twoDecimalFormatter},
            ),
            tableOptions: ChartTableOptions(
              includeMetadata: true,
              formatters: formatterRegistry,
            ),
            tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
            sourceOptions: ChartDartSourceOptions(
              variableName: 'candlestickChart',
              formatters: formatterRegistry,
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
  }) => _buildPinnedSummaryLayer(
    candles: displayCandles,
    title: 'Price',
    chart: BravenChartPlus(
      key: const ValueKey('candlestick-reference-chart'),
      onPointHover: _handlePinnedPointHover,
      onPointTap: _handlePinnedPointTap,
      onDataXCursorChanged: (dataX) =>
          _handlePinnedDataXCursorChanged(dataX, displayCandles),
      onAnnotationDragged: _handlePinnedSummaryAnnotationDragged,
      bravenChartController: controller,
      series: _buildSeries(displayCandles),
      annotations: [
        ..._buildMarketContextAnnotations(displayCandles),
        ..._buildPinnedSummaryAnnotations(displayCandles, title: 'Price'),
      ],
      theme: _effectiveChartTheme(options),
      showLegend: options.showLegend,
      legendStyle: _effectiveChartTheme(options).legendStyle.copyWith(
        position: _legendPosition,
        allowDragging: _legendDraggable,
      ),
      showXScrollbar: options.showXScrollbar,
      showYScrollbar: options.showYScrollbar,
      grid: GridConfig(
        horizontal: options.showGrid,
        vertical: options.showGrid,
      ),
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
        labelFormatter: _formatTwoDecimals,
        showAxisLine: options.showAxisLines,
        showTickLabels: _showYAxisLabels,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: options.enableZoom,
        enablePan: options.enablePan,
        enableSelection: _selectionEnabled,
        showFocusBorder: _showFocusBorder,
        enableFocusOnHover: false,
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
          style: _crosshairStyle,
        ),
        tooltip: _tooltipConfig,
        keyboard: KeyboardConfig(enabled: _keyboardEnabled),
      ),
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
    final effectiveCandlestickTheme = _customDirectionColors
        ? candlestickTheme.copyWith(
            risingBodyFillColor: _risingBodyColor,
            fallingBodyFillColor: _fallingBodyColor,
            dojiBodyFillColor: _dojiBodyColor,
            risingBorderColor: _risingBorderColor,
            fallingBorderColor: _fallingBorderColor,
            dojiBorderColor: _dojiBorderColor,
            risingWickColor: _risingWickColor,
            fallingWickColor: _fallingWickColor,
            dojiWickColor: _dojiWickColor,
          )
        : candlestickTheme;
    return base.copyWith(
      candlestickTheme: effectiveCandlestickTheme,
      interactionTheme: _customTrackingTheme
          ? base.interactionTheme.copyWith(
              crosshairColor: _focusColor,
              selectionColor: _selectionColor,
            )
          : base.interactionTheme,
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: Duration(milliseconds: _animationDurationMs),
        dataUpdateCurve: _motionCurve.curve,
      ),
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
        points: _styledCandles(candles),
        candlestickStyle: _candlestickStyle,
        animation: _candlestickAnimation,
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

  List<ChartAnnotation> _buildMarketContextAnnotations(
    List<CandlestickDataPoint> candles,
  ) {
    if (!_showMarketContext || candles.length < 8 || _useDensityStressData) {
      return const [];
    }
    final windowStart = math.max(1, candles.length ~/ 4);
    final windowEnd = math.min(candles.length - 2, windowStart + 5);
    final eventIndex = math.min(candles.length - 2, windowEnd + 3);
    final visibleHigh = candles.map((point) => point.high).reduce(math.max);
    final visibleLow = candles.map((point) => point.low).reduce(math.min);
    final threshold = visibleLow + (visibleHigh - visibleLow) * .72;
    final thresholdColor = _contextThresholdColor ?? const Color(0xFFF59E0B);
    final windowColor = _contextWindowColor ?? const Color(0xFF3B82F6);
    final eventColor = _contextEventColor ?? const Color(0xFF7C3AED);
    return [
      RangeAnnotation(
        id: 'candlestick-event-window',
        startX: candles[windowStart].x,
        endX: candles[windowEnd].x,
        label: 'Event window',
        fillColor: windowColor.withValues(alpha: .10),
        borderColor: windowColor.withValues(alpha: .48),
        style: AnnotationStyle(borderWidth: _contextLineWidth),
        allowDragging: false,
        allowEditing: false,
      ),
      ThresholdAnnotation(
        id: 'candlestick-risk-level',
        axis: AnnotationAxis.y,
        value: threshold,
        label: 'Reference level',
        lineColor: thresholdColor,
        lineWidth: _contextLineWidth,
        dashPattern: _contextLineDashed ? const [6, 4] : null,
        allowDragging: false,
        allowEditing: false,
      ),
      PointAnnotation(
        id: 'candlestick-market-event',
        seriesId: 'reference-ohlc',
        dataPointIndex: eventIndex,
        label: 'Market event',
        markerShape: MarkerShape.star,
        markerColor: eventColor,
        markerSize: 12,
        allowDragging: false,
        allowEditing: false,
      ),
    ];
  }

  List<ChartAnnotation> _buildPinnedSummaryAnnotations(
    List<CandlestickDataPoint> candles, {
    required String title,
  }) {
    if (!_showPinnedSummary ||
        _pinnedSummaryPresentation != _PinnedSummaryPresentation.annotation ||
        candles.isEmpty) {
      return const [];
    }
    final candle = _summaryCandleFor(candles);
    final textColor = _effectiveSummaryTextColor;
    return [
      TextAnnotation.rich(
        id: _pinnedSummaryAnnotationId,
        label: 'Pinned OHLC summary',
        position: _pinnedSummaryAnnotationPosition,
        anchor: AnnotationAnchor.topLeft,
        allowDragging: _pinnedSummaryDraggable,
        allowEditing: false,
        zIndex: 100,
        richTextDelta: [
          {
            'insert': '● ',
            'attributes': {
              'fg': _effectiveSummaryAccentColor(candle).toARGB32(),
            },
          },
          {
            'insert': '$title\n',
            'attributes': {'b': true, 'fg': textColor.toARGB32()},
          },
          if (candle.label case final label?)
            {
              'insert': '$label\n',
              'attributes': {'fg': textColor.toARGB32()},
            },
          {
            'insert': _formattedOhlcRows(candle),
            'attributes': {'fg': textColor.toARGB32()},
          },
        ],
        style: AnnotationStyle(
          textStyle: TextStyle(
            color: textColor,
            fontSize: _pinnedSummaryFontSize,
            fontFamily: 'monospace',
            height: 1.35,
          ),
          backgroundColor: _paintedSummaryBackgroundColor,
          borderColor: _effectiveSummaryBorderColor,
          borderWidth: _pinnedSummaryBorderWidth,
          borderRadius: BorderRadius.circular(_pinnedSummaryCornerRadius),
          padding: EdgeInsets.all(_pinnedSummaryPadding),
        ),
      ),
    ];
  }

  String _formattedOhlcRows(CandlestickDataPoint candle) =>
      'Open   \$${candle.open.toStringAsFixed(2)}\n'
      'High   \$${candle.high.toStringAsFixed(2)}\n'
      'Low    \$${candle.low.toStringAsFixed(2)}\n'
      'Close  \$${candle.close.toStringAsFixed(2)}';

  CandlestickChartStyle get _candlestickStyle => CandlestickChartStyle(
    risingBodyFillColor: _customDirectionColors ? _risingBodyColor : null,
    fallingBodyFillColor: _customDirectionColors ? _fallingBodyColor : null,
    dojiBodyFillColor: _customDirectionColors ? _dojiBodyColor : null,
    risingBorderColor: _customDirectionColors ? _risingBorderColor : null,
    fallingBorderColor: _customDirectionColors ? _fallingBorderColor : null,
    dojiBorderColor: _customDirectionColors ? _dojiBorderColor : null,
    risingWickColor: _customDirectionColors ? _risingWickColor : null,
    fallingWickColor: _customDirectionColors ? _fallingWickColor : null,
    dojiWickColor: _customDirectionColors ? _dojiWickColor : null,
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
  );

  CandlestickAnimationStyle get _candlestickAnimation =>
      CandlestickAnimationStyle(
        mode: _entranceAnimation,
        staggerFraction: _entranceStagger,
        dataUpdateMode: _dataUpdateAnimation,
      );

  List<CandlestickDataPoint> _styledCandles(
    List<CandlestickDataPoint> candles,
  ) => [
    for (var index = 0; index < candles.length; index++)
      if (_highlightLatestCandle && index == candles.length - 1)
        candles[index].copyWith(
          candlestickStyle: CandlestickPointStyle(
            bodyFillColor: _highlightBodyColor,
            borderColor: _highlightBorderColor,
            wickColor: _highlightWickColor,
          ),
        )
      else
        candles[index],
  ];

  CrosshairStyle get _crosshairStyle => CrosshairStyle(
    lineColor: _customTrackingTheme
        ? _crosshairColor ?? const Color(0xFF666666)
        : const Color(0xFF666666),
    lineWidth: _crosshairLineWidth,
    dashPattern: _crosshairDashed ? const [6, 4] : null,
    labelBackgroundColor: _customTrackingTheme
        ? _coordinateLabelBackgroundColor ?? const Color(0xFF333333)
        : const Color(0xFF333333),
    labelTextColor: _customTrackingTheme
        ? _coordinateLabelTextColor ?? const Color(0xFFFFFFFF)
        : const Color(0xFFFFFFFF),
  );

  TooltipConfig get _tooltipConfig => TooltipConfig(
    enabled: _showPointTooltip,
    preferredPosition: _tooltipPosition,
    followCursor: _tooltipFollowsCursor,
    style: _customTrackingTheme
        ? TooltipStyle(
            backgroundColor:
                _tooltipBackgroundColor ?? const TooltipStyle().backgroundColor,
            borderColor:
                _tooltipBorderColor ?? const TooltipStyle().borderColor,
            borderWidth: _tooltipBorderWidth,
            borderRadius: _tooltipCornerRadius,
            textColor: _tooltipTextColor ?? const TooltipStyle().textColor,
            fontSize: _tooltipFontSize,
          )
        : const TooltipStyle(),
  );

  String _formatTwoDecimals(double value) => value.toStringAsFixed(2);

  bool get _summaryUsesDarkSurface =>
      _effectiveChartTheme().backgroundColor.computeLuminance() < .35;

  Color get _effectiveSummaryBackgroundColor {
    if (!_pinnedSummaryBackgroundVisible) return Colors.transparent;
    return _pinnedSummaryBackgroundColor ??
        (_summaryUsesDarkSurface
            ? const Color(0xFF111827)
            : const Color(0xFFFFFFFF));
  }

  Color get _paintedSummaryBackgroundColor => _pinnedSummaryBackgroundVisible
      ? _effectiveSummaryBackgroundColor.withValues(
          alpha: _pinnedSummaryBackgroundOpacity,
        )
      : Colors.transparent;

  Color get _effectiveSummaryBorderColor {
    if (!_pinnedSummaryBorderVisible) return Colors.transparent;
    return _pinnedSummaryBorderColor ??
        (_summaryUsesDarkSurface
            ? const Color(0xFF475569)
            : const Color(0xFFCBD5E1));
  }

  Color get _effectiveSummaryTextColor =>
      _pinnedSummaryTextColor ??
      (_summaryUsesDarkSurface
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF1F2937));

  Color _effectiveSummaryAccentColor(CandlestickDataPoint candle) =>
      _pinnedSummaryAccentColor ??
      switch (candle.direction) {
        CandlestickDirection.rising => const Color(0xFF0F766E),
        CandlestickDirection.falling => const Color(0xFFB91C1C),
        CandlestickDirection.doji => const Color(0xFF475569),
      };

  CandlestickDataPoint _summaryCandleFor(List<CandlestickDataPoint> candles) {
    final active = _pinnedSummaryCandle.value;
    if (active != null &&
        candles.any(
          (candidate) =>
              candidate.x == active.x &&
              candidate.timestamp == active.timestamp,
        )) {
      return active;
    }
    return candles.last;
  }

  void _setPinnedSummaryCandle(CandlestickDataPoint? candle) {
    final previous = _pinnedSummaryCandle.value;
    if (previous?.x == candle?.x && previous?.timestamp == candle?.timestamp) {
      return;
    }
    _pinnedSummaryCandle.value = candle;
    if (mounted &&
        _showPinnedSummary &&
        _pinnedSummaryPresentation == _PinnedSummaryPresentation.annotation) {
      setState(() {});
    }
  }

  void _handlePinnedPointHover(ChartDataPoint? point, String? _) {
    if (point is CandlestickDataPoint) {
      _setPinnedSummaryCandle(point);
    }
  }

  void _handlePinnedDataXCursorChanged(
    double? dataX,
    List<CandlestickDataPoint> candles,
  ) {
    if (dataX == null || candles.isEmpty) {
      _setPinnedSummaryCandle(null);
      return;
    }
    var low = 0;
    var high = candles.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (candles[middle].x < dataX) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final index = switch (low) {
      <= 0 => 0,
      _ when low >= candles.length => candles.length - 1,
      _ =>
        (dataX - candles[low - 1].x).abs() <= (candles[low].x - dataX).abs()
            ? low - 1
            : low,
    };
    _setPinnedSummaryCandle(candles[index]);
  }

  void _handlePinnedPointTap(ChartDataPoint point, String _) {
    if (point is CandlestickDataPoint) {
      _setPinnedSummaryCandle(point);
    }
  }

  void _handlePinnedSummaryAnnotationDragged(
    ChartAnnotation annotation,
    Offset position,
  ) {
    if (annotation.id != _pinnedSummaryAnnotationId ||
        annotation is! TextAnnotation) {
      return;
    }
    setState(() => _pinnedSummaryAnnotationPosition = position);
  }

  Widget _buildPinnedSummaryLayer({
    required Widget chart,
    required List<CandlestickDataPoint> candles,
    required String title,
  }) {
    if (!_showPinnedSummary ||
        _pinnedSummaryPresentation != _PinnedSummaryPresentation.overlay ||
        candles.isEmpty) {
      return chart;
    }
    final top = switch (_pinnedSummaryCorner) {
      _PinnedSummaryCorner.topLeft || _PinnedSummaryCorner.topRight => 12.0,
      _ => null,
    };
    final bottom = switch (_pinnedSummaryCorner) {
      _PinnedSummaryCorner.bottomLeft ||
      _PinnedSummaryCorner.bottomRight => 12.0,
      _ => null,
    };
    final left = switch (_pinnedSummaryCorner) {
      _PinnedSummaryCorner.topLeft || _PinnedSummaryCorner.bottomLeft => 12.0,
      _ => null,
    };
    final right = switch (_pinnedSummaryCorner) {
      _PinnedSummaryCorner.topRight || _PinnedSummaryCorner.bottomRight => 12.0,
      _ => null,
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        chart,
        Positioned(
          key: const ValueKey('candlestick-pinned-summary-position'),
          top: top,
          right: right,
          bottom: bottom,
          left: left,
          child: IgnorePointer(
            child: ValueListenableBuilder<CandlestickDataPoint?>(
              valueListenable: _pinnedSummaryCandle,
              builder: (context, hovered, _) {
                final candle = _summaryCandleFor(candles);
                return _PinnedOhlcSummaryCard(
                  title: title,
                  candle: candle,
                  backgroundColor: _paintedSummaryBackgroundColor,
                  showShadow: _pinnedSummaryBackgroundVisible,
                  borderColor: _effectiveSummaryBorderColor,
                  textColor: _effectiveSummaryTextColor,
                  accentColor: _effectiveSummaryAccentColor(candle),
                  borderWidth: _pinnedSummaryBorderWidth,
                  cornerRadius: _pinnedSummaryCornerRadius,
                  padding: _pinnedSummaryPadding,
                  fontSize: _pinnedSummaryFontSize,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOptions() => [
    if (_playgroundActive ||
        _showcaseMode == _CandlestickShowcaseMode.workbench)
      OptionSection(
        title: 'Example data',
        icon: Icons.dataset_outlined,
        children: [
          if (_playgroundActive || !_useDensityStressData) ...[
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
    if (_playgroundActive ||
        _showcaseMode == _CandlestickShowcaseMode.workbench)
      OptionSection(
        title: 'Annotations and events',
        icon: Icons.event_note_outlined,
        children: [
          BoolOption(
            key: const ValueKey('candlestick-market-context'),
            label: 'Show market context',
            subtitle:
                'Combine a session range, price level, and candle-linked event',
            value: _showMarketContext,
            onChanged: (value) => setState(() => _showMarketContext = value),
          ),
          if (_playgroundActive || _showMarketContext) ...[
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-context-threshold-color'),
              label: 'Price level colour',
              value: _contextThresholdColor,
              onChanged: (value) =>
                  setState(() => _contextThresholdColor = value),
            ),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-context-window-color'),
              label: 'Session window colour',
              value: _contextWindowColor,
              onChanged: (value) => setState(() => _contextWindowColor = value),
            ),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-context-event-color'),
              label: 'Event marker colour',
              value: _contextEventColor,
              onChanged: (value) => setState(() => _contextEventColor = value),
            ),
            SliderOption(
              key: const ValueKey('candlestick-context-line-width'),
              label: 'Annotation stroke width',
              value: _contextLineWidth,
              min: .5,
              max: 4,
              divisions: 14,
              suffix: 'px',
              onChanged: (value) => setState(() => _contextLineWidth = value),
            ),
            BoolOption(
              key: const ValueKey('candlestick-context-dashed'),
              label: 'Dash price level',
              value: _contextLineDashed,
              onChanged: (value) => setState(() => _contextLineDashed = value),
            ),
          ],
        ],
      ),
    OptionSection(
      title: 'Tracking and tooltips',
      icon: Icons.track_changes,
      children: [
        const _OptionGroupLabel('Crosshair tracking'),
        BoolOption(
          key: const ValueKey('candlestick-tracking-enabled'),
          label: 'Track OHLC samples',
          subtitle:
              'Nearest session only; financial values are never interpolated',
          value: _trackingEnabled,
          onChanged: (value) => setState(() => _trackingEnabled = value),
        ),
        if (_playgroundActive || _trackingEnabled)
          BoolOption(
            key: const ValueKey('candlestick-tracking-tooltip'),
            label: 'Show crosshair OHLC panel',
            subtitle: 'All tracked series at the crosshair X position',
            value: _showTrackingTooltip,
            onChanged: (value) => setState(() => _showTrackingTooltip = value),
          ),
        if (_playgroundActive || _trackingEnabled) ...[
          BoolOption(
            key: const ValueKey('candlestick-coordinate-labels'),
            label: 'Show crosshair axis values',
            subtitle: 'Small X and Y value labels attached to the axes',
            value: _showCoordinateLabels,
            onChanged: (value) => setState(() => _showCoordinateLabels = value),
          ),
          BoolOption(
            key: const ValueKey('candlestick-intersection-markers'),
            label: 'Show crosshair intersection dot',
            subtitle: 'A marker only; it does not render another value label',
            value: _showIntersectionMarkers,
            onChanged: (value) =>
                setState(() => _showIntersectionMarkers = value),
          ),
          if (_playgroundActive || _showIntersectionMarkers)
            SliderOption(
              key: const ValueKey('candlestick-marker-radius'),
              label: 'Intersection dot radius',
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
        ],
        const _OptionGroupLabel('Candle hover'),
        BoolOption(
          key: const ValueKey('candlestick-point-tooltip'),
          label: 'Show candle hover card',
          subtitle:
              'One directly hit candle; independent of the crosshair panel',
          value: _showPointTooltip,
          onChanged: (value) => setState(() => _showPointTooltip = value),
        ),
        if (_playgroundActive || _showPointTooltip) ...[
          EnumOption<TooltipPosition>(
            key: const ValueKey('candlestick-tooltip-position'),
            label: 'Hover card position',
            value: _tooltipPosition,
            values: TooltipPosition.values,
            labelBuilder: (value) => value.name,
            onChanged: (value) => setState(() => _tooltipPosition = value),
          ),
          BoolOption(
            key: const ValueKey('candlestick-tooltip-follow-cursor'),
            label: 'Hover card follows cursor',
            value: _tooltipFollowsCursor,
            onChanged: (value) => setState(() => _tooltipFollowsCursor = value),
          ),
        ],
        const _OptionGroupLabel('Pinned summary'),
        BoolOption(
          key: const ValueKey('candlestick-pinned-summary'),
          label: 'Show pinned OHLC summary',
          subtitle:
              'Keep the active candle visible as an overlay or chart annotation',
          value: _showPinnedSummary,
          onChanged: (value) => setState(() => _showPinnedSummary = value),
        ),
        if (_playgroundActive || _showPinnedSummary) ...[
          EnumOption<_PinnedSummaryPresentation>(
            key: const ValueKey('candlestick-pinned-summary-presentation'),
            label: 'Presentation',
            value: _pinnedSummaryPresentation,
            values: _PinnedSummaryPresentation.values,
            labelBuilder: (value) => switch (value) {
              _PinnedSummaryPresentation.overlay => 'Overlay card',
              _PinnedSummaryPresentation.annotation => 'Chart text annotation',
            },
            onChanged: (value) =>
                setState(() => _pinnedSummaryPresentation = value),
          ),
          if (_playgroundActive ||
              _pinnedSummaryPresentation == _PinnedSummaryPresentation.overlay)
            EnumOption<_PinnedSummaryCorner>(
              key: const ValueKey('candlestick-pinned-summary-corner'),
              label: 'Overlay position',
              value: _pinnedSummaryCorner,
              values: _PinnedSummaryCorner.values,
              labelBuilder: (value) => switch (value) {
                _PinnedSummaryCorner.topLeft => 'Top left',
                _PinnedSummaryCorner.topRight => 'Top right',
                _PinnedSummaryCorner.bottomLeft => 'Bottom left',
                _PinnedSummaryCorner.bottomRight => 'Bottom right',
              },
              onChanged: (value) =>
                  setState(() => _pinnedSummaryCorner = value),
            ),
          if (_playgroundActive ||
              _pinnedSummaryPresentation ==
                  _PinnedSummaryPresentation.annotation) ...[
            BoolOption(
              key: const ValueKey('candlestick-pinned-summary-draggable'),
              label: 'Allow annotation dragging',
              subtitle: 'Move the native TextAnnotation on the chart canvas',
              value: _pinnedSummaryDraggable,
              onChanged: (value) =>
                  setState(() => _pinnedSummaryDraggable = value),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const ValueKey(
                  'candlestick-pinned-summary-reset-position',
                ),
                onPressed: () => setState(
                  () => _pinnedSummaryAnnotationPosition = const Offset(96, 48),
                ),
                icon: const Icon(Icons.center_focus_strong, size: 16),
                label: const Text('Reset annotation position'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const _OptionGroupLabel('Summary appearance'),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-summary-background'),
            label: 'Background colour',
            value: _pinnedSummaryBackgroundVisible
                ? _pinnedSummaryBackgroundColor ??
                      _effectiveSummaryBackgroundColor
                : null,
            onChanged: (value) => setState(() {
              _pinnedSummaryBackgroundVisible = value != null;
              _pinnedSummaryBackgroundColor = value;
            }),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-summary-border'),
            label: 'Border colour',
            value: _pinnedSummaryBorderVisible
                ? _pinnedSummaryBorderColor ?? _effectiveSummaryBorderColor
                : null,
            onChanged: (value) => setState(() {
              _pinnedSummaryBorderVisible = value != null;
              _pinnedSummaryBorderColor = value;
            }),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-summary-text'),
            label: 'Text colour',
            value: _pinnedSummaryTextColor,
            onChanged: (value) =>
                setState(() => _pinnedSummaryTextColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-summary-accent'),
            label: 'Accent colour',
            value: _pinnedSummaryAccentColor,
            onChanged: (value) =>
                setState(() => _pinnedSummaryAccentColor = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-summary-opacity'),
            label: 'Background opacity',
            value: _pinnedSummaryBackgroundOpacity,
            min: .2,
            max: 1,
            divisions: 16,
            decimalPlaces: 2,
            onChanged: (value) =>
                setState(() => _pinnedSummaryBackgroundOpacity = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-summary-border-width'),
            label: 'Border width',
            value: _pinnedSummaryBorderWidth,
            min: 0,
            max: 4,
            divisions: 16,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _pinnedSummaryBorderWidth = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-summary-corner-radius'),
            label: 'Corner radius',
            value: _pinnedSummaryCornerRadius,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _pinnedSummaryCornerRadius = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-summary-padding'),
            label: 'Inner padding',
            value: _pinnedSummaryPadding,
            min: 4,
            max: 24,
            divisions: 20,
            suffix: 'px',
            onChanged: (value) => setState(() => _pinnedSummaryPadding = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-summary-font-size'),
            label: 'Text size',
            value: _pinnedSummaryFontSize,
            min: 10,
            max: 18,
            divisions: 8,
            suffix: 'px',
            onChanged: (value) =>
                setState(() => _pinnedSummaryFontSize = value),
          ),
        ],
        if (_playgroundActive ||
            _showcaseMode == _CandlestickShowcaseMode.workbench) ...[
          const _OptionGroupLabel('Time scale'),
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
        ],
      ],
    ),
    if (_playgroundActive ||
        _showcaseMode == _CandlestickShowcaseMode.workbench)
      OptionSection(
        title: 'Motion and revisions',
        icon: Icons.animation_outlined,
        children: [
          EnumOption<CandlestickAnimationMode>(
            key: const ValueKey('candlestick-entrance-animation'),
            label: 'Entrance animation',
            value: _entranceAnimation,
            values: CandlestickAnimationMode.values,
            labelBuilder: (value) => switch (value) {
              CandlestickAnimationMode.none => 'None',
              CandlestickAnimationMode.reveal => 'Ordered reveal',
            },
            onChanged: (value) => setState(() => _entranceAnimation = value),
          ),
          if (_playgroundActive ||
              _entranceAnimation == CandlestickAnimationMode.reveal)
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
          EnumOption<CandlestickDataUpdateAnimationMode>(
            key: const ValueKey('candlestick-update-animation'),
            label: 'OHLC revision animation',
            subtitle: 'Preserve candle identity while values change',
            value: _dataUpdateAnimation,
            values: CandlestickDataUpdateAnimationMode.values,
            labelBuilder: (value) => switch (value) {
              CandlestickDataUpdateAnimationMode.none => 'None',
              CandlestickDataUpdateAnimationMode.interpolate => 'Interpolate',
            },
            onChanged: (value) => setState(() => _dataUpdateAnimation = value),
          ),
          IntSliderOption(
            key: const ValueKey('candlestick-animation-duration'),
            label: 'Animation duration',
            value: _animationDurationMs,
            min: 100,
            max: 1200,
            suffix: 'ms',
            onChanged: (value) => setState(() => _animationDurationMs = value),
          ),
          EnumOption<_CandlestickMotionCurve>(
            key: const ValueKey('candlestick-motion-curve'),
            label: 'Motion curve',
            value: _motionCurve,
            values: _CandlestickMotionCurve.values,
            labelBuilder: (value) => value.label,
            onChanged: (value) => setState(() => _motionCurve = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-revision-magnitude'),
            label: 'Revision magnitude',
            value: _revisionMagnitude,
            min: 1,
            max: 12,
            divisions: 22,
            suffix: 'USD',
            onChanged: (value) => setState(() => _revisionMagnitude = value),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('candlestick-options-replay'),
              onPressed: _chartController.replaySeriesEntrance,
              icon: const Icon(Icons.replay_outlined),
              label: const Text('Replay entrance'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('candlestick-options-revise'),
              onPressed: _reviseLatest,
              icon: const Icon(Icons.update_outlined),
              label: const Text('Revise latest candle'),
            ),
          ),
        ],
      ),
    OptionSection(
      title: 'Interaction detail',
      icon: Icons.ads_click_outlined,
      children: [
        const _OptionGroupLabel('Selection'),
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
          label: 'Show chart focus outline',
          subtitle:
              'Optional plot boundary after click or keyboard focus; off by default',
          value: _showFocusBorder,
          onChanged: (value) => setState(() => _showFocusBorder = value),
        ),
      ],
    ),
    OptionSection(
      title: 'Tracking theme',
      icon: Icons.colorize_outlined,
      children: [
        BoolOption(
          key: const ValueKey('candlestick-custom-tracking-theme'),
          label: 'Override tracking colours',
          subtitle: 'Style tracking, candle selection/focus, and both tooltips',
          value: _customTrackingTheme,
          onChanged: (value) => setState(() => _customTrackingTheme = value),
        ),
        if (_playgroundActive || _customTrackingTheme) ...[
          const _OptionGroupLabel('Tracking lines'),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-crosshair-color'),
            label: 'Crosshair colour',
            value: _crosshairColor,
            onChanged: (value) => setState(() => _crosshairColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-axis-value-background'),
            label: 'Axis value background',
            value: _coordinateLabelBackgroundColor,
            onChanged: (value) =>
                setState(() => _coordinateLabelBackgroundColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-axis-value-text'),
            label: 'Axis value text',
            value: _coordinateLabelTextColor,
            onChanged: (value) =>
                setState(() => _coordinateLabelTextColor = value),
          ),
          const _OptionGroupLabel('Candle states'),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-selection-color'),
            label: 'Selected candle',
            value: _selectionColor,
            onChanged: (value) => setState(() => _selectionColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-focus-color'),
            label: 'Focused candle',
            value: _focusColor,
            onChanged: (value) => setState(() => _focusColor = value),
          ),
          const _OptionGroupLabel('Tooltips'),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-tooltip-background'),
            label: 'Tooltip background',
            value: _tooltipBackgroundColor,
            onChanged: (value) =>
                setState(() => _tooltipBackgroundColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-tooltip-border-color'),
            label: 'Tooltip border',
            value: _tooltipBorderColor,
            onChanged: (value) => setState(() => _tooltipBorderColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-tooltip-text-color'),
            label: 'Tooltip text',
            value: _tooltipTextColor,
            onChanged: (value) => setState(() => _tooltipTextColor = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-tooltip-border-width'),
            label: 'Tooltip border width',
            value: _tooltipBorderWidth,
            min: 0,
            max: 4,
            divisions: 8,
            suffix: 'px',
            onChanged: (value) => setState(() => _tooltipBorderWidth = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-tooltip-radius'),
            label: 'Tooltip corner radius',
            value: _tooltipCornerRadius,
            min: 0,
            max: 16,
            divisions: 16,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _tooltipCornerRadius = value),
          ),
          SliderOption(
            key: const ValueKey('candlestick-tooltip-font-size'),
            label: 'Tooltip font size',
            value: _tooltipFontSize,
            min: 10,
            max: 18,
            divisions: 8,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _tooltipFontSize = value),
          ),
        ],
      ],
    ),
    if (_playgroundActive ||
        _showcaseMode == _CandlestickShowcaseMode.workbench)
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
          if (_playgroundActive || _densityGroupingEnabled) ...[
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
        EnumOption<_CandlestickStyleRecipe>(
          key: const ValueKey('candlestick-style-recipe'),
          label: 'Apply style recipe',
          subtitle: 'Start from a coherent visual treatment, then fine-tune',
          value: _styleRecipe,
          values: _CandlestickStyleRecipe.values,
          labelBuilder: (value) => value.label,
          onChanged: _applyStyleRecipe,
        ),
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
      title: 'Element colours',
      icon: Icons.palette_outlined,
      children: [
        BoolOption(
          key: const ValueKey('candlestick-custom-direction-colors'),
          label: 'Override direction colours',
          subtitle: 'Set body, border, and wick colours for every direction',
          value: _customDirectionColors,
          onChanged: (value) => setState(() => _customDirectionColors = value),
        ),
        if (_playgroundActive || _customDirectionColors) ...[
          const _OptionGroupLabel('Body fills'),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-rising-body-color'),
            label: 'Rising body',
            value: _risingBodyColor,
            onChanged: (value) => setState(() => _risingBodyColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-falling-body-color'),
            label: 'Falling body',
            value: _fallingBodyColor,
            onChanged: (value) => setState(() => _fallingBodyColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-doji-body-color'),
            label: 'Doji body',
            value: _dojiBodyColor,
            onChanged: (value) => setState(() => _dojiBodyColor = value),
          ),
          if (_playgroundActive || _showBodyBorder) ...[
            const _OptionGroupLabel('Body borders'),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-rising-border-color'),
              label: 'Rising border',
              value: _risingBorderColor,
              onChanged: (value) => setState(() => _risingBorderColor = value),
            ),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-falling-border-color'),
              label: 'Falling border',
              value: _fallingBorderColor,
              onChanged: (value) => setState(() => _fallingBorderColor = value),
            ),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-doji-border-color'),
              label: 'Doji border',
              value: _dojiBorderColor,
              onChanged: (value) => setState(() => _dojiBorderColor = value),
            ),
          ],
          if (_playgroundActive || _showWicks) ...[
            const _OptionGroupLabel('Wicks'),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-rising-wick-color'),
              label: 'Rising wick',
              value: _risingWickColor,
              onChanged: (value) => setState(() => _risingWickColor = value),
            ),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-falling-wick-color'),
              label: 'Falling wick',
              value: _fallingWickColor,
              onChanged: (value) => setState(() => _fallingWickColor = value),
            ),
            _AnnotationPaletteOption(
              key: const ValueKey('candlestick-doji-wick-color'),
              label: 'Doji wick',
              value: _dojiWickColor,
              onChanged: (value) => setState(() => _dojiWickColor = value),
            ),
          ],
        ],
        BoolOption(
          key: const ValueKey('candlestick-highlight-latest'),
          label: 'Highlight latest candle',
          subtitle: 'Demonstrate a point-level body, border, and wick override',
          value: _highlightLatestCandle,
          onChanged: (value) => setState(() => _highlightLatestCandle = value),
        ),
        if (_playgroundActive || _highlightLatestCandle) ...[
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-highlight-body-color'),
            label: 'Highlight body',
            value: _highlightBodyColor,
            onChanged: (value) => setState(() => _highlightBodyColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-highlight-border-color'),
            label: 'Highlight border',
            value: _highlightBorderColor,
            onChanged: (value) => setState(() => _highlightBorderColor = value),
          ),
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-highlight-wick-color'),
            label: 'Highlight wick',
            value: _highlightWickColor,
            onChanged: (value) => setState(() => _highlightWickColor = value),
          ),
        ],
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
        if (_playgroundActive || _showBodyBorder)
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
        if (_playgroundActive || _showWicks)
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
        if (_playgroundActive || _showCloseAverage) ...[
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
          _AnnotationPaletteOption(
            key: const ValueKey('candlestick-average-color'),
            label: 'Average colour',
            value: _averageColor,
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
        if (_playgroundActive ||
            _showcaseMode == _CandlestickShowcaseMode.workbench)
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
              color:
                  _averageColor ??
                  _effectiveChartTheme().seriesTheme.colorAt(1),
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
    final closeDelta = _revisionStep.isEven
        ? -_revisionMagnitude * .75
        : _revisionMagnitude;
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

  void _applyRandomSeed(int seed) {
    if (!mounted) return;
    final random = math.Random(seed);
    const colors = <Color>[
      Color(0xFF2563EB),
      Color(0xFF0D9488),
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
      Color(0xFFEF4444),
      Color(0xFF334155),
      Color(0xFFF8FAFC),
    ];
    Color randomColor() => colors[random.nextInt(colors.length)];
    final dataProfile = _CandlestickDataProfile
        .values[random.nextInt(_CandlestickDataProfile.values.length)];
    final recipe = _CandlestickStyleRecipe
        .values[random.nextInt(_CandlestickStyleRecipe.values.length)];
    _applyStyleRecipe(recipe);
    setState(() {
      _showcaseMode = _CandlestickShowcaseMode.workbench;
      _sessionCount = 18 + random.nextInt(83);
      _rangeScale = 0.55 + random.nextDouble() * 2.2;
      _trendBias = -0.65 + random.nextDouble() * 1.3;
      _gapFrequency =
          _GapFrequency.values[random.nextInt(_GapFrequency.values.length)];
      _useDensityStressData = false;
      _densityGroupingEnabled = false;
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
      _bodyFillMode = CandlestickBodyFillMode
          .values[random.nextInt(CandlestickBodyFillMode.values.length)];
      _bodyWidthFactor = 0.42 + random.nextDouble() * 0.5;
      _minBodyWidth = 1 + random.nextDouble() * 3;
      _maxBodyWidth = 10 + random.nextDouble() * 16;
      _bodyBorderWidth = 0.5 + random.nextDouble() * 2.5;
      _wickWidth = 0.5 + random.nextDouble() * 2.5;
      _cornerRadius = random.nextDouble() * 5;
      _minimumBodyHeight = 0.5 + random.nextDouble() * 3.5;
      _showBodyBorder = random.nextBool();
      _showWicks = random.nextBool();
      _showCloseAverage = random.nextBool();
      _showDirectionLegend = random.nextBool();
      _averageWindow = 3 + random.nextInt(18);
      _averageStrokeWidth = 1 + random.nextDouble() * 3;
      _averageColor = randomColor();
      _customDirectionColors = random.nextBool();
      _risingBodyColor = randomColor();
      _fallingBodyColor = randomColor();
      _dojiBodyColor = randomColor();
      _risingBorderColor = randomColor();
      _fallingBorderColor = randomColor();
      _dojiBorderColor = randomColor();
      _risingWickColor = randomColor();
      _fallingWickColor = randomColor();
      _dojiWickColor = randomColor();
      _highlightLatestCandle = random.nextBool();
      _highlightBodyColor = randomColor();
      _highlightBorderColor = randomColor();
      _highlightWickColor = randomColor();
      _trackingEnabled = random.nextBool();
      _showTrackingTooltip = random.nextBool();
      _showPointTooltip = random.nextBool();
      _showPinnedSummary = random.nextBool();
      _pinnedSummaryPresentation = _PinnedSummaryPresentation
          .values[random.nextInt(_PinnedSummaryPresentation.values.length)];
      _pinnedSummaryCorner = _PinnedSummaryCorner
          .values[random.nextInt(_PinnedSummaryCorner.values.length)];
      _pinnedSummaryDraggable = random.nextBool();
      _pinnedSummaryBackgroundVisible = random.nextBool();
      _pinnedSummaryBorderVisible = random.nextBool();
      _pinnedSummaryBackgroundColor = randomColor();
      _pinnedSummaryBorderColor = randomColor();
      _pinnedSummaryTextColor = randomColor();
      _pinnedSummaryAccentColor = randomColor();
      _pinnedSummaryBackgroundOpacity = 0.35 + random.nextDouble() * 0.65;
      _pinnedSummaryBorderWidth = random.nextDouble() * 3;
      _pinnedSummaryCornerRadius = random.nextDouble() * 16;
      _pinnedSummaryPadding = 4 + random.nextDouble() * 12;
      _pinnedSummaryFontSize = 8 + random.nextDouble() * 10;
      _showCoordinateLabels = random.nextBool();
      _showIntersectionMarkers = random.nextBool();
      _intersectionMarkerRadius = 2 + random.nextDouble() * 6;
      _crosshairLineWidth = 0.5 + random.nextDouble() * 2.5;
      _crosshairDashed = random.nextBool();
      _customTrackingTheme = random.nextBool();
      _crosshairColor = randomColor();
      _coordinateLabelBackgroundColor = randomColor();
      _coordinateLabelTextColor = randomColor();
      _tooltipBackgroundColor = randomColor();
      _tooltipBorderColor = randomColor();
      _tooltipTextColor = randomColor();
      _selectionColor = randomColor();
      _focusColor = randomColor();
      _tooltipBorderWidth = random.nextDouble() * 3;
      _tooltipCornerRadius = random.nextDouble() * 14;
      _tooltipFontSize = 8 + random.nextDouble() * 10;
      _tooltipPosition =
          TooltipPosition.values[random.nextInt(TooltipPosition.values.length)];
      _tooltipFollowsCursor = random.nextBool();
      _selectionEnabled = random.nextBool();
      _keyboardEnabled = random.nextBool();
      _showFocusBorder = random.nextBool();
      _entranceAnimation = CandlestickAnimationMode
          .values[random.nextInt(CandlestickAnimationMode.values.length)];
      _dataUpdateAnimation =
          CandlestickDataUpdateAnimationMode.values[random.nextInt(
            CandlestickDataUpdateAnimationMode.values.length,
          )];
      _animationDurationMs = 180 + random.nextInt(1021);
      _entranceStagger = random.nextDouble();
      _motionCurve = _CandlestickMotionCurve
          .values[random.nextInt(_CandlestickMotionCurve.values.length)];
      _revisionMagnitude = 1 + random.nextDouble() * 10;
      _targetGroupWidth = 2 + random.nextDouble() * 10;
      _minimumPointsPerGroup = 2 + random.nextInt(8);
      _timeSpacing = FinancialTimeSpacing
          .values[random.nextInt(FinancialTimeSpacing.values.length)];
      _legendPosition =
          LegendPosition.values[random.nextInt(LegendPosition.values.length)];
      _yAxisPosition =
          YAxisPosition.values[random.nextInt(YAxisPosition.values.length)];
      _xTickCount = 4 + random.nextInt(9);
      _showXAxisLabels = random.nextBool();
      _showYAxisLabels = random.nextBool();
      _legendDraggable = random.nextBool();
      _showMarketContext = random.nextBool();
      _contextThresholdColor = randomColor();
      _contextWindowColor = randomColor();
      _contextEventColor = randomColor();
      _contextLineWidth = 0.5 + random.nextDouble() * 3;
      _contextLineDashed = random.nextBool();
    });
  }

  void _applyStyleRecipe(_CandlestickStyleRecipe recipe) {
    setState(() {
      _styleRecipe = recipe;
      _customDirectionColors = false;
      _highlightLatestCandle = false;
      switch (recipe) {
        case _CandlestickStyleRecipe.balanced:
          _candlePalette = _CandlestickPalette.theme;
          _bodyFillMode = CandlestickBodyFillMode.hollowRising;
          _bodyBorderWidth = 1;
          _wickWidth = 1;
          _cornerRadius = 1;
          _minimumBodyHeight = 1;
          _averageColor = const Color(0xFF6366F1);
          break;
        case _CandlestickStyleRecipe.trading:
          _candlePalette = _CandlestickPalette.market;
          _bodyFillMode = CandlestickBodyFillMode.filled;
          _bodyBorderWidth = 1;
          _wickWidth = 1;
          _cornerRadius = 0;
          _minimumBodyHeight = 1;
          _averageColor = const Color(0xFF0EA5E9);
          break;
        case _CandlestickStyleRecipe.accessible:
          _candlePalette = _CandlestickPalette.blueOrange;
          _bodyFillMode = CandlestickBodyFillMode.hollowRising;
          _bodyBorderWidth = 1.8;
          _wickWidth = 1.6;
          _cornerRadius = 1;
          _minimumBodyHeight = 2;
          _averageColor = const Color(0xFF7C3AED);
          break;
        case _CandlestickStyleRecipe.print:
          _candlePalette = _CandlestickPalette.monochrome;
          _bodyFillMode = CandlestickBodyFillMode.hollowRising;
          _bodyBorderWidth = 1.6;
          _wickWidth = 1.4;
          _cornerRadius = 0;
          _minimumBodyHeight = 2;
          _averageColor = const Color(0xFF374151);
          break;
        case _CandlestickStyleRecipe.event:
          _candlePalette = _CandlestickPalette.market;
          _bodyFillMode = CandlestickBodyFillMode.filled;
          _bodyBorderWidth = 1.2;
          _wickWidth = 1.2;
          _cornerRadius = 1;
          _minimumBodyHeight = 1.5;
          _averageColor = const Color(0xFF6366F1);
          _highlightLatestCandle = true;
          break;
      }
    });
  }

  void _applyExample(
    _CandlestickExample example, {
    bool authoredSelection = true,
  }) {
    if (authoredSelection) {
      _showcaseRandomizer.pause();
      _showcaseRandomizer.clear();
    }
    _pinnedSummaryCandle.value = null;
    setState(() {
      if (authoredSelection) {
        _playgroundActive = false;
        _authoredExample = example;
      }
      _selectedExample = example;
      _showcaseMode = example == _CandlestickExample.stockComposition
          ? _CandlestickShowcaseMode.stock
          : _CandlestickShowcaseMode.workbench;
      _activeCandleIndex = null;
      _showMarketContext = example == _CandlestickExample.events;

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
        case _CandlestickExample.events:
          _sessionCount = 56;
          _rangeScale = 1.35;
          _trendBias = .12;
          _gapFrequency = _GapFrequency.occasional;
          _useDensityStressData = false;
          _densityGroupingEnabled = false;
          _showCloseAverage = true;
          _averageWindow = 10;
          _showMarketContext = true;
          _showDirectionLegend = true;
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

  void _setPlaygroundActive(bool active) {
    if (active == _playgroundActive) return;
    if (active) {
      _authoredExample = _selectedExample;
      setState(() {
        _playgroundActive = true;
        _showcaseMode = _CandlestickShowcaseMode.workbench;
      });
      _showcaseRandomizer.generateCurrent();
      return;
    }

    _showcaseRandomizer.pause();
    _showcaseRandomizer.clear();
    _reset();
    _applyExample(_authoredExample);
  }

  List<Widget> _buildPlaygroundOptions() => _buildOptions();

  void _regenerateWorkbenchData() {
    final dataProfile = switch (_selectedExample) {
      _CandlestickExample.trend => _CandlestickDataProfile.trend,
      _CandlestickExample.volatility => _CandlestickDataProfile.volatility,
      _CandlestickExample.gapsAndDoji => _CandlestickDataProfile.gapsAndDoji,
      _CandlestickExample.events => _CandlestickDataProfile.priceAction,
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
    _pinnedSummaryCandle.value = null;
  }

  String get _exampleDescription => _playgroundActive
      ? 'Generated OHLC data and every compatible candlestick property. Seeded playback is available in Options.'
      : switch (_selectedExample) {
          _CandlestickExample.priceAction =>
            'Balanced market action with rising, falling, and doji candles.',
          _CandlestickExample.trend =>
            'A sustained advance tests dense bodies and a longer moving average.',
          _CandlestickExample.volatility =>
            'Wide bodies, long wicks, and frequent gaps stress price-range handling.',
          _CandlestickExample.gapsAndDoji =>
            'Discontinuous opens and repeated doji make direction cues explicit.',
          _CandlestickExample.events =>
            'A session band, price level, and candle-linked event demonstrate native Cartesian annotations.',
          _CandlestickExample.accessible =>
            'Blue/orange hues, hollow rising bodies, stronger strokes, and a direction key avoid colour-only meaning.',
          _CandlestickExample.density =>
            '2,000 raw sessions demonstrate opt-in OHLC density grouping.',
          _CandlestickExample.stockComposition =>
            'Price, volume, and navigator charts share one financial time viewport.',
        };

  String get _exampleChartTitle => _playgroundActive
      ? 'Candlestick playground'
      : switch (_selectedExample) {
          _CandlestickExample.priceAction => 'Balanced price action',
          _CandlestickExample.trend => 'Advancing market trend',
          _CandlestickExample.volatility => 'High-volatility sessions',
          _CandlestickExample.gapsAndDoji => 'Opening gaps and doji',
          _CandlestickExample.events => 'Events and price levels',
          _CandlestickExample.accessible => 'Accessible direction cues',
          _ => 'Candlestick price action',
        };

  String _exampleLabel(_CandlestickExample example) => switch (example) {
    _CandlestickExample.priceAction => 'Price action',
    _CandlestickExample.trend => 'Trend',
    _CandlestickExample.volatility => 'Volatility',
    _CandlestickExample.gapsAndDoji => 'Gaps & doji',
    _CandlestickExample.events => 'Events & levels',
    _CandlestickExample.accessible => 'Accessible',
    _CandlestickExample.density => 'Density',
    _CandlestickExample.stockComposition => 'Stock composition',
  };

  IconData _exampleIcon(_CandlestickExample example) => switch (example) {
    _CandlestickExample.priceAction => Icons.candlestick_chart,
    _CandlestickExample.trend => Icons.trending_up,
    _CandlestickExample.volatility => Icons.show_chart,
    _CandlestickExample.gapsAndDoji => Icons.space_bar,
    _CandlestickExample.events => Icons.event_note_outlined,
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
      _customDirectionColors = false;
      _risingBodyColor = const Color(0xFFCCFBF1);
      _fallingBodyColor = const Color(0xFFEF4444);
      _dojiBodyColor = const Color(0xFF64748B);
      _risingBorderColor = const Color(0xFF0F766E);
      _fallingBorderColor = const Color(0xFFB91C1C);
      _dojiBorderColor = const Color(0xFF475569);
      _risingWickColor = const Color(0xFF0F766E);
      _fallingWickColor = const Color(0xFFB91C1C);
      _dojiWickColor = const Color(0xFF475569);
      _highlightLatestCandle = false;
      _highlightBodyColor = const Color(0xFFFEF08A);
      _highlightBorderColor = const Color(0xFFCA8A04);
      _highlightWickColor = const Color(0xFFA16207);
      _trackingEnabled = true;
      _showTrackingTooltip = true;
      _showPointTooltip = false;
      _showPinnedSummary = false;
      _pinnedSummaryPresentation = _PinnedSummaryPresentation.overlay;
      _pinnedSummaryCorner = _PinnedSummaryCorner.topLeft;
      _pinnedSummaryDraggable = true;
      _pinnedSummaryAnnotationPosition = const Offset(96, 48);
      _pinnedSummaryBackgroundVisible = true;
      _pinnedSummaryBorderVisible = true;
      _pinnedSummaryBackgroundColor = null;
      _pinnedSummaryBorderColor = null;
      _pinnedSummaryTextColor = null;
      _pinnedSummaryAccentColor = null;
      _pinnedSummaryBackgroundOpacity = .96;
      _pinnedSummaryBorderWidth = 1;
      _pinnedSummaryCornerRadius = 8;
      _pinnedSummaryPadding = 8;
      _pinnedSummaryFontSize = 11;
      _showCoordinateLabels = true;
      _showIntersectionMarkers = true;
      _intersectionMarkerRadius = 4;
      _crosshairLineWidth = 1;
      _crosshairDashed = false;
      _customTrackingTheme = false;
      _crosshairColor = const Color(0xFF475569);
      _coordinateLabelBackgroundColor = const Color(0xFF1F2937);
      _coordinateLabelTextColor = const Color(0xFFFFFFFF);
      _tooltipBackgroundColor = const Color(0xF2FFFFFF);
      _tooltipBorderColor = const Color(0xFF94A3B8);
      _tooltipTextColor = const Color(0xFF1F2937);
      _selectionColor = const Color(0xFF2563EB);
      _focusColor = const Color(0xFF475569);
      _tooltipBorderWidth = 1;
      _tooltipCornerRadius = 6;
      _tooltipFontSize = 12;
      _tooltipPosition = TooltipPosition.auto;
      _tooltipFollowsCursor = false;
      _selectionEnabled = true;
      _keyboardEnabled = true;
      _showFocusBorder = false;
      _dataUpdateAnimation = CandlestickDataUpdateAnimationMode.interpolate;
      _entranceAnimation = CandlestickAnimationMode.reveal;
      _entranceStagger = .85;
      _animationDurationMs = 400;
      _motionCurve = _CandlestickMotionCurve.easeInOutCubic;
      _revisionMagnitude = 4.6;
      _useDensityStressData = false;
      _densityGroupingEnabled = false;
      _targetGroupWidth = 5;
      _minimumPointsPerGroup = 2;
      _timeSpacing = FinancialTimeSpacing.ordinal;
      _selectedExample = _CandlestickExample.priceAction;
      _candlePalette = _CandlestickPalette.theme;
      _styleRecipe = _CandlestickStyleRecipe.balanced;
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
      _showMarketContext = false;
      _contextThresholdColor = const Color(0xFFF59E0B);
      _contextWindowColor = const Color(0xFF3B82F6);
      _contextEventColor = const Color(0xFF7C3AED);
      _contextLineWidth = 1.5;
      _contextLineDashed = true;
      _showcaseMode = _CandlestickShowcaseMode.workbench;
      _stockTimeSpacing = FinancialTimeSpacing.ordinal;
      _stockRange = _StockRangePreset.threeMonths;
      _showVolumePane = true;
      _regenerateWorkbenchData();
      _revisionStep = 0;
      _activeCandleIndex = null;
    });
    _pinnedSummaryCandle.value = null;
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

class _AnnotationPaletteOption extends StatelessWidget {
  const _AnnotationPaletteOption({
    required super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : assert(key is ValueKey<String>);

  final String label;
  final Color? value;
  final ValueChanged<Color?> onChanged;

  @override
  Widget build(BuildContext context) {
    final keyPrefix = (key! as ValueKey<String>).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (optional)',
          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: 8),
        ChartColorPalette(
          value: value,
          onChanged: onChanged,
          keyPrefix: keyPrefix,
          customColorFallback: value,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _OptionGroupLabel extends StatelessWidget {
  const _OptionGroupLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _PinnedOhlcSummaryCard extends StatelessWidget {
  const _PinnedOhlcSummaryCard({
    required this.title,
    required this.candle,
    required this.backgroundColor,
    required this.showShadow,
    required this.borderColor,
    required this.textColor,
    required this.accentColor,
    required this.borderWidth,
    required this.cornerRadius,
    required this.padding,
    required this.fontSize,
  });

  final String title;
  final CandlestickDataPoint candle;
  final Color backgroundColor;
  final bool showShadow;
  final Color borderColor;
  final Color textColor;
  final Color accentColor;
  final double borderWidth;
  final double cornerRadius;
  final double padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          '$title, open ${candle.open.toStringAsFixed(2)}, high ${candle.high.toStringAsFixed(2)}, low ${candle.low.toStringAsFixed(2)}, close ${candle.close.toStringAsFixed(2)}',
      child: Container(
        key: const ValueKey('candlestick-pinned-summary-card'),
        width: 168 + ((fontSize - 11).clamp(0, 5) * 5),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: showShadow
              ? const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontSize: fontSize + 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (candle.label case final label?) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withValues(alpha: .72),
                  fontSize: fontSize,
                ),
              ),
            ],
            const SizedBox(height: 6),
            _PinnedSummaryValue(
              label: 'Open',
              value: candle.open,
              color: textColor,
              fontSize: fontSize,
            ),
            _PinnedSummaryValue(
              label: 'High',
              value: candle.high,
              color: textColor,
              fontSize: fontSize,
            ),
            _PinnedSummaryValue(
              label: 'Low',
              value: candle.low,
              color: textColor,
              fontSize: fontSize,
            ),
            _PinnedSummaryValue(
              label: 'Close',
              value: candle.close,
              color: textColor,
              fontSize: fontSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedSummaryValue extends StatelessWidget {
  const _PinnedSummaryValue({
    required this.label,
    required this.value,
    required this.color,
    required this.fontSize,
  });

  final String label;
  final double value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color, fontSize: fontSize),
          ),
        ),
        Expanded(
          child: Text(
            '\$${value.toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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

const _pinnedSummaryAnnotationId = 'candlestick-pinned-ohlc-summary';

enum _PinnedSummaryPresentation { overlay, annotation }

enum _PinnedSummaryCorner { topLeft, topRight, bottomLeft, bottomRight }

enum _CandlestickShowcaseMode { workbench, stock }

enum _CandlestickExample {
  priceAction,
  trend,
  volatility,
  gapsAndDoji,
  events,
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

enum _CandlestickStyleRecipe {
  balanced('Balanced analytical'),
  trading('Trading terminal'),
  accessible('Accessible blue / orange'),
  print('Print-friendly mono'),
  event('Latest-event highlight');

  const _CandlestickStyleRecipe(this.label);

  final String label;
}

enum _CandlestickMotionCurve {
  linear('Linear', Curves.linear),
  easeOut('Ease out', Curves.easeOutCubic),
  easeInOutCubic('Ease in / out cubic', Curves.easeInOutCubic),
  fastOutSlowIn('Fast out / slow in', Curves.fastOutSlowIn);

  const _CandlestickMotionCurve(this.label, this.curve);

  final String label;
  final Curve curve;
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

// Period buttons and every attached chart use the same viewport authority.
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

CartesianNavigator(
  interactionGroupController: viewport,
  fullDomain: ChartXViewport(min: domainStart, max: domainEnd),
  initialViewport: ChartXViewport(min: rangeStart, max: rangeEnd),
  snapPolicy: CartesianNavigatorSnapPolicy.values(sessionXValues),
  overviewSeries: AreaChartSeries(id: 'navigator', points: closes),
);
''';
