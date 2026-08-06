import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals;

import '../meta/chart_surface.dart';

/// Metadata key used to keep one category's identity stable while its rank
/// position changes between race frames.
const String barRaceCategoryIdMetadataKey = 'braven.barRace.categoryId';

/// How the numeric axis domain behaves while a race advances.
enum BarRaceAxisRange {
  /// Advances through stable, human-readable ceilings.
  dynamic,

  /// Holds until the leader uses the available headroom, then follows it
  /// monotonically. This produces the continuously expanding domain commonly
  /// used by population and financial bar races.
  continuous,

  /// Uses one domain covering every frame.
  fixed,
}

enum BarRaceSort { descending, ascending }

/// Placement of the prominent temporal label composed over a bar race.
enum BarRacePeriodPosition { topLeft, topRight, bottomLeft, bottomRight }

/// Numeric notation used by [BarRaceValueFormat].
enum BarRaceValueNotation { standard, compact, scientific }

/// Portable formatter for bar-race values and aggregate totals.
///
/// The formatted number replaces `{value}` in [pattern]. For example,
/// `BarRaceValueFormat(pattern: '{value}M residents')` renders `1,234M
/// residents`. [scale] is applied before notation and decimal formatting.
@immutable
@chartSurface
final class BarRaceValueFormat {
  const BarRaceValueFormat({
    this.pattern = '{value}',
    this.notation = BarRaceValueNotation.standard,
    this.decimalPlaces = 0,
    this.useGrouping = true,
    this.trimTrailingZeros = true,
    this.scale = 1,
  }) : assert(pattern != ''),
       assert(decimalPlaces >= 0 && decimalPlaces <= 12),
       assert(scale > 0 && scale < double.infinity);

  /// Text template containing the `{value}` token.
  final String pattern;
  final BarRaceValueNotation notation;
  final int decimalPlaces;
  final bool useGrouping;
  final bool trimTrailingZeros;

  /// Divisor applied before the value is formatted.
  final double scale;

  String format(double value) {
    if (!value.isFinite) return pattern.replaceAll('{value}', value.toString());
    final scaled = value / scale;
    final formatted = switch (notation) {
      BarRaceValueNotation.standard => _formatStandard(scaled),
      BarRaceValueNotation.compact => _formatCompact(scaled),
      BarRaceValueNotation.scientific => _trim(
        scaled.toStringAsExponential(decimalPlaces),
      ),
    };
    return pattern.replaceAll('{value}', formatted);
  }

  String _formatCompact(double value) {
    final absolute = value.abs();
    final (divisor, suffix) = switch (absolute) {
      >= 1000000000000 => (1000000000000.0, 'T'),
      >= 1000000000 => (1000000000.0, 'B'),
      >= 1000000 => (1000000.0, 'M'),
      >= 1000 => (1000.0, 'k'),
      _ => (1.0, ''),
    };
    return '${_formatStandard(value / divisor)}$suffix';
  }

  String _formatStandard(double value) {
    var fixed = _trim(value.toStringAsFixed(decimalPlaces));
    if (!useGrouping) return fixed;
    final sign = fixed.startsWith('-') ? '-' : '';
    if (sign.isNotEmpty) fixed = fixed.substring(1);
    final decimalIndex = fixed.indexOf('.');
    final whole = decimalIndex == -1 ? fixed : fixed.substring(0, decimalIndex);
    final fraction = decimalIndex == -1 ? '' : fixed.substring(decimalIndex);
    final buffer = StringBuffer();
    for (var index = 0; index < whole.length; index++) {
      if (index > 0 && (whole.length - index) % 3 == 0) buffer.write(',');
      buffer.write(whole[index]);
    }
    return '$sign$buffer$fraction';
  }

  String _trim(String value) {
    if (!trimTrailingZeros) return value;
    final exponentIndex = value.indexOf(RegExp('[eE]'));
    final exponent = exponentIndex == -1 ? '' : value.substring(exponentIndex);
    var mantissa = exponentIndex == -1
        ? value
        : value.substring(0, exponentIndex);
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceFirst(RegExp(r'0+$'), '');
      mantissa = mantissa.replaceFirst(RegExp(r'\.$'), '');
    }
    return '$mantissa$exponent';
  }

  BarRaceValueFormat copyWith({
    String? pattern,
    BarRaceValueNotation? notation,
    int? decimalPlaces,
    bool? useGrouping,
    bool? trimTrailingZeros,
    double? scale,
  }) => BarRaceValueFormat(
    pattern: pattern ?? this.pattern,
    notation: notation ?? this.notation,
    decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    useGrouping: useGrouping ?? this.useGrouping,
    trimTrailingZeros: trimTrailingZeros ?? this.trimTrailingZeros,
    scale: scale ?? this.scale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRaceValueFormat &&
          other.pattern == pattern &&
          other.notation == notation &&
          other.decimalPlaces == decimalPlaces &&
          other.useGrouping == useGrouping &&
          other.trimTrailingZeros == trimTrailingZeros &&
          other.scale == scale;

  @override
  int get hashCode => Object.hash(
    pattern,
    notation,
    decimalPlaces,
    useGrouping,
    trimTrailingZeros,
    scale,
  );
}

