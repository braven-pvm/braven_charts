# Tasks: Theming System

**Branch**: `004-theming-system`  
**Input**: Design documents from `/specs/004-theming-system/`  
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

---

## Execution Flow

```
1. Load plan.md from feature directory
   ✓ Loaded: Dart 3.10.0, Flutter 3.37.0, pure Flutter (no packages)
   ✓ Structure: Single Flutter library, lib/src/theming/
   ✓ Tech: Immutable patterns, LRU cache, WCAG 2.1, JSON serialization
2. Load optional design documents:
   ✓ data-model.md: 9 entities extracted
   ✓ contracts/: 8 contract files identified
   ✓ research.md: 8 design decisions documented
   ✓ quickstart.md: 5 executable test scenarios
3. Generate tasks by category:
   ✓ Phase 0: Contract tests (8 tasks, all [P], MUST FAIL)
   ✓ Phase 1: Core data structures (9 tasks)
   ✓ Phase 2: Predefined themes (10 tasks, 7 themes + 3 validation)
   ✓ Phase 3: Theme builder (3 tasks)
   ✓ Phase 4: Utilities (6 tasks)
   ✓ Phase 5: Integration (5 tasks)
   ✓ Phase 6: Performance & docs (7 tasks)
4. Apply task rules:
   ✓ Different files = mark [P] for parallel
   ✓ Same file = sequential (no [P])
   ✓ Tests before implementation (TDD)
5. Number tasks: T001-T048 (48 tasks total)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   ✓ All 8 contracts have tests
   ✓ All 9 entities have implementation tasks
   ✓ All 5 quickstart scenarios validated
9. Return: SUCCESS (tasks ready for execution)
```

---

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in task descriptions

---

## Path Conventions

This is a **single Flutter library** project:
- **Source**: `lib/src/theming/`
- **Tests**: `test/`
- **Contracts**: `specs/004-theming-system/contracts/`

---

## Phase 0: Contract Tests (TDD Foundation)

**CRITICAL**: These tests MUST be written and MUST FAIL before ANY implementation in Phase 1.

**Purpose**: Define the contract (API) for all theming components through tests that specify expected behavior.

- [x] **T001** [P] Contract test for ChartTheme in `test/contract/theming/chart_theme_contract_test.dart`
  - Test 7 predefined themes exist (defaultLight, defaultDark, corporateBlue, vibrant, minimal, highContrast, colorblindFriendly)
  - Test copyWith() preserves unchanged fields
  - Test toJson() / fromJson() round-trip
  - Test equality operator and hashCode
  - **MUST FAIL**: ChartTheme class not implemented yet

- [x] **T002** [P] Contract test for GridStyle in `test/contract/theming/grid_style_contract_test.dart`
  - Test major grid configuration (color, width, dash pattern)
  - Test optional minor grid (showMinor flag)
  - Test 7 predefined styles
  - Test validation (widths >= 0, dash pattern format)
  - **MUST FAIL**: GridStyle class not implemented yet

- [x] **T003** [P] Contract test for AxisStyle in `test/contract/theming/axis_style_contract_test.dart`
  - Test axis line styling
  - Test text styles (labels and titles)
  - Test tick mark configuration
  - Test 7 predefined styles
  - **MUST FAIL**: AxisStyle class not implemented yet

- [x] **T004** [P] Contract test for SeriesTheme in `test/contract/theming/series_theme_contract_test.dart`
  - Test cycling behavior: colorAt(index), lineWidthAt(index), etc.
  - Test MarkerShape enum values
  - Test 7 predefined themes
  - Test validation (all lists length >= 1)
  - **MUST FAIL**: SeriesTheme class not implemented yet

- [x] **T005** [P] Contract test for InteractionTheme in `test/contract/theming/interaction_theme_contract_test.dart`
  - Test crosshair styling
  - Test tooltip styling
  - Test selection styling
  - Test 7 predefined themes
  - **MUST FAIL**: InteractionTheme class not implemented yet

- [x] **T006** [P] Contract test for TypographyTheme in `test/contract/theming/typography_theme_contract_test.dart`
  - Test font configuration
  - Test responsive scaling: computeScaleFactor(), withScaleFactor()
  - Test effective sizes with scale factor applied
  - Test 7 predefined themes
  - **MUST FAIL**: TypographyTheme class not implemented yet

