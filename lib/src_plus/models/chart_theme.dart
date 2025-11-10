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
    this.seriesColors = const [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ],
  });
  final Color backgroundColor;
  final Color gridColor;
  final Color axisColor;
  final Color textColor;
  final List<Color> seriesColors;

  static const ChartTheme light = ChartTheme();

  static const ChartTheme dark = ChartTheme(
    backgroundColor: Color(0xFF1E1E1E),
    gridColor: Color(0xFF404040),
    axisColor: Colors.white70,
    textColor: Colors.white70,
  );
}
