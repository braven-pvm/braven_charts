// Copyright 2025 Braven Charts - Scientific Charts Page
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/standard_options.dart';
import 'lactate_threshold_page.dart';
import 'power_lactate_page.dart';

enum _ScientificExample {
  waveSynthesis,
  distributions,
  regression,
  powerLactate,
  lactateThreshold,
}

/// A scientific charting hub spanning mathematical and applied physiology use.
class ScientificPage extends StatefulWidget {
  const ScientificPage({super.key});

  @override
  State<ScientificPage> createState() => _ScientificPageState();
}

class _ScientificPageState extends State<ScientificPage> {
  static const _blue = Color(0xFF3478F6);
  static const _orange = Color(0xFFFF7A30);
  static const _green = Color(0xFF11A683);
  static const _red = Color(0xFFFF405D);
  static const _purple = Color(0xFF7B4CE2);

  final ChartOptionsController _optionsController = ChartOptionsController();

  _ScientificExample _selectedExample = _ScientificExample.waveSynthesis;

  double _frequency = 0.16;
  double _amplitude = 28;
  double _phase = 0;
  int _harmonics = 2;

  double _meanA = 42;
  double _spreadA = 12;
  double _meanB = 62;
  double _spreadB = 8;

  double _regressionSlope = 0.55;
  double _regressionNoise = 24;
  bool _showAnalysisOverlay = true;

  late List<ChartDataPoint> _primaryData;
  late List<ChartDataPoint> _secondaryData;
  late List<ChartDataPoint> _fitData;

  @override
  void initState() {
    super.initState();
    _refreshAnalyticalData();
  }

