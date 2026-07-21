import 'package:flutter/material.dart';

import '../meta/chart_surface.dart';

/// Host-overridable visual tokens for chart data tables.
///
/// Add this extension to `ThemeData.extensions` to style every chart table in
/// an application, or pass an instance directly to a chart data table.
@chartSurface
@immutable
class ChartDataTableTheme extends ThemeExtension<ChartDataTableTheme> {
  const ChartDataTableTheme({
    this.rowHeight = 36,
    this.headerHeight = 44,
    this.rowNumberWidth = 44,
    this.xColumnWidth = 120,
    this.seriesColumnWidth = 136,
    this.cellHorizontalPadding = 8,
    this.headerBackgroundColor,
    this.evenRowColor,
    this.oddRowColor,
    this.dividerColor,
    this.focusedRowColor,
    this.selectedRowColor,
    this.headerTextStyle,
    this.cellTextStyle,
    this.rowNumberTextStyle,
  });

  final double rowHeight;
  final double headerHeight;
  final double rowNumberWidth;
  final double xColumnWidth;
  final double seriesColumnWidth;
  final double cellHorizontalPadding;
  final Color? headerBackgroundColor;
  final Color? evenRowColor;
  final Color? oddRowColor;
  final Color? dividerColor;
  final Color? focusedRowColor;
  final Color? selectedRowColor;
  final TextStyle? headerTextStyle;
  final TextStyle? cellTextStyle;
  final TextStyle? rowNumberTextStyle;

  @override
  ChartDataTableTheme copyWith({
    double? rowHeight,
    double? headerHeight,
    double? rowNumberWidth,
    double? xColumnWidth,
    double? seriesColumnWidth,
    double? cellHorizontalPadding,
    Color? headerBackgroundColor,
    Color? evenRowColor,
    Color? oddRowColor,
    Color? dividerColor,
    Color? focusedRowColor,
    Color? selectedRowColor,
    TextStyle? headerTextStyle,
    TextStyle? cellTextStyle,
    TextStyle? rowNumberTextStyle,
  }) => ChartDataTableTheme(
    rowHeight: rowHeight ?? this.rowHeight,
    headerHeight: headerHeight ?? this.headerHeight,
    rowNumberWidth: rowNumberWidth ?? this.rowNumberWidth,
    xColumnWidth: xColumnWidth ?? this.xColumnWidth,
    seriesColumnWidth: seriesColumnWidth ?? this.seriesColumnWidth,
    cellHorizontalPadding: cellHorizontalPadding ?? this.cellHorizontalPadding,
    headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
    evenRowColor: evenRowColor ?? this.evenRowColor,
    oddRowColor: oddRowColor ?? this.oddRowColor,
    dividerColor: dividerColor ?? this.dividerColor,
    focusedRowColor: focusedRowColor ?? this.focusedRowColor,
    selectedRowColor: selectedRowColor ?? this.selectedRowColor,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    cellTextStyle: cellTextStyle ?? this.cellTextStyle,
    rowNumberTextStyle: rowNumberTextStyle ?? this.rowNumberTextStyle,
  );

  @override
  ChartDataTableTheme lerp(covariant ChartDataTableTheme? other, double t) {
    if (other == null) return this;
    return ChartDataTableTheme(
      rowHeight: _lerpDouble(rowHeight, other.rowHeight, t),
      headerHeight: _lerpDouble(headerHeight, other.headerHeight, t),
      rowNumberWidth: _lerpDouble(rowNumberWidth, other.rowNumberWidth, t),
      xColumnWidth: _lerpDouble(xColumnWidth, other.xColumnWidth, t),
      seriesColumnWidth: _lerpDouble(
        seriesColumnWidth,
        other.seriesColumnWidth,
        t,
      ),
      cellHorizontalPadding: _lerpDouble(
        cellHorizontalPadding,
        other.cellHorizontalPadding,
        t,
      ),
      headerBackgroundColor: Color.lerp(
        headerBackgroundColor,
        other.headerBackgroundColor,
        t,
      ),
      evenRowColor: Color.lerp(evenRowColor, other.evenRowColor, t),
      oddRowColor: Color.lerp(oddRowColor, other.oddRowColor, t),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t),
      focusedRowColor: Color.lerp(focusedRowColor, other.focusedRowColor, t),
      selectedRowColor: Color.lerp(selectedRowColor, other.selectedRowColor, t),
      headerTextStyle: TextStyle.lerp(
        headerTextStyle,
        other.headerTextStyle,
        t,
      ),
      cellTextStyle: TextStyle.lerp(cellTextStyle, other.cellTextStyle, t),
      rowNumberTextStyle: TextStyle.lerp(
        rowNumberTextStyle,
        other.rowNumberTextStyle,
        t,
      ),
    );
  }
}

double _lerpDouble(double left, double right, double t) =>
    left + (right - left) * t;
