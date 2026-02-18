// Copyright (c) 2025 braven_charts. All rights reserved.
// Region Summary Renderer Module — stateless overlay card renderer

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../models/region_summary.dart';
import '../../models/region_summary_config.dart';

/// Renders a statistical summary card overlay for a selected chart region.
///
/// This module follows the same stateless pattern as [TooltipRenderer]:
/// a `const` class with a [paint] method that has no mutable state.
///
/// The card displays per-series metric rows (label + formatted value) grouped
/// by series. Positioning logic horizontally centres the card over
/// [regionBounds.center.dx] and places it above [regionBounds.top] by
/// default ([RegionSummaryPosition.aboveRegion]). If the card would clip past
/// the top of the canvas it automatically falls back to
/// [RegionSummaryPosition.insideTop].
///
/// **Performance**: stateless and const — safe to use as a `static const`
/// field inside `ChartRenderBox`, exactly like `TooltipRenderer`.
///
/// Example:
/// ```dart
/// const _regionSummaryRenderer = RegionSummaryRenderer();
///
/// // Inside _paintOverlayLayer():
/// _regionSummaryRenderer.paint(
///   canvas, size, summary, config, regionBoundsRect,
/// );
/// ```
class RegionSummaryRenderer {
  /// Creates a [RegionSummaryRenderer].
  ///
  /// Use as `const RegionSummaryRenderer()` for a singleton-like instance.
  const RegionSummaryRenderer();

  // ---------------------------------------------------------------------------
  // Design constants — subtle, compact, low-prominence style
  // ---------------------------------------------------------------------------

  static const double _cardPaddingH = 10.0;
  static const double _cardPaddingV = 6.0;
  static const double _headerFontSize = 9.5;
  static const double _metricFontSize = 9.5;
  static const double _rowSpacing = 2.0;
  static const double _seriesSpacing = 6.0;
  static const double _cardShadowBlur = 4.0;
  static const double _cardBorderRadius = 5.0;
  static const double _cardGapAbove = 6.0; // gap between card and regionBounds

