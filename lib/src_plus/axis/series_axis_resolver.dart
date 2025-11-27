/// Series-to-axis binding resolution for multi-axis charts.
///
/// Resolves which [YAxisConfig] applies to which [ChartSeries] based on:
/// 1. Explicit `yAxisId` binding
/// 2. Unit-based matching (`°C` series → `°C` axis)
/// 3. Default axis assignment (first left-positioned axis)
///
/// This module is the core of multi-axis functionality, ensuring each
/// series renders using the correct Y-axis scale.
///
/// See also:
/// - [YAxisConfig] for axis configuration
/// - [ChartSeries] for series data with `yAxisId` and `unit` properties
/// - [AxisBoundsCalculator] for computing per-axis bounds
library;

import '../models/chart_series.dart';
import '../models/y_axis_position.dart';
import 'y_axis_config.dart';

/// Result of resolving a single series to an axis.
class SeriesAxisBinding {
  /// Creates a series-axis binding.
  const SeriesAxisBinding({
    required this.seriesId,
    required this.axisId,
    required this.bindingType,
  });

  /// The series ID.
  final String seriesId;

  /// The resolved axis ID.
  final String axisId;

  /// How the binding was determined.
  final BindingType bindingType;

  @override
  String toString() => 'SeriesAxisBinding($seriesId → $axisId via $bindingType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesAxisBinding && seriesId == other.seriesId && axisId == other.axisId && bindingType == other.bindingType;

  @override
  int get hashCode => Object.hash(seriesId, axisId, bindingType);
}

/// How a series-to-axis binding was determined.
enum BindingType {
  /// Explicit `yAxisId` specified on the series.
  explicit,

  /// Matched by unit (series.unit == axis.unit).
  unitMatch,

  /// Default assignment to primary axis.
  defaultAssignment,

  /// No binding possible (axis not found).
  unbound,
}

/// Complete resolution result for all series-axis bindings.
class SeriesAxisResolution {
  /// Creates a resolution result.
  const SeriesAxisResolution({
    required this.bindings,
    required this.seriesByAxis,
    required this.unboundSeries,
    required this.defaultAxisId,
  });

  /// Creates an empty resolution.
  const SeriesAxisResolution.empty()
      : bindings = const [],
        seriesByAxis = const {},
        unboundSeries = const [],
        defaultAxisId = null;

  /// All series-axis bindings.
  final List<SeriesAxisBinding> bindings;

  /// Series grouped by their resolved axis ID.
  final Map<String, List<String>> seriesByAxis;

  /// Series that could not be bound to any axis.
  final List<String> unboundSeries;

  /// The default axis ID used for unbound series.
  final String? defaultAxisId;

  /// Gets the axis ID for a specific series.
  String? getAxisForSeries(String seriesId) {
    for (final binding in bindings) {
      if (binding.seriesId == seriesId) return binding.axisId;
    }
    return null;
  }

  /// Gets the binding for a specific series.
  SeriesAxisBinding? getBinding(String seriesId) {
    for (final binding in bindings) {
      if (binding.seriesId == seriesId) return binding;
    }
    return null;
  }

  /// Gets all series bound to a specific axis.
  List<String> getSeriesForAxis(String axisId) => seriesByAxis[axisId] ?? [];

  /// Whether all series were successfully bound.
  bool get allBound => unboundSeries.isEmpty;

  /// Total number of series.
  int get seriesCount => bindings.length + unboundSeries.length;

  /// Map of series ID to axis ID for quick lookup.
  Map<String, String> get seriesAxisMap {
    final map = <String, String>{};
    for (final binding in bindings) {
      map[binding.seriesId] = binding.axisId;
    }
    return map;
  }

  @override
  String toString() => 'SeriesAxisResolution(${bindings.length} bound, ${unboundSeries.length} unbound)';
}

/// Resolves series-to-axis bindings for multi-axis charts.
///
/// The resolver handles three binding strategies in priority order:
/// 1. **Explicit binding**: Series with `yAxisId` set are bound to matching axis
/// 2. **Unit matching**: Series with `unit` are bound to axis with matching `unit`
/// 3. **Default assignment**: Remaining series bound to primary (left) axis
///
/// Example:
/// ```dart
/// final resolver = SeriesAxisResolver(
///   axisConfigs: [powerAxis, heartRateAxis],
///   series: [powerSeries, hrSeries, cadenceSeries],
/// );
///
/// final resolution = resolver.resolve();
/// print('Power series → ${resolution.getAxisForSeries('power')}');
/// ```
class SeriesAxisResolver {
  /// Creates a series-axis resolver.
  ///
  /// [axisConfigs] defines the available axes.
  /// [series] is the list of data series to resolve bindings for.
  SeriesAxisResolver({
    required this.axisConfigs,
    required this.series,
  });

  /// The axis configurations.
  final List<YAxisConfig> axisConfigs;

  /// The data series.
  final List<ChartSeries> series;

  /// Cached axis map for lookup.
  late final Map<String, YAxisConfig> _axisMap = {
    for (final config in axisConfigs) config.id: config,
  };

  /// Cached unit-to-axis map for unit matching.
  late final Map<String, String> _unitToAxisMap = {
    for (final config in axisConfigs)
      if (config.unit != null) config.unit!: config.id,
  };

