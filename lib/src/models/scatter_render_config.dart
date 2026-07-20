// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

/// Rendering strategy for a Scatter series.
///
/// Additional dense-data strategies are introduced as their geometry,
/// interaction, artifact, and Workbench contracts become complete. Keeping
/// this explicit prevents dense rendering from being inferred from point
/// count, which would make the same document change appearance by viewport.
enum ScatterRenderMode {
  /// Render every visible source observation as its own marker.
  points,

  /// Aggregate nearby visible observations into deterministic screen-space
  /// clusters while retaining the raw source points in the document.
  clusters,

  /// Aggregate visible observations into a fixed rectangular screen grid.
  rectangularBins,

  /// Aggregate visible observations into a fixed flat-top hexagonal grid.
  hexbin,

  /// Estimate a deterministic screen-space density field and draw isolines.
  density,
}

/// Statistic encoded by a rectangular or hexagonal Scatter bin.
enum ScatterBinAggregate {
  /// Number of source observations in the bin.
  count,

  /// Sum of the available values selected by [ScatterBinConfig.valueSource].
  sum,

  /// Arithmetic mean of the available selected values.
  mean,

  /// Smallest available selected value.
  minimum,

  /// Largest available selected value.
  maximum,

  /// Bin observation count divided by all visible source observations.
  proportion,
}

/// Numeric point field consumed by non-count bin aggregates.
enum ScatterBinValueSource { x, y, magnitude, colorValue, opacityValue }

/// Screen-space layout and presentation for [ScatterRenderMode.clusters].
///
/// Clustering is performed in logical pixels after the active data transform,
/// so zooming naturally reveals detail without mutating the source series.
class ScatterClusterConfig {
  const ScatterClusterConfig({
    this.cellSize = 40,
    this.minimumPointCount = 2,
    this.minimumRadius = 8,
    this.maximumRadius = 24,
    this.showCountLabels = true,
    this.labelMinimumPointCount = 2,
    this.showZones = false,
    this.zoneOpacity = 0.08,
    this.drillOnTap = true,
    this.drillPadding = 0.18,
  }) : assert(cellSize >= 8 && cellSize <= 256),
       assert(minimumPointCount >= 2),
       assert(minimumRadius > 0 && minimumRadius <= maximumRadius),
       assert(maximumRadius <= 128),
       assert(labelMinimumPointCount >= 2),
       assert(zoneOpacity >= 0 && zoneOpacity <= 1),
       assert(drillPadding >= 0 && drillPadding <= 1);

  /// Width and height of one deterministic plot-space aggregation cell.
  final double cellSize;

  /// Number of observations required before a cell becomes a cluster.
  final int minimumPointCount;

  /// Radius assigned to the smallest qualifying cluster.
  final double minimumRadius;

  /// Radius assigned to the largest visible cluster.
  final double maximumRadius;

  /// Whether qualifying clusters display their observation count.
  final bool showCountLabels;

  /// Smallest cluster count that receives an on-marker label.
  final int labelMinimumPointCount;

  /// Whether to paint the screen-space extent represented by each cluster.
  ///
  /// Zones sit behind cluster markers and make dense aggregation boundaries
  /// inspectable without replacing the source points or chart viewport.
  final bool showZones;

  /// Fill opacity used by cluster zones.
  final double zoneOpacity;

  /// Whether activating an aggregate cluster narrows the existing viewport to
  /// the raw observations represented by that cluster.
  final bool drillOnTap;

  /// Fractional data-space padding added around drill-to-cluster bounds.
  final double drillPadding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterClusterConfig &&
          other.cellSize == cellSize &&
          other.minimumPointCount == minimumPointCount &&
          other.minimumRadius == minimumRadius &&
          other.maximumRadius == maximumRadius &&
          other.showCountLabels == showCountLabels &&
          other.labelMinimumPointCount == labelMinimumPointCount &&
          other.showZones == showZones &&
          other.zoneOpacity == zoneOpacity &&
          other.drillOnTap == drillOnTap &&
          other.drillPadding == drillPadding;

  @override
  int get hashCode => Object.hash(
    cellSize,
    minimumPointCount,
    minimumRadius,
    maximumRadius,
    showCountLabels,
    labelMinimumPointCount,
    showZones,
    zoneOpacity,
    drillOnTap,
    drillPadding,
  );

  @override
  String toString() =>
      'ScatterClusterConfig(cellSize: $cellSize, minimumPointCount: '
      '$minimumPointCount, minimumRadius: $minimumRadius, maximumRadius: '
      '$maximumRadius, showCountLabels: $showCountLabels, '
      'labelMinimumPointCount: $labelMinimumPointCount, showZones: '
      '$showZones, zoneOpacity: $zoneOpacity, drillOnTap: $drillOnTap, '
      'drillPadding: $drillPadding)';
}

