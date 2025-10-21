<!--
Sync Impact Report - Constitution Update
========================================
Version change: 1.0.0 → 1.1.0
Modified principles:
- Performance First (EXPANDED): Added critical Flutter pattern guidance for high-frequency state updates
  * ADDED: setState prohibition for >10Hz updates
  * ADDED: ValueNotifier + ValueListenableBuilder pattern requirement
  * ADDED: RepaintBoundary isolation mandate
  * ADDED: Architecture pattern justification requirement
Added sections:
- Performance First principle expansion with reactive patterns guidance
Removed sections: N/A
Templates requiring updates:
✅ plan-template.md - Constitution Check includes performance patterns
✅ spec-template.md - Architecture sections verify state management patterns
✅ tasks-template.md - Task types include architecture validation
Follow-up TODOs: None
Rationale for MINOR version bump: Material expansion of Performance First principle
with new mandatory patterns. No backward-incompatible changes to governance, but
adds testable requirements that affect architecture decisions going forward.
-->

# Braven Charts Constitution

## Core Principles

### I. Test-First Development (NON-NEGOTIABLE)

TDD methodology MUST be strictly enforced: Tests written → Requirements approved → Tests fail → Then implement. Every new feature, bug fix, or architectural change MUST include comprehensive test coverage including unit tests, integration tests, and visual regression tests where applicable. Test coverage MUST NOT decrease below current levels. Red-Green-Refactor cycle is mandatory. Integration tests MUST use proper ChromeDriver setup with flutter drive commands. No code merges without passing tests.

**Rationale**: TDD ensures correctness from day one, prevents regressions, and serves as living documentation. For a charting library where visual accuracy and performance are critical, comprehensive testing is the foundation of reliability.

### II. Performance First (60fps Target)

All rendering operations MUST achieve 60 FPS with frame times under 16ms for large datasets. Memory management requires aggressive virtualization and object pooling. Performance-critical code MUST be profiled and benchmarked before merging. Viewport-based optimization mandatory for web-first deployment. Use clipping, animation, and opacity sparingly due to performance impact. Memory leaks are blocking issues. All performance regressions require justification and approval.

**State Management for High-Frequency Updates (CRITICAL):**
- **setState MUST NOT be used** for updates occurring at >10Hz (e.g., mouse tracking, pointer events, continuous animations)
- **MUST use ValueNotifier + ValueListenableBuilder** pattern for high-frequency state changes
- **MUST isolate repainting layers** with RepaintBoundary to prevent cascade rebuilds
- **MUST justify architecture patterns** that trigger widget rebuilds during interaction loops
- **MouseTracker conflicts**: Any setState during pointer event handling WILL cause box.dart:3345 and mouse_tracker.dart:199 assertion failures

**Rationale**: As a web-first charting library, performance directly impacts user experience. Charts rendering thousands of data points must remain fluid and responsive. The 60fps/16ms standard ensures professional-grade performance on all target platforms. Flutter's setState rebuilds entire widget trees and is fundamentally incompatible with continuous pointer events (100+ updates/second). MouseTracker requires stable render trees during hit testing; setState invalidates coordinates mid-calculation causing catastrophic crashes. ValueNotifier provides granular reactivity without rebuild overhead, achieving smooth 60fps interactions even with complex charts.

### III. Architectural Integrity (Pure Flutter)

The codebase MUST maintain pure Flutter implementation with NO HTML elements or web-specific APIs. All components MUST follow established patterns with clean separation of concerns: models, renderers, controllers, and utilities. Components MUST integrate seamlessly with the Universal Coordinate System and annotation framework. No circular dependencies allowed; each layer has clear responsibilities and interfaces following SOLID design principles. Architecture changes require design review and approval.

**Rationale**: Pure Flutter ensures consistent behavior across all platforms (web, iOS, Android, desktop). Mixed implementations lead to platform-specific bugs and maintenance nightmares. SOLID principles keep the codebase maintainable and extensible.

### IV. Requirements Compliance (NON-NEGOTIABLE)

