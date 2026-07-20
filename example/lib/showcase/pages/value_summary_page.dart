// Copyright 2026 Braven Charts - Value Summary Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// First-class guide to the Cartesian value summary.
///
/// The value summary keeps the policy-resolved datum visible in a persistent
/// in-plot panel, independent of the crosshair tracking panel and the point
/// tooltip. Presets cover single-series fallback, crosshair independence,
/// multi-axis units, candlestick OHLC rows, a synchronized chart pair, and a
/// programmatic pinning workflow; the options panel exercises placement,
/// value policy, and the tri-state style model live.
class ValueSummaryPage extends StatefulWidget {
  const ValueSummaryPage({super.key});

  @override
  State<ValueSummaryPage> createState() => _ValueSummaryPageState();
}

class _ValueSummaryPageState extends State<ValueSummaryPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final _ShowcaseSummaryController _summaryController =
      _ShowcaseSummaryController();
  final ChartInteractionGroupController _syncGroup =
      ChartInteractionGroupController();
  late final List<CandlestickDataPoint> _candles = _buildSummaryCandles();

  _SummaryPreset _preset = _SummaryPreset.line;
  _PolicyChoice _policyChoice = _PolicyChoice.presetDefault;

  // Summary options.
  bool _summaryEnabled = true;
  Alignment _anchor = Alignment.topLeft;
  double _offsetX = 12;
  double _offsetY = 12;
  bool _showAccent = true;
  bool _announceChanges = false;
  bool _crosshairEnabled = _SummaryPreset.line.defaultCrosshair;

  // Tri-state style options. Color fields hold the ChartStyleValue directly;
  // the sliders keep a plain value plus an "overridden" flag so an untouched
  // slider still resolves through ChartStyleValue.inherit().
  ChartStyleValue<Color> _backgroundColor = const ChartStyleValue.inherit();
  ChartStyleValue<Color> _borderColor = const ChartStyleValue.inherit();
  ChartStyleValue<Color> _accentColor = const ChartStyleValue.inherit();
  double _backgroundOpacity = 0.92;
  bool _backgroundOpacityOverridden = false;
  double _cornerRadius = 8;
  bool _cornerRadiusOverridden = false;
  double _panelPadding = 8;
  bool _panelPaddingOverridden = false;

  @override
  void dispose() {
    _optionsController.dispose();
    _summaryController.dispose();
    _syncGroup.dispose();
    super.dispose();
  }

  CartesianValueSummaryValuePolicy get _effectivePolicy =>
      switch (_policyChoice) {
        _PolicyChoice.presetDefault => _preset.defaultPolicy,
        _PolicyChoice.trackingThenLatest =>
          CartesianValueSummaryValuePolicy.trackingThenLatest,
        _PolicyChoice.trackingThenFirst =>
          CartesianValueSummaryValuePolicy.trackingThenFirst,
        _PolicyChoice.selectionThenTrackingThenLatest =>
          CartesianValueSummaryValuePolicy.selectionThenTrackingThenLatest,
        _PolicyChoice.pinnedThenTrackingThenLatest =>
          CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
        _PolicyChoice.explicitOnly =>
          CartesianValueSummaryValuePolicy.explicitOnly,
      };

  bool get _pinControlsVisible =>
      _preset != _SummaryPreset.synchronized &&
      (_effectivePolicy ==
              CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest ||
          _effectivePolicy == CartesianValueSummaryValuePolicy.explicitOnly);

  CartesianValueSummaryStyle get _summaryStyle => CartesianValueSummaryStyle(
    backgroundColor: _backgroundColor,
    borderColor: _borderColor,
    accentColor: _accentColor,
    backgroundOpacity: _backgroundOpacityOverridden
        ? ChartStyleValue.value(_backgroundOpacity)
        : const ChartStyleValue.inherit(),
    borderRadius: _cornerRadiusOverridden
        ? ChartStyleValue.value(BorderRadius.circular(_cornerRadius))
        : const ChartStyleValue.inherit(),
    padding: _panelPaddingOverridden
        ? ChartStyleValue.value(EdgeInsets.all(_panelPadding))
        : const ChartStyleValue.inherit(),
  );

  CartesianValueSummaryConfig _summaryConfig({bool withController = true}) =>
      CartesianValueSummaryConfig(
        enabled: _summaryEnabled,
        presentation: CartesianValueSummaryPresentation.overlay(
          placement: ChartOverlayPlacement(
            anchor: _anchor,
            offset: Offset(_offsetX, _offsetY),
          ),
        ),
        valuePolicy: _effectivePolicy,
        style: _summaryStyle,
        showSeriesAccent: _showAccent,
        announceChanges: _announceChanges,
        controller: withController ? _summaryController : null,
      );

  void _applyPreset(_SummaryPreset preset) {
    if (_preset == preset) return;
    setState(() {
      _preset = preset;
      _policyChoice = _PolicyChoice.presetDefault;
      _crosshairEnabled = preset.defaultCrosshair;
      _summaryController.clearPin();
    });
  }

  void _resetStyle() {
    setState(() {
      _backgroundColor = const ChartStyleValue.inherit();
      _borderColor = const ChartStyleValue.inherit();
      _accentColor = const ChartStyleValue.inherit();
      _backgroundOpacity = 0.92;
      _backgroundOpacityOverridden = false;
      _cornerRadius = 8;
      _cornerRadiusOverridden = false;
      _panelPadding = 8;
      _panelPaddingOverridden = false;
    });
  }

  void _pinLatest() {
    final (seriesId, lastIndex) = _pinTarget;
    _summaryController.pin(
      ChartPointRef(seriesId: seriesId, pointIndex: lastIndex),
    );
  }

  /// The explicit override color, or null when the field is inherit or none.
  /// The palette renders null as its leading clear swatch being selected.
  static Color? _explicitColor(ChartStyleValue<Color> value) =>
      value is ChartStyleExplicit<Color> ? value.value : null;

  /// Maps a palette selection onto the tri-state model: a picked color
  /// (preset swatch or the custom dialog, including its alpha slider) becomes
  /// an explicit override; clearing (the leading clear swatch, or tapping the
  /// selected swatch again) becomes [ChartStyleValue.none]. Only "Reset Style
  /// to Theme" returns a field to [ChartStyleValue.inherit].
  static ChartStyleValue<Color> _styleValueFor(Color? color) => color == null
      ? const ChartStyleValue<Color>.none()
      : ChartStyleValue<Color>.value(color);

  static String _styleSubtitle(
    ChartStyleValue<Color> value, {
    required String whenNone,
  }) => value.isInherit
      ? 'ChartStyleValue.inherit() — the theme resolves it'
      : value.isNone
      ? whenNone
      : 'ChartStyleValue.value() — explicit override';

  (String, int) get _pinTarget => switch (_preset) {
    _SummaryPreset.line => ('summary-speed', _speedPoints.length - 1),
    _SummaryPreset.multiSeries => ('rider-a', _riderAPoints.length - 1),
    _SummaryPreset.multiAxis => ('summary-vo2', _vo2Points.length - 1),
    _SummaryPreset.candlestick => ('summary-ohlc', _candles.length - 1),
    _SummaryPreset.synchronized => ('sync-speed', _syncSpeedPoints.length - 1),
    _SummaryPreset.pinned => ('summary-lactate', _lactatePoints.length - 1),
  };

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Value Summary',
      subtitle:
          'A persistent, policy-driven datum panel — independent of the '
          'crosshair and tooltip',
      optionsChildren: _buildOptionsChildren(),
      chart: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPresetPicker(),
          const SizedBox(height: 12),
          Expanded(child: _buildStage()),
        ],
      ),
    );
  }

  // ==========================================================================
  // Preset picker
  // ==========================================================================

  Widget _buildPresetPicker() {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chips = <Widget>[
              for (final preset in _SummaryPreset.values)
                ChoiceChip(
                  key: ValueKey('value-summary-preset-${preset.name}'),
                  showCheckmark: false,
                  selected: preset == _preset,
                  onSelected: (_) => _applyPreset(preset),
                  avatar: Icon(
                    preset.icon,
                    size: 17,
                    color: preset == _preset
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  label: Text(preset.label),
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: preset == _preset
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: preset == _preset
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                  selectedColor: theme.colorScheme.secondaryContainer,
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ];
            if (constraints.maxWidth < 900) {
              return SingleChildScrollView(
                key: const ValueKey('value-summary-preset-scroll'),
                scrollDirection: Axis.horizontal,
                child: Row(spacing: 6, children: chips),
              );
            }
            return Wrap(
              key: const ValueKey('value-summary-preset-wrap'),
              spacing: 6,
              runSpacing: 6,
              children: chips,
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // Stage
  // ==========================================================================

  Widget _buildStage() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return ChartCard(
          title: _preset.stageTitle,
          subtitle: _preset.stageSubtitle,
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
          child: switch (_preset) {
            _SummaryPreset.line => _buildLineChart(),
            _SummaryPreset.multiSeries => _buildMultiSeriesChart(),
            _SummaryPreset.multiAxis => _buildMultiAxisChart(),
            _SummaryPreset.candlestick => _buildCandlestickChart(),
            _SummaryPreset.synchronized => _buildSynchronizedPair(),
            _SummaryPreset.pinned => _buildPinnedChart(),
          },
        );
      },
    );
  }

  InteractionConfig _interaction({
    CrosshairMode crosshairMode = CrosshairMode.both,
    bool withController = true,
  }) {
    final options = _optionsController.options;
    return InteractionConfig(
      enableZoom: options.enableZoom,
      enablePan: options.enablePan,
      crosshair: CrosshairConfig(
        enabled: _crosshairEnabled,
        mode: crosshairMode,
        displayMode: CrosshairDisplayMode.tracking,
        interpolateValues: false,
        showTrackingTooltip: false,
        showCoordinateLabels: false,
        showIntersectionMarkers: true,
        intersectionMarkerRadius: 3.5,
      ),
      tooltip: const TooltipConfig(enabled: false),
      valueSummary: _summaryConfig(withController: withController),
    );
  }

  Widget _chart({
    required List<ChartSeries> series,
    required XAxisConfig xAxisConfig,
    YAxisConfig? yAxis,
    CrosshairMode crosshairMode = CrosshairMode.both,
    bool withController = true,
    bool showLegend = true,
    ChartInteractionGroupController? groupController,
    Key? key,
  }) {
    final options = _optionsController.options;
    return BravenChartPlus(
      key: key,
      series: series,
      theme: options.theme,
      showLegend: showLegend && options.showLegend,
      showXScrollbar: options.showXScrollbar,
      showYScrollbar: options.showYScrollbar,
      interactionGroupController: groupController,
      interactionGroupOptions: groupController == null
          ? const ChartInteractionGroupOptions()
          : const ChartInteractionGroupOptions(
              synchronizeCursor: true,
              synchronizeViewport: true,
            ),
      grid: GridConfig(horizontal: options.showGrid, vertical: false),
      xAxisConfig: xAxisConfig.copyWith(showAxisLine: options.showAxisLines),
      yAxis: yAxis?.copyWith(showAxisLine: options.showAxisLines),
      interactionConfig: _interaction(
        crosshairMode: crosshairMode,
        withController: withController,
      ),
    );
  }

  Widget _buildLineChart() {
    return _chart(
      key: const ValueKey('value-summary-stage-line'),
      series: const [
        LineChartSeries(
          id: 'summary-speed',
          name: 'Speed',
          unit: 'km/h',
          points: _speedPoints,
          color: Color(0xFF0891B2),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.5,
        ),
      ],
      xAxisConfig: const XAxisConfig(label: 'Distance', unit: 'km'),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Speed',
        unit: 'km/h',
      ),
    );
  }

  Widget _buildMultiSeriesChart() {
    return _chart(
      key: const ValueKey('value-summary-stage-multi-series'),
      series: const [
        LineChartSeries(
          id: 'rider-a',
          name: 'Rider A',
          unit: 'W',
          points: _riderAPoints,
          color: Color(0xFF4F46E5),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.4,
        ),
        AreaChartSeries(
          id: 'rider-b',
          name: 'Rider B',
          unit: 'W',
          points: _riderBPoints,
          color: Color(0xFF10B981),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2,
          fillOpacity: 0.18,
        ),
        LineChartSeries(
          id: 'rider-c',
          name: 'Rider C',
          unit: 'W',
          points: _riderCPoints,
          color: Color(0xFFF59E0B),
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2.4,
        ),
      ],
      xAxisConfig: const XAxisConfig(label: 'Time', unit: 'min'),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Power',
        unit: 'W',
      ),
    );
  }

  Widget _buildMultiAxisChart() {
    return _chart(
      key: const ValueKey('value-summary-stage-multi-axis'),
      series: [
        LineChartSeries(
          id: 'summary-vo2',
          name: 'VO₂',
          unit: 'mL/kg/min',
          points: _vo2Points,
          color: const Color(0xFF1565C0),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.4,
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.left,
            label: 'VO₂',
            unit: 'mL/kg/min',
            color: const Color(0xFF1565C0),
          ).copyWith(id: 'summary-vo2-axis'),
        ),
        LineChartSeries(
          id: 'summary-hr',
          name: 'Heart rate',
          unit: 'bpm',
          points: _hrPoints,
          color: const Color(0xFFE53935),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.2,
          yAxisConfig: YAxisConfig(
            position: YAxisPosition.right,
            label: 'Heart rate',
            unit: 'bpm',
            color: const Color(0xFFE53935),
          ).copyWith(id: 'summary-hr-axis'),
        ),
      ],
      xAxisConfig: const XAxisConfig(
        label: 'Time',
        unit: 'min',
        min: 0,
        max: 30,
      ),
    );
  }

  Widget _buildCandlestickChart() {
    return _chart(
      key: const ValueKey('value-summary-stage-candlestick'),
      series: [
        CandlestickChartSeries(
          id: 'summary-ohlc',
          name: 'Session price',
          unit: 'USD',
          points: _candles,
        ),
      ],
      crosshairMode: CrosshairMode.vertical,
      xAxisConfig: const XAxisConfig(label: 'Session'),
      yAxis: YAxisConfig(
        position: YAxisPosition.right,
        label: 'Price',
        unit: 'USD',
      ),
    );
  }

  Widget _buildSynchronizedPair() {
    return Column(
      children: [
        Expanded(
          child: _chart(
            key: const ValueKey('value-summary-stage-sync-speed'),
            groupController: _syncGroup,
            withController: false,
            showLegend: false,
            series: const [
              LineChartSeries(
                id: 'sync-speed',
                name: 'Speed',
                unit: 'km/h',
                points: _syncSpeedPoints,
                color: Color(0xFF0891B2),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2.5,
              ),
            ],
            xAxisConfig: const XAxisConfig(visible: false, minHeight: 0),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Speed',
              unit: 'km/h',
              minWidth: 64,
              maxWidth: 64,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: _chart(
            key: const ValueKey('value-summary-stage-sync-hr'),
            groupController: _syncGroup,
            withController: false,
            showLegend: false,
            series: const [
              LineChartSeries(
                id: 'sync-heart-rate',
                name: 'Heart rate',
                unit: 'bpm',
                points: _syncHeartRatePoints,
                color: Color(0xFFE11D48),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2.5,
              ),
            ],
            xAxisConfig: const XAxisConfig(label: 'Distance', unit: 'km'),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Heart rate',
              unit: 'bpm',
              minWidth: 64,
              maxWidth: 64,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinnedChart() {
    return _chart(
      key: const ValueKey('value-summary-stage-pinned'),
      series: const [
        LineChartSeries(
          id: 'summary-lactate',
          name: 'Lactate',
          unit: 'mmol/L',
          points: _lactatePoints,
          color: Color(0xFF2E7D32),
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.5,
          showDataPointMarkers: true,
          dataPointMarkerRadius: 4,
        ),
      ],
      xAxisConfig: const XAxisConfig(label: 'Power', unit: 'W'),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Lactate',
        unit: 'mmol/L',
      ),
    );
  }

  // ==========================================================================
  // Options panel
  // ==========================================================================

  List<Widget> _buildOptionsChildren() {
    return [
      OptionSection(
        title: 'Summary',
        icon: Icons.summarize_outlined,
        children: [
          BoolOption(
            key: const ValueKey('value-summary-enabled'),
            label: 'Show Value Summary',
            value: _summaryEnabled,
            onChanged: (value) => setState(() => _summaryEnabled = value),
          ),
          const SizedBox(height: 4),
          Text(
            'Anchor corner',
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          SegmentedOption<Alignment>(
            value: _anchor,
            options: const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ],
            labelBuilder: (anchor) => switch (anchor) {
              Alignment.topLeft => 'TL',
              Alignment.topRight => 'TR',
              Alignment.bottomLeft => 'BL',
              _ => 'BR',
            },
            onChanged: (anchor) => setState(() => _anchor = anchor),
          ),
          const SizedBox(height: 8),
          SliderOption(
            label: 'Inset X',
            value: _offsetX,
            min: 0,
            max: 64,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _offsetX = value),
          ),
          SliderOption(
            label: 'Inset Y',
            value: _offsetY,
            min: 0,
            max: 64,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() => _offsetY = value),
          ),
          EnumOption<_PolicyChoice>(
            label: 'Value policy',
            subtitle: 'How the displayed datum is chosen',
            value: _policyChoice,
            values: _PolicyChoice.values,
            labelBuilder: (choice) => switch (choice) {
              _PolicyChoice.presetDefault =>
                'Preset default (${_preset.defaultPolicy.name})',
              _PolicyChoice.trackingThenLatest => 'Tracking, then latest',
              _PolicyChoice.trackingThenFirst => 'Tracking, then first',
              _PolicyChoice.selectionThenTrackingThenLatest =>
                'Selection, tracking, latest',
              _PolicyChoice.pinnedThenTrackingThenLatest =>
                'Pinned, tracking, latest',
              _PolicyChoice.explicitOnly => 'Explicit pin only',
            },
            onChanged: (choice) => setState(() => _policyChoice = choice),
          ),
          BoolOption(
            label: 'Series Accent Marks',
            value: _showAccent,
            onChanged: (value) => setState(() => _showAccent = value),
          ),
          BoolOption(
            label: 'Announce Changes',
            subtitle: 'Debounced screen-reader announcements',
            value: _announceChanges,
            onChanged: (value) => setState(() => _announceChanges = value),
          ),
        ],
      ),
      if (_pinControlsVisible)
        OptionSection(
          title: 'Pinning',
          icon: Icons.push_pin_outlined,
          children: [
            ListenableBuilder(
              listenable: _summaryController,
              builder: (context, _) {
                final pinned = _summaryController.pinnedPoint;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InfoBox(
                      message: pinned == null
                          ? 'Nothing pinned. The summary follows the active '
                                'policy chain.'
                          : 'Pinned ${pinned.seriesId} '
                                '[${pinned.pointIndex}]. Hover elsewhere — '
                                'the pin holds.',
                      type: pinned == null
                          ? InfoBoxType.info
                          : InfoBoxType.success,
                    ),
                    const SizedBox(height: 8),
                    ActionButton(
                      key: const ValueKey('value-summary-pin-latest'),
                      label: 'Pin Latest Point',
                      icon: Icons.push_pin,
                      isPrimary: true,
                      onPressed: _pinLatest,
                    ),
                    const SizedBox(height: 8),
                    ActionButton(
                      key: const ValueKey('value-summary-clear-pin'),
                      label: 'Clear Pin',
                      icon: Icons.close,
                      onPressed: _summaryController.clearPin,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      OptionSection(
        title: 'Style',
        icon: Icons.format_paint_outlined,
        children: [
          PaletteColorOption(
            label: 'Background color',
            subtitle: _styleSubtitle(
              _backgroundColor,
              whenNone: 'ChartStyleValue.none() — truly transparent',
            ),
            keyPrefix: 'value-summary-background-color',
            value: _explicitColor(_backgroundColor),
            customColorFallback: _explicitColor(_backgroundColor),
            onChanged: (color) =>
                setState(() => _backgroundColor = _styleValueFor(color)),
          ),
          PaletteColorOption(
            label: 'Border color',
            subtitle: _styleSubtitle(
              _borderColor,
              whenNone: 'ChartStyleValue.none() — no stroke',
            ),
            keyPrefix: 'value-summary-border-color',
            value: _explicitColor(_borderColor),
            customColorFallback: _explicitColor(_borderColor),
            onChanged: (color) =>
                setState(() => _borderColor = _styleValueFor(color)),
          ),
          PaletteColorOption(
            label: 'Accent color',
            subtitle: _styleSubtitle(
              _accentColor,
              whenNone: 'ChartStyleValue.none() — hides the accent marks',
            ),
            keyPrefix: 'value-summary-accent-color',
            value: _explicitColor(_accentColor),
            customColorFallback: _explicitColor(_accentColor),
            onChanged: (color) =>
                setState(() => _accentColor = _styleValueFor(color)),
          ),
          SliderOption(
            label: 'Background opacity',
            value: _backgroundOpacity,
            min: 0,
            max: 1,
            decimalPlaces: 2,
            onChanged: (value) => setState(() {
              _backgroundOpacity = value;
              _backgroundOpacityOverridden = true;
            }),
          ),
          SliderOption(
            label: 'Corner radius',
            value: _cornerRadius,
            min: 0,
            max: 24,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() {
              _cornerRadius = value;
              _cornerRadiusOverridden = true;
            }),
          ),
          SliderOption(
            label: 'Panel padding',
            value: _panelPadding,
            min: 0,
            max: 24,
            suffix: 'px',
            decimalPlaces: 0,
            onChanged: (value) => setState(() {
              _panelPadding = value;
              _panelPaddingOverridden = true;
            }),
          ),
          ActionButton(
            key: const ValueKey('value-summary-reset-style'),
            label: 'Reset Style to Theme',
            icon: Icons.restart_alt,
            onPressed: _resetStyle,
          ),
        ],
      ),
      OptionSection(
        title: 'Independence',
        icon: Icons.call_split,
        children: [
          BoolOption(
            key: const ValueKey('value-summary-crosshair'),
            label: 'Enable Crosshair',
            subtitle: 'The summary keeps tracking either way',
            value: _crosshairEnabled,
            onChanged: (value) => setState(() => _crosshairEnabled = value),
          ),
        ],
      ),
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
        showMarkerOption: false,
        showScrollbarOptions: false,
      ),
      OptionSection(
        title: 'How to Explore',
        icon: Icons.info_outline,
        children: [InfoBox(message: _preset.guide)],
      ),
    ];
  }
}

// ============================================================================
// Presets
// ============================================================================

enum _SummaryPreset {
  line,
  multiSeries,
  multiAxis,
  candlestick,
  synchronized,
  pinned,
}

extension on _SummaryPreset {
  String get label => switch (this) {
    _SummaryPreset.line => 'Line',
    _SummaryPreset.multiSeries => 'Multi-series',
    _SummaryPreset.multiAxis => 'Multi-axis',
    _SummaryPreset.candlestick => 'Candlestick',
    _SummaryPreset.synchronized => 'Synchronized',
    _SummaryPreset.pinned => 'Pinned',
  };

  IconData get icon => switch (this) {
    _SummaryPreset.line => Icons.show_chart,
    _SummaryPreset.multiSeries => Icons.stacked_line_chart,
    _SummaryPreset.multiAxis => Icons.align_vertical_bottom,
    _SummaryPreset.candlestick => Icons.candlestick_chart_outlined,
    _SummaryPreset.synchronized => Icons.sync_alt,
    _SummaryPreset.pinned => Icons.push_pin_outlined,
  };

  String get stageTitle => switch (this) {
    _SummaryPreset.line => 'Single series with latest fallback',
    _SummaryPreset.multiSeries => 'Three riders, crosshair off',
    _SummaryPreset.multiAxis => 'Dual axes with units',
    _SummaryPreset.candlestick => 'OHLC session summary',
    _SummaryPreset.synchronized => 'Synchronized pair',
    _SummaryPreset.pinned => 'Pinned datum workflow',
  };

  String get stageSubtitle => switch (this) {
    _SummaryPreset.line =>
      'The panel shows the latest datum before any pointer arrives',
    _SummaryPreset.multiSeries =>
      'The summary tracks the shared X while the crosshair stays disabled',
    _SummaryPreset.multiAxis =>
      'Each row keeps its own axis unit — mL/kg/min on the left, bpm on the '
          'right',
    _SummaryPreset.candlestick =>
      'Open, high, low, close, change, and direction for the hovered session',
    _SummaryPreset.synchronized =>
      'One shared cursor, two charts — each summary resolves its own series '
          'at the shared X',
    _SummaryPreset.pinned =>
      'Pin the latest point, hover elsewhere, and watch the pin hold',
  };

  CartesianValueSummaryValuePolicy get defaultPolicy => switch (this) {
    _SummaryPreset.pinned =>
      CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
    _ => CartesianValueSummaryValuePolicy.trackingThenLatest,
  };

  bool get defaultCrosshair => switch (this) {
    _SummaryPreset.multiSeries => false,
    _ => true,
  };

  String get guide => switch (this) {
    _SummaryPreset.line =>
      'The summary panel is visible before you touch the chart: the '
          'trackingThenLatest policy falls back to the latest visible datum. '
          'Hover to track, leave to fall back. Pan or zoom to see the panel '
          'freeze until the gesture ends.',
    _SummaryPreset.multiSeries =>
      'The crosshair is disabled on this preset, yet the summary still '
          'tracks the pointer — the two feedback layers are fully '
          'independent. Re-enable the crosshair under Independence.',
    _SummaryPreset.multiAxis =>
      'Two independently scaled axes: every summary row is formatted with '
          'its own axis unit.',
    _SummaryPreset.candlestick =>
      'Candlestick series produce rich OHLC rows automatically. Hover any '
          'session to inspect its open, high, low, close, and change.',
    _SummaryPreset.synchronized =>
      'Hover either chart: the shared cursor broadcasts one X position and '
          'each chart resolves its own series locally, so both panels stay '
          'in lockstep without duplicating state.',
    _SummaryPreset.pinned =>
      'Pin the latest point, then hover elsewhere: under '
          'pinnedThenTrackingThenLatest the pin wins until you clear it. '
          'Switch the policy to "Explicit pin only" to hide the panel until '
          'a pin exists.',
  };
}

enum _PolicyChoice {
  presetDefault,
  trackingThenLatest,
  trackingThenFirst,
  selectionThenTrackingThenLatest,
  pinnedThenTrackingThenLatest,
  explicitOnly,
}

/// A listenable pin controller: the package ships only the abstract
/// [CartesianValueSummaryController] interface, so applications provide the
/// notifying implementation.
class _ShowcaseSummaryController extends ChangeNotifier
    implements CartesianValueSummaryController {
  ChartPointRef? _pinnedPoint;

  @override
  ChartPointRef? get pinnedPoint => _pinnedPoint;

  @override
  void pin(ChartPointRef point) {
    if (_pinnedPoint == point) return;
    _pinnedPoint = point;
    notifyListeners();
  }

  @override
  void clearPin() {
    if (_pinnedPoint == null) return;
    _pinnedPoint = null;
    notifyListeners();
  }

  @override
  void resetPlacement() => notifyListeners();
}

// ============================================================================
// Data
// ============================================================================

const _speedPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 24),
  ChartDataPoint(x: 2, y: 28),
  ChartDataPoint(x: 4, y: 31),
  ChartDataPoint(x: 6, y: 27),
  ChartDataPoint(x: 8, y: 34),
  ChartDataPoint(x: 10, y: 36),
  ChartDataPoint(x: 12, y: 32),
  ChartDataPoint(x: 14, y: 38),
  ChartDataPoint(x: 16, y: 35),
  ChartDataPoint(x: 18, y: 41),
  ChartDataPoint(x: 20, y: 39),
];

const _riderAPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 210),
  ChartDataPoint(x: 2, y: 236),
  ChartDataPoint(x: 4, y: 248),
  ChartDataPoint(x: 6, y: 261),
  ChartDataPoint(x: 8, y: 255),
  ChartDataPoint(x: 10, y: 272),
  ChartDataPoint(x: 12, y: 284),
  ChartDataPoint(x: 14, y: 279),
  ChartDataPoint(x: 16, y: 295),
  ChartDataPoint(x: 18, y: 301),
  ChartDataPoint(x: 20, y: 288),
];

const _riderBPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 188),
  ChartDataPoint(x: 2, y: 204),
  ChartDataPoint(x: 4, y: 222),
  ChartDataPoint(x: 6, y: 214),
  ChartDataPoint(x: 8, y: 236),
  ChartDataPoint(x: 10, y: 249),
  ChartDataPoint(x: 12, y: 241),
  ChartDataPoint(x: 14, y: 258),
  ChartDataPoint(x: 16, y: 266),
  ChartDataPoint(x: 18, y: 254),
  ChartDataPoint(x: 20, y: 271),
];

