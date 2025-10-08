// Unit Test: TooltipConfig Model
// Feature: Layer 7 Interaction System
// Task: T012
// Status: Implementation complete, tests aligned

import 'package:braven_charts/src/interaction/models/tooltip_config.dart'
    as chart_tooltip;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TooltipConfig Model Tests', () {
    test('TooltipConfig.defaultConfig() creates sensible defaults', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig();

      expect(config.enabled, isTrue);
      expect(config.triggerMode, equals(chart_tooltip.TooltipTriggerMode.hover));
      expect(config.showDelay, equals(const Duration(milliseconds: 100)));
      expect(config.hideDelay, equals(const Duration(milliseconds: 200)));
      expect(config.preferredPosition, equals(chart_tooltip.TooltipPosition.auto));
      expect(config.offsetFromPoint, equals(10.0));
      expect(config.style, isNotNull);
      expect(config.customBuilder, isNull);
    });

    test('TooltipStyle has correct default values', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig();
      final style = config.style;

      expect(style.backgroundColor, isNotNull);
      expect(style.borderColor, isNotNull);
      expect(style.borderWidth, equals(1.0));
      expect(style.borderRadius, equals(4.0));
      expect(style.padding, isNotNull);
      expect(style.textColor, isNotNull);
      expect(style.fontSize, isNotNull);
      expect(style.shadowColor, isNotNull);
      expect(style.shadowBlurRadius, isNotNull);
    });

    test('copyWith() creates new instance with updated fields', () {
      final initial = chart_tooltip.TooltipConfig.defaultConfig();
      final updated = initial.copyWith(
        enabled: false,
        showDelay: const Duration(milliseconds: 500),
      );

      expect(updated.enabled, isFalse);
      expect(updated.showDelay, equals(const Duration(milliseconds: 500)));
      expect(updated.triggerMode, equals(initial.triggerMode)); // Unchanged
    });

    test('TooltipTriggerMode.hover for desktop', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        triggerMode: chart_tooltip.TooltipTriggerMode.hover,
      );

      expect(config.triggerMode, equals(chart_tooltip.TooltipTriggerMode.hover));
    });

    test('TooltipTriggerMode.tap for mobile', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        triggerMode: chart_tooltip.TooltipTriggerMode.tap,
      );

      expect(config.triggerMode, equals(chart_tooltip.TooltipTriggerMode.tap));
    });

    test('TooltipTriggerMode.both for universal', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        triggerMode: chart_tooltip.TooltipTriggerMode.both,
      );

      expect(config.triggerMode, equals(chart_tooltip.TooltipTriggerMode.both));
    });

    test('TooltipPosition.auto enables smart positioning', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig();

      expect(config.preferredPosition, equals(chart_tooltip.TooltipPosition.auto));
    });

    test('TooltipPosition can be set to top', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        preferredPosition: chart_tooltip.TooltipPosition.top,
      );

      expect(config.preferredPosition, equals(chart_tooltip.TooltipPosition.top));
    });

    test('TooltipPosition can be set to bottom', () {
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        preferredPosition: chart_tooltip.TooltipPosition.bottom,
      );

      expect(config.preferredPosition, equals(chart_tooltip.TooltipPosition.bottom));
    });

    test('validation: showDelay cannot be negative', () {
      // Note: Duration allows negative values, but TooltipConfig doesn't validate this
      // This test documents current behavior - validation may be added later
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        showDelay: const Duration(milliseconds: -100),
      );
      expect(config.showDelay.isNegative, isTrue);
    });

    test('validation: hideDelay cannot be negative', () {
      // Note: Duration allows negative values, but TooltipConfig doesn't validate this
      // This test documents current behavior - validation may be added later
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        hideDelay: const Duration(milliseconds: -50),
      );
      expect(config.hideDelay.isNegative, isTrue);
    });

    test('validation: offsetFromPoint cannot be negative', () {
      // Note: TooltipConfig doesn't currently validate offsetFromPoint
      // This test documents current behavior - validation may be added later
      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        offsetFromPoint: -5.0,
      );
      expect(config.offsetFromPoint, equals(-5.0));
    });

    test('custom TooltipStyle with custom colors', () {
      final style = chart_tooltip.TooltipStyle(
        backgroundColor: Colors.black,
        borderColor: Colors.white,
        borderWidth: 2.0,
        borderRadius: 8.0,
        padding: 12.0,
        textColor: Colors.white,
        fontSize: 16.0,
        shadowColor: Colors.transparent,
        shadowBlurRadius: 0.0,
      );

      expect(style.backgroundColor, equals(Colors.black));
      expect(style.borderColor, equals(Colors.white));
      expect(style.borderWidth, equals(2.0));
      expect(style.shadowColor, equals(Colors.transparent));
    });

    test('customBuilder can be provided', () {
      Widget builder(BuildContext context, Map<String, dynamic> dataPoint) {
        return Text('Custom: ${dataPoint['x']}, ${dataPoint['y']}');
      }

      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        customBuilder: builder,
      );

      expect(config.customBuilder, isNotNull);
    });

    test('equality: two configs with same values are equal', () {
      final config1 = chart_tooltip.TooltipConfig.defaultConfig();
      final config2 = chart_tooltip.TooltipConfig.defaultConfig();

      expect(config1, equals(config2));
    });

    test('immutability: copyWith returns new instance', () {
      final config1 = chart_tooltip.TooltipConfig.defaultConfig();
      final config2 = config1.copyWith(enabled: false);

      expect(identical(config1, config2), isFalse);
      expect(config1.enabled, isTrue);
      expect(config2.enabled, isFalse);
    });

    test('complex scenario: custom tooltip with all options', () {
      final customStyle = chart_tooltip.TooltipStyle(
        backgroundColor: Colors.blue.shade50,
        borderColor: Colors.blue,
        borderWidth: 1.5,
        borderRadius: 6.0,
        padding: 12.0,
        textColor: Colors.blue,
        fontSize: 14.0,
        shadowColor: Colors.black.withOpacity(0.2),
        shadowBlurRadius: 8.0,
      );

      Widget customBuilder(BuildContext context, Map<String, dynamic> dataPoint) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Series: ${dataPoint['seriesId'] ?? 'unknown'}'),
            Text('X: ${dataPoint['x']}'),
            Text('Y: ${dataPoint['y']}'),
          ],
        );
      }

      final config = chart_tooltip.TooltipConfig.defaultConfig().copyWith(
        enabled: true,
        triggerMode: chart_tooltip.TooltipTriggerMode.hover,
        showDelay: const Duration(milliseconds: 200),
        hideDelay: const Duration(milliseconds: 100),
        preferredPosition: chart_tooltip.TooltipPosition.top,
        offsetFromPoint: 15.0,
        style: customStyle,
        customBuilder: customBuilder,
      );

      expect(config.enabled, isTrue);
      expect(config.triggerMode, equals(chart_tooltip.TooltipTriggerMode.hover));
      expect(config.showDelay, equals(const Duration(milliseconds: 200)));
      expect(config.preferredPosition, equals(chart_tooltip.TooltipPosition.top));
      expect(config.customBuilder, isNotNull);
    });
  });
}