/// Screen-space layout and presentation for rectangular and hexagonal bins.
///
/// Each occupied bin represents one or more raw observations. The source
/// series remains unchanged, and every bin retains the represented source
/// indices for tooltips, selection, table projection, and callbacks.
class ScatterBinConfig {
  const ScatterBinConfig({
    this.cellSize = 36,
    this.gap = 1,
    this.minimumPointCount = 1,
    this.minimumOpacity = 0.2,
    this.maximumOpacity = 0.95,
    this.aggregate = ScatterBinAggregate.count,
    this.valueSource = ScatterBinValueSource.y,
    this.showLabels = false,
    this.labelMinimumPointCount = 10,
  }) : assert(cellSize >= 12 && cellSize <= 256),
       assert(gap >= 0 && gap <= 16),
       assert(minimumPointCount >= 1),
       assert(minimumOpacity >= 0 && minimumOpacity <= 1),
       assert(maximumOpacity >= minimumOpacity && maximumOpacity <= 1),
       assert(labelMinimumPointCount >= 1);

  /// Rectangular cell width or flat-top hexagon diameter in logical pixels.
  final double cellSize;

  /// Visual separation between adjacent bins in logical pixels.
  final double gap;

  /// Observations required before an occupied cell is rendered.
  final int minimumPointCount;

  /// Fill opacity assigned to the least populated visible bin.
  final double minimumOpacity;

  /// Fill opacity assigned to the most populated visible bin.
  final double maximumOpacity;

  /// Statistic mapped to bin opacity and optional labels.
  final ScatterBinAggregate aggregate;

  /// Numeric source field used by sum, mean, minimum, and maximum.
  ///
  /// Count and proportion ignore this value. Optional point fields contribute
  /// only when they contain a finite number; bins with no usable values are
  /// omitted for value-based aggregates.
  final ScatterBinValueSource valueSource;

  /// Whether qualifying bins display their aggregate value.
  final bool showLabels;

  /// Smallest bin count that receives an on-bin label.
  final int labelMinimumPointCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterBinConfig &&
          other.cellSize == cellSize &&
          other.gap == gap &&
          other.minimumPointCount == minimumPointCount &&
          other.minimumOpacity == minimumOpacity &&
          other.maximumOpacity == maximumOpacity &&
          other.aggregate == aggregate &&
          other.valueSource == valueSource &&
          other.showLabels == showLabels &&
          other.labelMinimumPointCount == labelMinimumPointCount;

  @override
  int get hashCode => Object.hash(
    cellSize,
    gap,
    minimumPointCount,
    minimumOpacity,
    maximumOpacity,
    aggregate,
    valueSource,
    showLabels,
    labelMinimumPointCount,
  );

  @override
  String toString() =>
      'ScatterBinConfig(cellSize: $cellSize, gap: $gap, '
      'minimumPointCount: $minimumPointCount, minimumOpacity: '
      '$minimumOpacity, maximumOpacity: $maximumOpacity, '
      'aggregate: $aggregate, valueSource: $valueSource, showLabels: '
      '$showLabels, labelMinimumPointCount: '
      '$labelMinimumPointCount)';
}

/// Screen-space kernel-density and contour presentation.
///
/// Density is derived after the active chart transform, so [bandwidth] and
/// [gridCellSize] are expressed in logical pixels. The source observations
/// remain unchanged and continue to back Data, Split, Source, and callbacks.
class ScatterDensityConfig {
  const ScatterDensityConfig({
    this.gridCellSize = 8,
    this.bandwidth = 32,
    this.contourCount = 6,
    this.minimumDensity = 0.08,
    this.minimumOpacity = 0.28,
    this.maximumOpacity = 0.9,
    this.lineWidth = 1.5,
    this.showPoints = false,
  }) : assert(gridCellSize >= 4 && gridCellSize <= 64),
       assert(bandwidth >= 4 && bandwidth <= 256),
       assert(contourCount >= 2 && contourCount <= 12),
       assert(minimumDensity > 0 && minimumDensity < 1),
       assert(minimumOpacity >= 0 && minimumOpacity <= 1),
       assert(maximumOpacity >= minimumOpacity && maximumOpacity <= 1),
       assert(lineWidth > 0 && lineWidth <= 12);

  /// Spacing between density samples in logical pixels.
  final double gridCellSize;

  /// Gaussian kernel standard deviation in logical pixels.
  final double bandwidth;

  /// Number of evenly spaced relative-density isolines.
  final int contourCount;

  /// Lowest relative density included in the contour family.
  final double minimumDensity;

  /// Opacity of the outermost contour.
  final double minimumOpacity;

  /// Opacity of the innermost contour.
  final double maximumOpacity;

  /// Stroke width of every contour in logical pixels.
  final double lineWidth;

  /// Whether raw markers are painted above the contour family.
  final bool showPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterDensityConfig &&
          other.gridCellSize == gridCellSize &&
          other.bandwidth == bandwidth &&
          other.contourCount == contourCount &&
          other.minimumDensity == minimumDensity &&
          other.minimumOpacity == minimumOpacity &&
          other.maximumOpacity == maximumOpacity &&
          other.lineWidth == lineWidth &&
          other.showPoints == showPoints;

  @override
  int get hashCode => Object.hash(
    gridCellSize,
    bandwidth,
    contourCount,
    minimumDensity,
    minimumOpacity,
    maximumOpacity,
    lineWidth,
    showPoints,
  );

  @override
  String toString() =>
      'ScatterDensityConfig(gridCellSize: $gridCellSize, bandwidth: '
      '$bandwidth, contourCount: $contourCount, minimumDensity: '
      '$minimumDensity, minimumOpacity: $minimumOpacity, maximumOpacity: '
      '$maximumOpacity, lineWidth: $lineWidth, showPoints: $showPoints)';
}
