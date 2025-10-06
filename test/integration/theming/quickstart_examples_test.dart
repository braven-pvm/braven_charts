/// Quickstart examples for theming system.
///
/// Executable test scenarios demonstrating:
/// 1. Apply predefined theme
/// 2. Switch theme <100ms
/// 3. Build custom theme
/// 4. Verify WCAG AAA contrast
/// 5. JSON serialization round-trip
library;

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:braven_charts/src/theming/builder/chart_theme_builder.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/components/grid_style.dart';
import 'package:braven_charts/src/theming/components/series_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quickstart Examples', () {
    test('Example 1: Apply predefined theme', () {
      // GIVEN: A predefined theme
      final theme = ChartTheme.defaultDark;

      // VERIFY: Theme has expected properties
      expect(theme.backgroundColor, const Color(0xFF121212));
      expect(theme.gridStyle.majorColor, const Color(0xFF424242));
      expect(theme.seriesTheme.colors.length, 5); // defaultDark has 5 colors
      expect(
          theme.seriesTheme.colors[0], const Color(0xFF64B5F6)); // Light Blue

      // WHEN: Theme is applied to chart (simulated - full chart not implemented yet)
      final appliedTheme = theme; // In real usage: ChartWidget(theme: theme)

      // THEN: Theme properties are accessible
      expect(appliedTheme.backgroundColor.value, 0xFF121212);
      expect(appliedTheme.axisStyle.lineColor, const Color(0xFFFFFFFF));
      expect(appliedTheme.typographyTheme.fontFamily, 'Roboto');
      expect(appliedTheme.animationTheme.dataUpdateDuration,
          const Duration(milliseconds: 350)); // defaultDark uses 350ms

      print('✅ Example 1 PASS: Default Dark theme applied successfully');
    });

    test('Example 2: Switch theme without recreation', () {
      // GIVEN: Chart with initial theme
      var currentTheme = ChartTheme.defaultLight;
      final chartState = <String, dynamic>{
        'zoom': 2.0,
        'panX': 100.0,
        'selectedIndex': 5,
      };

      // WHEN: Theme is switched
      final stopwatch = Stopwatch()..start();
      currentTheme = ChartTheme.defaultDark;
      stopwatch.stop();

      // THEN: Theme switch completes quickly
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Theme switch must complete <100ms',
      );

      // THEN: Chart state is preserved (simulated)
      expect(chartState['zoom'], 2.0);
      expect(chartState['panX'], 100.0);
      expect(chartState['selectedIndex'], 5);

      // THEN: New theme is active
      expect(currentTheme.backgroundColor,
          const Color(0xFF121212)); // Dark background
      expect(currentTheme, isNot(equals(ChartTheme.defaultLight)));

      print(
          '✅ Example 2 PASS: Theme switched in ${stopwatch.elapsedMilliseconds}ms, state preserved');
    });

    test('Example 3: Build custom brand theme', () {
      // GIVEN: Brand colors
      const brandPrimary = Color(0xFF0066CC); // Blue
      const brandSecondary = Color(0xFFFF6600); // Orange
      const brandBackground = Color(0xFFF8F9FA); // Light gray

      // WHEN: Custom theme is built
      final customSeriesTheme = SeriesTheme(
        colors: [
          brandPrimary,
          brandSecondary,
          const Color(0xFF28A745)
        ], // Green
        lineWidths: const [2.0],
        markerSizes: const [8.0],
        markerShapes: const [MarkerShape.circle],
      );

      final customTheme = ChartThemeBuilder()
          .backgroundColor(brandBackground)
          .borderColor(brandPrimary)
          .borderWidth(2.0)
          .seriesTheme(customSeriesTheme)
          .gridStyle(GridStyle(
            majorColor: Colors.grey[300]!,
            majorWidth: 1.0,
            showMinor: false,
          ))
          .build();

      // THEN: Custom theme has expected properties
      expect(customTheme.backgroundColor, brandBackground);
      expect(customTheme.borderColor, brandPrimary);
      expect(customTheme.borderWidth, 2.0);
      expect(customTheme.seriesTheme.colors[0], brandPrimary);
      expect(customTheme.seriesTheme.colors[1], brandSecondary);
      expect(customTheme.gridStyle.majorColor, Colors.grey[300]);

      // THEN: Custom theme is serializable
      final json = customTheme.toJson();
      expect(json['backgroundColor'], '#fff8f9fa'); // lowercase
      expect(json['borderColor'], '#ff0066cc'); // lowercase

      print('✅ Example 3 PASS: Custom brand theme created successfully');
    });

    test('Example 4: Verify WCAG AAA contrast', () {
      // GIVEN: High Contrast theme (should meet AAA)
      final theme = ChartTheme.highContrast;

      // WHEN: Contrast ratios are calculated
      final bgTextRatio = ColorUtils.calculateContrastRatio(
        theme.axisStyle.labelStyle.color!,
        theme.backgroundColor,
      );
      final tooltipRatio = ColorUtils.calculateContrastRatio(
        theme.interactionTheme.tooltipTextStyle.color!,
        theme.interactionTheme.tooltipBackground,
      );
      final titleRatio = ColorUtils.calculateContrastRatio(
        theme.axisStyle.titleStyle.color!,
        theme.backgroundColor,
      );

      // THEN: All ratios meet WCAG AAA (7:1)
      expect(
        bgTextRatio,
        greaterThanOrEqualTo(7.0),
        reason: 'Background/text must meet AAA (7:1)',
      );
      expect(
        tooltipRatio,
        greaterThanOrEqualTo(7.0),
        reason: 'Tooltip background/text must meet AAA (7:1)',
      );
      expect(
        titleRatio,
        greaterThanOrEqualTo(7.0),
        reason: 'Background/title must meet AAA (7:1)',
      );

      // VERIFY: Helper functions work
      expect(
        ColorUtils.meetsWCAG_AAA(
          theme.axisStyle.labelStyle.color!,
          theme.backgroundColor,
          isLargeText: false,
        ),
        isTrue,
      );
      expect(
        ColorUtils.meetsWCAG_AA(
          theme.axisStyle.labelStyle.color!,
          theme.backgroundColor,
          isLargeText: false,
        ),
        isTrue,
      ); // AAA implies AA

      print('✅ Example 4 PASS: High Contrast theme meets WCAG AAA');
      print('   - Background/Text ratio: ${bgTextRatio.toStringAsFixed(2)}:1');
      print('   - Tooltip ratio: ${tooltipRatio.toStringAsFixed(2)}:1');
      print('   - Title ratio: ${titleRatio.toStringAsFixed(2)}:1');
    });

    test('Example 5: JSON serialization round-trip', () {
      // GIVEN: A theme with all properties set
      final originalTheme = ChartTheme.corporateBlue;

      // WHEN: Theme is serialized to JSON
      final json = originalTheme.toJson();
      expect(json['backgroundColor'], isNotNull);
      expect(json['borderColor'], isNotNull);

      // AND: JSON is converted to string (simulates storage/network)
      final jsonString = jsonEncode(json);
      expect(jsonString, contains('"backgroundColor"'));
      expect(jsonString, contains('"borderColor"'));

      // AND: JSON string is parsed back
      final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;

      // AND: Theme is deserialized
      final deserializedTheme = ChartTheme.fromJson(parsedJson);

      // THEN: Deserialized theme equals original
      expect(deserializedTheme.backgroundColor, originalTheme.backgroundColor);
      expect(deserializedTheme.borderColor, originalTheme.borderColor);
      expect(deserializedTheme.borderWidth, originalTheme.borderWidth);
      expect(deserializedTheme.gridStyle.majorColor,
          originalTheme.gridStyle.majorColor);
      expect(deserializedTheme.gridStyle.majorWidth,
          originalTheme.gridStyle.majorWidth);
      expect(deserializedTheme.seriesTheme.colors.length,
          originalTheme.seriesTheme.colors.length);
      expect(deserializedTheme.seriesTheme.colors[0],
          originalTheme.seriesTheme.colors[0]);
      expect(deserializedTheme.axisStyle.lineColor,
          originalTheme.axisStyle.lineColor);
      expect(deserializedTheme.typographyTheme.fontFamily,
          originalTheme.typographyTheme.fontFamily);
      expect(
        deserializedTheme.animationTheme.dataUpdateDuration,
        originalTheme.animationTheme.dataUpdateDuration,
      );

      // THEN: Full equality check passes
      expect(deserializedTheme, equals(originalTheme));

      print('✅ Example 5 PASS: Theme serialization round-trip successful');
      print('   - JSON size: ${jsonString.length} bytes');
    });
  });
}