When implementing features with defined requirements (e.g., specs/###-feature-name/): STOP AND ASK if implementation deviates from requirements or architecture guidelines. IMMEDIATELY UPDATE the feature's tasks.md file when making technical implementation changes. ALWAYS UPDATE tasks.md after EVERY completed task to document progress and deviations. ACKNOWLEDGE DEVIATIONS explicitly in tasks.md change log with rationale and impact assessment.

**Rationale**: Requirements represent stakeholder agreements and architectural decisions. Undocumented deviations lead to misaligned expectations and technical debt. Task tracking ensures transparency and enables project visibility.

### V. API Consistency & Stability

Public APIs MUST follow established Flutter conventions and maintain backward compatibility. Breaking changes require major version increments with comprehensive migration documentation and deprecation notices. All public APIs require clear documentation with examples before exposure. Use proper Flutter naming conventions throughout codebase. APIs must be intuitive and discoverable by developers.

**Rationale**: Braven Charts will be published to pub.dev and used by many developers. API stability builds trust and adoption. Breaking changes without migration paths alienate users and damage reputation.

### VI. Documentation Discipline

All public APIs, complex algorithms, and architectural decisions MUST be thoroughly documented with working examples. Code comments MUST explain "why" not just "what" for non-obvious implementations. Inline documentation required for all rendering pipelines and coordinate transformations. Organize comprehensive documents, guides, and implementation references properly in folder structures (docs/, specs/, etc.). Architecture Decision Records (ADRs) required for major technical choices.

**Rationale**: Documentation is code for humans. For a library, it's the primary interface between maintainers and users. Complex charting algorithms require explanation for future maintainers. Proper organization ensures findability and reduces onboarding friction.

### VII. Simplicity & Pragmatism (KISS Principle)

Use the lowest level implementation possible for each problem (KISS - Keep It Simple Stupid). Adhere to SOLID design principles for maintainable, readable, and scalable software. Avoid premature optimization and over-engineering. Complexity must be justified with Architecture Decision Records. Research problems thoroughly before implementation, explain actions step-by-step, and ask for feedback when facing potential issues rather than making sweeping changes.

**Rationale**: Simple code is maintainable code. Over-engineered solutions become technical debt. The KISS principle combined with SOLID ensures we build only what's needed while maintaining quality. Asking for feedback prevents costly mistakes.

## Code Quality Standards

All code MUST adhere to:

- **KISS Principle**: Use lowest level implementation possible; avoid over-engineering
- **SOLID Design**: Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, Dependency Inversion principles
- **Flutter Conventions**: Proper industry-standard naming conventions (lowerCamelCase for variables/functions, UpperCamelCase for classes, SCREAMING_SNAKE_CASE for constants)
- **Documentation**: Comprehensive inline documentation and examples for all public APIs
- **Dart Analyzer**: Zero warnings required; fix all lints before commit
- **Code Reviews**: All PRs require constitution compliance verification

## Development Environment

Standard commands, processes, and tooling:

- **Language**: Dart 3.0+, Flutter SDK 3.10.0+
- **Target Platform**: Flutter Web (primary), iOS/Android (secondary)
- **Development Server**: `flutter run -d chrome .\example\lib\main.dart --web-port=8080`
- **Unit/Widget Tests**: `flutter test test/web/ test/unit/ test/golden/ test/performance/ test/braven_charts_test.dart`
- **Integration Tests**: 
  1. Start ChromeDriver: `chromedriver --port=4444` (separate process)
  2. Run tests: `flutter drive --driver=test/test_driver/integration_test.dart --target=test/integration_test/web_app_test.dart -d chrome --browser-name=chrome`
  3. Or use helper script: `./scripts/testing/run_chromedriver_tests.ps1`
- **Performance Profiling**: Use Flutter DevTools for performance analysis
- **Linting**: `flutter analyze` (must return zero warnings)

## Quality Gates

All code MUST pass automated quality gates before merge:

- **Dart Analyzer**: Zero warnings (blocking)
- **Test Coverage**: 100% coverage for new code (blocking)
- **Test Execution**: All tests passing (blocking)
- **Performance Benchmarks**: Within 60fps/16ms targets for affected code paths (blocking)
- **Documentation**: All public APIs documented with examples (blocking)
- **Visual Regression**: Golden tests approved for UI changes (blocking)
- **Constitution Compliance**: PR checklist verified (blocking)
- **Code Review**: At least one approval from maintainer (blocking)

## Development Workflow

All development activities follow these processes:

- **Branching**: Feature branches from `main` (`###-feature-name` format from specs)
- **Commits**: Conventional commit format mandatory (e.g., `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `perf:`, `chore:`)
  - Commits must be atomic and represent logical changes
  - Clear, descriptive messages explaining what and why
- **Pull Requests**: 
  - All PRs require constitution compliance verification
  - Architecture changes require design review
  - Performance-critical code requires benchmark comparison
  - Breaking changes require migration guide and version increment
- **Research First**: Research problems thoroughly before implementation
  - Explain actions step-by-step during development
  - Ask for feedback when facing potential issues
  - Never hallucinate or make sweeping changes without justification

## Governance

Constitution authority and amendment process:

- **Authority**: This constitution supersedes all other practices and guidelines
- **Amendments**: Require documentation, approval from maintainers, and migration plan if affecting existing code
- **Compliance**: All PRs and code reviews must verify constitutional compliance
- **Complexity Justification**: Any violation or complexity increase must be justified with Architecture Decision Records
- **Feedback Culture**: When in doubt, ask for feedback rather than making assumptions or sweeping changes
- **Continuous Improvement**: Constitution may be amended as project evolves; changes must be documented in Sync Impact Report

---

**Version**: 1.1.0 | **Ratified**: 2025-10-04 | **Last Amended**: 2025-10-21