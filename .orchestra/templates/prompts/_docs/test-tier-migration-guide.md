# Test Tier Setup & Migration Guide

This guide is the definitive reference for structuring tests in any project that uses Orchestra's intelligent test runner tools. It covers both **new project setup** (greenfield) and **migration of existing test suites** into the tiered directory structure that Orchestra requires.

## Prerequisites

Before setting up tiered tests, ensure you have:

- **Orchestra extension** installed in VS Code (provides the agent tools that run tests)
- **Git** initialized in your workspace (required for `git mv`, change detection, and promotion history)
- **A supported test framework**:

| Platform          | Framework   | Config File        | Test File Pattern |
| ----------------- | ----------- | ------------------ | ----------------- |
| TypeScript / Node | Vitest      | `vitest.config.ts` | `*.test.ts`       |
| Dart / Flutter    | `dart test` | `dart_test.yaml`   | `*_test.dart`     |

> **Note**: Orchestra provides full tool support for both Vitest and Dart/Flutter. The **directory structure, tier configuration, and workflow** are identical across platforms — only the `framework` field and test file naming convention differ.

## Understanding the Five Test Tiers

Orchestra supports five standard test tiers, each serving a specific purpose in your testing strategy:

### 1. `red` — TDD Failing Tests

Tests in the TDD red phase that are expected to fail. These tests define new behavior before the implementation exists.

**Characteristics:**

- Run in isolation from other tiers
- Expected to fail (failure is success for this tier)
- Promote to other tiers once implementation passes
- Short-lived; should not remain in `red` indefinitely

### 2. `smoke` — Fast Sanity Checks

Quick tests that verify basic wiring, structure, and configuration without executing application logic. Smoke tests are your first line of defense — they catch broken builds, missing files, and misconfigured registrations before slower tests even start.

**Characteristics:**

- Execute in under 5 seconds total
- No mocks, no database, no runtime dependencies
- Validate structure and wiring, not behavior
- Run on every save and before commits
- High confidence signal with minimal time investment

**Common smoke test categories:**

| Category                        | What It Validates                          | TS Example                                              | Dart Example                                    |
| ------------------------------- | ------------------------------------------ | ------------------------------------------------------- | ----------------------------------------------- |
| **Manifest validation**         | Config files have correct structure        | `package.json` has required VS Code contribution points | `pubspec.yaml` has correct dependencies         |
| **Registration/wiring checks**  | Source code references match declarations  | Commands registered in source match `package.json`      | Routes registered in source match config        |
| **Filesystem structure checks** | Required directories and files exist       | Agent scaffolding directories have `.gitkeep` files     | `lib/` structure matches expected module layout |
| **Schema validation**           | Schema definitions accept/reject correctly | MCP tool `inputSchema` fields are valid JSON Schema     | API request/response schemas match OpenAPI spec |
| **Convention enforcement**      | Source files follow required patterns      | All handler files include audit logging calls           | All repository classes extend `BaseRepository`  |
| **Static content validation**   | Documentation/config has required sections | Agent markdown prompts contain required headings        | README has required badges and sections         |

**How to identify smoke test candidates in an existing codebase:**

A test belongs in `smoke/` if it meets **all** of these criteria:

1. **No mocks** — doesn't use test doubles, stubs, or mock frameworks
2. **No database** — doesn't connect to or set up any database
3. **No runtime execution** — doesn't instantiate classes or call functions that perform application work
4. **Pure validation** — reads files, parses configs, or checks existence; then asserts structure
5. **Sub-second** — individual test completes in < 1 second

> **Warning**: Smoke tests should NOT test logic or behavior. A test that mocks dependencies and asserts return values is a unit test, even if it's fast. A test that reads a config file and checks it has the right keys is a smoke test.

### 3. `unit` — Isolated Unit Tests

Tests for individual functions, classes, or modules in complete isolation.

**Characteristics:**

- Mock all external dependencies
- Fast execution (typically < 100ms per test)
- High coverage of edge cases
- No file system, network, or database access

### 4. `integration` — Cross-Module Tests

Tests that verify multiple modules working together correctly.

**Characteristics:**

- May use real file system or databases
- Test module interfaces and contracts
- Slower than unit tests but faster than e2e
- Focus on internal integration points

### 5. `e2e` — End-to-End Tests

Full system tests that verify complete user workflows.

**Characteristics:**

- Test the entire application stack
- May require external services
- Longest execution time
- Highest confidence for user-facing functionality

---

## Quick Start: New Project

If you're starting a new project (no existing tests to migrate), follow this section. If you have existing tests to restructure, skip to [Migrating Existing Tests](#migrating-existing-tests).

### TypeScript / Vitest

**1. Create the directory structure:**

```
your-project/
├── src/                        # Source code
├── test/
│   ├── smoke/                  # Fast wiring/structure checks
│   ├── unit/                   # Isolated unit tests
│   ├── integration/            # Cross-module tests
│   └── setup/                  # Test infrastructure (helpers, fixtures)
├── vitest.config.ts
└── .agent-test-config.json
```

**2. Configure Vitest** (`vitest.config.ts`):

```typescript
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    include: [
      "test/smoke/**/*.test.ts",
      "test/unit/**/*.test.ts",
      "test/integration/**/*.test.ts",
    ],
    exclude: ["**/node_modules/**"],
    testTimeout: 30000,
  },
});
```

**3. Configure Orchestra** (`.agent-test-config.json`):

```json
{
  "framework": "vitest",
  "tiers": [
    {
      "name": "smoke",
      "path": "test/smoke/**/*.test.ts",
      "timeout": 10000
    },
    {
      "name": "unit",
      "path": "test/unit/**/*.test.ts",
      "timeout": 30000
    },
    {
      "name": "integration",
      "path": "test/integration/**/*.test.ts",
      "timeout": 60000
    }
  ],
  "workingDir": ".",
  "defaultTimeout": 30000,
  "maxFailureLines": 20,
  "configFingerprint": [
    "vitest.config.*",
    "tsconfig.json",
    ".agent-test-config.json"
  ],
  "promotion": {
    "dryRun": true
  }
}
```

**4. Write your first smoke test** (`test/smoke/project-structure.test.ts`):

