import 'dart:math';

// Import the Metric definitions (Simulated here for single-file runnable)
// import 'power_metrics.dart';

/// --------------------------------------------------------------------------
/// MOCK API FRAMEWORK (Represents the proposed 'braven_chart_plus/data' pkg)
/// --------------------------------------------------------------------------

/// 1. Schema Definition
class CsvSchema {
  final String dateColumn;
  final List<ColumnDef> columns;
  final String dateFormat;

  const CsvSchema({
    required this.dateColumn,
    this.dateFormat = 'ISO8601', // Default
    required this.columns,
  });
}

class ColumnDef {
  final String name;
  final FieldType type;
  const ColumnDef(this.name, this.type);
}

enum FieldType { float, integer, string }

/// 2. The DataFrame (Columnar Store)
class DataFrame {
  final Map<String, List<dynamic>> _columns;
  DataFrame(this._columns);
  List<T> get<T>(String columnName) => _columns[columnName] as List<T>;
}

/// 3. Series Pipeline with Extensions
class SeriesPipeline {
  final Series<dynamic, double> _source;

  SeriesPipeline(this._source);

  /// Apply a metric calculation (Scalar)
  T compute<T>(SeriesMetric<T> metric) {
    return metric.calculate(_source);
  }

  /// Create a Rolling Window Pipeline
  RollingPipeline rolling(
      {required Duration window, WindowAlignment align = WindowAlignment.end}) {
    // In real impl, we'd check X domain type. Assuming seconds here.
    return RollingPipeline(_source, window, align);
  }
}

enum WindowAlignment { start, center, end }

class RollingPipeline {
  final Series<dynamic, double> source;
  final Duration window;
  final WindowAlignment align;

  RollingPipeline(this.source, this.window, this.align);

  /// Apply a Reducer to the rolling window to create a new Series
  Series<double, double> reduce(SeriesReducer<double> reducer) {
    print(
        '  -> Calculating Rolling ${reducer.runtimeType} over ${window.inSeconds}s (Align: ${align.name})...');

    final inputY = source.storage.yAsList;
    final int winSize = window.inSeconds;
    final outY = <double>[];
    final outX = <double>[];

    // Naive rolling implementation
    for (int i = 0; i < inputY.length; i++) {
      // Trailing Window Logic (Simplest case)
      final int start = max(0, i - winSize + 1);
      final int end = i + 1;

      final windowData = inputY.sublist(start, end);
      outY.add(reducer.reduce(windowData));

      // Simplified Time Assignment:
      // Rolling/Smoothing usually preserves input timestamp (Trailing Alignment)
      outX.add(i.toDouble());
    }

    return ConcreteSeries(
        id: '${source.id}_rolling_$winSize', xData: outX, yData: outY);
  }
}

/// Extension to add "Syntax Sugar" for Power Metrics
extension PowerCalculations on SeriesPipeline {
  double calculateNormalizedPower() => compute(const NormalizedPowerMetric());
  double calculateXPower() => compute(const XPowerMetric());
  double calculateVariabilityIndex() => compute(const VariabilityIndexMetric());
}

/// --------------------------------------------------------------------------
/// FRAMEWORK INTERFACES (From power_metrics.dart)
/// --------------------------------------------------------------------------

abstract class Series<TX, TY> {
  SeriesStorage<TX, TY> get storage;
  String get id;
}

abstract class SeriesStorage<TX, TY> {
  List<TY> get yAsList;
}

abstract class SeriesMetric<T> {
  const SeriesMetric();
  T calculate(Series<dynamic, double> series);
}

abstract class SeriesReducer<T> {
  const SeriesReducer();
  T reduce(List<double> windowValues);
}

class ConcreteSeries<TX, TY> implements Series<TX, TY> {
  final List<TX> xData;
  final List<TY> yData;
  @override
  final String id;

  ConcreteSeries({required this.id, required this.xData, required this.yData});

  @override
  SeriesStorage<TX, TY> get storage => MockStorage(yData);
}

class MockStorage<TX, TY> implements SeriesStorage<TX, TY> {
  final List<TY> _data;
  MockStorage(this._data);
  @override
  List<TY> get yAsList => _data;
}

/// --------------------------------------------------------------------------
/// DOMAIN LOGIC: REDUCERS & METRICS
/// --------------------------------------------------------------------------

// Reducer: Simple Mean
class MeanReducer implements SeriesReducer<double> {
  const MeanReducer();
  @override
  double reduce(List<double> values) {
    if (values.isEmpty) return 0.0;
    double sum = 0.0;
    for (final v in values) sum += v;
    return sum / values.length;
  }
}

