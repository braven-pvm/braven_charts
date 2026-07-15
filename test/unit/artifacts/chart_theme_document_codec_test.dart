import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartThemeDocumentCodec', () {
    test('round-trips every built-in resolved theme preset', () {
      final presets = <String, ChartTheme>{
        'braven.light': ChartTheme.light,
        'braven.dark': ChartTheme.dark,
        'braven.corporateBlue': ChartTheme.corporateBlue,
        'braven.vibrant': ChartTheme.vibrant,
        'braven.minimal': ChartTheme.minimal,
        'braven.highContrast': ChartTheme.highContrast,
        'braven.colorblindFriendly': ChartTheme.colorblindFriendly,
      };

      for (final entry in presets.entries) {
        final document = _success(
          ChartThemeDocumentCodec.encode(entry.value, reference: entry.key),
        );
        final jsonRoundTrip = ChartThemeDocument.fromJson(document.toJson());
        final decoded = _success(ChartThemeDocumentCodec.decode(jsonRoundTrip));

        _expectThemeFields(decoded, entry.value, entry.key);
        expect(jsonRoundTrip.reference, entry.key);
        expect(
          jsonRoundTrip.captureMode,
          ChartThemeCaptureMode.referenceAndResolved.name,
        );
      }
    });

    test('resolved payload includes every appearance component', () {
      final document = _success(
        ChartThemeDocumentCodec.encode(ChartTheme.highContrast),
      );

      expect(document.resolved.values.keys, {
        'backgroundColor',
        'gridStyle',
        'axisStyle',
        'seriesTheme',
        'interactionTheme',
        'typographyTheme',
        'animationTheme',
        'annotationTheme',
        'scrollbarConfig',
        'legendStyle',
        'focusBorderColor',
        'focusBorderWidth',
        'focusBorderRadius',
      });
      final annotation =
          document.resolved.values['annotationTheme']!.toJson()
              as Map<String, Object?>;
      expect(annotation.keys, {
        'pointDefaults',
        'rangeDefaults',
        'textDefaults',
        'thresholdDefaults',
        'trendDefaults',
      });
    });

    test('reference-only capture requires a host registry to hydrate', () {
      final document = _success(
        ChartThemeDocumentCodec.encode(
          ChartTheme.light,
          captureMode: ChartThemeCaptureMode.referenceOnly,
          reference: 'braven.light',
        ),
      );

      expect(document.resolved.values, isEmpty);
      final result = ChartThemeDocumentCodec.decode(document);
      expect(result, isA<ChartArtifactFailure<ChartTheme>>());
      expect(
        (result as ChartArtifactFailure<ChartTheme>).error.code,
        ChartArtifactDiagnosticCodes.runtimeBindingRequired,
      );
    });

    test('resolved-only capture omits a semantic reference when absent', () {
      final document = _success(
        ChartThemeDocumentCodec.encode(
          ChartTheme.dark,
          captureMode: ChartThemeCaptureMode.resolvedOnly,
        ),
      );

      expect(document.captureMode, ChartThemeCaptureMode.resolvedOnly.name);
      expect(document.reference, isNull);
      _expectThemeFields(
        _success(ChartThemeDocumentCodec.decode(document)),
        ChartTheme.dark,
        'resolved dark',
      );
    });

    test('fails closed for custom animation curves', () {
      final theme = ChartTheme.light.copyWith(
        animationTheme: ChartTheme.light.animationTheme.copyWith(
          dataUpdateCurve: const Cubic(0.1, 0.2, 0.3, 0.4),
        ),
      );

      final result = ChartThemeDocumentCodec.encode(theme);

      expect(result, isA<ChartArtifactFailure<ChartThemeDocument>>());
      final failure = result as ChartArtifactFailure<ChartThemeDocument>;
      expect(
        failure.error.code,
        ChartArtifactDiagnosticCodes.unsupportedModelType,
      );
      expect(failure.error.path, contains('dataUpdateCurve'));
    });

    test('rejects malformed resolved component values', () {
      final result = ChartThemeDocumentCodec.decode(
        ChartThemeDocument(
          resolved:
              JsonValue.fromJson({'backgroundColor': 'not-a-color'})
                  as JsonObjectValue,
        ),
      );

      expect(result, isA<ChartArtifactFailure<ChartTheme>>());
      expect(
        (result as ChartArtifactFailure<ChartTheme>).error.code,
        ChartArtifactDiagnosticCodes.invalidArtifact,
      );
    });
  });
}

T _success<T>(ChartArtifactResult<T> result) {
  expect(result, isA<ChartArtifactSuccess<T>>());
  return (result as ChartArtifactSuccess<T>).value;
}

void _expectThemeFields(ChartTheme actual, ChartTheme expected, String reason) {
  expect(actual.backgroundColor, expected.backgroundColor, reason: reason);
  expect(actual.gridStyle, expected.gridStyle, reason: '$reason grid');
  expect(actual.axisStyle, expected.axisStyle, reason: '$reason axis');
  expect(actual.seriesTheme, expected.seriesTheme, reason: '$reason series');
  expect(
    actual.interactionTheme,
    expected.interactionTheme,
    reason: '$reason interaction',
  );
  expect(
    actual.typographyTheme,
    expected.typographyTheme,
    reason: '$reason typography',
  );
  expect(
    actual.animationTheme,
    expected.animationTheme,
    reason: '$reason animation',
  );
  expect(
    actual.annotationTheme,
    expected.annotationTheme,
    reason: '$reason annotations',
  );
  expect(
    actual.scrollbarConfig,
    expected.scrollbarConfig,
    reason: '$reason scrollbar',
  );
  expect(actual.legendStyle, expected.legendStyle, reason: '$reason legend');
  expect(
    actual.focusBorderColor.toARGB32(),
    expected.focusBorderColor.toARGB32(),
    reason: reason,
  );
  expect(actual.focusBorderWidth, expected.focusBorderWidth, reason: reason);
  expect(actual.focusBorderRadius, expected.focusBorderRadius, reason: reason);
}