- [x] **T007** [P] Contract test for AnimationTheme in `test/contract/theming/animation_theme_contract_test.dart`
  - Test duration and curve configuration
  - Test 7 predefined themes
  - Test serialization (curve names)
  - **MUST FAIL**: AnimationTheme class not implemented yet

- [x] **T008** [P] Contract test for ColorUtils in `test/contract/theming/color_utils_contract_test.dart`
  - Test WCAG 2.1 contrast ratio calculation (known test cases)
  - Test isWCAG_AA(), isWCAG_AAA() helpers
  - Test autoContrastText() (white background → black text, etc.)
  - Test colorblind simulation (known color transformations)
  - Test grayscale conversion
  - Test color distance (ΔE)
  - **MUST FAIL**: ColorUtils class not implemented yet

**Dependencies**: None (all tasks can run in parallel)  
**Verification**: Run `flutter test test/contract/theming/` - all 8 tests MUST FAIL

---

## Phase 1: Core Data Structures

**Purpose**: Implement the 9 core entities with immutability, serialization, and validation.

**GATE**: T001-T008 must be complete and failing before starting Phase 1.

- [x] **T009** [P] Implement GridStyle in `lib/src/theming/components/grid_style.dart`
  - Immutable class with const constructor
  - 7 predefined styles (defaultLight, defaultDark, corporateBlue, vibrant, minimal, highContrast, colorblindFriendly)
  - copyWith() method
  - toJson() / fromJson() with color parsing
  - Equality operator and hashCode
  - Validation: widths >= 0, dash pattern validation
  - **VERIFY**: T002 contract test now passes

- [x] **T010** [P] Implement AxisStyle in `lib/src/theming/components/axis_style.dart`
  - Immutable class with const constructor
  - 7 predefined styles
  - copyWith() method
  - toJson() / fromJson() with TextStyle serialization
  - Equality operator and hashCode
  - Validation: widths >= 0, font sizes >= minimums
  - **VERIFY**: T003 contract test now passes

- [x] **T011** [P] Implement SeriesTheme in `lib/src/theming/components/series_theme.dart`
  - Immutable class with const constructor
  - MarkerShape enum (circle, square, triangle, diamond, cross, plus, star, none)
  - 7 predefined themes
  - Cycling accessors: colorAt(), lineWidthAt(), dashPatternAt(), markerShapeAt(), markerSizeAt()
  - copyWith() method
  - toJson() / fromJson()
  - Equality operator and hashCode
  - Validation: all lists length >= 1
  - **VERIFY**: T004 contract test now passes

- [x] **T012** [P] Implement InteractionTheme in `lib/src/theming/components/interaction_theme.dart`
  - Immutable class with const constructor
  - 7 predefined themes
  - copyWith() method
  - toJson() / fromJson()
  - Equality operator and hashCode
  - Validation: widths >= 0, opacity 0.0-1.0
  - **VERIFY**: T005 contract test now passes

- [x] **T013** [P] Implement TypographyTheme in `lib/src/theming/components/typography_theme.dart`
  - Immutable class with const constructor
  - 7 predefined themes
  - Breakpoint constants: mobileBreakpoint (600), desktopBreakpoint (1024)
  - computeScaleFactor(viewportWidth) static method
  - withScaleFactor(factor) instance method
  - Effective size getters: effectiveBaseFontSize, effectiveTitleFontSize, effectiveLabelFontSize
  - copyWith() method
  - toJson() / fromJson() with FontWeight parsing
  - Equality operator and hashCode
  - Validation: font sizes >= minimums, scaleFactor 0.5-2.0
  - **VERIFY**: T006 contract test now passes

- [x] **T014** [P] Implement AnimationTheme in `lib/src/theming/components/animation_theme.dart`
  - Immutable class with const constructor
  - 7 predefined themes
  - copyWith() method
  - toJson() / fromJson() with Curve serialization
  - Equality operator and hashCode
  - **VERIFY**: T007 contract test now passes

