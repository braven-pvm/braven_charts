# Archived Testing Framework Setup Files

**Date Archived**: October 4, 2025  
**Reason**: These files were created during the initial testing framework setup and are not part of the actual Foundation layer implementation.

## Archived Files

### Test Suite Demos
- `braven_charts_test.dart.old` - Main test suite runner demonstrating comprehensive test structure
- `chart_utils_test.dart.old` - Unit tests for chart utility functions (demo/example)
- `web_utils_test.dart.old` - Web-specific utility tests (demo/example)

### Integration Test Examples
- `app_test.dart.old` - Example integration tests for full app context
- `web_app_test.dart.old` - Web-specific integration test examples
- `integration_test.dart.old` - Integration test driver configuration

## Purpose

These files served as:
1. **Testing framework validation** - Ensuring the 6-layer testing structure was correctly configured
2. **Documentation examples** - Showing how to use TestUtils, PerformanceTestUtils, WebTestUtils, etc.
3. **Configuration verification** - Confirming golden tests, ChromeDriver, and integration tests work

## Current Test Structure

The active test files are now organized as:
```
test/
├── contract/foundation/          # Contract tests for TDD (Phase 3.2)
│   ├── data_models_contract_test.dart
│   ├── performance_contract_test.dart
│   ├── type_system_contract_test.dart
│   └── math_contract_test.dart
├── unit/foundation/              # Unit tests (Phase 3.3+)
├── performance/foundation/       # Performance benchmarks (Phase 3.7)
├── integration_test/             # Integration tests (Phase 3.8)
└── golden/foundation/            # Golden file tests (future)
```

## Recovery

If these files are needed for reference, they can be:
1. Restored by renaming `.old` → `.dart`
2. Used as templates for new tests
3. Referenced for testing framework usage examples

---

*These files are preserved for historical reference but are not part of the Foundation layer implementation.*
