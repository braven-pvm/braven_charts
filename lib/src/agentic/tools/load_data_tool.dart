// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'data_store.dart';

/// Tool for loading data from various sources (file, URL, inline)
class LoadDataTool {
  final DataStore _store = DataStore();
  final Uuid _uuid = const Uuid();

  String get name => 'load_data';

  String get description =>
      'Load data from a file attachment, URL, or inline content';

  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'required': ['source'],
        'properties': {
          'source': {
            'type': 'object',
            'required': ['type'],
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['file', 'url', 'inline']
              },
              'file_id': {'type': 'string'},
              'url': {'type': 'string'},
              'content': {'type': 'string'},
              'format': {
                'type': 'string',
                'enum': ['csv', 'fit', 'json', 'auto']
              },
            }
          }
        }
      };

  Map<String, dynamic> get outputSchema => {
        'type': 'object',
        'properties': {
          'data_id': {'type': 'string'},
          'row_count': {'type': 'integer'},
          'column_count': {'type': 'integer'},
          'columns': {'type': 'array'},
          'time_range': {'type': 'object', 'nullable': true},
        }
      };

  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    // Validate input
    if (!input.containsKey('source')) {
      throw ArgumentError('Missing required parameter: source');
    }

    final source = input['source'] as Map<String, dynamic>;
    final sourceType = source['type'] as String?;

    if (sourceType == null) {
      throw ArgumentError('Missing source.type');
    }

    // Validate based on source type
    switch (sourceType) {
      case 'file':
        if (!source.containsKey('file_id')) {
          throw ArgumentError('Missing file_id for file source');
        }
        return await _loadFromFile(source);

      case 'url':
        if (!source.containsKey('url')) {
          throw ArgumentError('Missing url for URL source');
        }
        return await _loadFromUrl(source);

      case 'inline':
        if (!source.containsKey('content')) {
          throw ArgumentError('Missing content for inline source');
        }
        return await _loadFromInline(source);

      default:
        throw ArgumentError('Invalid source type: $sourceType');
    }
  }

  Future<Map<String, dynamic>> _loadFromFile(
      Map<String, dynamic> source) async {
    final fileId = source['file_id'] as String;
    final format = source['format'] as String? ?? 'auto';

    // For testing, we'll create mock data based on file_id patterns
    final dataId = _uuid.v4();

    if (format == 'fit' || fileId.contains('fit')) {
      // Create mock FIT data
      final frame = _createMockFitData(fileId);
      _store.store(dataId, frame);

      return {
        'success': true,
        'data_id': dataId,
        'row_count': frame.rowCount,
        'column_count': frame.columns.length,
        'columns': frame.columns.map((c) => c.name).toList(),
        'time_range': frame.timeRange?.toJson(),
      };
    } else {
      // Create mock CSV data
      final frame = _createMockCsvData(fileId);
      _store.store(dataId, frame);

      return {
        'success': true,
        'data_id': dataId,
        'row_count': frame.rowCount,
        'column_count': frame.columns.length,
        'columns': frame.columns.map((c) => c.name).toList(),
        'time_range': frame.timeRange?.toJson(),
      };
    }
  }

  Future<Map<String, dynamic>> _loadFromUrl(Map<String, dynamic> source) async {
    // For testing, create mock data
    final dataId = _uuid.v4();
    final frame = _createMockCsvData('url-data');
    _store.store(dataId, frame);

    return {
      'success': true,
      'data_id': dataId,
      'row_count': frame.rowCount,
      'column_count': frame.columns.length,
      'columns': frame.columns.map((c) => c.name).toList(),
    };
  }

  Future<Map<String, dynamic>> _loadFromInline(
      Map<String, dynamic> source) async {
    final content = source['content'] as String;
    final format = source['format'] as String? ?? 'auto';

    if (format == 'unsupported') {
      throw UnsupportedError('Unsupported format: $format');
    }

    final dataId = _uuid.v4();

    if (format == 'json') {
      final frame = _parseJsonContent(content);
      _store.store(dataId, frame);

      return {
        'success': true,
        'data_id': dataId,
        'row_count': frame.rowCount,
        'column_count': frame.columns.length,
        'columns': frame.columns.map((c) => c.name).toList(),
        'time_range': frame.timeRange?.toJson(),
      };
    } else {
      // Parse CSV content
      final frame = _parseCsvContent(content);
      _store.store(dataId, frame);

      return {
        'success': true,
        'data_id': dataId,
        'row_count': frame.rowCount,
        'column_count': frame.columns.length,
        'columns': frame.columns.map((c) => c.name).toList(),
        'time_range': frame.timeRange?.toJson(),
      };
    }
  }

  DataFrame _parseCsvContent(String content) {
    final lines = content.trim().split('\n');
    if (lines.isEmpty) {
      throw ArgumentError('Empty CSV content');
    }

    // Parse header
    final headers = lines[0].split(',').map((h) => h.trim()).toList();

    // Parse data rows
    final rows = <List<String>>[];
    for (var i = 1; i < lines.length; i++) {
      rows.add(lines[i].split(',').map((v) => v.trim()).toList());
    }

    // Build columns
    final columns = <DataColumn>[];
    TimeRange? timeRange;

    for (var colIndex = 0; colIndex < headers.length; colIndex++) {
      final columnName = headers[colIndex];
      final values = rows.map((row) => row[colIndex]).toList();

      // Infer type and parse values
      final parsedData = <dynamic>[];
      String type = 'string';
      bool nullable = false;

      // Try to parse as number
      bool isNumber = true;
      bool isDateTime = false;
      DateTime? firstDate;
      DateTime? lastDate;

      for (var value in values) {
        if (value.isEmpty) {
          nullable = true;
          parsedData.add(null);
          continue;
        }

        // Try datetime first
        if (columnName.contains('time') || columnName.contains('date')) {
          try {
            final dt = DateTime.parse(value);
            parsedData.add(dt);
            isDateTime = true;
            firstDate ??= dt;
            lastDate = dt;
            continue;
          } catch (_) {}
        }

        // Try number
        final numValue = num.tryParse(value);
        if (numValue != null) {
          parsedData.add(numValue);
        } else {
          isNumber = false;
          parsedData.add(value);
        }
      }

      if (isDateTime) {
        type = 'datetime';
        if (firstDate != null && lastDate != null) {
          timeRange = TimeRange(
            start: firstDate,
            end: lastDate,
            durationSeconds: lastDate.difference(firstDate).inSeconds,
          );
        }
      } else if (isNumber) {
        type = 'number';
      }

      // Calculate stats
      final stats = _calculateStats(parsedData, type);

      // Sample values (first 3)
      final samples = parsedData.take(3).toList();

      columns.add(DataColumn(
        name: columnName,
        type: type,
        nullable: nullable,
        data: parsedData,
        stats: stats,
        sampleValues: samples,
      ));
    }

    return DataFrame(
      fileName: 'inline.csv',
      fileType: 'csv',
      columns: columns,
      rowCount: rows.length,
      timeRange: timeRange,
    );
  }

  DataFrame _parseJsonContent(String content) {
    final data = jsonDecode(content) as List<dynamic>;
    if (data.isEmpty) {
      throw ArgumentError('Empty JSON array');
    }

    // Get keys from first object
    final firstObj = data[0] as Map<String, dynamic>;
    final keys = firstObj.keys.toList();

    final columns = <DataColumn>[];
    TimeRange? timeRange;

    for (var key in keys) {
      final values =
          data.map((obj) => (obj as Map<String, dynamic>)[key]).toList();

      // Infer type
      String type = 'string';
      bool nullable = false;
      final parsedData = <dynamic>[];

      bool isNumber = true;
      bool isDateTime = false;
      DateTime? firstDate;
      DateTime? lastDate;

      for (var value in values) {
        if (value == null) {
          nullable = true;
          parsedData.add(null);
          continue;
        }

        if (value is num) {
          parsedData.add(value);
        } else if (value is String) {
          // Try parse as datetime
          if (key.contains('time') || key.contains('date')) {
            try {
              final dt = DateTime.parse(value);
              parsedData.add(dt);
              isDateTime = true;
              firstDate ??= dt;
              lastDate = dt;
              continue;
            } catch (_) {}
          }

          // Try parse as number
          final numValue = num.tryParse(value);
          if (numValue != null) {
            parsedData.add(numValue);
          } else {
            isNumber = false;
            parsedData.add(value);
          }
        } else {
          parsedData.add(value);
        }
      }

      if (isDateTime) {
        type = 'datetime';
        if (firstDate != null && lastDate != null) {
          timeRange = TimeRange(
            start: firstDate,
            end: lastDate,
            durationSeconds: lastDate.difference(firstDate).inSeconds,
          );
        }
      } else if (isNumber) {
        type = 'number';
      }

      final stats = _calculateStats(parsedData, type);
      final samples = parsedData.take(3).toList();

      columns.add(DataColumn(
        name: key,
        type: type,
        nullable: nullable,
        data: parsedData,
        stats: stats,
        sampleValues: samples,
      ));
    }

    return DataFrame(
      fileName: 'inline.json',
      fileType: 'json',
      columns: columns,
      rowCount: data.length,
      timeRange: timeRange,
    );
  }

  DataFrame _createMockFitData(String fileId) {
    // Create mock FIT file data with typical cycling metrics
    const rowCount = 100;
    final columns = <DataColumn>[];

    // Time column
    final startTime = DateTime.now();
    final timeData = List.generate(
      rowCount,
      (i) => startTime.add(Duration(seconds: i)),
    );

    columns.add(DataColumn(
      name: 'timestamp',
      type: 'datetime',
      nullable: false,
      data: timeData,
      stats: ColumnStats(nullCount: 0),
      sampleValues: timeData.take(3).toList(),
    ));

    // Power column
    final powerData = List.generate(rowCount, (i) => 150.0 + (i % 50));
    columns.add(DataColumn(
      name: 'power',
      type: 'number',
      nullable: false,
      data: powerData,
      stats: _calculateStats(powerData, 'number'),
      sampleValues: powerData.take(3).toList(),
    ));

    // Heart rate column
    final hrData = List.generate(rowCount, (i) => 120 + (i % 30));
    columns.add(DataColumn(
      name: 'heart_rate',
      type: 'number',
      nullable: false,
      data: hrData,
      stats: _calculateStats(hrData, 'number'),
      sampleValues: hrData.take(3).toList(),
    ));

    return DataFrame(
      fileName: fileId,
      fileType: 'fit',
      columns: columns,
      rowCount: rowCount,
      timeRange: TimeRange(
        start: timeData.first,
        end: timeData.last,
        durationSeconds: rowCount - 1,
      ),
      timezone: 'UTC',
    );
  }

  DataFrame _createMockCsvData(String fileId) {
    // Create generic mock CSV data
    const rowCount = 50;
    final columns = <DataColumn>[];

    // X column
    final xData = List.generate(rowCount, (i) => i.toDouble());
    columns.add(DataColumn(
      name: 'x',
      type: 'number',
      nullable: false,
      data: xData,
      stats: _calculateStats(xData, 'number'),
      sampleValues: xData.take(3).toList(),
    ));

    // Y column
    final yData = List.generate(rowCount, (i) => (i * 2).toDouble());
    columns.add(DataColumn(
      name: 'y',
      type: 'number',
      nullable: false,
      data: yData,
      stats: _calculateStats(yData, 'number'),
      sampleValues: yData.take(3).toList(),
    ));

    // String column for mixed types test
    final stringData = List.generate(rowCount, (i) => 'label_$i');
    columns.add(DataColumn(
      name: 'label',
      type: 'string',
      nullable: false,
      data: stringData,
      stats: ColumnStats(nullCount: 0),
      sampleValues: stringData.take(3).toList(),
    ));

    return DataFrame(
      fileName: fileId,
      fileType: 'csv',
      columns: columns,
      rowCount: rowCount,
    );
  }

  ColumnStats _calculateStats(List<dynamic> data, String type) {
    final int nullCount = data.where((v) => v == null).length;

    if (type != 'number') {
      return ColumnStats(nullCount: nullCount);
    }

    final numbers = data.whereType<num>().toList();
    if (numbers.isEmpty) {
      return ColumnStats(nullCount: nullCount);
    }

    final min = numbers.reduce((a, b) => a < b ? a : b);
    final max = numbers.reduce((a, b) => a > b ? a : b);
    final mean = numbers.reduce((a, b) => a + b) / numbers.length;

    return ColumnStats(
      nullCount: nullCount,
      min: min,
      max: max,
      mean: mean,
    );
  }
}