- [x] **T015** [P] Implement ColorUtils in `lib/src/theming/utilities/color_utils.dart`
  - Static utility class (private constructor)
  - relativeLuminance(Color) - WCAG 2.1 spec
  - contrastRatio(Color, Color) - WCAG 2.1 spec
  - isWCAG_AA(), isWCAG_AA_Large(), isWCAG_AAA(), isWCAG_AAA_Large()
  - autoContrastText(Color) - returns black or white
  - simulateProtanopia(), simulateDeuteranopia(), simulateTritanopia() - Brettel algorithm
  - toGrayscale(Color)
  - colorDistance(Color, Color) - ΔE in CIELAB
  - **VERIFY**: T008 contract test now passes

- [x] **T016** Implement ChartTheme in `lib/src/theming/chart_theme.dart`
  - Immutable class with const constructor
  - 7 predefined themes (each references component predefined themes)
  - copyWith() method (all 10 fields)
  - toJson() / fromJson() (version 1.0 schema)
  - Equality operator and hashCode
  - Validation: borderWidth >= 0
  - **VERIFY**: T001 contract test now passes
  - **DEPENDS ON**: T009-T015 (imports all component themes)

- [x] **T017** Create barrel file `lib/src/theming/theming.dart`
  - Export chart_theme.dart
  - Export all component files (grid_style, axis_style, series_theme, interaction_theme, typography_theme, animation_theme)
  - Export color_utils.dart
  - Add library-level documentation
  - **DEPENDS ON**: T009-T016

**Dependencies**: 
- T009-T015 can run in parallel (independent files)
- T016 depends on T009-T015 (imports all components)
- T017 depends on T009-T016 (exports all)

**Verification**: Run `flutter test test/contract/theming/` - all 8 tests MUST PASS

---

## Phase 2: Predefined Themes & Validation

**Purpose**: Implement all 7 predefined themes and validate accessibility compliance.

**GATE**: T001-T017 must be complete and all contract tests passing.

- [x] **T018** [P] Validate Default Light theme in `test/accessibility/theming/default_light_wcag_test.dart`
  - Test background/text contrast >= 4.5:1 (WCAG AA)
  - Test tooltip background/text contrast >= 4.5:1
  - Test all series colors distinguishable (ΔE > 40)
  - **DEPENDS ON**: T016

- [x] **T019** [P] Validate Default Dark theme in `test/accessibility/theming/default_dark_wcag_test.dart`
  - Test background/text contrast >= 4.5:1 (WCAG AA)
  - Test tooltip background/text contrast >= 4.5:1
  - Test all series colors distinguishable (ΔE > 40)
  - **DEPENDS ON**: T016

- [x] **T020** [P] Validate Corporate Blue theme in `test/accessibility/theming/corporate_blue_wcag_test.dart`
  - Test background/text contrast >= 4.5:1 (WCAG AA)
  - Test blue color palette (5+ shades)
  - **DEPENDS ON**: T016

- [x] **T021** [P] Validate Vibrant theme in `test/accessibility/theming/vibrant_wcag_test.dart`
  - Test background/text contrast >= 4.5:1 (WCAG AA)
  - Test high saturation colors
  - **DEPENDS ON**: T016

- [x] **T022** [P] Validate Minimal theme in `test/accessibility/theming/minimal_wcag_test.dart`
  - Test background/text contrast >= 4.5:1 (WCAG AA)
  - Test subtle gray palette
  - **DEPENDS ON**: T016

- [x] **T023** [P] Validate High Contrast theme in `test/accessibility/theming/high_contrast_wcag_test.dart`
  - Test background/text contrast >= 7.0:1 (WCAG AAA)
  - Test tooltip background/text contrast >= 7.0:1
  - Test all text meets AAA standard
  - **DEPENDS ON**: T016

- [x] **T024** [P] Validate Colorblind Friendly theme in `test/accessibility/theming/colorblind_friendly_test.dart`
  - Simulate protanopia: verify series distinguishable (ΔE > 40)
  - Simulate deuteranopia: verify series distinguishable (ΔE > 40)
  - Simulate tritanopia: verify series distinguishable (ΔE > 40)
  - Test grayscale: verify series separable by shape/pattern
  - **DEPENDS ON**: T016

