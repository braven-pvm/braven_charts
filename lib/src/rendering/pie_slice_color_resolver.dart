import 'dart:ui';

import '../models/chart_data_point.dart';
import '../models/chart_theme.dart';
import '../models/radial_category_series.dart';

/// Resolves one pie slice color consistently across canvas and legend output.
abstract final class PieSliceColorResolver {
  /// Point override, then first-slice series color, then theme palette.
  static Color resolve({
    required RadialCategorySeries series,
    required ChartTheme theme,
    required ChartDataPoint point,
    required int visibleIndex,
  }) {
    final pointColor = point.pointStyle?.color;
    if (pointColor != null) return pointColor;
    if (visibleIndex == 0 && series.color != null) return series.color!;
    return theme.seriesTheme.colorAt(visibleIndex);
  }
}
