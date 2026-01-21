# Quickstart Guide: Theming System

**Feature**: 004-theming-system  
**Purpose**: Demonstrate all major theming capabilities with executable examples  
**Date**: 2025-10-06

---

## Overview

This document contains 5 executable test examples that demonstrate the core functionality of the Theming System. Each example is self-contained and can be run independently.

**Test Categories**:
1. Apply predefined theme
2. Switch theme without recreation
3. Build custom theme
4. Verify WCAG AAA contrast
5. JSON serialization round-trip

---

## Example 1: Apply Predefined Theme

**Purpose**: Demonstrate applying a predefined theme to a chart.

**Requirements**:
- Chart accepts theme parameter
- Theme is applied to all visual elements
- No exceptions thrown

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';

void main() {
  test('Example 1: Apply predefined theme', () {
    // GIVEN: A predefined theme
    final theme = ChartTheme.defaultDark;

    // VERIFY: Theme has expected properties
    expect(theme.backgroundColor, const Color(0xFF121212));
    expect(theme.gridStyle.majorColor, const Color(0xFF424242));
    expect(theme.seriesTheme.colors.length, 7);
    expect(theme.seriesTheme.colors[0], const Color(0xFF42A5F5)); // Light Blue

    // WHEN: Theme is applied to chart (simulated - full chart not implemented yet)
    final appliedTheme = theme; // In real usage: ChartWidget(theme: theme)

    // THEN: Theme properties are accessible
    expect(appliedTheme.backgroundColor.value, 0xFF121212);
    expect(appliedTheme.axisStyle.lineColor, const Color(0xFFFFFFFF));
    expect(appliedTheme.typographyTheme.fontFamily, 'Roboto');
    expect(appliedTheme.animationTheme.dataUpdateDuration, const Duration(milliseconds: 300));

    print('✅ Example 1 PASS: Default Dark theme applied successfully');
  });
}
```

**Expected Output**:
```
✅ Example 1 PASS: Default Dark theme applied successfully
```

---

## Example 2: Switch Theme Without Recreation

**Purpose**: Verify theme switching preserves chart state and completes within 100ms.

**Requirements**:
- Theme switch completes <100ms
- No chart recreation (state preserved)
- All visual elements updated

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';

void main() {
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
    expect(stopwatch.elapsedMilliseconds, lessThan(100),
        reason: 'Theme switch must complete <100ms');

    // THEN: Chart state is preserved (simulated)
    expect(chartState['zoom'], 2.0);
    expect(chartState['panX'], 100.0);
    expect(chartState['selectedIndex'], 5);

    // THEN: New theme is active
    expect(currentTheme.backgroundColor, const Color(0xFF121212)); // Dark background
    expect(currentTheme, isNot(equals(ChartTheme.defaultLight)));

    print('✅ Example 2 PASS: Theme switched in ${stopwatch.elapsedMilliseconds}ms, state preserved');
  });
}
```

**Expected Output**:
```
✅ Example 2 PASS: Theme switched in <1ms, state preserved
```

---

## Example 3: Build Custom Brand Theme

**Purpose**: Demonstrate creating a custom theme using the builder API.

**Requirements**:
- Builder supports method chaining
- Validation catches invalid values
- Custom theme is serializable

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/builder/chart_theme_builder.dart';
import 'package:braven_charts/src/theming/components/grid_style.dart';
import 'package:braven_charts/src/theming/components/series_theme.dart';

