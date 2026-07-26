// Copyright (c) 2025 braven_charts. All rights reserved.
// Calendar-nice date tick generation + interval labels (no Flutter, no intl).
//
// Positions for a time axis use the LINEAR arm of [ChartTransform]
// (epoch-milliseconds map linearly); this file only chooses WHERE the ticks
// land (real calendar boundaries) and HOW they are labelled. All arithmetic is
// UTC — the display timezone is deferred (spec: UTC-epoch).

/// The calendar granularity chosen for a time axis, coarsest label driver.
///
/// Declared finest → coarsest so [TimeTickInterval.values] can be scanned in
/// that order when picking the finest interval that fits within a tick budget.
enum TimeTickInterval { second, minute, hour, day, week, month, quarter, year }

// Approximate average durations (milliseconds) used ONLY to pick an interval;
// the actual ticks are placed on real calendar boundaries, not these steps.
const double _msSecond = 1000;
const double _msMinute = 60 * _msSecond;
const double _msHour = 60 * _msMinute;
const double _msDay = 24 * _msHour;
const double _msWeek = 7 * _msDay;
const double _msMonth = 30.436875 * _msDay; // 365.2425 / 12 days
const double _msQuarter = 3 * _msMonth;
const double _msYear = 365.2425 * _msDay;

// Upper bound on the calendar walk so pathological spans can never loop away.
const int _maxBoundaryScan = 100000;

const List<String> _monthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

double _approxIntervalMillis(TimeTickInterval interval) {
  switch (interval) {
    case TimeTickInterval.second:
      return _msSecond;
    case TimeTickInterval.minute:
      return _msMinute;
    case TimeTickInterval.hour:
      return _msHour;
    case TimeTickInterval.day:
      return _msDay;
    case TimeTickInterval.week:
      return _msWeek;
    case TimeTickInterval.month:
      return _msMonth;
    case TimeTickInterval.quarter:
      return _msQuarter;
    case TimeTickInterval.year:
      return _msYear;
  }
}

/// The interval chosen for a `[minMillis, maxMillis]` epoch span.
///
/// Picks the FINEST interval whose approximate tick count over the span is at
/// or below [maxTicks] (so a ~3-year span resolves to [TimeTickInterval.year],
/// a ~6-month span to [TimeTickInterval.month], and so on). Falls back to the
/// coarsest interval ([TimeTickInterval.year]) for very large spans, and to the
/// finest ([TimeTickInterval.second]) for a degenerate (non-positive) span.
TimeTickInterval intervalFor(
  double minMillis,
  double maxMillis, {
  int maxTicks = 8,
}) {
  final span = maxMillis - minMillis;
  if (span <= 0 || maxTicks <= 0) return TimeTickInterval.second;
  for (final interval in TimeTickInterval.values) {
    if (span / _approxIntervalMillis(interval) <= maxTicks) return interval;
  }
  return TimeTickInterval.year;
}

/// The first calendar boundary at or after [dt] for [interval] (UTC).
DateTime _ceilToBoundary(DateTime dt, TimeTickInterval interval) {
  final DateTime floor;
  switch (interval) {
    case TimeTickInterval.year:
      floor = DateTime.utc(dt.year);
    case TimeTickInterval.quarter:
      final quarterStartMonth = ((dt.month - 1) ~/ 3) * 3 + 1;
      floor = DateTime.utc(dt.year, quarterStartMonth);
    case TimeTickInterval.month:
      floor = DateTime.utc(dt.year, dt.month);
    case TimeTickInterval.week:
      final weekday = DateTime.utc(dt.year, dt.month, dt.day).weekday;
      floor = DateTime.utc(dt.year, dt.month, dt.day - (weekday - 1));
    case TimeTickInterval.day:
      floor = DateTime.utc(dt.year, dt.month, dt.day);
    case TimeTickInterval.hour:
      floor = DateTime.utc(dt.year, dt.month, dt.day, dt.hour);
    case TimeTickInterval.minute:
      floor = DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    case TimeTickInterval.second:
      floor = DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
      );
  }
  return floor.isBefore(dt) ? _advance(floor, interval, 1) : floor;
}

