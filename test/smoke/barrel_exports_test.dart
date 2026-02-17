import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Smoke: barrel exports', () {
    late String barrelContent;

    setUpAll(() {
      barrelContent = File('lib/braven_charts.dart').readAsStringSync();
    });

    test('barrel file should export core widget', () {
      expect(barrelContent, contains("export 'src/braven_chart_plus.dart'"));
    });

    test('barrel file should export model classes', () {
      const expectedModels = [
        "export 'src/models/chart_series.dart'",
        "export 'src/models/chart_data_point.dart'",
        "export 'src/models/chart_theme.dart'",
        "export 'src/models/x_axis_config.dart'",
        "export 'src/models/y_axis_config.dart'",
        "export 'src/models/grid_config.dart'",
        "export 'src/models/multi_axis_config.dart'",
      ];
      for (final export in expectedModels) {
        expect(
          barrelContent,
          contains(export),
          reason: 'Missing model export: $export',
        );
      }
    });

    test('barrel file should export rendering classes', () {
      const expectedRendering = [
        "export 'src/rendering/multi_axis_painter.dart'",
        "export 'src/rendering/multi_axis_normalizer.dart'",
        "export 'src/rendering/axis_color_resolver.dart'",
      ];
      for (final export in expectedRendering) {
        expect(
          barrelContent,
          contains(export),
          reason: 'Missing rendering export: $export',
        );
      }
    });

    test('barrel file should export streaming classes', () {
      const expectedStreaming = [
        "export 'src/streaming/streaming_controller.dart'",
        "export 'src/streaming/streaming_buffer.dart'",
        "export 'src/streaming/live_stream_controller.dart'",
      ];
      for (final export in expectedStreaming) {
        expect(
          barrelContent,
          contains(export),
          reason: 'Missing streaming export: $export',
        );
      }
    });

    test('barrel file should export AI integration classes', () {
      const expectedAi = [
        "export 'src/ai/chart_agent_interface.dart'",
        "export 'src/ai/chart_config_builder.dart'",
        "export 'src/ai/chart_tool_schema.dart'",
      ];
      for (final export in expectedAi) {
        expect(
          barrelContent,
          contains(export),
          reason: 'Missing AI export: $export',
        );
      }
    });

    test('barrel file should export controller classes', () {
      const expectedControllers = [
        "export 'src/controllers/annotation_controller.dart'",
        "export 'src/controllers/chart_controller.dart'",
      ];
      for (final export in expectedControllers) {
        expect(
          barrelContent,
          contains(export),
          reason: 'Missing controller export: $export',
        );
      }
    });

    test('all exported files should exist on disk', () {
      final exportPattern = RegExp(r"export '([^']+)'");
      final matches = exportPattern.allMatches(barrelContent);
      expect(
        matches.length,
        greaterThan(0),
        reason: 'Barrel file should have exports',
      );

      for (final match in matches) {
        final exportPath = match.group(1)!;
        final filePath = 'lib/$exportPath';
        expect(
          File(filePath).existsSync(),
          isTrue,
          reason: 'Exported file does not exist: $filePath',
        );
      }
    });
  });
}