```typescript
import * as fs from "fs/promises";
import * as path from "path";
import { describe, expect, it } from "vitest";

const ROOT = path.resolve(__dirname, "../..");

describe("Smoke: project structure", () => {
  it("package.json should exist and have a name", async () => {
    const raw = await fs.readFile(path.join(ROOT, "package.json"), "utf8");
    const pkg = JSON.parse(raw);
    expect(pkg.name).toBeTruthy();
  });

  it("src/ directory should exist", async () => {
    const stat = await fs.stat(path.join(ROOT, "src"));
    expect(stat.isDirectory()).toBe(true);
  });
});
```

**5. Write your first unit test** (`test/unit/example.test.ts`):

```typescript
import { describe, expect, it } from "vitest";

// Import the module under test
import { add } from "../../src/math.js";

describe("add()", () => {
  it("should return the sum of two numbers", () => {
    expect(add(2, 3)).toBe(5);
  });

  it("should handle negative numbers", () => {
    expect(add(-1, 1)).toBe(0);
  });
});
```

**6. Verify:**

```bash
npx vitest run test/smoke/     # Smoke tests only
npx vitest run test/unit/      # Unit tests only
npx vitest run                 # All tests
```

### Dart / Flutter

**1. Create the directory structure:**

```
your-project/
├── lib/                        # Source code
├── test/
│   ├── smoke/                  # Fast wiring/structure checks
│   ├── unit/                   # Isolated unit tests
│   ├── integration/            # Cross-module tests
│   └── helpers/                # Test infrastructure
├── dart_test.yaml              # (optional) Dart test configuration
├── pubspec.yaml
└── .agent-test-config.json
```

**2. Configure Dart test** (`dart_test.yaml`, optional):

```yaml
# Tag-based test filtering for TDD workflow
tags:
  red:
    # TDD red-phase tests: failing tests awaiting implementation.
    # Excluded from normal runs; run explicitly with --tags=red.
  smoke:
    # Smoke tests: fast sanity checks for quick CI feedback.
  e2e:
    # End-to-end tests: may be slow, excluded from local dev runs.
  slow:
    # Slow tests: excluded from default runs to keep feedback fast.
```

**3. Configure Orchestra** (`.agent-test-config.json`):

```json
{
  "framework": "dart",
  "tiers": [
    {
      "name": "smoke",
      "path": "test/smoke/**/*_test.dart",
      "timeout": 10000
    },
    {
      "name": "unit",
      "path": "test/unit/**/*_test.dart",
      "timeout": 30000
    },
    {
      "name": "integration",
      "path": "test/integration/**/*_test.dart",
      "timeout": 60000
    }
  ],
  "workingDir": ".",
  "defaultTimeout": 30000,
  "maxFailureLines": 20,
  "configFingerprint": [
    "pubspec.yaml",
    "dart_test.yaml",
    ".agent-test-config.json"
  ],
  "dartExcludeTags": ["slow"],
  "promotion": {
    "dryRun": true
  }
}
```

> **Dart vs Flutter**: Use `"framework": "dart"` for pure Dart projects (no Flutter SDK dependency in `pubspec.yaml`). Use `"framework": "flutter"` for Flutter projects. Flutter projects automatically get `--no-pub` to skip `pub get` on each test run. For pure Dart projects, set `"dartNoPub": true` to enable the same optimization.

**4. Write your first smoke test** (`test/smoke/project_structure_test.dart`):

```dart
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Smoke: project structure', () {
    test('pubspec.yaml should exist and have a name', () {
      final file = File('pubspec.yaml');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('name:'));
    });

    test('lib/ directory should exist', () {
      expect(Directory('lib').existsSync(), isTrue);
    });
  });
}
```

**5. Write your first unit test** (`test/unit/math_test.dart`):

```dart
import 'package:test/test.dart';
import 'package:your_project/math.dart';

void main() {
  group('add()', () {
    test('should return the sum of two numbers', () {
      expect(add(2, 3), equals(5));
    });

    test('should handle negative numbers', () {
      expect(add(-1, 1), equals(0));
    });
  });
}
```

**6. Verify:**

```bash
dart test test/smoke/         # Smoke tests only
dart test test/unit/          # Unit tests only
dart test                     # All tests
```

---

## Configuration Reference

The `.agent-test-config.json` file is the single source of truth for Orchestra's test runner tools. It must live at the workspace root.

### Schema

| Field               | Type       | Required | Default                                                           | Description                                                                                                             |
| ------------------- | ---------- | -------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `framework`         | `string`   | Yes      | `"vitest"`                                                        | Test framework: `"vitest"`, `"dart"`, or `"flutter"`.                                                                   |
| `tiers`             | `array`    | Yes      | —                                                                 | One or more tier definitions (see below). At least one tier must be declared.                                           |
| `workingDir`        | `string`   | No       | `"."`                                                             | Working directory for test execution, relative to workspace root.                                                       |
| `defaultTimeout`    | `number`   | No       | `30000`                                                           | Default timeout in milliseconds for test runs. Overridable per tier and per invocation.                                 |
| `maxFailureLines`   | `number`   | No       | `20`                                                              | Maximum lines of failure detail shown per failing test. Controls output verbosity.                                      |
| `configFingerprint` | `string[]` | No       | `["vitest.config.*", "tsconfig.json", ".agent-test-config.json"]` | Glob patterns for config files included in the fingerprint cache. Changes to these files invalidate all cached results. |
| `projects`          | `string[]` | No       | —                                                                 | Vitest project names for multi-project workspaces. Omit for single-project setups.                                      |
| `dartNoPub`         | `boolean`  | No       | —                                                                 | Dart-specific: apply `--no-pub` for pure Dart projects (Flutter gets it by default). Skips `pub get` before test runs.  |
| `dartExcludeTags`   | `string[]` | No       | —                                                                 | Dart-specific: tags to always exclude from test runs (e.g., `["slow", "e2e"]`). Applied as `--exclude-tags`.            |
| `promotion`         | `object`   | No       | `{ "dryRun": true }`                                              | Promotion defaults. `dryRun: true` means promotion previews changes without moving files.                               |

### Tier Definition

Each entry in the `tiers` array defines one test tier:

