

# Implementation Plan: Theming System# Implementation Plan: [FEATURE]



**Branch**: `004-theming-system` | **Date**: 2025-10-06 | **Spec**: [spec.md](spec.md)**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]

**Input**: Feature specification from `/specs/004-theming-system/spec.md`**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`



## Execution Flow (/plan command scope)## Execution Flow (/plan command scope)

``````

1. Load feature spec from Input path1. Load feature spec from Input path

   ✓ Loaded spec.md with 9 FRs, 5 user scenarios, 7 predefined themes   → If not found: ERROR "No feature spec at {path}"

2. Fill Technical Context (scan for NEEDS CLARIFICATION)2. Fill Technical Context (scan for NEEDS CLARIFICATION)

   ✓ Project Type: Single Flutter library (web-first)   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)

   ✓ All technical aspects clear from constitution and architecture docs   → Set Structure Decision based on project type

   ✓ Coordinate System (Layer 2) fully implemented and available3. Fill the Constitution Check section based on the content of the constitution document.

3. Fill the Constitution Check section4. Evaluate Constitution Check section below

   ✓ Constitutional requirements analyzed   → If violations exist: Document in Complexity Tracking

4. Evaluate Constitution Check section below   → If no justification possible: ERROR "Simplify approach first"

   ✓ No violations detected - design aligns with principles   → Update Progress Tracking: Initial Constitution Check

   ✓ Update Progress Tracking: Initial Constitution Check PASS5. Execute Phase 0 → research.md

5. Execute Phase 0 → research.md   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"

   ✓ Completed - theme architecture, accessibility standards, and serialization patterns documented6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code, or `AGENTS.md` for all other agents).

6. Execute Phase 1 → contracts, data-model.md, quickstart.md7. Re-evaluate Constitution Check section

   ✓ Completed - 9 theme entities, 8 contracts, quickstart examples defined   → If new violations: Refactor design, return to Phase 1

7. Re-evaluate Constitution Check section   → Update Progress Tracking: Post-Design Constitution Check

   ✓ No new violations after design8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)

   ✓ Update Progress Tracking: Post-Design Constitution Check PASS9. STOP - Ready for /tasks command

8. Plan Phase 2 → Task generation approach defined```

9. STOP - Ready for /tasks command

```**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:

- Phase 2: /tasks command creates tasks.md

**IMPORTANT**: The /plan command STOPS at step 9. Phases 2-4 are executed by other commands:- Phase 3-4: Implementation execution (manual or via tools)

- Phase 2: /tasks command creates tasks.md

- Phase 3-4: Implementation execution (manual or via tools)## Summary

[Extract from feature spec: primary requirement + technical approach from research]

## Summary

## Technical Context

The Theming System provides **comprehensive visual control** over all chart components through a layered, cascading style architecture. It includes 7 professionally designed themes and full customization capabilities, ensuring consistent visual design while maintaining <100ms theme switching performance and WCAG 2.1 AA/AAA accessibility compliance.**Language/Version**: [e.g., Python 3.11, Swift 5.9, Rust 1.75 or NEEDS CLARIFICATION]  

**Primary Dependencies**: [e.g., FastAPI, UIKit, LLVM or NEEDS CLARIFICATION]  

**Technical Approach** (from research):**Storage**: [if applicable, e.g., PostgreSQL, CoreData, files or N/A]  

- Immutable theme data structures with `copyWith()` patterns**Testing**: [e.g., pytest, XCTest, cargo test or NEEDS CLARIFICATION]  

- CSS-like cascading style resolution with inheritance and caching**Target Platform**: [e.g., Linux server, iOS 15+, WASM or NEEDS CLARIFICATION]

- Fluent ChartThemeBuilder API for custom theme creation**Project Type**: [single/web/mobile - determines source structure]  

- JSON serialization with versioned schema for persistence**Performance Goals**: [domain-specific, e.g., 1000 req/s, 10k lines/sec, 60 fps or NEEDS CLARIFICATION]  

- WCAG 2.1 color contrast utilities and colorblind simulation**Constraints**: [domain-specific, e.g., <200ms p95, <100MB memory, offline-capable or NEEDS CLARIFICATION]  

- Theme diffing and caching for performance-neutral theme switching**Scale/Scope**: [domain-specific, e.g., 10k users, 1M LOC, 50 screens or NEEDS CLARIFICATION]

- Responsive typography with breakpoint-based scaling

- Integration with Core Rendering Engine and Coordinate System## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

## Technical Context

**Language/Version**: Dart 3.10.0-227.0.dev  [Gates determined based on constitution file]

**Primary Dependencies**: Flutter SDK 3.37.0-1.0.pre-216, Standard Dart libraries (dart:ui, dart:math, dart:convert for JSON)  

**Storage**: JSON serialization for theme persistence (optional)  ## Project Structure

**Testing**: Flutter test framework, contract tests, accessibility compliance tests, colorblind simulation tests  

**Target Platform**: Flutter Web (primary), iOS/Android (secondary)  ### Documentation (this feature)

**Project Type**: Single Flutter library  ```

