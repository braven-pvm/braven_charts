// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/heatmap_chart_series.dart';
import '../models/heatmap_color_scale.dart';

/// A reusable legend for the independent value scale of a Heatmap series.
///
/// Unlike the ordinary series legend, this describes how measured cell values
/// map to colour. It renders continuous sequential/diverging ramps and discrete
/// threshold bands from the same [HeatmapColorScale] used by the renderer.
class HeatmapColorLegend extends StatelessWidget {
  const HeatmapColorLegend({
    super.key,
    required this.series,
    this.rampExtent = 220,
    this.rampThickness = 12,
    this.showTitle = true,
    this.textStyle,
  });

  final HeatmapChartSeries series;

  /// Maximum horizontal extent of a continuous colour ramp.
  final double rampExtent;

  /// Thickness of a continuous colour ramp.
  final double rampThickness;

  /// Whether to show [HeatmapColorScale.label] before the scale.
  final bool showTitle;

  /// Optional text style for legend labels.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scale = series.colorScale;
    if (!scale.showLegend) return const SizedBox.shrink();
    final style = textStyle ?? Theme.of(context).textTheme.labelMedium;
    final semanticLabel = [
      scale.label,
      if (scale.unit != null) scale.unit!,
      if (scale.type == HeatmapColorScaleType.threshold)
        ..._thresholdLabels(scale),
    ].join(', ');

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          if (showTitle)
            Text(
              _title(scale),
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
          if (scale.type == HeatmapColorScaleType.threshold)
            ..._thresholdItems(scale, style)
          else
            _continuousRamp(scale, style),
        ],
      ),
    );
  }

  Widget _continuousRamp(HeatmapColorScale scale, TextStyle? style) {
    final minimum = scale.minimumValue ?? series.resolvedMinimumValue;
    final maximum = scale.maximumValue ?? series.resolvedMaximumValue;
    final colors = scale.reverse
        ? scale.colors.reversed.toList(growable: false)
        : scale.colors;
    final labels = <double>[
      minimum,
      if (scale.type == HeatmapColorScaleType.diverging) scale.midpoint!,
      maximum,
    ];

    return SizedBox(
      width: rampExtent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: rampThickness,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(rampThickness),
              gradient: LinearGradient(colors: colors),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final value in labels)
                Text(_formatValue(value, scale.unit), style: style),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _thresholdItems(HeatmapColorScale scale, TextStyle? style) {
    final labels = _thresholdLabels(scale);
    final colors = scale.reverse
        ? scale.colors.reversed.toList(growable: false)
        : scale.colors;
    return [
      for (var index = 0; index < colors.length; index++)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(labels[index], style: style),
          ],
        ),
    ];
  }

  List<String> _thresholdLabels(HeatmapColorScale scale) {
    if (scale.bandLabels.isNotEmpty) return scale.bandLabels;
    return [
      for (var index = 0; index < scale.colors.length; index++)
        if (index == 0)
          '< ${_formatValue(scale.thresholds.first, scale.unit)}'
        else if (index == scale.colors.length - 1)
          '≥ ${_formatValue(scale.thresholds.last, scale.unit)}'
        else
          '${_formatValue(scale.thresholds[index - 1], scale.unit)}–'
              '${_formatValue(scale.thresholds[index], scale.unit)}',
    ];
  }

  String _title(HeatmapColorScale scale) {
    final unit = scale.unit;
    return unit == null || unit.isEmpty
        ? scale.label
        : '${scale.label} ($unit)';
  }

  String _formatValue(double value, String? unit) {
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return unit == null || unit.isEmpty ? number : '$number $unit';
  }
}