  // Glassy white card with a slightly increased transparency and a
  // subtly accentuated tint so it reads above chart content but feels
  // slightly more prominent than before.
  static const ui.Color _cardBackground = ui.Color(0xCCF9FAFB); // reduced alpha (slightly transparent)
  static const ui.Color _cardBorder = ui.Color(0xFFCCD6DF); // slightly stronger border tint
  static const ui.Color _cardShadow = ui.Color(0x18000000);
  // Series header — bold and slightly darker for better legibility
  static const ui.Color _headerColor = ui.Color(0xFF4E5F77);
  // Metric label — light grey
  static const ui.Color _labelColor = ui.Color(0xFF8C96A3);
  // Metric value — dark but not black
  static const ui.Color _valueColor = ui.Color(0xFF2E3A47);
  // Separator line between series blocks
  static const ui.Color _dividerColor = ui.Color(0xFFE4E8ED);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Renders the region summary card onto [canvas].
  ///
  /// **Parameters**:
  /// - [canvas]: The canvas to draw on (widget-space coordinates).
  /// - [size]: Total canvas size, used for boundary clamping.
  /// - [summary]: The [RegionSummary] to visualise.
  /// - [config]: Rendering configuration: which metrics to show, optional
  ///   custom [RegionSummaryConfig.valueFormatter], and
  ///   [RegionSummaryConfig.position].
  /// - [regionBounds]: The axis-aligned bounding rectangle of the selected
  ///   region in widget-space coordinates. Used for horizontal centering and
  ///   vertical placement.
  ///
  /// The method is a no-op when [summary.seriesSummaries] is empty **and**
  /// [config.metrics] is empty — in that case there is nothing to render.
  ///
  /// Example:
  /// ```dart
  /// const renderer = RegionSummaryRenderer();
  /// renderer.paint(canvas, size, regionSummary, summaryConfig, boundsRect);
  /// ```
  void paint(ui.Canvas canvas, ui.Size size, RegionSummary summary, RegionSummaryConfig config, Rect regionBounds) {
    // Nothing to render when there are no metrics configured, or no series.
    if (config.metrics.isEmpty || summary.seriesSummaries.isEmpty) {
      return;
    }

    // -------------------------------------------------------------------
    // 1. Build text content to measure card size
    // -------------------------------------------------------------------
    final seriesEntries = summary.seriesSummaries.entries.toList();
    final metricsList = config.metrics.toList();

    // For each series we will paint a header line (seriesName or seriesId)
    // followed by one row per metric.
    final rows = <_RowData>[];
    for (var i = 0; i < seriesEntries.length; i++) {
      final entry = seriesEntries[i];
      final seriesSummary = entry.value;
      final headerLabel = seriesSummary.seriesName ?? seriesSummary.seriesId;

      rows.add(_RowData(label: headerLabel, value: null, isHeader: true));

      for (final metric in metricsList) {
        final rawValue = _metricValue(seriesSummary, metric);
        if (rawValue == null) continue;

        final formatted = _formatValue(rawValue, seriesSummary.unit, config);
        rows.add(_RowData(label: metric.displayLabel, value: formatted, isHeader: false));
      }

      // Add spacing row between series (not after last series)
      if (i < seriesEntries.length - 1) {
        rows.add(const _RowData(label: '', value: null, isHeader: false, isSpacer: true));
      }
    }

    if (rows.isEmpty) return;

    // -------------------------------------------------------------------
    // 2. Measure all rows to determine card size
    // -------------------------------------------------------------------
    final textPainters = <TextPainter>[];
    double maxWidth = 0.0;
    double totalHeight = 0.0;

    for (final row in rows) {
      if (row.isSpacer) {
        textPainters.add(_emptyPainter());
        totalHeight += _seriesSpacing;
        continue;
      }

      final painter = row.isHeader ? _buildHeaderPainter(row.label) : _buildRowPainter(row.label, row.value ?? '');
      painter.layout();
      textPainters.add(painter);
      if (painter.width > maxWidth) maxWidth = painter.width;
      totalHeight += painter.height + _rowSpacing;
    }

    // Remove last row's trailing spacing
    if (rows.isNotEmpty && !rows.last.isSpacer) {
      totalHeight -= _rowSpacing;
    }

    final cardWidth = maxWidth + _cardPaddingH * 2;
    final cardHeight = totalHeight + _cardPaddingV * 2;

    // -------------------------------------------------------------------
    // 3. Compute card position
    // -------------------------------------------------------------------
    final cardLeft = (regionBounds.center.dx - cardWidth / 2).clamp(0.0, (size.width - cardWidth).clamp(0.0, double.infinity));
    final effectivePosition = _effectivePosition(config.position, regionBounds, cardHeight);

    final double cardTop;
    switch (effectivePosition) {
      case RegionSummaryPosition.aboveRegion:
        cardTop = regionBounds.top - cardHeight - _cardGapAbove;
        break;
      case RegionSummaryPosition.insideTop:
        cardTop = regionBounds.top + _cardGapAbove;
        break;
      case RegionSummaryPosition.insideBottom:
        cardTop = regionBounds.bottom - cardHeight - _cardGapAbove;
        break;
    }

    final cardRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight);