/// [d] advanced by [steps] whole [interval]s, using real calendar arithmetic
/// (month/year overflow normalised by [DateTime.utc]); NOT fixed-ms steps.
DateTime _advance(DateTime d, TimeTickInterval interval, int steps) {
  switch (interval) {
    case TimeTickInterval.year:
      return DateTime.utc(d.year + steps);
    case TimeTickInterval.quarter:
      return DateTime.utc(d.year, d.month + 3 * steps);
    case TimeTickInterval.month:
      return DateTime.utc(d.year, d.month + steps);
    case TimeTickInterval.week:
      return DateTime.utc(d.year, d.month, d.day + 7 * steps);
    case TimeTickInterval.day:
      return DateTime.utc(d.year, d.month, d.day + steps);
    case TimeTickInterval.hour:
      return DateTime.utc(d.year, d.month, d.day, d.hour + steps);
    case TimeTickInterval.minute:
      return DateTime.utc(d.year, d.month, d.day, d.hour, d.minute + steps);
    case TimeTickInterval.second:
      return DateTime.utc(
        d.year,
        d.month,
        d.day,
        d.hour,
        d.minute,
        d.second + steps,
      );
  }
}

/// Tick values (epoch-millis) on real calendar boundaries within
/// `[minMillis, maxMillis]`.
///
/// The interval is chosen by [intervalFor]; boundaries are walked with UTC
/// calendar arithmetic (real month/year lengths, NOT fixed-ms increments) from
/// the first boundary at or after `minMillis` through the last at or before
/// `maxMillis`. When more than [maxTicks] boundaries fall in range (e.g. a
/// many-decade span still on the year interval), they are strided down to at
/// most [maxTicks], mirroring the log decade generator.
///
/// An inverted or empty span yields an empty list.
List<double> dateTicks(
  double minMillis,
  double maxMillis, {
  int maxTicks = 8,
}) {
  if (maxMillis <= minMillis || maxTicks <= 0) return const <double>[];

  final interval = intervalFor(minMillis, maxMillis, maxTicks: maxTicks);
  final min = DateTime.fromMillisecondsSinceEpoch(
    minMillis.round(),
    isUtc: true,
  );
  final max = DateTime.fromMillisecondsSinceEpoch(
    maxMillis.round(),
    isUtc: true,
  );

  final boundaries = <DateTime>[];
  var d = _ceilToBoundary(min, interval);
  while (!d.isAfter(max) && boundaries.length < _maxBoundaryScan) {
    boundaries.add(d);
    d = _advance(d, interval, 1);
  }

  var stride = 1;
  if (boundaries.length > maxTicks) {
    stride = (boundaries.length / maxTicks).ceil();
  }

  final ticks = <double>[];
  for (var i = 0; i < boundaries.length; i += stride) {
    ticks.add(boundaries[i].millisecondsSinceEpoch.toDouble());
  }
  return ticks;
}

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// A hand-written (no `intl`) label for the tick at [millis] given the chosen
/// [interval]: `year`→`'2026'`, `quarter`/`month`→`'Feb 2026'`,
/// `week`/`day`→`'Feb 3'`, `hour`→`'Feb 3 14:00'`, `minute`→`'14:30'`,
/// `second`→`'14:30:05'`. All fields are read in UTC.
String dateLabel(double millis, TimeTickInterval interval) {
  final d = DateTime.fromMillisecondsSinceEpoch(millis.round(), isUtc: true);
  final month = _monthAbbreviations[d.month - 1];
  switch (interval) {
    case TimeTickInterval.year:
      return '${d.year}';
    case TimeTickInterval.quarter:
    case TimeTickInterval.month:
      return '$month ${d.year}';
    case TimeTickInterval.week:
    case TimeTickInterval.day:
      return '$month ${d.day}';
    case TimeTickInterval.hour:
      return '$month ${d.day} ${_twoDigits(d.hour)}:00';
    case TimeTickInterval.minute:
      return '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';
    case TimeTickInterval.second:
      return '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}:'
          '${_twoDigits(d.second)}';
  }
}
