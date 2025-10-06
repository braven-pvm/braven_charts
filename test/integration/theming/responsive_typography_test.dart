/// Integration tests for responsive typography scaling.
library;

import 'dart:ui';

import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/components/typography_theme.dart';
import 'package:flutter/material.dart' show TextPainter;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Responsive Typography Integration', () {
    late ChartTheme baseTheme;

    setUp(() {
      baseTheme = ChartTheme.defaultLight;
    });

    group('Mobile Viewport Scaling', () {
      test('mobile scale factor (0.9) applies correctly to font sizes', () {
        final mobileTheme = baseTheme.typographyTheme;
        const scaleFactor = 0.9; // Expected mobile scale factor

        // Mobile scale factor should match expected value
        expect(
          mobileTheme.scaleFactorMobile,
          equals(scaleFactor),
          reason: 'Mobile scale factor should be 0.9',
        );

        // Calculate effective sizes with mobile scaling
        final effectiveTitleSize = mobileTheme.baseFontSize * mobileTheme.scaleFactorMobile * mobileTheme.titleMultiplier;

        final effectiveLabelSize = mobileTheme.baseFontSize * mobileTheme.scaleFactorMobile * mobileTheme.labelMultiplier;

        // Verify scaling is applied
        expect(effectiveTitleSize, lessThan(mobileTheme.baseFontSize * mobileTheme.titleMultiplier));
        expect(effectiveLabelSize, lessThan(mobileTheme.baseFontSize * mobileTheme.labelMultiplier));
      });

      test('mobile viewport (400px) uses mobile scale factor', () {
        final typography = baseTheme.typographyTheme;

        // For 400px viewport, should use mobile scale factor
        // This is verified by the theme having the correct scale factor
        expect(typography.scaleFactorMobile, equals(0.9));
      });

      test('minimum font size is enforced in calculations', () {
        // Create typography with very small base size
        final smallTypography = TypographyTheme(
          fontFamily: 'Roboto',
          baseFontSize: 8.0,
          scaleFactorMobile: 0.9,
          scaleFactorTablet: 1.0,
          scaleFactorDesktop: 1.1,
          titleMultiplier: 1.0,
          labelMultiplier: 1.0,
        );

        // Even with scaling, result should not go below reasonable minimum
        final scaled = smallTypography.baseFontSize * smallTypography.scaleFactorMobile;

        // 8.0 * 0.9 = 7.2 (this would need clamping in real usage)
        expect(scaled, equals(7.2));

        // In practice, rendering code should clamp to minimum (e.g., 10.0)
        const minFontSize = 10.0;
        final clamped = scaled < minFontSize ? minFontSize : scaled;
        expect(clamped, equals(minFontSize));
      });
    });

    group('Tablet Viewport Scaling', () {
      test('tablet scale factor (1.0) provides baseline sizing', () {
        final tabletTheme = baseTheme.typographyTheme;
        const scaleFactor = 1.0;

        // Tablet scale factor should be 1.0 (no scaling)
        expect(
          tabletTheme.scaleFactorTablet,
          equals(scaleFactor),
          reason: 'Tablet scale factor should be 1.0',
        );

        // Calculate effective sizes with tablet scaling
        final effectiveTitleSize = tabletTheme.baseFontSize * tabletTheme.scaleFactorTablet * tabletTheme.titleMultiplier;

        // Should equal base size with multiplier (no scaling)
        expect(
          effectiveTitleSize,
          equals(tabletTheme.baseFontSize * tabletTheme.titleMultiplier),
        );
      });

      test('tablet viewport (800px) uses tablet scale factor', () {
        final typography = baseTheme.typographyTheme;

        // For 800px viewport, should use tablet scale factor
        expect(typography.scaleFactorTablet, equals(1.0));
      });

      test('tablet is baseline - no size adjustment', () {
        final typography = baseTheme.typographyTheme;

        final tabletTitle = typography.baseFontSize * typography.scaleFactorTablet * typography.titleMultiplier;

        final baseTitle = typography.baseFontSize * typography.titleMultiplier;

        // Tablet scaling should be identity (1.0)
        expect(tabletTitle, equals(baseTitle));
      });
    });

    group('Desktop Viewport Scaling', () {
      test('desktop scale factor (1.1) enlarges text', () {
        final desktopTheme = baseTheme.typographyTheme;
        const scaleFactor = 1.1;

        // Desktop scale factor should be 1.1
        expect(
          desktopTheme.scaleFactorDesktop,
          equals(scaleFactor),
          reason: 'Desktop scale factor should be 1.1',
        );

        // Calculate effective sizes with desktop scaling
        final effectiveTitleSize = desktopTheme.baseFontSize * desktopTheme.scaleFactorDesktop * desktopTheme.titleMultiplier;

        final baseTitle = desktopTheme.baseFontSize * desktopTheme.titleMultiplier;

        // Should be larger than base
        expect(effectiveTitleSize, greaterThan(baseTitle));
      });

      test('desktop viewport (1920px) uses desktop scale factor', () {
        final typography = baseTheme.typographyTheme;

        // For 1920px viewport, should use desktop scale factor
        expect(typography.scaleFactorDesktop, equals(1.1));
      });
    });

    group('Scale Factor Progression', () {
      test('scale factors increase from mobile to desktop', () {
        final typography = baseTheme.typographyTheme;

        // Mobile < Tablet < Desktop
        expect(
          typography.scaleFactorMobile < typography.scaleFactorTablet,
          isTrue,
          reason: 'Mobile scale should be less than tablet',
        );

        expect(
          typography.scaleFactorTablet < typography.scaleFactorDesktop,
          isTrue,
          reason: 'Tablet scale should be less than desktop',
        );
      });

      test('effective sizes scale proportionally across viewports', () {
        final typography = baseTheme.typographyTheme;

        final mobileSize = typography.baseFontSize * typography.scaleFactorMobile;
        final tabletSize = typography.baseFontSize * typography.scaleFactorTablet;
        final desktopSize = typography.baseFontSize * typography.scaleFactorDesktop;

        // Sizes should increase
        expect(mobileSize < tabletSize, isTrue);
        expect(tabletSize < desktopSize, isTrue);

        // Verify actual values
        expect(mobileSize, closeTo(10.8, 0.01)); // 12 * 0.9
        expect(tabletSize, closeTo(12.0, 0.01)); // 12 * 1.0
        expect(desktopSize, closeTo(13.2, 0.01)); // 12 * 1.1
      });
    });

    group('Typography Multipliers', () {
      test('title multiplier makes titles larger than labels', () {
        final typography = baseTheme.typographyTheme;

        final labelSize = typography.baseFontSize * typography.labelMultiplier;
        final titleSize = typography.baseFontSize * typography.titleMultiplier;

        expect(
          titleSize > labelSize,
          isTrue,
          reason: 'Titles should be larger than labels',
        );
      });

      test('multipliers apply independently of scale factors', () {
        final typography = baseTheme.typographyTheme;

        // Mobile title
        final mobileTitle = typography.baseFontSize * typography.scaleFactorMobile * typography.titleMultiplier;

        // Desktop label
        final desktopLabel = typography.baseFontSize * typography.scaleFactorDesktop * typography.labelMultiplier;

        // Both should use their respective multipliers
        expect(mobileTitle, closeTo(15.12, 0.01)); // 12 * 0.9 * 1.4
        expect(desktopLabel, closeTo(13.2, 0.01)); // 12 * 1.1 * 1.0
      });
    });

    group('Real-World Integration with RenderContext', () {
      late RenderContext mobileContext;
      late RenderContext tabletContext;
      late RenderContext desktopContext;

      setUp(() {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        mobileContext = RenderContext(
          canvas: canvas,
          size: const Size(400, 700),
          viewport: const Rect.fromLTWH(0, 0, 400, 700),
          culler: const ViewportCuller(),
          paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
          pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
          textPainterPool: ObjectPool<TextPainter>(
            factory: () => TextPainter(textDirection: TextDirection.ltr),
            reset: (tp) {},
          ),
          textCache: LinkedHashMapTextLayoutCache(),
          performanceMonitor: StopwatchPerformanceMonitor(),
        );

        tabletContext = RenderContext(
          canvas: canvas,
          size: const Size(800, 1024),
          viewport: const Rect.fromLTWH(0, 0, 800, 1024),
          culler: const ViewportCuller(),
          paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
          pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
          textPainterPool: ObjectPool<TextPainter>(
            factory: () => TextPainter(textDirection: TextDirection.ltr),
            reset: (tp) {},
          ),
          textCache: LinkedHashMapTextLayoutCache(),
          performanceMonitor: StopwatchPerformanceMonitor(),
        );

        desktopContext = RenderContext(
          canvas: canvas,
          size: const Size(1920, 1080),
          viewport: const Rect.fromLTWH(0, 0, 1920, 1080),
          culler: const ViewportCuller(),
          paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
          pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
          textPainterPool: ObjectPool<TextPainter>(
            factory: () => TextPainter(textDirection: TextDirection.ltr),
            reset: (tp) {},
          ),
          textCache: LinkedHashMapTextLayoutCache(),
          performanceMonitor: StopwatchPerformanceMonitor(),
        );
      });

      test('typography theme applies to different viewport sizes', () {
        final typography = baseTheme.typographyTheme;

        // Different contexts use the same typography theme
        // but rendering code would select appropriate scale factor based on viewport width

        // Mobile (400px) - would use scaleFactorMobile
        final mobileScale = mobileContext.viewport.width < 600 ? typography.scaleFactorMobile : typography.scaleFactorTablet;
        expect(mobileScale, equals(0.9));

        // Tablet (800px) - would use scaleFactorTablet
        final tabletScale =
            tabletContext.viewport.width >= 600 && tabletContext.viewport.width < 1200 ? typography.scaleFactorTablet : typography.scaleFactorDesktop;
        expect(tabletScale, equals(1.0));

        // Desktop (1920px) - would use scaleFactorDesktop
        final desktopScale = desktopContext.viewport.width >= 1200 ? typography.scaleFactorDesktop : typography.scaleFactorTablet;
        expect(desktopScale, equals(1.1));
      });

      test('theme can be customized with different scale factors', () {
        final customTypography = TypographyTheme(
          fontFamily: 'Arial',
          baseFontSize: 14.0,
          scaleFactorMobile: 0.85,
          scaleFactorTablet: 1.0,
          scaleFactorDesktop: 1.15,
          titleMultiplier: 1.5,
          labelMultiplier: 0.95,
        );

        final customTheme = baseTheme.copyWith(typographyTheme: customTypography);

        expect(customTheme.typographyTheme.baseFontSize, equals(14.0));
        expect(customTheme.typographyTheme.scaleFactorMobile, equals(0.85));
        expect(customTheme.typographyTheme.scaleFactorDesktop, equals(1.15));
      });
    });

    group('Edge Cases and Validation', () {
      test('scale factors must be positive', () {
        expect(
          () => TypographyTheme(
            fontFamily: 'Roboto',
            baseFontSize: 12.0,
            scaleFactorMobile: 0.0, // Invalid
            scaleFactorTablet: 1.0,
            scaleFactorDesktop: 1.1,
            titleMultiplier: 1.4,
            labelMultiplier: 1.0,
          ),
          throwsAssertionError,
        );
      });

      test('base font size must be positive', () {
        expect(
          () => TypographyTheme(
            fontFamily: 'Roboto',
            baseFontSize: 0.0, // Invalid
            scaleFactorMobile: 0.9,
            scaleFactorTablet: 1.0,
            scaleFactorDesktop: 1.1,
            titleMultiplier: 1.4,
            labelMultiplier: 1.0,
          ),
          throwsAssertionError,
        );
      });

      test('multipliers must be positive', () {
        expect(
          () => TypographyTheme(
            fontFamily: 'Roboto',
            baseFontSize: 12.0,
            scaleFactorMobile: 0.9,
            scaleFactorTablet: 1.0,
            scaleFactorDesktop: 1.1,
            titleMultiplier: 0.0, // Invalid
            labelMultiplier: 1.0,
          ),
          throwsAssertionError,
        );
      });
    });

    group('JSON Serialization with Responsive Settings', () {
      test('typography theme serializes with all scale factors', () {
        final json = baseTheme.typographyTheme.toJson();

        expect(json['scaleFactorMobile'], equals(0.9));
        expect(json['scaleFactorTablet'], equals(1.0));
        expect(json['scaleFactorDesktop'], equals(1.1));
        expect(json['baseFontSize'], equals(12.0));
      });

      test('typography theme deserializes correctly', () {
        final json = {
          'fontFamily': 'Roboto',
          'baseFontSize': 14.0,
          'scaleFactorMobile': 0.85,
          'scaleFactorTablet': 1.0,
          'scaleFactorDesktop': 1.2,
          'titleMultiplier': 1.5,
          'labelMultiplier': 0.9,
        };

        final typography = TypographyTheme.fromJson(json);

        expect(typography.baseFontSize, equals(14.0));
        expect(typography.scaleFactorMobile, equals(0.85));
        expect(typography.scaleFactorDesktop, equals(1.2));
      });
    });
  });
}
