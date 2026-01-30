/// Renderer layer for the braven_agent package.
///
/// Provides the [ChartRenderer] class for converting [ChartConfiguration]
/// models into Flutter widgets using the braven_charts library.
///
/// Also provides [ChartSnapshotService] for capturing charts as images.
///
/// ## Usage
///
/// ```dart
/// import 'package:braven_agent/src/renderer/renderer.dart';
///
/// final renderer = const ChartRenderer();
/// final widget = renderer.render(chartConfiguration);
///
/// // Capture as image
/// final snapshotService = ChartSnapshotService();
/// final imageContent = await snapshotService.captureChart(config: config);
/// ```
library;

export 'chart_renderer.dart';
export 'chart_snapshot_service.dart';
