import 'package:flutter/material.dart';import 'package:flutter/material.dart';import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/theming/components/scrollbar_config.dart';import 'package:flutter_test/flutter_test.dart';import 'package:flutter_test/flutter_test.dart';



/// Contract test for ScrollbarConfig immutability and copyWith()import 'package:braven_charts/src/theming/components/scrollbar_config.dart';import 'package:braven_charts/src/theming/components/scrollbar_config.dart';

///

/// Tests that ScrollbarConfig is properly immutable and supports selective

/// field modification via copyWith() pattern (required for theme customization).

////// Contract test for ScrollbarConfig immutability and copyWith()/// Contract test for ScrollbarConfig immutability and copyWith()

/// See data-model.md Entity 3 "ScrollbarConfig" for specification.

void main() {//////

  group('ScrollbarConfig - CONTRACT', () {

    test('MUST be immutable (instances with identical values are equal)', () {/// Tests that ScrollbarConfig is properly immutable and supports selective/// Tests that ScrollbarConfig is properly immutable and supports selective

      const config1 = ScrollbarConfig();

      const config2 = ScrollbarConfig();/// field modification via copyWith() pattern (required for theme customization)./// field modification via copyWith() pattern (required for theme customization).



      expect(config1, equals(config2));//////

      expect(config1.hashCode, equals(config2.hashCode));

    });/// See data-model.md Entity 3 "ScrollbarConfig" for specification./// See data-model.md Entity 3 "ScrollbarConfig" for specification.



    test('MUST support copyWith() for selective field modification', () {void main() {void main() {

      const original = ScrollbarConfig.defaultLight;

  group('ScrollbarConfig - CONTRACT', () {  group('ScrollbarConfig - CONTRACT', () {

      final modified = original.copyWith(thickness: 16.0);

    test('MUST be immutable (instances with identical values are equal)', () {    test('MUST be immutable (all fields final)', () {

      expect(modified.thickness, equals(16.0)); // Changed

      expect(modified.minHandleSize, equals(original.minHandleSize)); // Unchanged      // ARRANGE: Create two instances with identical default values      // ARRANGE: Create two instances with identical default values

      expect(modified.trackColor, equals(original.trackColor)); // Unchanged

      expect(modified.handleColor, equals(original.handleColor)); // Unchanged      const config1 = ScrollbarConfig();      const config1 = ScrollbarConfig();

      expect(modified.handleHoverColor, equals(original.handleHoverColor)); // Unchanged

      expect(modified.handleActiveColor, equals(original.handleActiveColor)); // Unchanged      const config2 = ScrollbarConfig();      const config2 = ScrollbarConfig();

      expect(modified.edgeGripWidth, equals(original.edgeGripWidth)); // Unchanged

      expect(modified.autoHide, equals(original.autoHide)); // Unchanged

      expect(modified.autoHideDelay, equals(original.autoHideDelay)); // Unchanged

      expect(modified.fadeDuration, equals(original.fadeDuration)); // Unchanged      // ASSERT: Instances with identical values must be equal      // ASSERT: Instances with identical values must be equal

      expect(modified.minZoomRatio, equals(original.minZoomRatio)); // Unchanged

      expect(modified.maxZoomRatio, equals(original.maxZoomRatio)); // Unchanged      expect(config1, equals(config2));      expect(config1, equals(config2));

    });

      expect(config1.hashCode, equals(config2.hashCode));      expect(config1.hashCode, equals(config2.hashCode));

    test('MUST support copyWith() for multiple field modifications', () {

      const original = ScrollbarConfig.defaultLight;    });    });



      final modified = original.copyWith(

        thickness: 16.0,

        handleColor: const Color(0xFF000000),    test('MUST support copyWith() for selective field modification', () {    test('MUST support copyWith() for selective field modification', () {

        autoHide: false,

        minZoomRatio: 0.05,      // ARRANGE: Start with default light theme      // ARRANGE: Start with default light theme

      );

      const original = ScrollbarConfig.defaultLight;      const original = ScrollbarConfig.defaultLight;

      expect(modified.thickness, equals(16.0)); // Changed

      expect(modified.handleColor, equals(const Color(0xFF000000))); // Changed

      expect(modified.autoHide, equals(false)); // Changed

      expect(modified.minZoomRatio, equals(0.05)); // Changed      // ACT: Modify only thickness using copyWith()      // ACT: Modify only thickness using copyWith()



      expect(modified.minHandleSize, equals(original.minHandleSize));      final modified = original.copyWith(thickness: 16.0);      final modified = original.copyWith(thickness: 16.0);

      expect(modified.trackColor, equals(original.trackColor));

      expect(modified.handleHoverColor, equals(original.handleHoverColor));

      expect(modified.handleActiveColor, equals(original.handleActiveColor));

      expect(modified.edgeGripWidth, equals(original.edgeGripWidth));      // ASSERT: Modified field should change, sample of others should remain identical      // ASSERT: Modified field should change, all others should remain identical

      expect(modified.autoHideDelay, equals(original.autoHideDelay));

      expect(modified.fadeDuration, equals(original.fadeDuration));      expect(modified.thickness, equals(16.0)); // Changed      expect(modified.thickness, equals(16.0)); // Changed

      expect(modified.maxZoomRatio, equals(original.maxZoomRatio));

    });      expect(modified.minHandleSize, equals(original.minHandleSize)); // Unchanged      expect(modified.minHandleSize, equals(original.minHandleSize)); // Unchanged



    test('MUST have correct default values in predefined themes', () {      expect(modified.trackColor, equals(original.trackColor)); // Unchanged      expect(modified.trackColor, equals(original.trackColor)); // Unchanged

      const light = ScrollbarConfig.defaultLight;

      const dark = ScrollbarConfig.defaultDark;      expect(modified.handleColor, equals(original.handleColor)); // Unchanged      expect(modified.handleColor, equals(original.handleColor)); // Unchanged

      const highContrast = ScrollbarConfig.highContrast;

      expect(modified.handleHoverColor, equals(original.handleHoverColor)); // Unchanged      expect(modified.hoverHandleColor, equals(original.hoverHandleColor)); // Unchanged

      expect(light.thickness, equals(12.0));

      expect(light.minHandleSize, equals(20.0));      expect(modified.handleActiveColor, equals(original.handleActiveColor)); // Unchanged      expect(modified.activeHandleColor, equals(original.activeHandleColor)); // Unchanged

      expect(light.trackColor, equals(Color(0xFFF5F5F5)));

      expect(light.handleColor, equals(Color(0xFFBDBDBD)));      expect(modified.edgeGripWidth, equals(original.edgeGripWidth)); // Unchanged      expect(modified.edgeGripWidth, equals(original.edgeGripWidth)); // Unchanged

      expect(light.handleHoverColor, equals(Color(0xFF9E9E9E)));

      expect(light.handleActiveColor, equals(Color(0xFF757575)));      expect(modified.autoHide, equals(original.autoHide)); // Unchanged      expect(modified.edgeGripColor, equals(original.edgeGripColor)); // Unchanged

      expect(light.autoHide, equals(true));

      expect(light.autoHideDelay, equals(Duration(seconds: 2)));      expect(modified.autoHideDelay, equals(original.autoHideDelay)); // Unchanged      expect(modified.autoHideEnabled, equals(original.autoHideEnabled)); // Unchanged

      expect(light.fadeDuration, equals(Duration(milliseconds: 200)));

      expect(light.minZoomRatio, equals(0.01));      expect(modified.fadeDuration, equals(original.fadeDuration)); // Unchanged      expect(modified.autoHideDelay, equals(original.autoHideDelay)); // Unchanged

      expect(light.maxZoomRatio, equals(1.0));

      expect(modified.minZoomRatio, equals(original.minZoomRatio)); // Unchanged      expect(modified.fadeDuration, equals(original.fadeDuration)); // Unchanged

      expect(dark.thickness, equals(12.0));

      expect(dark.minHandleSize, equals(20.0));      expect(modified.maxZoomRatio, equals(original.maxZoomRatio)); // Unchanged      expect(modified.minZoomForScrollbar, equals(original.minZoomForScrollbar)); // Unchanged

      expect(dark.trackColor, equals(Color(0xFF212121)));

      expect(dark.handleColor, equals(Color(0xFF616161)));    });      expect(modified.maxZoomForScrollbar, equals(original.maxZoomForScrollbar)); // Unchanged

      expect(dark.handleHoverColor, equals(Color(0xFF757575)));

      expect(dark.handleActiveColor, equals(Color(0xFF9E9E9E)));      expect(modified.enableKeyboardScrolling, equals(original.enableKeyboardScrolling)); // Unchanged



      expect(highContrast.thickness, equals(14.0));    test('MUST support copyWith() for multiple field modifications', () {      expect(modified.keyboardScrollIncrement, equals(original.keyboardScrollIncrement)); // Unchanged

      expect(highContrast.minHandleSize, equals(24.0));

      expect(highContrast.trackColor, equals(Color(0xFFFFFFFF)));      // ARRANGE: Start with default light theme      expect(modified.enableWheelScrolling, equals(original.enableWheelScrolling)); // Unchanged

      expect(highContrast.handleColor, equals(Color(0xFF000000)));

      expect(highContrast.handleHoverColor, equals(Color(0xFF1976D2)));      const original = ScrollbarConfig.defaultLight;      expect(modified.wheelScrollMultiplier, equals(original.wheelScrollMultiplier)); // Unchanged

      expect(highContrast.handleActiveColor, equals(Color(0xFFD32F2F)));

      expect(highContrast.autoHide, equals(false));      expect(modified.enableSemantics, equals(original.enableSemantics)); // Unchanged

    });

      // ACT: Modify multiple fields using copyWith()      expect(modified.semanticLabel, equals(original.semanticLabel)); // Unchanged

    test('MUST support JSON serialization round-trip', () {

      const original = ScrollbarConfig(      final modified = original.copyWith(      expect(modified.semanticHint, equals(original.semanticHint)); // Unchanged

        thickness: 14.0,

        minHandleSize: 28.0,        thickness: 16.0,      expect(modified.semanticValue, equals(original.semanticValue)); // Unchanged

        trackColor: Color(0xFF123456),

        handleColor: Color(0xFF789ABC),        handleColor: Color(0xFF000000),    });

        autoHide: false,

        minZoomRatio: 0.05,        autoHide: false,

      );

        minZoomRatio: 0.05,    test('MUST support copyWith() for multiple field modifications', () {

      final json = original.toJson();

      final deserialized = ScrollbarConfig.fromJson(json);      );      // ARRANGE: Start with default light theme



      expect(deserialized, equals(original));      const original = ScrollbarConfig.defaultLight;

      expect(deserialized.hashCode, equals(original.hashCode));

      // ASSERT: Modified fields should change, others should remain identical

      expect(deserialized.thickness, equals(original.thickness));

      expect(deserialized.minHandleSize, equals(original.minHandleSize));      expect(modified.thickness, equals(16.0)); // Changed      // ACT: Modify multiple fields using copyWith()

      expect(deserialized.trackColor, equals(original.trackColor));

      expect(deserialized.handleColor, equals(original.handleColor));      expect(modified.handleColor, equals(const Color(0xFF000000))); // Changed      final modified = original.copyWith(

      expect(deserialized.autoHide, equals(original.autoHide));

      expect(deserialized.minZoomRatio, equals(original.minZoomRatio));      expect(modified.autoHide, equals(false)); // Changed        thickness: 16.0,

    });

      expect(modified.minZoomRatio, equals(0.05)); // Changed        handleColor: Color(0xFF000000),

    test('MUST have different hashCodes for different configurations', () {

      const config1 = ScrollbarConfig.defaultLight;        autoHideEnabled: false,

      final config2 = config1.copyWith(thickness: 16.0);

      final config3 = config1.copyWith(handleColor: const Color(0xFF000000));      // Sample of unchanged fields        minZoomForScrollbar: 2.0,



      expect(config1.hashCode, isNot(equals(config2.hashCode)));      expect(modified.minHandleSize, equals(original.minHandleSize));      );

      expect(config1.hashCode, isNot(equals(config3.hashCode)));

      expect(config2.hashCode, isNot(equals(config3.hashCode)));      expect(modified.trackColor, equals(original.trackColor));

    });

      expect(modified.handleHoverColor, equals(original.handleHoverColor));      // ASSERT: Modified fields should change, others should remain identical

    test('MUST maintain equality transitivity', () {

      const config1 = ScrollbarConfig.defaultLight;      expect(modified.handleActiveColor, equals(original.handleActiveColor));      expect(modified.thickness, equals(16.0)); // Changed

      const config2 = ScrollbarConfig.defaultLight;

      final config3 = config1.copyWith();      expect(modified.edgeGripWidth, equals(original.edgeGripWidth));      expect(modified.handleColor, equals(const Color(0xFF000000))); // Changed



      expect(config1, equals(config2));      expect(modified.autoHideDelay, equals(original.autoHideDelay));      expect(modified.autoHideEnabled, equals(false)); // Changed

      expect(config2, equals(config3));

      expect(config1, equals(config3));      expect(modified.fadeDuration, equals(original.fadeDuration));      expect(modified.minZoomForScrollbar, equals(2.0)); // Changed

    });

      expect(modified.maxZoomRatio, equals(original.maxZoomRatio));

    test('MUST maintain equality reflexivity', () {

      const config = ScrollbarConfig.defaultLight;    });      // All other fields unchanged

      expect(config, equals(config));

    });      expect(modified.minHandleSize, equals(original.minHandleSize));



    test('MUST maintain equality symmetry', () {    test('MUST have correct default values in predefined themes', () {      expect(modified.trackColor, equals(original.trackColor));

      const config1 = ScrollbarConfig.defaultLight;

      const config2 = ScrollbarConfig.defaultLight;      // ARRANGE & ACT: Access predefined themes      expect(modified.hoverHandleColor, equals(original.hoverHandleColor));



      expect(config1, equals(config2));      const light = ScrollbarConfig.defaultLight;      expect(modified.activeHandleColor, equals(original.activeHandleColor));

      expect(config2, equals(config1));

    });      const dark = ScrollbarConfig.defaultDark;      expect(modified.edgeGripWidth, equals(original.edgeGripWidth));

  });

}      const highContrast = ScrollbarConfig.highContrast;      expect(modified.edgeGripColor, equals(original.edgeGripColor));


      expect(modified.autoHideDelay, equals(original.autoHideDelay));

      // ASSERT: Default light theme (sample of key properties)      expect(modified.fadeDuration, equals(original.fadeDuration));

      expect(light.thickness, equals(12.0));      expect(modified.maxZoomForScrollbar, equals(original.maxZoomForScrollbar));

      expect(light.minHandleSize, equals(20.0));      expect(modified.enableKeyboardScrolling, equals(original.enableKeyboardScrolling));

      expect(light.trackColor, equals(const Color(0xFFF5F5F5))); // Grey 100      expect(modified.keyboardScrollIncrement, equals(original.keyboardScrollIncrement));

      expect(light.handleColor, equals(const Color(0xFFBDBDBD))); // Grey 400      expect(modified.enableWheelScrolling, equals(original.enableWheelScrolling));

      expect(light.handleHoverColor, equals(const Color(0xFF9E9E9E))); // Grey 500      expect(modified.wheelScrollMultiplier, equals(original.wheelScrollMultiplier));

      expect(light.handleActiveColor, equals(const Color(0xFF757575))); // Grey 600      expect(modified.enableSemantics, equals(original.enableSemantics));

      expect(light.autoHide, equals(true));      expect(modified.semanticLabel, equals(original.semanticLabel));

      expect(light.autoHideDelay, equals(const Duration(seconds: 2)));      expect(modified.semanticHint, equals(original.semanticHint));

      expect(light.fadeDuration, equals(const Duration(milliseconds: 200)));      expect(modified.semanticValue, equals(original.semanticValue));

      expect(light.minZoomRatio, equals(0.01));    });

      expect(light.maxZoomRatio, equals(1.0));

    test('MUST have correct default values in predefined themes', () {

      // ASSERT: Default dark theme (key differences from light)      // ARRANGE & ACT: Access predefined themes

      expect(dark.thickness, equals(12.0));      const light = ScrollbarConfig.defaultLight;

      expect(dark.minHandleSize, equals(20.0));      const dark = ScrollbarConfig.defaultDark;

      expect(dark.trackColor, equals(Color(0xFF212121))); // Grey 900      const highContrast = ScrollbarConfig.highContrast;

      expect(dark.handleColor, equals(Color(0xFF616161))); // Grey 700

      expect(dark.handleHoverColor, equals(Color(0xFF757575))); // Grey 600      // ASSERT: Default light theme

      expect(dark.handleActiveColor, equals(Color(0xFF9E9E9E))); // Grey 500      expect(light.thickness, equals(12.0));

      expect(light.minHandleSize, equals(20.0));

      // ASSERT: High contrast theme (WCAG AAA compliance)      expect(light.trackColor, equals(Color(0xFFF5F5F5))); // Grey 100

      expect(highContrast.thickness, equals(14.0));      expect(light.handleColor, equals(Color(0xFFBDBDBD))); // Grey 400

      expect(highContrast.minHandleSize, equals(24.0));      expect(light.hoverHandleColor, equals(Color(0xFF9E9E9E))); // Grey 500

      expect(highContrast.trackColor, equals(Color(0xFFFFFFFF))); // Pure white      expect(light.activeHandleColor, equals(Color(0xFF757575))); // Grey 600

      expect(highContrast.handleColor, equals(Color(0xFF000000))); // Pure black      expect(light.edgeGripWidth, equals(6.0));

      expect(highContrast.handleHoverColor, equals(Color(0xFF1976D2))); // Blue 700      expect(light.edgeGripColor, equals(Color(0xFF9E9E9E))); // Grey 500

      expect(highContrast.handleActiveColor, equals(Color(0xFFD32F2F))); // Red 700      expect(light.autoHideEnabled, equals(true));

      expect(highContrast.autoHide, equals(false)); // Always visible for accessibility      expect(light.autoHideDelay, equals(Duration(milliseconds: 1500)));

    });      expect(light.fadeDuration, Function(Duration(milliseconds = 300)) equals);

      expect(light.minZoomForScrollbar, equals(1.1));

    test('MUST support JSON serialization (toJson/fromJson round-trip)', () {      expect(light.maxZoomForScrollbar, equals(100.0));

      // ARRANGE: Create config with custom values      expect(light.enableKeyboardScrolling, equals(true));

      const original = ScrollbarConfig(      expect(light.keyboardScrollIncrement, equals(10.0));

        thickness: 14.0,      expect(light.enableWheelScrolling, equals(true));

        minHandleSize: 28.0,      expect(light.wheelScrollMultiplier, equals(1.0));

        trackColor: Color(0xFF123456),      expect(light.enableSemantics, equals(true));

        handleColor: Color(0xFF789ABC),      expect(light.semanticLabel, isNull);

        autoHide: false,      expect(light.semanticHint, isNull);

        minZoomRatio: 0.05,      expect(light.semanticValue, isNull);

      );

      // ASSERT: Default dark theme

      // ACT: Serialize to JSON and deserialize back      expect(dark.thickness, equals(12.0));

      final json = original.toJson();      expect(dark.minHandleSize, equals(20.0));

      final deserialized = ScrollbarConfig.fromJson(json);      expect(dark.trackColor, equals(Color(0xFF212121))); // Grey 900

      expect(dark.handleColor, equals(Color(0xFF616161))); // Grey 700

      // ASSERT: Deserialized instance must equal original      expect(dark.hoverHandleColor, equals(Color(0xFF757575))); // Grey 600

      expect(deserialized, equals(original));      expect(dark.activeHandleColor, equals(Color(0xFF9E9E9E))); // Grey 500

      expect(deserialized.hashCode, equals(original.hashCode));

      // ASSERT: High contrast theme (WCAG AAA compliance)

      // ASSERT: Sample of fields preserved      expect(highContrast.thickness, equals(14.0));

      expect(deserialized.thickness, equals(original.thickness));      expect(highContrast.minHandleSize, equals(24.0));

      expect(deserialized.minHandleSize, equals(original.minHandleSize));      expect(highContrast.trackColor, equals(Color(0xFFFFFFFF))); // Pure white

      expect(deserialized.trackColor, equals(original.trackColor));      expect(highContrast.handleColor, equals(Color(0xFF000000))); // Pure black

      expect(deserialized.handleColor, equals(original.handleColor));      expect(highContrast.hoverHandleColor, equals(Color(0xFF1976D2))); // Blue 700

      expect(deserialized.autoHide, equals(original.autoHide));      expect(highContrast.activeHandleColor, equals(Color(0xFFD32F2F))); // Red 700

      expect(deserialized.minZoomRatio, equals(original.minZoomRatio));      expect(highContrast.autoHideEnabled, equals(false)); // Always visible for accessibility

    });    });



    test('MUST have different hashCodes for different configurations', () {    test('MUST support JSON serialization (toJson/fromJson round-trip)', () {

      // ARRANGE: Create configs that differ by single field      // ARRANGE: Create config with custom values

      const config1 = ScrollbarConfig.defaultLight;      const original = ScrollbarConfig(

      final config2 = config1.copyWith(thickness: 16.0);        thickness: 14.0,

      final config3 = config1.copyWith(handleColor: Color(0xFF000000));        minHandleSize: 28.0,

        trackColor: Color(0xFF123456),

      // ASSERT: Different configurations must have different hashCodes (high probability)        handleColor: Color(0xFF789ABC),

      expect(config1.hashCode, isNot(equals(config2.hashCode)));        hoverHandleColor: Color(0xFFDEF012),

      expect(config1.hashCode, isNot(equals(config3.hashCode)));        activeHandleColor: Color(0xFF345678),

      expect(config2.hashCode, isNot(equals(config3.hashCode)));        edgeGripWidth: 10.0,

    });        edgeGripColor: Color(0xFF9ABCDE),

        autoHideEnabled: false,

    test('MUST maintain equality transitivity', () {        autoHideDelay: Duration(milliseconds: 2000),

      // ARRANGE: Create three identical configs        fadeDuration: Duration(milliseconds: 500),

      const config1 = ScrollbarConfig.defaultLight;        minZoomForScrollbar: 1.5,

      const config2 = ScrollbarConfig.defaultLight;        maxZoomForScrollbar: 50.0,

      final config3 = config1.copyWith(); // Copy with no changes        enableKeyboardScrolling: false,

        keyboardScrollIncrement: 20.0,

      // ASSERT: Transitivity: if a==b and b==c, then a==c        enableWheelScrolling: false,

      expect(config1, equals(config2)); // a == b        wheelScrollMultiplier: 2.0,

      expect(config2, equals(config3)); // b == c        enableSemantics: false,

      expect(config1, equals(config3)); // a == c (transitivity)        semanticLabel: 'Custom label',

    });        semanticHint: 'Custom hint',

        semanticValue: 'Custom value',

    test('MUST maintain equality reflexivity', () {      );

      // ARRANGE: Create config

      const config = ScrollbarConfig.defaultLight;      // ACT: Serialize to JSON and deserialize back

      final json = original.toJson();

      // ASSERT: Reflexivity: a == a      final deserialized = ScrollbarConfig.fromJson(json);

      expect(config, equals(config));

    });      // ASSERT: Deserialized instance must equal original

      expect(deserialized, equals(original));

    test('MUST maintain equality symmetry', () {      expect(deserialized.hashCode, equals(original.hashCode));

      // ARRANGE: Create two identical configs

      const config1 = ScrollbarConfig.defaultLight;      // ASSERT: All fields preserved

      const config2 = ScrollbarConfig.defaultLight;      expect(deserialized.thickness, equals(original.thickness));

      expect(deserialized.minHandleSize, equals(original.minHandleSize));

      // ASSERT: Symmetry: if a==b, then b==a      expect(deserialized.trackColor, equals(original.trackColor));

      expect(config1, equals(config2));      expect(deserialized.handleColor, equals(original.handleColor));

      expect(config2, equals(config1));      expect(deserialized.hoverHandleColor, equals(original.hoverHandleColor));

    });      expect(deserialized.activeHandleColor, Function(original.activeHandleColor) equals);

  });      expect(deserialized.edgeGripWidth, Function(original.edgeGripWidth) equals);

}      expect(deserialized.edgeGripColor, Function(original.edgeGripColor) equals);

      expect(deserialized.autoHideEnabled, Function(original.autoHideEnabled) equals);
      expect(deserialized.autoHideDelay, Function(original.autoHideDelay) equals);
      expect(deserialized.fadeDuration, Function(original.fadeDuration) equals);
      expect(deserialized.minZoomForScrollbar, Function(original.minZoomForScrollbar) equals);
      expect(deserialized.maxZoomForScrollbar, Function(original.maxZoomForScrollbar) equals);
      expect(deserialized.enableKeyboardScrolling, Function(original.enableKeyboardScrolling) equals);
      expect(deserialized.keyboardScrollIncrement, Function(original.keyboardScrollIncrement) equals);
      expect(deserialized.enableWheelScrolling, Function(original.enableWheelScrolling) equals);
      expect(deserialized.wheelScrollMultiplier, Function(original.wheelScrollMultiplier) equals);
      expect(deserialized.enableSemantics, Function(original.enableSemantics) equals);
      expect(deserialized.semanticLabel, Function(original.semanticLabel) equals);
      expect(deserialized.semanticHint, Function(original.semanticHint) equals);
      expect(deserialized.semanticValue, Function(original.semanticValue) equals);
    });

    test('MUST handle null values correctly in JSON deserialization', () {
      // ARRANGE: JSON with some missing/null fields
      final json = {
        'thickness': 12.0,
        'minHandleSize': 20.0,
        'trackColor': 0xFFF5F5F5,
        'handleColor': 0xFFBDBDBD,
        'hoverHandleColor': 0xFF9E9E9E,
        'activeHandleColor': 0xFF757575,
        'edgeGripWidth': 6.0,
        'edgeGripColor': 0xFF9E9E9E,
        'autoHideEnabled': true,
        'autoHideDelayMs': 1500,
        'fadeDurationMs': 300,
        'minZoomForScrollbar': 1.1,
        'maxZoomForScrollbar': 100.0,
        'enableKeyboardScrolling': true,
        'keyboardScrollIncrement': 10.0,
        'enableWheelScrolling': true,
        'wheelScrollMultiplier': 1.0,
        'enableSemantics': true,
        // semanticLabel, semanticHint, semanticValue intentionally null
      };

      // ACT: Deserialize from JSON
      final config = ScrollbarConfig.fromJson(json);

      // ASSERT: Null values should be handled gracefully
      expect(config.semanticLabel, isNull);
      expect(config.semanticHint, isNull);
      expect(config.semanticValue, isNull);

      // ASSERT: Non-null values should be correct
      expect(config.thickness, equals(12.0));
      expect(config.minHandleSize, equals(20.0));
      expect(config.trackColor.value, equals(0xFFF5F5F5));
      expect(config.handleColor.value, equals(0xFFBDBDBD));
    });

    test('MUST have different hashCodes for different configurations', () {
      // ARRANGE: Create configs that differ by single field
      const config1 = ScrollbarConfig.defaultLight;
      final config2 = config1.copyWith(thickness: 16.0);
      final config3 = config1.copyWith(handleColor: Color(0xFF000000));

      // ASSERT: Different configurations must have different hashCodes (high probability)
      expect(config1.hashCode, isNot(equals(config2.hashCode)));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
      expect(config2.hashCode, isNot(equals(config3.hashCode)));
    });

    test('MUST maintain equality transitivity', () {
      // ARRANGE: Create three identical configs
      const config1 = ScrollbarConfig.defaultLight;
      const config2 = ScrollbarConfig.defaultLight;
      final config3 = config1.copyWith(); // Copy with no changes

      // ASSERT: Transitivity: if a==b and b==c, then a==c
      expect(config1, equals(config2)); // a == b
      expect(config2, equals(config3)); // b == c
      expect(config1, equals(config3)); // a == c (transitivity)
    });

    test('MUST maintain equality reflexivity', () {
      // ARRANGE: Create config
      const config = ScrollbarConfig.defaultLight;

      // ASSERT: Reflexivity: a == a
      expect(config, equals(config));
    });

    test('MUST maintain equality symmetry', () {
      // ARRANGE: Create two identical configs
      const config1 = ScrollbarConfig.defaultLight;
      const config2 = ScrollbarConfig.defaultLight;

      // ASSERT: Symmetry: if a==b, then b==a
      expect(config1, equals(config2));
      expect(config2, equals(config1));
    });
  });
}
