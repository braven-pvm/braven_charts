import 'json_value.dart';

/// Portable formatter descriptors for one Pie or Donut series.
///
/// Each descriptor corresponds to one runtime callback. Supply this object in
/// `ChartDocumentExtractOptions.radialFormatterDescriptors` when the source
/// series uses custom radial numeric formatters.
class RadialFormatterDocumentDescriptors {
  /// Creates formatter descriptors for selected radial display components.
  const RadialFormatterDocumentDescriptors({
    this.value,
    this.percentage,
    this.radius,
    this.center,
  });

  /// Descriptor for `PieDataLabelConfig.valueFormatter`.
  final JsonObjectValue? value;

  /// Descriptor for `PieDataLabelConfig.percentageFormatter`.
  final JsonObjectValue? percentage;

  /// Descriptor for `PieSliceRadiusConfig.formatter`.
  final JsonObjectValue? radius;

  /// Descriptor for `DonutCenterContent.valueFormatter`.
  final JsonObjectValue? center;

  /// Whether at least one formatter is represented.
  bool get isNotEmpty =>
      value != null || percentage != null || radius != null || center != null;
}
