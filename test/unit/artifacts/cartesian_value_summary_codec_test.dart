import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/artifacts/chart_document_extractor.dart';
import 'package:flutter/material.dart' hide TooltipTriggerMode;
import 'package:flutter_test/flutter_test.dart';

const _capability = 'chart.cartesian.value-summary.v1';
const _builderBindingId = 'app.summary.rows.v1';
const _placementBindingId = 'app.summary.placement.v1';

CartesianValueSummaryContentModel _customRows(
  CartesianTrackingSnapshot snapshot,
) => const CartesianValueSummaryContentModel(title: 'Custom');

const _fullStyle = CartesianValueSummaryStyle(
  backgroundColor: ChartStyleValue.value(Color(0xEE1E2430)),
  backgroundOpacity: ChartStyleValue.value(0.85),
  borderColor: ChartStyleValue<Color>.none(),
  borderWidth: ChartStyleValue.value(1.5),
  borderRadius: ChartStyleValue.value(
    BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.elliptical(6, 4),
      bottomRight: Radius.circular(2),
    ),
  ),
  padding: ChartStyleValue.value(EdgeInsets.fromLTRB(10, 6, 10, 8)),
  textStyle: ChartStyleValue.value(
    TextStyle(
      color: Color(0xFFE8ECF4),
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.25,
    ),
  ),
  labelStyle: ChartStyleValue<TextStyle>.none(),
  accentColor: ChartStyleValue.value(Color(0xFF38BDF8)),
  shadow: ChartStyleValue.value(
    BoxShadow(
      color: Color(0x59000000),
      offset: Offset(0, 3),
      blurRadius: 9,
      spreadRadius: 1.25,
      blurStyle: BlurStyle.outer,
    ),
  ),
  minWidth: ChartStyleValue.value(168),
  maxWidth: ChartStyleValue<double>.none(),
  rowGap: ChartStyleValue.value(4),
  labelValueGap: ChartStyleValue.value(18),
);

const _fullConfig = CartesianValueSummaryConfig(
  enabled: true,
  valuePolicy: CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest,
  valueMode: CartesianValueSummaryValueMode.dataPoints,
  presentation: CartesianValueSummaryPresentation.annotation(
    placement: ChartOverlayPlacement(
      anchor: Alignment(0.25, -1),
      offset: Offset(-18, 14),
    ),
    draggable: true,
    clampToPlot: false,
  ),
  content: CartesianValueSummaryContent.automatic(
    includeTrends: true,
    includeHiddenSeries: true,
  ),
  style: _fullStyle,
  showSeriesAccent: false,
  announceChanges: true,
);

