// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;

/// Polar showcase stories that can be generated from a stable seed.
enum PolarShowcasePresentationKind {
  standard,
  rose,
  partial,
  layered,
  grouped,
  stacked,
  references,
  intervals,
}

/// Theme families available to the seeded Polar showcase generator.
enum PolarShowcaseThemeKind {
  light,
  dark,
  corporate,
  vibrant,
  minimal,
  highContrast,
  colorblind,
}

/// Category palettes available to the seeded Polar showcase generator.
enum PolarShowcasePaletteKind { theme, ocean, sunset, earth, monochrome }

/// Line patterns shared by generated axes and reference rings.
enum PolarShowcaseLinePatternKind { solid, dashed, dotted }

/// A complete, valid Polar showcase configuration derived from one seed.
///
/// The generator deliberately varies product-level properties rather than
/// producing independent random numbers. Presentation-specific invariants are
/// retained: Rose charts are area-correct, stacks contain signed contributors,
/// references align targets by category, and intervals always bracket values.
class PolarShowcaseRandomization {
  const PolarShowcaseRandomization({
    required this.seed,
    required this.presentation,
    required this.theme,
    required this.palette,
    required this.primaryValues,
    required this.secondaryValues,
    required this.tertiaryValues,
    required this.startAngle,
    required this.sweepAngle,
    required this.clockwise,
    required this.innerRadius,
    required this.outerRadius,
    required this.innerPadding,
    required this.outerPadding,
    required this.compositionMode,
    required this.groupInnerPadding,
    required this.scaleMode,
    required this.tickCount,
    required this.showAngularLabels,
    required this.showAngularGrid,
    required this.maximumAngularLabels,
    required this.maximumAngularGridLines,
    required this.showRadialLabels,
    required this.showRadialGrid,
    required this.showValues,
    required this.maximumDataLabels,
    required this.cornerRadius,
    required this.cornerRadiusMode,
    required this.opacity,
    required this.showTargets,
    required this.showThreshold,
    required this.thresholdValue,
    required this.targetMarkerWidth,
    required this.targetMarkerLength,
    required this.targetOpacity,
    required this.showIntervals,
    required this.intervalDisplay,
    required this.intervalWidth,
    required this.intervalCapLength,
    required this.intervalBandLength,
    required this.intervalOpacity,
    required this.canvasColor,
    required this.axisLineColor,
    required this.axisLabelColor,
    required this.axisLineWidth,
    required this.axisLabelSize,
    required this.gridLineColor,
    required this.gridLineWidth,
    required this.gridLinePattern,
    required this.columnBorderColor,
    required this.columnBorderWidth,
    required this.targetColor,
    required this.thresholdColor,
    required this.thresholdWidth,
    required this.thresholdPattern,
    required this.intervalColor,
    required this.showTooltip,
    required this.tooltipTrigger,
    required this.tooltipPosition,
    required this.tooltipOffset,
    required this.tooltipBackgroundColor,
    required this.tooltipTextColor,
    required this.tooltipBorderColor,
    required this.tooltipBorderWidth,
    required this.tooltipCornerRadius,
    required this.selectionEffect,
    required this.selectionScale,
    required this.selectionOffset,
    required this.selectionBackdropBlur,
    required this.selectionColor,
  });

  final int seed;
  final PolarShowcasePresentationKind presentation;
  final PolarShowcaseThemeKind theme;
  final PolarShowcasePaletteKind palette;
  final Map<String, num> primaryValues;
  final Map<String, num> secondaryValues;
  final Map<String, num> tertiaryValues;

  int get categoryCount => primaryValues.length;

  final double startAngle;
  final double sweepAngle;
  final bool clockwise;
  final double innerRadius;
  final double outerRadius;
  final double innerPadding;
  final double outerPadding;
  final PolarColumnCompositionMode compositionMode;
  final double groupInnerPadding;
  final PolarRadialScaleMode scaleMode;
  final int tickCount;
  final bool showAngularLabels;
  final bool showAngularGrid;
  final int maximumAngularLabels;
  final int maximumAngularGridLines;
  final bool showRadialLabels;
  final bool showRadialGrid;
  final bool showValues;
  final int maximumDataLabels;
  final double cornerRadius;
  final PolarColumnCornerRadiusMode cornerRadiusMode;
  final double opacity;

  final bool showTargets;
  final bool showThreshold;
  final double thresholdValue;
  final double targetMarkerWidth;
  final double targetMarkerLength;
  final double targetOpacity;
  final bool showIntervals;
  final PolarColumnIntervalDisplay intervalDisplay;
  final double intervalWidth;
  final double intervalCapLength;
  final double intervalBandLength;
  final double intervalOpacity;

