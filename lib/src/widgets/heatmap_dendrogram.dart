// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/heatmap_dendrogram_data.dart';

/// Shape painted at a dendrogram leaf or merge anchor.
enum HeatmapDendrogramMarkerShape {
  /// Circular marker.
  circle,

  /// Axis-aligned square marker.
  square,

  /// Square marker rotated by 45 degrees.
  diamond,

  /// Upward-pointing triangular marker.
  triangle,
}

/// Fill treatment painted inside a dendrogram marker.
enum HeatmapDendrogramMarkerFill {
  /// Paint the marker interior and its optional border.
  solid,

  /// Leave the marker interior transparent and paint only its border.
  hollow,
}

/// Deterministic upper bound for dendrogram labels.
enum HeatmapDendrogramLabelDensity {
  /// Paint every enabled label.
  all,

  /// Paint at most twelve evenly distributed labels of each enabled kind.
  balanced,

  /// Paint at most six evenly distributed labels of each enabled kind.
  sparse,
}

/// Orientation-aware placement for dendrogram labels.
enum HeatmapDendrogramLabelPlacement {
  /// Place labels before the node along the category axis.
  before,

  /// Place labels after the node along the category axis.
  after,
}

/// Controls whether a dendrogram adapts presentation to its screen density.
enum HeatmapDendrogramLevelOfDetailMode {
  /// Suppress geometry and decoration that cannot be read at the current size.
  automatic,

  /// Paint every explicitly enabled branch, guide, marker, and label.
  disabled,
}

/// Immutable presentation contract for a [HeatmapDendrogram].
///
/// Geometry, hierarchy, and accepted leaf order remain owned by
/// [HeatmapDendrogramData]. This style changes only how that portable geometry
/// is painted.
@immutable
final class HeatmapDendrogramStyle {
  const HeatmapDendrogramStyle({
    this.branchColor,
    this.branchWidth = 1.5,
    this.branchCap = StrokeCap.round,
    this.branchJoin = StrokeJoin.round,
    this.baselineColor,
    this.baselineWidth = 1,
    this.showLeafBaseline = true,
    this.tickColor,
    this.tickWidth = 1,
    this.tickLength = 5,
    this.showLeafTicks = true,
    this.elbowRadius = 0,
    this.showLeafMarkers = false,
    this.leafMarkerColor,
    this.leafMarkerRadius = 3,
    this.leafMarkerShape = HeatmapDendrogramMarkerShape.circle,
    this.leafMarkerFill = HeatmapDendrogramMarkerFill.solid,
    this.leafMarkerBorderColor,
    this.leafMarkerBorderWidth = 1,
    this.showMergeMarkers = false,
    this.mergeMarkerColor,
    this.mergeMarkerRadius = 3.5,
    this.mergeMarkerShape = HeatmapDendrogramMarkerShape.circle,
    this.mergeMarkerFill = HeatmapDendrogramMarkerFill.solid,
    this.mergeMarkerBorderColor,
    this.mergeMarkerBorderWidth = 1,
    this.showLeafLabels = false,
    this.showMergeDistanceLabels = false,
    this.labelColor,
    this.labelBackgroundColor,
    this.labelFontSize = 10,
    this.labelPadding = 2,
    this.labelRadius = 3,
    this.labelOffset = 4,
    this.labelDensity = HeatmapDendrogramLabelDensity.balanced,
    this.labelPlacement = HeatmapDendrogramLabelPlacement.before,
    this.maxLabelCharacters = 14,
    this.mergeDistanceFractionDigits = 2,
    this.levelOfDetailMode = HeatmapDendrogramLevelOfDetailMode.automatic,
    this.minimumBranchLength = 0.75,
    this.minimumLeafGuideSpacing = 3,
    this.minimumLeafMarkerSpacing = 8,
    this.minimumMergeMarkerSpacing = 6,
    this.minimumLabelSpacing = 24,
  }) : assert(branchWidth > 0),
       assert(baselineWidth > 0),
       assert(tickWidth > 0),
       assert(tickLength >= 0),
       assert(elbowRadius >= 0),
       assert(leafMarkerRadius > 0),
       assert(leafMarkerBorderWidth >= 0),
       assert(mergeMarkerRadius > 0),
       assert(mergeMarkerBorderWidth >= 0),
       assert(labelFontSize > 0),
       assert(labelPadding >= 0),
       assert(labelRadius >= 0),
       assert(labelOffset >= 0),
       assert(maxLabelCharacters > 0),
       assert(minimumBranchLength >= 0),
       assert(minimumLeafGuideSpacing >= 0),
       assert(minimumLeafMarkerSpacing >= 0),
       assert(minimumMergeMarkerSpacing >= 0),
       assert(minimumLabelSpacing >= 0),
       assert(
         mergeDistanceFractionDigits >= 0 && mergeDistanceFractionDigits <= 6,
       );

  /// Branch colour, or `null` to derive it from the active theme.
  final Color? branchColor;

  /// Width of hierarchy branches in logical pixels.
  final double branchWidth;

  /// Cap applied at open branch ends.
  final StrokeCap branchCap;

  /// Join applied where branch segments meet.
  final StrokeJoin branchJoin;

  /// Leaf-baseline colour, or `null` for a quiet branch-colour derivative.
  final Color? baselineColor;

  /// Width of the leaf baseline in logical pixels.
  final double baselineWidth;

  /// Whether to paint the quiet line shared by all accepted leaves.
  final bool showLeafBaseline;

  /// Leaf-tick colour, or `null` to inherit the resolved baseline colour.
  final Color? tickColor;

  /// Width of leaf ticks in logical pixels.
  final double tickWidth;

