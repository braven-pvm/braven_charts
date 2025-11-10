// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import 'chart_data_point.dart';

/// Rendering style hints for series visualization.
enum SeriesStyle {
  line,
  bar,
  scatter,
  area,
}

/// Simplified ChartSeries for BravenChartPlus.
class ChartSeries {
  const ChartSeries({
    required this.id,
    this.name,
    required this.points,
    this.color,
    this.style,
    this.isXOrdered = false,
    this.metadata,
  });
  final String id;
  final String? name;
  final List<ChartDataPoint> points;
  final Color? color;
  final SeriesStyle? style;
  final bool isXOrdered;
  final Map<String, dynamic>? metadata;

  int get length => points.length;
  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;
  String get displayName => name ?? id;

  @override
  String toString() => 'ChartSeries(id: $id, points: ${points.length})';
}
