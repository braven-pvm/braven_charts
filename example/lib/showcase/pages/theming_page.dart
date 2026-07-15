// Copyright 2025 Braven Charts - Theming Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

enum _PalettePreset {
  braven('Braven', [
    Color(0xFF4F46E5),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFFE11D48),
    Color(0xFF8B5CF6),
  ]),
  ocean('Ocean', [
    Color(0xFF0369A1),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ]),
  ember('Ember', [
    Color(0xFFEA580C),
    Color(0xFFDC2626),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
  ]),
  colorblind('Colorblind safe', [
    Color(0xFF0173B2),
    Color(0xFFDE8F05),
    Color(0xFF029E73),
    Color(0xFFCC78BC),
    Color(0xFF56B4E9),
  ]);

  const _PalettePreset(this.label, this.colors);

  final String label;
  final List<Color> colors;
}

/// Demonstrates the complete [ChartTheme] surface through selectable presets
/// and nested copyWith customization.
class ThemingPage extends StatefulWidget {
  const ThemingPage({super.key});

  @override
  State<ThemingPage> createState() => _ThemingPageState();
}

class _ThemingPageState extends State<ThemingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  ThemePreset _selectedPreset = ThemePreset.light;
  bool _customizePreset = false;
  _PalettePreset _palette = _PalettePreset.braven;
  double _gridWidth = 0.8;
  double _axisWidth = 1;
  double _seriesWidth = 2.5;
  double _markerSize = 6;
  double _baseFontSize = 12;
  double _crosshairWidth = 1;
  double _focusWidth = 2;
  double _scrollbarThickness = 12;
  double _legendOpacity = 0.95;
  double _animationDurationMs = 400;
  bool _dashedGrid = false;
  bool _showMinorGrid = false;
  double _phase = 0;

  late List<ChartDataPoint> _observed;
  late List<ChartDataPoint> _forecast;
  late List<ChartDataPoint> _capacity;

  @override
  void initState() {
    super.initState();
    _optionsController.showDataMarkers = true;
    _optionsController.showXScrollbar = true;
    _generateData();
  }

  void _generateData() {
    _observed = List.generate(36, (index) {
      final x = index.toDouble();
      return ChartDataPoint(
        x: x,
        y: 54 + index * 0.7 + math.sin(index * 0.48 + _phase) * 8,
      );
    });
    _forecast = List.generate(36, (index) {
      final x = index.toDouble();
      return ChartDataPoint(
        x: x,
        y: 58 + index * 0.62 + math.sin(index * 0.34 + 1.2 + _phase) * 5,
      );
    });
    _capacity = List.generate(36, (index) {
      final x = index.toDouble();
      return ChartDataPoint(
        x: x,
        y: 70 + index * 0.46 + math.cos(index * 0.28 + _phase) * 4,
      );
    });
  }

  void _regenerateData() {
    setState(() {
      _phase += 0.7;
      _generateData();
    });
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Theming',
      subtitle:
          'Compare complete visual systems, then customize every layer of one chart',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildWorkspace(),
    );
  }

  Widget _buildWorkspace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Choose a visual system',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 172, child: _buildThemeRibbon()),
        const SizedBox(height: 16),
        _ThemeGuide(
          key: const ValueKey('theme-system-guide'),
          preset: _selectedPreset,
          theme: _effectiveTheme,
          customized: _customizePreset,
          customLabel: _palette.label,
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildMainChart()),
      ],
    );
  }

  Widget _buildThemeRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final cardWidth = constraints.maxWidth >= 1040
            ? (constraints.maxWidth - spacing * 3) / 4
            : 190.0;

        return SingleChildScrollView(
          key: const ValueKey('theme-preset-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < ThemePreset.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: spacing),
                SizedBox(
                  width: cardWidth,
                  child: _ThemePreviewCard(
                    key: ValueKey(
                      'theme-preset-${ThemePreset.values[index].name}',
                    ),
                    preset: ThemePreset.values[index],
                    selected: _selectedPreset == ThemePreset.values[index],
                    onTap: () => _selectPreset(ThemePreset.values[index]),
                    chart: _buildThemePreview(ThemePreset.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemePreview(ThemePreset preset) {
    final previewObserved = _observed
        .where((point) => point.x % 3 == 0)
        .toList(growable: false);
    final previewCapacity = _capacity
        .where((point) => point.x % 3 == 0)
        .toList(growable: false);

    return RepaintBoundary(
      child: BravenChartPlus(
        series: [
          AreaChartSeries(
            id: 'preview-${preset.name}-capacity',
            points: previewCapacity,
            interpolation: LineInterpolation.bezier,
            strokeWidth: 1.3,
            fillOpacity: 0.16,
          ),
          LineChartSeries(
            id: 'preview-${preset.name}-observed',
            points: previewObserved,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 2,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 1.8,
          ),
        ],
        theme: preset.theme,
        showLegend: false,
        grid: const GridConfig(horizontal: true, vertical: false),
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
      ),
    );
  }

  Widget _buildMainChart() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        final theme = _effectiveTheme;
        final annotationTheme = theme.annotationTheme;
        final pointDefaults = annotationTheme.pointDefaults;
        final rangeDefaults = annotationTheme.rangeDefaults;
        final textDefaults = annotationTheme.textDefaults;
        final thresholdDefaults = annotationTheme.thresholdDefaults;
        final trendDefaults = annotationTheme.trendDefaults;
        return ChartCard(
          title: '$_themeDisplayName operations overview',
          subtitle:
              '3 series · 5 themed annotations · tooltip, crosshair, legend, focus, and scrollbar',
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
          child: BravenChartPlus(
            key: const ValueKey('theming-main-chart'),
            series: [
              AreaChartSeries(
                id: 'capacity',
                name: 'Capacity',
                points: _capacity,
                interpolation: LineInterpolation.bezier,
                strokeWidth: _seriesWidth * 0.72,
                fillOpacity: 0.14,
              ),
              LineChartSeries(
                id: 'observed',
                name: 'Observed',
                points: _observed,
                interpolation: LineInterpolation.monotone,
                strokeWidth: _seriesWidth,
                showDataPointMarkers: _optionsController.showDataMarkers,
                dataPointMarkerRadius: _markerSize / 2,
              ),
              LineChartSeries(
                id: 'forecast',
                name: 'Forecast',
                points: _forecast,
                interpolation: LineInterpolation.bezier,
                strokeWidth: _seriesWidth * 0.82,
                showDataPointMarkers: _optionsController.showDataMarkers,
                dataPointMarkerRadius: _markerSize / 2.4,
              ),
            ],
            annotations: [
              RangeAnnotation(
                id: 'theme-target-range',
                startX: 12,
                endX: 24,
                label: 'Theme range',
                fillColor: rangeDefaults.normalFillColor,
                borderColor: rangeDefaults.normalBorderColor,
                style: rangeDefaults.toAnnotationStyle(),
                allowDragging: false,
                allowEditing: false,
              ),
              ThresholdAnnotation(
                id: 'theme-threshold',
                axis: AnnotationAxis.y,
                value: 78,
                label: 'Threshold',
                lineColor: thresholdDefaults.lineColor,
                lineWidth: thresholdDefaults.lineWidth,
                dashPattern: thresholdDefaults.dashPattern,
                style: thresholdDefaults.toAnnotationStyle(),
                allowDragging: false,
                allowEditing: false,
              ),
              PointAnnotation(
                id: 'theme-point',
                seriesId: 'observed',
                dataPointIndex: 29,
                label: 'Peak',
                markerShape: MarkerShape.values.byName(
                  pointDefaults.markerShape.name,
                ),
                markerSize: pointDefaults.markerSize,
                markerColor: pointDefaults.normalColor,
                style: AnnotationStyle(
                  textStyle: pointDefaults.labelStyle.textStyle,
                  backgroundColor: pointDefaults.labelStyle.backgroundColor,
                  borderColor: pointDefaults.labelStyle.borderColor,
                  borderWidth: pointDefaults.labelStyle.borderWidth,
                  borderRadius: BorderRadius.circular(
                    pointDefaults.labelStyle.borderRadius,
                  ),
                  padding: pointDefaults.labelStyle.padding,
                ),
                allowDragging: false,
                allowEditing: false,
              ),
              TrendAnnotation(
                id: 'theme-trend',
                seriesId: 'forecast',
                trendType: TrendType.linear,
                label: 'Trend',
                lineColor: trendDefaults.lineColor,
                lineWidth: trendDefaults.lineWidth,
                dashPattern: trendDefaults.dashPattern,
                style: trendDefaults.toAnnotationStyle(),
                allowDragging: false,
                allowEditing: false,
              ),
              TextAnnotation(
                id: 'theme-note',
                text: 'AnnotationTheme',
                position: const Offset(24, 24),
                backgroundColor: textDefaults.backgroundColor,
                borderColor: textDefaults.borderColor,
                style: textDefaults.toAnnotationStyle(),
                allowDragging: false,
                allowEditing: false,
              ),
            ],
            theme: theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: theme.scrollbarConfig.copyWith(autoHide: false),
            grid: GridConfig(
              horizontal: _optionsController.showGrid,
              vertical: _optionsController.showGrid,
            ),
            xAxisConfig: XAxisConfig(
              label: 'Reporting interval',
              min: 0,
              max: 35,
              renderMin: 1,
              renderMax: 34,
              showAxisLine: _optionsController.showAxisLines,
            ),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
              label: 'Utilization',
              unit: '%',
              min: 35,
              max: 95,
              showAxisLine: _optionsController.showAxisLines,
            ),
            interactionConfig: InteractionConfig(
              enableZoom: _optionsController.enableZoom,
              enablePan: _optionsController.enablePan,
              crosshair: const CrosshairConfig(
                enabled: true,
                mode: CrosshairMode.both,
                displayMode: CrosshairDisplayMode.tracking,
              ),
              tooltip: const TooltipConfig(enabled: true),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      OptionSection(
        title: 'Theme System',
        icon: Icons.palette_outlined,
        children: [
          EnumOption<ThemePreset>(
            key: const ValueKey('theme-preset-option'),
            label: 'Preset',
            value: _selectedPreset,
            values: ThemePreset.values,
            labelBuilder: (preset) => preset.displayName,
            onChanged: _selectPreset,
          ),
          BoolOption(
            key: const ValueKey('customize-theme'),
            label: 'Customize Preset',
            value: _customizePreset,
            onChanged: (value) => setState(() => _customizePreset = value),
            subtitle: 'Compose nested theme components with copyWith',
          ),
        ],
      ),
      if (_customizePreset) ...[
        OptionSection(
          title: 'Series Palette',
          icon: Icons.color_lens_outlined,
          children: [
            EnumOption<_PalettePreset>(
              key: const ValueKey('series-palette-option'),
              label: 'Palette',
              value: _palette,
              values: _PalettePreset.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) => setState(() => _palette = value),
            ),
            _PaletteStrip(colors: _palette.colors),
            const SizedBox(height: 8),
            SliderOption(
              label: 'Line Width',
              value: _seriesWidth,
              min: 1,
              max: 6,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _seriesWidth = value),
            ),
            SliderOption(
              label: 'Marker Size',
              value: _markerSize,
              min: 3,
              max: 12,
              divisions: 9,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _markerSize = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Grid & Axes',
          icon: Icons.grid_4x4,
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Grid Width',
              value: _gridWidth,
              min: 0,
              max: 2.5,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _gridWidth = value),
            ),
            BoolOption(
              label: 'Dashed Grid',
              value: _dashedGrid,
              onChanged: (value) => setState(() => _dashedGrid = value),
            ),
            BoolOption(
              label: 'Minor Grid',
              value: _showMinorGrid,
              onChanged: (value) => setState(() => _showMinorGrid = value),
            ),
            SliderOption(
              label: 'Axis Width',
              value: _axisWidth,
              min: 0.5,
              max: 3,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _axisWidth = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Interaction & Chrome',
          icon: Icons.touch_app_outlined,
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Crosshair Width',
              value: _crosshairWidth,
              min: 0.5,
              max: 4,
              divisions: 7,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _crosshairWidth = value),
            ),
            SliderOption(
              label: 'Focus Border',
              value: _focusWidth,
              min: 1,
              max: 5,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _focusWidth = value),
            ),
            SliderOption(
              label: 'Scrollbar Thickness',
              value: _scrollbarThickness,
              min: 6,
              max: 22,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _scrollbarThickness = value),
            ),
            SliderOption(
              label: 'Legend Opacity',
              value: _legendOpacity,
              min: 0.4,
              max: 1,
              divisions: 6,
              decimalPlaces: 2,
              onChanged: (value) => setState(() => _legendOpacity = value),
            ),
          ],
        ),
        OptionSection(
          title: 'Typography & Motion',
          icon: Icons.text_fields,
          initiallyExpanded: false,
          children: [
            SliderOption(
              label: 'Base Font Size',
              value: _baseFontSize,
              min: 9,
              max: 18,
              divisions: 9,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _baseFontSize = value),
            ),
            SliderOption(
              label: 'Data Animation',
              value: _animationDurationMs,
              min: 0,
              max: 1000,
              divisions: 10,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (value) =>
                  setState(() => _animationDurationMs = value),
            ),
          ],
        ),
      ],
      StandardChartOptions(
        controller: _optionsController,
        showThemeOption: false,
      ),
      OptionSection(
        title: 'Actions',
        icon: Icons.refresh,
        children: [
          ActionButton(
            label: 'Regenerate Data',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
          if (_customizePreset) ...[
            const SizedBox(height: 8),
            ActionButton(
              label: 'Reset Custom Theme',
              icon: Icons.restore,
              onPressed: _resetCustomTheme,
            ),
          ],
        ],
      ),
      const InfoBox(
        message:
            'ChartTheme combines background, grid, axes, series, interaction, typography, animation, annotations, scrollbar, legend, and focus styling. Every component can be replaced or composed with copyWith.',
      ),
    ];
  }

  ChartTheme get _effectiveTheme {
    final base = _selectedPreset.theme;
    if (!_customizePreset) return base;

    return base.copyWith(
      gridStyle: base.gridStyle.copyWith(
        majorWidth: _gridWidth,
        majorDashPattern: _dashedGrid ? const [5, 4] : const [],
        minorColor: base.gridStyle.majorColor.withValues(alpha: 0.45),
        minorWidth: 0.5,
        minorDashPattern: const [2, 3],
        showMinor: _showMinorGrid,
      ),
      axisStyle: base.axisStyle.copyWith(
        lineWidth: _axisWidth,
        tickWidth: _axisWidth,
      ),
      seriesTheme: base.seriesTheme.copyWith(
        colors: _palette.colors,
        lineWidths: [_seriesWidth],
        markerSizes: [_markerSize],
      ),
      interactionTheme: base.interactionTheme.copyWith(
        crosshairWidth: _crosshairWidth,
      ),
      typographyTheme: base.typographyTheme.copyWith(
        baseFontSize: _baseFontSize,
      ),
      animationTheme: base.animationTheme.copyWith(
        dataUpdateDuration: Duration(
          milliseconds: _animationDurationMs.round(),
        ),
      ),
      scrollbarConfig: base.scrollbarConfig.copyWith(
        thickness: _scrollbarThickness,
        autoHide: false,
      ),
      legendStyle: base.legendStyle.copyWith(opacity: _legendOpacity),
      focusBorderWidth: _focusWidth,
    );
  }

  String get _themeDisplayName => _customizePreset
      ? '${_selectedPreset.displayName} + ${_palette.label}'
      : _selectedPreset.displayName;

  void _selectPreset(ThemePreset preset) {
    setState(() => _selectedPreset = preset);
  }

  void _resetCustomTheme() {
    setState(() {
      _palette = _PalettePreset.braven;
      _gridWidth = 0.8;
      _axisWidth = 1;
      _seriesWidth = 2.5;
      _markerSize = 6;
      _baseFontSize = 12;
      _crosshairWidth = 1;
      _focusWidth = 2;
      _scrollbarThickness = 12;
      _legendOpacity = 0.95;
      _animationDurationMs = 400;
      _dashedGrid = false;
      _showMinorGrid = false;
    });
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final colors = appTheme.colorScheme;
    final chartTheme = preset.theme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Select ${preset.displayName} chart theme',
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
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preset.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appTheme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle,
                        key: ValueKey('selected-theme-${preset.name}'),
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _MiniSwatch(color: chartTheme.backgroundColor),
                    for (var i = 0; i < 4; i++) ...[
                      const SizedBox(width: 3),
                      _MiniSwatch(color: chartTheme.seriesTheme.colorAt(i)),
                    ],
                  ],
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

