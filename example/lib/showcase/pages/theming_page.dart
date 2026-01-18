// Copyright 2025 Braven Charts - Theming Page
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../data/data_generator.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';

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
      subtitle: 'Customize chart appearance',
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
            label: 'Compare Themes',
            value: _showComparison,
            onChanged: (v) => setState(() => _showComparison = v),
            subtitle: 'Show multiple themes side-by-side',
          ),
        ],
      ),

      // Theme preview
      OptionSection(
        title: 'Theme Preview',
        initiallyExpanded: false,
        children: [
          _buildThemePreview(_selectedPreset),
        ],
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
        ],
      ),
    ];
  }

  Widget _buildThemePreview(ThemePreset preset) {
    final theme = preset.theme;
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
            preset.displayName,
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
              for (var i = 0; i < 4 && i < theme.seriesTheme.colors.length; i++) ...[
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
        return ChartCard(
          title: _selectedPreset.displayName,
          subtitle: 'Theme demonstration',
          child: BravenChartPlus(
            series: [
              LineChartSeries(
                id: 'series1',
                name: 'Series 1',
                points: _data1,
                interpolation: LineInterpolation.bezier,
                strokeWidth: 2.0,
                showDataPointMarkers: _optionsController.showDataMarkers,
              ),
              LineChartSeries(
                id: 'series2',
                name: 'Series 2',
                points: _data2,
                interpolation: LineInterpolation.bezier,
                strokeWidth: 2.0,
                showDataPointMarkers: _optionsController.showDataMarkers,
              ),
            ],
            theme: _selectedPreset.theme,
            showLegend: _optionsController.showLegend,
            showXScrollbar: _optionsController.showXScrollbar,
            showYScrollbar: _optionsController.showYScrollbar,
            scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(autoHide: false),
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
            ),
          ),
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
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
            ],
            theme: preset.theme,
            showLegend: false,
            xAxisConfig: const XAxisConfig(),
            yAxis: YAxisConfig(
              position: YAxisPosition.left,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusPanel() {
    return StatusPanel(
      items: [
        StatusItem(
          label: 'Theme',
          value: _selectedPreset.displayName,
        ),
        const StatusItem(
          label: 'Series',
          value: '2',
        ),
        StatusItem(
          label: 'Mode',
          value: _showComparison ? 'Compare' : 'Single',
        ),
      ],
    );
  }
}