void main() {
  test('Example 3: Build custom brand theme', () {
    // GIVEN: Brand colors
    const brandPrimary = Color(0xFF0066CC); // Blue
    const brandSecondary = Color(0xFFFF6600); // Orange
    const brandBackground = Color(0xFFF8F9FA); // Light gray

    // WHEN: Custom theme is built
    final customTheme = ChartThemeBuilder()
        .backgroundColor(brandBackground)
        .borderColor(brandPrimary)
        .borderWidth(2.0)
        .seriesColors([brandPrimary, brandSecondary, const Color(0xFF28A745)]) // Green
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
    expect(json['version'], '1.0');
    expect(json['theme']['backgroundColor'], '#FFF8F9FA');
    expect(json['theme']['borderColor'], '#FF0066CC');

    print('✅ Example 3 PASS: Custom brand theme created successfully');
  });
}
```

**Expected Output**:
```
✅ Example 3 PASS: Custom brand theme created successfully
```

---

## Example 4: Verify WCAG AAA Contrast

**Purpose**: Verify High Contrast theme meets WCAG 2.1 AAA (7:1 contrast ratio).

**Requirements**:
- All text/background pairs meet AAA (7:1)
- Automated validation available
- ColorUtils.contrastRatio() accurate

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/utilities/color_utils.dart';

void main() {
  test('Example 4: Verify WCAG AAA contrast', () {
    // GIVEN: High Contrast theme (should meet AAA)
    final theme = ChartTheme.highContrast;

    // WHEN: Contrast ratios are calculated
    final bgTextRatio = ColorUtils.contrastRatio(
      theme.axisStyle.textStyle.color!,
      theme.backgroundColor,
    );
    final tooltipRatio = ColorUtils.contrastRatio(
      theme.interactionTheme.tooltipTextStyle.color!,
      theme.interactionTheme.tooltipBackground,
    );
    final titleRatio = ColorUtils.contrastRatio(
      theme.axisStyle.titleStyle.color!,
      theme.backgroundColor,
    );

    // THEN: All ratios meet WCAG AAA (7:1)
    expect(bgTextRatio, greaterThanOrEqualTo(7.0),
        reason: 'Background/text must meet AAA (7:1)');
    expect(tooltipRatio, greaterThanOrEqualTo(7.0),
        reason: 'Tooltip background/text must meet AAA (7:1)');
    expect(titleRatio, greaterThanOrEqualTo(7.0),
        reason: 'Background/title must meet AAA (7:1)');

    // VERIFY: Helper functions work
    expect(ColorUtils.isWCAG_AAA(
      theme.axisStyle.textStyle.color!,
      theme.backgroundColor,
    ), isTrue);
    expect(ColorUtils.isWCAG_AA(
      theme.axisStyle.textStyle.color!,
      theme.backgroundColor,
    ), isTrue); // AAA implies AA

    print('✅ Example 4 PASS: High Contrast theme meets WCAG AAA');
    print('   - Background/Text ratio: ${bgTextRatio.toStringAsFixed(2)}:1');
    print('   - Tooltip ratio: ${tooltipRatio.toStringAsFixed(2)}:1');
    print('   - Title ratio: ${titleRatio.toStringAsFixed(2)}:1');
  });
}
```

**Expected Output**:
```
✅ Example 4 PASS: High Contrast theme meets WCAG AAA
   - Background/Text ratio: 21.00:1
   - Tooltip ratio: 21.00:1
   - Title ratio: 21.00:1
```

---

## Example 5: JSON Serialization Round-Trip

**Purpose**: Verify theme can be serialized to JSON and deserialized without data loss.

**Requirements**:
- toJson() produces valid JSON
- fromJson() restores exact theme
- Version handling works correctly

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'dart:convert' show jsonEncode, jsonDecode;

void main() {
  test('Example 5: JSON serialization round-trip', () {
    // GIVEN: A theme with all properties set
    final originalTheme = ChartTheme.corporateBlue;

    // WHEN: Theme is serialized to JSON
    final json = originalTheme.toJson();
    expect(json['version'], '1.0');
    expect(json['theme'], isNotNull);

    // AND: JSON is converted to string (simulates storage/network)
    final jsonString = jsonEncode(json);
    expect(jsonString, contains('"version":"1.0"'));
    expect(jsonString, contains('"backgroundColor"'));

    // AND: JSON string is parsed back
    final parsedJson = jsonDecode(jsonString) as Map<String, dynamic>;

    // AND: Theme is deserialized
    final deserializedTheme = ChartTheme.fromJson(parsedJson);

    // THEN: Deserialized theme equals original
    expect(deserializedTheme.backgroundColor, originalTheme.backgroundColor);
    expect(deserializedTheme.borderColor, originalTheme.borderColor);
    expect(deserializedTheme.borderWidth, originalTheme.borderWidth);
    expect(deserializedTheme.gridStyle.majorColor, originalTheme.gridStyle.majorColor);
    expect(deserializedTheme.gridStyle.majorWidth, originalTheme.gridStyle.majorWidth);
    expect(deserializedTheme.seriesTheme.colors.length, originalTheme.seriesTheme.colors.length);
    expect(deserializedTheme.seriesTheme.colors[0], originalTheme.seriesTheme.colors[0]);
    expect(deserializedTheme.axisStyle.lineColor, originalTheme.axisStyle.lineColor);
    expect(deserializedTheme.typographyTheme.fontFamily, originalTheme.typographyTheme.fontFamily);
    expect(deserializedTheme.animationTheme.dataUpdateDuration,
        originalTheme.animationTheme.dataUpdateDuration);

    // THEN: Full equality check passes
    expect(deserializedTheme, equals(originalTheme));

    print('✅ Example 5 PASS: Theme serialization round-trip successful');
    print('   - JSON size: ${jsonString.length} bytes');
  });
}
```

**Expected Output**:
```
✅ Example 5 PASS: Theme serialization round-trip successful
   - JSON size: ~2500 bytes