  /// The default axis ID for series without explicit binding.
  ///
  /// Prefers left or leftOuter positioned axis, falls back to first axis.
  String? get defaultAxisId {
    if (axisConfigs.isEmpty) return null;

    // Priority: left > leftOuter > first
    for (final config in axisConfigs) {
      if (config.position == YAxisPosition.left) return config.id;
    }
    for (final config in axisConfigs) {
      if (config.position == YAxisPosition.leftOuter) return config.id;
    }
    return axisConfigs.first.id;
  }

  /// Resolves all series-axis bindings.
  ///
  /// Returns a [SeriesAxisResolution] containing:
  /// - Individual bindings with binding type
  /// - Series grouped by axis
  /// - Any unbound series (rare - only if no axes defined)
  SeriesAxisResolution resolve() {
    if (axisConfigs.isEmpty) {
      return SeriesAxisResolution(
        bindings: const [],
        seriesByAxis: const {},
        unboundSeries: series.map((s) => s.id).toList(),
        defaultAxisId: null,
      );
    }

    final bindings = <SeriesAxisBinding>[];
    final seriesByAxis = <String, List<String>>{};
    final unboundSeries = <String>[];

    for (final s in series) {
      final binding = _resolveSingleBinding(s);

      if (binding.bindingType == BindingType.unbound) {
        unboundSeries.add(s.id);
      } else {
        bindings.add(binding);
        seriesByAxis.putIfAbsent(binding.axisId, () => []).add(s.id);
      }
    }

    return SeriesAxisResolution(
      bindings: bindings,
      seriesByAxis: seriesByAxis,
      unboundSeries: unboundSeries,
      defaultAxisId: defaultAxisId,
    );
  }

  /// Resolves a single series to its axis.
  SeriesAxisBinding _resolveSingleBinding(ChartSeries s) {
    // 1. Explicit binding via yAxisId
    if (s.yAxisId != null) {
      if (_axisMap.containsKey(s.yAxisId)) {
        return SeriesAxisBinding(
          seriesId: s.id,
          axisId: s.yAxisId!,
          bindingType: BindingType.explicit,
        );
      }
      // yAxisId specified but axis not found - fall through to unit matching
    }

    // 2. Unit-based matching
    if (s.unit != null && _unitToAxisMap.containsKey(s.unit)) {
      return SeriesAxisBinding(
        seriesId: s.id,
        axisId: _unitToAxisMap[s.unit]!,
        bindingType: BindingType.unitMatch,
      );
    }

    // 3. Default assignment
    final defaultId = defaultAxisId;
    if (defaultId != null) {
      return SeriesAxisBinding(
        seriesId: s.id,
        axisId: defaultId,
        bindingType: BindingType.defaultAssignment,
      );
    }

    // No axis available
    return SeriesAxisBinding(
      seriesId: s.id,
      axisId: '',
      bindingType: BindingType.unbound,
    );
  }

  /// Resolves a single series by its ID or object.
  ///
  /// Static convenience method for resolving one series.
  ///
  /// Returns the axis ID if found, null otherwise.
  static String? resolveSeriesAxisBinding(
    ChartSeries series,
    List<String> availableAxisIds,
  ) {
    if (series.yAxisId != null) {
      if (availableAxisIds.contains(series.yAxisId)) {
        return series.yAxisId;
      }
      // yAxisId specified but not in available list
      return null;
    }
    // No yAxisId, return null (caller should use default)
    return null;
  }

  /// Computes auto axis assignments for all series.
  ///
  /// Static convenience method matching the API expected by tests.
  ///
  /// Returns a map of series ID to axis ID.
  static Map<String, String> computeAutoAxisAssignments(
    List<ChartSeries> series,
    List<YAxisConfig> configs,
  ) {
    if (configs.isEmpty) return {};

    final resolver = SeriesAxisResolver(
      axisConfigs: configs,
      series: series,
    );

    final resolution = resolver.resolve();
    return resolution.seriesAxisMap;
  }
}

/// Extension on generic series-like objects for testing.
///
/// Allows resolution of mock series objects that have the same properties
/// as [ChartSeries] but aren't instances of it.
extension SeriesAxisResolverExt on SeriesAxisResolver {
  /// Resolves bindings for mock series objects.
  ///
  /// Used in tests where mock series objects are used instead of [ChartSeries].
  static Map<String, String> resolveBindingsForMocks<T>({
    required List<T> series,
    required List<YAxisConfig> configs,
    required String Function(T) getId,
    required String? Function(T) getYAxisId,
    required String? Function(T) getUnit,
  }) {
    if (configs.isEmpty) return {};

    final axisMap = {for (final c in configs) c.id: c};
    final unitToAxisMap = {
      for (final c in configs)
        if (c.unit != null) c.unit!: c.id,
    };

    // Find default axis
    String? defaultAxisId;
    for (final config in configs) {
      if (config.position == YAxisPosition.left) {
        defaultAxisId = config.id;
        break;
      }
    }
    defaultAxisId ??= configs.isNotEmpty ? configs.first.id : null;

    final result = <String, String>{};

    for (final s in series) {
      final id = getId(s);
      final yAxisId = getYAxisId(s);
      final unit = getUnit(s);

      // 1. Explicit binding
      if (yAxisId != null && axisMap.containsKey(yAxisId)) {
        result[id] = yAxisId;
        continue;
      }

      // 2. Unit matching
      if (unit != null && unitToAxisMap.containsKey(unit)) {
        result[id] = unitToAxisMap[unit]!;
        continue;
      }

      // 3. Default
      if (defaultAxisId != null) {
        result[id] = defaultAxisId;
      }
    }

    return result;
  }
}
