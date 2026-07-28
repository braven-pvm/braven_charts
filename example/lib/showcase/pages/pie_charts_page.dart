// Copyright 2026 Braven Charts - Pie Charts Showcase
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

import '../data/radial_demo_data.dart';
import '../widgets/chart_options.dart';
import '../widgets/options_panel.dart';
import '../widgets/persistent_resizable_chart_panel.dart';
import '../widgets/radial_option_order.dart';
import '../widgets/radial_legend_value_card.dart';
import '../widgets/showcase_randomizer.dart';
import '../widgets/standard_options.dart';

/// Public showcase for categorical contribution charts.
class PieChartsPage extends StatefulWidget {
  const PieChartsPage({super.key});

  @override
  State<PieChartsPage> createState() => _PieChartsPageState();
}

class _PieChartsPageState extends State<PieChartsPage> {
  final ChartOptionsController _optionsController = ChartOptionsController();
  final BravenChartController _chartController = BravenChartController();
  final ChartWorkbenchController _workbenchController =
      ChartWorkbenchController();
  final math.Random _random = math.Random();
  late final ShowcaseRandomizerController<int> _showcaseRandomizer;

  _PieDataset _dataset = _PieDataset.revenue;
  _PieShowcasePreset _showcasePreset = _PieShowcasePreset.editorial;
  _PieDataset _authoredDataset = _PieDataset.revenue;
  _PieShowcasePreset _authoredPreset = _PieShowcasePreset.editorial;
  bool _playgroundActive = false;
  late Map<String, num> _values;
  late Map<String, num> _radiusValues;
  late int _categoryCount;
  bool _showLabels = true;
  _PieLabelLayout _labelLayout = _PieLabelLayout.split;
  PieDataLabelPosition _labelPosition = PieDataLabelPosition.outside;
  PieDataLabelContent _labelContent = PieDataLabelContent.categoryAndPercentage;
  PieDataLabelCollisionStrategy _collisionStrategy =
      PieDataLabelCollisionStrategy.shiftAndHide;
  double _minimumShare = 0.03;
  double _minimumSweepDegrees = 0;
  double _labelPadding = 6;
  double _insideLabelOffset = 0;
  double _outsideLabelOffset = 0;
  double _connectorLength = 14;
  double _connectorWidth = 1;
  bool _useCustomConnectorColor = false;
  Color _connectorColor = const Color(0xFF475569);
  double _startAngle = -90;
  bool _clockwise = true;
  double _radiusFactor = 0.86;
  double _minimumSliceRadiusFactor = 0.35;
  PieSliceRadiusScale _sliceRadiusScale = PieSliceRadiusScale.area;
  double _sliceGap = 4;
  double _borderWidth = 1;
  _PieBorderPreset _borderPreset = _PieBorderPreset.darkerSlice;
  Color _fixedBorderColor = const Color(0xFF334155);
  _PieGradientPreset _gradientPreset = _PieGradientPreset.radial;
  bool _useFixedGradientColors = false;
  Color _gradientStartColor = const Color(0xFF67E8F9);
  Color _gradientEndColor = const Color(0xFF1D4ED8);
  double _gradientStartLightnessShift = 0.2;
  double _gradientEndLightnessShift = -0.12;
  double _gradientAngleDegrees = -50;
  double _selectionExplodeOffset = 10;
  RadialSelectionEffect _selectionEffect = RadialSelectionEffect.explode;
  double _selectionLiftScale = 1.1;
  double _selectionLiftOffset = 6;
  double _selectionBackdropBlur = 1.25;
  double _cornerRadius = 8;
  PieCornerTreatment _cornerTreatment = PieCornerTreatment.roundAll;
  double _sliceOpacity = 1;
  bool _showShadow = false;
  bool _showSelectedGlow = true;
  _PieGlowColor _selectedGlowColor = _PieGlowColor.slice;
  double _selectedGlowBlur = 12;
  double _selectedGlowSpread = 2;
  double _selectedGlowOpacity = 0.48;
  double _selectedGlowOffsetY = 0;
  PieAnimationMode _animationMode = PieAnimationMode.grow;
  RadialDataTransitionMode _dataTransitionMode =
      RadialDataTransitionMode.automatic;
  bool _groupSmallSlices = false;
  double _groupingMinimumShare = 0.1;
  RadialSliceRadiusAggregation _radiusAggregation =
      RadialSliceRadiusAggregation.weightedMean;
  _PiePalette _palette = _PiePalette.theme;
  _PieCalloutPreset _calloutPreset = _PieCalloutPreset.none;
  _PieInsideShareStyle _insideShareStyle = _PieInsideShareStyle.darkBadge;
  _PieTooltipPreset _tooltipPreset = _PieTooltipPreset.theme;
  _PieLegendPreset _legendPreset = _PieLegendPreset.theme;
  _PieLegendContent _legendContent = _PieLegendContent.standard;
  bool _showLegend = true;
  LegendPosition _legendPosition = LegendPosition.bottomCenter;
  LegendOrientation _legendOrientation = LegendOrientation.horizontal;
  LegendMarkerShape _legendMarkerShape = LegendMarkerShape.circle;
  double _legendMarkerSize = 10;
  double _legendFontSize = 10;
  double _legendOpacity = 1;
  bool _showTooltips = true;
  TooltipPosition _tooltipPosition = TooltipPosition.auto;
  bool _tooltipFollowsCursor = false;
  double _tooltipOffset = 8;
  String? _selectedCategory;
  ChartArtifact? _capturedArtifact;
  HydratedChartConfiguration? _restoredConfiguration;
  String? _portableJson;
  String? _captureError;
  bool _isCapturing = false;
  bool _showRestoredCopy = false;

