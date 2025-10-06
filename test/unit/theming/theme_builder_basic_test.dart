// ChartThemeBuilder Basic Test
// Feature: 004-theming-system
// Phase 3: Theme Builder (T028)

import 'package:braven_charts/src/theming/builder/chart_theme_builder.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartThemeBuilder - Basic Functionality', () {
    test('default constructor creates builder with default values', () {
      final builder = ChartThemeBuilder();
      final theme = builder.build();

      expect(theme.backgroundColor, equals(const Color(0xFFFFFFFF)));
      expect(theme.borderColor, equals(const Color(0xFFE0E0E0)));
      expect(theme.borderWidth, equals(1.0));
      expect(theme.padding, equals(const EdgeInsets.all(16.0)));
    });

    test('from() constructor copies existing theme', () {
      final original = ChartTheme.vibrant;
      final builder = ChartThemeBuilder.from(original);
      final theme = builder.build();

      expect(theme, equals(original));
    });

    test('fluent setters return builder for chaining', () {
      final builder = ChartThemeBuilder();
      final result = builder.backgroundColor(Colors.blue);

      expect(result, same(builder));
    });

    test('build() creates ChartTheme with set values', () {
      final theme = ChartThemeBuilder().backgroundColor(Colors.grey).borderWidth(2.0).build();

      expect(theme.backgroundColor, equals(Colors.grey));
      expect(theme.borderWidth, equals(2.0));
    });
  });
}
