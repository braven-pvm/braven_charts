# Command: `orchestra verify`

> **Navigation**: [Phase 1 Index](../readme.md) | **Prev**: [prepare](prepare.md) | **Next**: [complete](complete.md)

---

## Purpose

Run verification checks for the current task. Executes all checks defined in the task's verification criteria and produces a structured report.

## Synopsis

```bash
orchestra verify [OPTIONS]
```

## Options

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--task` | INT | No | current | Task ID to verify (default: current in-progress) |
| `--check` | STR | No | all | Run specific check ID only |
| `--severity` | STR | No | all | Filter by severity (BLOCKING/MAJOR/MINOR/INFO) |
| `--continue-on-error` | FLAG | No | false | Continue after failures |
| `--json` | FLAG | No | false | Output JSON format |
| `--verbose` | FLAG | No | false | Show command output |

## Preconditions

1. **Task in progress**: Task must have status "in_progress"
2. **Verification criteria exist**: `verification/task-XXX.yaml` must exist
3. **Pre-signal artifact**: Optional but recommended (proves implementor ran checks)

## Behavior

### Step 1: Load Verification Criteria

```yaml
# .orchestra/orchestrator/.orchestrator-only/verification/task-003.yaml
task_id: 3
title: "Create YAxisConfig Model"
category: "INTEGRATION"

verification:
  - id: "V3.1"
    check: "File exists"
    severity: "BLOCKING"
    expected: "lib/src/models/y_axis_config.dart exists"
    type: "file_exists"
    params:
      path: "lib/src/models/y_axis_config.dart"
      
  - id: "V3.2"
    check: "Class defined"
    severity: "BLOCKING"
    expected: "YAxisConfig class is defined"
    type: "pattern_match"
    params:
      file: "lib/src/models/y_axis_config.dart"
      pattern: "class YAxisConfig"
      
  - id: "V3.3"
    check: "Tests exist"
    severity: "MAJOR"
    expected: "Test file exists with tests"
    type: "file_exists"
    params:
      path: "test/unit/y_axis_config_test.dart"
      
  - id: "V3.4"
    check: "Tests pass"
    severity: "BLOCKING"
    expected: "All tests pass"
    type: "command"
    params:
      command: "flutter test test/unit/y_axis_config_test.dart"
      expected_exit: 0
      
  - id: "V3.5"
    check: "Analyzer clean"
    severity: "MAJOR"
    expected: "No analyzer issues"
    type: "command"
    params:
      command: "flutter analyze lib/src/models/y_axis_config.dart"
      expected_output: "No issues found"
      
  - id: "V3.6"
    check: "Documentation"
    severity: "MINOR"
    expected: "Class has doc comments"
    type: "pattern_match"
    params:
      file: "lib/src/models/y_axis_config.dart"
      pattern: "/// "
```

### Step 2: Execute Checks

For each check, based on type:

#### Type: `file_exists`
```typescript
function checkFileExists(params: FileExistsParams): CheckResult {
  const filePath = path.resolve(params.path);
  if (fs.existsSync(filePath)) {
    return { passed: true, actual: `File exists at ${filePath}` };
  }
  return { passed: false, actual: `File not found: ${filePath}` };
}
```

#### Type: `pattern_match`
```typescript
function checkPatternMatch(params: PatternMatchParams): CheckResult {
  const content = fs.readFileSync(params.file, 'utf-8');
  const regex = new RegExp(params.pattern);
  if (regex.test(content)) {
    return { passed: true, actual: `Pattern found: ${params.pattern}` };
  }
  return { passed: false, actual: `Pattern not found: ${params.pattern}` };
}
```

#### Type: `command`
```typescript
import { execSync } from 'node:child_process';

