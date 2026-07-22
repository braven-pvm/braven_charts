// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

/// A built-in theme survives the trip from a LIVE chart to generated source.
///
/// A chart document names its theme with a reference rather than inlining the
/// resolved values, and the source generators turn a reference the package
/// owns back into `ChartTheme.<name>`. The reference a live extraction mints
/// and the reference the generators recognise must therefore be spelled the
/// same way, or every live chart's Source tab silently drops its theme and
/// tells the reader the theme was host-owned.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/source/chart_grammar_source_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final themes = <String, ChartTheme>{
    'light': ChartTheme.light,
    'dark': ChartTheme.dark,
    'corporateBlue': ChartTheme.corporateBlue,
    'vibrant': ChartTheme.vibrant,
    'minimal': ChartTheme.minimal,
    'highContrast': ChartTheme.highContrast,
    'colorblindFriendly': ChartTheme.colorblindFriendly,
  };

  themes.forEach((name, theme) {
    testWidgets('config source emits ChartTheme.$name from a live chart', (
      tester,
    ) async {
      final snapshot = await _liveSnapshot(tester, theme);

      final result = ChartDartSourceGenerator.generate(snapshot);
      expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      final generated =
          (result as ChartArtifactSuccess<ChartGeneratedSource>).value;

      expect(
        generated.source,
        contains('theme: ChartTheme.$name'),
        reason: 'the generated config must reproduce the chart theme',
      );
      expect(
        generated.warnings.map((warning) => warning.message),
        isNot(contains(contains('host-owned'))),
      );
      expect(
        generated.warnings.map((warning) => warning.path),
        isNot(contains(r'$.theme.reference')),
      );
    });

    testWidgets('grammar source emits ChartTheme.$name from a live chart', (
      tester,
    ) async {
      final snapshot = await _liveSnapshot(tester, theme, viaGrammar: true);

      final result = ChartGrammarSourceGenerator.generate(snapshot);
      expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      final generated =
          (result as ChartArtifactSuccess<ChartGeneratedSource>).value;

      expect(generated.source, contains('.theme(ChartTheme.$name)'));
      expect(
        generated.warnings.map((warning) => warning.path),
        isNot(contains(r'$.theme.reference')),
      );
    });
  });

  testWidgets('a live extraction mints the persisted reference spelling', (
    tester,
  ) async {
    final snapshot = await _liveSnapshot(tester, ChartTheme.dark);
    // `braven.dark` is what `ChartThemeDocumentCodec` persists and what the
    // artifact fixtures on disk carry, so a live extraction must agree.
    expect(snapshot.document.theme.reference, 'braven.dark');
  });

  testWidgets('a host-owned theme is still reported as host-owned', (
    tester,
  ) async {
    final snapshot = await _liveSnapshot(
      tester,
      ChartTheme.light.copyWith(backgroundColor: const Color(0xFF102030)),
      themeReference: 'acme.midnight',
    );

    final result =
        ChartDartSourceGenerator.generate(snapshot)
            as ChartArtifactSuccess<ChartGeneratedSource>;
    expect(result.value.source, isNot(contains('theme: ChartTheme.')));
    expect(
      result.value.warnings.map((warning) => warning.message).join('\n'),
      contains('"acme.midnight" is host-owned'),
    );
  });
}

class _Row {
  const _Row(this.t, this.power);

  final double t;
  final double power;
}

const _rows = <_Row>[_Row(0, 10), _Row(1, 12), _Row(2, 11)];

double _t(_Row row) => row.t;
double _power(_Row row) => row.power;

Future<ChartDocumentSnapshot> _liveSnapshot(
  WidgetTester tester,
  ChartTheme theme, {
  String? themeReference,
  bool viaGrammar = false,
}) async {
  final controller = BravenChartController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: viaGrammar
                ? BravenChart.of(_rows)
                      .x(_t, label: 'Elapsed')
                      .y(_power, label: 'Power')
                      .theme(theme)
                      .geomLine(name: 'Signal')
                      .build(bravenChartController: controller)
                : BravenChartPlus(
                    bravenChartController: controller,
                    theme: theme,
                    series: const [
                      LineChartSeries(
                        id: 'signal',
                        name: 'Signal',
                        points: [
                          ChartDataPoint(x: 0, y: 10),
                          ChartDataPoint(x: 1, y: 12),
                          ChartDataPoint(x: 2, y: 11),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final extracted = controller.extractSourceDocument(
    ChartDocumentExtractOptions(themeReference: themeReference),
  );
  expect(extracted, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}