| Field      | Type      | Required | Default          | Description                                                                         |
| ---------- | --------- | -------- | ---------------- | ----------------------------------------------------------------------------------- |
| `name`     | `string`  | Yes      | —                | Tier name used in tool invocations (e.g., `"unit"`, `"smoke"`, `"extension-unit"`). |
| `path`     | `string`  | Yes      | —                | Glob pattern for test files, relative to workspace root.                            |
| `timeout`  | `number`  | No       | `defaultTimeout` | Timeout override in ms for tests in this tier.                                      |
| `inverted` | `boolean` | No       | `false`          | If `true`, failing tests are "correct" (red-phase TDD). Only use for `red` tier.    |

### Tier Naming Rules

- Standard names: `red`, `smoke`, `unit`, `integration`, `e2e`
- For multi-package projects, prefix with package name: `extension-unit`, `extension-smoke`, etc.
- Custom names are allowed (e.g., `acceptance`, `performance`) — add them to `tiers` and create the matching directory
- Tier names must be unique within the config file

### Config Fingerprint

The `configFingerprint` array tells Orchestra which config files to monitor for cache invalidation. Include:

- **Test runner config**: `vitest.config.*` for TS, `dart_test.yaml` for Dart
- **Compiler/build config**: `tsconfig.json` for TS, `pubspec.yaml` for Dart
- **This file**: Always include `".agent-test-config.json"`
- **Additional runner configs**: If you have per-package vitest configs (e.g., `extension/vitest.config.ts`), add them explicitly — the glob `vitest.config.*` only matches the workspace root

---

## Dart / Flutter Platform Details

This section covers Dart and Flutter-specific behaviors, requirements, and configuration. If you're using Vitest, skip to [Migrating Existing Tests](#migrating-existing-tests).

### SDK Version Requirements

| SDK     | Minimum Version | Required For                                           |
| ------- | --------------- | ------------------------------------------------------ |
| Dart    | 3.0+            | JSON reporter (`--reporter=json`), tag-based filtering |
| Flutter | 3.10+           | `--machine` flag for structured test output            |

> Orchestra's DartRunner uses `dart test --reporter=json` (pure Dart) or `flutter test --machine` (Flutter) to parse structured test events. Older SDK versions that lack these flags are not supported.

### Framework Auto-Detection

If `.agent-test-config.json` is absent or has no `framework` field, Orchestra auto-detects the framework by scanning the workspace root:

| File Found          | Detected Framework                                                                        |
| ------------------- | ----------------------------------------------------------------------------------------- |
| `pubspec.yaml` only | `"dart"` or `"flutter"` (based on Flutter SDK dependency)                                 |
| `vitest.config.*`   | `"vitest"`                                                                                |
| Both present        | **Error** — dual-marker conflict. You must provide an explicit `.agent-test-config.json`. |
| Neither             | **Error** — no detectable framework.                                                      |

The auto-detection logic lives in `TestRunnerFactory.detect()`. It checks for `pubspec.yaml` (Dart/Flutter marker) and `vitest.config.*` (Vitest marker). If a `pubspec.yaml` is found, it inspects the `dependencies` and `dev_dependencies` sections for `flutter` to distinguish Dart from Flutter.

### CLI Differences: Dart vs Flutter

| Feature             | Pure Dart (`dart test`)                | Flutter (`flutter test`)           |
| ------------------- | -------------------------------------- | ---------------------------------- |
| Structured output   | `--reporter=json`                      | `--machine`                        |
| Tag include         | `--tags=smoke`                         | `--tags smoke`                     |
| Tag exclude         | `--exclude-tags=slow`                  | `--exclude-tags slow`              |
| No-pub optimization | Requires `dartNoPub: true` in config   | Applied automatically (`--no-pub`) |
| Concurrency         | `--concurrency=N`                      | `--concurrency=N`                  |
| File specification  | Paths after `--` or as positional args | Positional args                    |

Orchestra's `DartRunner` handles these differences transparently. You only need to set the correct `framework` value.

### The `--no-pub` Optimization

By default, `dart test` and `flutter test` run `pub get` before each test invocation to ensure dependencies are current. In CI or agent workflows where dependencies are already resolved, this adds unnecessary overhead.

- **Flutter projects**: `--no-pub` is applied automatically on every test run.
- **Pure Dart projects**: Set `"dartNoPub": true` in `.agent-test-config.json` to enable the same behavior.

### Tag-Based Filtering with `dart_test.yaml`

Dart's native test runner supports tag-based filtering via `dart_test.yaml`. Orchestra leverages this for:

- **TDD red-phase**: Tests tagged `@Tags(['red'])` are excluded from normal runs and only executed during red-phase verification.
- **Exclude tags**: The `dartExcludeTags` config field maps to `--exclude-tags`, letting you skip slow or e2e tests in default runs.

Example test with tags:

```dart
@Tags(['unit'])
import 'package:test/test.dart';

void main() {
  test('example unit test', () {
    expect(1 + 1, equals(2));
  });
}
```

### Related Scope Resolution for Dart

When `scope: "related"` is used with `run_tests`, Orchestra finds tests related to a given source file. For Dart projects, this uses a three-strategy approach:

1. **Naming convention**: `lib/src/math.dart` → looks for `test/**/*math_test.dart`
2. **Import graph analysis**: Builds a dependency graph from `import` / `export` / `part` directives using `DartImportGraph`. Walks up to depth 3 to find test files that transitively import the source file.
3. **Directory fallback**: If no matches from naming or imports, searches the corresponding test directory structure.

**Import graph caching**: The import graph is cached using an mtime-based fingerprint. When any `.dart` file's modification time changes, the cache is invalidated. The graph builder uses `ripgrep` when available for faster file scanning, falling back to Node.js `fs` operations. Cycle detection prevents infinite loops in circular import chains.

### Flutter Engine Log Filtering

Flutter's test output includes non-JSON engine log lines (e.g., `flutter: ...` debug messages, observatory URIs). Orchestra's `DartRunner.extractJsonEvents()` automatically filters these, extracting only valid JSON test event lines for result parsing. No configuration is needed — this happens transparently.

---

## Migrating Existing Tests

If you already have tests that need to be restructured into tiers, follow these steps. If you're starting fresh, see [Quick Start: New Project](#quick-start-new-project).

