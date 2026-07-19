import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../artifacts/chart_view_state.dart';
import '../models/chart_theme.dart';
import '../models/concentric_donut_config.dart';
import '../models/donut_chart_series.dart';
import '../models/legend_style.dart';
import '../models/radial_category_series.dart';
import '../models/radial_legend_item.dart';
import '../formatting/radial_value_formatter.dart';
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
    this.itemBuilder,
    this.disableAnimations = false,
  });

  /// Source pie series.
  final RadialCategorySeries series;

  /// Effective chart theme used by the slice painter.
  final ChartTheme chartTheme;

  /// Durable source-point selection shown by the legend.
  final Set<int> selectedPointIndices;

  /// Invoked with the source point index of an activated legend item.
  final ValueChanged<int> onSliceTap;

  /// Optional host builder for the visible contents of every legend item.
  ///
  /// Layout, activation, and assistive semantics remain package-owned. The
  /// returned widget replaces the default marker, category, value, and share.
  final RadialLegendItemBuilder? itemBuilder;

  /// Whether selection transitions must complete immediately.
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final style = chartTheme.legendStyle;
    final visibleSlices = series.visibleSlices;
    final total = series.total;
    if (visibleSlices.isEmpty || total <= 0) return const SizedBox.shrink();

    final items = [
      for (final (visibleIndex, slice) in visibleSlices.indexed)
        _PieLegendItem(
          key: ValueKey<String>(
            'pie-legend-item-${slice.sourcePointIndices.join('-')}',
          ),
          markerShape: style.markerShape,
          markerSize: style.markerSize,
          markerLineWidth: style.markerLineWidth,
          markerLabelSpacing: style.markerLabelSpacing,
          itemBuilder: itemBuilder,
          data: RadialLegendItemData(
            seriesId: series.id,
            seriesName: series.name,
            unit: series.unit,
            visibleIndex: visibleIndex,
            pointIndex: slice.pointIndex,
            sourcePointIndices: slice.sourcePointIndices,
            sourcePoints: [
              for (final pointIndex in slice.sourcePointIndices)
                series.points[pointIndex],
            ],
            point: slice.point,
            category: slice.point.label!.trim(),
            value: slice.point.y,
            share: slice.point.y / total,
            color: PieSliceColorResolver.resolve(
              series: series,
              theme: chartTheme,
              point: slice.point,
              visibleIndex: visibleIndex,
            ),
            selectionColor: chartTheme.focusBorderColor,
            defaultTextStyle: style.textStyle,
            selected: slice.sourcePointIndices.every(
              selectedPointIndices.contains,
            ),
            animationDuration: disableAnimations
                ? Duration.zero
                : chartTheme.animationTheme.interactionDuration,
            valueLabel: RadialValueFormatters.value(series, slice.point.y),
            shareLabel: RadialValueFormatters.share(
              series,
              slice.point.y / total,
            ),
          ),
          onTap: () => onSliceTap(slice.pointIndex),
        ),
    ];
    final itemLayout = style.orientation == LegendOrientation.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, item) in items.indexed) ...[
                if (index > 0) SizedBox(height: math.max(8, style.itemSpacing)),
                item,
              ],
            ],
          )
        : Wrap(
            alignment: WrapAlignment.center,
            spacing: math.max(8, style.itemSpacing),
            runSpacing: 8,
            children: items,
          );

    return Transform.translate(
      offset: style.offset,
      child: Opacity(
        opacity: style.opacity.clamp(0, 1),
        child: Material(
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
            child: itemLayout,
          ),
        ),
      ),
    );
  }
}

/// Native legend for two or more independently normalized Donut rings.
///
/// Grouped mode is the default because category labels may repeat between
/// rings. Flat mode keeps the same compact layout while qualifying every
/// default item with its series name. Selection callbacks always retain both
/// the stable series ID and source point index.
class ConcentricDonutLegend extends StatelessWidget {
  /// Creates a ring-aware legend for a Concentric Donut composition.
  const ConcentricDonutLegend({
    super.key,
    required this.series,
    required this.config,
    required this.chartTheme,
    required this.selectedPointRefs,
    required this.onSliceTap,
    this.itemBuilder,
    this.disableAnimations = false,
  });

  /// Independent Donut series in stable source order.
  final List<DonutChartSeries> series;