void main() {
  group('CartesianValueSummaryConfig artifact codec', () {
    test('omits the default config and decodes an absent field to disabled',
        () {
      final document = _encode(const InteractionConfig());
      final json = _configurationJson(document);
      expect(json.containsKey('valueSummary'), isFalse);

      final decoded = _decode(document);
      expect(decoded.valueSummary, const CartesianValueSummaryConfig());
      expect(decoded.valueSummary.enabled, isFalse);
    });

    test('runtime-only controller keeps the sub-config omitted', () {
      final controller = DefaultCartesianValueSummaryController();
      addTearDown(controller.dispose);
      final document = _encode(
        InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(controller: controller),
        ),
      );
      expect(_configurationJson(document).containsKey('valueSummary'), isFalse);
    });

    test('round-trips a fully explicit config value-equal', () {
      const source = InteractionConfig(valueSummary: _fullConfig);
      final document = _encode(source);
      final json = _valueSummaryJson(document);

      expect(json['enabled'], isTrue);
      expect(json['valuePolicy'], 'pinnedThenTrackingThenLatest');
      expect(json['valueMode'], 'dataPoints');
      final presentation = Map<String, Object?>.from(
        json['presentation']! as Map,
      );
      expect(presentation['kind'], 'annotation');
      expect(presentation['draggable'], isTrue);
      expect(presentation['clampToPlot'], isFalse);
      final placement = Map<String, Object?>.from(
        presentation['placement']! as Map,
      );
      expect(placement['anchor'], {'x': 0.25, 'y': -1.0});
      expect(placement['offset'], {'dx': -18.0, 'dy': 14.0});

      final decoded = _decode(
        ChartInteractionDocument.fromJson(document.toJson()),
      );
      expect(decoded, source);
      expect(decoded.valueSummary, _fullConfig);
      expect(decoded.valueSummary.style, _fullStyle);
    });

    test('tri-state style fields keep inherit, explicit, and none distinct',
        () {
      const source = InteractionConfig(
        valueSummary: CartesianValueSummaryConfig(
          enabled: true,
          style: CartesianValueSummaryStyle(
            borderColor: ChartStyleValue<Color>.none(),
            accentColor: ChartStyleValue.value(Color(0xFF2563EB)),
          ),
        ),
      );
      final document = _encode(source);
      final style = Map<String, Object?>.from(
        _valueSummaryJson(document)['style']! as Map,
      );
      expect(style.containsKey('backgroundColor'), isFalse);
      expect(style['borderColor'], 'none');
      expect(style['accentColor'], 0xFF2563EB);

      final decodedStyle = _decode(document).valueSummary.style;
      expect(decodedStyle.backgroundColor.isInherit, isTrue);
      expect(decodedStyle.borderColor.isNone, isTrue);
      expect(decodedStyle.borderColor, const ChartStyleValue<Color>.none());
      expect(
        decodedStyle.borderColor,
        isNot(const ChartStyleValue<Color>.inherit()),
      );
      expect(
        decodedStyle.accentColor,
        const ChartStyleValue.value(Color(0xFF2563EB)),
      );
      expect(decodedStyle, source.valueSummary.style);
    });

    test('labelValueGap round-trips inherit, none, and value forms', () {
      Map<String, Object?> styleJson(CartesianValueSummaryStyle style) {
        final document = _encode(
          InteractionConfig(
            valueSummary: CartesianValueSummaryConfig(
              enabled: true,
              style: style,
            ),
          ),
        );
        return Map<String, Object?>.from(
          _valueSummaryJson(document)['style']! as Map,
        );
      }

      CartesianValueSummaryStyle roundTrip(CartesianValueSummaryStyle style) {
        final document = _encode(
          InteractionConfig(
            valueSummary: CartesianValueSummaryConfig(
              enabled: true,
              style: style,
            ),
          ),
        );
        return _decode(
          ChartInteractionDocument.fromJson(document.toJson()),
        ).valueSummary.style;
      }

      // Inherit stays an absent key.
      const inherit = CartesianValueSummaryStyle(
        rowGap: ChartStyleValue.value(6),
      );
      expect(styleJson(inherit).containsKey('labelValueGap'), isFalse);
      expect(roundTrip(inherit).labelValueGap.isInherit, isTrue);

      // An explicit clear is the "none" token, decoded back to .none().
      const cleared = CartesianValueSummaryStyle(
        labelValueGap: ChartStyleValue<double>.none(),
      );
      expect(styleJson(cleared)['labelValueGap'], 'none');
      expect(
        roundTrip(cleared).labelValueGap,
        const ChartStyleValue<double>.none(),
      );

      // An explicit value carries the double payload.
      const packed = CartesianValueSummaryStyle(
        labelValueGap: ChartStyleValue.value(22.5),
      );
      expect(
        roundTrip(packed).labelValueGap,
        const ChartStyleValue<double>.value(22.5),
      );
    });

    test('omits the default value mode and decodes an absent key to '
        'interpolated', () {
      final document = _encode(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(enabled: true),
        ),
      );
      final json = _valueSummaryJson(document);
      expect(json.containsKey('valueMode'), isFalse);

      final decoded = _decode(
        ChartInteractionDocument.fromJson(document.toJson()),
      );
      expect(
        decoded.valueSummary.valueMode,
        CartesianValueSummaryValueMode.interpolated,
      );
    });

    test('rejects an unknown value mode with a structured diagnostic', () {
      final result = ChartInteractionDocumentCodec.decode(
        _mutateValueSummary(
          _encode(const InteractionConfig(valueSummary: _fullConfig)),
          (summary) => summary..['valueMode'] = 'quantumMode',
        ),
      );

      expect(result, isA<ChartArtifactFailure<InteractionConfig>>());
      final failure = result as ChartArtifactFailure<InteractionConfig>;
      expect(failure.error.code, ChartArtifactDiagnosticCodes.invalidArtifact);
      expect(failure.error.message, contains('valueMode'));
      expect(failure.error.message, contains('quantumMode'));
    });

    test('rejects an unknown value policy with a structured diagnostic', () {
      final result = ChartInteractionDocumentCodec.decode(
        _mutateValueSummary(
          _encode(const InteractionConfig(valueSummary: _fullConfig)),
          (summary) => summary..['valuePolicy'] = 'quantumPolicy',
        ),
      );

      expect(result, isA<ChartArtifactFailure<InteractionConfig>>());
      final failure = result as ChartArtifactFailure<InteractionConfig>;
      expect(failure.error.code, ChartArtifactDiagnosticCodes.invalidArtifact);
      expect(failure.error.message, contains('valuePolicy'));
    });

    test('rejects an unknown presentation kind with a structured diagnostic',
        () {
      final result = ChartInteractionDocumentCodec.decode(
        _mutateValueSummary(
          _encode(const InteractionConfig(valueSummary: _fullConfig)),
          (summary) => summary
            ..['presentation'] = {
              'kind': 'holographic',
              'placement': {
                'anchor': {'x': 0.0, 'y': 0.0},
                'offset': {'dx': 0.0, 'dy': 0.0},
              },
            },
        ),
      );

      expect(result, isA<ChartArtifactFailure<InteractionConfig>>());
      final failure = result as ChartArtifactFailure<InteractionConfig>;
      expect(failure.error.code, ChartArtifactDiagnosticCodes.invalidArtifact);
      expect(failure.error.message, contains('holographic'));
    });
  });

  group('CartesianValueSummary builder content', () {
    test('round-trips a registered builder descriptor', () {
      const content = CartesianValueSummaryContent.builder(
        _customRows,
        descriptorId: _builderBindingId,
      );
      const source = InteractionConfig(
        valueSummary: CartesianValueSummaryConfig(
          enabled: true,
          content: content,
        ),
      );

      final document = _encode(source);
      expect(document.requiredBindings, contains(_builderBindingId));
      final contentJson = Map<String, Object?>.from(
        _valueSummaryJson(document)['content']! as Map,
      );
      expect(contentJson, {
        'kind': 'builder',
        'descriptorId': _builderBindingId,
      });

      final result = ChartInteractionDocumentCodec.decode(
        ChartInteractionDocument.fromJson(document.toJson()),
        bindings: const ChartRuntimeBindings(
          callbacks: ChartCallbackRegistry(
            callbacks: {_builderBindingId: _customRows},
          ),
        ),
      );
      final success = result as ChartArtifactSuccess<InteractionConfig>;
      expect(success.warnings, isEmpty);
      expect(success.value.valueSummary.content, content);
    });

    test('falls back to automatic content with a diagnostic when unbound', () {
      final document = _encode(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            content: CartesianValueSummaryContent.builder(
              _customRows,
              descriptorId: _builderBindingId,
            ),
          ),
        ),
      );

      final result = ChartInteractionDocumentCodec.decode(document);
      final success = result as ChartArtifactSuccess<InteractionConfig>;
      expect(
        success.value.valueSummary.content,
        const CartesianValueSummaryContent.automatic(),
      );
      final warning = success.warnings.singleWhere(
        (warning) => warning.path!.contains('valueSummary'),
      );
      expect(
        warning.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(warning.message, contains(_builderBindingId));
    });

    test('encodes an unregistered builder as an omitted dependency', () {
      final result = ChartInteractionDocumentCodec.encode(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            content: CartesianValueSummaryContent.builder(_customRows),
          ),
        ),
      );

      final success = result as ChartArtifactSuccess<ChartInteractionDocument>;
      expect(
        success.warnings.single.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(success.warnings.single.path, contains('valueSummary.content'));
      final contentJson = Map<String, Object?>.from(
        _valueSummaryJson(success.value)['content']! as Map,
      );
      expect(contentJson['kind'], 'automatic');
      expect(success.value.requiredBindings, isEmpty);

      final decoded = _decode(success.value);
      expect(
        decoded.valueSummary.content,
        const CartesianValueSummaryContent.automatic(),
      );
    });

    test('requires the descriptor id to be declared in requiredBindings', () {
      final document = _encode(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            content: CartesianValueSummaryContent.builder(
              _customRows,
              descriptorId: _builderBindingId,
            ),
          ),
        ),
      );
      final json = document.toJson()..remove('requiredBindings');

      final result = ChartInteractionDocumentCodec.decode(
        ChartInteractionDocument.fromJson(json),
      );
      expect(result, isA<ChartArtifactFailure<InteractionConfig>>());
      expect(
        (result as ChartArtifactFailure<InteractionConfig>).error.code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
    });
  });

  group('CartesianValueSummary onPlacementChanged binding', () {
    test('requires a runtime descriptor when the callback is present', () {
      final result = ChartInteractionDocumentCodec.encode(
        InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            onPlacementChanged: (placement) {},
          ),
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartInteractionDocument>>());
      final failure = result as ChartArtifactFailure<ChartInteractionDocument>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
      expect(failure.error.path, contains('valueSummary.onPlacementChanged'));
    });

    test('rebinds the callback through the registry on decode', () {
      final descriptor =
          JsonValue.fromJson({'id': _placementBindingId}) as JsonObjectValue;
      final document = _encode(
        InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            onPlacementChanged: (placement) {},
          ),
        ),
        descriptors: {
          ChartInteractionDocumentCodec.valueSummaryPlacementChangedBinding:
              descriptor,
        },
      );
      // The config is value-equal to the default, so the sub-config stays
      // omitted while the callback descriptor is still captured.
      expect(_configurationJson(document).containsKey('valueSummary'), isFalse);
      expect(document.requiredBindings, {_placementBindingId});

      ChartOverlayPlacement? committed;
      void onPlacementChanged(ChartOverlayPlacement placement) =>
          committed = placement;
      final rebound = _decode(
        document,
        bindings: ChartRuntimeBindings(
          callbacks: ChartCallbackRegistry(
            callbacks: {_placementBindingId: onPlacementChanged},
          ),
        ),
      );
      expect(rebound.valueSummary.onPlacementChanged, isNotNull);
      rebound.valueSummary.onPlacementChanged!(ChartOverlayPlacement.topLeft);
      expect(committed, ChartOverlayPlacement.topLeft);

      final degraded = ChartInteractionDocumentCodec.decode(document)
          as ChartArtifactSuccess<InteractionConfig>;
      expect(degraded.value.valueSummary.onPlacementChanged, isNull);
      expect(
        degraded.warnings.single.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
    });
  });

  group('CartesianValueSummary capability and hydration', () {
    test('declares the capability only for non-default configs', () {
      final enabled = _extract(
        const InteractionConfig(valueSummary: _fullConfig),
      );
      expect(enabled.document.requiredCapabilities, contains(_capability));

      final disabled = _extract(const InteractionConfig());
      expect(
        disabled.document.requiredCapabilities,
        isNot(contains(_capability)),
      );
    });

    test('hydrates a non-default config end-to-end', () {
      final snapshot = _extract(
        const InteractionConfig(valueSummary: _fullConfig),
      );
      final hydrated = _hydrate(snapshot.document);
      expect(hydrated.interaction.valueSummary, _fullConfig);
    });

    test('an artifact without the field hydrates with a disabled summary', () {
      final snapshot = _extract(const InteractionConfig());
      expect(
        snapshot.document.requiredCapabilities,
        isNot(contains(_capability)),
      );
      final hydrated = _hydrate(snapshot.document);
      expect(hydrated.interaction.valueSummary.enabled, isFalse);
      expect(
        hydrated.interaction.valueSummary,
        const CartesianValueSummaryConfig(),
      );
    });

    test('hydration falls back to automatic content for a missing builder',
        () {
      final snapshot = _extract(
        const InteractionConfig(
          valueSummary: CartesianValueSummaryConfig(
            enabled: true,
            content: CartesianValueSummaryContent.builder(
              _customRows,
              descriptorId: _builderBindingId,
            ),
          ),
        ),
      );

      final result = ChartDocumentHydrator.hydrateDocument(snapshot.document);
      final success =
          result as ChartArtifactSuccess<HydratedChartConfiguration>;
      expect(
        success.value.interaction.valueSummary.content,
        const CartesianValueSummaryContent.automatic(),
      );
      expect(
        success.warnings.map((warning) => warning.code),
        contains(ChartArtifactDiagnosticCodes.runtimeBindingRequired),
      );
    });
  });
}