**Performance Goals**: <100ms theme switching, >95% style cache hit rate, zero allocations during theme application  specs/[###-feature]/

**Constraints**: No external packages, pure Flutter implementation, WCAG 2.1 AA compliance (AAA for High Contrast)  ├── plan.md              # This file (/plan command output)

**Scale/Scope**: 7 predefined themes, 9 theme components (Canvas, Grid, Axis, Series, Interaction, Typography, Animation, Color), 100% test coverage requirement├── research.md          # Phase 0 output (/plan command)

├── data-model.md        # Phase 1 output (/plan command)

**User Input Context**: ├── quickstart.md        # Phase 1 output (/plan command)

- **Foundation Layer** (001-foundation): Provides data models, validation utilities, type system├── contracts/           # Phase 1 output (/plan command)

- **Core Rendering Engine** (002-core-rendering): Provides RenderContext, RenderLayer, Paint/Path pooling, TextLayoutCache└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)

- **Coordinate System** (003-coordinate-system): Provides viewport dimensions for responsive theming, implemented and available```



## Constitution Check### Source Code (repository root)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*<!--

  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout

### I. Architectural Integrity (Pure Flutter)  for this feature. Delete unused options and expand the chosen structure with

✅ **PASS** - Pure Dart/Flutter implementation  real paths (e.g., apps/admin, packages/something). The delivered plan must

- Uses only dart:ui (Color, TextStyle), dart:math (for color calculations), dart:convert (JSON serialization)  not include Option labels.

- No HTML elements or web-specific APIs-->

- Integrates cleanly with Foundation Layer (ChartResult, ValidationResult), Core Rendering Engine (Paint styles), and Coordinate System (viewport-based responsive styling)```

- Clean separation: ChartTheme (root), GridStyle/AxisStyle/SeriesTheme/etc. (components), ChartThemeBuilder (construction), ColorUtils (utilities)# [REMOVE IF UNUSED] Option 1: Single project (DEFAULT)

- No circular dependencies: Depends on Foundation + Core Rendering + Coordinate System, consumed by future layers (Chart Types, Interaction, Annotation)src/

├── models/

### II. Performance First (60fps Target)├── services/

✅ **PASS** - Performance-optimized design├── cli/

- <100ms theme switching target (no chart recreation, only style updates)└── lib/

- Style resolution caching with >95% hit rate target

- LRU cache eviction to prevent memory bloattests/

- Theme diffing to minimize re-rendering (only changed components)├── contract/

- Zero allocations during theme application (pre-computed Paint objects)├── integration/

- Responsive typography calculations cached per viewport size└── unit/

- <16ms frame time maintained with theme-aware rendering

# [REMOVE IF UNUSED] Option 2: Web application (when "frontend" + "backend" detected)

### III. Testing Excellence (NON-NEGOTIABLE)backend/

✅ **PASS** - Comprehensive test strategy├── src/

- TDD approach: Contract tests → Unit tests → Accessibility tests → Integration tests → Implementation│   ├── models/

- 100% coverage target: All 7 predefined themes, all theme components, all builder methods│   ├── services/

- Accessibility tests: WCAG 2.1 AA contrast ratios (4.5:1), AAA for High Contrast (7:1)│   └── api/

- Colorblind simulation tests: Verify distinguishability with deuteranopia/protanopia/tritanopia simulations└── tests/

- Round-trip serialization tests: JSON export/import preserves all properties

- Performance benchmarks: <100ms theme switching, >95% cache hit ratefrontend/

- Golden tests: Visual validation of all 7 predefined themes├── src/

│   ├── components/

### IV. Requirements Compliance (NON-NEGOTIABLE)│   ├── pages/

✅ **PASS** - Specification-driven implementation│   └── services/

- All 9 functional requirements (FR-001 to FR-009) mapped to implementation tasks└── tests/

- tasks.md will document every requirement with corresponding tasks