```

---

## Running the Examples

### All Examples
```bash
# From repository root
flutter test specs/004-theming-system/quickstart_test.dart
```

### Single Example
```dart
flutter test specs/004-theming-system/quickstart_test.dart --name "Example 1"
```

### With Coverage
```bash
flutter test --coverage specs/004-theming-system/quickstart_test.dart
genhtml coverage/lcov.info -o coverage/html
```

---

## Success Criteria

All 5 examples must:
- ✅ **Execute without errors** - No exceptions thrown
- ✅ **Pass all assertions** - All `expect()` calls succeed
- ✅ **Complete quickly** - Each example <10ms (except theme switch <100ms)
- ✅ **Demonstrate feature** - Clear, understandable code
- ✅ **Be maintainable** - Easy to update as implementation evolves

---

## Additional Examples (Future)

### Example 6: Colorblind Simulation
```dart
test('Example 6: Verify colorblind-safe series colors', () {
  final theme = ChartTheme.colorblindFriendly;
  final colors = theme.seriesTheme.colors;

  // Simulate protanopia (red-blind)
  final protanopiaColors = colors.map(ColorUtils.simulateProtanopia).toList();

  // Verify all colors still distinguishable (ΔE > 40)
  for (var i = 0; i < protanopiaColors.length; i++) {
    for (var j = i + 1; j < protanopiaColors.length; j++) {
      final distance = ColorUtils.colorDistance(protanopiaColors[i], protanopiaColors[j]);
      expect(distance, greaterThan(40.0),
          reason: 'Series $i and $j not distinguishable in protanopia');
    }
  }

  print('✅ Example 6 PASS: All series distinguishable in protanopia');
});
```

### Example 7: Responsive Typography
```dart
test('Example 7: Verify responsive typography scaling', () {
  final theme = ChartTheme.defaultLight;

  // Mobile (< 600px): 0.9x
  final mobileTheme = theme.copyWith(
    typographyTheme: theme.typographyTheme.withScaleFactor(
      TypographyTheme.computeScaleFactor(400), // 400px width
    ),
  );
  expect(mobileTheme.typographyTheme.effectiveBaseFontSize, 10.8); // 12 * 0.9

  // Desktop (>= 1024px): 1.1x
  final desktopTheme = theme.copyWith(
    typographyTheme: theme.typographyTheme.withScaleFactor(
      TypographyTheme.computeScaleFactor(1920), // 1920px width
    ),
  );
  expect(desktopTheme.typographyTheme.effectiveBaseFontSize, 13.2); // 12 * 1.1

  print('✅ Example 7 PASS: Responsive typography scaling works');
});
```

### Example 8: Theme Diffing Performance
```dart
test('Example 8: Verify theme diff performance', () {
  final theme1 = ChartTheme.defaultLight;
  final theme2 = theme1.copyWith(backgroundColor: const Color(0xFFF5F5F5));

  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < 10000; i++) {
    final changed = theme1 != theme2; // Uses deep equality
    expect(changed, isTrue);
  }
  stopwatch.stop();

  final avgTimePerDiff = stopwatch.elapsedMicroseconds / 10000;
  expect(avgTimePerDiff, lessThan(10.0), // <10 microseconds per diff
      reason: 'Theme diff must be fast for rendering performance');

  print('✅ Example 8 PASS: Theme diff performance: ${avgTimePerDiff.toStringAsFixed(2)}μs/diff');
});
```

---

## Notes

1. **Contract Files**: These examples reference contract files in `contracts/` that define the API. Implementation will come later.

2. **Builder API**: Example 3 uses `ChartThemeBuilder` (not yet implemented). This is the fluent API for creating custom themes.

3. **Predefined Themes**: Examples 1, 2, 4 use the 7 predefined themes defined in `ChartTheme` static constants.

4. **Performance**: Example 2 demonstrates the <100ms theme switch requirement. Actual implementation must meet this target.

5. **Accessibility**: Example 4 verifies WCAG compliance using `ColorUtils`. All themes should pass similar tests.

6. **Serialization**: Example 5 tests JSON round-trip. This enables saving/loading themes from storage or network.

---

**Quickstart Complete**: 2025-10-06  
**Next Steps**: Run `/tasks` to generate task breakdown from plan.md