ChartInteractionDocument _encode(
  InteractionConfig config, {
  Map<String, JsonObjectValue> descriptors = const {},
}) {
  final result = ChartInteractionDocumentCodec.encode(
    config,
    runtimeBindingDescriptors: descriptors,
  );
  expect(result, isA<ChartArtifactSuccess<ChartInteractionDocument>>());
  return (result as ChartArtifactSuccess<ChartInteractionDocument>).value;
}

InteractionConfig _decode(
  ChartInteractionDocument document, {
  ChartRuntimeBindings bindings = const ChartRuntimeBindings(),
}) {
  final result = ChartInteractionDocumentCodec.decode(
    document,
    bindings: bindings,
  );
  expect(result, isA<ChartArtifactSuccess<InteractionConfig>>());
  return (result as ChartArtifactSuccess<InteractionConfig>).value;
}

Map<String, Object?> _configurationJson(ChartInteractionDocument document) =>
    Map<String, Object?>.from(document.configuration.toJson() as Map);

Map<String, Object?> _valueSummaryJson(ChartInteractionDocument document) =>
    Map<String, Object?>.from(
      _configurationJson(document)['valueSummary']! as Map,
    );

ChartInteractionDocument _mutateValueSummary(
  ChartInteractionDocument document,
  Map<String, Object?> Function(Map<String, Object?> summary) mutate,
) {
  final json = _configurationJson(document);
  json['valueSummary'] = mutate(
    Map<String, Object?>.from(json['valueSummary']! as Map),
  );
  return ChartInteractionDocument(
    configuration: JsonValue.fromJson(json) as JsonObjectValue,
    requiredBindings: document.requiredBindings,
  );
}

