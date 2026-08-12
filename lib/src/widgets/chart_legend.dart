// Copyright (c) 2025 braven_charts. All rights reserved.
// Chart Legend Widget - Show/Hide Series Control

import 'package:flutter/material.dart';

import '../models/chart_series.dart';
import '../models/bar_chart_style.dart';
import '../models/candlestick_chart_series.dart';
import '../models/range_area_chart_series.dart';
import '../rendering/bar_pattern_painter.dart';
import '../utils/dashed_path.dart';

/// A legend widget for displaying chart series with show/hide functionality.
///
/// The legend displays opted-in series with their colors and names, allowing
/// users to toggle series visibility. Series with
/// [ChartSeries.showInLegend] set to false are omitted completely.
///
/// Example:
/// ```dart
/// class MyChartWithLegend extends StatefulWidget {
///   @override
///   State<MyChartWithLegend> createState() => _MyChartWithLegendState();
/// }
///
/// class _MyChartWithLegendState extends State<MyChartWithLegend> {
///   final List<ChartSeries> _allSeries = [...]; // All series
///   final Set<String> _hiddenSeriesIds = {}; // IDs of hidden series
///
///   List<ChartSeries> get _visibleSeries =>
///       _allSeries.where((s) => !_hiddenSeriesIds.contains(s.id)).toList();
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         Expanded(
///           child: BravenChartPlus(
///             chartType: ChartType.line,
///             series: _visibleSeries,
///             theme: ChartTheme.light,
///           ),
///         ),
///         ChartLegend(
///           series: _allSeries,
///           hiddenSeriesIds: _hiddenSeriesIds,
///           onSeriesToggle: (seriesId) {
///             setState(() {
///               if (_hiddenSeriesIds.contains(seriesId)) {
///                 _hiddenSeriesIds.remove(seriesId);
///               } else {
///                 _hiddenSeriesIds.add(seriesId);
///               }
///             });
///           },
///         ),
///       ],
///     );
///   }
/// }
/// ```
class ChartLegend extends StatelessWidget {
  /// Creates a chart legend widget.
  ///
  /// [series] is the list of all chart series to display in the legend.
  /// [hiddenSeriesIds] is the set of series IDs that are currently hidden.
  /// [onSeriesToggle] is called when a user clicks on a legend item to show/hide a series.
  const ChartLegend({
    super.key,
    required this.series,
    required this.hiddenSeriesIds,
    required this.onSeriesToggle,
    this.onSeriesTap,
    this.orientation = Axis.horizontal,
    this.spacing = 16.0,
    this.runSpacing = 8.0,
    this.padding = const EdgeInsets.all(12.0),
    this.backgroundColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.showBorder = true,
    this.borderColor,
    this.textStyle,
  });

  /// List of all series to display in the legend.
  final List<ChartSeries> series;

  /// Set of series IDs that are currently hidden.
  final Set<String> hiddenSeriesIds;

  /// Callback when a legend item is tapped to toggle series visibility.
  final ValueChanged<String> onSeriesToggle;

  /// Called when a legend item is tapped (drives Y-axis slot selection).
  ///
  /// Unlike [onSeriesToggle] which controls line visibility, this callback
  /// signals series *selection* and is used to drive Y-axis slot swaps.
  /// Both callbacks fire on the same tap.
  final ValueChanged<String>? onSeriesTap;

  /// Orientation of the legend items (horizontal or vertical).
  final Axis orientation;

  /// Spacing between legend items.
  final double spacing;

  /// Run spacing for wrapped items (when using horizontal orientation).
  final double runSpacing;

  /// Padding around the legend content.
  final EdgeInsets padding;

  /// Background color of the legend. Defaults to theme's card color.
  final Color? backgroundColor;

  /// Border radius of the legend container.
  final BorderRadius borderRadius;

  /// Whether to show a border around the legend.
  final bool showBorder;

  /// Color of the legend border. Defaults to theme's divider color.
  final Color? borderColor;

  /// Text style applied to every series label.
  ///
  /// When omitted, the surrounding Material theme supplies the label style.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.cardColor;
    final effectiveBorderColor = borderColor ?? theme.dividerColor;
    final legendSeries = series
        .where((candidate) => candidate.showInLegend)
        .toList(growable: false);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: borderRadius,
        border: showBorder ? Border.all(color: effectiveBorderColor) : null,
      ),
      child: orientation == Axis.horizontal
          ? Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: legendSeries.map(_buildLegendItem).toList(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: legendSeries
                  .map(
                    (s) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: _buildLegendItem(s),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildLegendItem(ChartSeries series) {
    final isHidden = hiddenSeriesIds.contains(series.id);
    final seriesColor = _getSeriesColor(series);

    return InkWell(
      onTap: () {
        onSeriesToggle(series.id);
        onSeriesTap?.call(series.id);
      },
      borderRadius: BorderRadius.circular(4.0),
      child: Opacity(
        opacity: isHidden ? 0.4 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendSwatch(
                series: series,
                color: isHidden ? Colors.grey : seriesColor,
              ),
              const SizedBox(width: 8),
              // Series name
              Text(
                _getSeriesName(series),
                style: (textStyle ?? const TextStyle()).copyWith(
                  fontSize: textStyle?.fontSize ?? 13,
                  fontWeight: textStyle?.fontWeight ?? FontWeight.w500,
                  decoration: isHidden ? TextDecoration.lineThrough : null,
                  color: isHidden ? Colors.grey : textStyle?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get the color for a series based on its type.
  Color _getSeriesColor(ChartSeries series) {
    // Use provided color or generate from series hash
    if (series.color != null) {
      return series.color!;
    }
    final colorIndex = series.hashCode.abs() % _defaultColors.length;
    return _defaultColors[colorIndex];
  }

  /// Get the display name for a series.
  String _getSeriesName(ChartSeries series) {
    // ChartSeries has a displayName getter that returns name ?? id
    return series.displayName;
  }

  /// Default color palette for series.
  static const List<Color> _defaultColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFE91E63), // Pink
    Color(0xFF009688), // Teal
    Color(0xFF795548), // Brown
  ];
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.series, required this.color});

  final ChartSeries series;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (series is CandlestickChartSeries) {
      return CustomPaint(
        size: const Size(18, 16),
        painter: _CandlestickLegendSwatchPainter(color: color),
      );
    }
    if (series is RangeAreaChartSeries) {
      final rangeSeries = series as RangeAreaChartSeries;
      return CustomPaint(
        size: const Size(18, 12),
        painter: _RangeAreaLegendSwatchPainter(
          color: color,
          upperDashPattern: rangeSeries.upperBoundaryStyle.dashPattern,
          lowerDashPattern: rangeSeries.lowerBoundaryStyle.dashPattern,
        ),
      );
    }
    if (series case final BarChartSeries barSeries) {
      return CustomPaint(
        size: const Size(18, 12),
        painter: _BarLegendSwatchPainter(
          color: color,
          pattern: barSeries.barStyle.pattern,
        ),
      );
    }
    if (series is LineChartSeries || series is AreaChartSeries) {
      final dashPattern = switch (series) {
        LineChartSeries(:final dashPattern) => dashPattern,
        AreaChartSeries(:final dashPattern) => dashPattern,
        _ => const <double>[],
      };
      return CustomPaint(
        size: const Size(18, 12),
        painter: _PathLegendSwatchPainter(
          color: color,
          dashPattern: dashPattern,
          showAreaFill: series is AreaChartSeries,
        ),
      );
    }
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
    );
  }
}

class _CandlestickLegendSwatchPainter extends CustomPainter {
  const _CandlestickLegendSwatchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx, 1),
      Offset(center.dx, size.height - 1),
      stroke,
    );
    final body = Rect.fromCenter(center: center, width: 7, height: 10);
    canvas.drawRect(body, Paint()..color = color.withValues(alpha: 0.14));
    canvas.drawRect(body, stroke);
  }

  @override
  bool shouldRepaint(_CandlestickLegendSwatchPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RangeAreaLegendSwatchPainter extends CustomPainter {
  const _RangeAreaLegendSwatchPainter({
    required this.color,
    required this.upperDashPattern,
    required this.lowerDashPattern,
  });

  final Color color;
  final List<double> upperDashPattern;
  final List<double> lowerDashPattern;

  @override
  void paint(Canvas canvas, Size size) {
    final upperY = size.height * 0.25;
    final lowerY = size.height * 0.75;
    canvas.drawRect(
      Rect.fromLTRB(1, upperY, size.width - 1, lowerY),
      Paint()..color = color.withValues(alpha: 0.24),
    );
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      createDashedPath(
        Path()
          ..moveTo(1, upperY)
          ..lineTo(size.width - 1, upperY),
        upperDashPattern,
      ),
      stroke,
    );
    canvas.drawPath(
      createDashedPath(
        Path()
          ..moveTo(1, lowerY)
          ..lineTo(size.width - 1, lowerY),
        lowerDashPattern,
      ),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_RangeAreaLegendSwatchPainter oldDelegate) =>
      oldDelegate.color != color ||
      !_patternsEqual(oldDelegate.upperDashPattern, upperDashPattern) ||
      !_patternsEqual(oldDelegate.lowerDashPattern, lowerDashPattern);
}

class _PathLegendSwatchPainter extends CustomPainter {
  const _PathLegendSwatchPainter({
    required this.color,
    required this.dashPattern,
    required this.showAreaFill,
  });

  final Color color;
  final List<double> dashPattern;
  final bool showAreaFill;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    if (showAreaFill) {
      canvas.drawRect(
        Rect.fromLTRB(1, y, size.width - 1, size.height - 1),
        Paint()..color = color.withValues(alpha: 0.18),
      );
    }
    final source = Path()
      ..moveTo(1, y)
      ..lineTo(size.width - 1, y);
    canvas.drawPath(
      createDashedPath(source, dashPattern),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PathLegendSwatchPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.showAreaFill != showAreaFill ||
      !_patternsEqual(oldDelegate.dashPattern, dashPattern);
}

bool _patternsEqual(List<double> first, List<double> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

class _BarLegendSwatchPainter extends CustomPainter {
  const _BarLegendSwatchPainter({required this.color, required this.pattern});

  final Color color;
  final BarPatternStyle? pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final clip = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(2),
    );
    canvas.drawRRect(clip, Paint()..color = color);
    if (pattern case final pattern?) {
      BarPatternPainter.paint(
        canvas: canvas,
        clip: clip,
        style: pattern,
        baseColor: color,
      );
    }
    canvas.drawRRect(
      clip,
      Paint()
        ..color = color.computeLuminance() > 0.45
            ? const Color(0x66000000)
            : const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BarLegendSwatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pattern != pattern;
}
