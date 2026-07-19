import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'representative generated Dart formats and analyzes',
    () async {
      final series = const LineChartSeries(
        id: 'power',
        name: 'Power',
        points: [ChartDataPoint(x: 0, y: 148), ChartDataPoint(x: 1, y: 162)],
      );
      final scatter = const ScatterChartSeries(
        id: 'risk',
        name: 'Assets',
        points: [ChartDataPoint(x: 1, y: 2, colorValue: 80, opacityValue: 92)],
        colorEncoding: ScatterColorEncoding(
          colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
          scaleType: ScatterColorScaleType.piecewise,
          thresholds: [60],
          bandLabels: ['Normal', 'Critical'],
        ),
        opacityEncoding: ScatterOpacityEncoding(
          minimumOpacity: 0.15,
          maximumOpacity: 0.95,
          label: 'Confidence',
          unit: '%',
        ),
      );
      final snapshot = ChartDocumentSnapshot(
        document: ChartDocument(
          documentId: 'generated-source-compile',
          revision: 4,
          series: [
            _success(ChartSeriesDocumentCodec.encode(series)).value,
            _success(ChartSeriesDocumentCodec.encode(scatter)).value,
          ],
          annotations: [
            _success(
              ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(
                  id: 'legend',
                  series: [series],
                  legendStyle: const LegendStyle(
                    position: LegendPosition.bottomLeft,
                  ),
                ),
              ),
            ).value,
            _success(
              ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(
                  id: 'confidence-key',
                  opacityScale: const LegendOpacityScale(
                    label: 'Confidence',
                    color: Color(0xFF2563EB),
                    minimumOpacity: 0.15,
                    maximumOpacity: 0.95,
                    minimumLabel: '40 %',
                    midpointLabel: '70 %',
                    maximumLabel: '100 %',
                  ),
                ),
              ),
            ).value,
            _success(
              ChartAnnotationDocumentCodec.encode(
                LegendAnnotation(
                  id: 'risk-key',
                  colorScale: const LegendColorScale(
                    label: 'Risk score',
                    colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
                    minimumLabel: '0',
                    maximumLabel: '100',
                    type: LegendColorScaleType.piecewise,
                    segmentLabels: ['Normal', 'Critical'],
                  ),
                ),
              ),
            ).value,
          ],
          xAxis: _success(
            ChartAxisDocumentCodec.encodeXAxis(
              const XAxisConfig(label: 'Elapsed interval'),
            ),
          ).value,
          axes: [
            _success(
              ChartAxisDocumentCodec.encodeYAxis(
                YAxisConfig(position: YAxisPosition.left, label: 'Power'),
              ),
            ).value,
          ],
          theme: _success(
            ChartThemeDocumentCodec.encode(
              ChartTheme.dark.copyWith(
                backgroundColor: const Color(0xFF08111F),
                pieChartTheme: const PieChartTheme(
                  cornerRadius: 5,
                  gradient: PieGradientStyle(type: PieGradientType.radial),
                ),
              ),
            ),
          ).value,
          interaction: _success(
            ChartInteractionDocumentCodec.encode(const InteractionConfig()),
          ).value,
        ),
        viewState: ChartViewState(
          visibleBounds: const ChartBoundsDocument(
            xMin: 0,
            xMax: 1,
            yMin: 140,
            yMax: 170,
          ),
          selectedSeriesId: 'power',
          selectedPointRefs: const [
            ChartPointRef(seriesId: 'power', pointIndex: 1),
          ],
        ),
      );
      final generated = _success(
        ChartDartSourceGenerator.generate(
          snapshot,
          options: const ChartDartSourceOptions(includeViewState: true),
        ),
      ).value;

      final fixture = File(
        '${Directory.current.path}${Platform.pathSeparator}.dart_tool'
        '${Platform.pathSeparator}chart_generated_source_compile_test.dart',
      );
      await fixture.writeAsString(
        '// ignore_for_file: prefer_const_constructors\n${generated.source}',
      );
      try {
        final format = await Process.run(
          'dart',
          ['format', '--output=none', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          format.exitCode,
          0,
          reason: '${format.stdout}\n${format.stderr}',
        );

        final analyze = await Process.run(
          'dart',
          ['analyze', '--no-fatal-warnings', fixture.path],
          workingDirectory: Directory.current.path,
          runInShell: Platform.isWindows,
        );
        expect(
          analyze.exitCode,
          0,
          reason: '${analyze.stdout}\n${analyze.stderr}',
        );
      } finally {
        if (await fixture.exists()) await fixture.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

ChartArtifactSuccess<T> _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return result as ChartArtifactSuccess<T>;
}