  static const _colorChoices = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFFF59E0B),
    Color(0xFF7C3AED),
    Color(0xFFEF4444),
    Color(0xFF334155),
    Color(0xFFF8FAFC),
  ];

  static const _simpleValues = <String, num>{
    'Subscriptions': 0.8404721477638243,
    'Services': 16.291963338129094,
    'Hardware': 8.058886416022458,
    'Training': 3.1698479487445628,
    'Other': 13.011006858125905,
    'Category 6': 9.51274790876786,
    'Category 7': 20.4515616038186,
    'Category 8': 18.874973095668356,
    'Category 9': 9.78854068295935,
  };

  @override
  void initState() {
    super.initState();
    _showcaseRandomizer = ShowcaseRandomizerController<int>(
      initialSeed: 307,
      generate: (seed) => seed,
      apply: _applyRandomSeed,
    );
    _values = Map<String, num>.of(_dataset.categoryValues);
    _radiusValues = Map<String, num>.of(
      _dataset.radiusValues ?? const <String, num>{},
    );
    _categoryCount = _values.length;
  }

  @override
  void dispose() {
    _showcaseRandomizer.dispose();
    _optionsController.dispose();
    _workbenchController.dispose();
    _chartController.dispose();
    super.dispose();
  }

  void _selectDataset(_PieDataset dataset, {bool authoredSelection = true}) {
    if (_dataset == dataset && (!authoredSelection || !_playgroundActive)) {
      return;
    }
    if (authoredSelection) {
      _showcaseRandomizer.pause();
      _showcaseRandomizer.clear();
    }
    setState(() {
      if (authoredSelection) {
        _playgroundActive = false;
        _authoredDataset = dataset;
      }
      _dataset = dataset;
      _values = Map<String, num>.of(dataset.categoryValues);
      _radiusValues = Map<String, num>.of(
        dataset.radiusValues ?? const <String, num>{},
      );
      _categoryCount = _values.length;
      _selectedCategory = null;
      _clearPortableState();
    });
    _chartController.clearPointSelection();
  }

  void _applyRandomSeed(int seed) {
    if (!mounted) return;
    final random = math.Random(seed);
    final count = radialDemoMinimumDataPoints + random.nextInt(8);
    final labels = List<String>.generate(
      count,
      (index) => 'Category ${index + 1}',
      growable: false,
    );
    setState(() {
      _values = randomRadialDistribution(
        labels: labels,
        total: 100,
        random: random,
      );
      // Variable radii are part of the dataset contract. Supplying an
      // undeclared second metric would make grouped slices ambiguous because
      // there is no radius aggregation policy to apply.
      _radiusValues = randomRadialMetric(
        labels: labels,
        minimum: 0.35,
        maximum: 1,
        random: random,
      );
      _categoryCount = count;
      _showLabels = random.nextBool();
      _labelPosition = PieDataLabelPosition
          .values[random.nextInt(PieDataLabelPosition.values.length)];
      _labelContent = PieDataLabelContent
          .values[random.nextInt(PieDataLabelContent.values.length)];
      _collisionStrategy = PieDataLabelCollisionStrategy
          .values[random.nextInt(PieDataLabelCollisionStrategy.values.length)];
      _minimumShare = random.nextDouble() * 0.08;
      _minimumSweepDegrees = random.nextDouble() * 14;
      _labelPadding = random.nextDouble() * 14;
      _labelLayout =
          _PieLabelLayout.values[random.nextInt(_PieLabelLayout.values.length)];
      _insideLabelOffset = -8 + random.nextDouble() * 16;
      _outsideLabelOffset = random.nextDouble() * 14;
      _connectorLength = 6 + random.nextDouble() * 22;
      _connectorWidth = 0.5 + random.nextDouble() * 2.5;
      _useCustomConnectorColor = random.nextBool();
      _connectorColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _startAngle = -180 + random.nextDouble() * 360;
      _clockwise = random.nextBool();
      _radiusFactor = 0.62 + random.nextDouble() * 0.34;
      _minimumSliceRadiusFactor = 0.2 + random.nextDouble() * 0.55;
      _sliceRadiusScale = PieSliceRadiusScale
          .values[random.nextInt(PieSliceRadiusScale.values.length)];
      _sliceGap = random.nextDouble() * 8;
      _borderWidth = random.nextDouble() * 3;
      _borderPreset = _PieBorderPreset
          .values[random.nextInt(_PieBorderPreset.values.length)];
      _fixedBorderColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _gradientPreset = _PieGradientPreset
          .values[random.nextInt(_PieGradientPreset.values.length)];
      _useFixedGradientColors = random.nextBool();
      _gradientStartColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _gradientEndColor = _colorChoices[random.nextInt(_colorChoices.length)];
      _gradientStartLightnessShift = -0.25 + random.nextDouble() * 0.5;
      _gradientEndLightnessShift = -0.25 + random.nextDouble() * 0.5;
      _gradientAngleDegrees = -180 + random.nextDouble() * 360;
      _selectionEffect = RadialSelectionEffect
          .values[random.nextInt(RadialSelectionEffect.values.length)];
      _selectionExplodeOffset = random.nextDouble() * 20;
      _selectionLiftScale = 1 + random.nextDouble() * 0.3;
      _selectionLiftOffset = random.nextDouble() * 14;
      _selectionBackdropBlur = random.nextDouble() * 3;
      _cornerRadius = random.nextDouble() * 16;
      _cornerTreatment = PieCornerTreatment
          .values[random.nextInt(PieCornerTreatment.values.length)];
      _sliceOpacity = 0.58 + random.nextDouble() * 0.42;
      _showShadow = random.nextBool();
      _showSelectedGlow = random.nextBool();
      _selectedGlowColor =
          _PieGlowColor.values[random.nextInt(_PieGlowColor.values.length)];
      _selectedGlowBlur = random.nextDouble() * 24;
      _selectedGlowSpread = random.nextDouble() * 8;
      _selectedGlowOpacity = 0.15 + random.nextDouble() * 0.8;
      _selectedGlowOffsetY = -8 + random.nextDouble() * 16;
      _animationMode = PieAnimationMode
          .values[random.nextInt(PieAnimationMode.values.length)];
      _dataTransitionMode = RadialDataTransitionMode
          .values[random.nextInt(RadialDataTransitionMode.values.length)];
      _palette = _PiePalette.values[random.nextInt(_PiePalette.values.length)];
      _calloutPreset = _PieCalloutPreset
          .values[random.nextInt(_PieCalloutPreset.values.length)];
      _insideShareStyle = _PieInsideShareStyle
          .values[random.nextInt(_PieInsideShareStyle.values.length)];
      _showLegend = random.nextBool();
      _legendPosition =
          LegendPosition.values[random.nextInt(LegendPosition.values.length)];
      _legendMarkerShape = LegendMarkerShape
          .values[random.nextInt(LegendMarkerShape.values.length)];
      _legendPreset = _PieLegendPreset
          .values[random.nextInt(_PieLegendPreset.values.length)];
      _legendContent = _PieLegendContent
          .values[random.nextInt(_PieLegendContent.values.length)];
      _legendOrientation = LegendOrientation
          .values[random.nextInt(LegendOrientation.values.length)];
      _legendMarkerSize = 6 + random.nextDouble() * 12;
      _legendFontSize = 8 + random.nextDouble() * 8;
      _legendOpacity = 0.35 + random.nextDouble() * 0.65;
      _showTooltips = random.nextBool();
      _tooltipPosition =
          TooltipPosition.values[random.nextInt(TooltipPosition.values.length)];
      _tooltipPreset = _PieTooltipPreset
          .values[random.nextInt(_PieTooltipPreset.values.length)];
      _tooltipFollowsCursor = random.nextBool();
      _tooltipOffset = 2 + random.nextDouble() * 18;
      _groupSmallSlices = random.nextBool();
      _groupingMinimumShare = 0.04 + random.nextDouble() * 0.12;
      _radiusAggregation = RadialSliceRadiusAggregation
          .values[random.nextInt(RadialSliceRadiusAggregation.values.length)];
      if (_groupSmallSlices) {
        _radiusValues = const <String, num>{};
      }
      _selectedCategory = null;
      _clearPortableState();
    });
    _chartController.clearPointSelection();
  }

  void _applyShowcasePreset(
    _PieShowcasePreset preset, {
    bool authoredSelection = true,
  }) {
    if (authoredSelection) {
      _showcaseRandomizer.pause();
      _showcaseRandomizer.clear();
    }
    _chartController.clearPointSelection();
    setState(() {
      if (authoredSelection) {
        _playgroundActive = false;
        _authoredPreset = preset;
      }
      _showcasePreset = preset;
      _selectedCategory = null;
      _clearPortableState();
      _animationMode = PieAnimationMode.grow;
      _showTooltips = true;
      _minimumSweepDegrees = 0;
      _labelPadding = 6;
      _insideLabelOffset = 0;
      _connectorLength = 14;
      _connectorWidth = 1;
      _useCustomConnectorColor = false;
      _connectorColor = const Color(0xFF475569);
      _fixedBorderColor = const Color(0xFF334155);
      _useFixedGradientColors = false;
      _gradientStartColor = const Color(0xFF67E8F9);
      _gradientEndColor = const Color(0xFF1D4ED8);
      _gradientStartLightnessShift = 0.2;
      _gradientEndLightnessShift = -0.12;
      _gradientAngleDegrees = -50;
      _legendMarkerShape = LegendMarkerShape.circle;
      _legendMarkerSize = 10;
      _legendFontSize = 10;
      _legendOpacity = 1;
      _tooltipPosition = TooltipPosition.auto;
      _tooltipFollowsCursor = false;
      _tooltipOffset = 8;
      switch (preset) {
        case _PieShowcasePreset.simple:
          _dataset = _PieDataset.revenue;
          _values = Map<String, num>.of(_simpleValues);
          _radiusValues = const <String, num>{};
          _categoryCount = _values.length;
          _showLabels = true;
          _labelLayout = _PieLabelLayout.split;
          _labelPosition = PieDataLabelPosition.outside;
          _labelContent = PieDataLabelContent.categoryAndPercentage;
          _collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide;
          _minimumShare = 0.06;
          _minimumSweepDegrees = 2;
          _labelPadding = 3;
          _outsideLabelOffset = 0;
          _connectorLength = 20;
          _connectorWidth = 1.5;
          _startAngle = -45;
          _clockwise = true;
          _radiusFactor = 0.92;
          _sliceGap = 2;
          _borderWidth = 1;
          _borderPreset = _PieBorderPreset.darkerSlice;
          _gradientPreset = _PieGradientPreset.radial;
          _gradientStartLightnessShift = 0.25;
          _gradientEndLightnessShift = -0.15;
          _selectionExplodeOffset = 8;
          _selectionEffect = RadialSelectionEffect.lift;
          _selectionLiftScale = 1.18;
          _selectionLiftOffset = 8;
          _selectionBackdropBlur = 0;
          _cornerRadius = 4;
          _cornerTreatment = PieCornerTreatment.outerOnly;
          _sliceOpacity = 0.8;
          _showShadow = true;
          _showSelectedGlow = true;
          _selectedGlowColor = _PieGlowColor.slice;
          _selectedGlowBlur = 10;
          _selectedGlowSpread = 2;
          _selectedGlowOpacity = 0.48;
          _selectedGlowOffsetY = 0;
          _palette = _PiePalette.sunset;
          _calloutPreset = _PieCalloutPreset.simpleValues;
          _insideShareStyle = _PieInsideShareStyle.autoContrast;
          _tooltipPreset = _PieTooltipPreset.theme;
          _legendPreset = _PieLegendPreset.compact;
          _legendContent = _PieLegendContent.standard;
          _showLegend = false;
          _legendPosition = LegendPosition.bottomCenter;
          _legendOrientation = LegendOrientation.horizontal;
          _animationMode = PieAnimationMode.sweep;
          _dataTransitionMode = RadialDataTransitionMode.automatic;
          _groupSmallSlices = false;
        case _PieShowcasePreset.editorial:
          _showLabels = true;
          _labelLayout = _PieLabelLayout.split;
          _labelPosition = PieDataLabelPosition.outside;
          _labelContent = PieDataLabelContent.categoryAndPercentage;
          _collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide;
          _minimumShare = 0.03;
          _outsideLabelOffset = 0;
          _startAngle = -90;
          _clockwise = true;
          _radiusFactor = 0.86;
          _sliceGap = 4;
          _borderWidth = 1;
          _borderPreset = _PieBorderPreset.darkerSlice;
          _gradientPreset = _PieGradientPreset.radial;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.explode;
          _selectionLiftScale = 1.08;
          _selectionLiftOffset = 6;
          _selectionBackdropBlur = 1.25;
          _cornerRadius = 8;
          _cornerTreatment = PieCornerTreatment.roundAll;
          _sliceOpacity = 1;
          _showShadow = false;
          _showSelectedGlow = true;
          _selectedGlowColor = _PieGlowColor.slice;
          _selectedGlowBlur = 12;
          _selectedGlowSpread = 2;
          _selectedGlowOpacity = 0.48;
          _selectedGlowOffsetY = 0;
          _palette = _PiePalette.theme;
          _calloutPreset = _PieCalloutPreset.none;
          _insideShareStyle = _PieInsideShareStyle.darkBadge;
          _tooltipPreset = _PieTooltipPreset.theme;
          _legendPreset = _PieLegendPreset.theme;
          _legendContent = _PieLegendContent.standard;
          _showLegend = true;
          _legendPosition = LegendPosition.bottomCenter;
          _legendOrientation = LegendOrientation.horizontal;
        case _PieShowcasePreset.compact:
          _showLabels = true;
          _labelLayout = _PieLabelLayout.single;
          _labelPosition = PieDataLabelPosition.inside;
          _labelContent = PieDataLabelContent.percentage;
          _collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide;
          _minimumShare = 0.05;
          _outsideLabelOffset = 0;
          _startAngle = -90;
          _clockwise = true;
          _radiusFactor = 0.9;
          _sliceGap = 2;
          _borderWidth = 0.5;
          _borderPreset = _PieBorderPreset.darkerSlice;
          _gradientPreset = _PieGradientPreset.solid;
          _selectionExplodeOffset = 8;
          _selectionEffect = RadialSelectionEffect.explode;
          _selectionLiftScale = 1.06;
          _selectionLiftOffset = 6;
          _selectionBackdropBlur = 0;
          _cornerRadius = 4;
          _cornerTreatment = PieCornerTreatment.outerOnly;
          _sliceOpacity = 1;
          _showShadow = false;
          _showSelectedGlow = false;
          _selectedGlowOffsetY = 0;
          _palette = _PiePalette.ocean;
          _calloutPreset = _PieCalloutPreset.none;
          _insideShareStyle = _PieInsideShareStyle.autoContrast;
          _tooltipPreset = _PieTooltipPreset.contrast;
          _legendPreset = _PieLegendPreset.compact;
          _legendContent = _PieLegendContent.valueCards;
          _showLegend = true;
          _legendPosition = LegendPosition.bottomCenter;
          _legendOrientation = LegendOrientation.horizontal;
        case _PieShowcasePreset.elevated:
          _showLabels = true;
          _labelLayout = _PieLabelLayout.split;
          _labelPosition = PieDataLabelPosition.outside;
          _labelContent = PieDataLabelContent.categoryAndPercentage;
          _collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide;
          _minimumShare = 0.03;
          _outsideLabelOffset = 12;
          _startAngle = -110;
          _clockwise = true;
          _radiusFactor = 0.8;
          _sliceGap = 7;
          _borderWidth = 1.5;
          _borderPreset = _PieBorderPreset.shiftedHue;
          _gradientPreset = _PieGradientPreset.radial;
          _selectionExplodeOffset = 0;
          _selectionEffect = RadialSelectionEffect.lift;
          _selectionLiftScale = 1.12;
          _selectionLiftOffset = 8;
          _selectionBackdropBlur = 1.5;
          _cornerRadius = 14;
          _cornerTreatment = PieCornerTreatment.circularCenter;
          _sliceOpacity = 0.94;
          _showShadow = true;
          _showSelectedGlow = true;
          _selectedGlowColor = _PieGlowColor.neutral;
          _selectedGlowBlur = 18;
          _selectedGlowSpread = 3;
          _selectedGlowOpacity = 0.38;
          _selectedGlowOffsetY = 7;
          _palette = _PiePalette.sunset;
          _calloutPreset = _PieCalloutPreset.surface;
          _insideShareStyle = _PieInsideShareStyle.lightBadge;
          _tooltipPreset = _PieTooltipPreset.elevated;
          _legendPreset = _PieLegendPreset.surface;
          _legendContent = _PieLegendContent.standard;
          _showLegend = true;
          _legendPosition = LegendPosition.bottomCenter;
          _legendOrientation = LegendOrientation.horizontal;
        case _PieShowcasePreset.highContrast:
          _showLabels = true;
          _labelLayout = _PieLabelLayout.split;
          _labelPosition = PieDataLabelPosition.outside;
          _labelContent = PieDataLabelContent.categoryAndPercentage;
          _collisionStrategy = PieDataLabelCollisionStrategy.shiftAndHide;
          _minimumShare = 0.04;
          _outsideLabelOffset = 0;
          _startAngle = -90;
          _clockwise = true;
          _radiusFactor = 0.86;
          _sliceGap = 4;
          _borderWidth = 2;
          _borderPreset = _PieBorderPreset.chartTheme;
          _gradientPreset = _PieGradientPreset.solid;
          _selectionExplodeOffset = 10;
          _selectionEffect = RadialSelectionEffect.explode;
          _selectionLiftScale = 1.08;
          _selectionLiftOffset = 6;
          _selectionBackdropBlur = 0;
          _cornerRadius = 4;
          _cornerTreatment = PieCornerTreatment.circularCenter;
          _sliceOpacity = 1;
          _showShadow = false;
          _showSelectedGlow = true;
          _selectedGlowColor = _PieGlowColor.neutral;
          _selectedGlowBlur = 10;
          _selectedGlowSpread = 1;
          _selectedGlowOpacity = 0.45;
          _selectedGlowOffsetY = 0;
          _palette = _PiePalette.monochrome;
          _calloutPreset = _PieCalloutPreset.highContrast;
          _insideShareStyle = _PieInsideShareStyle.lightBadge;
          _tooltipPreset = _PieTooltipPreset.contrast;
          _legendPreset = _PieLegendPreset.surface;
          _legendContent = _PieLegendContent.standard;
          _showLegend = true;
          _legendPosition = LegendPosition.bottomCenter;
          _legendOrientation = LegendOrientation.horizontal;
      }
    });
    _optionsController.theme = switch (preset) {
      _PieShowcasePreset.simple => ChartTheme.light,
      _PieShowcasePreset.editorial => ChartTheme.light,
      _PieShowcasePreset.compact => ChartTheme.corporateBlue,
      _PieShowcasePreset.elevated => ChartTheme.vibrant,
      _PieShowcasePreset.highContrast => ChartTheme.highContrast,
    };
  }

  void _regenerateValues() {
    _chartController.clearPointSelection();
    setState(() {
      _selectedCategory = null;
      _clearPortableState();
      _randomizeDataset();
    });
  }

  void _setCategoryCount(int count) {
    if (_categoryCount == count) return;
    _chartController.clearPointSelection();
    setState(() {
      _categoryCount = count;
      _selectedCategory = null;
      _clearPortableState();
      _randomizeDataset();
    });
  }

  void _randomizeDataset() {
    final labels = radialDemoLabels(
      preferredLabels: _dataset.categoryValues.keys,
      count: _categoryCount,
    );
    final total = _dataset.categoryValues.values.fold<double>(
      0,
      (sum, value) => sum + value.toDouble(),
    );
    _values = randomRadialDistribution(
      labels: labels,
      total: total,
      random: _random,
    );

    final authoredRadiusValues = _dataset.radiusValues;
    if (authoredRadiusValues == null) {
      _radiusValues = const <String, num>{};
      return;
    }
    final radiusRange = authoredRadiusValues.values
        .map((value) => value.toDouble())
        .toList(growable: false);
    _radiusValues = randomRadialMetric(
      labels: labels,
      minimum: radiusRange.reduce((a, b) => a < b ? a : b),
      maximum: radiusRange.reduce((a, b) => a > b ? a : b),
      random: _random,
    );
  }

  void _clearPortableState() {
    _capturedArtifact = null;
    _restoredConfiguration = null;
    _portableJson = null;
    _captureError = null;
    _showRestoredCopy = false;
  }

  Future<void> _capturePortableCopy() async {
    if (_isCapturing) return;
    setState(() {
      _isCapturing = true;
      _captureError = null;
    });
    final captured = await _chartController.extractArtifact(
      ChartArtifactExtractOptions(
        artifactId: 'pie-showcase-${DateTime.now().microsecondsSinceEpoch}',
        createdAt: DateTime.now().toUtc(),
        includePreview: true,
        documentOptions: ChartDocumentExtractOptions(
          documentId: 'pie-showcase-${_dataset.name}',
          radialFormatterDescriptors: {
            'pie-showcase-${_dataset.name}': _radialFormatterDescriptors,
          },
        ),
        previewOptions: const ChartPreviewOptions(pixelRatio: 0.75),
      ),
    );
    if (!mounted) return;
    if (captured case ChartArtifactFailure<ChartArtifact>()) {
      setState(() {
        _isCapturing = false;
        _captureError =
            '${captured.error.message} Try again after the chart finishes rendering.';
      });
      return;
    }
    final artifact = (captured as ChartArtifactSuccess<ChartArtifact>).value;
    final encoded = ChartArtifactJsonCodec.encode(artifact);
    if (encoded case ChartArtifactFailure<String>()) {
      setState(() {
        _isCapturing = false;
        _captureError = encoded.error.message;
      });
      return;
    }
    final json = (encoded as ChartArtifactSuccess<String>).value;
    final hydrated = ChartDocumentHydrator.hydrateJson(json);
    if (hydrated case ChartArtifactFailure<HydratedChartConfiguration>()) {
      setState(() {
        _isCapturing = false;
        _captureError = hydrated.error.message;
      });
      return;
    }
    setState(() {
      _isCapturing = false;
      _capturedArtifact = artifact;
      _portableJson = json;
      _restoredConfiguration =
          (hydrated as ChartArtifactSuccess<HydratedChartConfiguration>).value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChartPageLayout(
      title: 'Pie Charts',
      subtitle: 'Explain how categories contribute to one meaningful whole',
      actions: [
        OutlinedButton.icon(
          key: const ValueKey('pie-reset-example'),
          onPressed: _resetExample,
          icon: const Icon(Icons.restart_alt, size: 18),
          label: const Text('Reset example'),
        ),
      ],
      optionsChildren: _buildOptions(),
      playground: ChartPlaygroundConfig(
        active: _playgroundActive,
        optionsChildren: _buildPlaygroundOptions(),
        randomizer: _showcaseRandomizer,
      ),
      randomizerKeyPrefix: 'pie-randomizer',
      chart: _buildWorkspace(),
    );
  }

  List<Widget> _buildOptions() {
    return orderRadialOptionSections([
      RadialOptionEntry(
        RadialOptionSectionKind.dataLabels,
        OptionSection(
          title: 'Data labels',
          icon: Icons.label_outline,
          children: [
            BoolOption(
              key: const ValueKey('pie-show-labels'),
              label: 'Show labels',
              value: _showLabels,
              onChanged: (value) => setState(() => _showLabels = value),
              subtitle: 'Keep category meaning next to each contribution',
            ),
            if (_playgroundActive || _showLabels) ...[
              EnumOption<_PieLabelLayout>(
                key: const ValueKey('pie-label-layout'),
                label: 'Layout',
                value: _labelLayout,
                values: _PieLabelLayout.values,
                labelBuilder: (value) => switch (value) {
                  _PieLabelLayout.single => 'One label per slice',
                  _PieLabelLayout.split => 'Category outside + share inside',
                },
                onChanged: (value) => setState(() => _labelLayout = value),
              ),
              if (_playgroundActive ||
                  _labelLayout == _PieLabelLayout.single) ...[
                EnumOption<PieDataLabelPosition>(
                  key: const ValueKey('pie-label-position'),
                  label: 'Position',
                  value: _labelPosition,
                  values: PieDataLabelPosition.values,
                  labelBuilder: _labelPositionName,
                  onChanged: (value) => setState(() => _labelPosition = value),
                ),
                EnumOption<PieDataLabelContent>(
                  key: const ValueKey('pie-label-content'),
                  label: 'Content',
                  value: _labelContent,
                  values: PieDataLabelContent.values,
                  labelBuilder: _labelContentName,
                  onChanged: (value) => setState(() => _labelContent = value),
                ),
              ],
              EnumOption<_PieCalloutPreset>(
                key: const ValueKey('pie-primary-label-style'),
                label: _labelLayout == _PieLabelLayout.split
                    ? 'Outside callout style'
                    : 'Label style',
                value: _calloutPreset,
                values: _PieCalloutPreset.values,
                labelBuilder: _calloutPresetName,
                onChanged: (value) => setState(() => _calloutPreset = value),
              ),
              if (_playgroundActive || _labelLayout == _PieLabelLayout.split)
                EnumOption<_PieInsideShareStyle>(
                  key: const ValueKey('pie-inside-share-style'),
                  label: 'Inside share style',
                  subtitle: 'Styled independently from the outside category',
                  value: _insideShareStyle,
                  values: _PieInsideShareStyle.values,
                  labelBuilder: _insideShareStyleName,
                  onChanged: (value) =>
                      setState(() => _insideShareStyle = value),
                ),
              SliderOption(
                key: const ValueKey('pie-label-minimum-share'),
                label: 'Minimum share',
                value: _minimumShare * 100,
                min: 0,
                max: 20,
                divisions: 20,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _minimumShare = value / 100),
              ),
              SliderOption(
                key: const ValueKey('pie-label-minimum-sweep'),
                label: 'Minimum sweep',
                value: _minimumSweepDegrees,
                min: 0,
                max: 24,
                divisions: 12,
                suffix: '°',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _minimumSweepDegrees = value),
              ),
              SliderOption(
                key: const ValueKey('pie-label-padding'),
                label: 'Label padding',
                value: _labelPadding,
                min: 0,
                max: 16,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _labelPadding = value),
              ),
              if (_playgroundActive ||
                  _labelLayout == _PieLabelLayout.split ||
                  _labelPosition == PieDataLabelPosition.inside)
                SliderOption(
                  key: const ValueKey('pie-label-inside-offset'),
                  label: 'Inside radial offset',
                  value: _insideLabelOffset,
                  min: -32,
                  max: 32,
                  divisions: 32,
                  suffix: 'px',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _insideLabelOffset = value),
                ),
              if (_playgroundActive ||
                  _labelLayout == _PieLabelLayout.split ||
                  _labelPosition == PieDataLabelPosition.outside) ...[
                EnumOption<PieDataLabelCollisionStrategy>(
                  key: const ValueKey('pie-label-collision'),
                  label: 'Collision handling',
                  value: _collisionStrategy,
                  values: PieDataLabelCollisionStrategy.values,
                  labelBuilder: _collisionName,
                  onChanged: (value) =>
                      setState(() => _collisionStrategy = value),
                ),
                SliderOption(
                  key: const ValueKey('pie-label-outside-offset'),
                  label: 'Outside offset',
                  value: _outsideLabelOffset,
                  min: 0,
                  max: 64,
                  divisions: 16,
                  suffix: 'px',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _outsideLabelOffset = value),
                ),
                SliderOption(
                  key: const ValueKey('pie-connector-length'),
                  label: 'Connector length',
                  value: _connectorLength,
                  min: 0,
                  max: 32,
                  divisions: 16,
                  suffix: 'px',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _connectorLength = value),
                ),
                SliderOption(
                  key: const ValueKey('pie-connector-width'),
                  label: 'Connector width',
                  value: _connectorWidth,
                  min: 0.5,
                  max: 4,
                  divisions: 7,
                  suffix: 'px',
                  decimalPlaces: 1,
                  onChanged: (value) => setState(() => _connectorWidth = value),
                ),
                BoolOption(
                  key: const ValueKey('pie-custom-connector-color'),
                  label: 'Custom connector color',
                  value: _useCustomConnectorColor,
                  onChanged: (value) =>
                      setState(() => _useCustomConnectorColor = value),
                ),
                if (_playgroundActive || _useCustomConnectorColor)
                  ColorOption(
                    key: const ValueKey('pie-connector-color'),
                    label: 'Connector color',
                    value: _connectorColor,
                    colors: _colorChoices,
                    onChanged: (value) =>
                        setState(() => _connectorColor = value),
                  ),
              ],
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.geometry,
        OptionSection(
          title: 'Pie geometry',
          icon: Icons.pie_chart_outline,
          children: [
            SliderOption(
              label: 'Start angle',
              value: _startAngle,
              min: -180,
              max: 180,
              divisions: 24,
              suffix: '°',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _startAngle = value),
            ),
            BoolOption(
              label: 'Clockwise order',
              value: _clockwise,
              onChanged: (value) => setState(() => _clockwise = value),
            ),
            SliderOption(
              label: 'Radius',
              value: _radiusFactor * 100,
              min: 55,
              max: 100,
              divisions: 9,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _radiusFactor = value / 100),
            ),
            if (_playgroundActive || _dataset.hasVariableSliceRadius) ...[
              SliderOption(
                label: 'Smallest slice radius',
                value: _minimumSliceRadiusFactor * 100,
                min: 0,
                max: 100,
                divisions: 20,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _minimumSliceRadiusFactor = value / 100),
              ),
              EnumOption<PieSliceRadiusScale>(
                label: 'Radius scale',
                value: _sliceRadiusScale,
                values: PieSliceRadiusScale.values,
                labelBuilder: (value) => switch (value) {
                  PieSliceRadiusScale.area => 'Perceptual area',
                  PieSliceRadiusScale.linear => 'Linear radius',
                },
                onChanged: (value) => setState(() => _sliceRadiusScale = value),
              ),
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.sliceAppearance,
        OptionSection(
          title: 'Slice appearance',
          icon: Icons.palette_outlined,
          children: [
            EnumOption<_PieGradientPreset>(
              key: const ValueKey('pie-gradient'),
              label: 'Slice fill',
              value: _gradientPreset,
              values: _PieGradientPreset.values,
              labelBuilder: _gradientPresetName,
              onChanged: (value) => setState(() => _gradientPreset = value),
            ),
            if (_playgroundActive ||
                _gradientPreset != _PieGradientPreset.solid) ...[
              BoolOption(
                key: const ValueKey('pie-fixed-gradient-colors'),
                label: 'Use fixed gradient colors',
                value: _useFixedGradientColors,
                onChanged: (value) =>
                    setState(() => _useFixedGradientColors = value),
                subtitle: 'Off derives both stops from each category color',
              ),
              if (_playgroundActive || _useFixedGradientColors) ...[
                ColorOption(
                  key: const ValueKey('pie-gradient-start-color'),
                  label: 'Gradient start',
                  value: _gradientStartColor,
                  colors: _colorChoices,
                  onChanged: (value) =>
                      setState(() => _gradientStartColor = value),
                ),
                ColorOption(
                  key: const ValueKey('pie-gradient-end-color'),
                  label: 'Gradient end',
                  value: _gradientEndColor,
                  colors: _colorChoices,
                  onChanged: (value) =>
                      setState(() => _gradientEndColor = value),
                ),
              ] else ...[
                SliderOption(
                  key: const ValueKey('pie-gradient-start-shift'),
                  label: 'Start lightness',
                  value: _gradientStartLightnessShift * 100,
                  min: -40,
                  max: 40,
                  divisions: 16,
                  suffix: '%',
                  decimalPlaces: 0,
                  onChanged: (value) => setState(
                    () => _gradientStartLightnessShift = value / 100,
                  ),
                ),
                SliderOption(
                  key: const ValueKey('pie-gradient-end-shift'),
                  label: 'End lightness',
                  value: _gradientEndLightnessShift * 100,
                  min: -40,
                  max: 40,
                  divisions: 16,
                  suffix: '%',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _gradientEndLightnessShift = value / 100),
                ),
              ],
              if (_playgroundActive ||
                  _gradientPreset == _PieGradientPreset.linear)
                SliderOption(
                  key: const ValueKey('pie-gradient-angle'),
                  label: 'Gradient angle',
                  value: _gradientAngleDegrees,
                  min: -180,
                  max: 180,
                  divisions: 24,
                  suffix: '°',
                  decimalPlaces: 0,
                  onChanged: (value) =>
                      setState(() => _gradientAngleDegrees = value),
                ),
            ],
            SliderOption(
              key: const ValueKey('pie-opacity'),
              label: 'Transparency',
              value: _sliceOpacity * 100,
              min: 25,
              max: 100,
              divisions: 15,
              suffix: '%',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _sliceOpacity = value / 100),
            ),
            SliderOption(
              key: const ValueKey('pie-slice-gap'),
              label: 'Slice gap',
              value: _sliceGap,
              min: 0,
              max: 12,
              divisions: 12,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _sliceGap = value),
            ),
            SliderOption(
              key: const ValueKey('pie-border-width'),
              label: 'Border width',
              value: _borderWidth,
              min: 0,
              max: 4,
              divisions: 8,
              suffix: 'px',
              decimalPlaces: 1,
              onChanged: (value) => setState(() => _borderWidth = value),
            ),
            if (_playgroundActive || _borderWidth > 0) ...[
              EnumOption<_PieBorderPreset>(
                key: const ValueKey('pie-border-color'),
                label: 'Border color',
                value: _borderPreset,
                values: _PieBorderPreset.values,
                labelBuilder: _borderPresetName,
                onChanged: (value) => setState(() => _borderPreset = value),
              ),
              if (_playgroundActive ||
                  _borderPreset == _PieBorderPreset.fixedAccent)
                ColorOption(
                  key: const ValueKey('pie-fixed-border-color'),
                  label: 'Fixed border',
                  value: _fixedBorderColor,
                  colors: _colorChoices,
                  onChanged: (value) =>
                      setState(() => _fixedBorderColor = value),
                ),
            ],
            SliderOption(
              key: const ValueKey('pie-corner-radius'),
              label: 'Rounded corners',
              value: _cornerRadius,
              min: 0,
              max: 20,
              divisions: 10,
              suffix: 'px',
              decimalPlaces: 0,
              onChanged: (value) => setState(() => _cornerRadius = value),
            ),
            if (_playgroundActive || _cornerRadius > 0)
              EnumOption<PieCornerTreatment>(
                key: const ValueKey('pie-corner-treatment'),
                label: 'Corner treatment',
                value: _cornerTreatment,
                values: PieCornerTreatment.values,
                labelBuilder: _cornerTreatmentName,
                onChanged: (value) => setState(() => _cornerTreatment = value),
              ),
            BoolOption(
              key: const ValueKey('pie-slice-shadow'),
              label: 'Slice shadow',
              value: _showShadow,
              onChanged: (value) => setState(() => _showShadow = value),
            ),
            BoolOption(
              key: const ValueKey('pie-selected-glow'),
              label: 'Selected slice glow',
              value: _showSelectedGlow,
              onChanged: (value) => setState(() => _showSelectedGlow = value),
            ),
            if (_playgroundActive || _showSelectedGlow) ...[
              EnumOption<_PieGlowColor>(
                key: const ValueKey('pie-glow-color'),
                label: 'Glow color',
                value: _selectedGlowColor,
                values: _PieGlowColor.values,
                labelBuilder: _glowColorName,
                onChanged: (value) =>
                    setState(() => _selectedGlowColor = value),
              ),
              SliderOption(
                key: const ValueKey('pie-glow-blur'),
                label: 'Glow blur',
                value: _selectedGlowBlur,
                min: 0,
                max: 24,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _selectedGlowBlur = value),
              ),
              SliderOption(
                key: const ValueKey('pie-glow-spread'),
                label: 'Glow spread',
                value: _selectedGlowSpread,
                min: 0,
                max: 6,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) =>
                    setState(() => _selectedGlowSpread = value),
              ),
              SliderOption(
                key: const ValueKey('pie-glow-opacity'),
                label: 'Glow opacity',
                value: _selectedGlowOpacity * 100,
                min: 0,
                max: 100,
                divisions: 20,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _selectedGlowOpacity = value / 100),
              ),
              SliderOption(
                key: const ValueKey('pie-glow-offset'),
                label: 'Depth offset',
                value: _selectedGlowOffsetY,
                min: -12,
                max: 12,
                divisions: 24,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _selectedGlowOffsetY = value),
              ),
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.selection,
        OptionSection(
          title: 'Selection',
          icon: Icons.layers_outlined,
          children: [
            EnumOption<RadialSelectionEffect>(
              key: const ValueKey('pie-selection-effect'),
              label: 'Selection treatment',
              value: _selectionEffect,
              values: RadialSelectionEffect.values,
              labelBuilder: _selectionEffectName,
              subtitle: 'Pull a slice outward or lift it towards the viewer',
              onChanged: (value) => setState(() => _selectionEffect = value),
            ),
            if (_playgroundActive ||
                _selectionEffect == RadialSelectionEffect.explode)
              SliderOption(
                key: const ValueKey('pie-selection-explode-offset'),
                label: 'Selected slice offset',
                value: _selectionExplodeOffset,
                min: 0,
                max: 24,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _selectionExplodeOffset = value),
              )
            else ...[
              SliderOption(
                key: const ValueKey('pie-selection-lift-scale'),
                label: 'Lift scale',
                value: _selectionLiftScale * 100,
                min: 100,
                max: 125,
                divisions: 25,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _selectionLiftScale = value / 100),
              ),
              SliderOption(
                key: const ValueKey('pie-selection-lift-offset'),
                label: 'Lift offset',
                value: _selectionLiftOffset,
                min: 0,
                max: 24,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _selectionLiftOffset = value),
              ),
              SliderOption(
                key: const ValueKey('pie-selection-backdrop-blur'),
                label: 'Backdrop blur',
                value: _selectionBackdropBlur,
                min: 0,
                max: 8,
                divisions: 16,
                suffix: 'px',
                decimalPlaces: 1,
                onChanged: (value) =>
                    setState(() => _selectionBackdropBlur = value),
              ),
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.motion,
        OptionSection(
          title: 'Motion',
          icon: Icons.animation_outlined,
          children: [
            EnumOption<PieAnimationMode>(
              key: const ValueKey('pie-animation-mode'),
              label: 'Entrance',
              value: _animationMode,
              values: PieAnimationMode.values,
              labelBuilder: _animationModeName,
              onChanged: _setAnimationMode,
              subtitle:
                  'Grow, reveal around the pie, fade, or render instantly',
            ),
            EnumOption<RadialDataTransitionMode>(
              key: const ValueKey('pie-data-transition-mode'),
              label: 'Data updates',
              value: _dataTransitionMode,
              values: RadialDataTransitionMode.values,
              labelBuilder: (value) => switch (value) {
                RadialDataTransitionMode.none => 'Instant',
                RadialDataTransitionMode.automatic => 'Identity-aware',
              },
              onChanged: (value) => setState(() => _dataTransitionMode = value),
              subtitle: 'Morph stable categories; fade structural changes',
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('replay-pie-entrance'),
                onPressed: _animationMode == PieAnimationMode.none
                    ? null
                    : _chartController.replayRadialEntrance,
                icon: const Icon(Icons.replay_outlined, size: 18),
                label: const Text('Replay entrance'),
              ),
            ),
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.smallCategories,
        OptionSection(
          title: 'Small categories',
          icon: Icons.call_merge_outlined,
          children: [
            BoolOption(
              key: const ValueKey('pie-group-small-slices'),
              label: 'Group small slices',
              value: _groupSmallSlices,
              onChanged: _setGroupingEnabled,
              subtitle: _dataset.hasVariableSliceRadius
                  ? 'Group angle and aggregate radius by the policy below'
                  : 'Render one Other slice while preserving every source row',
            ),
            if (_playgroundActive || _groupSmallSlices) ...[
              SliderOption(
                key: const ValueKey('pie-grouping-threshold'),
                label: 'Share threshold',
                value: _groupingMinimumShare * 100,
                min: 1,
                max: 15,
                divisions: 14,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: _setGroupingThreshold,
              ),
              if (_playgroundActive || _dataset.hasVariableSliceRadius)
                EnumOption<RadialSliceRadiusAggregation>(
                  key: const ValueKey('pie-radius-aggregation'),
                  label: 'Radius aggregation',
                  value: _radiusAggregation,
                  values: RadialSliceRadiusAggregation.values,
                  labelBuilder: _radiusAggregationName,
                  onChanged: (value) => setState(() {
                    _radiusAggregation = value;
                    _clearPortableState();
                  }),
                  subtitle: 'Explicit policy for the grouped second metric',
                ),
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.legend,
        OptionSection(
          title: 'Legend',
          icon: Icons.view_list_outlined,
          children: [
            BoolOption(
              key: const ValueKey('pie-show-legend'),
              label: 'Show slice legend',
              value: _showLegend,
              onChanged: (value) => setState(() => _showLegend = value),
              subtitle: 'Legend items select slices; they do not hide data',
            ),
            if (_playgroundActive || _showLegend) ...[
              EnumOption<_PieLegendPreset>(
                key: const ValueKey('pie-legend-style'),
                label: 'Legend style',
                value: _legendPreset,
                values: _PieLegendPreset.values,
                labelBuilder: _legendPresetName,
                onChanged: (value) => setState(() => _legendPreset = value),
              ),
              EnumOption<_PieLegendContent>(
                key: const ValueKey('pie-legend-content'),
                label: 'Item content',
                value: _legendContent,
                values: _PieLegendContent.values,
                labelBuilder: _legendContentName,
                onChanged: (value) => setState(() => _legendContent = value),
              ),
              EnumOption<LegendPosition>(
                key: const ValueKey('pie-legend-position'),
                label: 'Position',
                value: _legendPosition,
                values: LegendPosition.values,
                labelBuilder: _legendPositionName,
                onChanged: (value) => setState(() => _legendPosition = value),
              ),
              EnumOption<LegendOrientation>(
                key: const ValueKey('pie-legend-orientation'),
                label: 'Orientation',
                value: _legendOrientation,
                values: LegendOrientation.values,
                labelBuilder: _legendOrientationName,
                onChanged: (value) =>
                    setState(() => _legendOrientation = value),
              ),
              EnumOption<LegendMarkerShape>(
                key: const ValueKey('pie-legend-marker-shape'),
                label: 'Marker shape',
                value: _legendMarkerShape,
                values: LegendMarkerShape.values,
                labelBuilder: _legendMarkerShapeName,
                onChanged: (value) =>
                    setState(() => _legendMarkerShape = value),
              ),
              SliderOption(
                key: const ValueKey('pie-legend-marker-size'),
                label: 'Marker size',
                value: _legendMarkerSize,
                min: 6,
                max: 20,
                divisions: 14,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendMarkerSize = value),
              ),
              SliderOption(
                key: const ValueKey('pie-legend-font-size'),
                label: 'Text size',
                value: _legendFontSize,
                min: 8,
                max: 16,
                divisions: 8,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _legendFontSize = value),
              ),
              SliderOption(
                key: const ValueKey('pie-legend-opacity'),
                label: 'Legend opacity',
                value: _legendOpacity * 100,
                min: 25,
                max: 100,
                divisions: 15,
                suffix: '%',
                decimalPlaces: 0,
                onChanged: (value) =>
                    setState(() => _legendOpacity = value / 100),
              ),
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.interaction,
        OptionSection(
          title: 'Interaction',
          icon: Icons.touch_app_outlined,
          children: [
            BoolOption(
              key: const ValueKey('pie-show-tooltips'),
              label: 'Show tooltips',
              value: _showTooltips,
              onChanged: (value) => setState(() => _showTooltips = value),
              subtitle:
                  'Hover, tap, or select from the legend or table; deselect to hide',
            ),
            if (_playgroundActive || _showTooltips) ...[
              EnumOption<_PieTooltipPreset>(
                key: const ValueKey('pie-tooltip-style'),
                label: 'Tooltip style',
                value: _tooltipPreset,
                values: _PieTooltipPreset.values,
                labelBuilder: _tooltipPresetName,
                onChanged: (value) => setState(() => _tooltipPreset = value),
              ),
              EnumOption<TooltipPosition>(
                key: const ValueKey('pie-tooltip-position'),
                label: 'Preferred position',
                value: _tooltipPosition,
                values: TooltipPosition.values,
                labelBuilder: _tooltipPositionName,
                onChanged: (value) => setState(() => _tooltipPosition = value),
              ),
              BoolOption(
                key: const ValueKey('pie-tooltip-follow-cursor'),
                label: 'Follow pointer',
                value: _tooltipFollowsCursor,
                onChanged: (value) =>
                    setState(() => _tooltipFollowsCursor = value),
              ),
              SliderOption(
                key: const ValueKey('pie-tooltip-offset'),
                label: 'Point offset',
                value: _tooltipOffset,
                min: 0,
                max: 24,
                divisions: 12,
                suffix: 'px',
                decimalPlaces: 0,
                onChanged: (value) => setState(() => _tooltipOffset = value),
              ),
            ],
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.chartTheme,
        StandardChartOptions(
          controller: _optionsController,
          sectionTitle: 'Chart theme',
          sectionIcon: Icons.contrast_outlined,
          themeOptionKey: const ValueKey('pie-theme'),
          showGridOption: false,
          showAxisOption: false,
          showMarkerOption: false,
          showScrollbarOptions: false,
          showLegendOption: false,
          showInteractionOptions: false,
          showLineStyleOption: false,
          additionalOptions: [
            EnumOption<_PiePalette>(
              key: const ValueKey('pie-palette'),
              label: 'Color palette',
              value: _palette,
              values: _PiePalette.values,
              labelBuilder: _paletteName,
              onChanged: (value) => setState(() => _palette = value),
            ),
          ],
        ),
      ),
      RadialOptionEntry(
        RadialOptionSectionKind.demoData,
        OptionSection(
          title: 'Demo data',
          icon: Icons.dataset_outlined,
          children: [
            IntSliderOption(
              key: const ValueKey('pie-data-point-count'),
              label: 'Data points',
              value: _categoryCount,
              min: radialDemoMinimumDataPoints,
              max: radialDemoMaximumDataPoints,
              suffix: 'points',
              onChanged: _setCategoryCount,
            ),
            Text(
              'Changing the count creates a new random distribution while '
              'preserving the ${_dataset.unit} total.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            ActionButton(
              label: 'Regenerate values',
              icon: Icons.casino_outlined,
              onPressed: _regenerateValues,
            ),
          ],
        ),
      ),
    ]);
  }

  void _setPlaygroundActive(bool active) {
    if (active == _playgroundActive) return;
    if (active) {
      _authoredDataset = _dataset;
      _authoredPreset = _showcasePreset;
      setState(() => _playgroundActive = true);
      _showcaseRandomizer.generateCurrent();
      return;
    }

    _showcaseRandomizer.pause();
    _showcaseRandomizer.clear();
    _applyShowcasePreset(_authoredPreset);
    _selectDataset(_authoredDataset);
  }

  List<Widget> _buildPlaygroundOptions() => _buildOptions();

  void _resetExample() {
    if (_playgroundActive) {
      _showcaseRandomizer.generateCurrent();
      return;
    }
    final dataset = _dataset;
    _applyShowcasePreset(_showcasePreset);
    _selectDataset(dataset);
  }

  Widget _buildWorkspace() {
    return ListenableBuilder(
      listenable: _optionsController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 680;
            return SingleChildScrollView(
              key: const ValueKey('pie-showcase-scroll'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExamplePicker(),
                  const SizedBox(height: 16),
                  PersistentResizableChartPanelWorkspace(
                    preferenceKey: showcaseChartPanelHeightKey(
                      compact: compact,
                    ),
                    minimumPanelHeight: compact ? 520 : 360,
                    maximumPanelHeight: compact ? 1400 : 1200,
                    initialPanelHeight: compact ? 680 : 660,
                    wrapExplicitContentInScrollView: false,
                    panel: ChartCard(
                      key: const ValueKey('pie-showcase-card'),
                      title: _dataset.title,
                      subtitle: _chartSummary(),
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildDataSurface(compact: compact)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPortableWorkflow(compact: compact),
                  const SizedBox(height: 32),
                  _buildFeatureGuide(),
                  const SizedBox(height: 32),
                  _buildCodeRecipe(),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDataSurface({required bool compact}) {
    return BravenChartWorkbench(
      chartController: _chartController,
      workbenchController: _workbenchController,
      initialDisplayMode: ChartDisplayMode.chart,
      availableDisplayModes: const {
        ChartDisplayMode.chart,
        ChartDisplayMode.data,
        ChartDisplayMode.split,
        ChartDisplayMode.source,
      },
      sourceOptions: const ChartDartSourceOptions(variableName: 'pieChart'),
      splitBreakpoint: 1,
      splitAxis: compact ? Axis.vertical : Axis.horizontal,
      splitGap: 8,
      minimumChartPaneExtent: compact ? 240 : 360,
      minimumTablePaneExtent: compact ? 240 : 420,
      maximumAutoTablePaneExtent: 620,
      autoFitTablePane: true,
      isSplitResizable: true,
      documentOptions: ChartDocumentExtractOptions(
        includeViewState: true,
        radialFormatterDescriptors: {
          'pie-showcase-${_dataset.name}': _radialFormatterDescriptors,
        },
      ),
      tableRefreshPolicy: ChartTableRefreshPolicy.onDocumentRevision,
      onTableRowFocused: _focusTablePoints,
      onTableRowFocusCleared: _chartController.clearPointFocus,
      onTableRowHoverChanged: (points) => points == null
          ? _chartController.clearPointFocus()
          : _focusTablePoints(points),
      onTableRowActivated: _selectTablePoints,
      chartBuilder: (context, controller) => _buildLiveChart(controller),
    );
  }

  Widget _buildLiveChart(BravenChartController controller) {
    final theme = _buildPieTheme();
    return BravenChartPlus(
      key: const ValueKey('pie-showcase-chart'),
      title: _playgroundActive ? 'Pie playground' : _dataset.chartTitle,
      subtitle: _playgroundActive
          ? '${_values.length} generated categories · seed ${_showcaseRandomizer.appliedSeed ?? _showcaseRandomizer.seed}'
          : _dataset.chartSubtitle,
      bravenChartController: controller,
      showLegend: _showLegend,
      radialLegendItemBuilder: _legendContent == _PieLegendContent.valueCards
          ? _buildValueCardLegendItem
          : null,
      theme: theme,
      interactionConfig: InteractionConfig(
        crosshair: const CrosshairConfig(enabled: false),
        tooltip: TooltipConfig(
          enabled: _showTooltips,
          triggerMode: TooltipTriggerMode.both,
          preferredPosition: _tooltipPosition,
          followCursor: _tooltipFollowsCursor,
          offsetFromPoint: _tooltipOffset,
        ),
        enableZoom: false,
        enablePan: false,
        enableSelection: true,
        showFocusBorder: false,
      ),
      onPointTap: _handlePointActivation,
      series: [_buildSeries(theme)],
    );
  }

  Widget _buildValueCardLegendItem(
    BuildContext context,
    RadialLegendItemData item,
  ) => RadialLegendValueCard(
    key: ValueKey('pie-custom-legend-item-${item.visibleIndex}'),
    item: item,
  );

  void _focusTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ??
        _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    _chartController.focusPoints(points, revision: revision);
  }

  void _selectTablePoints(List<ChartPointRef> points) {
    final revision =
        _chartController.effectiveDocumentRevision.value ??
        _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    final selectedPoints = _chartController.selectedPointRefs;
    final targetPoints = _expandedVisibleSliceRefs(points);
    if (targetPoints.isNotEmpty &&
        selectedPoints.length == targetPoints.length &&
        selectedPoints.containsAll(targetPoints)) {
      _chartController.clearPointSelection();
      setState(() => _selectedCategory = null);
      return;
    }
    final result = _chartController.selectPoints(points, revision: revision);
    if (result case ChartArtifactSuccess<void>()) {
      final selected = points.firstOrNull;
      final category = selected == null
          ? null
          : _buildSeries(
              _buildPieTheme(),
            ).visibleSliceForSourcePointIndex(selected.pointIndex)?.point.label;
      setState(() => _selectedCategory = category);
    }
  }

  Set<ChartPointRef> _expandedVisibleSliceRefs(List<ChartPointRef> points) {
    final series = _buildSeries(_buildPieTheme());
    final expanded = <ChartPointRef>{};
    for (final ref in points) {
      final slice = series.visibleSliceForSourcePointIndex(ref.pointIndex);
      if (slice == null) {
        expanded.add(ref);
        continue;
      }
      expanded.addAll([
        for (final pointIndex in slice.sourcePointIndices)
          ChartPointRef(seriesId: ref.seriesId, pointIndex: pointIndex),
      ]);
    }
    return expanded;
  }

  void _setGroupingEnabled(bool value) {
    _chartController.clearPointSelection();
    setState(() {
      _groupSmallSlices = value;
      _selectedCategory = null;
      _clearPortableState();
    });
  }

  void _setGroupingThreshold(double value) {
    _chartController.clearPointSelection();
    setState(() {
      _groupingMinimumShare = value / 100;
      _selectedCategory = null;
      _clearPortableState();
    });
  }

  Widget _buildPortableWorkflow({required bool compact}) {
    final colors = Theme.of(context).colorScheme;
    final artifact = _capturedArtifact;
    final previewBytes = artifact?.preview?.bytes;
    final captureButton = ElevatedButton.icon(
      key: const ValueKey('capture-pie-artifact'),
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: _isCapturing ? null : _capturePortableCopy,
      icon: _isCapturing
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.camera_alt_outlined, size: 18),
      label: Text(_isCapturing ? 'Capturing copy…' : 'Capture portable copy'),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPortableHeading(),
                const SizedBox(height: 16),
                captureButton,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPortableHeading()),
                const SizedBox(width: 24),
                captureButton,
              ],
            ),
          if (_captureError != null) ...[
            const SizedBox(height: 16),
            _buildCaptureMessage(
              icon: Icons.error_outline,
              message: _captureError!,
              color: colors.errorContainer,
              foreground: colors.onErrorContainer,
            ),
          ],
          if (artifact == null && _captureError == null) ...[
            const SizedBox(height: 16),
            _buildCaptureMessage(
              icon: Icons.info_outline,
              message:
                  'Capture stores the Pie series, current configuration, view state, and a revision-bound PNG preview.',
              color: colors.primaryContainer.withValues(alpha: 0.36),
              foreground: colors.onPrimaryContainer,
            ),
          ],
          if (artifact != null) ...[
            const SizedBox(height: 24),
            _buildCapturedArtifactBody(
              artifact: artifact,
              previewBytes: previewBytes,
              compact: compact,
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: const ValueKey('inspect-pie-artifact-json'),
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 8),
                leading: const Icon(Icons.data_object_outlined),
                title: const Text('Inspect canonical JSON'),
                subtitle: Text(
                  '${_portableJson?.length ?? 0} UTF-16 characters',
                ),
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 220),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _portableJson ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_showRestoredCopy && _restoredConfiguration != null) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.restore, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restored from canonical JSON into a fresh chart runtime',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              key: const ValueKey('restored-pie-artifact'),
              height: compact ? 440 : 420,
              child: _restoredConfiguration!.build(
                key: ValueKey('restored-${artifact?.artifactId}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapturedArtifactBody({
    required ChartArtifact artifact,
    required Uint8List? previewBytes,
    required bool compact,
  }) {
    final colors = Theme.of(context).colorScheme;
    final preview = AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: previewBytes == null
            ? const Center(child: Text('Preview was not available'))
            : Image.memory(
                previewBytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                semanticLabel: 'Captured pie chart preview',
              ),
      ),
    );
    final details = _buildPortableDetails(artifact);
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [preview, const SizedBox(height: 16), details],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: preview),
        const SizedBox(width: 24),
        Expanded(flex: 3, child: details),
      ],
    );
  }

  Widget _buildPortableHeading() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Capture, transport, and restore',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Create a schema-v1 artifact, inspect its real JSON and PNG preview, then hydrate an independent chart from that saved copy.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPortableDetails(ChartArtifact artifact) {
    final colors = Theme.of(context).colorScheme;
    final preview = artifact.preview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text('Schema ${artifact.schemaVersion}')),
            const Chip(label: Text('series.pie')),
            const Chip(label: Text('series.pie.style.v2')),
            const Chip(label: Text('series.pie.corner-treatment.v1')),
            if (artifact.document.requiredCapabilities.contains(
              'series.pie.variable-radius.v1',
            ))
              const Chip(label: Text('series.pie.variable-radius.v1')),
            Chip(
              label: Text(
                preview == null
                    ? 'No PNG preview'
                    : '${preview.widthPixels.toInt()} × ${preview.heightPixels.toInt()} PNG',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${artifact.document.series.single.data.pointCount} transported categories · '
          '${artifact.document.requiredCapabilities.length} required capabilities · '
          '${_portableJson?.length ?? 0} JSON characters',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('restore-pie-artifact'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => setState(() => _showRestoredCopy = true),
          icon: const Icon(Icons.restore, size: 18),
          label: const Text('Restore captured chart'),
        ),
      ],
    );
  }

  Widget _buildCaptureMessage({
    required IconData icon,
    required String message,
    required Color color,
    required Color foreground,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }

  void _handlePointActivation(ChartDataPoint point, String seriesId) {
    final pointIndex = point.x.round();
    final isSelected = _chartController.selectedPointRefs.contains(
      ChartPointRef(seriesId: seriesId, pointIndex: pointIndex),
    );
    setState(() => _selectedCategory = isSelected ? point.label : null);
  }

  String get _interactionGuideText {
    if (_groupSmallSlices && _selectedCategory == 'Other') {
      final grouped = _buildSeries(
        _buildPieTheme(),
      ).visibleSlices.where((slice) => slice.isGrouped).firstOrNull;
      if (grouped != null) {
        return 'One visible Other slice now selects all ${grouped.sourcePointIndices.length} original source rows through the controller.';
      }
    }
    if (_groupSmallSlices) {
      return 'Small categories render as one Other slice while the data table keeps every original row. Select Other or any grouped row to see the shared selection.';
    }
    return 'Hover for details. Select a slice, legend item, or table row to explode it. With chart focus, use arrow keys to move, Enter to select, and Escape to clear.';
  }

  Widget _buildExamplePicker() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      container: true,
      label: 'Choose a Pie chart example',
      child: Card(
        key: const ValueKey('pie-example-picker'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 400;
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Choose a Pie chart example',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (compact)
                        Tooltip(
                          message: 'Regenerate values',
                          child: ElevatedButton(
                            key: const ValueKey('regenerate-pie-values'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.square(40),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _regenerateValues,
                            child: const Icon(Icons.casino_outlined, size: 18),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          key: const ValueKey('regenerate-pie-values'),
                          onPressed: _regenerateValues,
                          icon: const Icon(Icons.casino_outlined, size: 17),
                          label: const Text('Regenerate'),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                key: const ValueKey('pie-presentation-selector'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final preset in _PieShowcasePreset.values)
                    ShowcaseExampleChoiceChip(
                      key: ValueKey('pie-preset-${preset.name}'),
                      label: _presentationName(preset),
                      icon: _presentationIcon(preset),
                      selected: !_playgroundActive && preset == _showcasePreset,
                      onSelected: () => _applyShowcasePreset(preset),
                    ),
                  PlaygroundChoiceChip(
                    key: const ValueKey('pie-playground'),
                    selected: _playgroundActive,
                    onSelected: () => _setPlaygroundActive(true),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _playgroundActive
                    ? 'Generated data and every compatible Pie property. Seeded playback is available in Options.'
                    : _presentationDescription(_showcasePreset),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose a category story',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                key: const ValueKey('pie-dataset-selector'),
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final dataset in _PieDataset.values)
                    ShowcaseExampleChoiceChip(
                      key: ValueKey('pie-dataset-${dataset.name}'),
                      label: dataset.title,
                      icon: _datasetIcon(dataset),
                      selected: !_playgroundActive && dataset == _dataset,
                      onSelected: () => _selectDataset(dataset),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _dataset.selectorDescription,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final heading = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _selectedCategory == null
                              ? 'Try slice interaction'
                              : 'Selected: $_selectedCategory',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_selectedCategory != null)
                        IconButton(
                          tooltip: 'Clear slice selection',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _chartController.clearPointSelection();
                            setState(() => _selectedCategory = null);
                          },
                          icon: const Icon(Icons.close, size: 18),
                        ),
                    ],
                  );
                  final detail = Text(
                    _interactionGuideText,
                    maxLines: constraints.maxWidth < 520 ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  );
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [heading, const SizedBox(height: 4), detail],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(width: 8),
                      Expanded(child: detail),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _datasetIcon(_PieDataset dataset) => switch (dataset) {
    _PieDataset.revenue => Icons.pie_chart_outline,
    _PieDataset.effort => Icons.workspaces_outline,
    _PieDataset.support => Icons.support_agent_outlined,
    _PieDataset.countries => Icons.public_outlined,
  };

  Widget _buildFeatureGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built for readable category comparisons',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'The renderer keeps category order stable and resolves labels inside the available space.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 32) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.donut_large_outlined,
                  title: 'One whole, optional second metric',
                  description:
                      'Angle shows contribution. Add one radius value per category to compare a second non-negative metric without losing the whole.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.label_outline,
                  title: 'Labels that make room',
                  description:
                      'Choose inside or outside labels, control their content, and shift or hide labels when space is tight.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.contrast_outlined,
                  title: 'Theme-aware rendering',
                  description:
                      'Palettes, opacity, corner treatments, shadow, selected glow, callouts, tooltips, and legends resolve through the active chart theme.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.keyboard_alt_outlined,
                  title: 'Selection for every input',
                  description:
                      'Hover, tap, legend controls, arrow keys, and assistive actions resolve the same stable source slice.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.table_rows_outlined,
                  title: 'Source-preserving grouping',
                  description:
                      'Combine small contributions into one visible Other slice while tables, exports, controller selection, and artifacts retain every source row.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.animation_outlined,
                  title: 'Replayable entrance motion',
                  description:
                      'Grow from the center, reveal around the pie, fade in, or render instantly. Replay the configured entrance without remounting the chart.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.widgets_outlined,
                  title: 'Host-built legend items',
                  description:
                      'Return any Flutter widget for each Pie or Donut category while the chart retains selection, semantics, and responsive legend layout.',
                ),
                _FeatureCard(
                  width: cardWidth,
                  icon: Icons.inventory_2_outlined,
                  title: 'Portable by default',
                  description:
                      'Capture canonical schema-v1 JSON and a revision-bound PNG, then hydrate a fresh chart runtime from that saved document.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCodeRecipe() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final explanation = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Style a pie through the chart theme',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Insertion order becomes slice order. Keep geometry with the series and reusable presentation defaults in PieChartTheme, LegendStyle, and InteractionTheme.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          );
          final code = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SelectableText(
              "final series = PieChartSeries.fromMap(\n"
              "  id: 'revenue',\n"
              "  unit: 'USD',\n"
              "  values: {\n"
              "    'Subscriptions': 42,\n"
              "    'Services': 31,\n"
              "    'Hardware': 17,\n"
              "  },\n"
              "  // Optional: encode a second metric through radius.\n"
              "  radiusValues: {\n"
              "    'Subscriptions': 120,\n"
              "    'Services': 90,\n"
              "    'Hardware': 65,\n"
              "  },\n"
              "  sliceRadiusConfig: PieSliceRadiusConfig(\n"
              "    label: 'Market size',\n"
              "    unit: 'k users',\n"
              "  ),\n"
              "  sliceGroupingConfig: RadialSliceGroupingConfig(\n"
              "    minimumShare: 0.08,\n"
              "    label: 'Other',\n"
              "  ),\n"
              "  pieStyle: PieChartStyle(\n"
              "    gradient: PieGradientStyle(\n"
              "      type: PieGradientType.radial,\n"
              "    ),\n"
              "  ),\n"
              "  selectionStyle: RadialSelectionStyle(\n"
              "    effect: RadialSelectionEffect.lift,\n"
              "    liftScale: 1.12,\n"
              "    liftOffset: 8,\n"
              "    backdropBlur: 1.5,\n"
              "  ),\n"
              "  dataLabels: PieDataLabelConfig(\n"
              "    position: PieDataLabelPosition.outside,\n"
              "    insideOffset: 0, // Signed radial adjustment\n"
              "    outsideOffset: 0, // Tight to the pie\n"
              "  ),\n"
              ");\n\n"
              "final theme = ChartTheme.light.copyWith(\n"
              "  legendStyle: ChartTheme.light.legendStyle.copyWith(\n"
              "    position: LegendPosition.centerRight,\n"
              "    orientation: LegendOrientation.vertical,\n"
              "  ),\n"
              "  pieChartTheme: const PieChartTheme(\n"
              "    animationMode: PieAnimationMode.sweep,\n"
              "    cornerRadius: 10,\n"
              "    cornerTreatment: PieCornerTreatment.circularCenter,\n"
              "    selectedElevation: PieElevationStyle(\n"
              "      blurRadius: 12,\n"
              "      spreadRadius: 2,\n"
              "      opacity: 0.5,\n"
              "    ),\n"
              "  ),\n"
              ");\n\n"
              "BravenChartPlus(\n"
              "  series: [series],\n"
              "  theme: theme,\n"
              "  showLegend: true,\n"
              "  onPointTap: (point, seriesId) {\n"
              "    // Respond to the selected source slice.\n"
              "  },\n"
              ");",
              style: TextStyle(fontFamily: 'monospace', fontSize: 12.5),
            ),
          );

          if (constraints.maxWidth < 760) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [explanation, const SizedBox(height: 24), code],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: explanation),
              const SizedBox(width: 32),
              Expanded(flex: 2, child: code),
            ],
          );
        },
      ),
    );
  }

  PieChartSeries _buildSeries(ChartTheme theme) {
    final borderColor = _borderPreset == _PieBorderPreset.fixedAccent
        ? _fixedBorderColor
        : null;
    final borderColorMode = switch (_borderPreset) {
      _PieBorderPreset.chartTheme => PieBorderColorMode.chartTheme,
      _PieBorderPreset.darkerSlice ||
      _PieBorderPreset.shiftedHue => PieBorderColorMode.slice,
      _PieBorderPreset.fixedAccent => null,
    };
    final borderHueShift = _borderPreset == _PieBorderPreset.shiftedHue
        ? 28.0
        : 0.0;
    final borderLightnessShift = switch (_borderPreset) {
      _PieBorderPreset.darkerSlice => -0.18,
      _PieBorderPreset.shiftedHue => -0.08,
      _ => 0.0,
    };
    return PieChartSeries.fromMap(
      id: 'pie-showcase-${_dataset.name}',
      name: _dataset.title,
      unit: _dataset.unit,
      values: _values,
      radiusValues: _radiusValues,
      sliceRadiusConfig: _dataset.hasVariableSliceRadius
          ? PieSliceRadiusConfig(
              minimumFactor: _minimumSliceRadiusFactor,
              scale: _sliceRadiusScale,
              label: _dataset.radiusLabel!,
              unit: _dataset.radiusUnit,
              formatter: (value) =>
                  '${value.toStringAsFixed(0)} ${_dataset.radiusUnit}',
            )
          : null,
      sliceGroupingConfig: _groupSmallSlices
          ? RadialSliceGroupingConfig(
              minimumShare: _groupingMinimumShare,
              label: 'Other',
              radiusAggregation: _dataset.hasVariableSliceRadius
                  ? _radiusAggregation
                  : null,
            )
          : null,
      pieStyle: PieChartStyle(
        startAngleDegrees: _startAngle,
        clockwise: _clockwise,
        radiusFactor: _radiusFactor,
        sliceGap: _sliceGap,
        borderWidth: _borderWidth,
        borderColor: borderColor,
        borderColorMode: borderColorMode,
        borderHueShiftDegrees: borderHueShift,
        borderLightnessShift: borderLightnessShift,
        gradient: switch (_gradientPreset) {
          _PieGradientPreset.solid => null,
          _PieGradientPreset.linear => PieGradientStyle(
            type: PieGradientType.linear,
            startColor: _useFixedGradientColors ? _gradientStartColor : null,
            endColor: _useFixedGradientColors ? _gradientEndColor : null,
            startLightnessShift: _gradientStartLightnessShift,
            endLightnessShift: _gradientEndLightnessShift,
            angleDegrees: _gradientAngleDegrees,
          ),
          _PieGradientPreset.radial => PieGradientStyle(
            type: PieGradientType.radial,
            startColor: _useFixedGradientColors ? _gradientStartColor : null,
            endColor: _useFixedGradientColors ? _gradientEndColor : null,
            startLightnessShift: _gradientStartLightnessShift,
            endLightnessShift: _gradientEndLightnessShift,
          ),
        },
        selectionExplodeOffset: _selectionExplodeOffset,
        cornerTreatment: _cornerTreatment,
        dataTransitionMode: _dataTransitionMode,
      ),
      selectionStyle: RadialSelectionStyle(
        effect: _selectionEffect,
        liftScale: _selectionLiftScale,
        liftOffset: _selectionLiftOffset,
        backdropBlur: _selectionBackdropBlur,
      ),
      dataLabels: PieDataLabelConfig(
        isVisible: _showLabels,
        position: _labelLayout == _PieLabelLayout.split
            ? PieDataLabelPosition.outside
            : _labelPosition,
        content: _labelLayout == _PieLabelLayout.split
            ? PieDataLabelContent.category
            : _labelContent,
        secondaryContent: _labelLayout == _PieLabelLayout.split
            ? PieDataLabelContent.percentage
            : null,
        secondaryPosition: PieDataLabelPosition.inside,
        secondaryCalloutStyle: _labelLayout == _PieLabelLayout.split
            ? _insidePercentageStyle
            : null,
        minimumShare: _minimumShare,
        minimumSweepDegrees: _minimumSweepDegrees,
        padding: _labelPadding,
        insideOffset: _insideLabelOffset,
        outsideOffset: _outsideLabelOffset,
        connectorLength: _connectorLength,
        connectorWidth: _connectorWidth,
        connectorColor: _useCustomConnectorColor ? _connectorColor : null,
        collisionStrategy: _collisionStrategy,
        calloutStyle: _calloutStyle(theme),
        valueFormatter: (value) =>
            '${value.toStringAsFixed(1)} ${_dataset.unit}',
        percentageFormatter: (share) => '${(share * 100).toStringAsFixed(0)}%',
      ),
    );
  }

  ChartTheme _buildPieTheme() {
    final base = _optionsController.theme ?? ChartTheme.light;
    final palette = _paletteColors;
    final seriesTheme = palette == null
        ? base.seriesTheme
        : base.seriesTheme.copyWith(colors: palette);
    final calloutStyle = _calloutStyle(base);
    final tooltipStyle = _tooltipStyle(base);
    final legendBase = base.legendStyle.copyWith(
      position: _legendPosition,
      orientation: _legendOrientation,
      markerShape: _legendMarkerShape,
      markerSize: _legendMarkerSize,
      textStyle: base.legendStyle.textStyle.copyWith(fontSize: _legendFontSize),
      opacity: _legendOpacity,
      markerLabelSpacing: 8,
    );
    final legendStyle = switch (_legendPreset) {
      _PieLegendPreset.theme => legendBase,
      _PieLegendPreset.compact => legendBase.copyWith(
        markerLabelSpacing: 5,
        itemSpacing: 3,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      ),
      _PieLegendPreset.surface => legendBase.copyWith(
        textStyle: legendBase.textStyle.copyWith(fontWeight: FontWeight.w600),
        backgroundColor: base.backgroundColor.withValues(alpha: 0.94),
        borderColor: base.axisStyle.lineColor.withValues(alpha: 0.42),
        borderWidth: 1,
        borderRadius: BorderRadius.circular(12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemSpacing: 8,
      ),
    };
    final selectedGlowColor = switch (_selectedGlowColor) {
      _PieGlowColor.slice => null,
      _PieGlowColor.accent => seriesTheme.colorAt(0),
      _PieGlowColor.neutral =>
        base.axisStyle.labelStyle.color ?? const Color(0xFF1A1A1A),
    };
    return base.copyWith(
      seriesTheme: seriesTheme,
      legendStyle: legendStyle,
      interactionTheme: base.interactionTheme.copyWith(
        tooltipStyle: tooltipStyle,
      ),
      pieChartTheme: PieChartTheme(
        opacity: _sliceOpacity,
        cornerRadius: _cornerRadius,
        cornerTreatment: _cornerTreatment,
        shadow: _showShadow
            ? const PieElevationStyle(
                color: Color(0x4D1A1A1A),
                blurRadius: 8,
                offset: Offset(0, 4),
                opacity: 0.7,
              )
            : const PieElevationStyle(),
        selectedElevation: _showSelectedGlow
            ? PieElevationStyle(
                color: selectedGlowColor,
                blurRadius: _selectedGlowBlur,
                spreadRadius: _selectedGlowSpread,
                offset: Offset(0, _selectedGlowOffsetY),
                opacity: _selectedGlowOpacity,
              )
            : const PieElevationStyle(),
        calloutStyle: calloutStyle,
        animationMode: _animationMode,
      ),
    );
  }

  String _animationModeName(PieAnimationMode mode) => switch (mode) {
    PieAnimationMode.none => 'No animation',
    PieAnimationMode.grow => 'Grow',
    PieAnimationMode.sweep => 'Sweep',
    PieAnimationMode.fade => 'Fade',
  };

  String _selectionEffectName(RadialSelectionEffect effect) => switch (effect) {
    RadialSelectionEffect.explode => 'Pull outward',
    RadialSelectionEffect.lift => 'Lift towards viewer',
  };

  void _setAnimationMode(PieAnimationMode mode) {
    setState(() => _animationMode = mode);
  }

  String _radiusAggregationName(RadialSliceRadiusAggregation value) =>
      switch (value) {
        RadialSliceRadiusAggregation.sum => 'Sum',
        RadialSliceRadiusAggregation.mean => 'Mean',
        RadialSliceRadiusAggregation.weightedMean => 'Weighted mean',
        RadialSliceRadiusAggregation.minimum => 'Minimum',
        RadialSliceRadiusAggregation.maximum => 'Maximum',
      };

  RadialFormatterDocumentDescriptors get _radialFormatterDescriptors =>
      RadialFormatterDocumentDescriptors(
        value: ChartFormatterDescriptor(
          id: 'braven.number.fixed',
          arguments: {
            'decimals': JsonNumberValue(1),
            'suffix': JsonStringValue(' ${_dataset.unit}'),
          },
        ).toDocument(),
        percentage: ChartFormatterDescriptor(
          id: 'braven.number.percent',
          arguments: {'decimals': JsonNumberValue(0)},
        ).toDocument(),
        radius: _dataset.hasVariableSliceRadius
            ? ChartFormatterDescriptor(
                id: 'braven.number.fixed',
                arguments: {
                  'decimals': JsonNumberValue(0),
                  'suffix': JsonStringValue(' ${_dataset.radiusUnit}'),
                },
              ).toDocument()
            : null,
      );

  List<Color>? get _paletteColors => switch (_palette) {
    _PiePalette.theme => null,
    _PiePalette.ocean => const [
      Color(0xFF006D77),
      Color(0xFF0A9396),
      Color(0xFF48CAE4),
      Color(0xFF90E0EF),
      Color(0xFF023E8A),
      Color(0xFF0077B6),
    ],
    _PiePalette.sunset => const [
      Color(0xFFE63946),
      Color(0xFFF77F00),
      Color(0xFFFCBF49),
      Color(0xFFD62828),
      Color(0xFF9D4EDD),
      Color(0xFF5A189A),
    ],
    _PiePalette.earth => const [
      Color(0xFF386641),
      Color(0xFF6A994E),
      Color(0xFFA7C957),
      Color(0xFFBC6C25),
      Color(0xFFDDA15E),
      Color(0xFF606C38),
    ],
    _PiePalette.monochrome => const [
      Color(0xFF1F2937),
      Color(0xFF374151),
      Color(0xFF4B5563),
      Color(0xFF6B7280),
      Color(0xFF9CA3AF),
      Color(0xFFD1D5DB),
    ],
  };

  LabelStyle? _calloutStyle(ChartTheme theme) => switch (_calloutPreset) {
    _PieCalloutPreset.none => null,
    _PieCalloutPreset.surface => LabelStyle(
      textStyle: theme.axisStyle.labelStyle.copyWith(
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: theme.backgroundColor.withValues(alpha: 0.94),
      borderColor: theme.axisStyle.lineColor.withValues(alpha: 0.55),
      borderWidth: 1,
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shadowColor: const Color(0x261A1A1A),
      shadowBlurRadius: 6,
    ),
    _PieCalloutPreset.accent => LabelStyle(
      textStyle: theme.axisStyle.labelStyle.copyWith(
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: theme.seriesTheme.colorAt(0).withValues(alpha: 0.12),
      borderColor: theme.seriesTheme.colorAt(0).withValues(alpha: 0.72),
      borderWidth: 1.5,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shadowColor: theme.seriesTheme.colorAt(0).withValues(alpha: 0.18),
      shadowBlurRadius: 8,
    ),
    _PieCalloutPreset.highContrast => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFF1A1A1A),
      borderWidth: 2,
      borderRadius: 4,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    _PieCalloutPreset.simpleValues => LabelStyle(
      textStyle: TextStyle(
        color:
            (_labelLayout == _PieLabelLayout.split ||
                _labelPosition == PieDataLabelPosition.outside)
            ? (theme.axisStyle.labelStyle.color ?? const Color(0xFF374151))
            : const Color(0xFFFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: const Color(0x00000000),
      borderColor: const Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: const EdgeInsets.all(2),
    ),
  };

  LabelStyle get _insidePercentageStyle => switch (_insideShareStyle) {
    _PieInsideShareStyle.autoContrast => const LabelStyle(
      textStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      backgroundColor: Color(0x00000000),
      borderColor: Color(0x00000000),
      borderWidth: 0,
      borderRadius: 0,
      padding: EdgeInsets.all(2),
    ),
    _PieInsideShareStyle.darkBadge => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0xD91F2937),
      borderColor: Color(0x99FFFFFF),
      borderWidth: 1,
      borderRadius: 4,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      shadowColor: Color(0x26000000),
      shadowBlurRadius: 3,
    ),
    _PieInsideShareStyle.lightBadge => const LabelStyle(
      textStyle: TextStyle(
        color: Color(0xFF1A1A1A),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Color(0xF2FFFFFF),
      borderColor: Color(0x661A1A1A),
      borderWidth: 1,
      borderRadius: 4,
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      shadowColor: Color(0x26000000),
      shadowBlurRadius: 3,
    ),
  };

  LabelStyle _tooltipStyle(ChartTheme theme) => switch (_tooltipPreset) {
    _PieTooltipPreset.theme => theme.interactionTheme.tooltipStyle,
    _PieTooltipPreset.elevated => theme.interactionTheme.tooltipStyle.copyWith(
      borderRadius: 10,
      borderWidth: 1,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shadowColor: const Color(0x401A1A1A),
      shadowBlurRadius: 12,
    ),
    _PieTooltipPreset.contrast => LabelStyle(
      textStyle: TextStyle(
        color: theme.backgroundColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor:
          theme.axisStyle.labelStyle.color ?? const Color(0xFF1A1A1A),
      borderColor: theme.backgroundColor.withValues(alpha: 0.72),
      borderWidth: 1,
      borderRadius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shadowColor: const Color(0x4D1A1A1A),
      shadowBlurRadius: 8,
    ),
  };

  String _chartSummary() {
    if (_dataset.hasVariableSliceRadius) {
      return '${_values.length} countries · angle: ${_dataset.unit} · '
          'radius: ${_dataset.radiusLabel} (${_dataset.radiusUnit})';
    }
    final total = _values.values.fold<double>(
      0,
      (sum, value) => sum + value.toDouble(),
    );
    final formattedTotal = total.toStringAsFixed(total % 1 == 0 ? 0 : 1);
    final labelSummary = _showLabels
        ? '${_labelPositionName(_labelPosition).toLowerCase()} labels'
        : 'labels hidden';
    return '${_values.length} categories · $formattedTotal ${_dataset.unit} total · $labelSummary';
  }

  String _labelPositionName(PieDataLabelPosition value) => switch (value) {
    PieDataLabelPosition.inside => 'Inside slices',
    PieDataLabelPosition.outside => 'Outside with connectors',
  };

  String _labelContentName(PieDataLabelContent value) => switch (value) {
    PieDataLabelContent.category => 'Category',
    PieDataLabelContent.value => 'Value',
    PieDataLabelContent.percentage => 'Percentage',
    PieDataLabelContent.categoryAndValue => 'Category + value',
    PieDataLabelContent.categoryAndPercentage => 'Category + percentage',
    PieDataLabelContent.valueAndPercentage => 'Value + percentage',
    PieDataLabelContent.categoryValueAndPercentage =>
      'Category + value + percentage',
  };

  String _collisionName(PieDataLabelCollisionStrategy value) => switch (value) {
    PieDataLabelCollisionStrategy.none => 'Keep original positions',
    PieDataLabelCollisionStrategy.shift => 'Shift to avoid overlap',
    PieDataLabelCollisionStrategy.shiftAndHide => 'Shift, then hide if needed',
  };

  String _paletteName(_PiePalette value) => switch (value) {
    _PiePalette.theme => 'Chart theme',
    _PiePalette.ocean => 'Ocean',
    _PiePalette.sunset => 'Sunset',
    _PiePalette.earth => 'Earth',
    _PiePalette.monochrome => 'Monochrome',
  };

  String _presentationName(_PieShowcasePreset value) => switch (value) {
    _PieShowcasePreset.simple => 'Simple values',
    _PieShowcasePreset.editorial => 'Editorial labels',
    _PieShowcasePreset.compact => 'Compact dashboard',
    _PieShowcasePreset.elevated => 'Elevated radial',
    _PieShowcasePreset.highContrast => 'High contrast',
  };

  String _presentationDescription(_PieShowcasePreset value) => switch (value) {
    _PieShowcasePreset.simple =>
      'Radial gradients, dual labels, lifted selection, and no legend',
    _PieShowcasePreset.editorial =>
      'Readable outside callouts with restrained spacing and borders',
    _PieShowcasePreset.compact =>
      'Inside percentages, compact legend, and space-efficient geometry',
    _PieShowcasePreset.elevated =>
      'Rounded translucent slices, shadow, glow, and raised surfaces',
    _PieShowcasePreset.highContrast =>
      'Opaque outside labels, monochrome slices, and strong borders',
  };

  IconData _presentationIcon(_PieShowcasePreset value) => switch (value) {
    _PieShowcasePreset.simple => Icons.pie_chart_outline,
    _PieShowcasePreset.editorial => Icons.article_outlined,
    _PieShowcasePreset.compact => Icons.dashboard_outlined,
    _PieShowcasePreset.elevated => Icons.auto_awesome_outlined,
    _PieShowcasePreset.highContrast => Icons.contrast_outlined,
  };

  String _calloutPresetName(_PieCalloutPreset value) => switch (value) {
    _PieCalloutPreset.none => 'Plain text',
    _PieCalloutPreset.surface => 'Raised surface',
    _PieCalloutPreset.accent => 'Palette accent',
    _PieCalloutPreset.highContrast => 'High contrast',
    _PieCalloutPreset.simpleValues => 'Simple values',
  };

  String _insideShareStyleName(_PieInsideShareStyle value) => switch (value) {
    _PieInsideShareStyle.autoContrast => 'Auto-contrast text',
    _PieInsideShareStyle.darkBadge => 'Dark badge',
    _PieInsideShareStyle.lightBadge => 'Light badge',
  };

  String _tooltipPresetName(_PieTooltipPreset value) => switch (value) {
    _PieTooltipPreset.theme => 'Chart theme',
    _PieTooltipPreset.elevated => 'Elevated surface',
    _PieTooltipPreset.contrast => 'High contrast',
  };

  String _borderPresetName(_PieBorderPreset value) => switch (value) {
    _PieBorderPreset.chartTheme => 'Chart theme outline',
    _PieBorderPreset.darkerSlice => 'Darker slice shade',
    _PieBorderPreset.shiftedHue => 'Shifted slice hue',
    _PieBorderPreset.fixedAccent => 'Fixed accent color',
  };

  String _gradientPresetName(_PieGradientPreset value) => switch (value) {
    _PieGradientPreset.solid => 'Solid color',
    _PieGradientPreset.linear => 'Linear light',
    _PieGradientPreset.radial => 'Radial light',
  };

  String _cornerTreatmentName(PieCornerTreatment value) => switch (value) {
    PieCornerTreatment.roundAll => 'All corners (legacy)',
    PieCornerTreatment.outerOnly => 'Outer corners only',
    PieCornerTreatment.circularCenter => 'Circular center',
  };

  String _glowColorName(_PieGlowColor value) => switch (value) {
    _PieGlowColor.slice => 'Selected slice color',
    _PieGlowColor.accent => 'Palette accent',
    _PieGlowColor.neutral => 'Theme foreground',
  };

  String _legendPresetName(_PieLegendPreset value) => switch (value) {
    _PieLegendPreset.theme => 'Chart theme',
    _PieLegendPreset.compact => 'Compact',
    _PieLegendPreset.surface => 'Raised surface',
  };

  String _legendContentName(_PieLegendContent value) => switch (value) {
    _PieLegendContent.standard => 'Standard details',
    _PieLegendContent.valueCards => 'Custom value cards',
  };

  String _legendPositionName(LegendPosition value) => switch (value) {
    LegendPosition.topLeft => 'Top left',
    LegendPosition.topCenter => 'Top center',
    LegendPosition.topRight => 'Top right',
    LegendPosition.centerLeft => 'Center left',
    LegendPosition.center => 'Overlay center',
    LegendPosition.centerRight => 'Center right',
    LegendPosition.bottomLeft => 'Bottom left',
    LegendPosition.bottomCenter => 'Bottom center',
    LegendPosition.bottomRight => 'Bottom right',
  };

  String _legendOrientationName(LegendOrientation value) => switch (value) {
    LegendOrientation.horizontal => 'Horizontal',
    LegendOrientation.vertical => 'Vertical',
  };

  String _legendMarkerShapeName(LegendMarkerShape value) => switch (value) {
    LegendMarkerShape.circle => 'Circle',
    LegendMarkerShape.square => 'Square',
    LegendMarkerShape.line => 'Line',
    LegendMarkerShape.diamond => 'Diamond',
  };

  String _tooltipPositionName(TooltipPosition value) => switch (value) {
    TooltipPosition.auto => 'Automatic',
    TooltipPosition.top => 'Above',
    TooltipPosition.bottom => 'Below',
    TooltipPosition.left => 'Left',
    TooltipPosition.right => 'Right',
  };
}

enum _PieShowcasePreset { simple, editorial, compact, elevated, highContrast }

enum _PieLabelLayout { single, split }

enum _PiePalette { theme, ocean, sunset, earth, monochrome }

enum _PieCalloutPreset { none, surface, accent, highContrast, simpleValues }

enum _PieInsideShareStyle { autoContrast, darkBadge, lightBadge }

enum _PieTooltipPreset { theme, elevated, contrast }

enum _PieBorderPreset { chartTheme, darkerSlice, shiftedHue, fixedAccent }

enum _PieGradientPreset { solid, linear, radial }

enum _PieGlowColor { slice, accent, neutral }

enum _PieLegendPreset { theme, compact, surface }

enum _PieLegendContent { standard, valueCards }

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.description,
  });

  final double width;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PieDataset {
  revenue(
    title: 'Revenue contribution',
    chartTitle: 'Revenue by product',
    chartSubtitle: 'Contribution to total recurring revenue',
    selectorDescription: '5 product categories · balanced shares',
    unit: 'USD',
    categoryValues: {
      'Subscriptions': 42,
      'Services': 28,
      'Hardware': 16,
      'Training': 9,
      'Other': 5,
    },
  ),
  effort(
    title: 'Project effort',
    chartTitle: 'Delivery effort by phase',
    chartSubtitle: 'Hours allocated across the current release',
    selectorDescription: '6 delivery phases · one dominant category',
    unit: 'hours',
    categoryValues: {
      'Build': 46,
      'Discovery': 18,
      'Design': 14,
      'Testing': 12,
      'Launch': 7,
      'Support': 3,
    },
  ),
  support(
    title: 'Support volume',
    chartTitle: 'Requests by topic',
    chartSubtitle: 'Dense labels exercise collision-aware placement',
    selectorDescription: '8 request topics · dense label layout',
    unit: 'tickets',
    categoryValues: {
      'Accounts': 24,
      'Billing': 19,
      'Integrations': 15,
      'Reporting': 12,
      'Mobile': 10,
      'Security': 8,
      'Exports': 7,
      'Other': 5,
    },
  ),
  countries(
    title: 'Density and area',
    chartTitle: 'Countries by density and area',
    chartSubtitle:
        'Angle compares population density · radius compares total area',
    selectorDescription: '7 countries · two independent metrics',
    unit: 'people/km²',
    categoryValues: {
      'Germany': 233,
      'Spain': 96,
      'France': 119,
      'Poland': 120,
      'Czech Republic': 139,
      'Italy': 195,
      'Switzerland': 219,
    },
    radiusValues: {
      'Germany': 357022,
      'Spain': 505990,
      'France': 551695,
      'Poland': 312696,
      'Czech Republic': 78871,
      'Italy': 301340,
      'Switzerland': 41285,
    },
    radiusLabel: 'Total area',
    radiusUnit: 'km²',
  );

  const _PieDataset({
    required this.title,
    required this.chartTitle,
    required this.chartSubtitle,
    required this.selectorDescription,
    required this.unit,
    required this.categoryValues,
    this.radiusValues,
    this.radiusLabel,
    this.radiusUnit,
  });

  final String title;
  final String chartTitle;
  final String chartSubtitle;
  final String selectorDescription;
  final String unit;
  final Map<String, num> categoryValues;
  final Map<String, num>? radiusValues;
  final String? radiusLabel;
  final String? radiusUnit;

  bool get hasVariableSliceRadius => radiusValues != null;
}
