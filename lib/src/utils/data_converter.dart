// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Data Conversion Utilities

import 'dart:math' as math;

import 'dart:ui' show TextDirection;

import '../coordinates/chart_transform.dart';
import '../artifacts/chart_view_state.dart';
import '../elements/series_element.dart';
import '../interaction/core/coordinator.dart';
import '../models/bar_group_info.dart';
import '../models/bar_chart_style.dart';
import '../models/chart_series.dart';
import '../models/candlestick_chart_series.dart';
import '../models/chart_selection_expression.dart';
import '../models/chart_theme.dart';
import '../models/range_area_chart_series.dart';
import '../rendering/bar_composition.dart';
import '../theming/components/candlestick_theme.dart';
import '../theming/components/range_area_theme.dart';
import 'path_series_transition.dart';

/// Converts ChartSeries data to SeriesElements for rendering.
///
/// **Purpose**: Bridge between data model (ChartSeries) and rendering
/// system (SeriesElement + QuadTree).
///
/// **Usage**:
/// ```dart
/// final seriesElements = DataConverter.seriesToElements(
///   series: chartData,
///   transform: transform,
/// );
/// // Insert into QuadTree for hit testing
/// for (final element in seriesElements) {
///   spatialIndex.insert(element);
/// }
/// ```
class DataConverter {
  const DataConverter._();

