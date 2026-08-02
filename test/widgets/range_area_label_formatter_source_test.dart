// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// A LIVE Range Area band with a label formatter still produces source.
///
/// `ChartSeriesDocumentCodec` refuses a live `RangeAreaLabelConfig.formatter`
/// and the nested `labelConfig.labels.formatter`, exactly as it refuses the
/// Line/Area/Scatter data-point formatter and the Bar label formatter. Those
/// four families are stripped to a placeholder plus a capture warning by
/// `ChartSourceCaptureAdapter` before the codec ever sees them; Range Area was
/// not, so the whole extraction failed and the Source tab showed NOTHING. These
/// tests mount a real chart and go through `extractSourceDocument` — the seam
/// `BravenChartWorkbench` uses — because that is the only place the omission
/// was visible.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a live Range Area label formatter still extracts', (
    tester,
  ) async {
    final extracted = await _extract(
      tester,
      RangeAreaLabelConfig(
        value: RangeAreaLabelValue.both,
        formatter: (details) => '${details.value}',
      ),
    );

    expect(
      extracted,
      isA<ChartArtifactSuccess<ChartDocumentSnapshot>>(),
      reason:
          'a runtime-owned Range Area label formatter must be represented by a '
          'placeholder, not fail the whole extraction',
    );
  });

  testWidgets('the stripped Range Area label formatter is warned about', (
    tester,
  ) async {
    final extracted =
        await _extract(
              tester,
              RangeAreaLabelConfig(
                value: RangeAreaLabelValue.both,
                formatter: (details) => '${details.value}',
              ),
            )
            as ChartArtifactSuccess<ChartDocumentSnapshot>;

    final warning = extracted.warnings.singleWhere(
      (entry) => entry.path == r'$.series.band.labelConfig.formatter',
    );
    expect(warning.code, ChartArtifactDiagnosticCodes.runtimeBindingRequired);
    expect(warning.message, contains('runtime-owned'));
  });

  testWidgets('the NESTED Range Area data-point formatter also extracts', (
    tester,
  ) async {
    final extracted = await _extract(
      tester,
      RangeAreaLabelConfig(
        value: RangeAreaLabelValue.both,
        labels: DataPointLabelConfig(
          show: true,
          formatter: (point) => '${point.y}',
        ),
      ),
    );

    expect(extracted, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
    final warning = (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>)
        .warnings
        .singleWhere(
          (entry) =>
              entry.path == r'$.series.band.labelConfig.labels.formatter',
        );
    expect(warning.code, ChartArtifactDiagnosticCodes.runtimeBindingRequired);
  });

  // The formatter is stripped at CAPTURE, so the emitter never sees one and
  // never writes its `// formatter:` placeholder comment on this path — the
  // emitter branch stays defensive parity with the other families. What the
  // reader gets instead is the rest of the label config plus the capture
  // warning, which is the whole point: a band with a formatter used to emit
  // nothing at all.
  testWidgets('the generated config source still emits the label config', (
    tester,
  ) async {
    final snapshot =
        (await _extract(
              tester,
              RangeAreaLabelConfig(
                value: RangeAreaLabelValue.both,
                formatter: (details) => '${details.value}',
              ),
            ))
            as ChartArtifactSuccess<ChartDocumentSnapshot>;

    final generated =
        ChartDartSourceGenerator.generate(snapshot.value)
            as ChartArtifactSuccess<ChartGeneratedSource>;
    expect(
      generated.value.source,
      contains('labelConfig: RangeAreaLabelConfig('),
    );
  });

  testWidgets('a band with NO formatter extracts without a warning', (
    tester,
  ) async {
    final extracted =
        await _extract(
              tester,
              const RangeAreaLabelConfig(value: RangeAreaLabelValue.both),
            )
            as ChartArtifactSuccess<ChartDocumentSnapshot>;

    expect(
      extracted.warnings.where(
        (entry) => entry.path?.contains('labelConfig') ?? false,
      ),
      isEmpty,
    );
  });
}

Future<ChartArtifactResult<ChartDocumentSnapshot>> _extract(
  WidgetTester tester,
  RangeAreaLabelConfig labelConfig,
) async {
  final controller = BravenChartController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: BravenChartPlus(
              bravenChartController: controller,
              series: [
                RangeAreaChartSeries(
                  id: 'band',
                  name: 'Band',
                  points: [
                    RangeAreaDataPoint(x: 0, low: 1, high: 3),
                    RangeAreaDataPoint(x: 1, low: 2, high: 4),
                    RangeAreaDataPoint(x: 2, low: 1.5, high: 3.5),
                  ],
                  labelConfig: labelConfig,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return controller.extractSourceDocument(const ChartDocumentExtractOptions());
}