  /// Length of each leaf tick in logical pixels.
  final double tickLength;

  /// Whether to paint one alignment tick per accepted leaf.
  final bool showLeafTicks;

  /// Presentation-only radius used to soften orthogonal branch elbows.
  ///
  /// The value is clamped to the available adjacent segment lengths and never
  /// changes hierarchy geometry or accepted leaf order.
  final double elbowRadius;

  /// Whether to paint one marker at every source leaf.
  final bool showLeafMarkers;

  /// Leaf-marker colour, or `null` to inherit the resolved branch colour.
  final Color? leafMarkerColor;

  /// Leaf-marker radius in logical pixels.
  final double leafMarkerRadius;

  /// Shape painted at every enabled source leaf.
  final HeatmapDendrogramMarkerShape leafMarkerShape;

  /// Whether enabled leaf markers are solid or hollow.
  final HeatmapDendrogramMarkerFill leafMarkerFill;

  /// Leaf-marker border colour, or `null` to inherit the branch colour.
  final Color? leafMarkerBorderColor;

  /// Leaf-marker border width in logical pixels.
  final double leafMarkerBorderWidth;

  /// Whether to paint one marker at every hierarchy merge.
  final bool showMergeMarkers;

  /// Merge-marker colour, or `null` to inherit the resolved branch colour.
  final Color? mergeMarkerColor;

  /// Merge-marker radius in logical pixels.
  final double mergeMarkerRadius;

  /// Shape painted at every enabled hierarchy merge.
  final HeatmapDendrogramMarkerShape mergeMarkerShape;

  /// Whether enabled merge markers are solid or hollow.
  final HeatmapDendrogramMarkerFill mergeMarkerFill;

  /// Merge-marker border colour, or `null` to inherit the branch colour.
  final Color? mergeMarkerBorderColor;

  /// Merge-marker border width in logical pixels.
  final double mergeMarkerBorderWidth;

  /// Whether to paint source-category labels at leaf anchors.
  final bool showLeafLabels;

  /// Whether to paint original clustering distances at merge anchors.
  final bool showMergeDistanceLabels;

  /// Label foreground colour, or `null` for the active theme foreground.
  final Color? labelColor;

  /// Label background colour, or `null` for a theme-derived surface.
  final Color? labelBackgroundColor;

  /// Label font size in logical pixels.
  final double labelFontSize;

  /// Horizontal and vertical inset inside each label background.
  final double labelPadding;

  /// Corner radius of each label background.
  final double labelRadius;

  /// Gap between a node marker and its label.
  final double labelOffset;

  /// Deterministic label sampling policy.
  final HeatmapDendrogramLabelDensity labelDensity;

  /// Orientation-aware side on which labels are initially placed.
  ///
  /// Every label is shifted back inside the dendrogram canvas after placement.
  final HeatmapDendrogramLabelPlacement labelPlacement;

  /// Maximum source characters retained before an ellipsis is appended.
  final int maxLabelCharacters;

  /// Decimal places used by merge-distance labels.
  final int mergeDistanceFractionDigits;

  /// Whether screen-space level-of-detail suppression is active.
  ///
  /// Automatic LOD never enables presentation disabled by another style flag.
  final HeatmapDendrogramLevelOfDetailMode levelOfDetailMode;

  /// Minimum projected branch length retained in automatic mode.
  final double minimumBranchLength;

  /// Minimum category-axis spacing for per-leaf ticks in automatic mode.
  final double minimumLeafGuideSpacing;

  /// Minimum category-axis spacing for per-leaf markers in automatic mode.
  final double minimumLeafMarkerSpacing;

  /// Minimum screen-space separation between merge markers in automatic mode.
  final double minimumMergeMarkerSpacing;

  /// Minimum category-axis spacing allocated to labels in automatic mode.
  final double minimumLabelSpacing;

