// Unit Test: CrosshairConfig Model
// Feature: Layer 7 Interaction System
// Task: T011
// Status: Implementation complete, tests aligned

import 'package:braven_charts/src/interaction/models/crosshair_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrosshairConfig Model Tests', () {
    test('CrosshairConfig.defaultConfig() creates sensible defaults', () {
      final config = CrosshairConfig.defaultConfig();

      expect(config.enabled, isTrue);
      expect(config.mode, equals(CrosshairMode.both));
      expect(config.snapToDataPoint, isTrue);
      expect(config.snapRadius, equals(20.0));
      expect(config.showCoordinateLabels, isTrue);
      expect(config.style, isNotNull);
      expect(config.coordinateLabelStyle, isNotNull);
    });

    test('CrosshairStyle has correct default values', () {
      final config = CrosshairConfig.defaultConfig();
      final style = config.style;

      expect(style.lineColor, isNotNull);
      expect(style.lineWidth, equals(1.0));
      expect(style.dashPattern, isNotNull); // [5, 3] for dashed
      expect(style.strokeCap, equals(StrokeCap.round));
    });

    test('copyWith() creates new instance with updated fields', () {
      final initial = CrosshairConfig.defaultConfig();
      final updated = initial.copyWith(
        enabled: false,
        snapRadius: 30.0,
      );

      expect(updated.enabled, isFalse);
      expect(updated.snapRadius, equals(30.0));
      expect(updated.mode, equals(initial.mode)); // Unchanged
    });

    test('CrosshairMode.none disables rendering', () {
      final config = CrosshairConfig.defaultConfig().copyWith(
        mode: CrosshairMode.none,
      );

      expect(config.mode, equals(CrosshairMode.none));
    });

    test('CrosshairMode.vertical shows only vertical line', () {
      final config = CrosshairConfig.defaultConfig().copyWith(
        mode: CrosshairMode.vertical,
      );

      expect(config.mode, equals(CrosshairMode.vertical));
    });

    test('CrosshairMode.horizontal shows only horizontal line', () {
      final config = CrosshairConfig.defaultConfig().copyWith(
        mode: CrosshairMode.horizontal,
      );

      expect(config.mode, equals(CrosshairMode.horizontal));
    });

    test('CrosshairMode.both shows full crosshair', () {
      final config = CrosshairConfig.defaultConfig();

      expect(config.mode, equals(CrosshairMode.both));
    });

    test('validation: snapRadius cannot be negative', () {
      expect(
        () => CrosshairConfig.defaultConfig().copyWith(
          snapRadius: -10.0, // Invalid
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('validation: lineWidth must be positive', () {
      expect(
        () => CrosshairStyle(
          lineColor: Colors.blue,
          lineWidth: 0.0, // Invalid - should throw
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('custom CrosshairStyle with solid line', () {
      final style = const CrosshairStyle(
        lineColor: Colors.red,
        lineWidth: 2.0,
        dashPattern: null, // Solid line
        strokeCap: StrokeCap.square,
      );

      expect(style.lineColor, equals(Colors.red));
      expect(style.lineWidth, equals(2.0));
      expect(style.dashPattern, isNull);
      expect(style.strokeCap, equals(StrokeCap.square));
    });

    test('custom CrosshairStyle with dashed line', () {
      final style = const CrosshairStyle(
        lineColor: Colors.green,
        lineWidth: 1.5,
        dashPattern: [10, 5], // Custom dash pattern
        strokeCap: StrokeCap.round,
      );

      expect(style.dashPattern, equals([10, 5]));
    });

    test('equality: two configs with same values are equal', () {
      final config1 = CrosshairConfig.defaultConfig();
      final config2 = CrosshairConfig.defaultConfig();

      expect(config1, equals(config2));
    });

    test('immutability: copyWith returns new instance', () {
      final config1 = CrosshairConfig.defaultConfig();
      final config2 = config1.copyWith(enabled: false);

      expect(identical(config1, config2), isFalse);
      expect(config1.enabled, isTrue);
      expect(config2.enabled, isFalse);
    });

    test('complex scenario: custom crosshair with all options', () {
      final customStyle = const CrosshairStyle(
        lineColor: Colors.purple,
        lineWidth: 2.5,
        dashPattern: [8, 4],
        strokeCap: StrokeCap.butt,
      );

      final config = CrosshairConfig.defaultConfig().copyWith(
        enabled: true,
        mode: CrosshairMode.vertical,
        snapToDataPoint: false,
        snapRadius: 15.0,
        style: customStyle,
        showCoordinateLabels: false,
      );

      expect(config.enabled, isTrue);
      expect(config.mode, equals(CrosshairMode.vertical));
      expect(config.snapToDataPoint, isFalse);
      expect(config.snapRadius, equals(15.0));
      expect(config.showCoordinateLabels, isFalse);
      expect(config.style.lineColor, equals(Colors.purple));
    });
  });
}
