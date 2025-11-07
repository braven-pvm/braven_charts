// Copyright (c) 2025 braven_charts. All rights reserved.
// Element Data Storage for Zoom/Pan Support

import 'dart:ui';

import 'package:interaction_prototype/core/chart_element.dart';
import 'package:interaction_prototype/core/element_types.dart';

/// Stores original data coordinates alongside a rendered chart element.
///
/// This enables efficient zoom/pan by:
/// 1. Storing original data coordinates once
/// 2. Regenerating plot-space elements on transform changes
/// 3. Avoiding callback overhead or data loss
///
/// **Architecture**: When zoom/pan occurs:
/// - Original data coordinates remain unchanged
/// - ChartTransform creates new data→plot mapping
/// - Elements are regenerated from stored data
///
/// **Performance**: O(n) element regeneration on zoom/pan, where n = element count.
/// This is optimal since every element needs repositioning anyway.
class ElementData {
  /// The element type identifier for recreating the appropriate element class.
  final ChartElementType elementType;

  /// Unique identifier (passed through to regenerated element).
  final String id;

  /// Original data coordinates for series and datapoint clusters.
  ///
  /// **For Series**: List of (dataX, dataY) points defining the line.
  /// **For Datapoints**: Single point [(dataX, dataY)].
  /// **For Annotations**: null (uses dataRect instead).
  final List<Offset>? dataPoints;

  /// Original data rectangle for annotations.
  ///
  /// **For Annotations**: (dataX, dataY, dataWidth, dataHeight).
  /// **For Others**: null (uses dataPoints instead).
  final Rect? dataRect;

  /// Visual properties that don't change with transform.
  final ElementVisualProperties visualProperties;

  /// Currently rendered element (in plot space).
  ///
  /// This is regenerated whenever the transform changes.
  /// Stored here to avoid regenerating on every paint if transform hasn't changed.
  ChartElement currentElement;

  ElementData({
    required this.elementType,
    required this.id,
    this.dataPoints,
    this.dataRect,
    required this.visualProperties,
    required this.currentElement,
  }) : assert(
          (dataPoints != null) != (dataRect != null),
          'Must provide either dataPoints or dataRect, not both',
        );

  /// Creates ElementData for a series element.
  factory ElementData.series({
    required String id,
    required List<Offset> dataPoints,
    required Color color,
    required double strokeWidth,
    required ChartElement currentElement,
  }) {
    return ElementData(
      elementType: ChartElementType.series,
      id: id,
      dataPoints: dataPoints,
      visualProperties: ElementVisualProperties(
        color: color,
        strokeWidth: strokeWidth,
      ),
      currentElement: currentElement,
    );
  }

  /// Creates ElementData for a datapoint element.
  factory ElementData.datapoint({
    required String id,
    required Offset dataPoint,
    required double radius,
    required Color color,
    required ChartElement currentElement,
  }) {
    return ElementData(
      elementType: ChartElementType.datapoint,
      id: id,
      dataPoints: [dataPoint],
      visualProperties: ElementVisualProperties(
        color: color,
        radius: radius,
      ),
      currentElement: currentElement,
    );
  }

  /// Creates ElementData for an annotation element.
  factory ElementData.annotation({
    required String id,
    required Rect dataRect,
    required String text,
    required Color backgroundColor,
    required Color borderColor,
    required ChartElement currentElement,
  }) {
    return ElementData(
      elementType: ChartElementType.annotation,
      id: id,
      dataRect: dataRect,
      visualProperties: ElementVisualProperties(
        text: text,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
      ),
      currentElement: currentElement,
    );
  }

  /// Creates a copy with a new current element (after transform change).
  ElementData withCurrentElement(ChartElement newElement) {
    return ElementData(
      elementType: elementType,
      id: id,
      dataPoints: dataPoints,
      dataRect: dataRect,
      visualProperties: visualProperties,
      currentElement: newElement,
    );
  }
}

/// Visual properties that remain constant regardless of coordinate transform.
///
/// These are separated from positional data to clarify what changes during zoom/pan.
class ElementVisualProperties {
  final Color? color;
  final double? strokeWidth;
  final double? radius;
  final String? text;
  final Color? backgroundColor;
  final Color? borderColor;

  ElementVisualProperties({
    this.color,
    this.strokeWidth,
    this.radius,
    this.text,
    this.backgroundColor,
    this.borderColor,
  });

  /// Creates properties for a series element.
  ElementVisualProperties.series({
    required Color color,
    required double strokeWidth,
  })  : color = color,
        strokeWidth = strokeWidth,
        radius = null,
        text = null,
        backgroundColor = null,
        borderColor = null;

  /// Creates properties for a datapoint element.
  ElementVisualProperties.datapoint({
    required Color color,
    required double radius,
  })  : color = color,
        radius = radius,
        strokeWidth = null,
        text = null,
        backgroundColor = null,
        borderColor = null;

  /// Creates properties for an annotation element.
  ElementVisualProperties.annotation({
    required String text,
    required Color backgroundColor,
    required Color borderColor,
  })  : text = text,
        backgroundColor = backgroundColor,
        borderColor = borderColor,
        color = null,
        strokeWidth = null,
        radius = null;
}
