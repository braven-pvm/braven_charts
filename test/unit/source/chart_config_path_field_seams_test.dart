// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// The path-field seams, pinned as ONE body.
///
/// The grammar geom verbs and the config form take the same nested literals.
/// Two renderers would drift the first time a field landed on only one of them,
/// so `geomLine`/`geomArea`/`geomRangeArea` reach the config form's existing
/// private renderers through these seams instead of forking a second copy.
/// What follows pins what each seam writes on its own, including the
/// write-nothing cases the callers rely on to pass a value unconditionally.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/source/chart_config_dart_emitter.dart';
import 'package:braven_charts/src/source/dart_source_writer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emitFillGradient writes the gradient body', () {
    final writer = DartSourceWriter();
    _emitter().emitFillGradient(
      writer,
      const AreaGradient(colors: <Color>[Color(0xFF2563EB), Color(0x002563EB)]),
    );

    final source = writer.toString();
    expect(source, contains('fillGradient: AreaGradient('));
    expect(source, contains('Color(0xFF2563EB)'));
  });

  test('emitFillGradient writes NOTHING for a null gradient', () {
    final writer = DartSourceWriter();
    _emitter().emitFillGradient(writer, null);
    expect(writer.toString(), isEmpty);
  });

  test('emitPathAnimationStyle writes NOTHING for the family default', () {
    final writer = DartSourceWriter();
    _emitter().emitPathAnimationStyle(writer, const PathAnimationStyle());
    expect(writer.toString(), isEmpty);
  });

  test('emitPathAnimationStyle writes a non-default animation', () {
    final writer = DartSourceWriter();
    _emitter().emitPathAnimationStyle(
      writer,
      const PathAnimationStyle(entranceMode: PathEntranceAnimationMode.reveal),
    );

    final source = writer.toString();
    expect(source, contains('pathAnimation: PathAnimationStyle('));
    expect(source, contains('entranceMode: PathEntranceAnimationMode.reveal,'));
  });

  test('emitInlineLabel writes the inline-label body', () {
    final writer = DartSourceWriter();
    _emitter().emitInlineLabel(
      writer,
      const SeriesInlineLabelConfig(text: 'Load'),
    );

    final source = writer.toString();
    expect(source, contains('inlineLabel: SeriesInlineLabelConfig('));
    expect(source, contains("text: 'Load',"));
  });
}

/// Builds a `ChartConfigDartEmitter` over a minimal snapshot, through the same
/// hydrate-then-construct path `ChartDartSourceGenerator.generate` uses. The
/// seams under test read only `options`, so the series in the snapshot is there
/// to make the document well-formed, not to be emitted.
///
/// Copied from `chart_config_range_area_seams_test.dart` rather than reinvented
/// — one construction path for every seam test in this directory.
ChartConfigDartEmitter _emitter() {
  final snapshot = _snapshot();
  final hydrated =
      ChartDocumentHydrator.hydrateDocument(snapshot.document)
          as ChartArtifactSuccess<HydratedChartConfiguration>;
  return ChartConfigDartEmitter(
    snapshot: snapshot,
    configuration: hydrated.value,
    options: const ChartDartSourceOptions(),
  );
}

ChartDocumentSnapshot _snapshot() {
  final encodedSeries =
      (ChartSeriesDocumentCodec.encode(
                const LineChartSeries(
                  id: 'line',
                  points: <ChartDataPoint>[
                    ChartDataPoint(x: 0, y: 1),
                    ChartDataPoint(x: 1, y: 2),
                  ],
                ),
              )
              as ChartArtifactSuccess<ChartSeriesDocument>)
          .value;
  final encodedTheme = ChartThemeDocumentCodec.encode(
    ChartTheme.light,
    reference: 'braven.light',
  );
  final encodedInteraction = ChartInteractionDocumentCodec.encode(
    const InteractionConfig(),
  );
  final encodedXAxis = ChartAxisDocumentCodec.encodeXAxis(
    const XAxisConfig(label: 'Elapsed interval'),
  );
  final encodedYAxis = ChartAxisDocumentCodec.encodeYAxis(
    YAxisConfig(position: YAxisPosition.left, label: 'Value'),
  );

  return ChartDocumentSnapshot(
    document: ChartDocument(
      documentId: 'path-field-seams-test',
      revision: 1,
      series: [encodedSeries],
      annotations: const [],
      xAxis: (encodedXAxis as ChartArtifactSuccess<ChartAxisDocument>).value,
      axes: [(encodedYAxis as ChartArtifactSuccess<ChartAxisDocument>).value],
      theme: (encodedTheme as ChartArtifactSuccess<ChartThemeDocument>).value,
      interaction:
          (encodedInteraction as ChartArtifactSuccess<ChartInteractionDocument>)
              .value,
      configuration: JsonObjectValue(const {}),
      requiredCapabilities: const {},
    ),
  );
}