  /// Composition settings that determine ring order and legend organization.
  final ConcentricDonutConfig config;

  /// Effective chart theme used by every slice and legend item.
  final ChartTheme chartTheme;

  /// Durable source-point selection shown by the legend.
  final Set<ChartPointRef> selectedPointRefs;

  /// Invoked with the exact ring and source point represented by an item.
  final ValueChanged<ChartPointRef> onSliceTap;

  /// Optional host builder for the visible contents of every legend item.
  final RadialLegendItemBuilder? itemBuilder;

  /// Whether selection transitions must complete immediately.
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    final style = chartTheme.legendStyle;
    final ringGroups = <Widget>[];
    final flatItems = <Widget>[];

    for (final (ringIndex, ring) in series.indexed) {
      final positionLabel = _ringPositionLabel(ringIndex, series.length);
      final items = _itemsForRing(
        ring: ring,
        ringIndex: ringIndex,
        ringPositionLabel: positionLabel,
        qualifyCategory: config.legendMode == ConcentricDonutLegendMode.flat,
      );
      if (items.isEmpty) continue;
      flatItems.addAll(items);
      ringGroups.add(
        Semantics(
          container: true,
          label: '$positionLabel, ${ring.name ?? ring.id}',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Text(
                  '$positionLabel · ${ring.name ?? ring.id}',
                  key: ValueKey<String>('concentric-ring-heading-${ring.id}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style.textStyle.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              _itemLayout(items, style),
            ],
          ),
        ),
      );
    }

    if (flatItems.isEmpty) return const SizedBox.shrink();
    final content = switch (config.legendMode) {
      ConcentricDonutLegendMode.groupedByRing => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, group) in ringGroups.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            group,
          ],
        ],
      ),
      ConcentricDonutLegendMode.flat => _itemLayout(flatItems, style),
    };

    return Transform.translate(
      offset: style.offset,
      child: Opacity(
        opacity: style.opacity.clamp(0, 1),
        child: Material(
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
            child: content,
          ),
        ),
      ),
    );
  }

  List<Widget> _itemsForRing({
    required DonutChartSeries ring,
    required int ringIndex,
    required String ringPositionLabel,
    required bool qualifyCategory,
  }) {
    final style = chartTheme.legendStyle;
    final total = ring.total;
    if (total <= 0) return const <Widget>[];
    final selectedPointIndices = <int>{
      for (final ref in selectedPointRefs)
        if (ref.seriesId == ring.id) ref.pointIndex,
    };
    return [
      for (final (visibleIndex, slice) in ring.visibleSlices.indexed)
        _PieLegendItem(
          key: ValueKey<String>(
            'pie-legend-item-${ring.id}-'
            '${slice.sourcePointIndices.join('-')}',
          ),
          markerShape: style.markerShape,
          markerSize: style.markerSize,
          markerLineWidth: style.markerLineWidth,
          markerLabelSpacing: style.markerLabelSpacing,
          itemBuilder: itemBuilder,
          defaultCategoryLabel: qualifyCategory
              ? '${ring.name ?? ring.id} · ${slice.point.label!.trim()}'
              : null,
          data: RadialLegendItemData(
            seriesId: ring.id,
            seriesName: ring.name,
            unit: ring.unit,
            visibleIndex: visibleIndex,
            pointIndex: slice.pointIndex,
            sourcePointIndices: slice.sourcePointIndices,
            sourcePoints: [
              for (final pointIndex in slice.sourcePointIndices)
                ring.points[pointIndex],
            ],
            point: slice.point,
            category: slice.point.label!.trim(),
            value: slice.point.y,
            share: slice.point.y / total,
            color: PieSliceColorResolver.resolve(
              series: ring,
              theme: chartTheme,
              point: slice.point,
              visibleIndex: visibleIndex,
            ),
            selectionColor: chartTheme.focusBorderColor,
            defaultTextStyle: style.textStyle,
            selected: slice.sourcePointIndices.every(
              selectedPointIndices.contains,
            ),
            animationDuration: disableAnimations
                ? Duration.zero
                : chartTheme.animationTheme.interactionDuration,
            ringIndex: ringIndex,
            ringCount: series.length,
            ringPositionLabel: ringPositionLabel,
            ringTotal: total,
            valueLabel: RadialValueFormatters.value(ring, slice.point.y),
            shareLabel: RadialValueFormatters.share(
              ring,
              slice.point.y / total,
            ),
          ),
          onTap: () => onSliceTap(
            ChartPointRef(seriesId: ring.id, pointIndex: slice.pointIndex),
          ),
        ),
    ];
  }

  String _ringPositionLabel(int sourceIndex, int count) {
    final physicalIndex = switch (config.order) {
      ConcentricRingOrder.outerToInner => sourceIndex,
      ConcentricRingOrder.innerToOuter => count - sourceIndex - 1,
    };
    if (physicalIndex == 0) return 'Outer ring';
    if (physicalIndex == count - 1) return 'Inner ring';
    return 'Ring ${physicalIndex + 1} of $count';
  }

  Widget _itemLayout(List<Widget> items, LegendStyle style) {
    return style.orientation == LegendOrientation.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, item) in items.indexed) ...[
                if (index > 0) SizedBox(height: math.max(8, style.itemSpacing)),
                item,
              ],
            ],
          )
        : Wrap(
            alignment: WrapAlignment.center,
            spacing: math.max(8, style.itemSpacing),
            runSpacing: 8,
            children: items,
          );
  }
}

