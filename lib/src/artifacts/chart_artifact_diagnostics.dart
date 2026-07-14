import 'package:flutter/foundation.dart';

/// Stable machine-readable diagnostic codes for artifact operations.
abstract final class ChartArtifactDiagnosticCodes {
  static const invalidJson = 'invalid_json';
  static const invalidArtifact = 'invalid_artifact';
  static const unsupportedSchemaVersion = 'unsupported_schema_version';
  static const missingRequiredCapability = 'missing_required_capability';
  static const validationLimitExceeded = 'validation_limit_exceeded';
  static const metadataValueNotJsonSafe = 'metadata_value_not_json_safe';
  static const chartNotAttached = 'chart_not_attached';
  static const captureInProgress = 'capture_in_progress';
  static const unstableStreamRevision = 'unstable_stream_revision';
  static const previewCaptureFailed = 'preview_capture_failed';
}

@immutable
class ChartArtifactWarning {
  const ChartArtifactWarning({
    required this.code,
    required this.message,
    this.path,
  });

  final String code;
  final String message;
  final String? path;
}

@immutable
class ChartArtifactError {
  const ChartArtifactError({
    required this.code,
    required this.message,
    this.path,
  });

  final String code;
  final String message;
  final String? path;
}

sealed class ChartArtifactResult<T> {
  const ChartArtifactResult();
}

@immutable
final class ChartArtifactSuccess<T> extends ChartArtifactResult<T> {
  ChartArtifactSuccess({
    required this.value,
    Iterable<ChartArtifactWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);

  final T value;
  final List<ChartArtifactWarning> warnings;
}

@immutable
final class ChartArtifactFailure<T> extends ChartArtifactResult<T> {
  ChartArtifactFailure({
    required this.error,
    Iterable<ChartArtifactWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);

  final ChartArtifactError error;
  final List<ChartArtifactWarning> warnings;
}

/// Resource limits applied before and during artifact decoding.
@immutable
class ChartArtifactValidationLimits {
  const ChartArtifactValidationLimits({
    this.maxEncodedBytes = 16 * 1024 * 1024,
    this.maxDepth = 64,
    this.maxCollectionEntries = 2 * 1000 * 1000,
    this.maxStringLength = 1024 * 1024,
    this.maxSeries = 1000,
    this.maxPoints = 1000 * 1000,
  }) : assert(maxEncodedBytes > 0),
       assert(maxDepth > 0),
       assert(maxCollectionEntries > 0),
       assert(maxStringLength > 0),
       assert(maxSeries > 0),
       assert(maxPoints > 0);

  final int maxEncodedBytes;
  final int maxDepth;
  final int maxCollectionEntries;
  final int maxStringLength;
  final int maxSeries;
  final int maxPoints;
}

/// Pure migration step between adjacent artifact schema versions.
abstract interface class ChartArtifactMigration {
  int get sourceVersion;
  int get targetVersion;

  Map<String, Object?> migrate(Map<String, Object?> source);
}