### Step 1: Audit Your Current Test Structure

Before migrating, understand what you have.

**TypeScript:**

```bash
# macOS / Linux
find . -name "*.test.ts" -not -path "*/node_modules/*" | wc -l
find . -name "*.test.ts" -not -path "*/node_modules/*"

# Windows (PowerShell)
(Get-ChildItem -Recurse -Filter *.test.ts -Exclude node_modules).Count
Get-ChildItem -Recurse -Filter *.test.ts -Exclude node_modules | Select-Object FullName
```

**Dart:**

```bash
# macOS / Linux
find . -name "*_test.dart" -not -path "*/.dart_tool/*" | wc -l

# Windows (PowerShell)
(Get-ChildItem -Recurse -Filter *_test.dart -Exclude .dart_tool).Count
```

Identify:

- Where tests currently live (flat, nested, scattered)
- What types of tests you have (unit, integration, e2e)
- Any existing organizational patterns
- Which tests use mocks vs. which validate structure (smoke candidates)

### Step 2: Create the Tiered Directory Structure

Create directories for each tier you plan to use:

```bash
# macOS / Linux
mkdir -p test/unit test/integration test/smoke

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path test/unit, test/integration, test/smoke
```

For projects with separate packages (monorepos):

```bash
# Example: extension package
mkdir -p extension/test/unit extension/test/integration extension/test/smoke

# Windows (PowerShell)
New-Item -ItemType Directory -Force -Path extension/test/unit, extension/test/integration, extension/test/smoke
```

### Step 3: Classify and Move Test Files

Use this decision tree to classify each test file:

```
For each test file, ask in order:

1. Is it a TDD test expected to fail?                    → red
2. Does it validate structure/wiring WITHOUT mocks?       → smoke
   - Reads config/manifest files and checks keys?         → smoke
   - Reads source code as text and pattern-matches?       → smoke
   - Checks filesystem structure (dirs/files exist)?      → smoke
   - Validates schema definitions with sample data?       → smoke
   - Checks that source files follow a convention?        → smoke
3. Does it test multiple modules working together?        → integration
   - Uses real database or file system?                   → integration
   - Tests cross-module workflows?                        → integration
   - Has ".integration.test.ts" / "_integration_test.dart"? → integration
4. Does it test a complete user workflow end-to-end?      → e2e
5. Everything else (mocked dependencies, fast, isolated)  → unit
```

Move files using `git mv` to preserve history:

```bash
# TypeScript examples
git mv test/utils.test.ts test/unit/utils.test.ts
git mv test/database.test.ts test/integration/database.test.ts
git mv test/package-json-views.test.ts test/smoke/package-json-views.test.ts

# Dart examples
git mv test/utils_test.dart test/unit/utils_test.dart
git mv test/database_test.dart test/integration/database_test.dart
git mv test/pubspec_check_test.dart test/smoke/pubspec_check_test.dart
```

> **Prefer `git mv` over plain `mv`/`Move-Item`** to preserve file history in version control.

> **Preserve domain subdirectories.** If tests are organized by domain (e.g., `test/core/`, `test/commands/`), maintain that structure inside the tier: `test/unit/core/`, `test/unit/commands/`.

### Step 4: Update Import Paths (TypeScript)

After moving files one level deeper (e.g., `test/foo.test.ts` → `test/unit/foo.test.ts`), every relative path needs one more `../` added. This affects **three categories** of path references:

#### Category 1: Static Imports

```typescript
// Before (when test was in test/)
import { helper } from "../src/utils/helper.js";

// After (when test is in test/unit/)
import { helper } from "../../src/utils/helper.js";
```

#### Category 2: Dynamic Imports, Mocks, and Module References

These are easy to miss because they look like plain strings, not imports:

```typescript
// vi.mock() paths need the same fix
vi.mock("../../src/database/mutations.js", () => ({ ... }));
//       ^^^^^^ was ../.. now needs ../../..

// Dynamic imports too
const mod = await import("../../src/database/queries.js");

// vi.importActual
const actual = await vi.importActual<typeof import("../../src/foo.js")>("../../src/foo.js");
```

#### Category 3: Runtime File Access (`__dirname`, `readFileSync`, `readdirSync`)

**This is the most commonly missed category.** Tests that read source files, config files, or check directory structure use `path.join(__dirname, ...)` or `path.resolve(__dirname, ...)`. These are invisible to import-only fixers:

```typescript
// Before (test was in extension/test/commands/)
const extensionPath = path.join(__dirname, "..", "..", "src", "extension.ts");
//                                        ^^    ^^  resolved to extension/

// After (test is in extension/test/unit/commands/)
const extensionPath = path.join(
  __dirname,
  "..",
  "..",
  "..",
  "src",
  "extension.ts",
);
//                                        ^^    ^^    ^^  needs 3 levels now
```

Also watch for `path.resolve` with string concatenation:

```typescript
// Before
const root = path.resolve(__dirname, "../..");

// After
const root = path.resolve(__dirname, "../../..");
```

#### Automation Tips

A regex-based bulk fixer can handle Categories 1 and 2 by matching any string literal containing `../` chains that point at known directories:

```
Pattern: (['"])(\.\./(?:\.\./)*?)(src/|setup/|fixtures/)
Replace: $1../$2$3
```

Category 3 requires manual inspection. Search for affected files:

```bash
# macOS / Linux
grep -rn "__dirname" test/unit/ extension/test/unit/
grep -rn "readFileSync\|readdirSync\|existsSync" test/unit/ extension/test/unit/

# Windows (PowerShell)
Select-String -Recurse -Pattern "__dirname" -Path test/unit/, extension/test/unit/
Select-String -Recurse -Pattern "readFileSync|readdirSync|existsSync" -Path test/unit/, extension/test/unit/
```

#### Alternative: Path Aliases

For new TypeScript projects, consider `tsconfig.json` path aliases to avoid brittle relative imports entirely:

```json
{
  "compilerOptions": {
    "paths": {
      "@src/*": ["./src/*"],
      "@test/*": ["./test/*"]
    }
  }
}
```

```typescript
// Immune to directory moves
import { helper } from "@src/utils/helper.js";
```