class _ThemeGuide extends StatelessWidget {
  const _ThemeGuide({
    super.key,
    required this.preset,
    required this.theme,
    required this.customized,
    required this.customLabel,
  });

  final ThemePreset preset;
  final ChartTheme theme;
  final bool customized;
  final String customLabel;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final colors = appTheme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final summary = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.palette_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      customized
                          ? '${preset.displayName} + $customLabel'
                          : preset.displayName,
                      style: appTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ModeBadge(customized: customized),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _description(preset),
                  style: appTheme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: const [
                    'Grid',
                    'Axes',
                    'Series',
                    'Interaction',
                    'Type',
                    'Motion',
                    'Annotations',
                    'Scrollbar',
                    'Legend',
                    'Focus',
                  ].map((label) => _ComponentLabel(label: label)).toList(),
                ),
              ],
            );

            final tokens = _ThemeTokenPanel(
              apiName: _apiName(preset),
              theme: theme,
              customized: customized,
            );

            if (constraints.maxWidth >= 820) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 16),
                  SizedBox(width: 390, child: tokens),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [summary, const SizedBox(height: 12), tokens],
            );
          },
        ),
      ),
    );
  }

  static String _description(ThemePreset preset) {
    return switch (preset) {
      ThemePreset.light =>
        'A neutral default with quiet structure and clear interaction feedback.',
      ThemePreset.dark =>
        'A low-light system with brighter data marks and layered dark surfaces.',
      ThemePreset.corporateBlue =>
        'Restrained blue hierarchy for reporting, operations, and enterprise UI.',
      ThemePreset.vibrant =>
        'High-energy colour, rounded interaction details, and expressive motion.',
      ThemePreset.minimal =>
        'Reduced visual furniture that keeps attention on the data itself.',
      ThemePreset.highContrast =>
        'Strong strokes, larger type, and unmistakable interaction boundaries.',
      ThemePreset.colorblindFriendly =>
        'A deliberately separated palette that does not depend on red–green contrast.',
    };
  }

  static String _apiName(ThemePreset preset) {
    return switch (preset) {
      ThemePreset.light => 'ChartTheme.light',
      ThemePreset.dark => 'ChartTheme.dark',
      ThemePreset.corporateBlue => 'ChartTheme.corporateBlue',
      ThemePreset.vibrant => 'ChartTheme.vibrant',
      ThemePreset.minimal => 'ChartTheme.minimal',
      ThemePreset.highContrast => 'ChartTheme.highContrast',
      ThemePreset.colorblindFriendly => 'ChartTheme.colorblindFriendly',
    };
  }
}

