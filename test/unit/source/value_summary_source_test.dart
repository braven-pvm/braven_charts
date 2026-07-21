// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// Task 13: generated Dart Source for CartesianValueSummaryConfig.
//
// The emission matrix covers: default config omitted entirely; a full
// annotation configuration with mixed inherit/none/value tri-state style
// asserted as one exact source block; overlay placement literals; builder
// content emitted as an omitted-dependency comment naming the descriptorId,
// never as rendered text.

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('value summary source generation', () {
    test('omits valueSummary entirely for a default config', () {
      final generated = _generate(const InteractionConfig());

      expect(generated.source, contains('interactionConfig: InteractionConfig('));
      expect(generated.source, isNot(contains('valueSummary')));
      expect(generated.source, isNot(contains('CartesianValueSummaryConfig')));
    });

    test(
      'emits the full annotation config with mixed tri-state style as one '
      'exact block',
      () {
        const config = CartesianValueSummaryConfig(
          enabled: true,
          presentation: CartesianValueSummaryPresentation.annotation(
            placement: ChartOverlayPlacement(
              anchor: Alignment.bottomRight,
              offset: Offset(-16, -24),
            ),
            draggable: true,
            clampToPlot: false,
          ),
          valuePolicy:
              CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
          content: CartesianValueSummaryContent.automatic(includeTrends: true),
          style: CartesianValueSummaryStyle(
            backgroundColor: ChartStyleValue.value(Color(0xEE1E2430)),
            backgroundOpacity: ChartStyleValue.value(0.85),
            borderColor: ChartStyleValue.none(),
            borderRadius: ChartStyleValue.value(
              BorderRadius.only(
                topLeft: Radius.elliptical(6, 8),
                topRight: Radius.circular(4),
              ),
            ),
            padding: ChartStyleValue.value(EdgeInsets.fromLTRB(10, 6, 10, 6)),
            textStyle: ChartStyleValue.value(
              TextStyle(color: Color(0xFFE2E8F0), fontSize: 11),
            ),
            labelStyle: ChartStyleValue.none(),
            shadow: ChartStyleValue.value(
              BoxShadow(
                color: Color(0x33000000),
                offset: Offset(0, 2),
                blurRadius: 6,
                spreadRadius: 1.5,
                blurStyle: BlurStyle.outer,
              ),
            ),
            minWidth: ChartStyleValue.value(180),
            rowGap: ChartStyleValue.none(),
            labelValueGap: ChartStyleValue.value(20),
          ),
          showSeriesAccent: false,
          announceChanges: true,
        );
        final interaction = const InteractionConfig(valueSummary: config);
        final document = _encodeInteraction(interaction);
        final generated = _generate(interaction);

        const expectedBlock =
            '    valueSummary: CartesianValueSummaryConfig(\n'
            '      enabled: true,\n'
            '      presentation: CartesianValueSummaryPresentation.annotation(\n'
            '        placement: ChartOverlayPlacement(\n'
            '          anchor: Alignment.bottomRight,\n'
            '          offset: Offset(-16.0, -24.0),\n'
            '        ),\n'
            '        draggable: true,\n'
            '        clampToPlot: false,\n'
            '      ),\n'
            '      valuePolicy: '
            'CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,\n'
            '      content: CartesianValueSummaryContent.automatic(\n'
            '        includeTrends: true,\n'
            '      ),\n'
            '      style: CartesianValueSummaryStyle(\n'
            '        backgroundColor: ChartStyleValue.value(Color(0xEE1E2430)),\n'
            '        backgroundOpacity: ChartStyleValue.value(0.85),\n'
            '        borderColor: ChartStyleValue<Color>.none(),\n'
            '        borderRadius: ChartStyleValue.value(BorderRadius.only('
            'topLeft: Radius.elliptical(6.0, 8.0), '
            'topRight: Radius.circular(4.0), '
            'bottomLeft: Radius.circular(0.0), '
            'bottomRight: Radius.circular(0.0))),\n'
            '        padding: ChartStyleValue.value('
            'EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 6.0)),\n'
            '        textStyle: ChartStyleValue.value(\n'
            '          TextStyle(\n'
            '            color: Color(0xFFE2E8F0),\n'
            '            fontSize: 11.0,\n'
            '          ),\n'
            '        ),\n'
            '        labelStyle: ChartStyleValue<TextStyle>.none(),\n'
            '        shadow: ChartStyleValue.value(BoxShadow('
            'color: Color(0x33000000), offset: Offset(0.0, 2.0), '
            'blurRadius: 6.0, spreadRadius: 1.5, '
            'blurStyle: BlurStyle.outer)),\n'
            '        minWidth: ChartStyleValue.value(180.0),\n'
            '        rowGap: ChartStyleValue<double>.none(),\n'
            '        labelValueGap: ChartStyleValue.value(20.0),\n'
            '      ),\n'
            '      showSeriesAccent: false,\n'
            '      announceChanges: true,\n'
            '    ),\n';
        expect(generated.source, contains(expectedBlock));
        expect(generated.warnings, isEmpty);

        // Deterministic output.
        expect(_generate(interaction).source, generated.source);

        // The document the generator consumed reconstructs a value-equal
        // config, including every explicit .none() field.
        final decoded = ChartInteractionDocumentCodec.decode(document);
        expect(decoded, isA<ChartArtifactSuccess<InteractionConfig>>());
        final roundTripped =
            (decoded as ChartArtifactSuccess<InteractionConfig>)
                .value
                .valueSummary;
        expect(roundTripped, config);
        expect(roundTripped.style.borderColor.isNone, isTrue);
        expect(roundTripped.style.labelStyle.isNone, isTrue);
        expect(roundTripped.style.rowGap.isNone, isTrue);
        expect(
          roundTripped.style.labelValueGap,
          const ChartStyleValue<double>.value(20.0),
        );
      },
    );

    test('emits a cleared labelValueGap as a typed none', () {
      final generated = _generate(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            style: CartesianValueSummaryStyle(
              labelValueGap: ChartStyleValue.none(),
            ),
          ),
        ),
      );

      expect(
        generated.source,
        contains('labelValueGap: ChartStyleValue<double>.none(),'),
      );
      expect(generated.source, isNot(contains('labelValueGap: ChartStyleValue.value')));
    });

    test('emits non-default overlay placement and omits default arguments', () {
      final generated = _generate(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            presentation: CartesianValueSummaryPresentation.overlay(
              placement: ChartOverlayPlacement(
                anchor: Alignment.topRight,
                offset: Offset(-12, 12),
              ),
            ),
          ),
        ),
      );

      const expectedBlock =
          '    valueSummary: CartesianValueSummaryConfig(\n'
          '      enabled: true,\n'
          '      presentation: CartesianValueSummaryPresentation.overlay(\n'
          '        placement: ChartOverlayPlacement(\n'
          '          anchor: Alignment.topRight,\n'
          '          offset: Offset(-12.0, 12.0),\n'
          '        ),\n'
          '      ),\n'
          '    ),\n';
      expect(generated.source, contains(expectedBlock));
    });

    test('omits the default overlay presentation and default sub-configs', () {
      final generated = _generate(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(enabled: true),
        ),
      );

      const expectedBlock =
          '    valueSummary: CartesianValueSummaryConfig(\n'
          '      enabled: true,\n'
          '    ),\n';
      expect(generated.source, contains(expectedBlock));
      expect(generated.source, isNot(contains('presentation:')));
      expect(generated.source, isNot(contains('valuePolicy:')));
      expect(generated.source, isNot(contains('content:')));
      expect(generated.source, isNot(contains('CartesianValueSummaryStyle')));
    });

    test('emits a non-placement Alignment as a coordinate literal', () {
      final generated = _generate(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            presentation: CartesianValueSummaryPresentation.overlay(
              placement: ChartOverlayPlacement(
                anchor: Alignment(0.5, -1),
                offset: Offset(4, 18),
              ),
            ),
          ),
        ),
      );

      expect(generated.source, contains('anchor: Alignment(0.5, -1.0),'));
      expect(generated.source, contains('offset: Offset(4.0, 18.0),'));
    });

    test(
      'emits builder content as an omitted-dependency comment naming the '
      'descriptorId, never the rendered text',
      () {
        final interaction = InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            content: CartesianValueSummaryContent.builder(
              (snapshot) => const CartesianValueSummaryContentModel(
                title: 'RUNTIME ONLY TITLE',
                rows: [
                  CartesianValueSummaryRow(
                    label: 'RUNTIME ONLY LABEL',
                    value: 'RUNTIME ONLY VALUE',
                  ),
                ],
              ),
              descriptorId: 'showcase.summaryRows',
            ),
          ),
        );
        final result = ChartDartSourceGenerator.generate(
          _snapshot(interaction),
        );
        expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
        final success = result as ChartArtifactSuccess<ChartGeneratedSource>;
        final generated = success.value;

        expect(
          generated.source,
          contains('valueSummary: CartesianValueSummaryConfig('),
        );
        expect(generated.source, contains('enabled: true,'));
        expect(
          generated.source,
          contains(
            '// content: CartesianValueSummaryContent.builder(...), '
            '// Supply the runtime builder registered as '
            '"showcase.summaryRows".',
          ),
        );
        // Never serialize what the runtime builder happened to render.
        expect(generated.source, isNot(contains('RUNTIME ONLY')));
        expect(
          generated.source,
          isNot(contains('content: CartesianValueSummaryContent.builder(\n')),
        );

        // The omission is a structured source warning and appears once in the
        // header alongside the runtime binding list.
        expect(
          generated.warnings,
          contains(
            isA<ChartSourceWarning>()
                .having(
                  (warning) => warning.code,
                  'code',
                  ChartSourceWarningCodes.runtimeValueOmitted,
                )
                .having(
                  (warning) => warning.path,
                  'path',
                  r'$.interaction.configuration.valueSummary.content',
                ),
          ),
        );
        expect(
          generated.source,
          contains('Runtime interaction bindings omitted: showcase.summaryRows'),
        );
        // The hydration-side binding warning is not duplicated at the
        // artifact level; source generation reports the omission itself.
        expect(
          success.warnings.where(
            (warning) =>
                warning.code ==
                ChartArtifactDiagnosticCodes.runtimeBindingRequired,
          ),
          isEmpty,
        );
      },
    );

    test('reports onPlacementChanged once as a runtime binding omission', () {
      final interaction = InteractionConfig(
        valueSummary: CartesianValueSummaryConfig(
          enabled: true,
          onPlacementChanged: (placement) {},
        ),
      );
      final result = ChartDartSourceGenerator.generate(
        _snapshot(
          interaction,
          interactionBindingDescriptors: {
            ChartInteractionDocumentCodec.valueSummaryPlacementChangedBinding:
                JsonObjectValue(const {
                  'id': JsonStringValue('showcase.placementChanged'),
                }),
          },
        ),
      );
      expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
      final success = result as ChartArtifactSuccess<ChartGeneratedSource>;

      expect(
        success.value.source,
        contains(
          'Runtime interaction bindings omitted: showcase.placementChanged',
        ),
      );
      expect(success.value.source, isNot(contains('onPlacementChanged:')));
      expect(
        success.warnings.where(
          (warning) =>
              warning.code ==
              ChartArtifactDiagnosticCodes.runtimeBindingRequired,
        ),
        isEmpty,
      );
    });
  });
}