  /// Converts a list of ChartSeries to SeriesElements.
  ///
  /// Each ChartSeries becomes one SeriesElement that wraps the entire
  /// series for rendering and interaction.
  ///
  /// **Parameters**:
  /// - `series`: List of ChartSeries to convert
  /// - `transform`: Current ChartTransform for coordinate conversion
  /// - `theme`: Optional ChartTheme for styling (uses theme.seriesTheme for colors/widths/markers)
  /// - `coordinator`: Optional interaction coordinator for per-marker hover state
  ///
  /// **Returns**: List of SeriesElements ready for spatial index insertion
  static List<SeriesElement> seriesToElements({
    required List<ChartSeries> series,
    required ChartTransform transform,
    ChartTheme? theme,
    Set<ChartPointRef> focusedPointRefs = const {},
    Set<ChartPointRef> selectedPointRefs = const {},
    Set<String> selectedSeriesIds = const {},
    ChartSelectionExpression selectionExpression =
        const ChartSelectionExpression.empty(),
    Map<String, double> pathRevealProgressBySeries = const {},
    Map<String, PathSeriesPointMap> pathPointMapsBySeries = const {},
    double dataPointHoverScale = 1.5,
    double dataPointSelectionScale = 2.67,
    double completeSeriesHoverStrokeScale = 1.75,
    double completeSeriesSelectionStrokeScale = 1.5,
    @Deprecated('Use theme.seriesTheme instead') double? strokeWidth,
    ChartInteractionCoordinator? coordinator,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    _validateHorizontalBarChart(series);
    final barSeries = series.whereType<BarChartSeries>().toList();
    final barComposition = BarCompositionEngine.resolve(barSeries);
    final selectedBarSeriesIds = <String>{
      for (final candidate in barSeries)
        if (selectedSeriesIds.contains(candidate.id)) candidate.id,
    };
    final hasAnyRenderedPointSelection =
        selectedPointRefs.isNotEmpty ||
        selectedBarSeriesIds.isNotEmpty ||
        selectionExpression.isNotEmpty;

    // Use theme.seriesTheme if available, otherwise backward compatibility mode
    return series.asMap().entries.map((entry) {
      final index = entry.key;
      final s = entry.value;

      final BarGroupInfo? barGroupInfo = s is BarChartSeries
          ? barComposition[s.id]
          : null;

      return SeriesElement(
        series: s,
        transform: transform,
        isSelected: selectedSeriesIds.contains(s.id),
        seriesTheme: theme?.seriesTheme,
        candlestickTheme: theme?.candlestickTheme ?? CandlestickTheme.light,
        rangeAreaTheme: theme?.rangeAreaTheme ?? RangeAreaTheme.light,
        seriesIndex: index,
        coordinator: coordinator,
        barGroupInfo: barGroupInfo,
        focusedPointIndices: {
          for (final ref in focusedPointRefs)
            if (ref.seriesId == s.id) ref.pointIndex,
        },
        selectedPointIndices: {
          for (final ref in selectedPointRefs)
            if (ref.seriesId == s.id) ref.pointIndex,
          if (s is BarChartSeries && selectedBarSeriesIds.contains(s.id))
            for (var pointIndex = 0; pointIndex < s.points.length; pointIndex++)
              if (s.points[pointIndex].isValid) pointIndex,
        },
        selectionExpression: selectionExpression,
        pointFocusColor: theme?.interactionTheme.crosshairColor,
        pointSelectionColor: theme?.interactionTheme.selectionColor,
        fontFamily: theme?.typographyTheme.fontFamily,
        hasAnySelectedPoints: hasAnyRenderedPointSelection,
        revealProgress: pathRevealProgressBySeries[s.id] ?? 1,
        pathPointMap: pathPointMapsBySeries[s.id],
        dataPointHoverScale: dataPointHoverScale,
        dataPointSelectionScale: dataPointSelectionScale,
        completeSeriesHoverStrokeScale: completeSeriesHoverStrokeScale,
        completeSeriesSelectionStrokeScale: completeSeriesSelectionStrokeScale,
        textDirection: textDirection,
      );
    }).toList();
  }

  /// Computes data bounds from all series.
  ///
  /// Finds min/max X and Y values across all series for setting up
  /// the initial ChartTransform viewport.
  ///
  /// For bar charts, adds extra X padding to ensure edge bars aren't clipped.
  /// The padding is based on the average spacing between data points (bar width).
  ///
  /// **Returns**: DataBounds with xMin, xMax, yMin, yMax
  static DataBounds computeDataBounds(List<ChartSeries> series) {
    if (series.isEmpty || series.every((s) => s.isEmpty)) {
      return const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
    }

    _validateHorizontalBarChart(series);

    double xMin = double.infinity;
    double xMax = double.negativeInfinity;
    double yMin = double.infinity;
    double yMax = double.negativeInfinity;

    final barSeries = series.whereType<BarChartSeries>().toList();
    final barComposition = BarCompositionEngine.resolve(barSeries);

    for (final s in series) {
      for (var pointIndex = 0; pointIndex < s.points.length; pointIndex++) {
        final point = s.points[pointIndex];
        if (!point.isValid) continue;
        if (point.x < xMin) xMin = point.x;
        if (point.x > xMax) xMax = point.x;
        if (s is CandlestickChartSeries) {
          final candle = s.candleAt(pointIndex);
          if (candle.low < yMin) yMin = candle.low;
          if (candle.high > yMax) yMax = candle.high;
        } else if (s is RangeAreaChartSeries) {
          final interval = s.intervalAt(pointIndex);
          if (interval.isGap) continue;
          if (interval.low! < yMin) yMin = interval.low!;
          if (interval.high! > yMax) yMax = interval.high!;
        } else if (s is BarChartSeries) {
          final info = barComposition[s.id];
          final rangeStart = s.rangeStartValueFor(pointIndex);
          final start =
              info?.startValueFor(pointIndex, rangeStart) ?? rangeStart;
          final end = info?.endValueFor(pointIndex, point.y) ?? point.y;
          if (start < yMin) yMin = start;
          if (start > yMax) yMax = start;
          if (end < yMin) yMin = end;
          if (end > yMax) yMax = end;
          final target = s.targetValueFor(pointIndex);
          if (target != null && target.isFinite) {
            if (target < yMin) yMin = target;
            if (target > yMax) yMax = target;
          }
          final errorLower = s.errorLowerValueFor(pointIndex);
          final errorUpper = s.errorUpperValueFor(pointIndex);
          if (errorLower != null && errorLower.isFinite) {
            if (errorLower < yMin) yMin = errorLower;
            if (errorLower > yMax) yMax = errorLower;
          }
          if (errorUpper != null && errorUpper.isFinite) {
            if (errorUpper < yMin) yMin = errorUpper;
            if (errorUpper > yMax) yMax = errorUpper;
          }
        } else {
          if (point.y < yMin) yMin = point.y;
          if (point.y > yMax) yMax = point.y;
        }
      }
      if (s is! BarChartSeries) continue;
      final info = barComposition[s.id];
      final trackValue = info?.drawTrack == false ? null : s.trackStyle?.value;
      if (trackValue != null) {
        if (trackValue < yMin) yMin = trackValue;
        if (trackValue > yMax) yMax = trackValue;
      }
      for (final range in s.bulletStyle?.ranges ?? const <BarBulletRange>[]) {
        if (range.endValue < yMin) yMin = range.endValue;
        if (range.endValue > yMax) yMax = range.endValue;
      }
    }

    if (!xMin.isFinite || !xMax.isFinite || !yMin.isFinite || !yMax.isFinite) {
      return const DataBounds(xMin: 0, xMax: 1, yMin: 0, yMax: 1);
    }

    final divergingBars = barSeries
        .where(
          (current) => current.layoutMode == BarLayoutMode.divergingStacked,
        )
        .toList(growable: false);
    if (divergingBars.isNotEmpty &&
        divergingBars.length == series.length &&
        divergingBars.every(
          (current) =>
              current.baselineValue == divergingBars.first.baselineValue,
        )) {
      final baseline = divergingBars.first.baselineValue;
      final extent = math.max((yMin - baseline).abs(), (yMax - baseline).abs());
      yMin = baseline - extent;
      yMax = baseline + extent;
    }

    // Add 5% padding to data bounds for visual breathing room
    double xPadding = (xMax - xMin) * 0.05;
    var yPadding = (yMax - yMin) * 0.05;

    // For bar charts, ensure minimum X padding based on bar width (spacing)
    // so edge bars aren't clipped. Bars are centered on data points, so we
    // need at least half a bar width of padding on each side.
    final hasBarSeries = series.any((s) => s is BarChartSeries);
    if (hasBarSeries) {
      // Calculate average X spacing from all bar series
      double totalSpacing = 0;
      int spacingCount = 0;

      for (final s in series) {
        if (s is BarChartSeries && s.points.length >= 2) {
          // Sort points by X to calculate spacing correctly
          final sortedPoints = [
            for (final point in s.points)
              if (point.isValid) point,
          ]..sort((a, b) => a.x.compareTo(b.x));
          for (int i = 1; i < sortedPoints.length; i++) {
            totalSpacing += sortedPoints[i].x - sortedPoints[i - 1].x;
            spacingCount++;
          }
        }
      }

      if (spacingCount > 0) {
        final avgSpacing = totalSpacing / spacingCount;
        // Bar width is typically 80% of spacing, we need half that for edge padding
        // Plus a small buffer (10%) for visual comfort
        final barPadding = avgSpacing * 0.5;
        // Use whichever is larger: percentage padding or bar-based padding
        xPadding = xPadding > barPadding ? xPadding : barPadding;
      }
    }

    final candleSeries = series.whereType<CandlestickChartSeries>();
    for (final candles in candleSeries) {
      final spacing = _medianCandlestickSpacing(candles);
      final candlePadding = spacing == null
          ? (xMax == xMin ? 0.5 : 0.0)
          : spacing * candles.candlestickStyle.bodyWidthFactor / 2;
      if (candlePadding > xPadding) xPadding = candlePadding;
    }
    if (candleSeries.isNotEmpty && yPadding == 0) {
      yPadding = math.max(yMin.abs() * 0.05, 0.5);
    }

    final rangeAreaSeries = series.whereType<RangeAreaChartSeries>();
    if (rangeAreaSeries.isNotEmpty) {
      if (xPadding == 0) xPadding = 0.5;
      if (yPadding == 0) {
        yPadding = math.max(yMin.abs() * 0.05, 0.5);
      }
    }

    return DataBounds(
      xMin: xMin - xPadding,
      xMax: xMax + xPadding,
      yMin: yMin - yPadding,
      yMax: yMax + yPadding,
    );
  }

  static void _validateHorizontalBarChart(List<ChartSeries> series) {
    final hasHorizontalBars = series.any(
      (current) =>
          current is BarChartSeries &&
          current.orientation == BarOrientation.horizontal,
    );
    if (!hasHorizontalBars) return;
    if (series.any(
      (current) =>
          current is! BarChartSeries ||
          current.orientation != BarOrientation.horizontal,
    )) {
      throw ArgumentError(
        'Horizontal bars require every series in the chart to be a horizontal BarChartSeries',
      );
    }
  }

  static double? _medianCandlestickSpacing(CandlestickChartSeries series) {
    if (series.length < 2) return null;
    final spacings = List<double>.generate(
      series.length - 1,
      (index) => series.candleAt(index + 1).x - series.candleAt(index).x,
      growable: false,
    )..sort();
    return spacings[(spacings.length - 1) >> 1];
  }
}

/// Data bounds for chart viewport setup.
class DataBounds {
  const DataBounds({
    required this.xMin,
    required this.xMax,
    required this.yMin,
    required this.yMax,
  });

  final double xMin;
  final double xMax;
  final double yMin;
  final double yMax;
}
