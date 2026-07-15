import 'package:flutter/foundation.dart';

import 'chart_artifact.dart';
import 'chart_artifact_canonicalizer.dart';
import 'chart_artifact_diagnostics.dart';
import 'chart_document_extractor.dart';
import 'chart_preview.dart';
import 'chart_preview_capture.dart';
import 'json_value.dart';

/// Controls composition of a portable artifact from one mounted chart.
@immutable
class ChartArtifactExtractOptions {
  const ChartArtifactExtractOptions({
    this.artifactId,
    this.createdAt,
    this.includePreview = false,
    this.documentOptions = const ChartDocumentExtractOptions(),
    this.previewOptions = const ChartPreviewOptions(),
    this.renderer = const ChartRendererInfo(
      package: 'braven_charts',
      version: '0.1.0',
    ),
    this.provenance,
    this.integrity,
    this.extensions = const {},
    this.maxRevisionAttempts = 3,
  }) : assert(artifactId == null || artifactId != ''),
       assert(maxRevisionAttempts > 0);

  /// Stable host identity. A timestamped package identity is generated if null.
  final String? artifactId;

  /// Injectable UTC capture time for deterministic persistence and tests.
  final DateTime? createdAt;

  /// Whether the mounted chart should contribute a hash-matched preview.
  final bool includePreview;

  /// Defines the document used by both the artifact and preview hash.
  final ChartDocumentExtractOptions documentOptions;

  /// Defines raster capture only; its nested document options are overridden
  /// by [documentOptions] so the composed result cannot use two projections.
  final ChartPreviewOptions previewOptions;

  /// Renderer package/version metadata written into the envelope.
  final ChartRendererInfo renderer;

  /// Optional JSON-safe host provenance metadata.
  final ChartArtifactProvenance? provenance;

  /// Optional host integrity metadata.
  final ChartArtifactIntegrity? integrity;

  /// JSON-safe extension values preserved in the envelope.
  final Map<String, JsonValue> extensions;

  /// Maximum attempts to match the preview to the returned document hash.
  final int maxRevisionAttempts;
}

/// Composes document extraction and optional preview capture without storage IO.
abstract final class ChartArtifactExtractor {
  static Future<ChartArtifactResult<ChartArtifact>> extract({
    required ChartArtifactExtractOptions options,
    required ChartDocumentExtractionHandler extractDocument,
    ChartPreviewCaptureHandler? capturePreview,
  }) async {
    final validationError = _validateOptions(options);
    if (validationError != null) {
      return ChartArtifactFailure(error: validationError);
    }

    final createdAt = (options.createdAt ?? DateTime.now()).toUtc();
    final warnings = <ChartArtifactWarning>[];
    ChartDocumentSnapshot? latestSnapshot;

    for (var attempt = 0; attempt < options.maxRevisionAttempts; attempt++) {
      final documentResult = extractDocument(options.documentOptions);
      switch (documentResult) {
        case ChartArtifactFailure<ChartDocumentSnapshot>():
          return ChartArtifactFailure(
            error: documentResult.error,
            warnings: _mergeWarnings(warnings, documentResult.warnings),
          );
        case ChartArtifactSuccess<ChartDocumentSnapshot>():
          latestSnapshot = documentResult.value;
          warnings.addAll(documentResult.warnings);
      }

      if (!options.includePreview) {
        return _success(options, latestSnapshot, createdAt, null, warnings);
      }

      if (capturePreview == null) {
        warnings.add(
          const ChartArtifactWarning(
            code: ChartArtifactDiagnosticCodes.previewCaptureFailed,
            message: 'Preview capture is unavailable for this mounted chart.',
          ),
        );
        return _success(options, latestSnapshot, createdAt, null, warnings);
      }

      final previewResult = await capturePreview(
        _previewOptionsForDocument(options),
      );
      switch (previewResult) {
        case ChartArtifactFailure<ChartPreview>():
          warnings
            ..addAll(previewResult.warnings)
            ..add(
              ChartArtifactWarning(
                code: previewResult.error.code,
                message: previewResult.error.message,
                path: previewResult.error.path,
              ),
            );
          return _success(options, latestSnapshot, createdAt, null, warnings);
        case ChartArtifactSuccess<ChartPreview>():
          warnings.addAll(previewResult.warnings);
          final verifiedResult = extractDocument(options.documentOptions);
          switch (verifiedResult) {
            case ChartArtifactFailure<ChartDocumentSnapshot>():
              warnings
                ..addAll(verifiedResult.warnings)
                ..add(
                  ChartArtifactWarning(
                    code: verifiedResult.error.code,
                    message: verifiedResult.error.message,
                    path: verifiedResult.error.path,
                  ),
                );
              return _success(
                options,
                latestSnapshot,
                createdAt,
                null,
                warnings,
              );
            case ChartArtifactSuccess<ChartDocumentSnapshot>():
              latestSnapshot = verifiedResult.value;
              warnings.addAll(verifiedResult.warnings);
              final verifiedHash = ChartArtifactCanonicalizer.documentHash(
                latestSnapshot.document,
              );
              if (verifiedHash == previewResult.value.documentHash) {
                return _success(
                  options,
                  latestSnapshot,
                  createdAt,
                  previewResult.value,
                  warnings,
                );
              }
          }
      }
    }

    warnings.add(
      ChartArtifactWarning(
        code: ChartArtifactDiagnosticCodes.unstableStreamRevision,
        message:
            'The preview did not match the returned document after '
            '${options.maxRevisionAttempts} attempts; the native artifact '
            'was returned without a preview.',
      ),
    );
    return _success(options, latestSnapshot!, createdAt, null, warnings);
  }
}