    // -------------------------------------------------------------------
    // 4. Draw shadow
    // -------------------------------------------------------------------
    final shadowPath = Path()..addRRect(RRect.fromRectAndRadius(cardRect.shift(const Offset(0, 2)), const Radius.circular(_cardBorderRadius)));
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = _cardShadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, _cardShadowBlur),
    );

    // -------------------------------------------------------------------
    // 5. Draw card background
    // -------------------------------------------------------------------
    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(_cardBorderRadius));
    canvas.drawRRect(rrect, Paint()..color = _cardBackground);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // -------------------------------------------------------------------
    // 6. Paint text rows (spacer rows draw a thin divider line)
    // -------------------------------------------------------------------
    var y = cardTop + _cardPaddingV;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isSpacer) {
        // Thin divider centred in the spacer gap
        final dividerY = y + _seriesSpacing / 2;
        canvas.drawLine(
          Offset(cardLeft + _cardPaddingH, dividerY),
          Offset(cardLeft + cardWidth - _cardPaddingH, dividerY),
          Paint()
            ..color = _dividerColor
            ..strokeWidth = 0.5,
        );
        y += _seriesSpacing;
        continue;
      }
      final painter = textPainters[i];
      painter.paint(canvas, Offset(cardLeft + _cardPaddingH, y));
      y += painter.height + _rowSpacing;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Determines the effective position, applying the insideTop fallback when
  /// [RegionSummaryPosition.aboveRegion] would clip past the canvas top.
  RegionSummaryPosition _effectivePosition(RegionSummaryPosition requested, Rect regionBounds, double cardHeight) {
    if (requested == RegionSummaryPosition.aboveRegion) {
      // Fall back to insideTop if card would extend above the canvas.
      final projectedTop = regionBounds.top - cardHeight - _cardGapAbove;
      if (projectedTop < 0) {
        return RegionSummaryPosition.insideTop;
      }
    }
    return requested;
  }

  /// Returns the numeric value for [metric] from [s], or null when the value
  /// is not available (e.g., [RegionMetric.stdDev] with count < 2).
  double? _metricValue(SeriesRegionSummary s, RegionMetric metric) {
    return switch (metric) {
      RegionMetric.min => s.min,
      RegionMetric.max => s.max,
      RegionMetric.average => s.average,
      RegionMetric.sum => s.sum,
      RegionMetric.count => s.count.toDouble(),
      RegionMetric.range => s.range,
      RegionMetric.stdDev => s.stdDev,
      RegionMetric.delta => s.delta,
      RegionMetric.firstY => s.firstY,
      RegionMetric.lastY => s.lastY,
      RegionMetric.duration => s.duration,
    };
  }

  /// Formats [value] using the [config.valueFormatter] when provided, or falls
  /// back to 2-decimal-place default formatting with optional [unit] suffix.
  String _formatValue(double value, String? unit, RegionSummaryConfig config) {
    final formatter = config.valueFormatter;
    if (formatter != null) {
      return formatter(value, unit);
    }
    final formatted = value.toStringAsFixed(2);
    if (unit != null && unit.isNotEmpty) {
      return '$formatted $unit';
    }
    return formatted;
  }

  /// Builds a [TextPainter] for a series header — medium-weight, muted.
  TextPainter _buildHeaderPainter(String label) {
    return TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: _headerFontSize,
          fontWeight: FontWeight.w700,
          color: _headerColor,
          letterSpacing: 0.2,
        ), // make series name bold
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Builds a [TextPainter] for a metric row: "label  value".
  ///
  /// The label is light grey and the value slightly darker for soft hierarchy.
  TextPainter _buildRowPainter(String label, String value) {
    return TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label  ',
            style: const TextStyle(fontSize: _metricFontSize, fontWeight: FontWeight.w400, color: _labelColor),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontSize: _metricFontSize, fontWeight: FontWeight.w600, color: _valueColor),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  /// Returns a zeroed-out [TextPainter] used as a spacer placeholder.
  TextPainter _emptyPainter() {
    return TextPainter(
      text: const TextSpan(text: ''),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}

// ---------------------------------------------------------------------------
// Internal data holder
// ---------------------------------------------------------------------------

/// Internal utility for building the card row list.
class _RowData {
  const _RowData({required this.label, required this.value, required this.isHeader, this.isSpacer = false});

  final String label;
  final String? value;
  final bool isHeader;
  final bool isSpacer;
}