  final Color? canvasColor;
  final Color? axisLineColor;
  final Color? axisLabelColor;
  final double axisLineWidth;
  final double axisLabelSize;
  final Color? gridLineColor;
  final double gridLineWidth;
  final PolarShowcaseLinePatternKind gridLinePattern;
  final Color? columnBorderColor;
  final double columnBorderWidth;
  final Color targetColor;
  final Color thresholdColor;
  final double thresholdWidth;
  final PolarShowcaseLinePatternKind thresholdPattern;
  final Color intervalColor;

  final bool showTooltip;
  final TooltipTriggerMode tooltipTrigger;
  final TooltipPosition tooltipPosition;
  final double tooltipOffset;
  final Color tooltipBackgroundColor;
  final Color tooltipTextColor;
  final Color tooltipBorderColor;
  final double tooltipBorderWidth;
  final double tooltipCornerRadius;
  final RadialSelectionEffect selectionEffect;
  final double selectionScale;
  final double selectionOffset;
  final double selectionBackdropBlur;
  final Color selectionColor;
}

/// Builds complete, reproducible Polar showcase configurations.
abstract final class PolarShowcaseRandomizer {
  static const _channelLabels = <String>[
    'Search',
    'Social',
    'Email',
    'Direct',
    'Partners',
    'Events',
    'Referral',
    'Organic',
    'Retail',
    'Mobile',
    'Affiliates',
    'Community',
    'Video',
    'Display',
    'Marketplace',
    'Resellers',
    'Support',
    'Field sales',
  ];

  static const _monthLabels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _stageLabels = <String>[
    'Discover',
    'Evaluate',
    'Trial',
    'Adopt',
    'Expand',
    'Renew',
    'Advocate',
    'Return',
  ];

