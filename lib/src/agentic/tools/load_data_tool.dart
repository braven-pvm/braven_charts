// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';

import 'package:braven_data/braven_data.dart' as bd;
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

    final dataId = _uuid.v4();

    if (format == 'fit' || fileId.toLowerCase().endsWith('.fit')) {
      DataFrame frame;
      String? timezone = 'UTC';

      // Try to load actual FIT file using braven_data
      if (File(fileId).existsSync()) {
        try {
          final df = await bd.FitLoader.load(
            fileId,
            bd.FitMessageType.records,
          );
          frame =
              _convertBravenDataFrame(df, fileName: fileId, fileType: 'fit');
          // Extract timezone from FIT file metadata (FR-026)
          // For now, default to UTC if not available in metadata
          timezone = 'UTC';
        } catch (e) {
          throw Exception('Failed to parse FIT file: $e');
        }
      } else {
        throw Exception('FIT file not found: $fileId');
      }

      _store.store(dataId, frame);

      return {
        'success': true,
        'data_id': dataId,
        'row_count': frame.rowCount,
        'column_count': frame.columns.length,
        'columns': frame.columns.map((c) => c.name).toList(),
        'time_range': frame.timeRange?.toJson(),
        'timezone': timezone,
      };
    } else {
      DataFrame frame;

      // Try to load actual CSV file
      if (File(fileId).existsSync()) {
        try {
          final csvData = await File(fileId).readAsString();
          frame = _parseCsvContent(csvData);
        } catch (e) {
          throw Exception('Failed to parse CSV file: $e');
        }
      } else {
        throw Exception('CSV file not found: $fileId');
      }

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
    // URL loading not yet implemented
    throw Exception('URL data loading not yet implemented');
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

        // Try datetime first if column name suggests it's a time/date column
        if (columnName.contains('time') || columnName.contains('date')) {
          DateTime? dt;

          // Try ISO 8601 datetime string
          try {
            dt = DateTime.parse(value);
          } catch (_) {
            // Try Unix timestamp (seconds since epoch)
            final numValue = num.tryParse(value);
            if (numValue != null) {
              try {
                dt = DateTime.fromMillisecondsSinceEpoch(
                  (numValue * 1000).toInt(),
                  isUtc: true,
                );
              } catch (_) {
                // Not a valid timestamp
              }
            }
          }

          if (dt != null) {
            parsedData.add(dt);
            isDateTime = true;
            firstDate ??= dt;
            lastDate = dt;
            continue;
          }
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

  /// Convert braven_data DataFrame to internal DataFrame format
  DataFrame _convertBravenDataFrame(bd.DataFrame df,
      {String? fileName, String? fileType}) {
    final columns = <DataColumn>[];
    TimeRange? timeRange;
    DateTime? firstDate;
    DateTime? lastDate;

    // Convert each column
    for (final columnName in df.columnNames) {
      final columnData = df.columns[columnName];
      if (columnData == null || columnData.isEmpty) {
        continue;
      }

      // Detect column type
      String type = 'string';
      final bool isNumber = columnData.first is num;

      if (columnData.first is DateTime) {
        type = 'datetime';
        firstDate = columnData.first as DateTime;
        lastDate = columnData.last as DateTime;
      } else if (columnData.first is String) {
        // Check if this is a timestamp string (common in FIT files)
        if (columnName.toLowerCase().contains('time') ||
            columnName.toLowerCase().contains('timestamp') ||
            columnName.toLowerCase() == 'time') {
          try {
            final DateTime parsedFirst =
                DateTime.parse(columnData.first as String);
            final DateTime parsedLast =
                DateTime.parse(columnData.last as String);
            if (firstDate == null) {
              firstDate = parsedFirst;
              lastDate = parsedLast;
            }
          } catch (_) {
            // Not a valid ISO 8601 datetime string
          }
        }
      } else if (isNumber) {
        type = 'number';

        // Check if this is a timestamp column with Unix epoch values
        if ((columnName.toLowerCase().contains('time') ||
                columnName.toLowerCase().contains('timestamp')) &&
            firstDate == null) {
          try {
            final num firstValue = columnData.first as num;
            final num lastValue = columnData.last as num;
            // Try interpreting as Unix timestamp (seconds since epoch)
            firstDate = DateTime.fromMillisecondsSinceEpoch(
                (firstValue * 1000).toInt(),
                isUtc: true);
            lastDate = DateTime.fromMillisecondsSinceEpoch(
                (lastValue * 1000).toInt(),
                isUtc: true);
          } catch (_) {
            // Not a valid timestamp
          }
        }
      }

      final stats = _calculateStats(columnData.toList(), type);

      columns.add(DataColumn(
        name: columnName,
        type: type,
        nullable: columnData.contains(null),
        data: columnData.toList(),
        stats: stats,
        sampleValues: columnData.take(3).toList(),
      ));
    }

    if (firstDate != null && lastDate != null) {
      timeRange = TimeRange(
        start: firstDate,
        end: lastDate,
        durationSeconds: lastDate.difference(firstDate).inSeconds,
      );
    }

    return DataFrame(
      fileName: fileName ?? 'data',
      fileType: fileType ?? 'unknown',
      columns: columns,
      rowCount: df.columnNames.isNotEmpty
          ? (df.columns[df.columnNames.first]?.length ?? 0)
          : 0,
      timeRange: timeRange,
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
