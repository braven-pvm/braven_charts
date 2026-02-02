/// Renderer layer for the braven_agent package.
///
/// Provides the [ChartRenderer] class for converting [ChartConfiguration]
/// models into Flutter widgets using the braven_charts library.
///
/// Also provides [ChartSnapshotService] for capturing charts as images,
/// and re-exports [AnnotationController] for persistent annotation state.
///
/// ## Usage
///
/// ```dart
/// import 'package:braven_agent/src/renderer/renderer.dart';
///
/// // Create persistent controller for annotation state
/// final annotationController = AnnotationController();
///
/// final renderer = ChartRenderer(annotationController: annotationController);
/// final widget = renderer.render(chartConfiguration);
///
/// // Capture as image
/// final snapshotService = ChartSnapshotService();
/// final imageContent = await snapshotService.captureChart(config: config);
/// ```
library;

export 'package:braven_charts/braven_charts.dart' show AnnotationController;

export 'chart_renderer.dart';
export 'chart_snapshot_service.dart';