ChartDocumentSnapshot _extract(InteractionConfig interaction) {
  final series = LineChartSeries(
    id: 'power',
    name: 'Power',
    unit: 'W',
    color: const Color(0xFF2563EB),
    points: const [
      ChartDataPoint(x: 0, y: 180),
      ChartDataPoint(x: 1, y: 210),
      ChartDataPoint(x: 2, y: 195),
    ],
  );
  final theme = ChartTheme.light;
  final result = ChartDocumentExtractor.extract(
    source: ChartDocumentExtractionSource(
      allSeries: [series],
      visibleSeries: [series],
      declaredSeries: [series],
      annotations: const [],
      xAxis: const XAxisConfig(label: 'Sample'),
      axes: [
        YAxisConfig.withId(
          id: 'y',
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
        ),
      ],
      theme: theme,
      interaction: interaction,
      legendVisible: true,
      legendStyle: theme.legendStyle,
      grid: const GridConfig(),
      normalizationMode: NormalizationMode.none,
      backgroundColor: Colors.white,
      showToolbar: false,
      interactiveAnnotations: true,
      maxAxesPerSide: 3,
      axisSwapMode: AxisSwapMode.sticky,
      viewState: ChartViewState(),
    ),
    options: const ChartDocumentExtractOptions(
      documentId: 'value-summary-codec-test',
    ),
    revision: 1,
  );
  expect(result, isA<ChartArtifactSuccess<ChartDocumentSnapshot>>());
  return (result as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
}

HydratedChartConfiguration _hydrate(ChartDocument document) {
  final result = ChartDocumentHydrator.hydrateDocument(document);
  expect(result, isA<ChartArtifactSuccess<HydratedChartConfiguration>>());
  return (result as ChartArtifactSuccess<HydratedChartConfiguration>).value;
}
