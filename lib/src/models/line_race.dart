import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';

import '../meta/chart_surface.dart';
import 'chart_data_point.dart';

/// Stable identity and presentation defaults for one line-race participant.
@immutable
@chartSurface
final class LineRaceSeries {
  const LineRaceSeries({
    required this.id,
    required this.name,
    required this.color,
  }) : assert(id != ''),
       assert(name != '');

  final String id;
  final String name;
  final Color color;

  LineRaceSeries copyWith({String? id, String? name, Color? color}) =>
      LineRaceSeries(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineRaceSeries &&
          other.id == id &&
          other.name == name &&
          other.color.toARGB32() == color.toARGB32();

  @override
  int get hashCode => Object.hash(id, name, color.toARGB32());
}

/// One ordered observation boundary in a line-race timeline.
///
/// [values] is intentionally sparse. An absent series id means that the
/// participant has no observation at this X coordinate; controllers preserve
/// that absence as a path gap rather than inventing a value.
@immutable
@chartSurface
final class LineRaceFrame {
  const LineRaceFrame({
    required this.id,
    required this.label,
    required this.x,
    required this.values,
  }) : assert(id != ''),
       assert(label != '');

  final String id;
  final String label;
  final double x;
  final Map<String, double> values;

  LineRaceFrame copyWith({
    String? id,
    String? label,
    double? x,
    Map<String, double>? values,
  }) => LineRaceFrame(
    id: id ?? this.id,
    label: label ?? this.label,
    x: x ?? this.x,
    values: values ?? this.values,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineRaceFrame &&
          other.id == id &&
          other.label == label &&
          other.x == x &&
          mapEquals(other.values, values);

  @override
  int get hashCode =>
      Object.hash(id, label, x, Object.hashAllUnordered(values.entries));
}

/// Portable authored timeline for a cumulative line race.
@immutable
@chartSurface
final class LineRaceConfig {
  const LineRaceConfig({
    required this.series,
    required this.frames,
    this.durationPerFrame = const Duration(milliseconds: 800),
    this.loop = false,
  });

  final List<LineRaceSeries> series;
  final List<LineRaceFrame> frames;
  final Duration durationPerFrame;
  final bool loop;

  LineRaceConfig copyWith({
    List<LineRaceSeries>? series,
    List<LineRaceFrame>? frames,
    Duration? durationPerFrame,
    bool? loop,
  }) => LineRaceConfig(
    series: series ?? this.series,
    frames: frames ?? this.frames,
    durationPerFrame: durationPerFrame ?? this.durationPerFrame,
    loop: loop ?? this.loop,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineRaceConfig &&
          listEquals(other.series, series) &&
          listEquals(other.frames, frames) &&
          other.durationPerFrame == durationPerFrame &&
          other.loop == loop;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(series),
    Object.hashAll(frames),
    durationPerFrame,
    loop,
  );
}

/// Immutable render-ready projection of one line-race clock position.
@immutable
final class LineRaceSnapshot {
  const LineRaceSnapshot({
    required this.frame,
    required this.progress,
    required this.frontierX,
    required this.pointsBySeries,
  });

  final LineRaceFrame frame;
  final double progress;
  final double frontierX;
  final Map<String, List<ChartDataPoint>> pointsBySeries;

  List<ChartDataPoint> pointsFor(String seriesId) =>
      pointsBySeries[seriesId] ?? const [];
}
