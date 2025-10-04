<!--
Sync Impact Report - Constitution Update
========================================
Version change: 1.0.0 → 1.1.0
Modified principles:
- Enhanced Architectural Integrity with Pure Flutter requirement
- Enhanced Performance First with specific 60fps/16ms targets
- Enhanced Documentation Discipline with requirement tracking
Added sections:
- Requirements Compliance principle
- Code Style Standards section
- Development Environment section
Removed sections: None
Templates requiring updates:
✅ plan-template.md (Constitution Check alignment verified)
✅ spec-template.md (scope alignment verified)
✅ tasks-template.md (task categorization verified)
Follow-up TODOs: None
-->

# BravenCharts Constitution

## Core Principles

### I. Architectural Integrity (Pure Flutter)

The codebase MUST maintain pure Flutter implementation with NO HTML elements or web-specific APIs.
All components MUST follow established patterns with clean separation of concerns: models, renderers,
controllers, and utilities. Components MUST integrate seamlessly with the Universal Coordinate System
and annotation framework. No circular dependencies allowed; each layer has clear responsibilities
and interfaces following SOLID design principles.

### II. Performance First (60fps Target)

All rendering operations MUST achieve 60 FPS with <16ms frame times for large datasets. Memory
management requires aggressive virtualization and object pooling. Performance-critical code MUST be
profiled and benchmarked before merging. Viewport-based optimization mandatory for web-first
deployment. Use clipping, animation and opacity sparingly due to performance impact. Memory leaks
are blocking issues.

### III. Testing Excellence (NON-NEGOTIABLE)

Every new feature, bug fix, or architectural change MUST include comprehensive test coverage: unit
tests, integration tests, and visual regression tests where applicable. TDD methodology enforced:
Tests written → Requirements approved → Tests fail → Then implement. Test coverage MUST NOT decrease
below current levels. Integration tests MUST use proper chromedriver setup and flutter drive commands.

### IV. Requirements Compliance (NON-NEGOTIABLE)

When implementing features with defined requirements/tasks:
STOP AND ASK if implementation deviates from requirements or architecture guidelines. IMMEDIATELY
UPDATE the feature's tasks.md file when making technical implementation changes. ALWAYS UPDATE
tasks.md after EVERY completed task to document progress and deviations. ACKNOWLEDGE DEVIATIONS
explicitly in tasks.md change log with rationale.

### V. API Consistency

Public APIs MUST follow established Flutter conventions and maintain backward compatibility. Breaking
changes require major version increments and comprehensive migration documentation. All public APIs
require examples and clear documentation before exposure. Use proper Flutter naming conventions
throughout codebase.

### VI. Documentation Discipline

All public APIs, complex algorithms, and architectural decisions MUST be thoroughly documented with
examples. Code comments MUST explain "why" not just "what" for non-obvious implementations. Inline
documentation required for all rendering pipelines and coordinate transformations. Organize
comprehensive documents, guides and implementation references properly in folder structures.

## Code Style Standards

All code MUST adhere to:

- KISS principle (Keep It Simple Stupid) - use lowest level implementation possible
- SOLID design principles for maintainable, readable, and scalable software
- Proper industry standard Flutter naming conventions
- Comprehensive documentation and commenting
- Dart analyzer compliance with zero warnings

## Development Environment

Standard commands and processes:

- **Development**: `flutter run -d chrome .\example\lib\main.dart --web-port=8080`
- **Integration Testing**: Start chromedriver (`chromedriver --port=4444`) then run tests with proper flutter drive syntax
- **Target Platform**: Flutter Web (primary), iOS/Android (secondary)
- **Language Requirements**: Dart 3.0+, Flutter SDK 3.0.0+

## Quality Standards

All code MUST pass automated quality gates including:

- Dart analyzer with zero warnings
- 100% test coverage for new code
- Performance benchmarks within 60fps/16ms targets
- Documentation completeness verification
- Visual regression test approval
- Constitutional compliance verification

## Development Workflow

All PRs require constitution compliance verification; Architecture changes require design review;
Performance-critical code requires benchmark comparison; Breaking changes require migration guide
and version increment. Conventional commit format mandatory with clear, descriptive messages
representing atomic, logical changes. Research problems thoroughly before implementation, explain
actions step-by-step, and ask for feedback when facing potential issues.

## Governance

Constitution supersedes all other practices; Amendments require documentation, approval, and migration
plan; All PRs/reviews must verify compliance; Complexity must be justified with architectural decision
records; When in doubt, ask for feedback rather than making sweeping changes.

---

**Version**: 1.1.0 | **Ratified**: 2025-01-21 | **Last Amended**: 2025-09-21