const _riderCPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 242),
  ChartDataPoint(x: 2, y: 251),
  ChartDataPoint(x: 4, y: 239),
  ChartDataPoint(x: 6, y: 268),
  ChartDataPoint(x: 8, y: 277),
  ChartDataPoint(x: 10, y: 262),
  ChartDataPoint(x: 12, y: 290),
  ChartDataPoint(x: 14, y: 297),
  ChartDataPoint(x: 16, y: 283),
  ChartDataPoint(x: 18, y: 309),
  ChartDataPoint(x: 20, y: 315),
];

const _vo2Points = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 20),
  ChartDataPoint(x: 5, y: 23),
  ChartDataPoint(x: 10, y: 29),
  ChartDataPoint(x: 15, y: 38),
  ChartDataPoint(x: 20, y: 49),
  ChartDataPoint(x: 25, y: 57),
  ChartDataPoint(x: 30, y: 60),
];

const _hrPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 65),
  ChartDataPoint(x: 5, y: 78),
  ChartDataPoint(x: 10, y: 98),
  ChartDataPoint(x: 15, y: 122),
  ChartDataPoint(x: 20, y: 148),
  ChartDataPoint(x: 25, y: 168),
  ChartDataPoint(x: 30, y: 178),
];

const _syncSpeedPoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 22),
  ChartDataPoint(x: 2, y: 28),
  ChartDataPoint(x: 4, y: 31),
  ChartDataPoint(x: 6, y: 27),
  ChartDataPoint(x: 8, y: 34),
  ChartDataPoint(x: 10, y: 36),
  ChartDataPoint(x: 12, y: 32),
  ChartDataPoint(x: 14, y: 38),
  ChartDataPoint(x: 16, y: 35),
  ChartDataPoint(x: 18, y: 41),
  ChartDataPoint(x: 20, y: 39),
];