class _PieLegendItem extends StatelessWidget {
  const _PieLegendItem({
    super.key,
    required this.markerShape,
    required this.markerSize,
    required this.markerLineWidth,
    required this.markerLabelSpacing,
    required this.data,
    required this.itemBuilder,
    required this.onTap,
    this.defaultCategoryLabel,
  });

  final LegendMarkerShape markerShape;
  final double markerSize;
  final double markerLineWidth;
  final double markerLabelSpacing;
  final RadialLegendItemData data;
  final RadialLegendItemBuilder? itemBuilder;
  final VoidCallback onTap;
  final String? defaultCategoryLabel;

  @override
  Widget build(BuildContext context) {
    final valueText = data.valueLabel;
    final shareText = data.shareLabel;
    final textStyle = data.defaultTextStyle;
    final selectionColor = data.selectionColor;
    final selected = data.selected;
    final customContent = itemBuilder?.call(context, data);
    final interactiveContent = customContent == null
        ? AnimatedContainer(
            duration: data.animationDuration,
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
                _PieLegendMarker(
                  color: data.color,
                  borderColor: textStyle.color ?? Colors.black87,
                  selectionColor: selectionColor,
                  shape: markerShape,
                  size: markerSize,
                  lineWidth: markerLineWidth,
                  selected: selected,
                ),
                SizedBox(width: markerLabelSpacing),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        defaultCategoryLabel ?? data.category,
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
              ],
            ),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: customContent,
          );
    final interactive = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: interactiveContent,
    );
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: data.semanticLabel,
      child: customContent == null
          ? Tooltip(
              message:
                  '${defaultCategoryLabel ?? data.category}\n'
                  '$valueText · $shareText',
              child: interactive,
            )
          : interactive,
    );
  }
}

class _PieLegendMarker extends StatelessWidget {
  const _PieLegendMarker({
    required this.color,
    required this.borderColor,
    required this.selectionColor,
    required this.shape,
    required this.size,
    required this.lineWidth,
    required this.selected,
  });

  final Color color;
  final Color borderColor;
  final Color selectionColor;
  final LegendMarkerShape shape;
  final double size;
  final double lineWidth;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final dimension = math.max(14, size).toDouble();
    return SizedBox.square(
      dimension: dimension,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: switch (shape) {
              LegendMarkerShape.circle => DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
              ),
              LegendMarkerShape.square => DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: borderColor, width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              LegendMarkerShape.line => Center(
                child: Container(
                  width: dimension,
                  height: math.max(2, lineWidth).toDouble(),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(lineWidth),
                  ),
                ),
              ),
              LegendMarkerShape.diamond => Transform.rotate(
                angle: math.pi / 4,
                child: FractionallySizedBox(
                  widthFactor: 0.72,
                  heightFactor: 0.72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: borderColor, width: 1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            },
          ),
          if (selected)
            Positioned(
              right: -3,
              bottom: -3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selectionColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        ThemeData.estimateBrightnessForColor(selectionColor) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    width: 1,
                  ),
                ),
                child: SizedBox.square(
                  dimension: 11,
                  child: Icon(
                    Icons.check_rounded,
                    size: 9,
                    color:
                        ThemeData.estimateBrightnessForColor(selectionColor) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