> **Caveat**: Path aliases don't help with Category 3 (`__dirname`-based file access). Tests that read source files as text will always need manual path fixes when moved.

### Step 4b: Update Import Paths (Dart)

Dart's import system is simpler — package imports (`import 'package:...'`) are unaffected by file moves. Only **relative imports** need updating:

```dart
// Before (test was in test/)
import '../lib/src/utils/helper.dart';

// After (test is in test/unit/)
import '../../lib/src/utils/helper.dart';
```

Dart relative path fixes are the same concept as TypeScript — add one more `../` per level of nesting added.

**Dart-specific search for affected files:**

```bash
# macOS / Linux
grep -rn "import '\.\." test/unit/

# Windows (PowerShell)
Select-String -Recurse -Pattern "import '\.\." -Path test/unit/
```

> **Dart best practice**: Prefer `package:` imports over relative imports. Package imports are immune to file moves:
>
> ```dart
> // Immune to directory moves
> import 'package:your_project/src/utils/helper.dart';
> ```

### Step 5: Create the Configuration File

Create `.agent-test-config.json` in your workspace root. See [Configuration Reference](#configuration-reference) for the full schema.

**TypeScript / Vitest:**

```json
{
  "framework": "vitest",
  "tiers": [
    { "name": "smoke", "path": "test/smoke/**/*.test.ts", "timeout": 10000 },
    { "name": "unit", "path": "test/unit/**/*.test.ts", "timeout": 30000 },
    {
      "name": "integration",
      "path": "test/integration/**/*.test.ts",
      "timeout": 60000
    }
  ],
  "workingDir": ".",
  "defaultTimeout": 30000,
  "maxFailureLines": 20,
  "configFingerprint": [
    "vitest.config.*",
    "tsconfig.json",
    ".agent-test-config.json"
  ],
  "promotion": { "dryRun": true }
}
```

**Dart (pure):**

```json
{
  "framework": "dart",
  "tiers": [
    { "name": "smoke", "path": "test/smoke/**/*_test.dart", "timeout": 10000 },
    { "name": "unit", "path": "test/unit/**/*_test.dart", "timeout": 30000 },
    {
      "name": "integration",
      "path": "test/integration/**/*_test.dart",
      "timeout": 60000
    }
  ],
  "workingDir": ".",
  "defaultTimeout": 30000,
  "maxFailureLines": 20,
  "configFingerprint": [
    "pubspec.yaml",
    "dart_test.yaml",
    ".agent-test-config.json"
  ],
  "dartNoPub": true,
  "dartExcludeTags": ["slow"],
  "promotion": { "dryRun": true }
}
```

**Flutter:**

```json
{
  "framework": "flutter",
  "tiers": [
    { "name": "smoke", "path": "test/smoke/**/*_test.dart", "timeout": 10000 },
    { "name": "unit", "path": "test/unit/**/*_test.dart", "timeout": 30000 },
    {
      "name": "widget",
      "path": "test/widget/**/*_test.dart",
      "timeout": 60000
    },
    {
      "name": "integration",
      "path": "test/integration/**/*_test.dart",
      "timeout": 120000
    }
  ],
  "workingDir": ".",
  "defaultTimeout": 60000,
  "maxFailureLines": 20,
  "configFingerprint": [
    "pubspec.yaml",
    "dart_test.yaml",
    ".agent-test-config.json"
  ],
  "dartExcludeTags": ["slow", "e2e"],
  "promotion": { "dryRun": true }
}
```

> **Important**: Match the `path` glob patterns to your platform's test file naming convention: `**/*.test.ts` for TypeScript, `**/*_test.dart` for Dart.
>
> Use `"framework": "dart"` for pure Dart projects and `"framework": "flutter"` for Flutter projects. Flutter projects automatically get `--no-pub` on every test run; for pure Dart projects, set `"dartNoPub": true` to enable the same optimization.

Also update your test runner configuration to include the new tier directories:

**Vitest** — ensure `vitest.config.ts` `include` array covers all tier directories:

```typescript
include: [
  "test/smoke/**/*.test.ts",
  "test/unit/**/*.test.ts",
  "test/integration/**/*.test.ts",
],
```

**Dart** — `dart test` discovers tests in `test/` recursively by default, so no additional configuration is needed unless you're using `dart_test.yaml` to exclude specific directories.

### Step 6: Verify the Migration

Run tests through the new tier structure to confirm everything works:

**TypeScript / Vitest:**

```bash
# Run each tier individually
npx vitest run test/smoke/ --no-cache
npx vitest run test/unit/ --no-cache
npx vitest run test/integration/ --no-cache

# Run everything
npx vitest run --no-cache
```

**Dart / Flutter:**

```bash
# Run each tier individually
dart test test/smoke/
dart test test/unit/
dart test test/integration/

# Run everything
dart test
```

> **Always use `--no-cache` on first verification** to ensure you're not seeing stale cached results from before the migration.

**Using Orchestra agent tools** — once configured, the AI agent uses the tools with JSON input. For example, the agent invokes `run_tests` with:

```json
{ "scope": "suite", "target": "unit" }
```

And `list_test_suites` with:

```json
{ "detail": "suites" }
```

You don't invoke these directly — Orchestra's agents use them automatically when running tests on your behalf.

---

## Per-Package / Monorepo Convention

When a project has multiple test roots (e.g., a root `test/` and an `extension/test/`), each root needs **its own set of tier entries** with a namespace prefix. Use the convention `{package}-{tier}`:

| Tier Entry              | Package   | Tier        | Glob Path                                 |
| ----------------------- | --------- | ----------- | ----------------------------------------- |
| `unit`                  | root      | unit        | `test/unit/**/*.test.ts`                  |
| `extension-unit`        | extension | unit        | `extension/test/unit/**/*.test.ts`        |
| `smoke`                 | root      | smoke       | `test/smoke/**/*.test.ts`                 |
| `extension-smoke`       | extension | smoke       | `extension/test/smoke/**/*.test.ts`       |
| `integration`           | root      | integration | `test/integration/**/*.test.ts`           |
| `extension-integration` | extension | integration | `extension/test/integration/**/*.test.ts` |

**Why separate entries?** Different packages may have different test runner configs, module aliases, or test infrastructure. Scoping tiers per-package lets you:

- Run only one package's tests (e.g., `scope: "suite", target: "extension-unit"`)
- Set different timeouts per package
- Track test results per package independently

**Config fingerprint for monorepos**: If you have separate test runner configs per package (e.g., `extension/vitest.config.ts`), add them explicitly to `configFingerprint`:

```json
"configFingerprint": [
  "vitest.config.*",
  "extension/vitest.config.ts",
  "tsconfig.json",
  ".agent-test-config.json"
]
```

The glob `vitest.config.*` only matches at the workspace root — nested configs need explicit entries.

For single-package projects, use plain tier names (`unit`, `integration`, `smoke`).

---

## What Good Tests Look Like in Each Tier

This section shows the _character_ of tests that belong in each tier. Use these as templates when creating new tests.

### Smoke Test Examples

Smoke tests read files and check structure. They never instantiate application code.

**TypeScript:**

```typescript
import * as fs from "fs/promises";
import * as path from "path";
import { describe, expect, it } from "vitest";

const ROOT = path.resolve(__dirname, "../..");

describe("Smoke: config structure", () => {
  it("tsconfig.json should have strict mode enabled", async () => {
    const raw = await fs.readFile(path.join(ROOT, "tsconfig.json"), "utf8");
    const config = JSON.parse(raw);
    expect(config.compilerOptions.strict).toBe(true);
  });
});
```

**Dart:**

```dart
import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Smoke: config structure', () {
    test('analysis_options.yaml should exist', () {
      expect(File('analysis_options.yaml').existsSync(), isTrue);
    });

    test('pubspec.yaml should declare test dependency', () {
      final content = File('pubspec.yaml').readAsStringSync();
      expect(content, contains('test:'));
    });
  });
}
```

### Unit Test Examples

Unit tests mock dependencies and test isolated behavior.

**TypeScript:**

```typescript
import { describe, expect, it, vi } from "vitest";
import { UserService } from "../../src/services/user-service.js";

vi.mock("../../src/database/user-repo.js", () => ({
  UserRepo: vi.fn().mockImplementation(() => ({
    findById: vi.fn().mockResolvedValue({ id: 1, name: "Alice" }),
  })),
}));

describe("UserService", () => {
  it("should return user by id", async () => {
    const service = new UserService();
    const user = await service.getUser(1);
    expect(user.name).toBe("Alice");
  });
});
```

**Dart:**

```dart
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:your_project/services/user_service.dart';
import 'package:your_project/repositories/user_repo.dart';

class MockUserRepo extends Mock implements UserRepo {}

void main() {
  group('UserService', () {
    test('should return user by id', () async {
      final repo = MockUserRepo();
      when(repo.findById(1)).thenAnswer((_) async => User(id: 1, name: 'Alice'));
      final service = UserService(repo);
      final user = await service.getUser(1);
      expect(user.name, equals('Alice'));
    });
  });
}
```

### Integration Test Examples

Integration tests use real dependencies and test cross-module behavior.

**TypeScript:**

```typescript
import * as fs from "fs/promises";
import * as os from "os";
import * as path from "path";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { ConfigLoader } from "../../src/config/loader.js";

describe("ConfigLoader integration", () => {
  let tempDir: string;

  beforeEach(async () => {
    tempDir = await fs.mkdtemp(path.join(os.tmpdir(), "test-"));
  });

  afterEach(async () => {
    await fs.rm(tempDir, { recursive: true });
  });

  it("should load config from disk", async () => {
    await fs.writeFile(
      path.join(tempDir, "config.json"),
      JSON.stringify({ name: "test" }),
    );
    const loader = new ConfigLoader(tempDir);
    const config = await loader.load();
    expect(config.name).toBe("test");
  });
});
```

**Dart:**

```dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:your_project/config/loader.dart';

void main() {
  group('ConfigLoader integration', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('test-');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should load config from disk', () async {
      File('${tempDir.path}/config.json')
          .writeAsStringSync('{"name": "test"}');
      final loader = ConfigLoader(tempDir.path);
      final config = await loader.load();
      expect(config.name, equals('test'));
    });
  });
}
```

---

## TDD Red/Green Workflow

Orchestra supports a TDD workflow using a dedicated `red` tier. The flow is:

1. **Write a failing test** → place it in `test/red/` (or `test/tdd/`)
2. **Run the red tier** — Orchestra verifies the test _fails_ (inverted assertion)
3. **Write the implementation** — make the test pass
4. **Promote the test** — move it from `red` to the appropriate tier (`unit`, `integration`, etc.)

### TypeScript Red-Phase Test

```typescript
// @orchestra-task: 5
// File: test/red/unit/new-feature.test.ts
import { describe, expect, it } from "vitest";
import { newFeature } from "../../src/features/new-feature.js";

describe("newFeature", () => {
  it("should return processed data", () => {
    // This test is expected to FAIL — the function doesn't exist yet
    const result = newFeature("input");
    expect(result).toBe("processed: input");
  });
});
```

### Dart Red-Phase Test

Dart uses directory-based isolation, same as TypeScript:

```dart
// @orchestra-task: 5
// File: test/red/unit/new_feature_test.dart
import 'package:test/test.dart';
import 'package:your_project/features/new_feature.dart';

void main() {
  group('newFeature', () {
    test('should return processed data', () {
      // This test is expected to FAIL — the function doesn't exist yet
      final result = newFeature('input');
      expect(result, equals('processed: input'));
    });
  });
}
```

Run red-phase tests:

```bash
# TypeScript
npx vitest run test/red/

# Dart
flutter test test/red/
```

### Red Tier Configuration

```json
{
  "name": "red",
  "path": "test/red/**/*.test.ts",
  "timeout": 10000,
  "inverted": true
}
```

The `inverted: true` flag tells Orchestra that failing tests in this tier are _expected_. A test that passes in the red tier indicates the test doesn't actually validate new behavior (it passed before implementation).

---

## Migrating Large Test Suites (3,000+ Tests)

Large codebases require a strategic, incremental approach. Attempting to migrate thousands of tests at once will disrupt development workflows.

### Incremental Batch Migration

Break the migration into batches of 100–200 tests per phase. For each batch, follow the classify-move-verify cycle:

1. **Classify**: Review each test and determine its appropriate tier
2. **Move**: Relocate the test file to the new tier directory using `git mv`
3. **Verify**: Run both the moved tests and any related tests to ensure nothing broke

### Recommended Tier Order

Start with the easiest-to-classify tier and expand:

1. **Unit tests** (Weeks 1–3): Highest volume, lowest risk. Clear boundaries.
2. **Integration tests** (Weeks 4–5): More complex classification, requires understanding module boundaries.
3. **E2E tests** (Week 6): Usually the smallest count, highest complexity.
4. **Smoke tests** (Week 7): Extract from unit/integration tests or create new ones.
5. **Red tier** (Ongoing): Address TDD tests as they arise.

### Strategies for Minimizing Disruption

- **Run parallel configurations**: Keep your existing test config active alongside the tiered structure until migration is complete
- **Migrate during low-activity periods**: Schedule batches at the end of sprints
- **Track progress**: Maintain a spreadsheet or issue tracking migration status per file
- **Create temporary aliases**: Map old test commands to new tier-based commands during transition

### Example Timeline (3,500 tests, 4–5 developers)

| Week | Focus                                              | Tests Migrated | Cumulative |
| ---- | -------------------------------------------------- | -------------- | ---------- |
| 1    | Setup tier structure, migrate first 100 unit tests | 100            | 100        |
| 2–3  | Continue unit tests                                | 800            | 900        |
| 4–5  | Integration tests                                  | 500            | 1,400      |
| 6    | E2E tests                                          | 100            | 1,500      |
| 7    | Extract/create smoke tests                         | 50             | 1,550      |
| 8–10 | Remaining tests, edge cases, legacy cleanup        | 1,950          | 3,500      |

---

## Configuration-Driven Tier Validation

Orchestra validates that only declared tiers are available. If the agent requests a test run for an undeclared tier, it receives a clear error:

```
Error: Tier "acceptance" is not configured.
Available tiers: smoke, unit, integration, e2e

To add this tier, update .agent-test-config.json:
{
  "tiers": [
    ...existing tiers...,
    {
      "name": "acceptance",
      "path": "test/acceptance/**/*.test.ts",
      "timeout": 120000
    }
  ]
}
```

This explicit configuration prevents typos and ensures consistent tier names across all team members and agents.

---

## Troubleshooting

### Tests Not Discovered

If Orchestra's tools don't find your tests:

1. Verify the `path` glob in `.agent-test-config.json` matches your file locations and naming convention (`*.test.ts` for TS, `*_test.dart` for Dart)
2. Ensure the tier directory actually exists on disk
3. Check that `workingDir` is correct for your project structure
4. **TypeScript**: Verify your `vitest.config.ts` `include` patterns also cover the new tier directories — the Orchestra config and vitest config must agree
5. **Dart**: Verify your files are inside `test/` (Dart's default discovery root)

### Import Path Errors After Moving (TypeScript)

The most common post-migration error is `Failed to load url ... Does the file exist?`. This means a relative import wasn't updated after the file moved deeper.

**Diagnosis**: The error message shows the resolved path — count the `../` segments to determine if one is missing.

**Quick fix**: Add one more `../` to the failing import. If many files are affected, use the regex bulk-fix approach from [Step 4](#step-4-update-import-paths-typescript).

**Prevention**: After moving files, audit all relative imports before running tests:

```bash
# macOS / Linux
grep -rn "from \"\.\." test/unit/

# Windows (PowerShell)
Select-String -Recurse -Pattern 'from "\.\.' -Path test/unit/
```

### Import Path Errors After Moving (Dart)

If you see `Can't load ... URI` errors:

- Check relative imports (`import '../...'`) — add one more `../` per level of nesting
- Switch to `package:` imports to avoid the problem entirely

### Stale Test Results / Cache Issues

Test runners may cache file resolutions. If you've fixed imports but tests still fail with old error messages:

```bash
# TypeScript / Vitest
rm -rf node_modules/.vitest          # macOS / Linux
Remove-Item -Recurse .vitest-cache   # Windows (PowerShell)
npx vitest run --no-cache

# Dart
dart test --no-color  # Dart test has no explicit cache, but a clean run helps
```

### Runtime Path Resolution Failures (ENOENT)

Tests that use `path.join(__dirname, "..", "src", ...)` (TypeScript) or `File('../lib/...')` (Dart) with relative paths will fail with `ENOENT` / `FileSystemException` after moving. These are **not** import errors — they're runtime filesystem access.

Search for affected files:

```bash
# TypeScript
grep -rn "__dirname" test/unit/ | grep "path\.\(join\|resolve\)"          # macOS / Linux
Select-String -Recurse -Pattern "__dirname" -Path test/unit/               # PowerShell

# Dart
grep -rn "File(" test/unit/ | grep "\.\."                                 # macOS / Linux
Select-String -Recurse -Pattern "File\(" -Path test/unit/                  # PowerShell
```

Fix each occurrence by adding the appropriate number of `..` segments.

### Timeout Issues

If tests timeout after migration, increase the tier's timeout:

```json
{
  "name": "integration",
  "path": "test/integration/**/*.test.ts",
  "timeout": 120000
}
```

### Configuration Not Recognized

Ensure `.agent-test-config.json` is at workspace root and has valid JSON syntax:

```bash
# macOS / Linux
cat .agent-test-config.json | python3 -m json.tool

# Windows (PowerShell)
Get-Content .agent-test-config.json | ConvertFrom-Json
```

### Encoding Issues with Automated Fix Scripts (Windows)

PowerShell's `Set-Content` can write UTF-16 by default, causing test runners to misread files. Always specify encoding:

```powershell
# WRONG — may write UTF-16 BOM
$content | Set-Content $file -NoNewline

# CORRECT — preserves UTF-8
[System.IO.File]::WriteAllText($file, $content)
# or
$content | Set-Content $file -NoNewline -Encoding utf8
```

---

## Appendix A: Case Study — Orchestra's Own Migration

Orchestra migrated its own test suite using this guide. This section documents what happened, what worked, and what caught us off guard.

### Scope

- **245 test files** total: 94 in `test/` (MCP server/core), 151 in `extension/test/` (VS Code extension)
- **247 test suites**, **3,564+ individual tests**
- Two vitest configs: root `vitest.config.ts` and `extension/vitest.config.ts`

### Approach

1. **Direct classification** — We knew our test base well enough to classify in bulk. All root tests went to `test/unit/` (no root integration tests existed). Extension tests were split: 5 files with `.integration.test.ts` naming went to `extension/test/integration/`, everything else to `extension/test/unit/`.

2. **`git mv` for all moves** — Preserves file history. No files were copied-and-deleted.

3. **Bulk import fix script** — A PowerShell script using regex to add one `../` to all relative path string literals targeting known directories (`src/`, `setup/`, `fixtures/`):

   ```
   Pattern: (['"])(\.\./(?:\.\./)*?)(src/|setup/|fixtures/|extension/)
   Replace: $1../$2$3
   ```

4. **Manual fix pass** — After the bulk script, 14 files still failed due to `path.join(__dirname, "..", ...)` patterns where the `..` segments were separate string arguments. These required manual inspection.

### Gotchas and Lessons Learned

**1. `__dirname`-relative paths are the silent killer.**
The bulk regex fixer catches `"../../src/foo.js"` in all contexts. But `path.join(__dirname, "..", "..", "src", "extension.ts")` has each `..` as a _separate string argument_ — invisible to any single-string regex. These only surface as `ENOENT` errors at runtime.

_Mitigation_: After running a bulk fixer, search for `__dirname` in all moved files and verify every `path.join`/`path.resolve` chain manually.

**2. PowerShell `Set-Content` encoding traps.**
PowerShell's `Set-Content` can silently change file encoding to UTF-16, causing vitest to misread files. Use `[System.IO.File]::WriteAllText()` or explicitly pass `-Encoding utf8`.

**3. Vitest caching hides fixes.**
After fixing import paths, vitest sometimes serves stale cached results from before the fix. Run with `--no-cache` and delete the vitest cache directory when debugging.

**4. Double-fixing is easy.**
If a bulk import fixer already processed a file, and you then manually add another `../`, the path goes too deep. Use `git diff` to review changes before running tests.

**5. Multi-line `path.join()` is harder to regex.**
When `path.join(__dirname, "..", "src", ...)` is spread across multiple lines, even sophisticated regexes fail. These always require manual or AST-based fixes.

**6. Integration test identification.**
We used the `.integration.test.ts` naming convention. If your project doesn't have a naming convention, look for: tests that import database setup helpers, tests that create real temp directories, and tests with `beforeAll`/`afterAll` that start/stop services.

### Per-Package Tier Decision

We chose separate namespace tiers (`unit` / `extension-unit`) rather than flat because:

- The root package and extension package have different vitest configs with different module aliases
- Running `extension-unit` scopes to just the VS Code extension
- Timeouts can differ between packages

### Smoke Test Candidates (Pending Extraction)

During migration, we identified 13 test files currently in `unit/` that fit the smoke tier definition. These are pending extraction to `smoke/` and `extension/test/smoke/`:

**Extension package:**

| File                                    | New Tier        | What It Validates                            | Smoke Category       |
| --------------------------------------- | --------------- | -------------------------------------------- | -------------------- |
| `package-json-configuration.test.ts`    | extension-smoke | VS Code settings in `package.json`           | Manifest validation  |
| `package-json-views.test.ts`            | extension-smoke | Views, menus, keybindings in `package.json`  | Manifest validation  |
| `extension-registration.test.ts`        | extension-smoke | Command registration (package.json ↔ source) | Wiring check         |
| `extension-config-service.test.ts`      | extension-smoke | ConfigService import/instantiation in source | Wiring check         |
| `commands/AgentCommandHandler.test.ts`  | extension-smoke | Agent command registration                   | Wiring check         |
| `agents/directory-structure.test.ts`    | extension-smoke | Agent directory scaffold exists              | Filesystem structure |
| `prompts/ensurePromptTemplates.test.ts` | extension-smoke | Real extension bundle has templates          | Filesystem structure |

**Root package:**

| File                                                     | New Tier | What It Validates                          | Smoke Category         |
| -------------------------------------------------------- | -------- | ------------------------------------------ | ---------------------- |
| `mcp-server/role-filtering.test.ts`                      | smoke    | Tool-to-role assignment and access control | Registration check     |
| `mcp-server/tool-schema-validation.test.ts`              | smoke    | MCP tool `inputSchema` definitions         | Schema validation      |
| `mcp-server/audit-logging-coverage.test.ts`              | smoke    | All handlers have audit logging            | Convention enforcement |
| `interface-validations-config.test.ts`                   | smoke    | Interface validations YAML structure       | Config validation      |
| `agents/orchestrator-agent-interface-validation.test.ts` | smoke    | Orchestrator agent.md required sections    | Content validation     |
| `agents/controller-agent-interface-validation.test.ts`   | smoke    | Controller agent.md required sections      | Content validation     |

> These files will be moved to `test/smoke/` and `extension/test/smoke/` in a future pass. The `.agent-test-config.json` already has `smoke` and `extension-smoke` tier entries defined.

---

## Summary

Setting up tiered tests enables Orchestra's intelligent test runner to optimize your testing workflow. Whether starting fresh or migrating:

1. **Create** tiered directories: `test/smoke/`, `test/unit/`, `test/integration/` (and per-package variants for monorepos)
2. **Configure** `.agent-test-config.json` with your tiers, framework, and config fingerprint files
3. **Align** your test runner config (`vitest.config.ts` includes or `dart_test.yaml`) with the tier directories
4. **Write or move** tests to appropriate tiers — use the decision tree, not just test speed
5. **Fix paths** after migration: static imports, mock/dynamic imports, and runtime `__dirname`/`File()` paths
6. **Verify** with `--no-cache` to avoid stale results
7. **Don't skip smoke tests** — they're your fastest feedback loop

**Key takeaway**: The directory structure and configuration are platform-agnostic. Whether you're writing TypeScript with Vitest or Dart with `dart test`, the tier model, decision tree, and `.agent-test-config.json` format are identical. Set up the structure correctly once, and Orchestra's agents handle the rest.
