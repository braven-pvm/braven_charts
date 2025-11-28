// ============================================================================
// WIDGET TEST TEMPLATE
// ============================================================================
// Use this template for widget/UI tests. Delete this header after copying.
//
// CRITICAL REQUIREMENTS:
// 1. NEVER use `expect(find.byType(X), findsOneWidget)` as the ONLY assertion
// 2. ALWAYS test specific text, values, or visual properties
// 3. For Canvas-rendered content, use golden tests
// 4. Verify layout positions when testing multiple elements
// ============================================================================

// Copyright (c) [Year] [Project]. All rights reserved.
// Widget tests for [Feature Name]

/// # Test Suite: [Feature] Widget Tests
///
/// ## Purpose
/// Verify [Feature] renders correctly and responds to user interaction.
///
/// ## Requirements Covered
/// - FR-XXX: [Requirement text]
/// - SC-XXX: [Success criterion]
///
/// ## Verification Instructions
/// 1. Run: `flutter test [path/to/this/file]`
/// 2. Expected: All N tests pass
/// 3. Visual check: Run app manually and compare to test expectations
/// 4. Golden update (if needed): `flutter test --update-goldens [path]`
///
/// ## Canvas-Rendered Content
/// For content drawn directly on Canvas (axes, grid lines, etc.):
/// - Use golden tests (matchesGoldenFile)
/// - Or test the data that drives rendering
/// - find.text() won't find Canvas-drawn text
///
/// ## Last Verified
/// - Date: [YYYY-MM-DD]
/// - By: [Name/Agent]
/// - Commit: [hash]

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// Add component imports