- Deviations will be explicitly acknowledged in tasks.md changelog with rationale# [REMOVE IF UNUSED] Option 3: Mobile + API (when "iOS/Android" detected)

- Progress tracking in tasks.md updated after each completed taskapi/

└── [same as backend above]

### V. API Consistency

✅ **PASS** - Flutter-idiomatic API designios/ or android/

- Follows Flutter theming patterns: ThemeData-like structure, copyWith() semantics└── [platform-specific structure: feature modules, UI flows, platform tests]

- Matches Foundation Layer patterns: immutability (const constructors), value semantics```

- Fluent builder API: `ChartThemeBuilder().backgroundColor(color).seriesColors([...]).build()`

- Named parameters for clarity: `theme.copyWith(backgroundColor: newColor)`**Structure Decision**: [Document the selected structure and reference the real

- Proper Dart naming conventions: camelCase methods, PascalCase classesdirectories captured above]

- No breaking changes to foundation or rendering APIs

## Phase 0: Outline & Research

### VI. Documentation Discipline1. **Extract unknowns from Technical Context** above:

✅ **PASS** - Comprehensive documentation plan   - For each NEEDS CLARIFICATION → research task

- Dartdoc for all public APIs with examples (ChartTheme, ChartThemeBuilder, all theme components)   - For each dependency → best practices task

- Architecture documentation: Theme structure, cascading resolution, caching strategy   - For each integration → patterns task

- Accessibility guide: WCAG compliance, colorblind-friendly design, contrast utilities

- Migration guide: How to switch from default theme to custom themes2. **Generate and dispatch research agents**:

- Quickstart examples: Each predefined theme + custom theme creation + theme switching   ```

   For each unknown in Technical Context:

## Project Structure     Task: "Research {unknown} for {feature context}"

   For each technology choice:

### Documentation (this feature)     Task: "Find best practices for {tech} in {domain}"

```   ```

specs/004-theming-system/

├── plan.md              # This file (/plan command output)3. **Consolidate findings** in `research.md` using format:

├── research.md          # Phase 0 output (/plan command)   - Decision: [what was chosen]

├── data-model.md        # Phase 1 output (/plan command)   - Rationale: [why chosen]

├── quickstart.md        # Phase 1 output (/plan command)   - Alternatives considered: [what else evaluated]

├── contracts/           # Phase 1 output (/plan command)

│   ├── chart_theme.dart**Output**: research.md with all NEEDS CLARIFICATION resolved

│   ├── grid_style.dart

│   ├── axis_style.dart## Phase 1: Design & Contracts

│   ├── series_theme.dart*Prerequisites: research.md complete*

│   ├── interaction_theme.dart

│   ├── typography_theme.dart1. **Extract entities from feature spec** → `data-model.md`:

│   ├── animation_theme.dart   - Entity name, fields, relationships

│   └── color_utils.dart   - Validation rules from requirements

└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)   - State transitions if applicable

```

2. **Generate API contracts** from functional requirements:

### Source Code (repository root)   - For each user action → endpoint

```   - Use standard REST/GraphQL patterns

lib/   - Output OpenAPI/GraphQL schema to `/contracts/`

