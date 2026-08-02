// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/heatmap_chart_series.dart';
import '../models/heatmap_color_scale.dart';

/// Publishes a value-filter change for one Heatmap colour axis.
typedef HeatmapLegendFilterChanged =
    void Function(String seriesId, HeatmapValueFilter? filter);

/// Presents the independent colour axes of several Heatmap series.
///
/// Every child legend reads the scale, resolved domain, empty-value style,
/// and current value filter from its own source series. The group does not
/// merge domains or imply linked chart state.
class HeatmapColorLegendGroup extends StatelessWidget {
  const HeatmapColorLegendGroup({
    super.key,
    required this.series,
    this.direction = Axis.horizontal,
    this.spacing = 16,
    this.runSpacing = 12,
    this.rampExtent = 180,
    this.rampThickness = 10,
    this.showSeriesNames = true,
    this.textStyle,
    this.onValueFilterChanged,
  });

  /// Heatmap series in chart/legend order.
  final List<HeatmapChartSeries> series;

  /// Whether legend entries wrap horizontally or stack vertically.
  final Axis direction;

  final double spacing;
  final double runSpacing;
  final double rampExtent;
  final double rampThickness;

  /// Whether each axis is prefixed by its source series name.
  final bool showSeriesNames;

  final TextStyle? textStyle;

  /// Optional independently routed filter callback.
  final HeatmapLegendFilterChanged? onValueFilterChanged;

  @override
  Widget build(BuildContext context) {
    final visibleSeries = series
        .where((item) => item.colorScale.showLegend)
        .toList(growable: false);
    if (visibleSeries.isEmpty) return const SizedBox.shrink();

    final entries = <Widget>[
      for (final item in visibleSeries)
        _HeatmapColorLegendGroupEntry(
          key: ValueKey('heatmap-colour-axis-${item.id}'),
          series: item,
          rampExtent: rampExtent,
          rampThickness: rampThickness,
          showSeriesName: showSeriesNames,
          textStyle: textStyle,
          onValueFilterChanged: onValueFilterChanged == null
              ? null
              : (filter) => onValueFilterChanged!(item.id, filter),
        ),
    ];

    return Semantics(
      container: true,
      label: '${visibleSeries.length} Heatmap colour axes',
      child: direction == Axis.vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  if (index > 0) SizedBox(height: spacing),
                  entries[index],
                ],
              ],
            )
          : Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: entries,
            ),
    );
  }
}

class _HeatmapColorLegendGroupEntry extends StatelessWidget {
  const _HeatmapColorLegendGroupEntry({
    super.key,
    required this.series,
    required this.rampExtent,
    required this.rampThickness,
    required this.showSeriesName,
    required this.textStyle,
    required this.onValueFilterChanged,
  });

  final HeatmapChartSeries series;
  final double rampExtent;
  final double rampThickness;
  final bool showSeriesName;
  final TextStyle? textStyle;
  final ValueChanged<HeatmapValueFilter?>? onValueFilterChanged;

  @override
  Widget build(BuildContext context) {
    final style = textStyle ?? Theme.of(context).textTheme.labelMedium;
    return Semantics(
      container: true,
      label: '${series.displayName} colour axis',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSeriesName) ...[
            Text(
              series.displayName,
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
          ],
          HeatmapColorLegend(
            series: series,
            rampExtent: rampExtent,
            rampThickness: rampThickness,
            textStyle: textStyle,
            onValueFilterChanged: onValueFilterChanged,
          ),
        ],
      ),
    );
  }
}

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
    this.onValueFilterChanged,
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

  /// Enables interactive filtering for continuous scales.
  ///
  /// Passing a callback opts the legend into an accessible range control.
  /// The callback receives an immutable presentation filter; passing `null`
  /// from the legend's reset action restores the complete measured domain.
  /// Threshold-scale filtering is intentionally not implied by this API.
  final ValueChanged<HeatmapValueFilter?>? onValueFilterChanged;

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
      if (series.emptyValueStyle case final emptyStyle?
          when emptyStyle.showInLegend)
        emptyStyle.legendLabel,
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
            _continuousRamp(context, scale, style),
          if (series.emptyValueStyle case final emptyStyle?
              when emptyStyle.showInLegend)
            _legendSwatch(
              color: emptyStyle.fillColor,
              label: emptyStyle.legendLabel,
              style: style,
            ),
        ],
      ),
    );
  }

  Widget _continuousRamp(
    BuildContext context,
    HeatmapColorScale scale,
    TextStyle? style,
  ) {
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

    final filter = series.valueFilter;
    final canFilter = onValueFilterChanged != null && maximum > minimum;
    final values = filter == null
        ? RangeValues(minimum, maximum)
        : RangeValues(
            filter.minimumValue.clamp(minimum, maximum).toDouble(),
            filter.maximumValue.clamp(minimum, maximum).toDouble(),
          );

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
          if (canFilter) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                    ),
                    child: RangeSlider(
                      values: values,
                      min: minimum,
                      max: maximum,
                      labels: RangeLabels(
                        _formatValue(values.start, scale.unit),
                        _formatValue(values.end, scale.unit),
                      ),
                      semanticFormatterCallback: (value) =>
                          _formatValue(value, scale.unit),
                      onChanged: (next) {
                        final current = series.valueFilter;
                        onValueFilterChanged!(
                          HeatmapValueFilter(
                            minimumValue: next.start,
                            maximumValue: next.end,
                            mode: current?.mode ?? HeatmapValueFilterMode.dim,
                            excludedOpacity: current?.excludedOpacity ?? 0.14,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (filter != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Clear value filter',
                    onPressed: () => onValueFilterChanged!(null),
                    icon: const Icon(Icons.restart_alt, size: 18),
                  ),
              ],
            ),
          ],
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

  Widget _legendSwatch({
    required Color color,
    required String label,
    required TextStyle? style,
  }) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: style),
    ],
  );

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