  /// Restores a style retained in JSON-safe chart metadata.
  factory HeatmapDendrogramStyle.fromJson(Map<String, dynamic> json) {
    double number(String key, double fallback) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is! num) {
        throw FormatException('Invalid Heatmap dendrogram style $key');
      }
      return value.toDouble();
    }

    bool boolean(String key, bool fallback) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is! bool) {
        throw FormatException('Invalid Heatmap dendrogram style $key');
      }
      return value;
    }

    Color? color(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! int) {
        throw FormatException('Invalid Heatmap dendrogram style $key');
      }
      return Color(value);
    }

    T enumValue<T extends Enum>(String key, List<T> values, T fallback) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is! String) {
        throw FormatException('Invalid Heatmap dendrogram style $key');
      }
      for (final candidate in values) {
        if (candidate.name == value) return candidate;
      }
      throw FormatException('Invalid Heatmap dendrogram style $key');
    }

    final branchWidth = number('branchWidth', 1.5);
    final baselineWidth = number('baselineWidth', 1);
    final tickWidth = number('tickWidth', 1);
    final tickLength = number('tickLength', 5);
    final elbowRadius = number('elbowRadius', 0);
    final leafMarkerRadius = number('leafMarkerRadius', 3);
    final leafMarkerBorderWidth = number('leafMarkerBorderWidth', 1);
    final mergeMarkerRadius = number('mergeMarkerRadius', 3.5);
    final mergeMarkerBorderWidth = number('mergeMarkerBorderWidth', 1);
    final labelFontSize = number('labelFontSize', 10);
    final labelPadding = number('labelPadding', 2);
    final labelRadius = number('labelRadius', 3);
    final labelOffset = number('labelOffset', 4);
    final maxLabelCharacters = number('maxLabelCharacters', 14);
    final mergeDistanceFractionDigits = number(
      'mergeDistanceFractionDigits',
      2,
    );
    final minimumBranchLength = number('minimumBranchLength', 0.75);
    final minimumLeafGuideSpacing = number('minimumLeafGuideSpacing', 3);
    final minimumLeafMarkerSpacing = number('minimumLeafMarkerSpacing', 8);
    final minimumMergeMarkerSpacing = number('minimumMergeMarkerSpacing', 6);
    final minimumLabelSpacing = number('minimumLabelSpacing', 24);
    if (!branchWidth.isFinite ||
        branchWidth <= 0 ||
        !baselineWidth.isFinite ||
        baselineWidth <= 0 ||
        !tickWidth.isFinite ||
        tickWidth <= 0 ||
        !tickLength.isFinite ||
        tickLength < 0 ||
        !elbowRadius.isFinite ||
        elbowRadius < 0 ||
        !leafMarkerRadius.isFinite ||
        leafMarkerRadius <= 0 ||
        !leafMarkerBorderWidth.isFinite ||
        leafMarkerBorderWidth < 0 ||
        !mergeMarkerRadius.isFinite ||
        mergeMarkerRadius <= 0 ||
        !mergeMarkerBorderWidth.isFinite ||
        mergeMarkerBorderWidth < 0 ||
        !labelFontSize.isFinite ||
        labelFontSize <= 0 ||
        !labelPadding.isFinite ||
        labelPadding < 0 ||
        !labelRadius.isFinite ||
        labelRadius < 0 ||
        !labelOffset.isFinite ||
        labelOffset < 0 ||
        maxLabelCharacters != maxLabelCharacters.roundToDouble() ||
        maxLabelCharacters <= 0 ||
        mergeDistanceFractionDigits !=
            mergeDistanceFractionDigits.roundToDouble() ||
        mergeDistanceFractionDigits < 0 ||
        mergeDistanceFractionDigits > 6 ||
        !minimumBranchLength.isFinite ||
        minimumBranchLength < 0 ||
        !minimumLeafGuideSpacing.isFinite ||
        minimumLeafGuideSpacing < 0 ||
        !minimumLeafMarkerSpacing.isFinite ||
        minimumLeafMarkerSpacing < 0 ||
        !minimumMergeMarkerSpacing.isFinite ||
        minimumMergeMarkerSpacing < 0 ||
        !minimumLabelSpacing.isFinite ||
        minimumLabelSpacing < 0) {
      throw const FormatException('Invalid Heatmap dendrogram style values');
    }
    return HeatmapDendrogramStyle(
      branchColor: color('branchColor'),
      branchWidth: branchWidth,
      branchCap: enumValue('branchCap', StrokeCap.values, StrokeCap.round),
      branchJoin: enumValue('branchJoin', StrokeJoin.values, StrokeJoin.round),
      baselineColor: color('baselineColor'),
      baselineWidth: baselineWidth,
      showLeafBaseline: boolean('showLeafBaseline', true),
      tickColor: color('tickColor'),
      tickWidth: tickWidth,
      tickLength: tickLength,
      showLeafTicks: boolean('showLeafTicks', true),
      elbowRadius: elbowRadius,
      showLeafMarkers: boolean('showLeafMarkers', false),
      leafMarkerColor: color('leafMarkerColor'),
      leafMarkerRadius: leafMarkerRadius,
      leafMarkerShape: enumValue(
        'leafMarkerShape',
        HeatmapDendrogramMarkerShape.values,
        HeatmapDendrogramMarkerShape.circle,
      ),
      leafMarkerFill: enumValue(
        'leafMarkerFill',
        HeatmapDendrogramMarkerFill.values,
        HeatmapDendrogramMarkerFill.solid,
      ),
      leafMarkerBorderColor: color('leafMarkerBorderColor'),
      leafMarkerBorderWidth: leafMarkerBorderWidth,
      showMergeMarkers: boolean('showMergeMarkers', false),
      mergeMarkerColor: color('mergeMarkerColor'),
      mergeMarkerRadius: mergeMarkerRadius,
      mergeMarkerShape: enumValue(
        'mergeMarkerShape',
        HeatmapDendrogramMarkerShape.values,
        HeatmapDendrogramMarkerShape.circle,
      ),
      mergeMarkerFill: enumValue(
        'mergeMarkerFill',
        HeatmapDendrogramMarkerFill.values,
        HeatmapDendrogramMarkerFill.solid,
      ),
      mergeMarkerBorderColor: color('mergeMarkerBorderColor'),
      mergeMarkerBorderWidth: mergeMarkerBorderWidth,
      showLeafLabels: boolean('showLeafLabels', false),
      showMergeDistanceLabels: boolean('showMergeDistanceLabels', false),
      labelColor: color('labelColor'),
      labelBackgroundColor: color('labelBackgroundColor'),
      labelFontSize: labelFontSize,
      labelPadding: labelPadding,
      labelRadius: labelRadius,
      labelOffset: labelOffset,
      labelDensity: enumValue(
        'labelDensity',
        HeatmapDendrogramLabelDensity.values,
        HeatmapDendrogramLabelDensity.balanced,
      ),
      labelPlacement: enumValue(
        'labelPlacement',
        HeatmapDendrogramLabelPlacement.values,
        HeatmapDendrogramLabelPlacement.before,
      ),
      maxLabelCharacters: maxLabelCharacters.toInt(),
      mergeDistanceFractionDigits: mergeDistanceFractionDigits.toInt(),
      levelOfDetailMode: enumValue(
        'levelOfDetailMode',
        HeatmapDendrogramLevelOfDetailMode.values,
        HeatmapDendrogramLevelOfDetailMode.automatic,
      ),
      minimumBranchLength: minimumBranchLength,
      minimumLeafGuideSpacing: minimumLeafGuideSpacing,
      minimumLeafMarkerSpacing: minimumLeafMarkerSpacing,
      minimumMergeMarkerSpacing: minimumMergeMarkerSpacing,
      minimumLabelSpacing: minimumLabelSpacing,
    );
  }

  /// JSON-safe representation suitable for portable chart metadata.
  Map<String, dynamic> toJson() => {
    if (branchColor != null) 'branchColor': branchColor!.toARGB32(),
    'branchWidth': branchWidth,
    'branchCap': branchCap.name,
    'branchJoin': branchJoin.name,
    if (baselineColor != null) 'baselineColor': baselineColor!.toARGB32(),
    'baselineWidth': baselineWidth,
    'showLeafBaseline': showLeafBaseline,
    if (tickColor != null) 'tickColor': tickColor!.toARGB32(),
    'tickWidth': tickWidth,
    'tickLength': tickLength,
    'showLeafTicks': showLeafTicks,
    'elbowRadius': elbowRadius,
    'showLeafMarkers': showLeafMarkers,
    if (leafMarkerColor != null) 'leafMarkerColor': leafMarkerColor!.toARGB32(),
    'leafMarkerRadius': leafMarkerRadius,
    'leafMarkerShape': leafMarkerShape.name,
    'leafMarkerFill': leafMarkerFill.name,
    if (leafMarkerBorderColor != null)
      'leafMarkerBorderColor': leafMarkerBorderColor!.toARGB32(),
    'leafMarkerBorderWidth': leafMarkerBorderWidth,
    'showMergeMarkers': showMergeMarkers,
    if (mergeMarkerColor != null)
      'mergeMarkerColor': mergeMarkerColor!.toARGB32(),
    'mergeMarkerRadius': mergeMarkerRadius,
    'mergeMarkerShape': mergeMarkerShape.name,
    'mergeMarkerFill': mergeMarkerFill.name,
    if (mergeMarkerBorderColor != null)
      'mergeMarkerBorderColor': mergeMarkerBorderColor!.toARGB32(),
    'mergeMarkerBorderWidth': mergeMarkerBorderWidth,
    'showLeafLabels': showLeafLabels,
    'showMergeDistanceLabels': showMergeDistanceLabels,
    if (labelColor != null) 'labelColor': labelColor!.toARGB32(),
    if (labelBackgroundColor != null)
      'labelBackgroundColor': labelBackgroundColor!.toARGB32(),
    'labelFontSize': labelFontSize,
    'labelPadding': labelPadding,
    'labelRadius': labelRadius,
    'labelOffset': labelOffset,
    'labelDensity': labelDensity.name,
    'labelPlacement': labelPlacement.name,
    'maxLabelCharacters': maxLabelCharacters,
    'mergeDistanceFractionDigits': mergeDistanceFractionDigits,
    'levelOfDetailMode': levelOfDetailMode.name,
    'minimumBranchLength': minimumBranchLength,
    'minimumLeafGuideSpacing': minimumLeafGuideSpacing,
    'minimumLeafMarkerSpacing': minimumLeafMarkerSpacing,
    'minimumMergeMarkerSpacing': minimumMergeMarkerSpacing,
    'minimumLabelSpacing': minimumLabelSpacing,
  };

  /// Metadata key scoped to the corresponding row or column hierarchy.
  Map<String, dynamic> metadataFor(HeatmapDendrogramAxis axis) => {
    'heatmapDendrogram${axis == HeatmapDendrogramAxis.rows ? 'Row' : 'Column'}Style':
        toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapDendrogramStyle &&
          other.branchColor == branchColor &&
          other.branchWidth == branchWidth &&
          other.branchCap == branchCap &&
          other.branchJoin == branchJoin &&
          other.baselineColor == baselineColor &&
          other.baselineWidth == baselineWidth &&
          other.showLeafBaseline == showLeafBaseline &&
          other.tickColor == tickColor &&
          other.tickWidth == tickWidth &&
          other.tickLength == tickLength &&
          other.showLeafTicks == showLeafTicks &&
          other.elbowRadius == elbowRadius &&
          other.showLeafMarkers == showLeafMarkers &&
          other.leafMarkerColor == leafMarkerColor &&
          other.leafMarkerRadius == leafMarkerRadius &&
          other.leafMarkerShape == leafMarkerShape &&
          other.leafMarkerFill == leafMarkerFill &&
          other.leafMarkerBorderColor == leafMarkerBorderColor &&
          other.leafMarkerBorderWidth == leafMarkerBorderWidth &&
          other.showMergeMarkers == showMergeMarkers &&
          other.mergeMarkerColor == mergeMarkerColor &&
          other.mergeMarkerRadius == mergeMarkerRadius &&
          other.mergeMarkerShape == mergeMarkerShape &&
          other.mergeMarkerFill == mergeMarkerFill &&
          other.mergeMarkerBorderColor == mergeMarkerBorderColor &&
          other.mergeMarkerBorderWidth == mergeMarkerBorderWidth &&
          other.showLeafLabels == showLeafLabels &&
          other.showMergeDistanceLabels == showMergeDistanceLabels &&
          other.labelColor == labelColor &&
          other.labelBackgroundColor == labelBackgroundColor &&
          other.labelFontSize == labelFontSize &&
          other.labelPadding == labelPadding &&
          other.labelRadius == labelRadius &&
          other.labelOffset == labelOffset &&
          other.labelDensity == labelDensity &&
          other.labelPlacement == labelPlacement &&
          other.maxLabelCharacters == maxLabelCharacters &&
          other.mergeDistanceFractionDigits == mergeDistanceFractionDigits &&
          other.levelOfDetailMode == levelOfDetailMode &&
          other.minimumBranchLength == minimumBranchLength &&
          other.minimumLeafGuideSpacing == minimumLeafGuideSpacing &&
          other.minimumLeafMarkerSpacing == minimumLeafMarkerSpacing &&
          other.minimumMergeMarkerSpacing == minimumMergeMarkerSpacing &&
          other.minimumLabelSpacing == minimumLabelSpacing;

  @override
  int get hashCode => Object.hashAll([
    branchColor,
    branchWidth,
    branchCap,
    branchJoin,
    baselineColor,
    baselineWidth,
    showLeafBaseline,
    tickColor,
    tickWidth,
    tickLength,
    showLeafTicks,
    elbowRadius,
    showLeafMarkers,
    leafMarkerColor,
    leafMarkerRadius,
    leafMarkerShape,
    leafMarkerFill,
    leafMarkerBorderColor,
    leafMarkerBorderWidth,
    showMergeMarkers,
    mergeMarkerColor,
    mergeMarkerRadius,
    mergeMarkerShape,
    mergeMarkerFill,
    mergeMarkerBorderColor,
    mergeMarkerBorderWidth,
    showLeafLabels,
    showMergeDistanceLabels,
    labelColor,
    labelBackgroundColor,
    labelFontSize,
    labelPadding,
    labelRadius,
    labelOffset,
    labelDensity,
    labelPlacement,
    maxLabelCharacters,
    mergeDistanceFractionDigits,
    levelOfDetailMode,
    minimumBranchLength,
    minimumLeafGuideSpacing,
    minimumLeafMarkerSpacing,
    minimumMergeMarkerSpacing,
    minimumLabelSpacing,
  ]);
}