ChartGeneratedSource _generate(InteractionConfig interaction) {
  final result = ChartDartSourceGenerator.generate(_snapshot(interaction));
  expect(result, isA<ChartArtifactSuccess<ChartGeneratedSource>>());
  return (result as ChartArtifactSuccess<ChartGeneratedSource>).value;
}

ChartInteractionDocument _encodeInteraction(
  InteractionConfig interaction, {
  Map<String, JsonObjectValue> interactionBindingDescriptors = const {},
}) {
  final encoded = ChartInteractionDocumentCodec.encode(
    interaction,
    runtimeBindingDescriptors: interactionBindingDescriptors,
  );
  expect(encoded, isA<ChartArtifactSuccess<ChartInteractionDocument>>());
  return (encoded as ChartArtifactSuccess<ChartInteractionDocument>).value;
}

ChartDocumentSnapshot _snapshot(
  InteractionConfig interaction, {
  Map<String, JsonObjectValue> interactionBindingDescriptors = const {},
}) {
  final encodedSeries =
      ChartSeriesDocumentCodec.encode(
            const LineChartSeries(
              id: 'signal',
              name: 'Signal',
              points: [ChartDataPoint(x: 0, y: 10), ChartDataPoint(x: 1, y: 12)],
            ),
          )
          as ChartArtifactSuccess<ChartSeriesDocument>;
  final encodedTheme =
      ChartThemeDocumentCodec.encode(ChartTheme.light, reference: 'braven.light')
          as ChartArtifactSuccess<ChartThemeDocument>;
  final encodedXAxis =
      ChartAxisDocumentCodec.encodeXAxis(const XAxisConfig(label: 'Elapsed'))
          as ChartArtifactSuccess<ChartAxisDocument>;
  final encodedYAxis =
      ChartAxisDocumentCodec.encodeYAxis(
            YAxisConfig(position: YAxisPosition.left, label: 'Value'),
          )
          as ChartArtifactSuccess<ChartAxisDocument>;

  return ChartDocumentSnapshot(
    document: ChartDocument(
      documentId: 'value-summary-source-test',
      revision: 1,
      series: [encodedSeries.value],
      xAxis: encodedXAxis.value,
      axes: [encodedYAxis.value],
      theme: encodedTheme.value,
      interaction: _encodeInteraction(
        interaction,
        interactionBindingDescriptors: interactionBindingDescriptors,
      ),
      requiredCapabilities: {
        if (interaction.valueSummary != const CartesianValueSummaryConfig())
          'chart.cartesian.value-summary.v1',
      },
    ),
  );
}