void main() {
  group('[Feature Name] Widget Tests', () {
    // ========================================================================
    // Basic Rendering Tests
    // ========================================================================

    group('basic rendering', () {
      /// PROVES: Widget renders with required visual elements
      /// FAILURE MODE: Would catch missing labels, broken layout
      testWidgets('renders required text elements', (tester) async {
        // ARRANGE - Use distinctive, searchable text
        const testLabel = 'UNIQUE_TEST_LABEL_12345';
        const testValue = 'UNIQUE_TEST_VALUE_67890';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeatureWidget(
                label: testLabel,
                value: testValue,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ASSERT - Find SPECIFIC text, not just widget type
        expect(find.text(testLabel), findsOneWidget);
        expect(find.text(testValue), findsOneWidget);

        // ❌ BANNED: expect(find.byType(FeatureWidget), findsOneWidget);
        // This only proves widget exists, not that it displays correctly
      });

      /// PROVES: Multiple elements render at distinct positions
      /// FAILURE MODE: Would catch overlapping elements, wrong positions
      testWidgets('renders multiple elements at correct positions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: FeatureWidget(
                  leftElement: ElementConfig(id: 'left', label: 'LEFT'),
                  rightElement: ElementConfig(id: 'right', label: 'RIGHT'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // CRITICAL: Verify BOTH elements exist
        expect(find.text('LEFT'), findsOneWidget);
        expect(find.text('RIGHT'), findsOneWidget);

        // Verify POSITIONS
        final leftRect = tester.getRect(find.text('LEFT'));
        final rightRect = tester.getRect(find.text('RIGHT'));

        // Left element should be on left side of widget
        expect(leftRect.center.dx, lessThan(400));
        // Right element should be on right side
        expect(rightRect.center.dx, greaterThan(400));
        // They should not overlap
        expect(leftRect.right, lessThan(rightRect.left));
      });
    });

    // ========================================================================
    // Layout Tests
    // ========================================================================

    group('layout', () {
      /// PROVES: Elements are positioned correctly relative to each other
      /// FAILURE MODE: Would catch layout bugs, incorrect margins
      testWidgets('elements have correct relative positions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: FeatureWidget(
                  header: 'Header',
                  content: 'Content',
                  footer: 'Footer',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final headerRect = tester.getRect(find.text('Header'));
        final contentRect = tester.getRect(find.text('Content'));
        final footerRect = tester.getRect(find.text('Footer'));

        // Verify vertical ordering
        expect(headerRect.bottom, lessThanOrEqualTo(contentRect.top));
        expect(contentRect.bottom, lessThanOrEqualTo(footerRect.top));
      });

      /// PROVES: Widget handles different sizes correctly
      /// FAILURE MODE: Would catch responsive layout bugs
      testWidgets('adapts to container size', (tester) async {
        // Test with small size
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 200,
                child: FeatureWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final smallSize = tester.getSize(find.byType(FeatureWidget));
        expect(smallSize.width, equals(300));
        expect(smallSize.height, equals(200));

        // Test with large size
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 800,
                child: FeatureWidget(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final largeSize = tester.getSize(find.byType(FeatureWidget));
        expect(largeSize.width, equals(1200));
        expect(largeSize.height, equals(800));
      });
    });

    // ========================================================================
    // Interaction Tests
    // ========================================================================

    group('interaction', () {
      /// PROVES: Widget responds to tap correctly
      /// FAILURE MODE: Would catch broken tap handlers
      testWidgets('responds to tap with expected behavior', (tester) async {
        var tapCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeatureWidget(
                onTap: () => tapCount++,
              ),
            ),
          ),
        );

        // Verify initial state
        expect(tapCount, equals(0));

        // Perform tap
        await tester.tap(find.byType(FeatureWidget));
        await tester.pumpAndSettle();

        // Verify tap was registered
        expect(tapCount, equals(1));
      });

      /// PROVES: Widget shows hover state
      /// FAILURE MODE: Would catch broken hover effects
      testWidgets('shows hover state on mouse enter', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeatureWidget(),
            ),
          ),
        );

        // Initial state
        expect(find.byType(HoverIndicator), findsNothing);

        // Simulate hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(FeatureWidget)));
        await tester.pumpAndSettle();

        // Verify hover state
        expect(find.byType(HoverIndicator), findsOneWidget);
      });
    });

    // ========================================================================
    // Data Flow / Integration Tests
    // ========================================================================

    group('integration', () {
      /// PROVES: Widget displays data from configuration correctly
      /// FAILURE MODE: Would catch data binding bugs
      testWidgets('displays configured data correctly', (tester) async {
        // Use distinctive values that are traceable
        const configValue = 12345.67;
        const configLabel = 'INTEGRATION_TEST_LABEL';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeatureWidget(
                config: FeatureConfig(
                  label: configLabel,
                  value: configValue,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify configuration flows to display
        expect(find.text(configLabel), findsOneWidget);
        expect(find.textContaining('12345'), findsOneWidget);
      });

      /// PROVES: Widget updates when data changes
      /// FAILURE MODE: Would catch reactive update bugs
      testWidgets('updates display when data changes', (tester) async {
        final valueNotifier = ValueNotifier<String>('Initial');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<String>(
                valueListenable: valueNotifier,
                builder: (context, value, _) => FeatureWidget(label: value),
              ),
            ),
          ),
        );

        // Initial state
        expect(find.text('Initial'), findsOneWidget);

        // Update data
        valueNotifier.value = 'Updated';
        await tester.pumpAndSettle();

        // Verify update
        expect(find.text('Initial'), findsNothing);
        expect(find.text('Updated'), findsOneWidget);
      });
    });

    // ========================================================================
    // Golden Tests (for Canvas-rendered content)
    // ========================================================================

    group('golden', () {
      /// PROVES: Visual output matches expected reference
      /// FAILURE MODE: Would catch any visual regression
      testWidgets('matches golden: default configuration', (tester) async {
        // Set deterministic size
        tester.view.physicalSize = const Size(800, 400);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(), // Deterministic theme
            home: Scaffold(
              body: FeatureWidget(
                // Use fixed configuration for reproducibility
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(FeatureWidget),
          matchesGoldenFile('goldens/feature_default_800x400.png'),
        );
      });

      /// Update goldens with: flutter test --update-goldens [this_file]
      testWidgets('matches golden: complex configuration', (tester) async {
        tester.view.physicalSize = const Size(1200, 600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Scaffold(
              body: FeatureWidget(
                elements: [
                  ElementConfig(id: 'a'),
                  ElementConfig(id: 'b'),
                  ElementConfig(id: 'c'),
                  ElementConfig(id: 'd'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(FeatureWidget),
          matchesGoldenFile('goldens/feature_complex_1200x600.png'),
        );
      });
    });

    // ========================================================================
    // Edge Cases
    // ========================================================================

    group('edge cases', () {
      /// PROVES: Widget handles empty data gracefully
      /// FAILURE MODE: Would catch null pointer exceptions
      testWidgets('handles empty configuration', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeatureWidget(
                elements: [], // Empty
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(FeatureWidget), findsOneWidget);
        // Should show empty state indicator
        expect(find.text('No data'), findsOneWidget);
      });

      /// PROVES: Widget handles null optional values
      /// FAILURE MODE: Would catch null safety issues
      testWidgets('handles null optional values', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeatureWidget(
                optionalLabel: null, // Explicitly null
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(FeatureWidget), findsOneWidget);
      });
    });
  });
}

// ============================================================================
// TEST HELPERS
// ============================================================================

/// Creates a standard test widget wrapper
Widget createTestWidget({required Widget child}) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

// ============================================================================
// ASSERTION PATTERNS REFERENCE
// ============================================================================
//
// ❌ BANNED - Tests nothing meaningful:
//    expect(find.byType(Widget), findsOneWidget);
//
// ✅ REQUIRED - Tests specific behavior:
//    expect(find.text('Specific Text'), findsOneWidget);
//    expect(find.textContaining('partial'), findsWidgets);
//    expect(tester.getRect(finder).left, lessThan(100));
//    await expectLater(finder, matchesGoldenFile('golden.png'));
//
// ============================================================================
