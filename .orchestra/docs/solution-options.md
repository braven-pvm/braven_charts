# Orchestra Pattern: Solution Options

> **Status**: Ideation / Brainstorming  
> **Created**: 2025-01-08  
> **Purpose**: Capture ideas for formalizing and automating the orchestrator pattern

---

## Current State

### What We've Built (Manually)

```
.orchestra/
├── manifest.yaml          # Full task list with phases
├── progress.yaml          # Tracking with commit hashes, attempts, stats
├── verification/          # Hidden per-task verification criteria
│   └── task-XXX.yaml
├── handover/              # Implementor-visible communication
│   ├── AGENT_README.md    # Onboarding (stable)
│   ├── current-task.md    # Reset each task (volatile)
│   ├── task-context.md    # Sprint context (semi-stable)
│   └── completion-signal.md
└── docs/                  # Process documentation
```

### Pain Points Experienced

| Pain Point | Description | Frequency |
|------------|-------------|-----------|
| Manual translation | Orchestrator reads spec → writes current-task.md | Every task |
| Manual verification | Running each check command, interpreting results | Every task |
| Manual progress updates | Updating YAML, adding task history entries | Every task |
| Context loss risk | If orchestrator loses context, needs to re-read everything | Occasional |
| No automation | Every step is human-in-the-loop | Always |

---

## Solution Options

### Option A: CLI Tool (`orchestra`)

A command-line tool for orchestrator operations.

```bash
# Initialize a new sprint from spec
orchestra init --spec specs/011-multi-axis/spec.md --output .orchestra/

# Prepare next task for implementor
orchestra prepare-task 3

# Run verification for current task
orchestra verify

# Complete task (commit, update progress, prepare next)
orchestra complete --message "feat: add SeriesAxisBinding"

# Check status
orchestra status
```

**Pros:**
- Simple, shell-based
- Works with any agent/IDE
- Easy to prototype in Python
- Can be used by human or agent

**Cons:**
- Still requires someone to run commands
- No deep integration with agent context

**Implementation Complexity:** Low-Medium

---

### Option B: MCP Server (`orchestra-mcp`)

An MCP server exposing orchestrator tools directly to the agent.

```typescript
// Tools exposed via MCP
orchestra_init_sprint(spec_path: string)
orchestra_get_current_task(): TaskDetails
orchestra_prepare_task(task_id: number)
orchestra_run_verification(): VerificationReport
orchestra_complete_task(commit_message: string)
orchestra_get_progress(): ProgressReport
orchestra_handle_failure(feedback: string)
```

**Pros:**
- Agent can self-orchestrate
- Fully autonomous workflow possible
- Deep integration with agent context
- Can enforce patterns programmatically

**Cons:**
- More complex to build
- Agent needs to know when to use tools
- MCP setup required

**Implementation Complexity:** Medium-High

---

### Option C: VS Code Extension

A dedicated VS Code extension for orchestra management.

**Features:**
- Command palette: "Orchestra: Prepare Next Task"
- Side panel showing sprint progress
- Verification runner with visual output
- Auto-generates current-task.md from templates
- Status bar indicator for current task

**Pros:**
- Integrated UX
- Visual feedback
- Could work alongside agents
- Rich UI possibilities

**Cons:**
- Tied to VS Code
- Complex to build and maintain
- Overkill for current needs

**Implementation Complexity:** High

---

### Option D: Hybrid - Config-Driven Templates + CLI (Recommended)

Combine templating with a lightweight CLI.

#### Task Type Configuration

```yaml
# .orchestra/templates/task-types.yaml
task_types:
  enum:
    template: templates/enum-task.md
    verification:
      - file_exists: "lib/src/models/{name}.dart"
      - test_exists: "test/unit/{category}/{name}_test.dart"
      - export_added: "lib/src/models/enums.dart"
      - tests_pass: "flutter test {test_file}"
      - analysis_clean: "flutter analyze {file}"
    minimum_tests: 10
    
  model:
    template: templates/model-task.md
    verification:
      - file_exists: "lib/src/models/{name}.dart"
      - test_exists: "test/unit/{category}/{name}_test.dart"
      - properties_present: [pattern list]
      - copyWith_exists: true
      - equality_exists: true
      - tests_pass: true
      - analysis_clean: true
    minimum_tests: 15
    
  widget:
    template: templates/widget-task.md
    verification:
      - file_exists: "lib/src/widgets/{name}.dart"
      - screenshot_exists: "screenshots/task-{id}.png"
      # ... widget-specific checks
    minimum_tests: 10
```