- [x] **T025** [P] Create theme constants in `lib/src/theming/constants/theme_constants.dart`
  - Define color palettes (corporateBlue, vibrant, colorblindSafe)
  - Define breakpoint constants (mobile, tablet, desktop)
  - Define validation minimums (minFontSize, minLineWidth)
  - Add documentation for each palette
  - **DEPENDS ON**: T016

- [ ] **T026** [P] Create predefined themes showcase in `lib/src/theming/themes/predefined_themes.dart`
  - Re-export all 7 themes from ChartTheme
  - Add usage examples in documentation
  - Create comparison table in docs
  - **DEPENDS ON**: T016

- [ ] **T027** Update unit tests in `test/unit/theming/theme_equality_test.dart`
  - Test theme equality across all 7 themes
  - Test hashCode consistency
  - Test copyWith() creates new instance
  - Test toJson() produces expected structure
  - **DEPENDS ON**: T016

**Dependencies**: All tasks depend on T016 (ChartTheme implementation)

**Verification**: Run `flutter test test/accessibility/theming/` - all tests MUST PASS

---

## Phase 3: Theme Builder

**Purpose**: Create fluent builder API for custom theme creation.

**GATE**: T018-T027 must be complete.

- [ ] **T028** Implement ChartThemeBuilder in `lib/src/theming/builder/chart_theme_builder.dart`
  - Default constructor (starts from defaults)
  - from(ChartTheme) constructor (starts from existing theme)
  - Fluent setters for all 10 fields (return this)
  - Private validation method
  - build() method with validation
  - **DEPENDS ON**: T016

- [ ] **T029** Create builder validation tests in `test/unit/theming/theme_builder_validation_test.dart`
  - Test negative borderWidth throws
  - Test empty seriesColors throws
  - Test invalid scaleFactor throws
  - Test all validations from data-model.md
  - **DEPENDS ON**: T028

- [ ] **T030** Create builder usage tests in `test/unit/theming/theme_builder_usage_test.dart`
  - Test minimal customization (1-2 fields)
  - Test starting from predefined theme
  - Test complex customization (all fields)
  - Test method chaining
  - **DEPENDS ON**: T028

**Dependencies**: T028 → T029, T030

**Verification**: Run `flutter test test/unit/theming/theme_builder*` - all tests MUST PASS

---

## Phase 4: Utilities

**Purpose**: Implement caching, serialization helpers, and additional utilities.

**GATE**: T028-T030 must be complete.

- [ ] **T031** [P] Implement StyleCache in `lib/src/theming/utilities/style_cache.dart`
  - StyleCacheKey class (themeHash, elementType, overridesHash)
  - StyleCache class with LinkedHashMap
  - LRU eviction (maxSize = 1000)
  - get<T>(), put<T>(), clear() methods
  - Hit rate tracking (hits / (hits + misses))
  - size getter
  - **DEPENDS ON**: T017

- [ ] **T032** [P] Create cache tests in `test/unit/theming/style_cache_test.dart`
  - Test LRU eviction (add 1001 items, verify oldest removed)
  - Test hit rate calculation
  - Test get() moves item to end
  - Test clear() empties cache
  - Test cache miss returns null
  - **DEPENDS ON**: T031

- [ ] **T033** [P] Create serialization helpers in `lib/src/theming/utilities/serialization_helpers.dart`
  - parseColor(String) helper
  - colorToHex(Color) helper
  - parseEdgeInsets(Map) helper
  - edgeInsetsToJson(EdgeInsets) helper
  - Add error handling and null safety
  - **DEPENDS ON**: T017