class _ThemeTokenPanel extends StatelessWidget {
  const _ThemeTokenPanel({
    required this.apiName,
    required this.theme,
    required this.customized,
  });

  final String apiName;
  final ChartTheme theme;
  final bool customized;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: appTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appTheme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.code, size: 16, color: appTheme.colorScheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              customized ? '$apiName.copyWith(…)' : apiName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: appTheme.textTheme.labelMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 10),
          _TokenSwatch(label: 'BG', color: theme.backgroundColor),
          _TokenSwatch(label: 'Grid', color: theme.gridStyle.majorColor),
          _TokenSwatch(label: 'Axis', color: theme.axisStyle.lineColor),
          for (var i = 0; i < 3; i++)
            _TokenSwatch(
              label: 'S${i + 1}',
              color: theme.seriesTheme.colorAt(i),
            ),
          _TokenSwatch(
            label: 'Point annotation',
            color: theme.annotationTheme.pointDefaults.normalColor,
          ),
          _TokenSwatch(
            label: 'Threshold annotation',
            color: theme.annotationTheme.thresholdDefaults.lineColor,
          ),
        ],
      ),
    );
  }
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: colors
            .map(
              (color) => Expanded(child: Container(height: 28, color: color)),
            )
            .toList(),
      ),
    );
  }
}

class _MiniSwatch extends StatelessWidget {
  const _MiniSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
    );
  }
}

class _TokenSwatch extends StatelessWidget {
  const _TokenSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Tooltip(
        message: label,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.customized});

  final bool customized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        customized ? 'CUSTOM' : 'PRESET',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _ComponentLabel extends StatelessWidget {
  const _ComponentLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
