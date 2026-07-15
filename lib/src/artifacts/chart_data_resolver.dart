import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'artifact_json_readers.dart';
import 'chart_artifact.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_artifact_json_codec.dart';
import 'chart_data_payload.dart';
import 'json_value.dart';

part 'chart_data_binary_codec.dart';

/// Immutable encoded data blob ready for host-controlled persistence.
@immutable
class ChartDataBlob {
  ChartDataBlob({
    required Iterable<int> bytes,
    required this.contentType,
    required this.checksum,
    required this.pointCount,
  }) : bytes = List<int>.unmodifiable(bytes) {
    if (this.bytes.any((byte) => byte < 0 || byte > 255)) {
      throw ArgumentError.value(bytes, 'bytes', 'Values must be 0 through 255');
    }
  }

  final List<int> bytes;
  final String contentType;
  final String checksum;
  final int pointCount;

  int get byteLength => bytes.length;

  /// Creates a manifest after the host has persisted [bytes].
  ReferencedPayload reference({String? resolverKey, Uri? uri}) =>
      ReferencedPayload(
        contentType: contentType,
        byteLength: byteLength,
        checksum: checksum,
        pointCount: pointCount,
        resolverKey: resolverKey,
        uri: uri,
      );
}

/// Host boundary for authorized chart data retrieval.
///
/// The package never opens [ReferencedPayload.uri] itself. Implementations are
/// responsible for authorization, allowed schemes, storage access, and any
/// network or file policy before returning bytes.
abstract interface class ChartDataResolver {
  Future<ChartArtifactResult<List<int>>> resolve(ReferencedPayload reference);
}

/// Deterministic encoding and integrity validation for external data blobs.
abstract final class ChartDataBlobCodec {
  static const contentType = 'application/vnd.braven-charts.data+json';

