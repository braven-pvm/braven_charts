// Copyright 2025 Braven Charts - Theming Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
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

/// Demonstrates theming capabilities:
/// - Pre-built themes (light, dark, corporate, vibrant)
/// - Custom theme creation
/// - Theme comparison
class ThemingPage extends StatefulWidget {
  const ThemingPage({super.key});

  @override
  State<ThemingPage> createState() => _ThemingPageState();
}

class _ThemingPageState extends State<ThemingPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();

  // Theme selection
  ThemePreset _selectedPreset = ThemePreset.light;
  bool _showComparison = false;
  bool _customizePreset = true;
  _PalettePreset _palette = _PalettePreset.braven;
  double _gridWidth = 0.8;
  double _axisWidth = 1.0;
  double _seriesWidth = 2.5;
  double _markerSize = 6.0;
  double _baseFontSize = 12.0;
  bool _dashedGrid = false;
  bool _showMinorGrid = false;

  // Generated data
  late List<ChartDataPoint> _data1;
  late List<ChartDataPoint> _data2;

  @override
  void initState() {
    super.initState();
    _regenerateData();
  }

  void _regenerateData() {
    setState(() {
      _data1 = DataGenerator.generateSineWave(
        count: 50,
        amplitude: 30,
        yOffset: 50,
        frequency: 0.15,
      );
      _data2 = DataGenerator.generateCosineWave(
        count: 50,
        amplitude: 25,
        yOffset: 55,
        frequency: 0.15,
      );
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
          'Compare presets and configure palette, grid, axes, series, typography, and interaction styling',
      optionsChildren: _buildOptionsChildren(),
      chart: _buildChart(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  List<Widget> _buildOptionsChildren() {
    return [
      // Standard display options (minus theme since we have our own)
      StandardChartOptions(
        controller: _optionsController,
        showThemeOption: false,
      ),

      // Theme selection
      OptionSection(
        title: 'Theme Selection',
        icon: Icons.palette,
        children: [
          EnumOption<ThemePreset>(
            label: 'Theme Preset',
            value: _selectedPreset,
            values: ThemePreset.values,
            labelBuilder: (p) => p.displayName,
            onChanged: (v) => setState(() => _selectedPreset = v),
          ),
          BoolOption(
            key: const ValueKey('compare-themes'),
            label: 'Compare Themes',
            value: _showComparison,
            onChanged: (v) => setState(() => _showComparison = v),
            subtitle: 'Show multiple themes side-by-side',
          ),
          BoolOption(
            label: 'Customize Preset',
            value: _customizePreset,
            onChanged: (v) => setState(() => _customizePreset = v),
            subtitle: 'Build on the preset with ChartTheme.copyWith',
          ),
        ],
      ),

      if (_customizePreset)
        OptionSection(
          title: 'Series Palette',
          icon: Icons.color_lens_outlined,
          children: [
            EnumOption<_PalettePreset>(
              label: 'Palette',
              value: _palette,
              values: _PalettePreset.values,
              labelBuilder: (value) => value.label,
              onChanged: (value) => setState(() => _palette = value),
            ),
            const SizedBox(height: 8),
            _PaletteStrip(colors: _palette.colors),
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

      if (_customizePreset)
        OptionSection(
          title: 'Grid & Axes',
          icon: Icons.grid_4x4,
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

      if (_customizePreset)
        OptionSection(
          title: 'Typography',
          icon: Icons.text_fields,
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
          ],
        ),

      // Theme preview
      OptionSection(
        title: 'Theme Preview',
        initiallyExpanded: false,
        children: [_buildThemePreview(_effectiveTheme, _themeDisplayName)],
      ),

      // Actions
      OptionSection(
        title: 'Actions',
        children: [
          ActionButton(
            label: 'Regenerate Data',
            icon: Icons.refresh,
            onPressed: _regenerateData,
          ),
          ActionButton(
            label: 'Reset Custom Theme',
            icon: Icons.restore,
            onPressed: _resetCustomTheme,
          ),
        ],
      ),
      const InfoBox(
        message:
            'The custom preview is composed with ChartTheme.copyWith plus GridStyle, AxisStyle, SeriesTheme, and TypographyTheme copyWith methods.',
      ),
    ];
  }

  ChartTheme get _effectiveTheme {
    final base = _selectedPreset.theme;
    if (!_customizePreset) return base;

    final minorColor = base.gridStyle.majorColor.withValues(alpha: 0.45);
    return base.copyWith(
      gridStyle: base.gridStyle.copyWith(
        majorWidth: _gridWidth,
        majorDashPattern: _dashedGrid ? const [5, 4] : const [],
        minorColor: minorColor,
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
      typographyTheme: base.typographyTheme.copyWith(
        baseFontSize: _baseFontSize,
      ),
    );
  }

  String get _themeDisplayName => _customizePreset
      ? '${_selectedPreset.displayName} + ${_palette.label}'
      : _selectedPreset.displayName;

  void _resetCustomTheme() {
    setState(() {
      _palette = _PalettePreset.braven;
      _gridWidth = 0.8;
      _axisWidth = 1;
      _seriesWidth = 2.5;
      _markerSize = 6;
      _baseFontSize = 12;
      _dashedGrid = false;
      _showMinorGrid = false;
    });
  }

  Widget _buildThemePreview(ChartTheme theme, String name) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(
              color: theme.axisStyle.labelStyle.color ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _colorSwatch('Grid', theme.gridStyle.majorColor),
              const SizedBox(width: 8),
              _colorSwatch('Axis', theme.axisStyle.lineColor),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (
                var i = 0;
                i < 4 && i < theme.seriesTheme.colors.length;
                i++
              ) ...[
                if (i > 0) const SizedBox(width: 4),
                _colorSwatch('S${i + 1}', theme.seriesTheme.colors[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _colorSwatch(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade400),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9)),
      ],
    );
  }

  Widget _buildChart() {
    if (_showComparison) {
      return _buildComparisonView();
    }

    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return Column(
          children: [
            _ThemeAnatomy(theme: _effectiveTheme),
            const SizedBox(height: 12),
            Expanded(
              child: ChartCard(
                title: _themeDisplayName,
                subtitle:
                    'Series, annotations, axes, grid, legend, crosshair, tooltip, scrollbar, and focus styling',
                child: BravenChartPlus(
                  series: [
                    LineChartSeries(
                      id: 'series1',
                      name: 'Series 1',
                      points: _data1,
                      interpolation: LineInterpolation.bezier,
                      strokeWidth: _seriesWidth,
                      showDataPointMarkers: _optionsController.showDataMarkers,
                    ),
                    LineChartSeries(
                      id: 'series2',
                      name: 'Series 2',
                      points: _data2,
                      interpolation: LineInterpolation.bezier,
                      strokeWidth: _seriesWidth,
                      showDataPointMarkers: _optionsController.showDataMarkers,
                    ),
                  ],
                  annotations: [
                    RangeAnnotation(
                      id: 'theme-target-range',
                      startX: 18,
                      endX: 32,
                      label: 'Target zone',
                      fillColor: _effectiveTheme.seriesTheme
                          .colorAt(2)
                          .withValues(alpha: 0.12),
                      borderColor: _effectiveTheme.seriesTheme.colorAt(2),
                      allowDragging: false,
                      allowEditing: false,
                    ),
                    ThresholdAnnotation(
                      id: 'theme-threshold',
                      axis: AnnotationAxis.y,
                      value: 75,
                      label: 'Threshold',
                      lineColor: _effectiveTheme.seriesTheme.colorAt(3),
                      dashPattern: const [5, 4],
                      allowDragging: false,
                      allowEditing: false,
                    ),
                  ],
                  theme: _effectiveTheme,
                  showLegend: _optionsController.showLegend,
                  showXScrollbar: _optionsController.showXScrollbar,
                  showYScrollbar: _optionsController.showYScrollbar,
                  scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
                    autoHide: false,
                  ),
                  xAxisConfig: XAxisConfig(
                    showAxisLine: _optionsController.showAxisLines,
                  ),
                  yAxis: YAxisConfig(
                    position: YAxisPosition.left,
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
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonView() {
    final presets = [
      ThemePreset.light,
      ThemePreset.dark,
      ThemePreset.corporateBlue,
      ThemePreset.vibrant,
      ThemePreset.minimal,
      ThemePreset.highContrast,
      ThemePreset.colorblindFriendly,
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 520,
        mainAxisExtent: 300,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final preset = presets[index];
        return ChartCard(
          title: preset.displayName,
          padding: const EdgeInsets.all(8),
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'series1',
                name: 'Series 1',
                points: _data1,
                interpolation: LineInterpolation.bezier,
                strokeWidth: 1.5,
              ),
              LineChartSeries(
                id: 'series2',
                name: 'Series 2',
                points: _data2,
                interpolation: LineInterpolation.monotone,
                strokeWidth: 1.5,
              ),
            ],
            theme: preset.theme,
            showLegend: true,
            xAxisConfig: const XAxisConfig(),
            yAxis: YAxisConfig(position: YAxisPosition.left),
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(label: 'Theme', value: _selectedPreset.displayName),
        const StatusItem(label: 'Series', value: '2'),
        StatusItem(
          label: 'Mode',
          value: _showComparison
              ? '7 presets'
              : (_customizePreset ? 'Custom' : 'Preset'),
        ),
        StatusItem(
          label: 'Palette',
          value: _customizePreset ? _palette.label : 'Preset default',
        ),
      ],
    );
  }
}

class _PaletteStrip extends StatelessWidget {
  const _PaletteStrip({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: colors
          .map(
            (color) => Expanded(
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ThemeAnatomy extends StatelessWidget {
  const _ThemeAnatomy({required this.theme});

  final ChartTheme theme;

  @override
  Widget build(BuildContext context) {
    const components = [
      (Icons.grid_4x4, 'GridStyle'),
      (Icons.straighten, 'AxisStyle'),
      (Icons.show_chart, 'SeriesTheme'),
      (Icons.touch_app_outlined, 'InteractionTheme'),
      (Icons.text_fields, 'TypographyTheme'),
      (Icons.edit_note_outlined, 'AnnotationTheme'),
      (Icons.view_sidebar_outlined, 'Legend & scrollbar'),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme anatomy',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: components
                  .map(
                    (component) => Chip(
                      avatar: Icon(component.$1, size: 15),
                      label: Text(component.$2),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