/// Portable formatter for the period label composed over a bar race.
///
/// The pattern supports `{label}`, `{yyyy}`, `{yy}`, `{MMMM}`, `{MMM}`,
/// `{MM}`, `{M}`, `{dd}`, `{d}`, `{HH}`, `{H}`, `{mm}`, `{m}`, `{ss}`, and
/// `{s}`. Date tokens use [BarRaceFrame.timestamp]; frames without a timestamp
/// fall back to their authored [BarRaceFrame.label].
@immutable
@chartSurface
final class BarRacePeriodFormat {
  const BarRacePeriodFormat({this.pattern = '{label}'}) : assert(pattern != '');

  final String pattern;

  String format(BarRaceFrame frame) {
    var result = pattern.replaceAll('{label}', frame.label);
    final timestamp = frame.timestamp;
    if (timestamp == null) {
      return RegExp(
            r'\{(?:yyyy|yy|MMMM|MMM|MM|M|dd|d|HH|H|mm|m|ss|s)\}',
          ).hasMatch(result)
          ? frame.label
          : result;
    }
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final replacements = <String, String>{
      '{yyyy}': timestamp.year.toString().padLeft(4, '0'),
      '{yy}': (timestamp.year % 100).toString().padLeft(2, '0'),
      '{MMMM}': months[timestamp.month - 1],
      '{MMM}': months[timestamp.month - 1].substring(0, 3),
      '{MM}': timestamp.month.toString().padLeft(2, '0'),
      '{M}': timestamp.month.toString(),
      '{dd}': timestamp.day.toString().padLeft(2, '0'),
      '{d}': timestamp.day.toString(),
      '{HH}': timestamp.hour.toString().padLeft(2, '0'),
      '{H}': timestamp.hour.toString(),
      '{mm}': timestamp.minute.toString().padLeft(2, '0'),
      '{m}': timestamp.minute.toString(),
      '{ss}': timestamp.second.toString().padLeft(2, '0'),
      '{s}': timestamp.second.toString(),
    };
    for (final replacement in replacements.entries) {
      result = result.replaceAll(replacement.key, replacement.value);
    }
    return result;
  }

  BarRacePeriodFormat copyWith({String? pattern}) =>
      BarRacePeriodFormat(pattern: pattern ?? this.pattern);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRacePeriodFormat && other.pattern == pattern;

  @override
  int get hashCode => pattern.hashCode;
}

/// Presentation for the temporal label that identifies the active race frame.
///
/// A frame label is intentionally a string rather than a date. Applications
/// can therefore race over years, months, quarters, simulation steps, or any
/// other ordered dimension without changing the playback model.
@immutable
@chartSurface
final class BarRacePeriodStyle {
  const BarRacePeriodStyle({
    this.position = BarRacePeriodPosition.bottomRight,
    this.fontSize = 72,
    this.color,
    this.fontWeight = FontWeight.w700,
    this.opacity = 0.22,
    this.inset = 24,
    this.supportingTextSize = 12,
  }) : assert(fontSize > 0),
       assert(opacity >= 0 && opacity <= 1),
       assert(inset >= 0),
       assert(supportingTextSize > 0);

  final BarRacePeriodPosition position;
  final double fontSize;

  /// Null inherits the active theme's foreground colour.
  final Color? color;

  final FontWeight fontWeight;
  final double opacity;
  final double inset;
  final double supportingTextSize;

  BarRacePeriodStyle copyWith({
    BarRacePeriodPosition? position,
    double? fontSize,
    Color? color,
    bool clearColor = false,
    FontWeight? fontWeight,
    double? opacity,
    double? inset,
    double? supportingTextSize,
  }) => BarRacePeriodStyle(
    position: position ?? this.position,
    fontSize: fontSize ?? this.fontSize,
    color: clearColor ? null : color ?? this.color,
    fontWeight: fontWeight ?? this.fontWeight,
    opacity: opacity ?? this.opacity,
    inset: inset ?? this.inset,
    supportingTextSize: supportingTextSize ?? this.supportingTextSize,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRacePeriodStyle &&
          other.position == position &&
          other.fontSize == fontSize &&
          other.color?.toARGB32() == color?.toARGB32() &&
          other.fontWeight == fontWeight &&
          other.opacity == opacity &&
          other.inset == inset &&
          other.supportingTextSize == supportingTextSize;

  @override
  int get hashCode => Object.hash(
    position,
    fontSize,
    color?.toARGB32(),
    fontWeight,
    opacity,
    inset,
    supportingTextSize,
  );
}

@immutable
@chartSurface
final class BarRaceCategory {
  const BarRaceCategory({
    required this.id,
    required this.label,
    required this.color,
  }) : assert(id != ''),
       assert(label != '');

  final String id;
  final String label;
  final Color color;

