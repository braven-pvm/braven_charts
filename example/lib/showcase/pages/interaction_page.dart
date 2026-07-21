// Copyright 2025 Braven Charts - Interaction Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

/// Browse and configure direct exploration and multi-series tracking patterns.
class InteractionPage extends StatefulWidget {
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final ChartInteractionGroupController _navigatorController =
      ChartInteractionGroupController();

  _InteractionMode _mode = _InteractionMode.explore;
  _CurveStudy _curveStudy = _CurveStudy.interpolation;
  bool _showTrackingTooltip = true;
  bool _showIntersectionMarkers = true;
  bool _enableCrosshair = true;
  bool _enableTooltips = true;
  bool _useConstrainedLayout = false;

  ChartDataPoint? _hoveredPoint;
  ChartDataPoint? _tappedPoint;
  late List<ChartDataPoint> _interactionData;
  late List<ChartDataPoint> _navigatorData;
  int _navigatorPointCount = 160;
  double _navigatorCycles = 4;
  int _navigatorRevision = 0;

  @override
  void initState() {
    super.initState();
    _regenerateInteractionData();
    _regenerateNavigatorData();
    _navigatorController.viewportListenable.addListener(
      _handleNavigatorViewportChanged,
    );
    final requestedMode = Uri.base.queryParameters['mode'];
    for (final mode in _InteractionMode.values) {
      if (mode.name == requestedMode) {
        _mode = mode;
        break;
      }
    }
  }

  void _regenerateInteractionData() {
    _interactionData = DataGenerator.generateRandomWalk(
      count: 80,
      startY: 50,
      stepSize: 9,
    );
  }

  void _regenerateNavigatorData() {
    final phase = _navigatorRevision * 0.37;
    _navigatorData = List<ChartDataPoint>.generate(_navigatorPointCount, (
      index,
    ) {
      final progress = index / (_navigatorPointCount - 1);
      final primary = math.sin(
        progress * math.pi * 2 * _navigatorCycles + phase,
      );
      final detail = math.sin(
        progress * math.pi * 2 * (_navigatorCycles * 2.35) + phase * 0.7,
      );
      final pulse = math.cos(progress * math.pi * 2 * 1.5 - phase * 0.45);
      return ChartDataPoint(
        x: index.toDouble(),
        y: 52 + primary * 11 + detail * 3.8 + pulse * 2.2 + progress * 8,
      );
    }, growable: false);
  }

  void _handleNavigatorViewportChanged() {
    if (!mounted || _mode != _InteractionMode.navigator) return;
    setState(() {});
  }

  void _setNavigatorPointCount(int value) {
    if (value == _navigatorPointCount) return;
    setState(() {
      _navigatorPointCount = value;
      _regenerateNavigatorData();
    });
  }

  void _setNavigatorCycles(double value) {
    if (value == _navigatorCycles) return;
    setState(() {
      _navigatorCycles = value;
      _regenerateNavigatorData();
    });
  }

  void _reseedNavigatorData() {
    setState(() {
      _navigatorRevision++;
      _regenerateNavigatorData();
    });
  }

  void _showNavigatorWindow(double startFraction, double endFraction) {
    final domainMax = (_navigatorPointCount - 1).toDouble();
    final min = (domainMax * startFraction).roundToDouble();
    final max = (domainMax * endFraction).roundToDouble();
    _navigatorController.setViewport(ChartXViewport(min: min, max: max));
  }

