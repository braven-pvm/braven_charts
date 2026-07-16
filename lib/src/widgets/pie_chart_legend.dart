import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/chart_theme.dart';
import '../models/pie_chart_series.dart';
import '../rendering/pie_slice_color_resolver.dart';

/// Native, slice-aware legend used by radial charts.
///
/// Items select slices rather than hiding them. Native controls provide
/// keyboard focus, tap targets, and assistive semantics outside the canvas.
class PieChartLegend extends StatelessWidget {
  /// Creates a selectable legend for one pie series.
  const PieChartLegend({
    super.key,
    required this.series,
    required this.chartTheme,
    required this.selectedPointIndices,
    required this.onSliceTap,
    this.disableAnimations = false,
  });

  /// Source pie series.
  final PieChartSeries series;

  /// Effective chart theme used by the slice painter.
  final ChartTheme chartTheme;

  /// Durable source-point selection shown by the legend.
  final Set<int> selectedPointIndices;

  /// Invoked with the source point index of an activated legend item.
  final ValueChanged<int> onSliceTap;

  /// Whether selection transitions must complete immediately.
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final style = chartTheme.legendStyle;
    final visibleIndices = series.visiblePointIndices;
    final total = series.total;
    if (visibleIndices.isEmpty || total <= 0) return const SizedBox.shrink();

    return Material(
      color: style.backgroundColor ?? chartTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: style.effectiveBorderRadius,
        side: style.borderWidth > 0
            ? BorderSide(
                color: style.borderColor ?? chartTheme.axisStyle.lineColor,
                width: style.borderWidth,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: style.padding ?? const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: math.max(8, style.itemSpacing),
          runSpacing: 8,
          children: [
            for (final (visibleIndex, pointIndex) in visibleIndices.indexed)
              _PieLegendItem(
                key: ValueKey<String>('pie-legend-item-$pointIndex'),
                category: series.points[pointIndex].label!.trim(),
                value: series.points[pointIndex].y,
                unit: series.unit,
                share: series.points[pointIndex].y / total,
                color: PieSliceColorResolver.resolve(
                  series: series,
                  theme: chartTheme,
                  point: series.points[pointIndex],
                  visibleIndex: visibleIndex,
                ),
                selectionColor: chartTheme.focusBorderColor,
                textStyle: style.textStyle,
                selected: selectedPointIndices.contains(pointIndex),
                duration: disableAnimations
                    ? Duration.zero
                    : chartTheme.animationTheme.interactionDuration,
                onTap: () => onSliceTap(pointIndex),
              ),
          ],
        ),
      ),
    );
  }
}

class _PieLegendItem extends StatelessWidget {
  const _PieLegendItem({
    super.key,
    required this.category,
    required this.value,
    required this.unit,
    required this.share,
    required this.color,
    required this.selectionColor,
    required this.textStyle,
    required this.selected,
    required this.duration,
    required this.onTap,
  });

  final String category;
  final double value;
  final String? unit;
  final double share;
  final Color color;
  final Color selectionColor;
  final TextStyle textStyle;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final valueText =
        '${value.toStringAsFixed(2)}${unit == null || unit!.isEmpty ? '' : ' $unit'}';
    final shareText = '${(share * 100).toStringAsFixed(1)}%';
    final semanticLabel =
        '$category, $valueText, ${(share * 100).toStringAsFixed(1)} percent, '
        '${selected ? 'selected' : 'not selected'}';
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Tooltip(
        message: '$category\n$valueText · $shareText',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: duration,
            constraints: const BoxConstraints(minHeight: 48, maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? selectionColor.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? selectionColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: textStyle.color ?? Colors.black87,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$valueText · $shareText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyle.copyWith(
                          fontSize: (textStyle.fontSize ?? 11) * 0.92,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 18, color: selectionColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