// Reducer: Normalized Power for a Window
class NormalizedPowerReducer implements SeriesReducer<double> {
  const NormalizedPowerReducer();
  @override
  double reduce(List<double> values) {
    if (values.isEmpty) return 0.0;
    // NP Formula: Root4(Avg(Pow4))
    double sum4th = 0.0;
    for (final v in values) sum4th += pow(v, 4);
    return pow(sum4th / values.length, 0.25).toDouble();
  }
}

// Metric: Whole Ride NP
class NormalizedPowerMetric implements SeriesMetric<double> {
  const NormalizedPowerMetric();
  @override
  double calculate(Series<dynamic, double> series) {
    // For whole ride, we usually need 30s smoothing first.
    // But for this mock, we'll verify valid data only.
    // Real impl would call _calculateSMA first.
    return const NormalizedPowerReducer().reduce(series.storage.yAsList);
  }
}

class XPowerMetric implements SeriesMetric<double> {
  const XPowerMetric();
  @override
  double calculate(Series series) => 0.0; // Placeholder
}

class VariabilityIndexMetric implements SeriesMetric<double> {
  const VariabilityIndexMetric();
  @override
  double calculate(Series series) => 1.05; // Placeholder
}

/// --------------------------------------------------------------------------
/// REAL-WORLD EXAMPLE: Garmin FIT/CSV Ingestion
/// --------------------------------------------------------------------------

void main() async {
  print('--- BEGIN SCIENTIFIC DATA INGESTION ---');

  // A. DEFINE SCHEMA
  // Matches: data/tp-2023646.2025-10-26-13-23-16-784Z.GarminPing.AAAAAGj-IMQ_uYSx_core_records.csv
  const schema = CsvSchema(dateColumn: 'timestamp', columns: [
    ColumnDef('power', FieldType.float),
    ColumnDef('heart_rate', FieldType.integer),
  ]);

  // B. LOAD DATA
  final table = await _mockCsvLoaderLoad('garmin_data.csv', schema);

  print("Loaded DataFrame with ${table.get('power').length} rows.");

  // C. EXTRACT SERIES
  final timeBuffer = table
      .get<DateTime>('timestamp')
      .map((dt) => dt.millisecondsSinceEpoch.toDouble())
      .toList();

  final powerSeries = ConcreteSeries<double, double>(
    id: 'cycling_power',
    xData: timeBuffer,
    yData: table.get<double>('power'),
  );

  // D. APPLY SCIENTIFIC CALCULATIONS (SCALARS)

  final pipeline = SeriesPipeline(powerSeries);

  // 1. Normalized Power (NP)
  final np = pipeline.calculateNormalizedPower();
  print(
      'Metric: Normalized Power (NP) [Whole Ride]: ${np.toStringAsFixed(1)} W');

  // E. GENERATE PLOTTING DATA (SERIES)
  // "I want to see the 30s average power curve over time"

  print('\n--- GENERATING PLOT DATA ---');

  // 1. Rolling 30s Average
  final rollingAvg30 = pipeline
      .rolling(window: const Duration(seconds: 30))
      .reduce(const MeanReducer());

  print(
      "Generated '${rollingAvg30.id}' with ${rollingAvg30.storage.yAsList.length} points.");
  print(
      'Sample (T=60s): ${rollingAvg30.storage.yAsList[60].toStringAsFixed(1)} W');

  // 2. Rolling 30s "Normalized" (Intensity)
  final rollingNP30 = pipeline
      .rolling(window: const Duration(seconds: 30))
      .reduce(const NormalizedPowerReducer());

  print(
      "Generated '${rollingNP30.id}' with ${rollingNP30.storage.yAsList.length} points.");
  print(
      'Sample (T=60s): ${rollingNP30.storage.yAsList[60].toStringAsFixed(1)} W (Weighted)');

  print('--- END ANALYSIS ---');
}

/// --------------------------------------------------------------------------
/// MOCK LOADER
/// --------------------------------------------------------------------------

Future<DataFrame> _mockCsvLoaderLoad(String path, CsvSchema schema) async {
  const count = 1000;
  final timestamps = <DateTime>[];
  final power = <double>[];
  final hr = <double>[];

  final start = DateTime.parse('2025-10-26 07:32:46+02:00');

  for (int i = 0; i < count; i++) {
    timestamps.add(start.add(Duration(seconds: i)));
    // Base 150W + Noise +/- 20W + Occasional 400W surge
    double p = 150.0 + (Random().nextDouble() * 40 - 20);
    if (i % 60 == 0) p = 400.0;
    power.add(p);
    hr.add(140.0 + (Random().nextDouble() * 5));
  }

  return DataFrame({
    'timestamp': timestamps,
    'power': power,
    'heart_rate': hr,
  });
}
