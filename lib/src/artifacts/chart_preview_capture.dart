import 'package:flutter/foundation.dart';

import 'chart_artifact_diagnostics.dart';
import 'chart_document_extractor.dart';
import 'chart_preview.dart';

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

  final double pixelRatio;
  final bool includeTransientInteractions;
  final int maxPixelCount;
  final int maxCaptureAttempts;
  final ChartDocumentExtractOptions documentOptions;
}

typedef ChartPreviewCaptureHandler =
    Future<ChartArtifactResult<ChartPreview>> Function(
      ChartPreviewOptions options,
    );