  @override
  void dispose() {
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildExampleNavigator(),
        Expanded(
          child: switch (_selectedExample) {
            _ScientificExample.powerLactate => const PowerLactatePage(),
            _ScientificExample.lactateThreshold => const LactateThresholdPage(),
            _ => _buildAnalyticalPage(),
          },
        ),
      ],
    );
  }

  Widget _buildExampleNavigator() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scientific examples',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'From mathematical models to live physiology and threshold detection',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(height: 146, child: _buildExampleRibbon()),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleRibbon() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final width = constraints.maxWidth >= 1120
            ? (constraints.maxWidth - gap * 4) / 5
            : 194.0;
        return SingleChildScrollView(
          key: const ValueKey('scientific-example-ribbon'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (
                var index = 0;
                index < _ScientificExample.values.length;
                index++
              ) ...[
                if (index > 0) const SizedBox(width: gap),
                SizedBox(
                  width: width,
                  child: _ScientificExampleCard(
                    key: ValueKey(
                      'scientific-example-${_ScientificExample.values[index].name}',
                    ),
                    example: _ScientificExample.values[index],
                    selected:
                        _selectedExample == _ScientificExample.values[index],
                    onTap: () =>
                        _selectExample(_ScientificExample.values[index]),
                    chart: _buildPreview(_ScientificExample.values[index]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(_ScientificExample example) {
    final data = _previewSeries(example);
    return BravenChartPlus(
      key: ValueKey('scientific-preview-${example.name}'),
      series: data,
      annotations: _previewAnnotations(example),
      normalizationMode: example == _ScientificExample.powerLactate
          ? NormalizationMode.perSeries
          : null,
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
      grid: const GridConfig(horizontal: true, vertical: false),
      showLegend: false,
      interactionConfig: const InteractionConfig(
        enableZoom: false,
        enablePan: false,
      ),
    );
  }

  List<ChartSeries> _previewSeries(_ScientificExample example) {
    List<ChartDataPoint> sample(List<ChartDataPoint> source) => source
        .asMap()
        .entries
        .where((entry) => entry.key % 8 == 0)
        .map((entry) => entry.value)
        .toList();

    switch (example) {
      case _ScientificExample.waveSynthesis:
        final wave = _generateWave(0.16, 24, 0, 2);
        return [
          LineChartSeries(
            id: 'preview-wave',
            points: sample(wave),
            color: _blue,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.5,
          ),
        ];
      case _ScientificExample.distributions:
        return [
          AreaChartSeries(
            id: 'preview-gaussian-a',
            points: sample(_generateGaussian(42, 12)),
            color: _purple,
            interpolation: LineInterpolation.bezier,
            fillOpacity: 0.22,
            strokeWidth: 1.4,
          ),
          AreaChartSeries(
            id: 'preview-gaussian-b',
            points: sample(_generateGaussian(62, 8)),
            color: _green,
            interpolation: LineInterpolation.bezier,
            fillOpacity: 0.18,
            strokeWidth: 1.4,
          ),
        ];
      case _ScientificExample.regression:
        final regression = _generateRegression(0.55, 24);
        return [
          ScatterChartSeries(
            id: 'preview-samples',
            points: regression.$1.where((point) => point.x % 8 == 0).toList(),
            color: _blue,
            markerRadius: 2.2,
          ),
          LineChartSeries(
            id: 'preview-fit',
            points: sample(regression.$2),
            color: _red,
            strokeWidth: 1.4,
          ),
        ];
      case _ScientificExample.powerLactate:
        final power = List.generate(
          17,
          (index) => ChartDataPoint(
            x: index.toDouble(),
            y: 180 + index * 8 + math.sin(index * 0.8) * 35,
          ),
        );
        final lactate = List.generate(
          7,
          (index) => ChartDataPoint(
            x: (index * 2.5).toDouble(),
            y: 0.8 + math.pow(index / 6, 2.7) * 4.8,
          ),
        );
        return [
          AreaChartSeries(
            id: 'preview-power',
            points: power,
            color: _orange,
            fillOpacity: 0.16,
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.left,
              visible: false,
            ),
          ),
          LineChartSeries(
            id: 'preview-lactate',
            points: lactate,
            color: _red,
            strokeWidth: 1.6,
            yAxisConfig: YAxisConfig(
              position: YAxisPosition.right,
              visible: false,
            ),
          ),
        ];
      case _ScientificExample.lactateThreshold:
        final curve = List.generate(15, (index) {
          final x = 100 + index * 12.0;
          final offset = math.max(0, index - 7);
          return ChartDataPoint(
            x: x,
            y: 1.0 + index * 0.05 + offset * offset * 0.1,
          );
        });
        return [
          LineChartSeries(
            id: 'preview-threshold',
            points: curve,
            color: _purple,
            interpolation: LineInterpolation.monotone,
            strokeWidth: 1.7,
            showDataPointMarkers: true,
            dataPointMarkerRadius: 2,
          ),
        ];
    }
  }

  List<ChartAnnotation> _previewAnnotations(_ScientificExample example) {
    if (example != _ScientificExample.lactateThreshold) return const [];
    return [
      ThresholdAnnotation(
        id: 'preview-lt1',
        axis: AnnotationAxis.x,
        value: 196,
        label: 'LT1',
        lineColor: _green,
        lineWidth: 1,
        dashPattern: const [3, 2],
      ),
    ];
  }

  Widget _buildAnalyticalPage() {
    return ChartPageLayout(
      title: _exampleTitle(_selectedExample),
      subtitle: _exampleSubtitle(_selectedExample),
      optionsChildren: _buildOptions(),
      chart: _buildAnalyticalWorkspace(),
      bottomPanel: _buildStatusPanel(),
    );
  }

  Widget _buildAnalyticalWorkspace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final guide = _ScientificGuide(
          key: const ValueKey('scientific-analysis-guide'),
          example: _selectedExample,
        );
        final stage = _buildAnalyticalStage();
        if (constraints.maxHeight < 420) {
          return ListView(
            children: [
              guide,
              const SizedBox(height: 16),
              SizedBox(height: 430, child: stage),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            guide,
            const SizedBox(height: 16),
            Expanded(child: stage),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticalStage() {
    return ChartCard(
      key: const ValueKey('scientific-main-stage'),
      title: _stageTitle(_selectedExample),
      subtitle: _stageSubtitle(_selectedExample),
      child: ListenableBuilder(
        listenable: _optionsController,
        builder: (context, _) => BravenChartPlus(
          key: ValueKey('scientific-main-chart-${_selectedExample.name}'),
          series: _mainSeries,
          annotations: _mainAnnotations,
          theme: _optionsController.theme,
          showLegend: _optionsController.showLegend,
          showXScrollbar: _optionsController.showXScrollbar,
          showYScrollbar: _optionsController.showYScrollbar,
          scrollbarTheme: ScrollbarConfig.defaultLight.copyWith(
            autoHide: false,
          ),
          xAxisConfig: XAxisConfig(
            label: _selectedExample == _ScientificExample.regression
                ? 'Predictor'
                : 'Sample',
            unit: _selectedExample == _ScientificExample.waveSynthesis
                ? 's'
                : null,
            min: _selectedExample == _ScientificExample.waveSynthesis ? -4 : -5,
            max: _selectedExample == _ScientificExample.waveSynthesis
                ? 84
                : 105,
            renderMin: 0,
            renderMax: _selectedExample == _ScientificExample.waveSynthesis
                ? 80
                : 100,
            showAxisLine: _optionsController.showAxisLines,
          ),
          yAxis: YAxisConfig(
            position: YAxisPosition.left,
            label: _selectedExample == _ScientificExample.distributions
                ? 'Density'
                : 'Response',
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

  List<ChartSeries> get _mainSeries {
    final markers = _optionsController.showDataMarkers;
    return switch (_selectedExample) {
      _ScientificExample.waveSynthesis => [
        LineChartSeries(
          id: 'wave-synthesis',
          name: 'Sine + harmonics',
          points: _primaryData,
          color: _blue,
          interpolation: LineInterpolation.monotone,
          strokeWidth: 2.2,
          showDataPointMarkers: markers,
        ),
        LineChartSeries(
          id: 'reference-wave',
          name: 'Reference cosine',
          points: _secondaryData,
          color: _orange,
          interpolation: LineInterpolation.monotone,
          strokeWidth: 1.5,
          showDataPointMarkers: markers,
        ),
      ],
      _ScientificExample.distributions => [
        AreaChartSeries(
          id: 'distribution-a',
          name: 'Cohort A',
          points: _primaryData,
          color: _purple,
          interpolation: LineInterpolation.bezier,
          fillOpacity: 0.26,
          strokeWidth: 2,
          showDataPointMarkers: markers,
        ),
        AreaChartSeries(
          id: 'distribution-b',
          name: 'Cohort B',
          points: _secondaryData,
          color: _green,
          interpolation: LineInterpolation.bezier,
          fillOpacity: 0.2,
          strokeWidth: 2,
          showDataPointMarkers: markers,
        ),
      ],
      _ScientificExample.regression => [
        ScatterChartSeries(
          id: 'observations',
          name: 'Observations',
          points: _primaryData,
          color: _blue,
          markerRadius: 4,
        ),
        LineChartSeries(
          id: 'linear-fit',
          name: 'Linear fit',
          points: _fitData,
          color: _red,
          strokeWidth: 2.2,
          showDataPointMarkers: markers,
        ),
      ],
      _ => const [],
    };
  }

  List<ChartAnnotation> get _mainAnnotations {
    if (!_showAnalysisOverlay) return const [];
    return switch (_selectedExample) {
      _ScientificExample.waveSynthesis => [
        ThresholdAnnotation(
          id: 'signal-center',
          axis: AnnotationAxis.y,
          value: 50,
          label: 'Signal center',
          lineColor: _purple.withValues(alpha: 0.75),
          dashPattern: const [6, 4],
        ),
      ],
      _ScientificExample.distributions => [
        ThresholdAnnotation(
          id: 'mean-a',
          axis: AnnotationAxis.x,
          value: _meanA,
          label: 'μ A',
          lineColor: _purple,
          dashPattern: const [5, 3],
        ),
        ThresholdAnnotation(
          id: 'mean-b',
          axis: AnnotationAxis.x,
          value: _meanB,
          label: 'μ B',
          lineColor: _green,
          dashPattern: const [5, 3],
          labelPosition: AnnotationLabelPosition.topRight,
        ),
      ],
      _ScientificExample.regression => [
        RangeAnnotation(
          id: 'fit-window',
          startX: 25,
          endX: 75,
          label: 'Fit window',
          fillColor: _blue.withValues(alpha: 0.07),
          borderColor: _blue.withValues(alpha: 0.45),
        ),
      ],
      _ => const [],
    };
  }

  List<Widget> _buildOptions() {
    return [
      OptionSection(
        title: 'Scientific Model',
        icon: Icons.science_outlined,
        children: [
          EnumOption<_ScientificExample>(
            label: 'Example',
            value: _selectedExample,
            values: const [
              _ScientificExample.waveSynthesis,
              _ScientificExample.distributions,
              _ScientificExample.regression,
            ],
            labelBuilder: _exampleLabel,
            onChanged: _selectExample,
          ),
        ],
      ),
      ..._buildModelOptions(),
      OptionSection(
        title: 'Analysis Overlay',
        icon: Icons.analytics_outlined,
        children: [
          BoolOption(
            label: 'Show Reference Annotations',
            value: _showAnalysisOverlay,
            subtitle: _overlayDescription(_selectedExample),
            onChanged: (value) => setState(() => _showAnalysisOverlay = value),
          ),
        ],
      ),
      StandardChartOptions(
        controller: _optionsController,
        showLineStyleOption: false,
      ),
      OptionSection(
        title: 'What to Try',
        icon: Icons.fact_check_outlined,
        children: [InfoBox(message: _instruction(_selectedExample))],
      ),
    ];
  }

  List<Widget> _buildModelOptions() {
    return switch (_selectedExample) {
      _ScientificExample.waveSynthesis => [
        OptionSection(
          title: 'Wave Parameters',
          icon: Icons.waves,
          children: [
            SliderOption(
              label: 'Frequency',
              value: _frequency,
              min: 0.05,
              max: 0.35,
              divisions: 12,
              decimalPlaces: 2,
              suffix: 'Hz',
              onChanged: (value) => _update(() => _frequency = value),
            ),
            SliderOption(
              label: 'Amplitude',
              value: _amplitude,
              min: 10,
              max: 40,
              divisions: 12,
              decimalPlaces: 0,
              onChanged: (value) => _update(() => _amplitude = value),
            ),
            SliderOption(
              label: 'Phase',
              value: _phase,
              min: 0,
              max: math.pi * 2,
              divisions: 16,
              decimalPlaces: 2,
              suffix: 'rad',
              onChanged: (value) => _update(() => _phase = value),
            ),
            IntSliderOption(
              label: 'Harmonics',
              value: _harmonics,
              min: 1,
              max: 5,
              onChanged: (value) => _update(() => _harmonics = value),
            ),
          ],
        ),
      ],
      _ScientificExample.distributions => [
        OptionSection(
          title: 'Distribution Parameters',
          icon: Icons.area_chart,
          children: [
            SliderOption(
              label: 'Mean A',
              value: _meanA,
              min: 20,
              max: 55,
              divisions: 14,
              decimalPlaces: 0,
              onChanged: (value) => _update(() => _meanA = value),
            ),
            SliderOption(
              label: 'Spread A',
              value: _spreadA,
              min: 4,
              max: 20,
              divisions: 16,
              decimalPlaces: 0,
              onChanged: (value) => _update(() => _spreadA = value),
            ),
            SliderOption(
              label: 'Mean B',
              value: _meanB,
              min: 45,
              max: 80,
              divisions: 14,
              decimalPlaces: 0,
              onChanged: (value) => _update(() => _meanB = value),
            ),
            SliderOption(
              label: 'Spread B',
              value: _spreadB,
              min: 4,
              max: 20,
              divisions: 16,
              decimalPlaces: 0,
              onChanged: (value) => _update(() => _spreadB = value),
            ),
          ],
        ),
      ],
      _ScientificExample.regression => [
        OptionSection(
          title: 'Regression Parameters',
          icon: Icons.scatter_plot_outlined,
          children: [
            SliderOption(
              label: 'Slope',
              value: _regressionSlope,
              min: 0.1,
              max: 1,
              divisions: 18,
              decimalPlaces: 2,
              onChanged: (value) => _update(() => _regressionSlope = value),
            ),
            SliderOption(
              label: 'Noise',
              value: _regressionNoise,
              min: 0,
              max: 50,
              divisions: 20,
              decimalPlaces: 0,
              onChanged: (value) => _update(() => _regressionNoise = value),
            ),
          ],
        ),
      ],
      _ => const [],
    };
  }

  Widget _buildStatusPanel() {
    final overlayCount = _mainAnnotations.length;
    return StatusPanel(
      items: [
        StatusItem(label: 'Model', value: _exampleLabel(_selectedExample)),
        StatusItem(label: 'Samples', value: '${_primaryData.length}'),
        StatusItem(label: 'Series', value: '${_mainSeries.length}'),
        StatusItem(label: 'Overlays', value: '$overlayCount'),
      ],
    );
  }

  void _selectExample(_ScientificExample example) {
    if (_selectedExample == example) return;
    setState(() {
      _selectedExample = example;
      if (_isAnalytical(example)) _refreshAnalyticalData();
    });
  }

  void _update(VoidCallback mutation) {
    setState(() {
      mutation();
      _refreshAnalyticalData();
    });
  }

  void _refreshAnalyticalData() {
    switch (_selectedExample) {
      case _ScientificExample.waveSynthesis:
        _primaryData = _generateWave(
          _frequency,
          _amplitude,
          _phase,
          _harmonics,
        );
        _secondaryData = _generateReferenceWave();
        _fitData = const [];
      case _ScientificExample.distributions:
        _primaryData = _generateGaussian(_meanA, _spreadA);
        _secondaryData = _generateGaussian(_meanB, _spreadB);
        _fitData = const [];
      case _ScientificExample.regression:
        final regression = _generateRegression(
          _regressionSlope,
          _regressionNoise,
        );
        _primaryData = regression.$1;
        _secondaryData = const [];
        _fitData = regression.$2;
      case _:
        _primaryData = const [];
        _secondaryData = const [];
        _fitData = const [];
    }
  }

  List<ChartDataPoint> _generateWave(
    double frequency,
    double amplitude,
    double phase,
    int harmonics,
  ) {
    return List.generate(161, (index) {
      final x = index / 2;
      var y = 50.0;
      for (var harmonic = 1; harmonic <= harmonics; harmonic++) {
        y +=
            (amplitude / harmonic) * math.sin(frequency * harmonic * x + phase);
      }
      return ChartDataPoint(x: x, y: y);
    });
  }

  List<ChartDataPoint> _generateReferenceWave() {
    return List.generate(161, (index) {
      final x = index / 2;
      return ChartDataPoint(
        x: x,
        y: 50 + _amplitude * 0.55 * math.cos(_frequency * x),
      );
    });
  }

  List<ChartDataPoint> _generateGaussian(double mean, double spread) {
    return List.generate(121, (index) {
      final x = index * (100 / 120);
      final exponent = -math.pow(x - mean, 2) / (2 * spread * spread);
      return ChartDataPoint(x: x, y: 100 * math.exp(exponent));
    });
  }

  (List<ChartDataPoint>, List<ChartDataPoint>) _generateRegression(
    double slope,
    double noise,
  ) {
    final random = math.Random(42);
    final observations = List.generate(51, (index) {
      final x = index * 2.0;
      final error = (random.nextDouble() - 0.5) * noise;
      return ChartDataPoint(x: x, y: 20 + slope * x + error);
    });
    final fit = List.generate(51, (index) {
      final x = index * 2.0;
      return ChartDataPoint(x: x, y: 20 + slope * x);
    });
    return (observations, fit);
  }

  static bool _isAnalytical(_ScientificExample example) {
    return example.index <= _ScientificExample.regression.index;
  }

  static String _exampleLabel(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis => 'Wave synthesis',
      _ScientificExample.distributions => 'Distributions',
      _ScientificExample.regression => 'Regression',
      _ScientificExample.powerLactate => 'Power + lactate',
      _ScientificExample.lactateThreshold => 'Lactate threshold',
    };
  }

  static String _exampleDescription(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis => 'Harmonics · phase · frequency',
      _ScientificExample.distributions => 'Overlapping cohorts · μ · σ',
      _ScientificExample.regression => 'Scatter · fit · analysis window',
      _ScientificExample.powerLactate => 'Live 1 Hz + sparse samples',
      _ScientificExample.lactateThreshold => 'Chords · baseline · LT1',
    };
  }

  static String _exampleTitle(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis => 'Signal synthesis',
      _ScientificExample.distributions => 'Probability distributions',
      _ScientificExample.regression => 'Regression analysis',
      _ => _exampleLabel(example),
    };
  }

  static String _exampleSubtitle(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis =>
        'Build complex periodic signals from a fundamental wave and harmonics',
      _ScientificExample.distributions =>
        'Compare independently configurable Gaussian populations',
      _ScientificExample.regression =>
        'Explore noisy observations, a fitted model, and an analysis window',
      _ => '',
    };
  }

  static String _stageTitle(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis => 'Composite waveform',
      _ScientificExample.distributions => 'Cohort density comparison',
      _ScientificExample.regression => 'Observed response and linear fit',
      _ => '',
    };
  }

  String _stageSubtitle(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis =>
        'f=${_frequency.toStringAsFixed(2)} Hz · A=${_amplitude.toStringAsFixed(0)} · $_harmonics harmonics',
      _ScientificExample.distributions =>
        'A: μ=${_meanA.toStringAsFixed(0)}, σ=${_spreadA.toStringAsFixed(0)} · B: μ=${_meanB.toStringAsFixed(0)}, σ=${_spreadB.toStringAsFixed(0)}',
      _ScientificExample.regression =>
        'y = 20 + ${_regressionSlope.toStringAsFixed(2)}x · noise ±${(_regressionNoise / 2).toStringAsFixed(0)}',
      _ => '',
    };
  }

  static String _overlayDescription(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis => 'Mark the signal center reference',
      _ScientificExample.distributions => 'Mark both population means',
      _ScientificExample.regression => 'Highlight the central fitting window',
      _ => '',
    };
  }

  static String _instruction(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis =>
        'Increase harmonics to build a more complex waveform, then adjust phase and frequency. Zoom into a region to inspect the generated samples.',
      _ScientificExample.distributions =>
        'Move each mean and spread independently. The area overlap reveals how population separation and variance change together.',
      _ScientificExample.regression =>
        'Increase noise while keeping the slope fixed, then use the highlighted fitting window and tracking crosshair to inspect residual spread.',
      _ => '',
    };
  }
}

class _ScientificExampleCard extends StatelessWidget {
  const _ScientificExampleCard({
    super.key,
    required this.example,
    required this.selected,
    required this.onTap,
    required this.chart,
  });

  final _ScientificExample example;
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
      label: 'Select ${_ScientificPageState._exampleLabel(example)} example',
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ScientificPageState._exampleLabel(example),
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
                        key: ValueKey('selected-scientific-${example.name}'),
                        size: 16,
                        color: colors.primary,
                      ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  _ScientificPageState._exampleDescription(example),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(child: IgnorePointer(child: chart)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScientificGuide extends StatelessWidget {
  const _ScientificGuide({super.key, required this.example});

  final _ScientificExample example;

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
              Icon(_icon(example), size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _explanation(example),
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
                    _api(example),
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
                SizedBox(width: 455, child: api),
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

  static IconData _icon(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis => Icons.waves,
      _ScientificExample.distributions => Icons.area_chart,
      _ScientificExample.regression => Icons.scatter_plot_outlined,
      _ => Icons.science_outlined,
    };
  }

  static String _explanation(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis =>
        'Generate ordered samples from a configurable mathematical model and compare them with a reference signal.',
      _ScientificExample.distributions =>
        'Layer translucent areas to compare centers, spread, overlap, and relative population shape.',
      _ScientificExample.regression =>
        'Combine raw scatter observations, a fitted line, and a bounded analysis annotation in one coordinate system.',
      _ => '',
    };
  }

  static String _api(_ScientificExample example) {
    return switch (example) {
      _ScientificExample.waveSynthesis =>
        'LineChartSeries(points, interpolation) · XAxisConfig · tracking crosshair',
      _ScientificExample.distributions =>
        'AreaChartSeries(fillOpacity) · layered series · ThresholdAnnotation(μ)',
      _ScientificExample.regression =>
        'ScatterChartSeries + LineChartSeries · RangeAnnotation(fit window)',
      _ => '',
    };
  }
}