#### CLI Usage

```bash
# Prepare task from template
orchestra prepare --type model --name YAxisConfig --task-id 2
# → Auto-generates current-task.md from template with substitutions
# → Auto-generates verification/task-002.yaml from task type config

# Run verification
orchestra verify
# → Reads verification/task-002.yaml
# → Runs all checks
# → Outputs structured report
# → Returns exit code for scripting

# Complete and advance
orchestra complete "feat(multi-axis): add YAxisConfig"
# → Commits with message
# → Updates progress.yaml
# → Optionally prepares next task
```

**Pros:**
- Templates reduce orchestrator cognitive load
- Verification is codified, not manual
- CLI is simple to build (Python/Dart)
- Can evolve toward MCP later
- Captures patterns in reusable form
- Low barrier to entry

**Cons:**
- Still needs human/agent to invoke CLI
- Template maintenance overhead

**Implementation Complexity:** Low-Medium

---

## Component Breakdown (Option D)

### 1. Task Type Templates

```
.orchestra/templates/
├── enum.md.template
├── model.md.template
├── widget.md.template
├── integration.md.template
└── visual.md.template
```

Each template uses placeholders:
- `{{name}}` - PascalCase class name
- `{{name_snake}}` - snake_case file name
- `{{file_path}}` - full file path
- `{{test_path}}` - test file path
- `{{task_id}}` - current task number
- `{{category}}` - test category folder

### 2. Verification Schema

Standardized verification checks that can be parameterized:

```yaml
# Reusable check definitions
checks:
  file_exists:
    command: 'Test-Path "{{path}}"'
    expected: "True"
    shell: powershell
  
  pattern_match:
    command: 'Select-String -Path "{{file}}" -Pattern "{{pattern}}"'
    expected: "matches found"
    shell: powershell
  
  tests_pass:
    command: "flutter test {{test_file}}"
    expected_regex: "All tests passed"
    shell: default
    
  analysis_clean:
    command: "flutter analyze {{file}}"
    expected_regex: "No issues found"
    shell: default
```

### 3. CLI Tool Structure

```
tools/orchestra/
├── orchestra.py          # Main CLI entry point
├── commands/
│   ├── init.py           # Initialize sprint from spec
│   ├── prepare.py        # Prepare task for implementor
│   ├── verify.py         # Run verification checks
│   ├── complete.py       # Commit and advance
│   └── status.py         # Show current state
├── templates/            # Task templates
│   └── *.md.template
├── lib/
│   ├── verification.py   # Run verification checks
│   ├── progress.py       # Update progress.yaml
│   ├── git_utils.py      # Commit/push helpers
│   └── yaml_utils.py     # YAML manipulation
└── tests/
```

### 4. Sprint Initialization

From a spec file, auto-generate:
- `manifest.yaml` with tasks extracted from spec sections
- `progress.yaml` initialized with zero counts
- `verification/` stubs for each task based on type

---

## Evolution Path

```
Phase 1: Manual (Current)
    ↓
Phase 2: CLI Tool (Option D)
    ↓
Phase 3: MCP Integration (Option B wrapping D)
    ↓
Phase 4: Full Automation (Agent uses MCP to self-orchestrate)
```

---

## Open Questions

1. **Task type inference** - Can we auto-detect task type from spec content?
2. **Spec parsing** - What format should specs follow for reliable extraction?
3. **Cross-project reuse** - How to share templates across projects?
4. **Agent feedback loop** - How does implementor signal partial completion?
5. **Failure recovery** - How to handle verification failures gracefully?
6. **Multi-agent** - Could orchestrator and implementor be different agent instances?

---

## Next Steps (When Ready)

1. [ ] Document current manual process formally
2. [ ] Extract templates from Task 1, 2, 3 patterns
3. [ ] Prototype `orchestra verify` command
4. [ ] Prototype `orchestra complete` command
5. [ ] Prototype `orchestra prepare` command
6. [ ] Test end-to-end on Task 4+

---

## References

- `.orchestra/README.md` - Current orchestrator documentation
- `.orchestra/handover/AGENT_README.md` - Implementor onboarding
- ADR-001 (in RESEARCH_LOG.md) - Translation Layer decision
