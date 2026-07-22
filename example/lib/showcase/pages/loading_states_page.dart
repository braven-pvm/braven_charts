// Copyright 2025 Braven Charts - Loading States Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _StatePattern { animatedChart, spinner, progressBar, empty, loaded }

enum _SkeletonPalette { theme, emerald, violet }

enum _ReplacementMode { builtIn, configBuilder, loadingWidget }

enum _EmptyIcon {
  chart(Icons.insert_chart_outlined, 'Chart'),
  inbox(Icons.inbox_outlined, 'Inbox'),
  activity(Icons.monitor_heart_outlined, 'Activity'),
  upload(Icons.upload_file_outlined, 'Upload');

  const _EmptyIcon(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// A focused workbench for chart loading, empty, and loaded states.
class LoadingStatesPage extends StatefulWidget {
  const LoadingStatesPage({super.key});

  @override
  State<LoadingStatesPage> createState() => _LoadingStatesPageState();
}

class _LoadingStatesPageState extends State<LoadingStatesPage> {
  static const _blue = Color(0xFF3478D4);
  static const _emerald = Color(0xFF047857);
  static const _teal = Color(0xFF14B8A6);
  static const _violet = Color(0xFF6D28D9);
  static const _pink = Color(0xFFEC4899);

  final ChartOptionsController _optionsController = ChartOptionsController();

  _StatePattern _selectedPattern = _StatePattern.animatedChart;
  _SkeletonPalette _skeletonPalette = _SkeletonPalette.theme;
  _ReplacementMode _replacementMode = _ReplacementMode.builtIn;
  _EmptyIcon _emptyIcon = _EmptyIcon.activity;

  String _loadingMessage = 'Loading chart data';
  String _semanticLabel = 'Loading power samples';
  bool _showMessage = true;
  bool _determinate = false;
  double _progress = 0.42;

  double _animationSeconds = 2.4;
  double _motionIntensity = 1;
  bool _showSecondaryTrace = true;
  bool _showSkeletonGrid = false;
  double _edgeFade = 0.12;
  double _widthFactor = 0.78;
  double _aspectRatio = 2.4;

  String _emptyTitle = 'No workout samples';
  String _emptyMessage = 'Import a workout or change the selected date range.';
  bool _showEmptyIcon = true;
  bool _customEmptyAction = false;

  static const _series = <ChartSeries>[
    LineChartSeries(
      id: 'power',
      name: 'Power',
      color: _blue,
      interpolation: LineInterpolation.monotone,
      showDataPointMarkers: true,
      points: <ChartDataPoint>[
        ChartDataPoint(x: 0, y: 118),
        ChartDataPoint(x: 1, y: 142),
        ChartDataPoint(x: 2, y: 136),
        ChartDataPoint(x: 3, y: 172),
        ChartDataPoint(x: 4, y: 164),
        ChartDataPoint(x: 5, y: 198),
        ChartDataPoint(x: 6, y: 184),
        ChartDataPoint(x: 7, y: 215),
      ],
    ),
  ];

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Loading States',
      subtitle:
          'Preserve the chart viewport while data loads, then resolve clearly to empty or loaded content',
      optionsChildren: _buildOptions(),
      chart: _buildWorkspace(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  Widget _buildWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heading = Text(
          'Choose a lifecycle presentation',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        );
        final guide = _StateGuide(
          key: const ValueKey('loading-state-guide'),
          pattern: _selectedPattern,
        );

        if (constraints.maxHeight < 420) {
          return ListView(
            children: [
              heading,
              const SizedBox(height: 8),
              SizedBox(height: 172, child: _buildPatternRibbon()),
              const SizedBox(height: 16),
              guide,
              const SizedBox(height: 16),
              SizedBox(height: 430, child: _buildMainStage()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 8),
            SizedBox(height: 172, child: _buildPatternRibbon()),
            const SizedBox(height: 16),
            guide,
            const SizedBox(height: 16),
            Expanded(child: _buildMainStage()),
          ],
        );
      },
    );
  }

  Widget _buildPatternRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth >= 1120
            ? (constraints.maxWidth - gap * 4) / 5
            : 200.0;
        return SingleChildScrollView(
          key: const ValueKey('loading-state-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < _StatePattern.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: _StatePatternCard(
                    key: ValueKey(
                      'loading-state-pattern-${_StatePattern.values[index].name}',
                    ),
                    pattern: _StatePattern.values[index],
                    selected: _selectedPattern == _StatePattern.values[index],
                    onTap: () => _selectPattern(_StatePattern.values[index]),
                    chart: _buildPatternPreview(_StatePattern.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatternPreview(_StatePattern pattern) {
    return BravenChartPlus(
      key: ValueKey('loading-state-preview-${pattern.name}'),
      series: pattern == _StatePattern.loaded ? _series : const [],
      isLoading: _isLoadingPattern(pattern),
      loadingConfig: switch (pattern) {
        _StatePattern.animatedChart => const ChartLoadingConfig.skeleton(
          showMessage: false,
          skeletonStyle: ChartLoadingSkeletonStyle(
            animationDuration: Duration(milliseconds: 2800),
            motionIntensity: 0.7,
            maxWidth: 240,
            widthFactor: 1,
            edgeFadeFraction: 0.14,
          ),
        ),
        _StatePattern.spinner => const ChartLoadingConfig.circular(
          showMessage: false,
        ),
        _StatePattern.progressBar => const ChartLoadingConfig.linear(
          progress: 0.58,
          showMessage: false,
        ),
        _ => const ChartLoadingConfig.skeleton(showMessage: false),
      },
      emptyStateConfig: const ChartEmptyStateConfig(
        title: 'No samples',
        message: null,
        icon: Icons.monitor_heart_outlined,
      ),
      showLegend: false,
      xAxisConfig: const XAxisConfig(
        showTickLabels: false,
        showTicks: false,
        showAxisLine: true,
        minHeight: 8,
        maxHeight: 8,
      ),
      yAxis: YAxisConfig(
        position: YAxisPosition.left,
        showTickLabels: false,
        showTicks: false,
        maxWidth: 14,
      ),
      grid: const GridConfig(horizontal: false, vertical: false),
      interactionConfig: const InteractionConfig(
        enableZoom: false,
        enablePan: false,
      ),
    );
  }

  Widget _buildMainStage() {
    return ChartCard(
      key: const ValueKey('loading-state-main-stage'),
      title: _patternLabel(_selectedPattern),
      subtitle: _stageSubtitle(_selectedPattern),
      child: ListenableBuilder(
        listenable: _optionsController,
        builder: (context, _) => BravenChartPlus(
          key: ValueKey('loading-state-main-chart-${_selectedPattern.name}'),
          series: _selectedPattern == _StatePattern.loaded ? _series : const [],
          isLoading: _isLoadingPattern(_selectedPattern),
          loadingConfig: _loadingConfig,
          loadingWidget: _replacementMode == _ReplacementMode.loadingWidget
              ? _CustomLoadingPresentation(message: _loadingMessage)
              : null,
          emptyStateConfig: _emptyConfig,
          theme: _optionsController.theme,
          title: 'Power profile',
          subtitle: 'Last 8 intervals',
          showLegend:
              _selectedPattern == _StatePattern.loaded &&
              _optionsController.showLegend,
          showXScrollbar:
              _selectedPattern == _StatePattern.loaded &&
              _optionsController.showXScrollbar,
          showYScrollbar:
              _selectedPattern == _StatePattern.loaded &&
              _optionsController.showYScrollbar,
          xAxisConfig: XAxisConfig(
            label: 'Interval',
            min: -0.4,
            max: 7.4,
            renderMin: 0,
            renderMax: 7,
            showAxisLine: _optionsController.showAxisLines,
          ),
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            label: 'Power',
            unit: 'W',
            min: 100,
            max: 225,
            showAxisLine: _optionsController.showAxisLines,
          ),
          grid: GridConfig(
            horizontal: _optionsController.showGrid,
            vertical: _optionsController.showGrid,
          ),
          interactionConfig: InteractionConfig(
            enableZoom: _optionsController.enableZoom,
            enablePan: _optionsController.enablePan,
            crosshair: CrosshairConfig.tracking(interpolate: true),
            tooltip: const TooltipConfig(enabled: true),
          ),
        ),
      ),
    );
  }

  ChartLoadingConfig get _loadingConfig {
    final customBuilder = _replacementMode == _ReplacementMode.configBuilder
        ? (BuildContext context) => _CustomLoadingPresentation(
            message: _loadingMessage,
            compact: false,
          )
        : null;
    return switch (_selectedPattern) {
      _StatePattern.animatedChart => ChartLoadingConfig.skeleton(
        message: _loadingMessage,
        semanticLabel: _semanticLabel,
        showMessage: _showMessage,
        customBuilder: customBuilder,
        skeletonStyle: ChartLoadingSkeletonStyle(
          seriesColor: _skeletonColors.$1,
          secondarySeriesColor: _skeletonColors.$2,
          animationDuration: Duration(
            milliseconds: (_animationSeconds * 1000).round(),
          ),
          widthFactor: _widthFactor,
          aspectRatio: _aspectRatio,
          motionIntensity: _motionIntensity,
          showSecondaryTrace: _showSecondaryTrace,
          showGrid: _showSkeletonGrid,
          edgeFadeFraction: _edgeFade,
        ),
      ),
      _StatePattern.spinner => ChartLoadingConfig.circular(
        progress: _determinate ? _progress : null,
        message: _loadingMessage,
        semanticLabel: _semanticLabel,
        showMessage: _showMessage,
        customBuilder: customBuilder,
      ),
      _StatePattern.progressBar => ChartLoadingConfig.linear(
        progress: _determinate ? _progress : null,
        message: _loadingMessage,
        semanticLabel: _semanticLabel,
        showMessage: _showMessage,
        customBuilder: customBuilder,
      ),
      _ => const ChartLoadingConfig.skeleton(),
    };
  }

  ChartEmptyStateConfig get _emptyConfig => ChartEmptyStateConfig(
    title: _emptyTitle,
    message: _emptyMessage,
    icon: _emptyIcon.icon,
    showIcon: _showEmptyIcon,
    semanticLabel: '$_emptyTitle. $_emptyMessage',
    customBuilder: _customEmptyAction
        ? (context) => _CustomEmptyPresentation(
            title: _emptyTitle,
            message: _emptyMessage,
          )
        : null,
  );

  (Color?, Color?) get _skeletonColors => switch (_skeletonPalette) {
    _SkeletonPalette.theme => (null, null),
    _SkeletonPalette.emerald => (_emerald, _teal),
    _SkeletonPalette.violet => (_violet, _pink),
  };

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Lifecycle State',
        icon: Icons.account_tree_outlined,
        children: [
          EnumOption<_StatePattern>(
            label: 'Presentation',
            value: _selectedPattern,
            values: _StatePattern.values,
            labelBuilder: _patternLabel,
            onChanged: _selectPattern,
          ),
          InfoBox(message: _statePrecedenceMessage, type: InfoBoxType.info),
        ],
      ),
      if (_isLoadingPattern(_selectedPattern)) ...[
        OptionSection(
          title: 'Loading Content',
          icon: Icons.hourglass_top,
          children: [
            TextOption(
              key: ValueKey('loading-message-$_loadingMessage'),
              label: 'Visible Message',
              value: _loadingMessage,
              onChanged: (value) => setState(() => _loadingMessage = value),
            ),
            BoolOption(
              label: 'Show Message',
              value: _showMessage,
              onChanged: (value) => setState(() => _showMessage = value),
            ),
            TextOption(
              key: ValueKey('semantic-label-$_semanticLabel'),
              label: 'Semantic Label',
              value: _semanticLabel,
              onChanged: (value) => setState(() => _semanticLabel = value),
            ),
            EnumOption<_ReplacementMode>(
              label: 'Presentation Source',
              subtitle: 'Built-in or complete replacement',
              value: _replacementMode,
              values: _ReplacementMode.values,
              labelBuilder: (value) => switch (value) {
                _ReplacementMode.builtIn => 'Built-in indicator',
                _ReplacementMode.configBuilder => 'customBuilder',
                _ReplacementMode.loadingWidget => 'loadingWidget override',
              },
              onChanged: (value) => setState(() => _replacementMode = value),
            ),
          ],
        ),
        if (_selectedPattern == _StatePattern.animatedChart)
          OptionSection(
            title: 'Animated Chart',
            icon: Icons.show_chart,
            children: [
              EnumOption<_SkeletonPalette>(
                label: 'Palette',
                value: _skeletonPalette,
                values: _SkeletonPalette.values,
                labelBuilder: (value) => switch (value) {
                  _SkeletonPalette.theme => 'Inherit chart theme',
                  _SkeletonPalette.emerald => 'Emerald + teal',
                  _SkeletonPalette.violet => 'Violet + pink',
                },
                onChanged: (value) => setState(() => _skeletonPalette = value),
              ),
              SliderOption(
                label: 'Animation Duration',
                value: _animationSeconds,
                min: 0.8,
                max: 5,
                divisions: 21,
                suffix: 's',
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _animationSeconds = value),
              ),
              SliderOption(
                label: 'Motion Intensity',
                value: _motionIntensity,
                min: 0,
                max: 1,
                divisions: 10,
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _motionIntensity = value),
              ),
              BoolOption(
                label: 'Secondary Trace',
                value: _showSecondaryTrace,
                onChanged: (value) =>
                    setState(() => _showSecondaryTrace = value),
              ),
              BoolOption(
                label: 'Skeleton Grid',
                value: _showSkeletonGrid,
                onChanged: (value) => setState(() => _showSkeletonGrid = value),
              ),
              SliderOption(
                label: 'Edge Fade',
                value: _edgeFade,
                min: 0,
                max: 0.4,
                divisions: 20,
                decimalPlaces: 2,
                onChanged: (value) => setState(() => _edgeFade = value),
              ),
              SliderOption(
                label: 'Width Factor',
                value: _widthFactor,
                min: 0.4,
                max: 1,
                divisions: 12,
                decimalPlaces: 2,
                onChanged: (value) => setState(() => _widthFactor = value),
              ),
              SliderOption(
                label: 'Aspect Ratio',
                value: _aspectRatio,
                min: 1.4,
                max: 4,
                divisions: 13,
                decimalPlaces: 1,
                onChanged: (value) => setState(() => _aspectRatio = value),
              ),
              const InfoBox(
                message:
                    'Reduced-motion preferences automatically freeze the animation at a representative frame.',
              ),
            ],
          )
        else
          OptionSection(
            title: 'Progress',
            icon: Icons.pending_outlined,
            children: [
              BoolOption(
                label: 'Determinate Progress',
                subtitle: 'Use only when the data source reports completion',
                value: _determinate,
                onChanged: (value) => setState(() => _determinate = value),
              ),
              if (_determinate)
                SliderOption(
                  label: 'Progress',
                  value: _progress,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  suffix: '%',
                  decimalPlaces: 2,
                  onChanged: (value) => setState(() => _progress = value),
                ),
            ],
          ),
      ],
      if (_selectedPattern == _StatePattern.empty)
        OptionSection(
          title: 'Empty State',
          icon: Icons.inbox_outlined,
          children: [
            TextOption(
              key: ValueKey('empty-title-$_emptyTitle'),
              label: 'Title',
              value: _emptyTitle,
              onChanged: (value) => setState(() => _emptyTitle = value),
            ),
            TextOption(
              key: ValueKey('empty-message-$_emptyMessage'),
              label: 'Guidance',
              value: _emptyMessage,
              onChanged: (value) => setState(() => _emptyMessage = value),
            ),
            EnumOption<_EmptyIcon>(
              label: 'Icon',
              value: _emptyIcon,
              values: _EmptyIcon.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) => setState(() => _emptyIcon = value),
            ),
            BoolOption(
              label: 'Show Icon',
              value: _showEmptyIcon,
              onChanged: (value) => setState(() => _showEmptyIcon = value),
            ),
            BoolOption(
              key: const ValueKey('custom-empty-action'),
              label: 'Custom Action State',
              subtitle: 'Replaces the complete empty presentation',
              value: _customEmptyAction,
              onChanged: (value) => setState(() => _customEmptyAction = value),
            ),
          ],
        ),
      StandardChartOptions(
        controller: _optionsController,
        showGridOption: _selectedPattern == _StatePattern.loaded,
        showAxisOption: _selectedPattern == _StatePattern.loaded,
        showMarkerOption: false,
        showScrollbarOptions: _selectedPattern == _StatePattern.loaded,
        showLegendOption: _selectedPattern == _StatePattern.loaded,
        showInteractionOptions: _selectedPattern == _StatePattern.loaded,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Reset',
        icon: Icons.restart_alt,
        initiallyExpanded: false,
        children: [
          ActionButton(
            label: 'Reset State Demo',
            icon: Icons.restart_alt,
            onPressed: _reset,
          ),
        ],
      ),
    ];
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(label: 'Lifecycle', value: _lifecycleLabel),
        StatusItem(
          label: 'Presentation',
          value: _patternLabel(_selectedPattern),
        ),
        const StatusItem(label: 'Viewport', value: 'Stable'),
        StatusItem(label: 'API', value: _statusApi),
      ],
    );
  }

  void _selectPattern(_StatePattern pattern) {
    if (_selectedPattern == pattern) return;
    setState(() {
      _selectedPattern = pattern;
      _replacementMode = _ReplacementMode.builtIn;
      if (pattern == _StatePattern.progressBar) {
        _determinate = true;
        _progress = 0.58;
      } else if (pattern == _StatePattern.spinner) {
        _determinate = false;
      }
    });
  }

  void _reset() {
    setState(() {
      _skeletonPalette = _SkeletonPalette.theme;
      _replacementMode = _ReplacementMode.builtIn;
      _emptyIcon = _EmptyIcon.activity;
      _loadingMessage = 'Loading chart data';
      _semanticLabel = 'Loading power samples';
      _showMessage = true;
      _determinate = _selectedPattern == _StatePattern.progressBar;
      _progress = 0.42;
      _animationSeconds = 2.4;
      _motionIntensity = 1;
      _showSecondaryTrace = true;
      _showSkeletonGrid = false;
      _edgeFade = 0.12;
      _widthFactor = 0.78;
      _aspectRatio = 2.4;
      _emptyTitle = 'No workout samples';
      _emptyMessage = 'Import a workout or change the selected date range.';
      _showEmptyIcon = true;
      _customEmptyAction = false;
    });
  }

  String get _statePrecedenceMessage => switch (_selectedPattern) {
    _StatePattern.animatedChart ||
    _StatePattern.spinner ||
    _StatePattern.progressBar =>
      'isLoading takes precedence over empty and loaded chart content.',
    _StatePattern.empty =>
      'With loading complete and no valid points, ChartEmptyStateConfig is shown.',
    _StatePattern.loaded =>
      'Valid points replace lifecycle placeholders with the interactive chart.',
  };

  String get _lifecycleLabel => _isLoadingPattern(_selectedPattern)
      ? 'Loading'
      : _selectedPattern == _StatePattern.empty
      ? 'Empty'
      : 'Loaded';

  String get _statusApi => _isLoadingPattern(_selectedPattern)
      ? 'ChartLoadingConfig'
      : _selectedPattern == _StatePattern.empty
      ? 'ChartEmptyStateConfig'
      : 'series';

  static bool _isLoadingPattern(_StatePattern pattern) =>
      pattern == _StatePattern.animatedChart ||
      pattern == _StatePattern.spinner ||
      pattern == _StatePattern.progressBar;

  static String _patternLabel(_StatePattern pattern) {
    return switch (pattern) {
      _StatePattern.animatedChart => 'Animated chart',
      _StatePattern.spinner => 'Spinner',
      _StatePattern.progressBar => 'Progress bar',
      _StatePattern.empty => 'Empty state',
      _StatePattern.loaded => 'Loaded chart',
    };
  }

  static String _patternDescription(_StatePattern pattern) {
    return switch (pattern) {
      _StatePattern.animatedChart => 'Context-preserving default',
      _StatePattern.spinner => 'Compact indeterminate work',
      _StatePattern.progressBar => 'Known or unknown progress',
      _StatePattern.empty => 'No valid points after loading',
      _StatePattern.loaded => 'Interactive data viewport',
    };
  }

  static String _stageSubtitle(_StatePattern pattern) {
    return switch (pattern) {
      _StatePattern.animatedChart =>
        'The default loader previews the chart shape while preserving viewport size',
      _StatePattern.spinner =>
        'Use a circular indicator when loading has no meaningful spatial context',
      _StatePattern.progressBar =>
        'Use determinate progress only when the data source reports completion',
      _StatePattern.empty =>
        'Explain why data is absent and give concise guidance about what happens next',
      _StatePattern.loaded =>
        'The same viewport resolves to the fully interactive chart when valid points arrive',
    };
  }
}

