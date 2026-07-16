// Copyright 2025 Braven Charts - Chart Types Showcase
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

const _availableChartTypes = <ChartType>[
  ChartType.line,
  ChartType.area,
  ChartType.bar,
  ChartType.scatter,
  ChartType.pie,
];

/// A browse-then-configure showcase for every primary chart type.
class ChartTypesPage extends StatefulWidget {
  const ChartTypesPage({super.key});

  @override
  State<ChartTypesPage> createState() => _ChartTypesPageState();
}

class _ChartTypesPageState extends State<ChartTypesPage> {
  final ChartOptionsController _optionsController = ChartOptionsController(
    const ChartOptions(showDataMarkers: true),
  );

  ChartType _chartType = ChartType.line;
  LineInterpolation _interpolation = LineInterpolation.bezier;
  double _strokeWidth = 2.5;
  double _fillOpacity = 0.28;
  double _barWidthPercent = 0.64;
  double _markerRadius = 5.0;
  bool _showSecondSeries = true;

  late List<ChartDataPoint> _observedData;
  late List<ChartDataPoint> _benchmarkData;

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      _observedData = DataGenerator.generateLinear(
        count: 16,
        slope: 3.2,
        intercept: 28,
        noise: 22,
        startX: 1,
      );
      _benchmarkData = DataGenerator.generateLinear(
        count: 16,
        slope: 2.6,
        intercept: 34,
        noise: 8,
        startX: 1,
      );
    });
  }

  void _selectChartType(ChartType chartType) {
    if (_chartType == chartType) return;
    setState(() => _chartType = chartType);
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Chart Types',
      subtitle: 'Compare every chart type, then configure it live',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      OptionSection(
        title: 'Chart Type',
        icon: Icons.insert_chart_outlined,
        children: [
          EnumOption<ChartType>(
            label: 'Type',
            value: _chartType,
            values: _availableChartTypes,
            labelBuilder: (value) => _chartTypeLabel(value),
            onChanged: _selectChartType,
          ),
          if (_chartType != ChartType.pie)
            BoolOption(
              label: 'Show Second Series',
              value: _showSecondSeries,
              onChanged: (value) => setState(() => _showSecondSeries = value),
              subtitle: 'Compare observed data with a benchmark',
            ),
        ],
      ),
      if (_chartType == ChartType.line || _chartType == ChartType.area)
        OptionSection(
          title: 'Line Appearance',
          icon: Icons.show_chart,
          children: [
            EnumOption<LineInterpolation>(
              label: 'Interpolation',
              value: _interpolation,
              values: LineInterpolation.values,
              onChanged: (value) => setState(() => _interpolation = value),
            ),
            SliderOption(
              label: 'Stroke Width',
              value: _strokeWidth,
              min: 0.5,
              max: 5.0,
              divisions: 9,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
          ],
        ),
      if (_chartType == ChartType.area)
        OptionSection(
          title: 'Area Fill',
          icon: Icons.area_chart_outlined,
          children: [
            SliderOption(
              label: 'Fill Opacity',
              value: _fillOpacity,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _fillOpacity = value),
            ),
          ],
        ),
      if (_chartType == ChartType.bar)
        OptionSection(
          title: 'Bar Appearance',
          icon: Icons.bar_chart,
          children: [
            SliderOption(
              label: 'Bar Width',
              value: _barWidthPercent,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _barWidthPercent = value),
            ),
          ],
        ),
      if (_chartType == ChartType.scatter)
        OptionSection(
          title: 'Marker Appearance',
          icon: Icons.scatter_plot_outlined,
          children: [
            SliderOption(
              label: 'Marker Radius',
              value: _markerRadius,
              min: 1.0,
              max: 10.0,
              divisions: 9,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _markerRadius = value),
            ),
          ],
        ),
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'Dataset',
        icon: Icons.refresh,
        children: [
          ActionButton(
            label: 'Regenerate Dataset',
            icon: Icons.refresh,
            onPressed: _regenerateData,
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
              'Choose a chart type',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 168, child: _buildChartTypeRibbon()),
            const SizedBox(height: 16),
            Expanded(child: _buildMainChart()),
          ],
        );
      },
    );
  }

  Widget _buildChartTypeRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const minimumCardWidth = 168.0;
        final fitWidth = (constraints.maxWidth - spacing * 3) / 4;
        final cardWidth = fitWidth >= minimumCardWidth
            ? fitWidth
            : minimumCardWidth;

        return ListView.separated(
          key: const ValueKey('chart-type-ribbon'),
          scrollDirection: Axis.horizontal,
          itemCount: _availableChartTypes.length,
          separatorBuilder: (_, _) => const SizedBox(width: spacing),
          itemBuilder: (context, index) {
            final chartType = _availableChartTypes[index];
            return SizedBox(
              width: cardWidth,
              child: _ChartTypePreviewCard(
                key: ValueKey('chart-type-preview-${chartType.name}'),
                chartType: chartType,
                label: _chartTypeLabel(chartType),
                description: _chartTypeDescription(chartType),
                selected: _chartType == chartType,
                onTap: () => _selectChartType(chartType),
                chart: _buildPreviewChart(chartType),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewChart(ChartType chartType) {
    return BravenChartPlus(
      series: _buildSeries(chartType, preview: true),
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
      interactionConfig: InteractionConfig.none(),
    );
  }

  Widget _buildMainChart() {
    return ChartCard(
      title: '${_chartTypeLabel(_chartType)} chart playground',
      subtitle: _mainChartSummary(),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: BravenChartPlus(
        series: _buildSeries(_chartType),
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
          label: 'Interval',
          min: 0,
          max: 17,
          renderMin: 1,
          renderMax: 16,
          showAxisLine: _optionsController.showAxisLines,
        ),
        yAxis: YAxisConfig(
          position: YAxisPosition.left,
          label: 'Value',
          min: 0,
          max: 110,
          showAxisLine: _optionsController.showAxisLines,
        ),
        interactionConfig: InteractionConfig(
          enableZoom: _optionsController.enableZoom,
          enablePan: _optionsController.enablePan,
          tooltip: const TooltipConfig(),
        ),
      ),
    );
  }

  List<ChartSeries> _buildSeries(ChartType chartType, {bool preview = false}) {
    final showSecondSeries = preview || _showSecondSeries;

    switch (chartType) {
      case ChartType.line:
        return [
          LineChartSeries(
            id: preview ? 'preview-line-observed' : 'line-observed',
            name: 'Observed',
            points: _observedData,
            color: const Color(0xFF6366F1),
            interpolation: preview ? LineInterpolation.bezier : _interpolation,
            strokeWidth: preview ? 2.2 : _strokeWidth,
            showDataPointMarkers: preview || _optionsController.showDataMarkers,
            dataPointMarkerRadius: preview ? 2.2 : 3.5,
          ),
          if (showSecondSeries)
            LineChartSeries(
              id: preview ? 'preview-line-benchmark' : 'line-benchmark',
              name: 'Benchmark',
              points: _benchmarkData,
              color: const Color(0xFFF97316),
              interpolation: preview
                  ? LineInterpolation.bezier
                  : _interpolation,
              strokeWidth: preview ? 1.8 : _strokeWidth,
              showDataPointMarkers:
                  preview || _optionsController.showDataMarkers,
              dataPointMarkerRadius: preview ? 1.8 : 3,
            ),
        ];
      case ChartType.area:
        return [
          AreaChartSeries(
            id: preview ? 'preview-area-observed' : 'area-observed',
            name: 'Observed',
            points: _observedData,
            color: const Color(0xFF10B981),
            interpolation: preview ? LineInterpolation.bezier : _interpolation,
            strokeWidth: preview ? 2 : _strokeWidth,
            fillOpacity: preview ? 0.30 : _fillOpacity,
            showDataPointMarkers:
                !preview && _optionsController.showDataMarkers,
          ),
          if (showSecondSeries)
            AreaChartSeries(
              id: preview ? 'preview-area-benchmark' : 'area-benchmark',
              name: 'Benchmark',
              points: _benchmarkData,
              color: const Color(0xFF6366F1),
              interpolation: preview
                  ? LineInterpolation.bezier
                  : _interpolation,
              strokeWidth: preview ? 1.8 : _strokeWidth,
              fillOpacity: preview ? 0.16 : _fillOpacity * 0.65,
              showDataPointMarkers:
                  !preview && _optionsController.showDataMarkers,
            ),
        ];
      case ChartType.bar:
        return [
          BarChartSeries(
            id: preview ? 'preview-bar-observed' : 'bar-observed',
            name: 'Observed',
            points: _observedData,
            color: const Color(0xFFF59E0B),
            barWidthPercent: preview ? 0.58 : _barWidthPercent,
          ),
          if (showSecondSeries)
            BarChartSeries(
              id: preview ? 'preview-bar-benchmark' : 'bar-benchmark',
              name: 'Benchmark',
              points: _benchmarkData,
              color: const Color(0xFF3B82F6),
              barWidthPercent: preview ? 0.38 : _barWidthPercent * 0.65,
            ),
        ];
      case ChartType.scatter:
        return [
          ScatterChartSeries(
            id: preview ? 'preview-scatter-observed' : 'scatter-observed',
            name: 'Observed',
            points: _observedData,
            color: const Color(0xFF8B5CF6),
            markerRadius: preview ? 3.2 : _markerRadius,
          ),
          if (showSecondSeries)
            ScatterChartSeries(
              id: preview ? 'preview-scatter-benchmark' : 'scatter-benchmark',
              name: 'Benchmark',
              points: _benchmarkData,
              color: const Color(0xFF14B8A6),
              markerRadius: preview ? 2.2 : _markerRadius * 0.72,
            ),
        ];
      case ChartType.pie:
        const categories = [
          'Subscriptions',
          'Services',
          'Hardware',
          'Training',
          'Other',
        ];
        final categoryCount = preview ? 4 : categories.length;
        return [
          PieChartSeries.fromMap(
            id: preview ? 'preview-pie' : 'pie-contributions',
            name: 'Contribution',
            unit: 'units',
            values: {
              for (var index = 0; index < categoryCount; index++)
                categories[index]: _observedData[index].y.clamp(
                  1,
                  double.infinity,
                ),
            },
            pieStyle: PieChartStyle(
              radiusFactor: preview ? 0.82 : 0.86,
              sliceGap: preview ? 1 : 2,
              borderWidth: preview ? 0 : 1,
            ),
            dataLabels: PieDataLabelConfig(
              isVisible: !preview,
              position: PieDataLabelPosition.outside,
              content: PieDataLabelContent.categoryAndPercentage,
            ),
          ),
        ];
    }
  }

  String _mainChartSummary() {
    final seriesCount = _chartType == ChartType.pie
        ? 1
        : (_showSecondSeries ? 2 : 1);
    final configuration = switch (_chartType) {
      ChartType.line => '${_interpolation.name} interpolation',
      ChartType.area =>
        '${_interpolation.name} · ${(_fillOpacity * 100).round()}% fill',
      ChartType.bar => '${(_barWidthPercent * 100).round()}% bar width',
      ChartType.scatter => '${_markerRadius.toStringAsFixed(0)}px markers',
      ChartType.pie => '5 categories · collision-aware outside labels',
    };

    final dataSummary = _chartType == ChartType.pie
        ? '1 series'
        : '$seriesCount series · ${_observedData.length} points each';
    return '$dataSummary · $configuration · '
        '${_themeName()} theme';
  }

  String _themeName() {
    final selectedTheme = _optionsController.theme;
    if (selectedTheme == null) return 'Light';

    for (final preset in ThemePreset.values) {
      if (preset.theme.backgroundColor == selectedTheme.backgroundColor) {
        return preset.displayName;
      }
    }
    return 'Custom';
  }

  String _chartTypeLabel(ChartType chartType) {
    return switch (chartType) {
      ChartType.line => 'Line',
      ChartType.area => 'Area',
      ChartType.bar => 'Bar',
      ChartType.scatter => 'Scatter',
      ChartType.pie => 'Pie',
    };
  }

  String _chartTypeDescription(ChartType chartType) {
    return switch (chartType) {
      ChartType.line => 'Smooth + markers',
      ChartType.area => 'Layered fills',
      ChartType.bar => 'Multi-series columns',
      ChartType.scatter => 'Distinct marker sets',
      ChartType.pie => 'Category contributions',
    };
  }
}

class _ChartTypePreviewCard extends StatelessWidget {
  const _ChartTypePreviewCard({
    super.key,
    required this.chartType,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final ChartType chartType;
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
      label: 'Select $label chart',
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
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-chart-type-${chartType.name}'),
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
