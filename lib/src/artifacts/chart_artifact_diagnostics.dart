import 'package:flutter/foundation.dart';

/// Stable machine-readable diagnostic codes for artifact operations.
abstract final class ChartArtifactDiagnosticCodes {
  static const invalidJson = 'invalid_json';
  static const invalidArtifact = 'invalid_artifact';
  static const unsupportedSchemaVersion = 'unsupported_schema_version';
  static const invalidMigrationRegistry = 'invalid_migration_registry';
  static const artifactMigrationFailed = 'artifact_migration_failed';
  static const missingRequiredCapability = 'missing_required_capability';
  static const validationLimitExceeded = 'validation_limit_exceeded';
  static const metadataValueNotJsonSafe = 'metadata_value_not_json_safe';
  static const runtimeBindingRequired = 'runtime_binding_required';
  static const unregisteredFormatter = 'unregistered_formatter';
  static const unsupportedModelType = 'unsupported_model_type';
  static const chartNotAttached = 'chart_not_attached';
  static const captureInProgress = 'capture_in_progress';
  static const unstableStreamRevision = 'unstable_stream_revision';
  static const previewCaptureFailed = 'preview_capture_failed';
  static const previewTooLarge = 'preview_too_large';
  static const dataPayloadTooLarge = 'data_payload_too_large';
  static const dataPayloadResolutionFailed = 'data_payload_resolution_failed';
  static const dataPayloadIntegrityMismatch = 'data_payload_integrity_mismatch';
  static const unsupportedDataPayloadContentType =
      'unsupported_data_payload_content_type';
}

/// Non-fatal diagnostic attached to a successful or failed artifact operation.
///
/// Applications should log [code] and [path] while still using a successful
/// value when one is available.
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

/// Machine-readable reason an artifact operation could not produce its value.
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

/// Result type used by all fallible artifact, payload, and table operations.
///
/// A success may still contain warnings. Failures are explicit so callers do
/// not accidentally render partially decoded data.
sealed class ChartArtifactResult<T> {
  const ChartArtifactResult();
}

/// Successful artifact operation with its value and non-fatal warnings.
@immutable
final class ChartArtifactSuccess<T> extends ChartArtifactResult<T> {
  ChartArtifactSuccess({
    required this.value,
    Iterable<ChartArtifactWarning> warnings = const [],
  }) : warnings = List.unmodifiable(warnings);

  final T value;
  final List<ChartArtifactWarning> warnings;
}

/// Failed artifact operation with a stable error and collected warnings.
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
///
/// Keep the defaults for untrusted JSON. Increase a limit only for a trusted
/// transport after measuring the data size and memory budget.
@immutable
class ChartArtifactValidationLimits {
  const ChartArtifactValidationLimits({
    this.maxEncodedBytes = 16 * 1024 * 1024,
    this.maxDepth = 64,
    this.maxCollectionEntries = 2 * 1000 * 1000,
    this.maxStringLength = 1024 * 1024,
    this.maxSeries = 1000,
    this.maxPoints = 1000 * 1000,
    this.maxDataPayloadBytes = 64 * 1024 * 1024,
    this.maxTotalDataPayloadBytes = 256 * 1024 * 1024,
  }) : assert(maxEncodedBytes > 0),
       assert(maxDepth > 0),
       assert(maxCollectionEntries > 0),
       assert(maxStringLength > 0),
       assert(maxSeries > 0),
       assert(maxPoints > 0),
       assert(maxDataPayloadBytes > 0),
       assert(maxTotalDataPayloadBytes > 0);

  final int maxEncodedBytes;
  final int maxDepth;
  final int maxCollectionEntries;
  final int maxStringLength;
  final int maxSeries;
  final int maxPoints;
  final int maxDataPayloadBytes;
  final int maxTotalDataPayloadBytes;
}

/// Pure migration step between adjacent artifact schema versions.
abstract interface class ChartArtifactMigration {
  int get sourceVersion;
  int get targetVersion;

  Map<String, Object?> migrate(Map<String, Object?> source);
}
