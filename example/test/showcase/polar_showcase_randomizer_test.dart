import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/data/polar_showcase_randomizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the same seed reproduces every generated Polar property', () {
    final first = PolarShowcaseRandomizer.generate(317);
    final replay = PolarShowcaseRandomizer.generate(317);
    final next = PolarShowcaseRandomizer.generate(318);

    expect(_signature(replay), _signature(first));
    expect(_signature(next), isNot(_signature(first)));
  });

  test('generated configurations retain presentation invariants', () {
    final presentations = <PolarShowcasePresentationKind>{};
    final themes = <PolarShowcaseThemeKind>{};
    final palettes = <PolarShowcasePaletteKind>{};

    for (var seed = 0; seed < 400; seed++) {
      final generated = PolarShowcaseRandomizer.generate(seed);
      presentations.add(generated.presentation);
      themes.add(generated.theme);
      palettes.add(generated.palette);

      expect(generated.categoryCount, inInclusiveRange(4, 18));
      expect(
        generated.primaryValues.keys.toSet(),
        hasLength(generated.categoryCount),
      );
      expect(generated.startAngle, inInclusiveRange(-180, 180));
      expect(generated.sweepAngle, inInclusiveRange(180, 360));
      expect(generated.innerRadius, inInclusiveRange(0, 0.45));
      expect(generated.outerRadius, inInclusiveRange(0.78, 0.94));
      expect(generated.innerRadius, lessThan(generated.outerRadius));
      expect(generated.maximumAngularLabels, inInclusiveRange(4, 18));
      expect(generated.maximumAngularGridLines, inInclusiveRange(8, 18));
      expect(generated.maximumDataLabels, inInclusiveRange(4, 18));
      expect(
        _contrastRatio(
          generated.tooltipTextColor,
          generated.tooltipBackgroundColor,
        ),
        greaterThanOrEqualTo(4.5),
      );

      switch (generated.presentation) {
        case PolarShowcasePresentationKind.rose:
          expect(generated.scaleMode, PolarRadialScaleMode.areaCorrect);
          expect(generated.categoryCount, inInclusiveRange(8, 12));
        case PolarShowcasePresentationKind.partial:
          expect(generated.sweepAngle, lessThan(360));
          expect(generated.innerRadius, greaterThanOrEqualTo(0.18));
        case PolarShowcasePresentationKind.layered:
          expect(generated.secondaryValues.keys, generated.primaryValues.keys);
          for (final category in generated.primaryValues.keys) {
            expect(
              generated.secondaryValues[category]!,
              greaterThan(generated.primaryValues[category]!),
            );
          }
        case PolarShowcasePresentationKind.grouped:
          expect(generated.compositionMode, PolarColumnCompositionMode.grouped);
          expect(generated.secondaryValues.keys, generated.primaryValues.keys);
          expect(generated.tertiaryValues.keys, generated.primaryValues.keys);
        case PolarShowcasePresentationKind.stacked:
          expect(generated.compositionMode, PolarColumnCompositionMode.stacked);
          expect(generated.secondaryValues.keys, generated.primaryValues.keys);
          expect(generated.tertiaryValues.keys, generated.primaryValues.keys);
          expect(
            generated.tertiaryValues.values.every((value) => value < 0),
            isTrue,
          );
        case PolarShowcasePresentationKind.references:
          expect(generated.showTargets, isTrue);
          expect(generated.secondaryValues.keys, generated.primaryValues.keys);
        case PolarShowcasePresentationKind.intervals:
          expect(generated.showIntervals, isTrue);
          expect(generated.secondaryValues.keys, generated.primaryValues.keys);
          expect(generated.tertiaryValues.keys, generated.primaryValues.keys);
          for (final category in generated.primaryValues.keys) {
            expect(
              generated.secondaryValues[category]!,
              lessThanOrEqualTo(generated.primaryValues[category]!),
            );
            expect(
              generated.tertiaryValues[category]!,
              greaterThanOrEqualTo(generated.primaryValues[category]!),
            );
          }
        case PolarShowcasePresentationKind.standard:
          expect(generated.secondaryValues, isEmpty);
          expect(generated.tertiaryValues, isEmpty);
      }
    }

    expect(presentations, PolarShowcasePresentationKind.values.toSet());
    expect(themes, PolarShowcaseThemeKind.values.toSet());
    expect(palettes, PolarShowcasePaletteKind.values.toSet());
  });
}

List<Object?> _signature(PolarShowcaseRandomization value) => <Object?>[
  value.seed,
  value.presentation,
  value.theme,
  value.palette,
  value.primaryValues.toString(),
  value.secondaryValues.toString(),
  value.tertiaryValues.toString(),
  value.startAngle,
  value.sweepAngle,
  value.clockwise,
  value.innerRadius,
  value.outerRadius,
  value.innerPadding,
  value.outerPadding,
  value.compositionMode,
  value.groupInnerPadding,
  value.scaleMode,
  value.tickCount,
  value.showAngularLabels,
  value.showAngularGrid,
  value.maximumAngularLabels,
  value.maximumAngularGridLines,
  value.showRadialLabels,
  value.showRadialGrid,
  value.showValues,
  value.maximumDataLabels,
  value.cornerRadius,
  value.cornerRadiusMode,
  value.opacity,
  value.showTargets,
  value.showThreshold,
  value.thresholdValue,
  value.targetMarkerWidth,
  value.targetMarkerLength,
  value.targetOpacity,
  value.showIntervals,
  value.intervalDisplay,
  value.intervalWidth,
  value.intervalCapLength,
  value.intervalBandLength,
  value.intervalOpacity,
  value.canvasColor,
  value.axisLineColor,
  value.axisLabelColor,
  value.axisLineWidth,
  value.axisLabelSize,
  value.gridLineColor,
  value.gridLineWidth,
  value.gridLinePattern,
  value.columnBorderColor,
  value.columnBorderWidth,
  value.targetColor,
  value.thresholdColor,
  value.thresholdWidth,
  value.thresholdPattern,
  value.intervalColor,
  value.showTooltip,
  value.tooltipTrigger,
  value.tooltipPosition,
  value.tooltipOffset,
  value.tooltipBackgroundColor,
  value.tooltipTextColor,
  value.tooltipBorderColor,
  value.tooltipBorderWidth,
  value.tooltipCornerRadius,
  value.selectionEffect,
  value.selectionScale,
  value.selectionOffset,
  value.selectionBackdropBlur,
  value.selectionColor,
];

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