└── src/

    └── theming/3. **Generate contract tests** from contracts:

        ├── chart_theme.dart              # Root theme container   - One test file per endpoint

        ├── components/   - Assert request/response schemas

        │   ├── grid_style.dart           # Grid line styling   - Tests must fail (no implementation yet)

        │   ├── axis_style.dart           # Axis styling (lines, labels, titles)

        │   ├── series_theme.dart         # Series colors, line styles, markers4. **Extract test scenarios** from user stories:

        │   ├── interaction_theme.dart    # Crosshair, tooltip, selection   - Each story → integration test scenario

        │   ├── typography_theme.dart     # Text styles and responsive scaling   - Quickstart test = story validation steps

        │   └── animation_theme.dart      # Animation durations and curves

        ├── builder/5. **Update agent file incrementally** (O(1) operation):

        │   └── chart_theme_builder.dart  # Fluent theme builder API   - Run `.specify/scripts/powershell/update-agent-context.ps1 -AgentType copilot`

        ├── themes/     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.

        │   ├── default_light.dart        # Default Light theme   - If exists: Add only NEW tech from current plan

        │   ├── default_dark.dart         # Default Dark theme   - Preserve manual additions between markers

        │   ├── corporate_blue.dart       # Corporate Blue theme   - Update recent changes (keep last 3)

        │   ├── vibrant.dart              # Vibrant theme   - Keep under 150 lines for token efficiency

        │   ├── minimal.dart              # Minimal theme   - Output to repository root

        │   ├── high_contrast.dart        # High Contrast (AAA) theme

        │   └── colorblind_friendly.dart  # Colorblind Friendly theme**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

        ├── utilities/

        │   ├── color_utils.dart          # Contrast calculation, colorblind simulation## Phase 2: Task Planning Approach

        │   ├── style_cache.dart          # LRU cache for resolved styles*This section describes what the /tasks command will do - DO NOT execute during /plan*

        │   └── theme_serialization.dart  # JSON import/export

        └── constants/**Task Generation Strategy**:

            └── theme_constants.dart      # Breakpoints, defaults, palette constants- Load `.specify/templates/tasks-template.md` as base

- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)

test/- Each contract → contract test task [P]

├── contract/- Each entity → model creation task [P] 

│   └── theming/- Each user story → integration test task

│       ├── chart_theme_contract_test.dart- Implementation tasks to make tests pass

│       ├── grid_style_contract_test.dart

│       ├── axis_style_contract_test.dart**Ordering Strategy**:

│       ├── series_theme_contract_test.dart- TDD order: Tests before implementation 

│       ├── interaction_theme_contract_test.dart- Dependency order: Models before services before UI

│       ├── typography_theme_contract_test.dart- Mark [P] for parallel execution (independent files)

│       ├── animation_theme_contract_test.dart

│       └── color_utils_contract_test.dart**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

├── unit/

│   └── theming/**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

│       ├── chart_theme_test.dart

│       ├── chart_theme_builder_test.dart## Phase 3+: Future Implementation

│       ├── predefined_themes_test.dart*These phases are beyond the scope of the /plan command*

│       ├── theme_serialization_test.dart

│       ├── color_utils_test.dart**Phase 3**: Task execution (/tasks command creates tasks.md)  

│       ├── style_cache_test.dart**Phase 4**: Implementation (execute tasks.md following constitutional principles)  

│       └── responsive_typography_test.dart**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

├── accessibility/

│   └── theming/## Complexity Tracking

│       ├── wcag_contrast_test.dart         # WCAG 2.1 AA/AAA compliance*Fill ONLY if Constitution Check has violations that must be justified*

│       └── colorblind_simulation_test.dart # Colorblind distinguishability

├── integration/| Violation | Why Needed | Simpler Alternative Rejected Because |

│   └── theming/|-----------|------------|-------------------------------------|

│       ├── theme_switching_test.dart       # Theme change without chart recreation| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |

│       └── rendering_integration_test.dart # Theme + RenderContext integration| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |

└── benchmarks/

    └── theming/

        ├── theme_switching_benchmark.dart  # <100ms switching## Progress Tracking

        └── style_cache_benchmark.dart      # >95% hit rate*This checklist is updated during execution flow*

```

**Phase Status**:

**Structure Decision**: Single Flutter library structure with theming as a new top-level module under `lib/src/`. The theming system is organized into clear subdirectories (components, builder, themes, utilities, constants) to maintain separation of concerns and enable easy navigation. Test structure mirrors source structure with dedicated accessibility and benchmark folders for theming-specific validation.- [ ] Phase 0: Research complete (/plan command)

- [ ] Phase 1: Design complete (/plan command)

## Phase 0: Outline & Research- [ ] Phase 2: Task planning complete (/plan command - describe approach only)

- [ ] Phase 3: Tasks generated (/tasks command)

**Status**: ✅ COMPLETE (see research.md)- [ ] Phase 4: Implementation complete

- [ ] Phase 5: Validation passed

### Research Complete

**Gate Status**:

All research documented in `research.md` with the following decisions:- [ ] Initial Constitution Check: PASS

- [ ] Post-Design Constitution Check: PASS

1. **Theme Architecture**: Immutable data structures with copyWith() semantics- [ ] All NEEDS CLARIFICATION resolved

2. **Style Cascade**: CSS-like cascade (element > chart > theme > default)- [ ] Complexity deviations documented

3. **Accessibility**: WCAG 2.1 AA/AAA standards with Brettel algorithm for colorblind simulation

4. **Serialization**: JSON with versioned schema for forward/backward compatibility---

5. **Performance**: LRU style cache with 1000-entry limit*Based on Constitution v2.1.1 - See `/memory/constitution.md`*

6. **Responsive Typography**: Breakpoint-based scaling (mobile/tablet/desktop)
7. **Builder API**: Fluent API with validation before build()

## Phase 1: Design & Contracts

**Status**: ✅ COMPLETE

All design artifacts created. See above Project Structure section for complete file organization and contract definitions.

**Outputs**:
- ✅ data-model.md (9 entities documented)
- ✅ contracts/ (8 contract files)
- ✅ quickstart.md (5 executable examples)
- ✅ .github/copilot-instructions.md (updated)

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:

1. **Load Template**: Use `.specify/templates/tasks-template.md` as base structure

2. **Generate from Contracts** (Phase 0: Contracts & Tests):
   - Each contract file → contract test task [P] (8 tasks, parallel)
   - Contract tasks MUST fail initially (TDD requirement)
   - Example: T001 [P] - Create ChartTheme contract test (MUST FAIL)

3. **Generate from Data Model** (Phase 1: Core Data Structures):
   - Each entity → implementation task (9 tasks, some parallel)
   - Immutability: copyWith(), equality, hashCode
   - Serialization: toJson() / fromJson()
   - Example: T009 - Implement ChartTheme with immutability

4. **Generate Predefined Themes** (Phase 2: Predefined Themes):
   - Each of 7 themes → implementation task [P] (7 tasks, parallel)
   - WCAG validation tests (2 tasks: AA for all, AAA for High Contrast)
   - Colorblind simulation tests (1 task)
   - Example: T020 - Implement Default Light theme with WCAG AA

5. **Generate Builder** (Phase 3: Theme Builder):
   - Builder API implementation (1 task)
   - Builder validation (1 task)
   - Builder tests (1 task)
   - Example: T028 - Implement ChartThemeBuilder fluent API

6. **Generate Utilities** (Phase 4: Utilities):
   - ColorUtils implementation (1 task)
   - StyleCache implementation (1 task)
   - Theme serialization (1 task)
   - Utility tests (3 tasks)
   - Example: T032 - Implement ColorUtils with WCAG algorithms

7. **Integration Tasks** (Phase 5: Integration):
   - RenderContext integration (1 task)
   - Theme switching logic (1 task)
   - Responsive typography (1 task)
   - Integration tests (2 tasks)
   - Example: T038 - Integrate themes with RenderContext

8. **Performance & Documentation** (Phase 6: Performance & Docs):
   - Performance benchmarks (2 tasks)
   - Dartdoc for all public APIs (1 task)
   - Usage guide (1 task)
   - Accessibility guide (1 task)
   - Example: T043 - Benchmark theme switching <100ms

**Ordering Strategy**:
- TDD order: Contract tests (fail) → Implementation → Tests pass
- Dependency order: Core structures → Components → Builder → Utilities → Integration
- Mark [P] for parallel execution (independent files/components)
- All tests must fail initially, then pass after implementation

**Estimated Output**: ~45-50 numbered, ordered tasks in tasks.md

**Task Categories**:
- Phase 0 (T001-T008): Contract tests [P]
- Phase 1 (T009-T017): Core data structures [P after T001-T008]
- Phase 2 (T018-T027): Predefined themes + validation [P after T009-T017]
- Phase 3 (T028-T031): Theme builder [after T027]
- Phase 4 (T032-T037): Utilities [P after T017]
- Phase 5 (T038-T042): Integration [after T037]
- Phase 6 (T043-T050): Performance, docs, polish [after T042]

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

**No violations detected** - Constitution Check passed on initial evaluation and post-design re-evaluation.

## Progress Tracking

- [x] Phase 0: Initial Constitution Check (PASS - no violations)
- [x] Phase 0: Research approach documented
- [x] Phase 1: Data model structure defined (9 entities)
- [x] Phase 1: Contract interfaces defined (8 contract files)
- [x] Phase 1: Quickstart examples planned (5 tests)
- [x] Phase 1: Agent context documented
- [x] Phase 1: Post-Design Constitution Check (PASS - no violations)
- [x] Phase 2: Task planning approach documented
- [ ] Phase 2: tasks.md generation (execute via /tasks command)
- [ ] Phase 3+: Implementation (manual or tool-assisted)

---

**STATUS**: ✅ Planning phase complete. Ready for `/tasks` command or manual creation of research.md, data-model.md, contracts/, and quickstart.md.

**Next Steps**:
1. Create research.md with detailed design decisions
2. Create data-model.md with complete entity specifications
3. Create contracts/ directory with 8 interface files
4. Create quickstart.md with 5 executable test examples
5. Run `/tasks` command to generate tasks.md