  static const _accentColors = <Color>[
    Color(0xFF2563EB),
    Color(0xFF0891B2),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFDC2626),
    Color(0xFF9333EA),
  ];

  static const _lightCanvases = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
    Color(0xFFFFFBEB),
  ];

  static const _darkCanvases = <Color>[
    Color(0xFF0F172A),
    Color(0xFF111827),
    Color(0xFF1F2937),
  ];

  static PolarShowcaseRandomization generate(int seed) {
    final random = math.Random(seed);
    final presentation = _pick(random, PolarShowcasePresentationKind.values);
    final theme = _pick(random, PolarShowcaseThemeKind.values);
    var palette = _pick(random, PolarShowcasePaletteKind.values);
    final baseTheme = _themeFor(theme);
    final baseIsDark =
        ThemeData.estimateBrightnessForColor(baseTheme.backgroundColor) ==
        Brightness.dark;
    if (baseIsDark && palette == PolarShowcasePaletteKind.monochrome) {
      palette = PolarShowcasePaletteKind.ocean;
    }

    final categoryCount = _categoryCount(random, presentation);
    final labels = _labels(random, presentation, categoryCount);
    final data = _data(random, presentation, labels);
    final isPartial = presentation == PolarShowcasePresentationKind.partial;
    final isRose = presentation == PolarShowcasePresentationKind.rose;
    final isStacked = presentation == PolarShowcasePresentationKind.stacked;
    final useCustomCanvas = random.nextDouble() < 0.35;
    final canvasColor = useCustomCanvas
        ? _pick(random, baseIsDark ? _darkCanvases : _lightCanvases)
        : null;
    final effectiveCanvas = canvasColor ?? baseTheme.backgroundColor;
    final canvasIsDark =
        ThemeData.estimateBrightnessForColor(effectiveCanvas) ==
        Brightness.dark;
    final strongInk = canvasIsDark
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF0F172A);
    final softInk = canvasIsDark
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);
    final accent = _pick(random, _accentColors);
    final showAngularLabels = random.nextDouble() < 0.82;
    final showValues = random.nextDouble() < 0.7 || !showAngularLabels;

    return PolarShowcaseRandomization(
      seed: seed,
      presentation: presentation,
      theme: theme,
      palette: palette,
      primaryValues: data.$1,
      secondaryValues: data.$2,
      tertiaryValues: data.$3,
      startAngle: _stepped(random, -180, 180, 15),
      sweepAngle: isPartial
          ? _pick(random, const <double>[180, 210, 240, 270, 300])
          : 360,
      clockwise: random.nextBool(),
      innerRadius: isPartial
          ? _stepped(random, 0.18, 0.45, 0.03)
          : _stepped(random, 0, isRose ? 0.2 : 0.32, 0.04),
      outerRadius: _stepped(random, 0.78, 0.94, 0.02),
      innerPadding: _stepped(random, 0.04, 0.28, 0.02),
      outerPadding: isPartial
          ? _stepped(random, 0.02, 0.16, 0.02)
          : _stepped(random, 0, 0.1, 0.02),
      compositionMode: switch (presentation) {
        PolarShowcasePresentationKind.grouped =>
          PolarColumnCompositionMode.grouped,
        PolarShowcasePresentationKind.stacked =>
          PolarColumnCompositionMode.stacked,
        _ => PolarColumnCompositionMode.layered,
      },
      groupInnerPadding: _stepped(random, 0.04, 0.3, 0.02),
      scaleMode: isRose
          ? PolarRadialScaleMode.areaCorrect
          : PolarRadialScaleMode.linear,
      tickCount: 3 + random.nextInt(5),
      showAngularLabels: showAngularLabels,
      showAngularGrid: random.nextDouble() < 0.76,
      maximumAngularLabels: math.min(
        categoryCount,
        categoryCount > 12 ? 6 + random.nextInt(7) : categoryCount,
      ),
      maximumAngularGridLines: math.max(
        8,
        math.min(
          categoryCount,
          categoryCount > 14 ? 8 + random.nextInt(7) : categoryCount,
        ),
      ),
      showRadialLabels: random.nextDouble() < 0.62,
      showRadialGrid: random.nextDouble() < 0.86,
      showValues: showValues,
      maximumDataLabels: math.min(
        categoryCount,
        categoryCount > 12 ? 6 + random.nextInt(7) : categoryCount,
      ),
      cornerRadius: _stepped(random, 0, 14, 1),
      cornerRadiusMode: isStacked
          ? _pick(random, const [
              PolarColumnCornerRadiusMode.stackExterior,
              PolarColumnCornerRadiusMode.outerEnd,
            ])
          : _pick(random, const [
              PolarColumnCornerRadiusMode.outerEnd,
              PolarColumnCornerRadiusMode.bothEnds,
            ]),
      opacity: _stepped(random, 0.72, 1, 0.04),
      showTargets: presentation == PolarShowcasePresentationKind.references,
      showThreshold:
          presentation == PolarShowcasePresentationKind.references &&
          random.nextDouble() < 0.82,
      thresholdValue: _stepped(random, 45, 95, 5),
      targetMarkerWidth: _stepped(random, 1.5, 5, 0.5),
      targetMarkerLength: _stepped(random, 0.4, 0.95, 0.05),
      targetOpacity: _stepped(random, 0.6, 1, 0.05),
      showIntervals: presentation == PolarShowcasePresentationKind.intervals,
      intervalDisplay: _pick(random, PolarColumnIntervalDisplay.values),
      intervalWidth: _stepped(random, 1, 4, 0.5),
      intervalCapLength: _stepped(random, 0.4, 0.95, 0.05),
      intervalBandLength: _stepped(random, 0.4, 0.95, 0.05),
      intervalOpacity: _stepped(random, 0.55, 1, 0.05),
      canvasColor: canvasColor,
      axisLineColor: random.nextDouble() < 0.52 ? softInk : null,
      axisLabelColor: random.nextDouble() < 0.64 ? strongInk : null,
      axisLineWidth: _stepped(random, 0.5, 2.5, 0.25),
      axisLabelSize: _stepped(random, 9, 15, 1),
      gridLineColor: random.nextDouble() < 0.52
          ? softInk.withValues(alpha: canvasIsDark ? 0.42 : 0.3)
          : null,
      gridLineWidth: _stepped(random, 0.5, 2, 0.25),
      gridLinePattern: _pick(random, PolarShowcaseLinePatternKind.values),
      columnBorderColor: random.nextDouble() < 0.58 ? softInk : null,
      columnBorderWidth: _stepped(random, 0, 2, 0.25),
      targetColor: _pick(random, _accentColors),
      thresholdColor: _pick(random, _accentColors),
      thresholdWidth: _stepped(random, 1, 4, 0.5),
      thresholdPattern: _pick(random, PolarShowcaseLinePatternKind.values),
      intervalColor: _pick(random, _accentColors),
      showTooltip: random.nextDouble() < 0.92,
      tooltipTrigger: _pick(random, TooltipTriggerMode.values),
      tooltipPosition: _pick(random, TooltipPosition.values),
      tooltipOffset: _stepped(random, 4, 16, 2),
      tooltipBackgroundColor: canvasIsDark
          ? const Color(0xFFF8FAFC)
          : const Color(0xFF0F172A),
      tooltipTextColor: canvasIsDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      tooltipBorderColor: accent,
      tooltipBorderWidth: _stepped(random, 0.5, 2, 0.25),
      tooltipCornerRadius: _stepped(random, 2, 14, 1),
      selectionEffect: _pick(random, RadialSelectionEffect.values),
      selectionScale: _stepped(random, 1.04, 1.18, 0.01),
      selectionOffset: _stepped(random, 2, 14, 1),
      selectionBackdropBlur: _stepped(random, 0, 4, 0.5),
      selectionColor: accent,
    );
  }

  static int _categoryCount(
    math.Random random,
    PolarShowcasePresentationKind presentation,
  ) => switch (presentation) {
    PolarShowcasePresentationKind.rose => 8 + random.nextInt(5),
    PolarShowcasePresentationKind.partial => 4 + random.nextInt(5),
    PolarShowcasePresentationKind.layered ||
    PolarShowcasePresentationKind.grouped ||
    PolarShowcasePresentationKind.stacked => 5 + random.nextInt(12),
    PolarShowcasePresentationKind.references ||
    PolarShowcasePresentationKind.intervals => 5 + random.nextInt(10),
    PolarShowcasePresentationKind.standard => 5 + random.nextInt(14),
  };

  static List<String> _labels(
    math.Random random,
    PolarShowcasePresentationKind presentation,
    int count,
  ) {
    final source = switch (presentation) {
      PolarShowcasePresentationKind.rose => _monthLabels,
      PolarShowcasePresentationKind.partial => _stageLabels,
      _ => _channelLabels,
    };
    final offset = random.nextInt(source.length);
    return [
      for (var index = 0; index < count; index++)
        source[(offset + index) % source.length],
    ];
  }

  static (Map<String, num>, Map<String, num>, Map<String, num>) _data(
    math.Random random,
    PolarShowcasePresentationKind presentation,
    List<String> labels,
  ) {
    Map<String, num> positive({int minimum = 22, int spread = 79}) => {
      for (final label in labels) label: minimum + random.nextInt(spread),
    };

    switch (presentation) {
      case PolarShowcasePresentationKind.layered:
        final observed = positive(minimum: 24, spread: 63);
        return (
          observed,
          {
            for (final entry in observed.entries)
              entry.key: entry.value + 8 + random.nextInt(22),
          },
          const {},
        );
      case PolarShowcasePresentationKind.grouped:
        return (positive(), positive(), positive());
      case PolarShowcasePresentationKind.stacked:
        return (
          {for (final label in labels) label: 18 + random.nextInt(31)},
          {for (final label in labels) label: 7 + random.nextInt(19)},
          {for (final label in labels) label: -(6 + random.nextInt(21))},
        );
      case PolarShowcasePresentationKind.references:
        final actual = positive();
        return (
          actual,
          {
            for (final entry in actual.entries)
              entry.key: math.max(
                12,
                math.min(116, entry.value + random.nextInt(29) - 14),
              ),
          },
          const {},
        );
      case PolarShowcasePresentationKind.intervals:
        final values = positive();
        return (
          values,
          {
            for (final entry in values.entries)
              entry.key: math.max(0, entry.value - (5 + random.nextInt(13))),
          },
          {
            for (final entry in values.entries)
              entry.key: entry.value + 5 + random.nextInt(16),
          },
        );
      case PolarShowcasePresentationKind.standard:
      case PolarShowcasePresentationKind.rose:
      case PolarShowcasePresentationKind.partial:
        return (positive(), const {}, const {});
    }
  }

  static ChartTheme _themeFor(PolarShowcaseThemeKind theme) => switch (theme) {
    PolarShowcaseThemeKind.light => ChartTheme.light,
    PolarShowcaseThemeKind.dark => ChartTheme.dark,
    PolarShowcaseThemeKind.corporate => ChartTheme.corporateBlue,
    PolarShowcaseThemeKind.vibrant => ChartTheme.vibrant,
    PolarShowcaseThemeKind.minimal => ChartTheme.minimal,
    PolarShowcaseThemeKind.highContrast => ChartTheme.highContrast,
    PolarShowcaseThemeKind.colorblind => ChartTheme.colorblindFriendly,
  };

  static T _pick<T>(math.Random random, List<T> values) =>
      values[random.nextInt(values.length)];

  static double _stepped(
    math.Random random,
    double minimum,
    double maximum,
    double step,
  ) {
    final steps = ((maximum - minimum) / step).round();
    final value = minimum + random.nextInt(steps + 1) * step;
    return (value * 1000000).round() / 1000000;
  }
}