/// Paints portable Heatmap cluster hierarchy geometry.
///
/// This widget does not cluster data. It renders the normalized branch segments
/// in [data], allowing applications to compose row and column dendrograms around
/// the native Heatmap.
class HeatmapDendrogram extends StatelessWidget {
  const HeatmapDendrogram({
    super.key,
    required this.data,
    this.style = const HeatmapDendrogramStyle(),
    this.padding = EdgeInsets.zero,
    this.semanticLabel,
  });

  final HeatmapDendrogramData data;
  final HeatmapDendrogramStyle style;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final branchColor =
        style.branchColor ??
        Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.72);
    final baselineColor =
        style.baselineColor ?? branchColor.withValues(alpha: 0.24);
    final tickColor = style.tickColor ?? baselineColor;
    final leafMarkerColor = style.leafMarkerColor ?? branchColor;
    final leafMarkerBorderColor = style.leafMarkerBorderColor ?? branchColor;
    final mergeMarkerColor = style.mergeMarkerColor ?? branchColor;
    final mergeMarkerBorderColor = style.mergeMarkerBorderColor ?? branchColor;
    final labelColor =
        style.labelColor ?? Theme.of(context).colorScheme.onSurface;
    final labelBackgroundColor =
        style.labelBackgroundColor ??
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.88);
    final label =
        semanticLabel ??
        '${data.axis == HeatmapDendrogramAxis.rows ? 'Row' : 'Column'} '
            'dendrogram, ${data.labels.length} categories';
    return Semantics(
      container: true,
      image: true,
      label: label,
      child: Padding(
        padding: padding,
        child: CustomPaint(
          key: ValueKey('heatmap-${data.axis.name}-dendrogram-canvas'),
          painter: _HeatmapDendrogramPainter(
            data: data,
            style: style,
            branchColor: branchColor,
            baselineColor: baselineColor,
            tickColor: tickColor,
            leafMarkerColor: leafMarkerColor,
            leafMarkerBorderColor: leafMarkerBorderColor,
            mergeMarkerColor: mergeMarkerColor,
            mergeMarkerBorderColor: mergeMarkerBorderColor,
            labelColor: labelColor,
            labelBackgroundColor: labelBackgroundColor,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

final class _HeatmapDendrogramPainter extends CustomPainter {
  _HeatmapDendrogramPainter({
    required this.data,
    required this.style,
    required this.branchColor,
    required this.baselineColor,
    required this.tickColor,
    required this.leafMarkerColor,
    required this.leafMarkerBorderColor,
    required this.mergeMarkerColor,
    required this.mergeMarkerBorderColor,
    required this.labelColor,
    required this.labelBackgroundColor,
  });

  final HeatmapDendrogramData data;
  final HeatmapDendrogramStyle style;
  final Color branchColor;
  final Color baselineColor;
  final Color tickColor;
  final Color leafMarkerColor;
  final Color leafMarkerBorderColor;
  final Color mergeMarkerColor;
  final Color mergeMarkerBorderColor;
  final Color labelColor;
  final Color labelBackgroundColor;
  Size? _cachedBranchPathSize;
  Path? _cachedBranchPath;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (style.showLeafBaseline || style.showLeafTicks) {
      _paintLeafGuides(canvas, size);
    }
    if (data.segments.isNotEmpty) {
      final paint = Paint()
        ..color = branchColor
        ..strokeWidth = style.branchWidth
        ..strokeCap = style.branchCap
        ..strokeJoin = style.branchJoin
        ..style = PaintingStyle.stroke;
      canvas.drawPath(_branchPath(size), paint);
    }
    _paintMarkers(canvas, size);
    _paintLabels(canvas, size);
  }

  void _paintMarkers(Canvas canvas, Size size) {
    if (!style.showLeafMarkers && !style.showMergeMarkers) return;
    final leafSpacing = _leafSpacing(size);
    if (style.showLeafMarkers &&
        (!_usesAutomaticLevelOfDetail ||
            leafSpacing >= style.minimumLeafMarkerSpacing)) {
      final leaves = data.nodes.where((node) => node.isLeaf).toList()
        ..sort((a, b) => a.category.compareTo(b.category));
      for (final node in leaves) {
        _paintLeafMarker(
          canvas,
          size,
          center: _offset(
            size,
            category: node.category,
            distance: node.distance,
          ),
          radius: style.leafMarkerRadius,
          shape: style.leafMarkerShape,
          fill: style.leafMarkerFill,
          fillColor: leafMarkerColor,
          borderColor: leafMarkerBorderColor,
          borderWidth: style.leafMarkerBorderWidth,
        );
      }
    }
    if (style.showMergeMarkers) {
      final merges = data.nodes.where((node) => !node.isLeaf).toList()
        ..sort((a, b) {
          final distance = b.distance.compareTo(a.distance);
          return distance != 0 ? distance : a.category.compareTo(b.category);
        });
      final occupied = _ScreenSpaceIndex(
        _usesAutomaticLevelOfDetail ? style.minimumMergeMarkerSpacing : 0,
      );
      for (final node in merges) {
        final center = _offset(
          size,
          category: node.category,
          distance: node.distance,
        );
        if (!occupied.accept(center)) continue;
        _paintMarker(
          canvas,
          center: center,
          radius: style.mergeMarkerRadius,
          shape: style.mergeMarkerShape,
          fill: style.mergeMarkerFill,
          fillColor: mergeMarkerColor,
          borderColor: mergeMarkerBorderColor,
          borderWidth: style.mergeMarkerBorderWidth,
        );
      }
    }
  }

  void _paintLeafMarker(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required HeatmapDendrogramMarkerShape shape,
    required HeatmapDendrogramMarkerFill fill,
    required Color fillColor,
    required Color borderColor,
    required double borderWidth,
  }) {
    canvas.save();
    canvas.clipRect(switch (data.axis) {
      HeatmapDendrogramAxis.columns => Rect.fromLTRB(
        0,
        0,
        size.width,
        center.dy,
      ),
      HeatmapDendrogramAxis.rows => Rect.fromLTRB(0, 0, center.dx, size.height),
    }, doAntiAlias: false);
    _paintMarker(
      canvas,
      center: center,
      radius: radius,
      shape: shape,
      fill: fill,
      fillColor: fillColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
    canvas.restore();
  }

  void _paintMarker(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required HeatmapDendrogramMarkerShape shape,
    required HeatmapDendrogramMarkerFill fill,
    required Color fillColor,
    required Color borderColor,
    required double borderWidth,
  }) {
    final path = switch (shape) {
      HeatmapDendrogramMarkerShape.circle =>
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      HeatmapDendrogramMarkerShape.square =>
        Path()..addRect(Rect.fromCircle(center: center, radius: radius)),
      HeatmapDendrogramMarkerShape.diamond =>
        Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close(),
      HeatmapDendrogramMarkerShape.triangle =>
        Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy + radius)
          ..close(),
    };
    if (fill == HeatmapDendrogramMarkerFill.solid) {
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }
    if (borderWidth > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _paintLabels(Canvas canvas, Size size) {
    if (!style.showLeafLabels && !style.showMergeDistanceLabels) return;
    if (style.showLeafLabels) {
      final leaves = data.nodes.where((node) => node.isLeaf).toList()
        ..sort((a, b) => a.category.compareTo(b.category));
      for (final node in _sampleLabels(leaves, size)) {
        _paintBoundedLabel(
          canvas,
          size,
          anchor: _offset(
            size,
            category: node.category,
            distance: node.distance,
          ),
          markerRadius: style.showLeafMarkers ? style.leafMarkerRadius : 0,
          text: data.sourceLabels[node.leafIndex!],
        );
      }
    }
    if (style.showMergeDistanceLabels) {
      final merges = data.nodes.where((node) => !node.isLeaf).toList()
        ..sort((a, b) {
          final distance = b.distance.compareTo(a.distance);
          return distance != 0 ? distance : a.category.compareTo(b.category);
        });
      for (final node in _sampleLabels(merges, size)) {
        _paintBoundedLabel(
          canvas,
          size,
          anchor: _offset(
            size,
            category: node.category,
            distance: node.distance,
          ),
          markerRadius: style.showMergeMarkers ? style.mergeMarkerRadius : 0,
          text: node.mergeDistance.toStringAsFixed(
            style.mergeDistanceFractionDigits,
          ),
        );
      }
    }
  }

  List<HeatmapDendrogramNode> _sampleLabels(
    List<HeatmapDendrogramNode> candidates,
    Size size,
  ) {
    var limit = switch (style.labelDensity) {
      HeatmapDendrogramLabelDensity.all => candidates.length,
      HeatmapDendrogramLabelDensity.balanced => 12,
      HeatmapDendrogramLabelDensity.sparse => 6,
    };
    if (_usesAutomaticLevelOfDetail && style.minimumLabelSpacing > 0) {
      final available = _categoryExtent(size);
      final screenLimit = (available / style.minimumLabelSpacing).floor();
      if (screenLimit < limit) limit = screenLimit;
    }
    if (limit <= 0) return const [];
    if (candidates.length <= limit || limit == 0) return candidates;
    if (limit == 1) return [candidates.first];
    return [
      for (var index = 0; index < limit; index++)
        candidates[(index * (candidates.length - 1) / (limit - 1)).round()],
    ];
  }

  void _paintBoundedLabel(
    Canvas canvas,
    Size size, {
    required Offset anchor,
    required double markerRadius,
    required String text,
  }) {
    final truncated = text.length <= style.maxLabelCharacters
        ? text
        : '${text.substring(0, style.maxLabelCharacters - 1)}…';
    final textPainter = TextPainter(
      text: TextSpan(
        text: truncated,
        style: TextStyle(
          color: labelColor,
          fontSize: style.labelFontSize,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: size.shortestSide * 0.72);
    final boxSize = Size(
      textPainter.width + style.labelPadding * 2,
      textPainter.height + style.labelPadding * 2,
    );
    final gap = markerRadius + style.labelOffset;
    var topLeft = switch (data.axis) {
      HeatmapDendrogramAxis.columns =>
        style.labelPlacement == HeatmapDendrogramLabelPlacement.before
            ? Offset(
                anchor.dx - boxSize.width / 2,
                anchor.dy - gap - boxSize.height,
              )
            : Offset(anchor.dx - boxSize.width / 2, anchor.dy + gap),
      HeatmapDendrogramAxis.rows =>
        style.labelPlacement == HeatmapDendrogramLabelPlacement.before
            ? Offset(
                anchor.dx - gap - boxSize.width,
                anchor.dy - boxSize.height / 2,
              )
            : Offset(anchor.dx + gap, anchor.dy - boxSize.height / 2),
    };
    const inset = 1.0;
    topLeft = Offset(
      topLeft.dx.clamp(
        inset,
        (size.width - boxSize.width - inset).clamp(inset, double.infinity),
      ),
      topLeft.dy.clamp(
        inset,
        (size.height - boxSize.height - inset).clamp(inset, double.infinity),
      ),
    );
    final rect = topLeft & boxSize;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style.labelRadius)),
      Paint()
        ..color = labelBackgroundColor
        ..style = PaintingStyle.fill,
    );
    textPainter.paint(
      canvas,
      topLeft + Offset(style.labelPadding, style.labelPadding),
    );
  }

  HeatmapDendrogramSegment? _segmentWithSuffix(
    List<HeatmapDendrogramSegment> segments,
    String suffix,
  ) {
    for (final segment in segments) {
      if (segment.id.endsWith(suffix)) return segment;
    }
    return null;
  }

  Path _branchPath(Size size) {
    if (_cachedBranchPathSize == size && _cachedBranchPath != null) {
      return _cachedBranchPath!;
    }
    final path = Path();
    final segmentsByNode = <String, List<HeatmapDendrogramSegment>>{};
    for (final segment in data.segments) {
      (segmentsByNode[segment.nodeId] ??= []).add(segment);
    }
    for (final segments in segmentsByNode.values) {
      final left = _segmentWithSuffix(segments, ':left');
      final right = _segmentWithSuffix(segments, ':right');
      final join = _segmentWithSuffix(segments, ':join');
      if (left != null && right != null && join != null) {
        if (_branchIsVisible(size, [left, join, right])) {
          _addBranchPath(path, size, left: left, right: right, join: join);
        }
        continue;
      }
      for (final segment in segments) {
        if (_segmentIsVisible(size, segment)) {
          _addSegment(path, size, segment);
        }
      }
    }
    _cachedBranchPathSize = size;
    _cachedBranchPath = path;
    return path;
  }

  bool _branchIsVisible(Size size, List<HeatmapDendrogramSegment> segments) {
    if (!_usesAutomaticLevelOfDetail || style.minimumBranchLength == 0) {
      return true;
    }
    return segments.any((segment) => _segmentIsVisible(size, segment));
  }

  bool _segmentIsVisible(Size size, HeatmapDendrogramSegment segment) {
    if (!_usesAutomaticLevelOfDetail || style.minimumBranchLength == 0) {
      return true;
    }
    final start = _offset(
      size,
      category: segment.startCategory,
      distance: segment.startDistance,
    );
    final end = _offset(
      size,
      category: segment.endCategory,
      distance: segment.endDistance,
    );
    return (end - start).distance >= style.minimumBranchLength;
  }

  void _addSegment(Path path, Size size, HeatmapDendrogramSegment segment) {
    final start = _offset(
      size,
      category: segment.startCategory,
      distance: segment.startDistance,
    );
    final end = _offset(
      size,
      category: segment.endCategory,
      distance: segment.endDistance,
    );
    path
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
  }

  void _addBranchPath(
    Path path,
    Size size, {
    required HeatmapDendrogramSegment left,
    required HeatmapDendrogramSegment right,
    required HeatmapDendrogramSegment join,
  }) {
    final start = _offset(
      size,
      category: left.startCategory,
      distance: left.startDistance,
    );
    final firstElbow = _offset(
      size,
      category: join.startCategory,
      distance: join.startDistance,
    );
    final secondElbow = _offset(
      size,
      category: join.endCategory,
      distance: join.endDistance,
    );
    final end = _offset(
      size,
      category: right.startCategory,
      distance: right.startDistance,
    );
    if (style.elbowRadius == 0) {
      path
        ..moveTo(start.dx, start.dy)
        ..lineTo(firstElbow.dx, firstElbow.dy)
        ..lineTo(secondElbow.dx, secondElbow.dy)
        ..lineTo(end.dx, end.dy);
      return;
    }
    final firstRadius = style.elbowRadius
        .clamp(
          0.0,
          _shorterDistance(start, firstElbow, firstElbow, secondElbow) / 2,
        )
        .toDouble();
    final secondRadius = style.elbowRadius
        .clamp(
          0.0,
          _shorterDistance(firstElbow, secondElbow, secondElbow, end) / 2,
        )
        .toDouble();
    final beforeFirst = _pointTowards(firstElbow, start, firstRadius);
    final afterFirst = _pointTowards(firstElbow, secondElbow, firstRadius);
    final beforeSecond = _pointTowards(secondElbow, firstElbow, secondRadius);
    final afterSecond = _pointTowards(secondElbow, end, secondRadius);
    path
      ..moveTo(start.dx, start.dy)
      ..lineTo(beforeFirst.dx, beforeFirst.dy)
      ..quadraticBezierTo(
        firstElbow.dx,
        firstElbow.dy,
        afterFirst.dx,
        afterFirst.dy,
      )
      ..lineTo(beforeSecond.dx, beforeSecond.dy)
      ..quadraticBezierTo(
        secondElbow.dx,
        secondElbow.dy,
        afterSecond.dx,
        afterSecond.dy,
      )
      ..lineTo(end.dx, end.dy);
  }

  double _shorterDistance(Offset a, Offset b, Offset c, Offset d) {
    final first = (a - b).distance;
    final second = (c - d).distance;
    return first < second ? first : second;
  }

  Offset _pointTowards(Offset origin, Offset target, double distance) {
    final delta = target - origin;
    final length = delta.distance;
    if (length == 0 || distance == 0) return origin;
    return origin + delta * (distance / length);
  }

  void _paintLeafGuides(Canvas canvas, Size size) {
    final edge = _edge;
    final baselinePaint = Paint()
      ..color = baselineColor
      ..strokeWidth = style.baselineWidth
      ..strokeCap = StrokeCap.round;
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = style.tickWidth
      ..strokeCap = StrokeCap.round;
    switch (data.axis) {
      case HeatmapDendrogramAxis.columns:
        final leafY = size.height - edge;
        if (style.showLeafBaseline) {
          canvas.drawLine(
            Offset(edge, leafY),
            Offset(size.width - edge, leafY),
            baselinePaint,
          );
        }
        if (!style.showLeafTicks ||
            (_usesAutomaticLevelOfDetail &&
                _leafSpacing(size) < style.minimumLeafGuideSpacing)) {
          return;
        }
        for (var index = 0; index < data.labels.length; index++) {
          final category = (index + 0.5) / data.labels.length;
          final x = edge + category * (size.width - 2 * edge);
          canvas.drawLine(
            Offset(x, leafY - style.tickLength),
            Offset(x, leafY),
            tickPaint,
          );
        }
      case HeatmapDendrogramAxis.rows:
        final leafX = size.width - edge;
        if (style.showLeafBaseline) {
          canvas.drawLine(
            Offset(leafX, edge),
            Offset(leafX, size.height - edge),
            baselinePaint,
          );
        }
        if (!style.showLeafTicks ||
            (_usesAutomaticLevelOfDetail &&
                _leafSpacing(size) < style.minimumLeafGuideSpacing)) {
          return;
        }
        for (var index = 0; index < data.labels.length; index++) {
          final category = (index + 0.5) / data.labels.length;
          final y = edge + (1 - category) * (size.height - 2 * edge);
          canvas.drawLine(
            Offset(leafX - style.tickLength, y),
            Offset(leafX, y),
            tickPaint,
          );
        }
    }
  }

  double get _edge {
    var width = style.branchWidth;
    if (style.showLeafBaseline && style.baselineWidth > width) {
      width = style.baselineWidth;
    }
    if (style.showLeafTicks && style.tickWidth > width) {
      width = style.tickWidth;
    }
    return width / 2;
  }

  bool get _usesAutomaticLevelOfDetail =>
      style.levelOfDetailMode == HeatmapDendrogramLevelOfDetailMode.automatic;

  double _categoryExtent(Size size) => switch (data.axis) {
    HeatmapDendrogramAxis.columns => size.width - 2 * _edge,
    HeatmapDendrogramAxis.rows => size.height - 2 * _edge,
  };

  double _leafSpacing(Size size) =>
      data.labels.isEmpty ? 0 : _categoryExtent(size) / data.labels.length;

  Offset _offset(
    Size size, {
    required double category,
    required double distance,
  }) {
    final edge = _edge;
    final width = size.width - 2 * edge;
    final height = size.height - 2 * edge;
    return switch (data.axis) {
      HeatmapDendrogramAxis.columns => Offset(
        edge + category * width,
        edge + (1 - distance) * height,
      ),
      HeatmapDendrogramAxis.rows => Offset(
        edge + (1 - distance) * width,
        edge + (1 - category) * height,
      ),
    };
  }

  @override
  bool shouldRepaint(_HeatmapDendrogramPainter oldDelegate) =>
      oldDelegate.data != data ||
      oldDelegate.style != style ||
      oldDelegate.branchColor != branchColor ||
      oldDelegate.baselineColor != baselineColor ||
      oldDelegate.tickColor != tickColor ||
      oldDelegate.leafMarkerColor != leafMarkerColor ||
      oldDelegate.leafMarkerBorderColor != leafMarkerBorderColor ||
      oldDelegate.mergeMarkerColor != mergeMarkerColor ||
      oldDelegate.mergeMarkerBorderColor != mergeMarkerBorderColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.labelBackgroundColor != labelBackgroundColor;
}

final class _ScreenSpaceIndex {
  _ScreenSpaceIndex(this.spacing);

  final double spacing;
  final Map<(int, int), List<Offset>> _occupied = {};

  bool accept(Offset point) {
    if (spacing <= 0) return true;
    final x = (point.dx / spacing).floor();
    final y = (point.dy / spacing).floor();
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final points = _occupied[(x + dx, y + dy)];
        if (points != null &&
            points.any((candidate) => (candidate - point).distance < spacing)) {
          return false;
        }
      }
    }
    (_occupied[(x, y)] ??= []).add(point);
    return true;
  }
}