class _CustomLoadingPresentation extends StatelessWidget {
  const _CustomLoadingPresentation({
    required this.message,
    this.compact = true,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 320 : 420),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 36,
              color: colors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Preparing chart' : message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _CustomEmptyPresentation extends StatelessWidget {
  const _CustomEmptyPresentation({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Import workout'),
          ),
        ],
      ),
    );
  }
}

class _StatePatternCard extends StatelessWidget {
  const _StatePatternCard({
    super.key,
    required this.pattern,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _StatePattern pattern;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.45)
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
                      _LoadingStatesPageState._patternLabel(pattern),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      key: ValueKey('selected-loading-state-${pattern.name}'),
                      size: 16,
                      color: colors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _LoadingStatesPageState._patternDescription(pattern),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(child: IgnorePointer(child: chart)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateGuide extends StatelessWidget {
  const _StateGuide({super.key, required this.pattern});

  final _StatePattern pattern;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanation = Row(
            children: [
              Icon(_icon(pattern), size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _explanation(pattern),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          );
          final api = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.code, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _api(pattern),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(child: explanation),
                const SizedBox(width: 16),
                SizedBox(width: 470, child: api),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [explanation, const SizedBox(height: 10), api],
          );
        },
      ),
    );
  }

  static IconData _icon(_StatePattern pattern) {
    return switch (pattern) {
      _StatePattern.animatedChart => Icons.show_chart,
      _StatePattern.spinner => Icons.autorenew,
      _StatePattern.progressBar => Icons.linear_scale,
      _StatePattern.empty => Icons.inbox_outlined,
      _StatePattern.loaded => Icons.check_circle_outline,
    };
  }

  static String _explanation(_StatePattern pattern) {
    return switch (pattern) {
      _StatePattern.animatedChart =>
        'The default mirrors the eventual chart, scales with its viewport, inherits theme colours, and respects reduced motion.',
      _StatePattern.spinner =>
        'A familiar compact indicator works best when the duration is unknown and chart context is not useful.',
      _StatePattern.progressBar =>
        'Pass progress from 0 to 1 for determinate work, or null when completion cannot be measured.',
      _StatePattern.empty =>
        'Empty is a completed state, not loading: explain the absence and guide the next useful action.',
      _StatePattern.loaded =>
        'The same component renders data as soon as loading is false and at least one valid point exists.',
    };
  }

  static String _api(_StatePattern pattern) {
    return switch (pattern) {
      _StatePattern.animatedChart =>
        'isLoading · ChartLoadingConfig.skeleton · ChartLoadingSkeletonStyle',
      _StatePattern.spinner => 'ChartLoadingConfig.circular(progress: null)',
      _StatePattern.progressBar => 'ChartLoadingConfig.linear(progress: 0.58)',
      _StatePattern.empty => 'ChartEmptyStateConfig · customBuilder',
      _StatePattern.loaded => 'isLoading: false · series: data',
    };
  }
}