  BarRaceCategory copyWith({String? id, String? label, Color? color}) =>
      BarRaceCategory(
        id: id ?? this.id,
        label: label ?? this.label,
        color: color ?? this.color,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRaceCategory &&
          other.id == id &&
          other.label == label &&
          other.color.toARGB32() == color.toARGB32();

  @override
  int get hashCode => Object.hash(id, label, color.toARGB32());
}

@immutable
@chartSurface
final class BarRaceFrame {
  const BarRaceFrame({
    required this.id,
    required this.label,
    required this.values,
    this.timestamp,
    this.total,
  }) : assert(id != ''),
       assert(label != '');

  final String id;
  final String label;
  final Map<String, double> values;
  final DateTime? timestamp;
  final double? total;

  BarRaceFrame copyWith({
    String? id,
    String? label,
    Map<String, double>? values,
    DateTime? timestamp,
    bool clearTimestamp = false,
    double? total,
    bool clearTotal = false,
  }) => BarRaceFrame(
    id: id ?? this.id,
    label: label ?? this.label,
    values: values ?? this.values,
    timestamp: clearTimestamp ? null : timestamp ?? this.timestamp,
    total: clearTotal ? null : total ?? this.total,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRaceFrame &&
          other.id == id &&
          other.label == label &&
          mapEquals(other.values, values) &&
          other.timestamp == timestamp &&
          other.total == total;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    Object.hashAllUnordered(values.entries),
    timestamp,
    total,
  );
}

@immutable
@chartSurface
final class BarRaceConfig {
  const BarRaceConfig({
    required this.categories,
    required this.frames,
    this.topCount = 10,
    this.durationPerFrame = const Duration(milliseconds: 800),
    this.axisRange = BarRaceAxisRange.dynamic,
    this.sort = BarRaceSort.descending,
    this.loop = false,
    this.showPeriod = true,
    this.showTotal = false,
    this.periodStyle = const BarRacePeriodStyle(),
    this.periodFormat = const BarRacePeriodFormat(),
    this.valueFormat = const BarRaceValueFormat(),
    this.totalFormat = const BarRaceValueFormat(
      notation: BarRaceValueNotation.compact,
      decimalPlaces: 1,
      pattern: '{value} total',
    ),
  }) : assert(topCount > 0),
       assert(topCount <= 10000);

  final List<BarRaceCategory> categories;
  final List<BarRaceFrame> frames;
  final int topCount;
  final Duration durationPerFrame;
  final BarRaceAxisRange axisRange;
  final BarRaceSort sort;
  final bool loop;
  final bool showPeriod;
  final bool showTotal;
  final BarRacePeriodStyle periodStyle;
  final BarRacePeriodFormat periodFormat;
  final BarRaceValueFormat valueFormat;
  final BarRaceValueFormat totalFormat;

  BarRaceConfig copyWith({
    List<BarRaceCategory>? categories,
    List<BarRaceFrame>? frames,
    int? topCount,
    Duration? durationPerFrame,
    BarRaceAxisRange? axisRange,
    BarRaceSort? sort,
    bool? loop,
    bool? showPeriod,
    bool? showTotal,
    BarRacePeriodStyle? periodStyle,
    BarRacePeriodFormat? periodFormat,
    BarRaceValueFormat? valueFormat,
    BarRaceValueFormat? totalFormat,
  }) => BarRaceConfig(
    categories: categories ?? this.categories,
    frames: frames ?? this.frames,
    topCount: topCount ?? this.topCount,
    durationPerFrame: durationPerFrame ?? this.durationPerFrame,
    axisRange: axisRange ?? this.axisRange,
    sort: sort ?? this.sort,
    loop: loop ?? this.loop,
    showPeriod: showPeriod ?? this.showPeriod,
    showTotal: showTotal ?? this.showTotal,
    periodStyle: periodStyle ?? this.periodStyle,
    periodFormat: periodFormat ?? this.periodFormat,
    valueFormat: valueFormat ?? this.valueFormat,
    totalFormat: totalFormat ?? this.totalFormat,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRaceConfig &&
          listEquals(other.categories, categories) &&
          listEquals(other.frames, frames) &&
          other.topCount == topCount &&
          other.durationPerFrame == durationPerFrame &&
          other.axisRange == axisRange &&
          other.sort == sort &&
          other.loop == loop &&
          other.showPeriod == showPeriod &&
          other.showTotal == showTotal &&
          other.periodStyle == periodStyle &&
          other.periodFormat == periodFormat &&
          other.valueFormat == valueFormat &&
          other.totalFormat == totalFormat;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(categories),
    Object.hashAll(frames),
    topCount,
    durationPerFrame,
    axisRange,
    sort,
    loop,
    showPeriod,
    showTotal,
    periodStyle,
    periodFormat,
    valueFormat,
    totalFormat,
  );
}

@immutable
final class BarRaceRankedValue {
  const BarRaceRankedValue({
    required this.category,
    required this.value,
    this.rank = 0,
  });

  final BarRaceCategory category;
  final double value;

  /// The zero-based visual rank for this category.
  ///
  /// Target frame values use whole ranks. Values returned by
  /// `BarRaceController.effectiveRankedValues` may use fractional ranks while
  /// categories exchange positions between frames.
  final double rank;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarRaceRankedValue &&
          other.category == category &&
          other.value == value &&
          other.rank == rank;

  @override
  int get hashCode => Object.hash(category, value, rank);
}
