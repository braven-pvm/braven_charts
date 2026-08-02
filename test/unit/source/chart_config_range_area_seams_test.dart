// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// The range-area nested-config seams, pinned as ONE body.
///
/// The grammar geom verb and the config form take the same nested literals. Two
/// renderers would drift the first time a field landed on only one of them, and
/// nothing else in the suite compares the two forms field by field — so these
/// tests assert the seam and the config path produce IDENTICAL text.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/source/chart_config_dart_emitter.dart';
import 'package:braven_charts/src/source/dart_source_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emitRangeAreaBoundaryStyle writes the argument it is given', () {
    final writer = DartSourceWriter();
    _emitter().emitRangeAreaBoundaryStyle(
      writer,
      'upperBoundaryStyle',
      const RangeAreaBoundaryStyle(strokeWidth: 2.5, glowRadius: 3),
    );

    final source = writer.toString();
    expect(source, contains('upperBoundaryStyle: RangeAreaBoundaryStyle('));
    expect(source, contains('strokeWidth: 2.5,'));
    expect(source, contains('glowRadius: 3.0,'));
  });

  test('emitRangeAreaBoundaryStyle writes NOTHING for the family default', () {
    final writer = DartSourceWriter();
    _emitter().emitRangeAreaBoundaryStyle(
      writer,
      'lowerBoundaryStyle',
      const RangeAreaBoundaryStyle(),
    );

    expect(writer.toString(), isEmpty);
  });

  test('emitRangeAreaLabelConfig writes the label body', () {
    final writer = DartSourceWriter();
    _emitter().emitRangeAreaLabelConfig(
      writer,
      const RangeAreaLabelConfig(
        value: RangeAreaLabelValue.both,
        boundaryGap: 6,
      ),
      0,
    );

    final source = writer.toString();
    expect(source, contains('labelConfig: RangeAreaLabelConfig('));
    expect(source, contains('value: RangeAreaLabelValue.both,'));
    expect(source, contains('boundaryGap: 6.0,'));
  });

  test('a live label formatter emits a placeholder AND warns', () {
    // Neither existing mechanism can catch this one. The grammar round-trip
    // compares the labelConfig instance against ITSELF (the mark carries it
    // verbatim), and the emitter drift gate never lists `formatter` because the
    // surface manifest omits it as a callback. So it is pinned here directly.
    final emitter = _emitter();
    final writer = DartSourceWriter();
    emitter.emitRangeAreaLabelConfig(
      writer,
      RangeAreaLabelConfig(
        value: RangeAreaLabelValue.both,
        formatter: (details) => '${details.value}',
      ),
      2,
    );

    expect(writer.toString(), contains('// formatter:'));
    final warning = emitter.emittedWarnings.singleWhere(
      (entry) => entry.path?.contains('labelConfig.formatter') ?? false,
    );
    expect(warning.code, ChartSourceWarningCodes.runtimeValueOmitted);
    expect(warning.path, contains(r'$.series[2]'));
  });

  test('no formatter emits no placeholder and no warning', () {
    final emitter = _emitter();
    final writer = DartSourceWriter();
    emitter.emitRangeAreaLabelConfig(
      writer,
      const RangeAreaLabelConfig(value: RangeAreaLabelValue.both),
      0,
    );

    expect(writer.toString(), isNot(contains('// formatter:')));
    expect(emitter.emittedWarnings, isEmpty);
  });
}

/// Builds a `ChartConfigDartEmitter` over a minimal snapshot, through the same
/// hydrate-then-construct path `ChartDartSourceGenerator.generate` uses. The
/// seams under test read only `options`, so the band in the snapshot is there to
/// make the document well-formed, not to be emitted.
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
                RangeAreaChartSeries(
                  id: 'band',
                  points: <RangeAreaDataPoint>[
                    RangeAreaDataPoint(x: 0, low: 1, high: 3),
                    RangeAreaDataPoint(x: 1, low: 2, high: 4),
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
      documentId: 'range-area-seams-test',
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
