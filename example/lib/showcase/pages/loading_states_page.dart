import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

enum _PreviewState { loading, empty, data }

enum _SkeletonPalette { theme, emerald, violet }

/// Interactive showcase for loading and empty chart states.
class LoadingStatesPage extends StatefulWidget {
  const LoadingStatesPage({super.key});

  @override
  State<LoadingStatesPage> createState() => _LoadingStatesPageState();
}

class _LoadingStatesPageState extends State<LoadingStatesPage> {
  static const _series = <ChartSeries>[
    LineChartSeries(
      id: 'power',
      name: 'Power',
      color: Color(0xFF2563EB),
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

  _PreviewState _previewState = _PreviewState.loading;
  ChartLoadingIndicator _indicator = ChartLoadingIndicator.skeleton;
  bool _determinate = false;
  double _progress = 0.42;
  _SkeletonPalette _skeletonPalette = _SkeletonPalette.theme;

  ChartLoadingSkeletonStyle get _skeletonStyle => switch (_skeletonPalette) {
    _SkeletonPalette.theme => const ChartLoadingSkeletonStyle(),
    _SkeletonPalette.emerald => const ChartLoadingSkeletonStyle(
      seriesColor: Color(0xFF047857),
      secondarySeriesColor: Color(0xFF14B8A6),
    ),
    _SkeletonPalette.violet => const ChartLoadingSkeletonStyle(
      seriesColor: Color(0xFF6D28D9),
      secondarySeriesColor: Color(0xFFEC4899),
    ),
  };

  ChartLoadingConfig get _loadingConfig {
    final progress = _determinate ? _progress : null;
    return switch (_indicator) {
      ChartLoadingIndicator.skeleton => ChartLoadingConfig.skeleton(
        skeletonStyle: _skeletonStyle,
      ),
      ChartLoadingIndicator.circular => ChartLoadingConfig.circular(
        progress: progress,
      ),
      ChartLoadingIndicator.linear => ChartLoadingConfig.linear(
        progress: progress,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = _previewState == _PreviewState.loading;
    final series = _previewState == _PreviewState.data
        ? _series
        : const <ChartSeries>[];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Loading and empty states',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Keep the chart viewport stable while data is loading, then show '
          'clear guidance when no data is available.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _ControlGroup(
              label: 'Preview state',
              child: SegmentedButton<_PreviewState>(
                segments: const [
                  ButtonSegment(
                    value: _PreviewState.loading,
                    icon: Icon(Icons.hourglass_top_outlined),
                    label: Text('Loading'),
                  ),
                  ButtonSegment(
                    value: _PreviewState.empty,
                    icon: Icon(Icons.inbox_outlined),
                    label: Text('Empty'),
                  ),
                  ButtonSegment(
                    value: _PreviewState.data,
                    icon: Icon(Icons.show_chart),
                    label: Text('Data'),
                  ),
                ],
                selected: {_previewState},
                onSelectionChanged: (selection) {
                  setState(() => _previewState = selection.first);
                },
              ),
            ),
            if (isLoading)
              _ControlGroup(
                label: 'Loading indicator',
                child: SegmentedButton<ChartLoadingIndicator>(
                  segments: const [
                    ButtonSegment(
                      value: ChartLoadingIndicator.skeleton,
                      label: Text('Chart'),
                    ),
                    ButtonSegment(
                      value: ChartLoadingIndicator.circular,
                      label: Text('Spinner'),
                    ),
                    ButtonSegment(
                      value: ChartLoadingIndicator.linear,
                      label: Text('Progress bar'),
                    ),
                  ],
                  selected: {_indicator},
                  onSelectionChanged: (selection) {
                    setState(() => _indicator = selection.first);
                  },
                ),
              ),
            if (isLoading && _indicator == ChartLoadingIndicator.skeleton)
              _ControlGroup(
                label: 'Animation palette',
                child: SegmentedButton<_SkeletonPalette>(
                  segments: const [
                    ButtonSegment(
                      value: _SkeletonPalette.theme,
                      label: Text('Theme'),
                    ),
                    ButtonSegment(
                      value: _SkeletonPalette.emerald,
                      label: Text('Emerald'),
                    ),
                    ButtonSegment(
                      value: _SkeletonPalette.violet,
                      label: Text('Violet'),
                    ),
                  ],
                  selected: {_skeletonPalette},
                  onSelectionChanged: (selection) {
                    setState(() => _skeletonPalette = selection.first);
                  },
                ),
              ),
          ],
        ),
        if (isLoading && _indicator != ChartLoadingIndicator.skeleton) ...[
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show determinate progress'),
                  subtitle: const Text(
                    'Use an exact value when the data source reports progress.',
                  ),
                  value: _determinate,
                  onChanged: (value) {
                    setState(() => _determinate = value);
                  },
                ),
                if (_determinate) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _progress,
                          onChanged: (value) {
                            setState(() => _progress = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${(_progress * 100).round()}%',
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: 440,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BravenChartPlus(
                series: series,
                isLoading: isLoading,
                loadingConfig: _loadingConfig,
                emptyStateConfig: const ChartEmptyStateConfig(
                  title: 'No workout samples',
                  message:
                      'Import a workout or change the selected date range.',
                  icon: Icons.monitor_heart_outlined,
                ),
                title: 'Power profile',
                subtitle: 'Last 8 intervals',
                showLegend: false,
                xAxisConfig: const XAxisConfig(label: 'Interval'),
                yAxis: YAxisConfig(
                  position: YAxisPosition.left,
                  label: 'Power',
                  unit: 'W',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'API example',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SelectableText(
            'BravenChartPlus(\n'
            '  series: series,\n'
            '  isLoading: isLoading,\n'
            '  loadingConfig: const ChartLoadingConfig.skeleton(),\n'
            '  emptyStateConfig: const ChartEmptyStateConfig(\n'
            "    title: 'No workout samples',\n"
            "    message: 'Import a workout or change the selected date range.',\n"
            '  ),\n'
            ')',
          ),
        ),
      ],
    );
  }
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