  void _selectMode(_InteractionMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  @override
  void dispose() {
    _navigatorController.viewportListenable.removeListener(
      _handleNavigatorViewportChanged,
    );
    _navigatorController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Interaction',
      subtitle: 'Choose an interaction pattern, then configure it live',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      OptionSection(
        title: 'Interaction Mode',
        icon: Icons.touch_app_outlined,
        children: [
          EnumOption<_InteractionMode>(
            label: 'Pattern',
            value: _mode,
            values: _InteractionMode.values,
            labelBuilder: _modeLabel,
            onChanged: _selectMode,
          ),
        ],
      ),
      if (_mode == _InteractionMode.explore)
        OptionSection(
          title: 'Explore & Select',
          icon: Icons.ads_click,
          children: [
            BoolOption(
              label: 'Enable Crosshair',
              value: _enableCrosshair,
              onChanged: (value) => setState(() => _enableCrosshair = value),
            ),
            BoolOption(
              label: 'Enable Tooltips',
              value: _enableTooltips,
              onChanged: (value) => setState(() => _enableTooltips = value),
            ),
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
      if (_mode != _InteractionMode.explore &&
          _mode != _InteractionMode.navigator)
        OptionSection(
          title: 'Tracking Overlay',
          icon: Icons.track_changes,
          children: [
            BoolOption(
              label: 'Show Tracking Tooltip',
              value: _showTrackingTooltip,
              onChanged: (value) =>
                  setState(() => _showTrackingTooltip = value),
            ),
            BoolOption(
              label: 'Show Intersection Markers',
              value: _showIntersectionMarkers,
              onChanged: (value) =>
                  setState(() => _showIntersectionMarkers = value),
            ),
          ],
        ),
      if (_mode == _InteractionMode.navigator) ...[
        OptionSection(
          title: 'Navigator Data',
          icon: Icons.dataset_outlined,
          children: [
            IntSliderOption(
              label: 'Data Points',
              value: _navigatorPointCount,
              min: 24,
              max: 400,
              suffix: 'points',
              onChanged: _setNavigatorPointCount,
            ),
            SliderOption(
              label: 'Signal Cycles',
              value: _navigatorCycles,
              min: 1,
              max: 8,
              divisions: 14,
              suffix: 'cycles',
              onChanged: _setNavigatorCycles,
            ),
            ActionButton(
              label: 'Regenerate Signal',
              icon: Icons.auto_graph_outlined,
              onPressed: _reseedNavigatorData,
            ),
          ],
        ),
        OptionSection(
          title: 'Viewport Controller',
          icon: Icons.settings_ethernet,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _navigatorViewportSummary(),
                key: const ValueKey('navigator-viewport-summary'),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            _buildNavigatorControllerActions(),
          ],
        ),
      ],
      if (_mode == _InteractionMode.normalize)
        OptionSection(
          title: 'Layout',
          icon: Icons.vertical_split_outlined,
          children: [
            BoolOption(
              label: 'Use Constrained Split Pane',
              value: _useConstrainedLayout,
              subtitle: 'Validate tracking inside a narrow analytical panel',
              onChanged: (value) =>
                  setState(() => _useConstrainedLayout = value),
            ),
          ],
        ),
      if (_mode == _InteractionMode.curves)
        OptionSection(
          title: 'Curve Study',
          icon: Icons.multiline_chart,
          children: [
            EnumOption<_CurveStudy>(
              label: 'Comparison',
              value: _curveStudy,
              values: _CurveStudy.values,
              labelBuilder: (value) => switch (value) {
                _CurveStudy.interpolation => 'Interpolation methods',
                _CurveStudy.tension => 'Bezier tension',
              },
              onChanged: (value) => setState(() => _curveStudy = value),
            ),
          ],
        ),
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'How to Explore',
        icon: Icons.info_outline,
        children: [InfoBox(message: _modeGuide())],
      ),
      if (_mode != _InteractionMode.navigator)
        OptionSection(
          title: 'Dataset',
          icon: Icons.refresh,
          children: [
            ActionButton(
              label: 'Refresh Example Data',
              icon: Icons.refresh,
              onPressed: () => setState(_regenerateInteractionData),
            ),
          ],
        ),
    ];
  }

