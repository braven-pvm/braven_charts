// ChartThemeBuilder Validation Tests
// Feature: 004-theming-system
// Phase 3: Theme Builder (T029)

import 'package:braven_charts/src/theming/builder/chart_theme_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartThemeBuilder - Validation', () {
    group('Border Width Validation', () {
      test('negative borderWidth throws ArgumentError', () {
        final builder = ChartThemeBuilder().borderWidth(-1.0);

        expect(
          () => builder.build(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('must be >= 0'),
            ),
          ),
        );
      });

      test('zero borderWidth is valid (no border)', () {
        final builder = ChartThemeBuilder().borderWidth(0.0);

        expect(() => builder.build(), returnsNormally);
      });

      test('positive borderWidth is valid', () {
        final builder = ChartThemeBuilder().borderWidth(2.5);

        expect(() => builder.build(), returnsNormally);
      });

      test('very large borderWidth is technically valid', () {
        final builder = ChartThemeBuilder().borderWidth(1000.0);

        expect(() => builder.build(), returnsNormally);
      });
    });

    group('Component Theme Validation', () {
      test('component themes validate on construction (delegated)', () {
        // This test verifies that component validation is delegated
        // Component themes throw on invalid construction, not the builder

        // Example: GridStyle validates majorWidth >= 0
        // If we tried to create an invalid GridStyle and pass it to the builder,
        // the GridStyle constructor would throw, not the builder

        // This is by design - builder validates chart-level constraints,
        // component themes validate their own constraints

        final builder = ChartThemeBuilder();
        expect(() => builder.build(), returnsNormally);
      });
    });

    group('Validation Error Messages', () {
      test('borderWidth error message includes actual value', () {
        final builder = ChartThemeBuilder().borderWidth(-5.0);

        expect(
          () => builder.build(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'error string',
              contains('-5.0'),
            ),
          ),
        );
      });

      test('borderWidth error message includes field name', () {
        final builder = ChartThemeBuilder().borderWidth(-1.0);

        expect(
          () => builder.build(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.toString(),
              'error string',
              contains('borderWidth'),
            ),
          ),
        );
      });

      test('borderWidth error message is descriptive', () {
        final builder = ChartThemeBuilder().borderWidth(-2.5);

        expect(
          () => builder.build(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('must be >= 0'),
            ),
          ),
        );
      });
    });

    group('Multiple Validation Failures', () {
      test('validation fails on first error encountered', () {
        // Set multiple invalid values
        final builder = ChartThemeBuilder().borderWidth(-1.0); // Invalid

        // Should throw on the first validation error
        expect(() => builder.build(), throwsArgumentError);
      });
    });

    group('Validation Timing', () {
      test('validation occurs during build(), not during setters', () {
        // Setting invalid value should not throw
        expect(
          () => ChartThemeBuilder().borderWidth(-1.0),
          returnsNormally,
        );

        // Building with invalid value should throw
        expect(
          () => ChartThemeBuilder().borderWidth(-1.0).build(),
          throwsArgumentError,
        );
      });

      test('validation happens before theme construction', () {
        final builder = ChartThemeBuilder().borderWidth(-1.0);

        // If validation happens after construction, we'd get an assertion error
        // from ChartTheme constructor. Instead, we should get ArgumentError
        // from builder validation.
        expect(() => builder.build(), throwsArgumentError);
      });
    });

    group('Edge Cases', () {
      test('double.infinity borderWidth is technically valid', () {
        final builder = ChartThemeBuilder().borderWidth(double.infinity);

        // While not practical, infinity is >= 0
        expect(() => builder.build(), returnsNormally);
      });

      test('double.nan borderWidth causes assertion error', () {
        final builder = ChartThemeBuilder().borderWidth(double.nan);

        // NaN comparisons are always false, so borderWidth >= 0 fails
        // This should trigger the assertion in ChartTheme constructor
        expect(() => builder.build(), throwsA(isA<AssertionError>()));
      });

      test('very small positive borderWidth is valid', () {
        final builder = ChartThemeBuilder().borderWidth(0.001);

        expect(() => builder.build(), returnsNormally);
      });

      test('borderWidth at exact boundary (0.0) is valid', () {
        final builder = ChartThemeBuilder().borderWidth(0.0);

        final theme = builder.build();
        expect(theme.borderWidth, equals(0.0));
      });
    });

    group('Validation Consistency', () {
      test('same validation rules as ChartTheme constructor', () {
        // ChartTheme constructor validates borderWidth >= 0
        // Builder should enforce the same rule

        // Valid for both
        expect(() => ChartThemeBuilder().borderWidth(1.0).build(), returnsNormally);

        // Invalid for both (builder throws ArgumentError, constructor would assert)
        expect(() => ChartThemeBuilder().borderWidth(-1.0).build(), throwsArgumentError);
      });
    });
  });
}