- [ ] **T034** [P] Create serialization tests in `test/unit/theming/serialization_test.dart`
  - Test valid color parsing (#AARRGGBB)
  - Test invalid color formats return null
  - Test EdgeInsets round-trip
  - Test null handling
  - **DEPENDS ON**: T033

- [ ] **T035** [P] Create theme versioning in `lib/src/theming/utilities/theme_version.dart`
  - ThemeVersion class (major, minor, patch)
  - fromString() parser
  - toString() formatter
  - isCompatible(ThemeVersion) checker
  - currentVersion constant (1.0.0)
  - **DEPENDS ON**: T017

- [ ] **T036** [P] Create versioning tests in `test/unit/theming/theme_version_test.dart`
  - Test version parsing (1.0.0, 1.2.3)
  - Test compatibility checks (1.0 compatible with 1.1, not with 2.0)
  - Test toString() format
  - Test invalid version formats
  - **DEPENDS ON**: T035

**Dependencies**: All tasks can run in parallel (independent files)

**Verification**: Run `flutter test test/unit/theming/` - all tests MUST PASS

---

## Phase 5: Integration

**Purpose**: Integrate theming with Core Rendering Engine and Coordinate System.

**GATE**: T031-T036 must be complete.

- [ ] **T037** Create ThemeChangeSet in `lib/src/theming/utilities/theme_change_set.dart`
  - Factory constructor compute(oldTheme, newTheme)
  - Boolean fields for each component (backgroundChanged, gridStyleChanged, etc.)
  - anyChanged getter
  - **DEPENDS ON**: T016

- [ ] **T038** Create theme diffing tests in `test/unit/theming/theme_diffing_test.dart`
  - Test no changes returns all false
  - Test single component change detected
  - Test multiple component changes detected
  - Test anyChanged getter
  - **DEPENDS ON**: T037

- [ ] **T039** Create RenderContext extension in `lib/src/theming/extensions/render_context_theme_extension.dart`
  - applyTheme(ChartTheme) method
  - updateTheme(ChartTheme) with diffing
  - currentTheme getter
  - Private cache instance
  - **DEPENDS ON**: T037, T031 (StyleCache)

- [ ] **T040** Create integration tests in `test/integration/theming/theme_switching_test.dart`
  - Test theme application (apply defaultLight)
  - Test theme switching preserves state (zoom, pan)
  - Test partial re-render (only changed components)
  - Test cache invalidation on theme change
  - **DEPENDS ON**: T039

- [ ] **T041** Create responsive typography integration in `test/integration/theming/responsive_typography_test.dart`
  - Test mobile viewport (400px): 0.9x scale factor
  - Test tablet viewport (800px): 1.0x scale factor
  - Test desktop viewport (1920px): 1.1x scale factor
  - Test minimum font size enforcement
  - **DEPENDS ON**: T013 (TypographyTheme)

**Dependencies**: T037 → T038, T039 → T040

**Verification**: Run `flutter test test/integration/theming/` - all tests MUST PASS

---

## Phase 6: Performance & Documentation

**Purpose**: Validate performance targets and complete documentation.

**GATE**: T037-T041 must be complete.

- [ ] **T042** [P] Create theme switching benchmark in `test/benchmarks/theming/theme_switching_benchmark.dart`
  - Measure theme switch time (target: <100ms)
  - Measure with/without cache
  - Test on various theme pairs (similar vs different)
  - Generate performance report
  - **DEPENDS ON**: T039

- [ ] **T043** [P] Create style cache benchmark in `test/benchmarks/theming/style_cache_benchmark.dart`
  - Measure cache hit rate (target: >95%)
  - Measure lookup time (target: <0.1ms)
  - Test with realistic rendering patterns
  - Generate performance report
  - **DEPENDS ON**: T031

- [ ] **T044** [P] Add Dartdoc to all public APIs in `lib/src/theming/**/*.dart`
  - Document all public classes
  - Document all public methods
  - Add code examples to complex APIs
  - Document all parameters and return values
  - **DEPENDS ON**: T017

- [ ] **T045** [P] Create usage guide in `docs/guides/theming-usage.md`
  - Quick start with predefined themes
  - Custom theme creation with builder
  - Theme switching best practices
  - Accessibility guidelines
  - Performance tips
  - **DEPENDS ON**: T028

- [ ] **T046** [P] Create accessibility guide in `docs/guides/theming-accessibility.md`
  - WCAG 2.1 compliance overview
  - How to verify contrast ratios
  - Colorblind-friendly design patterns
  - Testing for accessibility
  - **DEPENDS ON**: T015 (ColorUtils)

- [ ] **T047** [P] Execute quickstart examples in `specs/004-theming-system/quickstart.md`
  - Run Example 1: Apply predefined theme
  - Run Example 2: Switch theme <100ms
  - Run Example 3: Build custom theme
  - Run Example 4: Verify WCAG AAA contrast
  - Run Example 5: JSON serialization round-trip
  - All examples MUST PASS
  - **DEPENDS ON**: T028, T039

- [ ] **T048** Final validation and cleanup
  - Run all tests: `flutter test`
  - Verify code coverage >90%
  - Run dartanalyzer with zero warnings
  - Run dartfmt on all files
  - Update CHANGELOG.md
  - Update README.md with theming examples
  - **DEPENDS ON**: T001-T047 (all tasks)

**Dependencies**: All tasks can run in parallel except T048 (depends on everything)

**Verification**: 
- `flutter test test/benchmarks/theming/` - benchmarks meet targets
- `flutter test` - all 100% tests passing
- `dart analyze` - zero issues

---

## Task Dependencies Graph

```
Phase 0: Contract Tests (T001-T008)
  ├─ All tasks [P] (parallel)
  └─ All MUST FAIL initially

Phase 1: Core Structures (T009-T017)
  ├─ T009-T015 [P] (parallel)
  ├─ T016 ← depends on T009-T015
  └─ T017 ← depends on T009-T016

Phase 2: Predefined Themes (T018-T027)
  ├─ T018-T024 [P] ← all depend on T016
  ├─ T025 [P] ← depends on T016
  ├─ T026 [P] ← depends on T016
  └─ T027 [P] ← depends on T016

Phase 3: Theme Builder (T028-T030)
  ├─ T028 ← depends on T016
  ├─ T029 ← depends on T028
  └─ T030 ← depends on T028

Phase 4: Utilities (T031-T036)
  ├─ T031 [P] ← depends on T017
  ├─ T032 [P] ← depends on T031
  ├─ T033 [P] ← depends on T017
  ├─ T034 [P] ← depends on T033
  ├─ T035 [P] ← depends on T017
  └─ T036 [P] ← depends on T035

Phase 5: Integration (T037-T041)
  ├─ T037 ← depends on T016
  ├─ T038 ← depends on T037
  ├─ T039 ← depends on T037, T031
  ├─ T040 ← depends on T039
  └─ T041 ← depends on T013

Phase 6: Performance & Docs (T042-T048)
  ├─ T042 [P] ← depends on T039
  ├─ T043 [P] ← depends on T031
  ├─ T044 [P] ← depends on T017
  ├─ T045 [P] ← depends on T028
  ├─ T046 [P] ← depends on T015
  ├─ T047 [P] ← depends on T028, T039
  └─ T048 ← depends on T001-T047
```

---

## Parallel Execution Examples

### Phase 0: Launch all contract tests together
```bash
# All 8 contract tests can run in parallel (different files, no dependencies)
flutter test test/contract/theming/chart_theme_contract_test.dart &
flutter test test/contract/theming/grid_style_contract_test.dart &
flutter test test/contract/theming/axis_style_contract_test.dart &
flutter test test/contract/theming/series_theme_contract_test.dart &
flutter test test/contract/theming/interaction_theme_contract_test.dart &
flutter test test/contract/theming/typography_theme_contract_test.dart &
flutter test test/contract/theming/animation_theme_contract_test.dart &
flutter test test/contract/theming/color_utils_contract_test.dart &
wait
# Expected: All tests FAIL (not implemented yet)
```

### Phase 1: Implement component themes in parallel
```bash
# T009-T015 can run in parallel (independent files)
# Example using Task agents (if available):
Task: "Implement GridStyle in lib/src/theming/components/grid_style.dart"
Task: "Implement AxisStyle in lib/src/theming/components/axis_style.dart"
Task: "Implement SeriesTheme in lib/src/theming/components/series_theme.dart"
Task: "Implement InteractionTheme in lib/src/theming/components/interaction_theme.dart"
Task: "Implement TypographyTheme in lib/src/theming/components/typography_theme.dart"
Task: "Implement AnimationTheme in lib/src/theming/components/animation_theme.dart"
Task: "Implement ColorUtils in lib/src/theming/utilities/color_utils.dart"
```

### Phase 2: Validate all themes in parallel
```bash
# T018-T027 can run in parallel (all depend on T016 but are independent of each other)
flutter test test/accessibility/theming/default_light_wcag_test.dart &
flutter test test/accessibility/theming/default_dark_wcag_test.dart &
flutter test test/accessibility/theming/corporate_blue_wcag_test.dart &
flutter test test/accessibility/theming/vibrant_wcag_test.dart &
flutter test test/accessibility/theming/minimal_wcag_test.dart &
flutter test test/accessibility/theming/high_contrast_wcag_test.dart &
flutter test test/accessibility/theming/colorblind_friendly_test.dart &
wait
# Expected: All tests PASS
```

### Phase 4: Create utilities in parallel
```bash
# T031, T033, T035 can run in parallel (independent files)
Task: "Implement StyleCache in lib/src/theming/utilities/style_cache.dart"
Task: "Create serialization helpers in lib/src/theming/utilities/serialization_helpers.dart"
Task: "Create theme versioning in lib/src/theming/utilities/theme_version.dart"
```

---

## Validation Checklist

**Pre-Execution**:
- [x] All 8 contracts have corresponding tests (T001-T008)
- [x] All 9 entities have implementation tasks (T009-T016 + utilities)
- [x] All tests come before implementation (Phase 0 before Phase 1)
- [x] Parallel tasks truly independent (verified file paths)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task

**Post-Execution** (after T048):
- [ ] All contract tests passing (T001-T008 verification)
- [ ] All accessibility tests passing (T018-T024)
- [ ] All builder tests passing (T029-T030)
- [ ] All utility tests passing (T032, T034, T036, T038, T040, T041)
- [ ] All benchmarks meet targets (T042: <100ms, T043: >95% hit rate)
- [ ] All quickstart examples passing (T047)
- [ ] Code coverage >90%
- [ ] Zero analyzer warnings
- [ ] Documentation complete

---

## Notes

1. **TDD Workflow**: 
   - Phase 0 creates failing tests
   - Phase 1 makes tests pass
   - Never implement without a failing test first

2. **Parallel Execution**:
   - [P] tasks can run simultaneously (different files)
   - Sequential tasks modify same file or have dependencies
   - Use `&` in bash or Task agents for parallel execution

3. **Performance Targets**:
   - Theme switching: <100ms (T042)
   - Cache hit rate: >95% (T043)
   - Style resolution: <0.1ms per lookup

4. **Accessibility Requirements**:
   - All themes: WCAG 2.1 AA (4.5:1 contrast)
   - High Contrast: WCAG 2.1 AAA (7:1 contrast)
   - Colorblind Friendly: Tested with Brettel simulation

5. **File Organization**:
   ```
   lib/src/theming/
   ├── chart_theme.dart (T016)
   ├── theming.dart (T017, barrel file)
   ├── components/
   │   ├── grid_style.dart (T009)
   │   ├── axis_style.dart (T010)
   │   ├── series_theme.dart (T011)
   │   ├── interaction_theme.dart (T012)
   │   ├── typography_theme.dart (T013)
   │   └── animation_theme.dart (T014)
   ├── builder/
   │   └── chart_theme_builder.dart (T028)
   ├── themes/
   │   └── predefined_themes.dart (T026)
   ├── utilities/
   │   ├── color_utils.dart (T015)
   │   ├── style_cache.dart (T031)
   │   ├── serialization_helpers.dart (T033)
   │   ├── theme_version.dart (T035)
   │   └── theme_change_set.dart (T037)
   ├── extensions/
   │   └── render_context_theme_extension.dart (T039)
   └── constants/
       └── theme_constants.dart (T025)
   ```

6. **Commit Strategy**:
   - Commit after each task completion
   - Run tests before each commit
   - Use descriptive commit messages referencing task number

7. **Manual Testing**:
   - After T047, manually verify theme switching in example app
   - Test responsive typography at different viewport sizes
   - Verify accessibility with screen readers (if applicable)

---

**TASKS GENERATION COMPLETE**: 48 tasks generated, ready for execution  
**Estimated Completion**: ~8-12 hours (depending on parallel execution capability)  
**Next Command**: Begin with `/implement T001` or run Phase 0 tests in parallel