  Widget _buildWorkspace() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an interaction pattern',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 168, child: _buildModeRibbon()),
            const SizedBox(height: 16),
            Expanded(child: _buildMainStage()),
          ],
        );
      },
    );
  }

  Widget _buildModeRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minimumCardWidth = 168.0;
        final fitWidth =
            (constraints.maxWidth -
                spacing * (_InteractionMode.values.length - 1)) /
            _InteractionMode.values.length;
        final cardWidth = fitWidth >= minimumCardWidth
            ? fitWidth
            : minimumCardWidth;

        return ListView.separated(
          key: const ValueKey('interaction-mode-ribbon'),
          scrollDirection: Axis.horizontal,
          itemCount: _InteractionMode.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final mode = _InteractionMode.values[index];
            return SizedBox(
              width: cardWidth,
              child: _InteractionPreviewCard(
                key: ValueKey('interaction-preview-${mode.name}'),
                mode: mode,
                label: _modeLabel(mode),
                description: _modeDescription(mode),
                selected: _mode == mode,
                onTap: () => _selectMode(mode),
                chart: _buildPreviewChart(mode),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewChart(_InteractionMode mode) {
    return BravenChartPlus(
      series: _previewSeries(mode),
      theme: _optionsController.theme ?? ChartTheme.light,
      showLegend: false,
      grid: const GridConfig(horizontal: false, vertical: false),
      xAxisConfig: const XAxisConfig(
        visible: false,
        minHeight: 0,
        maxHeight: 0,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.hidden,
        minWidth: 0,
        maxWidth: 0,
      ),
      normalizationMode: switch (mode) {
        _InteractionMode.track => NormalizationMode.perSeries,
        _InteractionMode.normalize => NormalizationMode.auto,
        _ => NormalizationMode.none,
      },
      interactionConfig: InteractionConfig.none(),
    );
  }

  List<ChartSeries> _previewSeries(_InteractionMode mode) {
    switch (mode) {
      case _InteractionMode.explore:
        return [
          LineChartSeries(
            id: 'preview-explore',
            name: 'Explore',
            points: _interactionData,
            color: const Color(0xFF4F46E5),
            interpolation: LineInterpolation.bezier,
            strokeWidth: 2,
          ),
        ];
      case _InteractionMode.track:
        return _trackingSeries
            .map((series) {
              return LineChartSeries(
                id: 'preview-${series.id}',
                name: series.name,
                points: series.points,
                color: series.color,
                interpolation: LineInterpolation.monotone,
                strokeWidth: 1.8,
              );
            })
            .toList(growable: false);
      case _InteractionMode.normalize:
        return [
          AreaChartSeries(
            id: 'preview-normalized-area',
            name: 'Fat oxidation',
            points: _normalizedSeries.first.points,
            color: const Color(0xFF10B981),
            interpolation: LineInterpolation.bezier,
            strokeWidth: 1.8,
            fillOpacity: 0.3,
          ),
          LineChartSeries(
            id: 'preview-normalized-line',
            name: 'CHO oxidation',
            points: _normalizedSeries.last.points,
            color: const Color(0xFFF59E0B),
            interpolation: LineInterpolation.bezier,
            strokeWidth: 1.8,
          ),
        ];
      case _InteractionMode.curves:
        return _interpolationSeries;
      case _InteractionMode.stress:
        return _stressSeries;
      case _InteractionMode.navigator:
        return [
          AreaChartSeries(
            id: 'preview-navigator',
            name: 'Navigator',
            points: _navigatorData,
            color: const Color(0xFF0F766E),
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.8,
            fillOpacity: 0.28,
          ),
        ];
    }
  }

  Widget _buildMainStage() {
    return ChartCard(
      title: _mainTitle(),
      subtitle: _mainSubtitle(),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: switch (_mode) {
        _InteractionMode.explore => _buildExploreChart(),
        _InteractionMode.track => _buildTrackingChart(
          series: _trackingSeries,
          yAxisLabel: 'Normalized value',
          normalizationMode: NormalizationMode.perSeries,
          xAxisConfig: const XAxisConfig(
            label: 'Time',
            unit: 'min',
            min: 0,
            max: 30,
          ),
          annotations: _trackingBoundaryAnnotations,
        ),
        _InteractionMode.normalize =>
          _useConstrainedLayout
              ? _buildSplitPaneExample()
              : _buildTrackingChart(
                  series: _normalizedSeries,
                  yAxisLabel: 'Substrate oxidation',
                  normalizationMode: NormalizationMode.auto,
                  xAxisConfig: const XAxisConfig(
                    label: 'Power',
                    unit: 'W',
                    min: 150,
                    max: 315,
                  ),
                  annotations: _normalizationAnnotations,
                ),
        _InteractionMode.curves => _buildTrackingChart(
          series: _curveStudy == _CurveStudy.interpolation
              ? _interpolationSeries
              : _tensionSeries,
          yAxisLabel: _curveStudy == _CurveStudy.interpolation
              ? 'Interpolation lane'
              : 'Tension lane',
        ),
        _InteractionMode.stress => _buildTrackingChart(
          series: _stressSeries,
          yAxisLabel: 'Stress path',
        ),
        _InteractionMode.navigator => _buildNavigatorExample(),
      },
    );
  }

  Widget _buildNavigatorExample() {
    final domainMax = (_navigatorPointCount - 1).toDouble();
    final initialMin = (domainMax * 0.12).roundToDouble();
    final initialMax = (domainMax * 0.52).roundToDouble();
    final chartTheme = _optionsController.theme ?? ChartTheme.light;
    return Column(
      key: const ValueKey('interaction-navigator-composition'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: BravenChartPlus(
            key: const ValueKey('interaction-navigator-chart'),
            interactionGroupController: _navigatorController,
            series: [
              LineChartSeries(
                id: 'navigator-signal',
                name: 'Signal',
                points: _navigatorData,
                color: const Color(0xFF0F766E),
                interpolation: LineInterpolation.monotone,
                strokeWidth: 2.4,
                showDataPointMarkers: _optionsController.showDataMarkers,
              ),
            ],
            theme: chartTheme,
            showLegend: _optionsController.showLegend,
            grid: GridConfig(
              horizontal: _optionsController.showGrid,
              vertical: _optionsController.showGrid,
            ),
            xAxisConfig: XAxisConfig(
              label: 'Sample',
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Signal',
              showAxisLine: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
              crosshair: CrosshairConfig.tracking(
                interpolate: true,
                showTooltip: true,
                showMarkers: true,
              ),
              tooltip: const TooltipConfig(enabled: false),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: CartesianNavigator(
            key: const ValueKey('interaction-cartesian-navigator'),
            interactionGroupController: _navigatorController,
            overviewSeries: AreaChartSeries(
              id: 'navigator-overview',
              name: 'Full signal',
              points: _navigatorData,
              color: const Color(0xFF0F766E),
              interpolation: LineInterpolation.monotone,
              strokeWidth: 1.5,
              fillOpacity: 0.24,
              showDataPointMarkers: false,
            ),
            fullDomain: ChartXViewport(min: 0, max: domainMax),
            initialViewport: ChartXViewport(min: initialMin, max: initialMax),
            behavior: CartesianNavigatorBehavior(
              minimumSpan: math.max(4, domainMax / 24),
            ),
            snapPolicy: CartesianNavigatorSnapPolicy.interval(1),
            theme: chartTheme,
            height: 88,
            semanticLabel: 'Signal sample viewport',
          ),
        ),
      ],
    );
  }

  Widget _buildNavigatorControllerActions() {
    Widget action({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) => Expanded(
      child: SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 17),
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            action(
              label: 'Show first',
              icon: Icons.first_page,
              onPressed: () => _showNavigatorWindow(0, 0.3),
            ),
            const SizedBox(width: 8),
            action(
              label: 'Show middle',
              icon: Icons.align_horizontal_center,
              onPressed: () => _showNavigatorWindow(0.35, 0.65),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            action(
              label: 'Show latest',
              icon: Icons.last_page,
              onPressed: () => _showNavigatorWindow(0.7, 1),
            ),
            const SizedBox(width: 8),
            action(
              label: 'Show all',
              icon: Icons.fit_screen,
              onPressed: () => _showNavigatorWindow(0, 1),
            ),
          ],
        ),
      ],
    );
  }

  String _navigatorViewportSummary() {
    final viewport = _navigatorController.viewport;
    final domainMax = (_navigatorPointCount - 1).toDouble();
    final effective =
        viewport ??
        ChartXViewport(
          min: (domainMax * 0.12).roundToDouble(),
          max: (domainMax * 0.52).roundToDouble(),
        );
    return 'Visible samples ${effective.min.toStringAsFixed(0)}–${effective.max.toStringAsFixed(0)} of ${domainMax.toStringAsFixed(0)}';
  }

  Widget _buildExploreChart() {
    return BravenChartPlus(
      series: [
        LineChartSeries(
          id: 'random-walk',
          name: 'Random walk',
          points: _interactionData,
          color: const Color(0xFF4F46E5),
          interpolation: LineInterpolation.bezier,
          strokeWidth: 2.4,
          showDataPointMarkers: _optionsController.showDataMarkers,
        ),
      ],
      theme: _optionsController.theme,
      showLegend: _optionsController.showLegend,
      showXScrollbar: _optionsController.showXScrollbar,
      showYScrollbar: _optionsController.showYScrollbar,
      scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
      grid: GridConfig(
        horizontal: _optionsController.showGrid,
        vertical: _optionsController.showGrid,
      ),
      xAxisConfig: XAxisConfig(
        label: 'Sample',
        showAxisLine: _optionsController.showAxisLines,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Value',
        showAxisLine: _optionsController.showAxisLines,
      ),
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.enableZoom,
        enablePan: _optionsController.enablePan,
        crosshair: CrosshairConfig(enabled: _enableCrosshair),
        tooltip: TooltipConfig(enabled: _enableTooltips),
      ),
      onPointTap: (point, seriesId) => setState(() => _tappedPoint = point),
      onPointHover: (point, seriesId) => setState(() => _hoveredPoint = point),
    );
  }

  Widget _buildTrackingChart({
    required List<ChartSeries> series,
    required String yAxisLabel,
    NormalizationMode normalizationMode = NormalizationMode.none,
    XAxisConfig? xAxisConfig,
    List<ChartAnnotation> annotations = const [],
  }) {
    return BravenChartPlus(
      series: series,
      annotations: annotations,
      theme: _optionsController.theme,
      showLegend: _optionsController.showLegend,
      showXScrollbar: _optionsController.showXScrollbar,
      showYScrollbar: _optionsController.showYScrollbar,
      scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
      grid: GridConfig(
        horizontal: _optionsController.showGrid,
        vertical: _optionsController.showGrid,
      ),
      xAxisConfig: (xAxisConfig ?? const XAxisConfig(label: 'Sample')).copyWith(
        showAxisLine: _optionsController.showAxisLines,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        label: yAxisLabel,
        showAxisLine: _optionsController.showAxisLines,
      ),
      normalizationMode: normalizationMode,
      interactionConfig: InteractionConfig(
        enableZoom: _optionsController.enableZoom,
        enablePan: _optionsController.enablePan,
        crosshair: CrosshairConfig.tracking(
          interpolate: true,
          showTooltip: _showTrackingTooltip,
          showMarkers: _showIntersectionMarkers,
        ),
        tooltip: const TooltipConfig(enabled: false),
      ),
    );
  }

  Widget _buildSplitPaneExample() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chart = _buildTrackingChart(
          series: _normalizedSeries,
          yAxisLabel: 'Substrate oxidation',
          normalizationMode: NormalizationMode.auto,
          xAxisConfig: const XAxisConfig(
            label: 'Power',
            unit: 'W',
            min: 150,
            max: 315,
          ),
          annotations: _normalizationAnnotations,
        );
        final notes = DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Constrained viewport',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text('A narrow analytical pane with mixed normalized series.'),
                SizedBox(height: 16),
                Text(
                  'Try zooming and panning. Tracking remains aligned after the viewport changes.',
                ),
              ],
            ),
          ),
        );

        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(flex: 3, child: notes),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: chart),
            ],
          );
        }

        return Column(
          children: [
            notes,
            const SizedBox(height: 12),
            Expanded(child: chart),
          ],
        );
      },
    );
  }

  List<ChartSeries> get _trackingSeries => [
    LineChartSeries(
      id: 'tracking-vo2',
      name: 'VO₂',
      points: const [
        ChartDataPoint(x: 0, y: 20),
        ChartDataPoint(x: 5, y: 23),
        ChartDataPoint(x: 10, y: 29),
        ChartDataPoint(x: 15, y: 38),
        ChartDataPoint(x: 20, y: 49),
        ChartDataPoint(x: 25, y: 57),
        ChartDataPoint(x: 30, y: 60),
      ],
      color: const Color(0xFF1565C0),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.4,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        label: 'VO₂',
        unit: 'mL/kg/min',
        color: const Color(0xFF1565C0),
        showCrosshairLabel: true,
      ).copyWith(id: 'tracking-vo2-axis'),
    ),
    LineChartSeries(
      id: 'tracking-hr',
      name: 'Heart rate',
      points: const [
        ChartDataPoint(x: 0, y: 65),
        ChartDataPoint(x: 5, y: 78),
        ChartDataPoint(x: 10, y: 98),
        ChartDataPoint(x: 15, y: 122),
        ChartDataPoint(x: 20, y: 148),
        ChartDataPoint(x: 25, y: 168),
        ChartDataPoint(x: 30, y: 178),
      ],
      color: const Color(0xFFE53935),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.2,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.right,
        label: 'Heart rate',
        unit: 'bpm',
        color: const Color(0xFFE53935),
        showCrosshairLabel: true,
      ).copyWith(id: 'tracking-hr-axis'),
    ),
    LineChartSeries(
      id: 'tracking-lactate',
      name: 'Lactate',
      points: const [
        ChartDataPoint(x: 0, y: 0.8),
        ChartDataPoint(x: 4, y: 1.0),
        ChartDataPoint(x: 8, y: 1.3),
        ChartDataPoint(x: 12, y: 2.0),
        ChartDataPoint(x: 16, y: 3.6),
        ChartDataPoint(x: 20, y: 7.1),
        ChartDataPoint(x: 22, y: 9.4),
      ],
      color: const Color(0xFF2E7D32),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2.5,
      showDataPointMarkers: true,
      dataPointMarkerRadius: 4,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Lactate',
        unit: 'mmol/L',
        color: const Color(0xFF2E7D32),
        showCrosshairLabel: true,
      ).copyWith(id: 'tracking-lactate-axis'),
    ),
    AreaChartSeries(
      id: 'tracking-la-acc',
      name: 'La_acc',
      points: const [
        ChartDataPoint(x: 0, y: 0),
        ChartDataPoint(x: 4, y: 0.1),
        ChartDataPoint(x: 8, y: 0.3),
        ChartDataPoint(x: 12, y: 1.0),
        ChartDataPoint(x: 16, y: 3.7),
        ChartDataPoint(x: 18, y: 7.2),
      ],
      color: const Color(0xFF66BB6A),
      interpolation: LineInterpolation.monotone,
      strokeWidth: 2,
      fillOpacity: 0.24,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        label: 'La_acc',
        unit: 'mmol/L/min',
        color: const Color(0xFF66BB6A),
        showCrosshairLabel: true,
      ).copyWith(id: 'tracking-la-acc-axis'),
    ),
  ];

  List<ChartSeries> get _normalizedSeries => [
    AreaChartSeries(
      id: 'fat-oxidation',
      name: 'Fat oxidation',
      points: const [
        ChartDataPoint(x: 155, y: 0.32),
        ChartDataPoint(x: 180, y: 0.48),
        ChartDataPoint(x: 205, y: 0.66),
        ChartDataPoint(x: 230, y: 0.82),
        ChartDataPoint(x: 255, y: 0.91),
        ChartDataPoint(x: 280, y: 0.74),
        ChartDataPoint(x: 307, y: 0.38),
      ],
      color: const Color(0xFF10B981),
      interpolation: LineInterpolation.bezier,
      tension: 0.15,
      strokeWidth: 2.4,
      fillOpacity: 0.28,
      showDataPointMarkers: true,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.left,
        label: 'Fat oxidation',
        unit: 'g/min',
        color: const Color(0xFF10B981),
        showCrosshairLabel: true,
      ).copyWith(id: 'fat-axis'),
    ),
    LineChartSeries(
      id: 'cho-oxidation',
      name: 'CHO oxidation',
      points: const [
        ChartDataPoint(x: 155, y: 0.4),
        ChartDataPoint(x: 180, y: 0.6),
        ChartDataPoint(x: 205, y: 0.9),
        ChartDataPoint(x: 230, y: 1.35),
        ChartDataPoint(x: 255, y: 1.9),
        ChartDataPoint(x: 280, y: 2.5),
        ChartDataPoint(x: 307, y: 3.1),
      ],
      color: const Color(0xFFF59E0B),
      interpolation: LineInterpolation.bezier,
      tension: 0.14,
      strokeWidth: 2.4,
      showDataPointMarkers: true,
      yAxisConfig: YAxisConfig(
        position: YAxisPosition.right,
        label: 'CHO oxidation',
        unit: 'g/min',
        color: const Color(0xFFF59E0B),
        showCrosshairLabel: true,
      ).copyWith(id: 'cho-axis'),
    ),
  ];

  List<ChartSeries> get _interpolationSeries => [
    _lineSeries(
      id: 'linear-reference',
      name: 'Linear',
      color: const Color(0xFF1F4E79),
      interpolation: LineInterpolation.linear,
      points: _offsetSeries(_baseCurvePoints, 90),
    ),
    _lineSeries(
      id: 'bezier-soft',
      name: 'Bezier',
      color: const Color(0xFF2F855A),
      interpolation: LineInterpolation.bezier,
      tension: 0.2,
      points: _offsetSeries(_baseCurvePoints, 55),
    ),
    _lineSeries(
      id: 'monotone-curve',
      name: 'Monotone',
      color: const Color(0xFFB7791F),
      interpolation: LineInterpolation.monotone,
      points: _offsetSeries(_baseCurvePoints, 20),
    ),
    _lineSeries(
      id: 'stepped-control',
      name: 'Stepped',
      color: const Color(0xFF6B46C1),
      interpolation: LineInterpolation.stepped,
      points: _offsetSeries(_baseCurvePoints, -15),
    ),
  ];

  List<ChartSeries> get _tensionSeries => [
    _lineSeries(
      id: 'tension-low',
      name: 'Tension 0.10',
      color: const Color(0xFF1565C0),
      interpolation: LineInterpolation.bezier,
      tension: 0.10,
      points: _offsetSeries(_baseStressPoints, 45),
    ),
    _lineSeries(
      id: 'tension-medium',
      name: 'Tension 0.35',
      color: const Color(0xFF00897B),
      interpolation: LineInterpolation.bezier,
      tension: 0.35,
      points: _baseStressPoints,
    ),
    _lineSeries(
      id: 'tension-high',
      name: 'Tension 0.70',
      color: const Color(0xFFEF6C00),
      interpolation: LineInterpolation.bezier,
      tension: 0.70,
      points: _offsetSeries(_baseStressPoints, -45),
    ),
  ];

  List<ChartSeries> get _stressSeries => [
    _lineSeries(
      id: 'stress-bezier',
      name: 'Bezier stress',
      color: const Color(0xFF3949AB),
      interpolation: LineInterpolation.bezier,
      tension: 0.45,
      points: _baseStressPoints,
    ),
    _lineSeries(
      id: 'stress-monotone',
      name: 'Monotone stress',
      color: const Color(0xFFD81B60),
      interpolation: LineInterpolation.monotone,
      points: _offsetSeries(_baseStressPoints, -18),
    ),
  ];

  LineChartSeries _lineSeries({
    required String id,
    required String name,
    required Color color,
    required LineInterpolation interpolation,
    required List<ChartDataPoint> points,
    double tension = 0.25,
  }) {
    return LineChartSeries(
      id: id,
      name: name,
      points: points,
      color: color,
      interpolation: interpolation,
      tension: tension,
      strokeWidth: 2.5,
      showDataPointMarkers: _optionsController.showDataMarkers,
      dataPointMarkerRadius: 3,
    );
  }

  List<ChartDataPoint> _offsetSeries(
    List<ChartDataPoint> source,
    double offset,
  ) {
    return source
        .map((point) => ChartDataPoint(x: point.x, y: point.y + offset))
        .toList(growable: false);
  }

  String _mainTitle() => switch (_mode) {
    _InteractionMode.explore => 'Explore and select',
    _InteractionMode.track => 'Multi-series tracking boundaries',
    _InteractionMode.normalize => 'Tracking with automatic normalization',
    _InteractionMode.curves =>
      _curveStudy == _CurveStudy.interpolation
          ? 'Interpolation-aware tracking'
          : 'Bezier tension tracking',
    _InteractionMode.stress => 'Sharp-reversal tracking',
    _InteractionMode.navigator => 'Navigator and viewport controller',
  };

  String _mainSubtitle() {
    return switch (_mode) {
      _InteractionMode.explore => _exploreSubtitle(),
      _InteractionMode.track =>
        'Series leave the tracking overlay after their final value',
      _InteractionMode.normalize =>
        _useConstrainedLayout
            ? 'Tracking inside a constrained analytical split pane'
            : 'Mixed area and line series with dual axes and automatic normalization',
      _InteractionMode.curves =>
        _curveStudy == _CurveStudy.interpolation
            ? 'Linear, Bezier, monotone, and stepped curves share the same anchors'
            : 'The same anchors rendered with three Bezier tension values',
      _InteractionMode.stress =>
        'Markers stay aligned through reversals, plateaus, and strong curvature',
      _InteractionMode.navigator =>
        '${_navigatorData.length} points · drag the overview window or call the shared controller',
    };
  }

  String _exploreSubtitle() {
    final feedback = <String>[];
    if (_hoveredPoint != null) {
      feedback.add(
        'Hover ${_hoveredPoint!.x.toStringAsFixed(0)}, ${_hoveredPoint!.y.toStringAsFixed(1)}',
      );
    }
    if (_tappedPoint != null) {
      feedback.add(
        'Selected ${_tappedPoint!.x.toStringAsFixed(0)}, ${_tappedPoint!.y.toStringAsFixed(1)}',
      );
    }

    const instruction =
        'Shift + wheel to zoom · drag to pan · hover and click points';
    return feedback.isEmpty
        ? instruction
        : '$instruction · ${feedback.join(' · ')}';
  }

  String _modeLabel(_InteractionMode mode) => switch (mode) {
    _InteractionMode.explore => 'Explore',
    _InteractionMode.track => 'Track',
    _InteractionMode.normalize => 'Normalize',
    _InteractionMode.curves => 'Compare curves',
    _InteractionMode.stress => 'Stress paths',
    _InteractionMode.navigator => 'Navigator',
  };

  String _modeDescription(_InteractionMode mode) => switch (mode) {
    _InteractionMode.explore => 'Zoom, pan, hover, select',
    _InteractionMode.track => 'Crosshair + boundaries',
    _InteractionMode.normalize => 'Mixed scales + axes',
    _InteractionMode.curves => 'Interpolation-aware',
    _InteractionMode.stress => 'Reversals + plateaus',
    _InteractionMode.navigator => 'Overview + controller',
  };

  String _modeGuide() => switch (_mode) {
    _InteractionMode.explore =>
      'Hover or click a point, hold Shift while using the wheel to zoom, and drag to pan. The chart title reports live hover and selection events.',
    _InteractionMode.track =>
      'Move horizontally across the chart. La_acc and lactate stop contributing when the cursor passes their final samples.',
    _InteractionMode.normalize =>
      'Track the mixed-scale series and compare their real axis values. Toggle the constrained layout to test a split pane.',
    _InteractionMode.curves =>
      'Move across the curves to verify that each tracking marker remains centered on its rendered interpolation.',
    _InteractionMode.stress =>
      'Track across abrupt direction changes and plateaus to inspect marker alignment under difficult geometry.',
    _InteractionMode.navigator =>
      'Change the data-point count, drag or resize the overview window, then use the viewport buttons. Every path writes to the same ChartInteractionGroupController.',
  };

  List<ChartAnnotation> get _trackingBoundaryAnnotations => [
    ThresholdAnnotation(
      id: 'la-acc-end',
      axis: AnnotationAxis.x,
      value: 18,
      label: 'La_acc ends',
      labelPosition: AnnotationLabelPosition.topLeft,
      lineColor: const Color(0xFF66BB6A),
      lineWidth: 1.5,
      dashPattern: [4, 4],
    ),
    ThresholdAnnotation(
      id: 'lactate-end',
      axis: AnnotationAxis.x,
      value: 22,
      label: 'Lactate ends',
      labelPosition: AnnotationLabelPosition.topLeft,
      lineColor: const Color(0xFF2E7D32),
      lineWidth: 1.5,
      dashPattern: [4, 4],
    ),
  ];

  List<ChartAnnotation> get _normalizationAnnotations => [
    ThresholdAnnotation(
      id: 'normalized-lt1',
      axis: AnnotationAxis.x,
      value: 180,
      label: 'LT1',
      lineColor: const Color(0xFFF59E0B),
      lineWidth: 1.4,
      dashPattern: [3, 3],
    ),
    ThresholdAnnotation(
      id: 'normalized-lt2',
      axis: AnnotationAxis.x,
      value: 255,
      label: 'LT2',
      lineColor: const Color(0xFFF59E0B),
      lineWidth: 1.4,
      dashPattern: [3, 3],
    ),
    ThresholdAnnotation(
      id: 'normalized-fatmax',
      axis: AnnotationAxis.x,
      value: 280,
      label: 'FatMax',
      lineColor: const Color(0xFF10B981),
      lineWidth: 1.4,
      dashPattern: [3, 3],
    ),
  ];

  static const _baseCurvePoints = [
    ChartDataPoint(x: 0, y: 12),
    ChartDataPoint(x: 1, y: 28),
    ChartDataPoint(x: 2, y: 6),
    ChartDataPoint(x: 3, y: 34),
    ChartDataPoint(x: 4, y: 14),
    ChartDataPoint(x: 5, y: 40),
    ChartDataPoint(x: 6, y: 18),
    ChartDataPoint(x: 7, y: 46),
    ChartDataPoint(x: 8, y: 24),
    ChartDataPoint(x: 9, y: 54),
    ChartDataPoint(x: 10, y: 30),
  ];

  static const _baseStressPoints = [
    ChartDataPoint(x: 0, y: 82),
    ChartDataPoint(x: 1, y: 88),
    ChartDataPoint(x: 2, y: 54),
    ChartDataPoint(x: 3, y: 58),
    ChartDataPoint(x: 4, y: 22),
    ChartDataPoint(x: 5, y: 72),
    ChartDataPoint(x: 6, y: 20),
    ChartDataPoint(x: 7, y: 74),
    ChartDataPoint(x: 8, y: 44),
    ChartDataPoint(x: 9, y: 48),
    ChartDataPoint(x: 10, y: 16),
    ChartDataPoint(x: 11, y: 84),
  ];
}

enum _InteractionMode { explore, track, normalize, curves, stress, navigator }

enum _CurveStudy { interpolation, tension }

class _InteractionPreviewCard extends StatelessWidget {
  const _InteractionPreviewCard({
    super.key,
    required this.mode,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _InteractionMode mode;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Select $label interaction pattern',
      child: Material(
        color: selected
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-interaction-${mode.name}'),
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(child: IgnorePointer(child: chart)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
