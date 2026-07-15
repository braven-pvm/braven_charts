import 'package:flutter/foundation.dart';

import 'chart_artifact_diagnostics.dart';
import 'chart_document_extractor.dart';
import 'chart_preview.dart';

/// Controls raster preview capture for a mounted chart.
@immutable
class ChartPreviewOptions {
  const ChartPreviewOptions({
    this.pixelRatio = 1,
    this.includeTransientInteractions = false,
    this.maxPixelCount = 64 * 1024 * 1024,
    this.maxCaptureAttempts = 3,
    this.documentOptions = const ChartDocumentExtractOptions(),
  }) : assert(pixelRatio > 0),
       assert(maxPixelCount > 0),
       assert(maxCaptureAttempts > 0);

  /// Requested Flutter raster pixel ratio.
  final double pixelRatio;

  /// Keeps hover/selection visuals when true; defaults to a clean preview.
  final bool includeTransientInteractions;

  /// Hard cap on width × height before allocating the raster.
  final int maxPixelCount;

  /// Stable-revision attempts before returning an error.
  final int maxCaptureAttempts;

  /// Document projection used to bind the preview hash to the chart state.
  final ChartDocumentExtractOptions documentOptions;
}

/// Host callback that captures a preview from the currently mounted chart.
typedef ChartPreviewCaptureHandler =
    Future<ChartArtifactResult<ChartPreview>> Function(
      ChartPreviewOptions options,
    );
