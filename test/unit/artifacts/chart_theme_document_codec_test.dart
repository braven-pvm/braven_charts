import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
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
        'pieChartTheme',
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

    test('round-trips advanced Pie theme styling', () {
      final theme = ChartTheme.dark.copyWith(
        pieChartTheme: const PieChartTheme(
          opacity: 0.72,
          cornerRadius: 11,
          cornerTreatment: PieCornerTreatment.circularCenter,
          gradient: PieGradientStyle(
            type: PieGradientType.linear,
            startColor: Color(0xFFABCDEF),
            endColor: Color(0xFF123456),
            startLightnessShift: 0.2,
            endLightnessShift: -0.15,
            angleDegrees: 25,
          ),
          shadow: PieElevationStyle(
            color: Color(0x66000000),
            blurRadius: 8,
            spreadRadius: 1,
            offset: Offset(0, 3),
            opacity: 0.8,
          ),
          selectedElevation: PieElevationStyle(
            color: Color(0xFF64B5F6),
            blurRadius: 14,
            spreadRadius: 2,
            opacity: 0.5,
          ),
          borderColorMode: PieBorderColorMode.slice,
          borderHueShiftDegrees: 18,
          borderSaturationShift: -0.08,
          borderLightnessShift: -0.2,
          calloutStyle: LabelStyle(
            textStyle: TextStyle(color: Colors.white, fontSize: 13),
            backgroundColor: Color(0xE6212121),
            borderColor: Color(0xFF64B5F6),
            borderWidth: 1.5,
            borderRadius: 9,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shadowColor: Color(0x66000000),
            shadowBlurRadius: 6,
          ),
          centerLabelStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFFB0BEC5), fontSize: 11),
            backgroundColor: Color(0x00000000),
            borderColor: Color(0x00000000),
            borderWidth: 0,
            borderRadius: 0,
            padding: EdgeInsets.zero,
          ),
          centerValueStyle: LabelStyle(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            backgroundColor: Color(0x22000000),
            borderColor: Color(0xFF64B5F6),
            borderWidth: 1,
            borderRadius: 10,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          animationMode: PieAnimationMode.fade,
        ),
      );

      final decoded = _success(
        ChartThemeDocumentCodec.decode(
          _success(ChartThemeDocumentCodec.encode(theme)),
        ),
      );

      expect(decoded.pieChartTheme, theme.pieChartTheme);
    });

    test('defaults older Pie themes to the legacy corner treatment', () {
      final encoded = _success(
        ChartThemeDocumentCodec.encode(
          ChartTheme.light.copyWith(
            pieChartTheme: const PieChartTheme(cornerRadius: 8),
          ),
        ),
      );
      final resolved = Map<String, Object?>.from(
        encoded.resolved.toJson() as Map<String, Object?>,
      );
      final pieTheme = Map<String, Object?>.from(
        resolved['pieChartTheme']! as Map<String, Object?>,
      )..remove('cornerTreatment');
      resolved['pieChartTheme'] = pieTheme;
      final legacyDocument = ChartThemeDocument(
        captureMode: encoded.captureMode,
        reference: encoded.reference,
        resolved: JsonValue.fromJson(resolved) as JsonObjectValue,
      );

      final decoded = _success(ChartThemeDocumentCodec.decode(legacyDocument));

      expect(
        decoded.pieChartTheme.cornerTreatment,
        PieCornerTreatment.roundAll,
      );
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
  expect(actual.pieChartTheme, expected.pieChartTheme, reason: '$reason pie');
  expect(
    actual.focusBorderColor.toARGB32(),
    expected.focusBorderColor.toARGB32(),
    reason: reason,
  );
  expect(actual.focusBorderWidth, expected.focusBorderWidth, reason: reason);
  expect(actual.focusBorderRadius, expected.focusBorderRadius, reason: reason);
}
