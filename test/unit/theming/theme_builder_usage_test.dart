// ChartThemeBuilder Usage Tests
// Feature: 004-theming-system
// Phase 3: Theme Builder (T030)

import 'package:braven_charts/src/theming/builder/chart_theme_builder.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/components/grid_style.dart';
import 'package:braven_charts/src/theming/components/series_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartThemeBuilder - Usage Patterns', () {
    group('Minimal Customization', () {
      test('customize single property (backgroundColor)', () {
        final theme = ChartThemeBuilder().backgroundColor(Colors.grey).build();

        expect(theme.backgroundColor, equals(Colors.grey));
        // Other properties should remain at default values
        expect(theme.borderColor, equals(const Color(0xFFE0E0E0)));
        expect(theme.borderWidth, equals(1.0));
      });

      test('customize two properties (backgroundColor + borderWidth)', () {
        final theme = ChartThemeBuilder().backgroundColor(Colors.blue).borderWidth(2.0).build();

        expect(theme.backgroundColor, equals(Colors.blue));
        expect(theme.borderWidth, equals(2.0));
        // Other properties at defaults
        expect(theme.borderColor, equals(const Color(0xFFE0E0E0)));
      });

      test('customize padding only', () {
        final customPadding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
        final theme = ChartThemeBuilder().padding(customPadding).build();

        expect(theme.padding, equals(customPadding));
        expect(theme.backgroundColor, equals(const Color(0xFFFFFFFF)));
      });

      test('customize border color and width', () {
        final theme = ChartThemeBuilder().borderColor(const Color(0xFF1976D2)).borderWidth(3.0).build();

        expect(theme.borderColor, equals(const Color(0xFF1976D2)));
        expect(theme.borderWidth, equals(3.0));
      });
    });

    group('Starting from Predefined Theme', () {
      test('customize vibrant theme with different padding', () {
        final theme = ChartThemeBuilder.from(ChartTheme.vibrant).padding(const EdgeInsets.all(32.0)).build();

        // Custom property
        expect(theme.padding, equals(const EdgeInsets.all(32.0)));

        // Inherited from vibrant
        expect(theme.backgroundColor, equals(ChartTheme.vibrant.backgroundColor));
        expect(theme.borderColor, equals(ChartTheme.vibrant.borderColor));
        expect(theme.seriesTheme, equals(ChartTheme.vibrant.seriesTheme));
      });

      test('customize defaultDark with lighter border', () {
        final theme = ChartThemeBuilder.from(ChartTheme.defaultDark).borderWidth(2.0).borderColor(Colors.grey).build();

        expect(theme.borderWidth, equals(2.0));
        expect(theme.borderColor, equals(Colors.grey));
        expect(theme.backgroundColor, equals(ChartTheme.defaultDark.backgroundColor));
      });

      test('start from corporateBlue and change background', () {
        final theme = ChartThemeBuilder.from(ChartTheme.corporateBlue).backgroundColor(const Color(0xFFF5F5F5)).build();

        expect(theme.backgroundColor, equals(const Color(0xFFF5F5F5)));
        expect(theme.seriesTheme, equals(ChartTheme.corporateBlue.seriesTheme));
      });

      test('customize minimal theme with bolder grid', () {
        final theme = ChartThemeBuilder.from(ChartTheme.minimal).gridStyle(GridStyle.defaultLight).build();

        expect(theme.gridStyle, equals(GridStyle.defaultLight));
        expect(theme.backgroundColor, equals(ChartTheme.minimal.backgroundColor));
      });

      test('high contrast with custom series colors', () {
        final theme = ChartThemeBuilder.from(ChartTheme.highContrast).seriesTheme(SeriesTheme.vibrant).build();

        expect(theme.seriesTheme, equals(SeriesTheme.vibrant));
        expect(theme.backgroundColor, equals(ChartTheme.highContrast.backgroundColor));
      });
    });

    group('Complex Customization', () {
      test('customize all chart-level properties', () {
        final theme = ChartThemeBuilder()
            .backgroundColor(const Color(0xFFFAFAFA))
            .borderColor(const Color(0xFF1976D2))
            .borderWidth(3.0)
            .padding(const EdgeInsets.all(24.0))
            .build();

        expect(theme.backgroundColor, equals(const Color(0xFFFAFAFA)));
        expect(theme.borderColor, equals(const Color(0xFF1976D2)));
        expect(theme.borderWidth, equals(3.0));
        expect(theme.padding, equals(const EdgeInsets.all(24.0)));
      });

      test('customize multiple component themes', () {
        final theme = ChartThemeBuilder().gridStyle(GridStyle.minimal).seriesTheme(SeriesTheme.vibrant).build();

        expect(theme.gridStyle, equals(GridStyle.minimal));
        expect(theme.seriesTheme, equals(SeriesTheme.vibrant));
      });

      test('comprehensive enterprise theme customization', () {
        final theme = ChartThemeBuilder()
            .backgroundColor(const Color(0xFFFAFAFA))
            .borderColor(const Color(0xFF1976D2))
            .borderWidth(3.0)
            .padding(const EdgeInsets.all(24.0))
            .gridStyle(GridStyle.corporateBlue)
            .seriesTheme(SeriesTheme.corporateBlue)
            .build();

        expect(theme.backgroundColor, equals(const Color(0xFFFAFAFA)));
        expect(theme.borderColor, equals(const Color(0xFF1976D2)));
        expect(theme.borderWidth, equals(3.0));
        expect(theme.padding, equals(const EdgeInsets.all(24.0)));
        expect(theme.gridStyle, equals(GridStyle.corporateBlue));
        expect(theme.seriesTheme, equals(SeriesTheme.corporateBlue));
      });

      test('mix and match components from different predefined themes', () {
        final theme = ChartThemeBuilder()
            .backgroundColor(ChartTheme.defaultLight.backgroundColor)
            .borderColor(ChartTheme.vibrant.borderColor)
            .gridStyle(ChartTheme.minimal.gridStyle)
            .seriesTheme(ChartTheme.corporateBlue.seriesTheme)
            .build();

        expect(theme.backgroundColor, equals(ChartTheme.defaultLight.backgroundColor));
        expect(theme.borderColor, equals(ChartTheme.vibrant.borderColor));
        expect(theme.gridStyle, equals(ChartTheme.minimal.gridStyle));
        expect(theme.seriesTheme, equals(ChartTheme.corporateBlue.seriesTheme));
      });
    });

    group('Method Chaining', () {
      test('fluent API supports continuous chaining', () {
        final builder = ChartThemeBuilder();

        final result = builder.backgroundColor(Colors.white).borderColor(Colors.grey).borderWidth(1.0).padding(const EdgeInsets.all(16.0));

        // Each method should return the same builder instance
        expect(identical(result, builder), isTrue);
      });

      test('long chain of customizations', () {
        final theme = ChartThemeBuilder()
            .backgroundColor(const Color(0xFFFFFFFF))
            .borderColor(const Color(0xFFE0E0E0))
            .borderWidth(1.0)
            .padding(const EdgeInsets.all(16.0))
            .gridStyle(GridStyle.defaultLight)
            .seriesTheme(SeriesTheme.defaultLight)
            .build();

        expect(theme.backgroundColor, equals(const Color(0xFFFFFFFF)));
        expect(theme.borderColor, equals(const Color(0xFFE0E0E0)));
        expect(theme.borderWidth, equals(1.0));
      });

      test('can reassign values in chain (last wins)', () {
        final theme = ChartThemeBuilder()
            .backgroundColor(Colors.red)
            .backgroundColor(Colors.blue) // Override previous value
            .build();

        expect(theme.backgroundColor, equals(Colors.blue));
      });

      test('chaining from predefined theme', () {
        final theme = ChartThemeBuilder.from(ChartTheme.vibrant).backgroundColor(Colors.white).borderWidth(1.0).build();

        expect(theme.backgroundColor, equals(Colors.white));
        expect(theme.borderWidth, equals(1.0));
      });
    });

    group('Builder Reusability', () {
      test('builder state persists between builds', () {
        final builder = ChartThemeBuilder().backgroundColor(Colors.grey).borderWidth(1.0);

        final theme1 = builder.build();

        // Modify builder after first build
        builder.borderWidth(2.0);

        final theme2 = builder.build();

        // First theme has original state
        expect(theme1.backgroundColor, equals(Colors.grey));
        expect(theme1.borderWidth, equals(1.0));

        // Second theme has modified state
        expect(theme2.backgroundColor, equals(Colors.grey));
        expect(theme2.borderWidth, equals(2.0));
      });

      test('multiple builds from same builder state', () {
        final builder = ChartThemeBuilder().backgroundColor(Colors.blue).borderWidth(2.0);

        final theme1 = builder.build();
        final theme2 = builder.build();

        // Both themes should be equal
        expect(theme1, equals(theme2));
        expect(theme1.backgroundColor, equals(Colors.blue));
        expect(theme2.backgroundColor, equals(Colors.blue));
      });
    });

    group('Real-World Usage Scenarios', () {
      test('create light theme variant with custom brand colors', () {
        final brandPrimary = const Color(0xFF1976D2);
        final brandBackground = const Color(0xFFFAFAFA);

        final theme = ChartThemeBuilder.from(ChartTheme.defaultLight).backgroundColor(brandBackground).borderColor(brandPrimary).build();

        expect(theme.backgroundColor, equals(brandBackground));
        expect(theme.borderColor, equals(brandPrimary));
      });

      test('create dark theme with accessibility improvements', () {
        final theme = ChartThemeBuilder.from(ChartTheme.defaultDark).borderWidth(2.0).seriesTheme(SeriesTheme.colorblindFriendly).build();

        expect(theme.borderWidth, equals(2.0));
        expect(theme.seriesTheme, equals(SeriesTheme.colorblindFriendly));
      });

      test('create mobile-optimized theme with larger padding', () {
        final theme = ChartThemeBuilder.from(ChartTheme.defaultLight).padding(const EdgeInsets.all(20.0)).build();

        expect(theme.padding, equals(const EdgeInsets.all(20.0)));
      });

      test('create print-friendly theme', () {
        final theme = ChartThemeBuilder()
            .backgroundColor(Colors.white)
            .borderColor(Colors.black)
            .borderWidth(2.0)
            .gridStyle(GridStyle.highContrast)
            .seriesTheme(SeriesTheme.highContrast)
            .build();

        expect(theme.backgroundColor, equals(Colors.white));
        expect(theme.borderColor, equals(Colors.black));
        expect(theme.gridStyle, equals(GridStyle.highContrast));
      });

      test('create dashboard theme with minimal styling', () {
        final theme = ChartThemeBuilder.from(ChartTheme.minimal).padding(const EdgeInsets.all(8.0)).borderWidth(0.0).build();

        expect(theme.padding, equals(const EdgeInsets.all(8.0)));
        expect(theme.borderWidth, equals(0.0));
      });
    });

    group('Default Constructor Behavior', () {
      test('default constructor matches ChartTheme.defaultLight values', () {
        final builtTheme = ChartThemeBuilder().build();
        final defaultLight = ChartTheme.defaultLight;

        expect(builtTheme.backgroundColor, equals(defaultLight.backgroundColor));
        expect(builtTheme.borderColor, equals(defaultLight.borderColor));
        expect(builtTheme.borderWidth, equals(defaultLight.borderWidth));
        expect(builtTheme.padding, equals(defaultLight.padding));
      });
    });

    group('From Constructor Behavior', () {
      test('from() constructor creates exact copy when no setters called', () {
        final original = ChartTheme.vibrant;
        final copy = ChartThemeBuilder.from(original).build();

        expect(copy, equals(original));
      });

      test('from() works with all predefined themes', () {
        final themes = [
          ChartTheme.defaultLight,
          ChartTheme.defaultDark,
          ChartTheme.corporateBlue,
          ChartTheme.vibrant,
          ChartTheme.minimal,
          ChartTheme.highContrast,
          ChartTheme.colorblindFriendly,
        ];

        for (final original in themes) {
          final copy = ChartThemeBuilder.from(original).build();
          expect(copy, equals(original));
        }
      });
    });
  });
}