  static ChartArtifactResult<ChartDataBlob> encode(
    InlineChartDataPayload payload, {
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
  }) {
    final bytes = utf8.encode(canonicalJsonEncode(payload.toJson()));
    if (bytes.length > limits.maxDataPayloadBytes) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
          message:
              'Data payload is ${bytes.length} bytes; maximum is '
              '${limits.maxDataPayloadBytes}.',
          path: r'$.data',
        ),
      );
    }
    return ChartArtifactSuccess(
      value: ChartDataBlob(
        bytes: bytes,
        contentType: contentType,
        checksum: _checksum(bytes),
        pointCount: payload.pointCount,
      ),
    );
  }

  static ChartArtifactResult<InlineChartDataPayload> decode(
    ReferencedPayload reference,
    List<int> bytes, {
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
    String path = r'$.data',
  }) {
    final manifestFailure = _validateManifest(
      reference,
      limits,
      path,
      supportedContentTypes: const {contentType},
    );
    if (manifestFailure != null) {
      return ChartArtifactFailure(error: manifestFailure);
    }
    final bytesFailure = _validateResolvedBytes(reference, bytes, path);
    if (bytesFailure != null) {
      return ChartArtifactFailure(error: bytesFailure);
    }

    try {
      final encoded = utf8.decode(bytes, allowMalformed: false);
      final decoded = jsonDecode(encoded);
      _validateStructure(decoded, limits, path);
      final payloadJson = readStringMap(decoded, 'resolved data payload');
      final rawPointCount = _readInlinePointCount(payloadJson);
      if (rawPointCount != reference.pointCount) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch,
            message:
                'Resolved payload has $rawPointCount points; manifest '
                'declares ${reference.pointCount}.',
            path: '$path.pointCount',
          ),
        );
      }
      if (rawPointCount > limits.maxPoints) {
        return ChartArtifactFailure(
          error: ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
            message:
                'Resolved payload has $rawPointCount points; maximum is '
                '${limits.maxPoints}.',
            path: '$path.pointCount',
          ),
        );
      }
      final payload = ChartDataPayload.fromJson(payloadJson);
      if (payload is! InlineChartDataPayload) {
        throw const FormatException(
          'Resolved data payload must use an inline storage strategy.',
        );
      }
      return ChartArtifactSuccess(value: payload);
    } on _ResolvedPayloadLimitException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.validationLimitExceeded,
          message: error.message,
          path: error.path,
        ),
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
          path: path,
        ),
      );
    } on ArgumentError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message?.toString() ?? 'Invalid data payload.',
          path: path,
        ),
      );
    }
  }

  static ChartArtifactError? _validateManifest(
    ReferencedPayload reference,
    ChartArtifactValidationLimits limits,
    String path, {
    required Set<String> supportedContentTypes,
  }) {
    if (!supportedContentTypes.contains(reference.contentType)) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.unsupportedDataPayloadContentType,
        message:
            'Unsupported data payload content type: '
            '${reference.contentType}.',
        path: '$path.contentType',
      );
    }
    if (reference.byteLength > limits.maxDataPayloadBytes) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.dataPayloadTooLarge,
        message:
            'Data payload declares ${reference.byteLength} bytes; maximum is '
            '${limits.maxDataPayloadBytes}.',
        path: '$path.byteLength',
      );
    }
    return null;
  }

  static ChartArtifactError? _validateResolvedBytes(
    ReferencedPayload reference,
    List<int> bytes,
    String path,
  ) {
    if (bytes.length != reference.byteLength) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch,
        message:
            'Resolved payload has ${bytes.length} bytes; manifest declares '
            '${reference.byteLength}.',
        path: '$path.byteLength',
      );
    }
    if (bytes.any((byte) => byte < 0 || byte > 255)) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.invalidArtifact,
        message: 'Resolved payload contains values outside the byte range.',
        path: path,
      );
    }
    if (_checksum(bytes) != reference.checksum) {
      return ChartArtifactError(
        code: ChartArtifactDiagnosticCodes.dataPayloadIntegrityMismatch,
        message: 'Resolved payload checksum does not match its manifest.',
        path: '$path.checksum',
      );
    }
    return null;
  }

  static String _checksum(List<int> bytes) => 'sha256:${sha256.convert(bytes)}';

  static int _readInlinePointCount(Map<String, Object?> payload) {
    final storage = payload['storage'];
    final values = switch (storage) {
      'inlinePoints' => payload['points'],
      'inlineColumns' => payload['x'],
      _ => throw const FormatException(
        'Resolved data payload must use an inline storage strategy.',
      ),
    };
    if (values is! List) {
      throw FormatException(
        storage == 'inlinePoints'
            ? 'points must be an array'
            : 'x must be an array',
      );
    }
    return values.length;
  }

  static void _validateStructure(
    Object? root,
    ChartArtifactValidationLimits limits,
    String rootPath,
  ) {
    var entries = 0;

    void visit(Object? value, int depth, String path) {
      if (depth > limits.maxDepth) {
        throw _ResolvedPayloadLimitException(
          'Resolved payload nesting exceeds ${limits.maxDepth}.',
          path,
        );
      }
      if (value is String && value.length > limits.maxStringLength) {
        throw _ResolvedPayloadLimitException(
          'Resolved payload string exceeds ${limits.maxStringLength}.',
          path,
        );
      }
      if (value is List) {
        entries += value.length;
        if (entries > limits.maxCollectionEntries) {
          throw _ResolvedPayloadLimitException(
            'Resolved payload exceeds ${limits.maxCollectionEntries} '
            'collection entries.',
            path,
          );
        }
        for (var index = 0; index < value.length; index++) {
          visit(value[index], depth + 1, '$path[$index]');
        }
      } else if (value is Map) {
        entries += value.length;
        if (entries > limits.maxCollectionEntries) {
          throw _ResolvedPayloadLimitException(
            'Resolved payload exceeds ${limits.maxCollectionEntries} '
            'collection entries.',
            path,
          );
        }
        for (final entry in value.entries) {
          if (entry.key is! String) {
            throw FormatException('Non-string key at $path.');
          }
          if ((entry.key as String).length > limits.maxStringLength) {
            throw _ResolvedPayloadLimitException(
              'Resolved payload key exceeds ${limits.maxStringLength}.',
              path,
            );
          }
          visit(entry.value, depth + 1, '$path.${entry.key}');
        }
      }
    }

    visit(root, 0, rootPath);
  }
}