ChartArtifactResult<ChartArtifact> _success(
  ChartArtifactExtractOptions options,
  ChartDocumentSnapshot snapshot,
  DateTime createdAt,
  ChartPreview? preview,
  Iterable<ChartArtifactWarning> warnings,
) => ChartArtifactSuccess(
  value: ChartArtifact(
    artifactId:
        options.artifactId ??
        'chart-artifact-${createdAt.microsecondsSinceEpoch}',
    renderer: options.renderer,
    createdAt: createdAt,
    document: snapshot.document,
    viewState: snapshot.viewState,
    preview: preview,
    provenance: options.provenance,
    integrity: options.integrity,
    extensions: options.extensions,
  ),
  warnings: _mergeWarnings(warnings),
);

ChartPreviewOptions _previewOptionsForDocument(
  ChartArtifactExtractOptions options,
) => ChartPreviewOptions(
  pixelRatio: options.previewOptions.pixelRatio,
  includeTransientInteractions:
      options.previewOptions.includeTransientInteractions,
  maxPixelCount: options.previewOptions.maxPixelCount,
  maxCaptureAttempts: options.previewOptions.maxCaptureAttempts,
  documentOptions: options.documentOptions,
);

ChartArtifactError? _validateOptions(ChartArtifactExtractOptions options) {
  if (options.artifactId case final artifactId? when artifactId.isEmpty) {
    return const ChartArtifactError(
      code: ChartArtifactDiagnosticCodes.invalidArtifact,
      message: 'artifactId must be a non-empty string.',
      path: r'$.artifactId',
    );
  }
  if (options.maxRevisionAttempts <= 0) {
    return const ChartArtifactError(
      code: ChartArtifactDiagnosticCodes.invalidArtifact,
      message: 'maxRevisionAttempts must be greater than zero.',
      path: r'$.options.maxRevisionAttempts',
    );
  }
  if (options.renderer.package.isEmpty || options.renderer.version.isEmpty) {
    return const ChartArtifactError(
      code: ChartArtifactDiagnosticCodes.invalidArtifact,
      message: 'Renderer package and version must be non-empty.',
      path: r'$.renderer',
    );
  }
  return null;
}

List<ChartArtifactWarning> _mergeWarnings(
  Iterable<ChartArtifactWarning> first, [
  Iterable<ChartArtifactWarning> second = const [],
]) {
  final seen = <(String, String, String?)>{};
  return [
    for (final warning in [...first, ...second])
      if (seen.add((warning.code, warning.message, warning.path))) warning,
  ];
}