const _syncHeartRatePoints = <ChartDataPoint>[
  ChartDataPoint(x: 0, y: 118),
  ChartDataPoint(x: 2, y: 126),
  ChartDataPoint(x: 4, y: 138),
  ChartDataPoint(x: 6, y: 147),
  ChartDataPoint(x: 8, y: 154),
  ChartDataPoint(x: 10, y: 149),
  ChartDataPoint(x: 12, y: 158),
  ChartDataPoint(x: 14, y: 166),
  ChartDataPoint(x: 16, y: 161),
  ChartDataPoint(x: 18, y: 172),
  ChartDataPoint(x: 20, y: 168),
];

const _lactatePoints = <ChartDataPoint>[
  ChartDataPoint(x: 150, y: 0.9),
  ChartDataPoint(x: 175, y: 1.1),
  ChartDataPoint(x: 200, y: 1.4),
  ChartDataPoint(x: 225, y: 1.9),
  ChartDataPoint(x: 250, y: 2.8),
  ChartDataPoint(x: 275, y: 4.6),
  ChartDataPoint(x: 300, y: 7.3),
  ChartDataPoint(x: 325, y: 10.2),
];

/// Deterministic OHLC sessions (no randomness so tests and hot reload see the
/// same shapes).
List<CandlestickDataPoint> _buildSummaryCandles() {
  var previousClose = 186.0;
  return List<CandlestickDataPoint>.generate(28, (index) {
    final movement = math.sin(index * .58) * 3.4 + math.cos(index * .21) * 1.6;
    final open = previousClose;
    final close = open + movement;
    final high = math.max(open, close) + 1.4 + (index % 4) * .5;
    final low = math.min(open, close) - 1.2 - (index % 3) * .6;
    previousClose = close;
    return CandlestickDataPoint(
      x: index.toDouble(),
      open: open,
      high: high,
      low: low,
      close: close,
    );
  }, growable: false);
}
