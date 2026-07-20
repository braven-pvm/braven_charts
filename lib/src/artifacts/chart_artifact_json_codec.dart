import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'chart_artifact_diagnostics.dart';
import 'chart_artifact.dart';
import 'chart_artifact_migrations.dart';
import 'json_value.dart';

/// Decoded artifact plus schema-version and migration provenance.
@immutable
class ChartArtifactDecodeResult {
  ChartArtifactDecodeResult({
    required this.artifact,
    required this.sourceSchemaVersion,
    required this.migratedSchemaVersion,
    Iterable<String> migrationsApplied = const [],
  }) : migrationsApplied = List.unmodifiable(migrationsApplied);

  final ChartArtifact artifact;
  final int sourceSchemaVersion;
  final int migratedSchemaVersion;
  final List<String> migrationsApplied;
}

/// Deterministic JSON transport codec for the chart artifact envelope.
///
/// [encode] validates the current schema and returns canonical JSON. [decode]
/// validates untrusted input, applies only explicitly registered adjacent
/// migrations, and reports unsupported capabilities before hydration.
abstract final class ChartArtifactJsonCodec {
  static ChartArtifactResult<String> encode(
    ChartArtifact artifact, {
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
  }) {
    if (artifact.schemaVersion != ChartArtifact.currentSchemaVersion) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
          message:
              'Cannot encode schema ${artifact.schemaVersion}; '
              'this renderer writes schema '
              '${ChartArtifact.currentSchemaVersion}.',
          path: r'$.schemaVersion',
        ),
      );
    }
    final semanticFailure = _validateArtifactSemantics(artifact, limits);
    if (semanticFailure != null) {
      return ChartArtifactFailure(error: semanticFailure);
    }

    try {
      _validateRawDocumentCounts(artifact.toJson(), limits);
      final encoded = canonicalJsonEncode(artifact.toJson());
      final encodedBytes = utf8.encode(encoded).length;
      if (encodedBytes > limits.maxEncodedBytes) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
            message:
                'Encoded artifact is $encodedBytes bytes; maximum is '
                '${limits.maxEncodedBytes}.',
            path: r'$',
          ),
        );
      }
      return ChartArtifactSuccess(value: encoded);
    } on _LimitException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: error.code,
          message: error.message,
          path: error.path,
        ),
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
        ),
      );
    }
  }

  static ChartArtifactResult<ChartArtifactDecodeResult> decode(
    String encoded, {
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
    Set<String> supportedCapabilities = const {},
    Iterable<ChartArtifactMigration> migrations = const [],
  }) {
    if (encoded.length > limits.maxEncodedBytes) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message: 'Artifact exceeds the ${limits.maxEncodedBytes}-byte limit.',
          path: r'$',
        ),
      );
    }
    final encodedBytes = utf8.encode(encoded).length;
    if (encodedBytes > limits.maxEncodedBytes) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message:
              'Artifact is $encodedBytes bytes; maximum is '
              '${limits.maxEncodedBytes}.',
          path: r'$',
        ),
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(encoded);
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidJson,
          message: error.message,
          path: r'$',
        ),
      );
    }

    try {
      _validateStructure(decoded, limits);
      var root = _stringMap(decoded);
      final version = root['schemaVersion'];
      if (version is! int) {
        throw const FormatException('schemaVersion must be an integer');
      }
      if (version > ChartArtifact.currentSchemaVersion) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.unsupportedSchemaVersion,
            message:
                'Schema $version is unsupported; this renderer supports '
                'schema ${ChartArtifact.currentSchemaVersion}.',
            path: r'$.schemaVersion',
          ),
        );
      }

      var migratedSchemaVersion = version;
      var migrationsApplied = const <String>[];
      if (version < ChartArtifact.currentSchemaVersion) {
        final migrated = ChartArtifactMigrationRegistry(migrations).migrate(
          root,
          targetSchemaVersion: ChartArtifact.currentSchemaVersion,
        );
        if (migrated case ChartArtifactFailure<ChartArtifactMigrationRun>()) {
          return ChartArtifactFailure(
            error: migrated.error,
            warnings: migrated.warnings,
          );
        }
        final run =
            (migrated as ChartArtifactSuccess<ChartArtifactMigrationRun>).value;
        root = run.artifactJson;
        migratedSchemaVersion = run.migratedSchemaVersion;
        migrationsApplied = run.migrationsApplied;
        _validateStructure(root, limits);
      }

      _validateRawDocumentCounts(root, limits);
      final artifact = ChartArtifact.fromJson(root);
      final semanticFailure = _validateArtifactSemantics(artifact, limits);
      if (semanticFailure != null) {
        return ChartArtifactFailure(error: semanticFailure);
      }

      final requiredCapabilities = <String>{
        ...artifact.document.requiredCapabilities,
        for (final annotation in artifact.document.annotations)
          ...annotation.requiredCapabilities,
        for (final series in artifact.document.series)
          ...series.requiredCapabilities,
        for (final series in artifact.document.series)
          for (final annotation in series.annotations)
            ...annotation.requiredCapabilities,
      };
      final unsupported = requiredCapabilities.difference(
        supportedCapabilities,
      );
      if (unsupported.isNotEmpty) {
        final sorted = unsupported.toList()..sort();
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.missingRequiredCapability,
            message: 'Missing required capabilities: ${sorted.join(', ')}.',
            path: r'$.document.requiredCapabilities',
          ),
        );
      }

      return ChartArtifactSuccess(
        value: ChartArtifactDecodeResult(
          artifact: artifact,
          sourceSchemaVersion: version,
          migratedSchemaVersion: migratedSchemaVersion,
          migrationsApplied: migrationsApplied,
        ),
      );
    } on _LimitException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: error.code,
          message: error.message,
          path: error.path,
        ),
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
        ),
      );
    } on ArgumentError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message?.toString() ?? 'Invalid artifact value.',
        ),
      );
    }
  }

  static ChartArtifactError? _validateArtifactSemantics(
    ChartArtifact artifact,
    ChartArtifactValidationLimits limits,
  ) {
    final document = artifact.document;
    if (artifact.artifactId.isEmpty) {
      return const ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'artifactId must be a non-empty string.',
        path: r'$.artifactId',
      );
    }
    if (document.documentId.isEmpty) {
      return const ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'documentId must be a non-empty string.',
        path: r'$.document.documentId',
      );
    }
    if (document.revision < 0) {
      return const ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Document revision cannot be negative.',
        path: r'$.document.revision',
      );
    }
    if (document.series.length > limits.maxSeries) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
        message:
            'Document has ${document.series.length} series; maximum is '
            '${limits.maxSeries}.',
        path: r'$.document.series',
      );
    }
    if (document.pointCount > limits.maxPoints) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
        message:
            'Document has ${document.pointCount} points; maximum is '
            '${limits.maxPoints}.',
        path: r'$.document.series',
      );
    }
    final seriesIds = <String>{};
    for (var index = 0; index < document.series.length; index++) {
      final series = document.series[index];
      final id = series.id;
      if (id.isEmpty || series.type.isEmpty) {
        return ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Series id and type must be non-empty.',
          path: '\$.document.series[$index]',
        );
      }
      if (!seriesIds.add(id)) {
        return ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Duplicate series id: $id.',
          path: '\$.document.series[$index].id',
        );
      }
    }
    return null;
  }

  static void _validateRawDocumentCounts(
    Map<String, Object?> root,
    ChartArtifactValidationLimits limits,
  ) {
    final document = _requiredRawMap(root, 'document');
    var seriesCount = 0;
    var pointCount = 0;
    var dataPayloadBytes = 0;

    late void Function(List<Object?> annotations, String path) countAnnotations;

    void countSeries(List<Object?> series, String path) {
      seriesCount += series.length;
      if (seriesCount > limits.maxSeries) {
        throw _LimitException(
          'Artifact has more than ${limits.maxSeries} series.',
          path,
        );
      }
      for (var index = 0; index < series.length; index++) {
        final seriesPath = '$path[$index]';
        final seriesMap = _rawStringMap(series[index], 'series');
        final data = _requiredRawMap(seriesMap, 'data');
        final storage = data['storage'];
        if (storage == 'inlinePoints' ||
            storage == 'inlineColumns' ||
            storage == 'referenced') {
          final count = switch (storage) {
            'inlinePoints' => _requiredRawList(data, 'points').length,
            'inlineColumns' => _validateColumnarPayload(data, seriesPath),
            'referenced' => _validateReferencedPayload(
              data,
              seriesPath,
              limits,
              (byteLength) {
                dataPayloadBytes += byteLength;
                if (dataPayloadBytes > limits.maxTotalDataPayloadBytes) {
                  throw _LimitException(
                    'Referenced data declares more than '
                        '${limits.maxTotalDataPayloadBytes} total bytes.',
                    '$seriesPath.data.byteLength',
                    ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
                  );
                }
              },
            ),
            _ => throw StateError('Unreachable storage strategy.'),
          };
          pointCount += count;
          if (pointCount > limits.maxPoints) {
            throw _LimitException(
              'Artifact has more than ${limits.maxPoints} points.',
              switch (storage) {
                'inlinePoints' => '$seriesPath.data.points',
                'inlineColumns' => '$seriesPath.data.x',
                _ => '$seriesPath.data.pointCount',
              },
            );
          }
        }
        final annotations = _optionalRawList(seriesMap, 'annotations');
        if (annotations != null) {
          countAnnotations(annotations, '$seriesPath.annotations');
        }
      }
    }

    countAnnotations = (List<Object?> annotations, String path) {
      for (var index = 0; index < annotations.length; index++) {
        final annotationPath = '$path[$index]';
        final annotation = _rawStringMap(annotations[index], 'annotation');
        if (annotation['type'] == 'legend') {
          final payload = _requiredRawMap(annotation, 'payload');
          countSeries(
            _requiredRawList(payload, 'series'),
            '$annotationPath.payload.series',
          );
        }
      }
    };

    countSeries(_requiredRawList(document, 'series'), r'$.document.series');
    final annotations = _optionalRawList(document, 'annotations');
    if (annotations != null) {
      countAnnotations(annotations, r'$.document.annotations');
    }
  }

  static int _validateColumnarPayload(
    Map<String, Object?> data,
    String seriesPath,
  ) {
    final x = _requiredRawList(data, 'x');
    final y = _requiredRawList(data, 'y');
    if (y.length != x.length) {
      throw FormatException(
        '$seriesPath.data.y must match the X column length.',
      );
    }
    for (final key in const [
      'timestamps',
      'labels',
      'magnitudes',
      'colorValues',
      'opacityValues',
      'categoryValues',
      'metadata',
      'segmentStyles',
      'pointStyles',
      'pointExtensions',
    ]) {
      final value = data[key];
      if (value == null) continue;
      if (value is! List || value.length != x.length) {
        throw FormatException(
          '$seriesPath.data.$key must match the X column length.',
        );
      }
    }
    return x.length;
  }

  static int _validateReferencedPayload(
    Map<String, Object?> data,
    String seriesPath,
    ChartArtifactValidationLimits limits,
    void Function(int byteLength) addBytes,
  ) {
    final pointCount = data['pointCount'];
    final byteLength = data['byteLength'];
    if (pointCount is! int || pointCount < 0) {
      throw FormatException(
        '$seriesPath.data.pointCount must be a non-negative integer.',
      );
    }
    if (byteLength is! int || byteLength <= 0) {
      throw FormatException(
        '$seriesPath.data.byteLength must be a positive integer.',
      );
    }
    if (byteLength > limits.maxDataPayloadBytes) {
      throw _LimitException(
        'Referenced data declares $byteLength bytes; maximum is '
            '${limits.maxDataPayloadBytes}.',
        '$seriesPath.data.byteLength',
        ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
      );
    }
    addBytes(byteLength);
    return pointCount;
  }

  static void _validateStructure(
    Object? root,
    ChartArtifactValidationLimits limits,
  ) {
    var entries = 0;

    void visit(Object? value, int depth, String path) {
      if (depth > limits.maxDepth) {
        throw _LimitException(
          'Artifact nesting exceeds maximum depth ${limits.maxDepth}.',
          path,
        );
      }
      if (value is String && value.length > limits.maxStringLength) {
        throw _LimitException(
          'String length exceeds maximum ${limits.maxStringLength}.',
          path,
        );
      }
      if (value is List) {
        entries += value.length;
        if (entries > limits.maxCollectionEntries) {
          throw _LimitException(
            'Artifact collection entries exceed maximum '
            '${limits.maxCollectionEntries}.',
            path,
          );
        }
        for (var index = 0; index < value.length; index++) {
          visit(value[index], depth + 1, '$path[$index]');
        }
      } else if (value is Map) {
        entries += value.length;
        if (entries > limits.maxCollectionEntries) {
          throw _LimitException(
            'Artifact collection entries exceed maximum '
            '${limits.maxCollectionEntries}.',
            path,
          );
        }
        for (final entry in value.entries) {
          final key = entry.key;
          if (key is! String) {
            throw FormatException('Non-string object key at $path');
          }
          if (key.length > limits.maxStringLength) {
            throw _LimitException(
              'Object key length exceeds maximum ${limits.maxStringLength}.',
              path,
            );
          }
          visit(entry.value, depth + 1, '$path.$key');
        }
      }
    }

    visit(root, 0, r'$');
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Artifact root must be an object');
    }
    return {
      for (final entry in value.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  static Map<String, Object?> _requiredRawMap(
    Map<String, Object?> source,
    String key,
  ) => _rawStringMap(source[key], key);

  static List<Object?>? _optionalRawList(
    Map<String, Object?> source,
    String key,
  ) => source[key] == null ? null : _requiredRawList(source, key);

  static Map<String, Object?> _rawStringMap(Object? value, String label) {
    if (value is! Map) throw FormatException('$label must be an object');
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('$label contains a non-string key');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static List<Object?> _requiredRawList(
    Map<String, Object?> source,
    String key,
  ) {
    final value = source[key];
    if (value is! List) throw FormatException('$key must be an array');
    return List<Object?>.from(value);
  }
}

final class _LimitException implements Exception {
  const _LimitException(
    this.message,
    this.path, [
    this.code = ChartArtifactDiagnosticCodes.validationLimitExceeded,
  ]);

  final String message;
  final String path;
  final String code;
}
