// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart' show listEquals;

import '../models/chart_theme.dart' show ChartTheme;
import '../models/interaction_config.dart' show InteractionConfig;
import '../models/x_axis_config.dart' show XAxisConfig;
import '../models/y_axis_config.dart' show YAxisConfig;
import 'mark.dart';

/// A complete, typed grammar-of-graphics specification over rows of type `T`.
///
/// A spec is DECLARATIVE and inert: it names data, geometries and coordinate
/// options, and nothing else. Turning it into the objects the render pipeline
/// understands is the job of `lower`, which produces ordinary
/// `ChartSeries`/`ChartAnnotation`/axis configs — the artifact codecs, Source
/// generation and Workbench are untouched and receive exactly what they
/// already know.
///
/// ```dart
/// PlotSpec<Ride>(
///   data: rides,
///   marks: [
///     LineMark(x: (r) => r.km, y: (r) => r.power, id: 'power'),
///     TrendMark(sourceMarkId: 'power'),
///   ],
///   yAxes: [YAxisConfig(position: YAxisPosition.left, label: 'W')],
/// )
/// ```
///
/// Every lowered chart takes the MULTI-AXIS path: [yAxes] defaults to a single
/// left axis when it is left empty, and the lowering always binds each series
/// to an explicit axis. The legacy single-axis path is never targeted.
class PlotSpec<T> {
  /// Creates a plot specification.
  const PlotSpec({
    required this.data,
    required this.marks,
    this.transposed = false,
    this.theme,
    this.interaction,
    this.xAxis,
    this.yAxes = const <YAxisConfig>[],
  });

  /// Rows every mark's accessors read from.
  final List<T> data;

  /// Geometries and derived statistics, in paint order.
  ///
  /// A mark without an explicit `id` is lowered as `mark-<index>` using its
  /// index in this list, counting [TrendMark]s.
  final List<Mark<T>> marks;

  /// Whether the Cartesian plane is transposed.
  ///
  /// Transposition is implemented in this package by horizontal bar geometry,
  /// which transposes the WHOLE chart. A transposed spec must therefore
  /// contain bar marks only; anything else is rejected with
  /// `GrammarDiagnosticCode.unsupportedTransposition` instead of rendering
  /// some geometries rotated and others not.
  final bool transposed;

  /// Optional theme handed to the chart unchanged.
  final ChartTheme? theme;

  /// Optional interaction configuration. Null lowers to
  /// `const InteractionConfig()`.
  final InteractionConfig? interaction;

  /// Optional X-axis configuration.
  final XAxisConfig? xAxis;

  /// Y-axis slots marks bind to through [Mark.yAxisId].
  ///
  /// An axis with an empty id is assigned `axis-<index>`. An empty list lowers
  /// to a single default left axis, `axis-0`.
  final List<YAxisConfig> yAxes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlotSpec<T> &&
          listEquals(other.data, data) &&
          listEquals(other.marks, marks) &&
          other.transposed == transposed &&
          other.theme == theme &&
          other.interaction == interaction &&
          other.xAxis == xAxis &&
          listEquals(other.yAxes, yAxes);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(data),
    Object.hashAll(marks),
    transposed,
    theme,
    interaction,
    xAxis,
    Object.hashAll(yAxes),
  );

  @override
  String toString() =>
      'PlotSpec(rows: ${data.length}, marks: ${marks.length}, '
      'transposed: $transposed)';
}