function checkCommand(params: CommandParams): CheckResult {
  try {
    const result = execSync(params.command, {
      encoding: 'utf-8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    
    if (params.expectedOutput) {
      const passed = result.includes(params.expectedOutput);
      return { passed, actual: result, exitCode: 0 };
    }
    
    return { passed: true, actual: result, exitCode: 0 };
  } catch (error) {
    const execError = error as { status?: number; stdout?: string; stderr?: string };
    const passed = params.expectedExit === execError.status;
    return {
      passed,
      actual: execError.stdout || execError.stderr || '',
      exitCode: execError.status ?? 1,
    };
  }
}
```

#### Type: `screenshot_exists`
```typescript
function checkScreenshotExists(params: ScreenshotParams): CheckResult {
  const filePath = path.resolve(params.path);
  if (!fs.existsSync(filePath)) {
    return { passed: false, actual: 'Screenshot not found' };
  }
  // Check file is not empty
  const stats = fs.statSync(filePath);
  const minSize = params.minSize ?? 1000; // < 1KB likely empty/corrupt
  if (stats.size < minSize) {
    return { passed: false, actual: 'Screenshot appears empty' };
  }
  return { passed: true, actual: `Screenshot exists: ${filePath}` };
}
```

### Step 3: Aggregate Results

```typescript
interface VerificationReport {
  taskId: string;
  timestamp: string;
  overall: 'PASSED' | 'FAILED';
  checks: CheckResult[];
  blockingPassed: number;
  blockingFailed: number;
  majorPassed: number;
  majorFailed: number;
  minorPassed: number;
  minorFailed: number;
  infoCount: number;
}

function isPassed(report: VerificationReport): boolean {
  // Task passes if no BLOCKING failures and <2 MAJOR failures
  return report.blockingFailed === 0 && report.majorFailed < 2;
}
```

### Step 4: Save Report

```yaml
# .orchestra/orchestrator/results/task-003-verification.yaml
task_id: 3
timestamp: "2025-12-01T14:30:00Z"
overall: "PASSED"

summary:
  blocking: { passed: 3, failed: 0 }
  major: { passed: 2, failed: 0 }
  minor: { passed: 1, failed: 0 }
  info: { count: 0 }

checks:
  - id: "V3.1"
    severity: "BLOCKING"
    status: "PASSED"
    expected: "lib/src/models/y_axis_config.dart exists"
    actual: "File exists at lib/src/models/y_axis_config.dart"
    
  - id: "V3.4"
    severity: "BLOCKING"
    status: "PASSED"
    expected: "All tests pass"
    actual: "15 tests passed in 2.3s"
```

## Output

### Success (Human)

```
Verification Report
─────────────────────────────────────────
Task: 3 - Create YAxisConfig Model
Result: ✓ PASSED

Checks:
  ✓ [BLOCKING] V3.1: File exists
  ✓ [BLOCKING] V3.2: Class defined
  ✓ [MAJOR]    V3.3: Tests exist
  ✓ [BLOCKING] V3.4: Tests pass (15 tests, 2.3s)
  ✓ [MAJOR]    V3.5: Analyzer clean
  ✓ [MINOR]    V3.6: Documentation

Summary:
  BLOCKING: 3/3 passed
  MAJOR:    2/2 passed
  MINOR:    1/1 passed

Next: Run 'orchestra complete' to finish task
```

### Failure (Human)

```
Verification Report
─────────────────────────────────────────
Task: 3 - Create YAxisConfig Model
Result: ✗ FAILED

Checks:
  ✓ [BLOCKING] V3.1: File exists
  ✓ [BLOCKING] V3.2: Class defined
  ✗ [MAJOR]    V3.3: Tests exist
      Expected: test/unit/y_axis_config_test.dart exists
      Actual:   File not found
  ✗ [BLOCKING] V3.4: Tests pass
      Expected: All tests pass
      Actual:   Test file not found
  ✓ [MAJOR]    V3.5: Analyzer clean
  ○ [MINOR]    V3.6: Documentation (skipped)

Summary:
  BLOCKING: 2/3 passed (1 FAILED)
  MAJOR:    1/2 passed (1 FAILED)
  MINOR:    0/1 passed (skipped)

Failed Checks:
  V3.3: Create test file at test/unit/y_axis_config_test.dart
  V3.4: Tests cannot run without test file

Attempt: 1 of 3
Next: Fix issues and run 'orchestra verify' again
```

### JSON Output

```json
{
  "task_id": 3,
  "timestamp": "2025-12-01T14:30:00Z",
  "overall": "FAILED",
  "summary": {
    "blocking": { "passed": 2, "failed": 1 },
    "major": { "passed": 1, "failed": 1 },
    "minor": { "passed": 0, "skipped": 1 }
  },
  "checks": [
    {
      "id": "V3.1",
      "severity": "BLOCKING",
      "status": "PASSED",
      "check": "File exists",
      "expected": "lib/src/models/y_axis_config.dart exists",
      "actual": "File exists at lib/src/models/y_axis_config.dart"
    },
    {
      "id": "V3.3",
      "severity": "MAJOR",
      "status": "FAILED",
      "check": "Tests exist",
      "expected": "test/unit/y_axis_config_test.dart exists",
      "actual": "File not found"
    }
  ],
  "failed_checks": ["V3.3", "V3.4"],
  "attempt": 1,
  "max_attempts": 3
}
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed |
| 1 | One or more checks failed |
| 2 | No task in progress |
| 3 | Verification criteria not found |
| 4 | Check execution error |

## Examples

```bash
# Verify current task
orchestra verify

# Verify specific task
orchestra verify --task 3

# Run only BLOCKING checks
orchestra verify --severity BLOCKING

# Run specific check
orchestra verify --check V3.4

# Continue after failures (run all checks)
orchestra verify --continue-on-error

# Verbose output (show command output)
orchestra verify --verbose

# JSON output for scripting
orchestra verify --json
```

## Check Types Reference

| Type | Description | Parameters |
|------|-------------|------------|
| `file_exists` | Check file exists | `path` |
| `dir_exists` | Check directory exists | `path` |
| `pattern_match` | Regex search in file | `file`, `pattern` |
| `command` | Run shell command | `command`, `expected_exit`, `expected_output` |
| `json_valid` | Validate JSON file | `path` |
| `yaml_valid` | Validate YAML file | `path` |
| `screenshot_exists` | Check screenshot file | `path`, `min_size` |
| `export_exists` | Check export in barrel file | `barrel_file`, `export_pattern` |

## Custom Check Types

Add custom check types in `.orchestra/config.yaml`:

```yaml
verification:
  custom_checks:
    flutter_widget_test:
      command: "flutter test --tags=widget {{file}}"
      expected_exit: 0
      
    has_documentation:
      type: pattern_match
      pattern: "^/// "
      min_matches: 3
```

## Implementation Notes

1. **Parallel execution**: Independent checks can run in parallel
2. **Caching**: Cache expensive checks (test runs) within session
3. **Timeout**: Commands have configurable timeout (default 60s)
4. **Output capture**: Save full command output for debugging
5. **Skip logic**: Skip dependent checks if prerequisite fails
