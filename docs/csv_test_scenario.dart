import 'package:braven_chart_plus/src/braven_chart_plus.dart';

void main() async {
  // 1. Ingest Data: Define Schema
  // This matches (subset of) the CSV provided
  final schema =
      CsvSchema(xColumn: 'timestamp', xType: DataType.timestamp, columns: [
    ColumnDef(name: 'power', type: DataType.float32), // Cyclic power
    ColumnDef(
        name: 'heart_rate', type: DataType.float32), // Int but float is safe
    ColumnDef(name: 'cadence', type: DataType.float32),
    ColumnDef(name: 'speed', type: DataType.float32),
  ]);

  // 2. Load "Raw Table"
  // In a real app this would use CsvLoader.load(), here we mock the structure
  // derived from "tp-2023646...records.csv"
  final rawTable = await MockCsvLoader.load('tp-2023646...csv', schema);

  // 3. Create Series: Semantic Mapping
  // Notice: 'powerSeries' and 'hrSeries' are just views on the raw table columns.

  // Power Series: Watts per second
  final powerSeries = Series.fromColumns(
      id: 'power_watts',
      x: rawTable['timestamp'],
      y: rawTable['power'],
      xDomain: AxisDomain.time(),
      yDomain: AxisDomain.numeric(unit: 'W'));

  // HR Series: Beats per minute
  final hrSeries = Series.fromColumns(
      id: 'heart_rate_bpm',
      x: rawTable['timestamp'],
      y: rawTable['heart_rate'],
      xDomain: AxisDomain.time(),
      yDomain: AxisDomain.numeric(unit: 'bpm'));

  // 4. Aggregation Pipeline: "Meaningful Metrics"

  // Scenario A: Average Power (30s moving average)
  // Cyclists use 1s, 3s, 10s, 30s power averages to smooth out pedal strokes.
  final avgPower30s = SeriesPipeline(powerSeries)
      .window(WindowSpec.sliding(duration: const Duration(seconds: 30)))
      .reduce({ReducerType.mean}).toRenderSeries();

  // Scenario B: Max Power (Peak) per Minute
  // Find the strongest sprint in each minute block.
  final maxPower1m = SeriesPipeline(powerSeries)
      .window(WindowSpec.fixed(duration: const Duration(minutes: 1)))
      .reduce({ReducerType.max}).toRenderSeries();

  // Scenario C: Heart Rate Drift (Mean per 5 min)
  // Track aerobic decoupling over long rides.
  final hrTrend = SeriesPipeline(hrSeries)
      .window(WindowSpec.fixed(duration: const Duration(minutes: 5)))
      .reduce({
    ReducerType.mean,
    ReducerType.min,
    ReducerType.max
  }).toRenderSeries();

  print('Pipelines Configured. Ready for Render.');
}

// --- Mocks to simulate the API structure ---

class CsvSchema {
  final String xColumn;
  final DataType xType;
  final List<ColumnDef> columns;
  CsvSchema(
      {required this.xColumn, required this.xType, required this.columns});
}

class ColumnDef {
  final String name;
  final DataType type;
  ColumnDef({required this.name, required this.type});
}

enum DataType { float32, float64, timestamp, string }

class MockCsvLoader {
  static Future<Map<String, dynamic>> load(
      String path, CsvSchema schema) async {
    return {
      'timestamp': [1700000000, 1700000001, 1700000002], // Mock timestamps
      'power': [100.0, 102.0, 103.0],
      'heart_rate': [85.0, 86.0, 86.0],
    };
  }
}

class Series {
  static void fromColumns(
      {required String id,
      required dynamic x,
      required dynamic y,
      required AxisDomain xDomain,
      required AxisDomain yDomain}) {}
}

class AxisDomain {
  static void time() {}
  static void numeric({String? unit}) {}
}

class SeriesPipeline {
  SeriesPipeline(dynamic series);
  SeriesPipeline window(dynamic spec) => this;
  SeriesPipeline reduce(Set<ReducerType> types) => this;
  dynamic toRenderSeries() {}
}

class WindowSpec {
  static void fixed({required Duration duration}) {}
  static void sliding({required Duration duration}) {}
}

enum ReducerType { mean, max, min }
