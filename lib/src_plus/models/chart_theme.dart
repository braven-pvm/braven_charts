// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

/// Simplified ChartTheme for BravenChartPlus.
class ChartTheme {
  const ChartTheme({
    this.backgroundColor = Colors.white,
    this.gridColor = const Color(0xFFE0E0E0),
    this.axisColor = Colors.black87,
    this.textColor = Colors.black87,
    this.seriesColors = const [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple],
  });
  final Color backgroundColor;
  final Color gridColor;
  final Color axisColor;
  final Color textColor;
  final List<Color> seriesColors;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChartTheme) return false;

    // Compare all fields
    if (backgroundColor != other.backgroundColor) return false;
    if (gridColor != other.gridColor) return false;
    if (axisColor != other.axisColor) return false;
    if (textColor != other.textColor) return false;

    // Compare seriesColors lists
    if (seriesColors.length != other.seriesColors.length) return false;
    for (int i = 0; i < seriesColors.length; i++) {
      if (seriesColors[i] != other.seriesColors[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        gridColor,
        axisColor,
        textColor,
        Object.hashAll(seriesColors),
      );

  static const ChartTheme light = ChartTheme();

  static const ChartTheme dark = ChartTheme(
    backgroundColor: Color(0xFF1E1E1E),
    gridColor: Color(0xFF404040),
    axisColor: Colors.white70,
    textColor: Colors.white70,
    seriesColors: [
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
      Color(0xFFCDDC39), // Lime
      Color(0xFFE91E63), // Pink
      Color(0xFFFFC107), // Amber
    ],
  );
}