/// Resolves every referenced series payload into an immutable inline payload.
abstract final class ChartDataResolution {
  static Future<ChartArtifactResult<ChartArtifact>> resolveArtifact(
    ChartArtifact artifact, {
    required ChartDataResolver resolver,
    ChartArtifactValidationLimits limits =
        const ChartArtifactValidationLimits(),
  }) async {
    final encodedResult = ChartArtifactJsonCodec.encode(
      artifact,
      limits: limits,
    );
    if (encodedResult case ChartArtifactFailure<String>()) {
      return ChartArtifactFailure(
        error: encodedResult.error,
        warnings: encodedResult.warnings,
      );
    }

    final warnings = <ChartArtifactWarning>[];
    final cache = <String, InlineChartDataPayload>{};
    try {
      final encoded = (encodedResult as ChartArtifactSuccess<String>).value;
      final root = readStringMap(jsonDecode(encoded), 'artifact');
      final document = readRequiredMap(root, 'document');
      await _resolveSeriesList(
        readRequiredList(document, 'series'),
        r'$.document.series',
        resolver,
        limits,
        cache,
        warnings,
      ).then((series) => document['series'] = series);
      final annotations = document['annotations'];
      if (annotations is List) {
        document['annotations'] = await _resolveAnnotations(
          List<Object?>.from(annotations),
          r'$.document.annotations',
          resolver,
          limits,
          cache,
          warnings,
        );
      }
      root['document'] = document;
      return ChartArtifactSuccess(
        value: ChartArtifact.fromJson(root),
        warnings: warnings,
      );
    } on _ResolutionFailure catch (failure) {
      return ChartArtifactFailure(
        error: failure.error,
        warnings: [...warnings, ...failure.warnings],
      );
    } on FormatException catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message,
        ),
        warnings: warnings,
      );
    } on ArgumentError catch (error) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: error.message?.toString() ?? 'Invalid artifact value.',
        ),
        warnings: warnings,
      );
    }
  }

  static Future<List<Object?>> _resolveSeriesList(
    List<Object?> source,
    String path,
    ChartDataResolver resolver,
    ChartArtifactValidationLimits limits,
    Map<String, InlineChartDataPayload> cache,
    List<ChartArtifactWarning> warnings,
  ) async {
    final result = <Object?>[];
    for (var index = 0; index < source.length; index++) {
      final seriesPath = '$path[$index]';
      final series = readStringMap(source[index], 'series');
      final data = readRequiredMap(series, 'data');
      if (data['storage'] == 'referenced') {
        final reference = ReferencedPayload.fromJson(data);
        final cacheKey = canonicalJsonEncode(reference.toJson());
        final payload =
            cache[cacheKey] ??
            await _resolveOne(
              reference,
              '$seriesPath.data',
              resolver,
              limits,
              warnings,
            );
        cache[cacheKey] = payload;
        series['data'] = payload.toJson();
      }
      final annotations = series['annotations'];
      if (annotations is List) {
        series['annotations'] = await _resolveAnnotations(
          List<Object?>.from(annotations),
          '$seriesPath.annotations',
          resolver,
          limits,
          cache,
          warnings,
        );
      }
      result.add(series);
    }
    return result;
  }

  static Future<List<Object?>> _resolveAnnotations(
    List<Object?> source,
    String path,
    ChartDataResolver resolver,
    ChartArtifactValidationLimits limits,
    Map<String, InlineChartDataPayload> cache,
    List<ChartArtifactWarning> warnings,
  ) async {
    final result = <Object?>[];
    for (var index = 0; index < source.length; index++) {
      final annotation = readStringMap(source[index], 'annotation');
      if (annotation['type'] == 'legend') {
        final payload = readRequiredMap(annotation, 'payload');
        payload['series'] = await _resolveSeriesList(
          readRequiredList(payload, 'series'),
          '$path[$index].payload.series',
          resolver,
          limits,
          cache,
          warnings,
        );
        annotation['payload'] = payload;
      }
      result.add(annotation);
    }
    return result;
  }

  static Future<InlineChartDataPayload> _resolveOne(
    ReferencedPayload reference,
    String path,
    ChartDataResolver resolver,
    ChartArtifactValidationLimits limits,
    List<ChartArtifactWarning> warnings,
  ) async {
    final manifestFailure = ChartDataBlobCodec._validateManifest(
      reference,
      limits,
      path,
      supportedContentTypes: const {
        ChartDataBlobCodec.contentType,
        ChartDataBinaryCodec.contentType,
      },
    );
    if (manifestFailure != null) throw _ResolutionFailure(manifestFailure);

    final ChartArtifactResult<List<int>> resolved;
    try {
      resolved = await resolver.resolve(reference);
    } catch (error) {
      throw _ResolutionFailure(
        ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.dataPayloadResolutionFailed,
          message: 'Host data resolver failed: $error',
          path: path,
        ),
      );
    }
    if (resolved case ChartArtifactFailure<List<int>>()) {
      throw _ResolutionFailure(resolved.error, resolved.warnings);
    }
    final success = resolved as ChartArtifactSuccess<List<int>>;
    warnings.addAll(success.warnings);
    final decoded = switch (reference.contentType) {
      ChartDataBlobCodec.contentType => ChartDataBlobCodec.decode(
        reference,
        success.value,
        limits: limits,
        path: path,
      ),
      ChartDataBinaryCodec.contentType => ChartDataBinaryCodec.decode(
        reference,
        success.value,
        limits: limits,
        path: path,
      ),
      _ => throw StateError('Unsupported data payload content type.'),
    };
    return switch (decoded) {
      ChartArtifactSuccess<InlineChartDataPayload>() => decoded.value,
      ChartArtifactFailure<InlineChartDataPayload>() =>
        throw _ResolutionFailure(decoded.error, decoded.warnings),
    };
  }
}

final class _ResolutionFailure implements Exception {
  _ResolutionFailure(
    this.error, [
    Iterable<ChartArtifactWarning> warnings = const [],
  ]) : warnings = List.unmodifiable(warnings);

  final ChartArtifactError error;
  final List<ChartArtifactWarning> warnings;
}

final class _ResolvedPayloadLimitException implements Exception {
  const _ResolvedPayloadLimitException(this.message, this.path);

  final String message;
  final String path;
}
