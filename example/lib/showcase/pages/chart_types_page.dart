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
  ChartType.donut,
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
  bool _pieShowLabels = true;
  PieDataLabelPosition _pieLabelPosition = PieDataLabelPosition.outside;
  double _pieLabelOffset = 0;
  double _pieSliceGap = 3;
  double _pieStartAngle = -90;
  double _donutInnerRadius = 0.58;
  double _donutSweepAngle = 360;
  bool _donutShowCenter = true;
  DonutCenterValueMode _donutCenterValueMode =
      DonutCenterValueMode.selectedOrTotal;
  _ChartTypePieFill _pieFill = _ChartTypePieFill.radial;
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
          if (!_isRadialType(_chartType))
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
      if (_isRadialType(_chartType))
        OptionSection(
          title: _chartType == ChartType.donut
              ? 'Donut Appearance'
              : 'Pie Appearance',
          icon: _chartType == ChartType.donut
              ? Icons.donut_large_outlined
              : Icons.pie_chart_outline,
          children: [
            BoolOption(
              label: 'Show Data Labels',
              value: _pieShowLabels,
              onChanged: (value) => setState(() => _pieShowLabels = value),
              subtitle: 'Keep category meaning beside each contribution',
            ),
            if (_pieShowLabels)
              EnumOption<PieDataLabelPosition>(
                label: 'Label Position',
                value: _pieLabelPosition,
                values: PieDataLabelPosition.values,
                labelBuilder: (value) => switch (value) {
                  PieDataLabelPosition.inside => 'Inside slices',
                  PieDataLabelPosition.outside => 'Outside with connectors',
                },
                onChanged: (value) => setState(() => _pieLabelPosition = value),
              ),
            if (_pieShowLabels &&
                _pieLabelPosition == PieDataLabelPosition.outside)
              SliderOption(
                label: 'Label Offset',
                value: _pieLabelOffset,
                min: 0,
                max: 64,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _pieLabelOffset = value),
              ),
            SliderOption(
              label: 'Slice Gap',
              value: _pieSliceGap,
              min: 0,
              max: 8,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _pieSliceGap = value),
            ),
            SliderOption(
              label: 'Start Angle',
              value: _pieStartAngle,
              min: -180,
              max: 180,
              divisions: 24,
              suffix: '°',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _pieStartAngle = value),
            ),
            if (_chartType == ChartType.donut) ...[
              SliderOption(
                label: 'Inner Radius',
                value: _donutInnerRadius * 100,
                min: 20,
                max: 82,
                divisions: 31,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _donutInnerRadius = value / 100),
              ),
              SliderOption(
                label: 'Sweep Angle',
                value: _donutSweepAngle,
                min: 90,
                max: 360,
                divisions: 18,
                suffix: '°',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _donutSweepAngle = value),
              ),
              BoolOption(
                label: 'Show Center Content',
                value: _donutShowCenter,
                onChanged: (value) => setState(() => _donutShowCenter = value),
              ),
              if (_donutShowCenter)
                EnumOption<DonutCenterValueMode>(
                  label: 'Center Value',
                  value: _donutCenterValueMode,
                  values: DonutCenterValueMode.values,
                  labelBuilder: (value) => switch (value) {
                    DonutCenterValueMode.total => 'Total',
                    DonutCenterValueMode.selectedValue => 'Selected value',
                    DonutCenterValueMode.selectedOrTotal => 'Selected or total',
                    DonutCenterValueMode.custom => 'Custom text',
                  },
                  onChanged: (value) =>
                      setState(() => _donutCenterValueMode = value),
                ),
            ],
            EnumOption<_ChartTypePieFill>(
              label: 'Slice Fill',
              value: _pieFill,
              values: _ChartTypePieFill.values,
              labelBuilder: (value) => switch (value) {
                _ChartTypePieFill.solid => 'Solid color',
                _ChartTypePieFill.linear => 'Linear gradient',
                _ChartTypePieFill.radial => 'Radial gradient',
              },
              onChanged: (value) => setState(() => _pieFill = value),
            ),
          ],
        ),
      StandardChartOptions(
        controller: _optionsController,
        showGridOption: !_isRadialType(_chartType),
        showAxisOption: !_isRadialType(_chartType),
        showMarkerOption: !_isRadialType(_chartType),
        showScrollbarOptions: !_isRadialType(_chartType),
        showLineStyleOption: false,
        showInteractionOptions: !_isRadialType(_chartType),
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
        final chartTypeCount = _availableChartTypes.length;
        final fitWidth =
            (constraints.maxWidth - spacing * (chartTypeCount - 1)) /
            chartTypeCount;
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
    final isRadial = _isRadialType(_chartType);
    return ChartCard(
      title: '${_chartTypeLabel(_chartType)} chart playground',
      subtitle: _mainChartSummary(),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: BravenChartPlus(
        series: _buildSeries(_chartType),
        theme: _optionsController.theme,
        showLegend: _optionsController.showLegend,
        showXScrollbar: !isRadial && _optionsController.showXScrollbar,
        showYScrollbar: !isRadial && _optionsController.showYScrollbar,
        scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
        grid: isRadial
            ? const GridConfig(horizontal: false, vertical: false)
            : GridConfig(
                horizontal: _optionsController.showGrid,
                vertical: _optionsController.showGrid,
              ),
        xAxisConfig: isRadial
            ? null
            : XAxisConfig(
                label: 'Interval',
                min: 0,
                max: 17,
                renderMin: 1,
                renderMax: 16,
                showAxisLine: _optionsController.showAxisLines,
              ),
        yAxis: isRadial
            ? null
            : YAxisConfig(
                position: YAxisPosition.left,
                label: 'Value',
                min: 0,
                max: 110,
                showAxisLine: _optionsController.showAxisLines,
              ),
        interactionConfig: isRadial
            ? const InteractionConfig(
                crosshair: CrosshairConfig(enabled: false),
                tooltip: TooltipConfig(enabled: true),
                enableZoom: false,
                enablePan: false,
              )
            : InteractionConfig(
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
              startAngleDegrees: preview ? -90 : _pieStartAngle,
              radiusFactor: preview ? 0.82 : 0.86,
              sliceGap: preview ? 1 : _pieSliceGap,
              borderWidth: preview ? 0 : 1,
              gradient: switch (preview ? _ChartTypePieFill.radial : _pieFill) {
                _ChartTypePieFill.solid => null,
                _ChartTypePieFill.linear => const PieGradientStyle(
                  type: PieGradientType.linear,
                ),
                _ChartTypePieFill.radial => const PieGradientStyle(
                  type: PieGradientType.radial,
                ),
              },
            ),
            dataLabels: PieDataLabelConfig(
              isVisible: !preview && _pieShowLabels,
              position: _pieLabelPosition,
              content: PieDataLabelContent.categoryAndPercentage,
              outsideOffset: _pieLabelOffset,
            ),
          ),
        ];
      case ChartType.donut:
        const categories = [
          'Subscriptions',
          'Services',
          'Hardware',
          'Training',
          'Other',
        ];
        final categoryCount = preview ? 4 : categories.length;
        return [
          DonutChartSeries.fromMap(
            id: preview ? 'preview-donut' : 'donut-contributions',
            name: 'Contribution',
            unit: 'units',
            values: {
              for (var index = 0; index < categoryCount; index++)
                categories[index]: _observedData[index].y.clamp(
                  1,
                  double.infinity,
                ),
            },
            donutStyle: DonutChartStyle(
              innerRadiusFactor: preview ? 0.58 : _donutInnerRadius,
              sweepAngleDegrees: preview ? 360 : _donutSweepAngle,
              startAngleDegrees: preview ? -90 : _pieStartAngle,
              radiusFactor: preview ? 0.82 : 0.86,
              sliceGap: preview ? 1 : _pieSliceGap,
              borderWidth: preview ? 0 : 1,
              gradient: switch (preview ? _ChartTypePieFill.radial : _pieFill) {
                _ChartTypePieFill.solid => null,
                _ChartTypePieFill.linear => const PieGradientStyle(
                  type: PieGradientType.linear,
                ),
                _ChartTypePieFill.radial => const PieGradientStyle(
                  type: PieGradientType.radial,
                ),
              },
            ),
            centerContent: DonutCenterContent(
              isVisible: preview || _donutShowCenter,
              label: preview
                  ? 'Total'
                  : switch (_donutCenterValueMode) {
                      DonutCenterValueMode.total => 'Total',
                      DonutCenterValueMode.custom => 'Status',
                      DonutCenterValueMode.selectedValue ||
                      DonutCenterValueMode.selectedOrTotal => null,
                    },
              valueMode: preview
                  ? DonutCenterValueMode.total
                  : _donutCenterValueMode,
              customValue:
                  !preview &&
                      _donutCenterValueMode == DonutCenterValueMode.custom
                  ? 'On track'
                  : null,
            ),
            dataLabels: PieDataLabelConfig(
              isVisible: !preview && _pieShowLabels,
              position: _pieLabelPosition,
              content: PieDataLabelContent.categoryAndPercentage,
              outsideOffset: _pieLabelOffset,
            ),
          ),
        ];
    }
  }

  String _mainChartSummary() {
    final seriesCount = _isRadialType(_chartType)
        ? 1
        : (_showSecondSeries ? 2 : 1);
    final configuration = switch (_chartType) {
      ChartType.line => '${_interpolation.name} interpolation',
      ChartType.area =>
        '${_interpolation.name} · ${(_fillOpacity * 100).round()}% fill',
      ChartType.bar => '${(_barWidthPercent * 100).round()}% bar width',
      ChartType.scatter => '${_markerRadius.toStringAsFixed(0)}px markers',
      ChartType.pie =>
        '5 categories · ${_pieSliceGap.toStringAsFixed(0)}px gap · '
            '${_pieFill.name} fill · '
            '${_pieShowLabels ? _pieLabelPosition.name : 'labels hidden'}',
      ChartType.donut =>
        '5 categories · ${(_donutInnerRadius * 100).round()}% center · '
            '${_donutSweepAngle.round()}° sweep · ${_pieFill.name} fill · '
            '${_donutShowCenter ? _donutCenterValueMode.name : 'center hidden'}',
    };

    final dataSummary = _isRadialType(_chartType)
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
      ChartType.donut => 'Donut',
    };
  }

  String _chartTypeDescription(ChartType chartType) {
    return switch (chartType) {
      ChartType.line => 'Smooth + markers',
      ChartType.area => 'Layered fills',
      ChartType.bar => 'Multi-series columns',
      ChartType.scatter => 'Distinct marker sets',
      ChartType.pie => 'Category contributions',
      ChartType.donut => 'Contributions around a center',
    };
  }

  bool _isRadialType(ChartType chartType) =>
      chartType == ChartType.pie || chartType == ChartType.donut;
}

enum _ChartTypePieFill { solid, linear, radial }

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
