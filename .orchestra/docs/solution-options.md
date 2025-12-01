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

---

## Brainstorming Session (2025-12-01)

### Key Design Dimensions Identified

#### 1. Deployment Model

| Option | Pros | Cons |
|--------|------|------|
| **Drop-in folder** (current) | Zero deps, works anywhere, git-trackable | Manual process, no automation |
| **npm/pip/pub package** | Standard tooling, versioning | Adds dependency, language-specific |
| **VS Code extension** | Rich UI, agent integration | VS Code only, complex to build |
| **CLI tool** | Cross-platform, scriptable | Another install, learning curve |
| **GitHub Action/Bot** | Automated, PR-native | GitHub-only, less interactive |

#### 2. Agent Integration Model

| Option | Pros | Cons |
|--------|------|------|
| **System prompt injection** (current) | Works with any agent | Fragile, prompt bloat, no enforcement |
| **MCP Server** | Structured tools, Copilot-native | New, limited adoption, complexity |
| **Custom agent wrapper** | Full control | Build from scratch, maintenance |
| **IDE extension with agent hooks** | Native feel | Platform lock-in |

#### 3. SpecKit Integration

| Option | Pros | Cons |
|--------|------|------|
| **Sibling folder** (current) | Clean separation | Two systems to manage |
| **Orchestra consumes SpecKit** | Single source of truth | Tighter coupling |
| **SpecKit plugin/extension** | SpecKit drives everything | SpecKit becomes dependency |

#### 4. State Management

| Option | Pros | Cons |
|--------|------|------|
| **YAML files** (current) | Human-readable, git-friendly | No validation, manual updates |
| **SQLite/JSON DB** | Queryable, typed | Less git-friendly |
| **Git branches as state** | Native to workflow | Complex, branch pollution |

### Key Questions to Answer

1. **Who runs Orchestra?** Human orchestrator? Automated agent? Both?
2. **What's the minimum viable interface?** CLI? VS Code command palette? Chat?
3. **How does it discover project structure?** Config file? Auto-detect? Both?
4. **How does verification work at scale?** Manual review? Automated checks? AI verification?
5. **What's the handover mechanism?** Files? API? Agent-to-agent protocol?

### Current Lean: MCP Server + Drop-in Folder + CLI

```
Orchestra = MCP Server + Drop-in folder + CLI
```

- **MCP Server**: Exposes tools for agent interaction (prepare-task, validate-handover, signal-complete)
- **Drop-in folder**: `.orchestra/` remains the state/config store
- **CLI**: `orchestra init`, `orchestra status`, `orchestra next-task` for human orchestrators

This gives us:
- Works with Copilot/Claude via MCP
- Works without agents via CLI
- No platform lock-in
- Git-trackable state

### Updated Folder Structure (from restructure work)

```
.orchestra/
├── orchestrator/                    # Orchestrator role
│   ├── .orchestrator-only/          # HIDDEN from implementor
│   │   ├── manifest.yaml            # Sprint task definitions
│   │   ├── progress.yaml            # Sprint progress tracking
│   │   ├── verification/            # Task verification criteria
│   │   └── preflight/               # Orchestrator prep checklists
│   ├── scripts/                     # Orchestrator automation
│   │   ├── task-closeout-check.ps1
│   │   ├── prepare-handover.ps1
│   │   ├── handover-validate.ps1
│   │   ├── accept-signal-check.ps1
│   │   └── verification-audit.ps1
│   └── results/                     # Verification results
├── implementor/                     # Implementor role
│   ├── .implementor-only/           # HIDDEN from orchestrator
│   │   └── scripts/
│   │       ├── validate-handover.ps1
│   │       └── pre-signal-check.ps1
│   └── artifacts/
├── common/                          # Shared resources
│   ├── scripts/                     # set-env.ps1, check-utils.ps1
│   └── templates/                   # Handover templates
├── handover/                        # TRANSIENT exchange zone
│   ├── agent_readme.md
│   ├── current-task.md
│   └── task-context.md
└── docs/                            # Persistent documentation
```

---

## User's Ideal Vision (2025-12-01)

### The VS Code Extension Model

User proposes a **VS Code extension** as the orchestration engine:

#### Workflow Steps

1. **Onboarding/Discovery**: Extension discovers current SpecKit feature branch, preps internal structure for implementation
2. **Dashboard UI**: User sees status, progress, issues, verification results in proper UI
3. **Initiate Implementation**: User triggers next task → extension spins up **orchestrator agent** with proper instructions/tools for task prep, then ends (keeping context)
4. **Implementor Phase**: Extension spins up **implementor agent** with prepared task + all instructions/context. Implementor implements, generates artifacts. Context preserved.
5. **Gate Checks**: Extension runs basic file checks (current scripts) for simple verification
6. **Verification Phase**: Extension spins up **orchestrator agent** (with context from step 3 if needed) to verify task per protocol. Failures → pass back to implementor (new agent + context). Pass → generate artifacts per protocol.
7. **Final Gate**: Extension confirms verification passed, artifacts present
8. **Logging/Metrics**: Update statuses, dashboards, failure counters, protocol adherence metrics
9. **Notifications**: Wire to mobile framework for progress, failures, status (expandable to accept commands/overrides)
10. **Advance**: Move to next task, repeat

---

## Analysis of User Vision (2025-12-01)

### What's Strong

| Aspect | Why It Works |
|--------|--------------|
| **SpecKit discovery** | Leverages existing investment, single source of truth |
| **Agent separation** (orchestrator vs implementor) | Maintains role integrity, prevents context bleed |
| **Context preservation** | Addresses #1 pain point with file-based handover |
| **Extension as conductor** | Deterministic checks + AI judgment = best of both worlds |
| **Dashboard/notifications** | Human stays informed without babysitting |
| **Loop architecture** | Task → Implement → Verify → Fix/Advance is clean |

### Critical Analysis

#### 1. Context Preservation - The Hidden Monster

> "we keep the context"

**Problem**: Technically non-trivial.

| Approach | Feasibility | Issues |
|----------|-------------|--------|
| Keep agent alive | ❌ Expensive | Timeouts, API limits, Copilot sessions die |
| Serialize conversation | ⚠️ Possible | Bloats fast, what to prune? |
| Structured memory store | ✅ Better | Build memory system (vector DB, summaries) |
| Tool-based recall | ✅ Best | Agent queries memory via MCP tools |

**Recommendation**: Context = structured artifacts + queryable memory, NOT raw conversation history.

#### 2. "Custom LLM Agent" - Clarification Needed

| Option | What It Means | Complexity |
|--------|---------------|------------|
| Copilot Chat API | Extension sends prompt to Copilot | Medium - limited tool control |
| Direct Claude/GPT API | Extension calls API directly | Medium - you pay, full control |
| Custom agent framework | Build agent loop (LangChain, etc.) | High - maintenance burden |
| MCP + Copilot | Copilot uses your MCP tools | Low-Medium - leverages existing |

**Recommendation**: **MCP + Copilot** for now, option to swap backend later.

#### 3. Agent Spin-Up/Spin-Down - The Orchestration Problem

**What you CAN do**:
- Open Copilot Chat panel programmatically
- Pre-populate prompt via `vscode.commands.executeCommand`
- Provide tools via MCP that Copilot discovers

**What you CAN'T do** (easily):
- Force Copilot to use specific tools
- Guarantee Copilot follows instructions
- Get programmatic completion signal from Copilot

**Workaround architecture**:

```
Extension                    Copilot/Agent
    │                             │
    ├── Opens chat + sends prompt ──►
    │                             │
    │◄── Agent uses MCP tools ────┤
    │                             │
    │◄── Agent calls "signal_complete" MCP tool
    │                             │
    ├── Extension detects signal, runs checks
    │                             │
    ├── Opens NEW chat for next phase ──►
```

The **MCP `signal_complete` tool** becomes the handoff mechanism.

#### 4. Verification Failures - Retry Loop

**Questions raised**:
1. How many retries before human escalation?
2. Does implementor get full failure context or summary?
3. What if implementor keeps making same mistake?

**Recommendation**: Add retry budget + failure pattern detection:

```yaml
retry_policy:
  max_attempts: 3
  escalate_after: 2  # Human notified after 2 failures
  same_error_threshold: 2  # If same error twice, escalate
```

#### 5. "Basic File Checks" - Boundary Definition

| Extension Does (Deterministic) | Agent Does (Judgment) |
|-------------------------------|----------------------|
| File exists? | Is the code correct? |
| Test passes? | Is the test meaningful? |
| No analyzer errors? | Is the architecture right? |
| Screenshot captured? | Does screenshot show correct UI? |
| CHANGELOG updated? | Is CHANGELOG entry well-written? |

**The extension is a GATE, not a JUDGE.**

#### 6. Mobile Notifications - Scope Creep Alert

**Pragmatic path**:
1. **v1**: Desktop notifications (VS Code native) ✅
2. **v2**: Webhook to Discord/Slack/Telegram ⚠️
3. **v3**: Custom mobile app ❌ (scope creep)

**Recommendation**: Design notification interface now, implement simple first:

```typescript
interface OrchestraNotifier {
  notify(event: OrchestraEvent): Promise<void>;
}
```

#### 7. SpecKit Coupling

| Model | Description | Tradeoff |
|-------|-------------|----------|
| Orchestra reads SpecKit | Orchestra parses manifest, tasks.md | Tight coupling, but single source |
| SpecKit exports to Orchestra | `speckit export --format orchestra` | Loose coupling, extra step |

**Recommendation**: Start with **Orchestra reads SpecKit** (control both), design for swap later.

#### 8. Missing: Error Recovery & State Persistence

| Scenario | Current Answer |
|----------|----------------|
| Extension crashes mid-task | ? |
| User closes VS Code | ? |
| Agent times out | ? |
| Network failure during API call | ? |

**Recommendation**: Persist state to `.orchestra/state.json` after every phase transition:

```json
{
  "current_task": 16,
  "phase": "implementing",
  "retry_count": 1,
  "last_agent_context_id": "abc123",
  "started_at": "2025-12-01T10:30:00Z"
}
```

### Refined Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    VS Code Extension                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ State Mgr   │  │ Notifier    │  │ Dashboard WebView   │  │
│  │ (persist)   │  │ (webhook)   │  │ (progress, logs)    │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────┴───────────────────────────────┐  │
│  │                   Orchestration Engine                 │  │
│  │  - Phase transitions (prep → implement → verify)      │  │
│  │  - Retry logic & escalation                           │  │
│  │  - Gate checks (deterministic)                        │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│  ┌───────────────────────┴───────────────────────────────┐  │
│  │                     MCP Server                         │  │
│  │  Tools: prepare_task, signal_complete, get_context,   │  │
│  │         validate_handover, log_issue, request_help    │  │
│  └───────────────────────┬───────────────────────────────┘  │
└──────────────────────────┼──────────────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │     Copilot / Claude    │
              │   (uses MCP tools)      │
              └─────────────────────────┘
```

### Open Questions for User

1. **Agent backend**: Copilot-only? Or option for direct Claude API?
2. **Context memory**: Accept structured artifacts as the mechanism? (No raw conversation serialization)
3. **Retry policy**: 3 attempts + human escalation acceptable?
4. **v1 notification**: Desktop-only, webhook for v2?
5. **State persistence**: `.orchestra/state.json` approach acceptable?

### Verdict

**This vision is buildable.** The core loop is sound. Main risks:
1. **Context preservation** - solved by structured memory + MCP tools
2. **Agent control** - solved by MCP `signal_complete` as handoff
3. **Scope creep** - mitigate by phasing notifications

---

## User Answers to Key Questions (2025-12-01)

### Original Questions from Brainstorm

1. **Who runs Orchestra?** 
   > "For now always assume a human, but we have to get it automated as far as possible"

2. **What's the minimum viable interface?** 
   > "If I have to babysit every step it becomes much less viable. I would say at least a CLI"

3. **How does it discover project structure?** 
   > "Some onboarding process. And you should be able to rerun this process without it being too destructive. In other words it must discover the current speckit feature branch and then transform to the orchestra mapping for tasks/progress etc"

4. **How does verification work at scale?** 
   > "There will always be human oversight, but this oversight must almost become a dashboard, which can be a checklist that checks both the progress and the compliance by the orchestrator agent (i.e. how strictly is he following protocol, failure rates, issues, logs etc)"

5. **What's the handover mechanism?** 
   > "In an ideal world some agent-to-agent communication, which doesn't exist, except if we custom implement agents to do this? Otherwise the current file based handover works, but is of course VERY rudimentary."

### Key Implications

| Answer | Design Implication |
|--------|-------------------|
| Human for now, automate later | Build for human control, design automation hooks |
| CLI minimum | CLI is MVP, extension is target |
| Non-destructive re-onboarding | Idempotent init, merge not replace |
| Dashboard for oversight | Metrics collection from day 1 |
| File-based handover acceptable | MCP tools can read/write these files |

---

## VS Code Agent API Research (2025-12-01)

### Research Question

> Can a VS Code extension programmatically invoke Copilot/agents? What are the actual APIs available?

### Verified Understanding

| Statement | Verified? | Details |
|-----------|-----------|---------|
| **Chat Participant** - invoked via `@prefix`, scopes chat interaction | ✅ Yes | `vscode.chat.createChatParticipant()` |
| **Cannot invoke the actual agent in the chat** | ✅ Yes | No API to programmatically send prompts to Copilot |
| **Direct LLM call with tools** | ✅ Yes | `vscode.lm.selectChatModels()` + `sendRequest()` with `tools` option |
| **Tools must be defined** | ✅ Yes | Either via `package.json` + `vscode.lm.registerTool()` or MCP server |

### The Three Extension Mechanisms for AI

| Mechanism | What It Does | Can You Invoke It Programmatically? |
|-----------|--------------|-------------------------------------|
| **Chat Participant** | Respond when user types `@yourparticipant` | ❌ No - user must invoke via `@` |
| **Language Model Tool** | Extend agent mode - Copilot calls YOUR tool | ❌ No - Copilot decides when to call |
| **MCP Server** | Expose tools/resources to agent mode | ❌ No - Copilot decides when to call |

**Key Finding: There is NO API to programmatically invoke Copilot/agent mode.**

### What APIs Actually Exist

#### 1. Direct LLM Access (Build Your Own Agent Loop)

```typescript
// Select a model
const [model] = await vscode.lm.selectChatModels({ 
  vendor: 'copilot', 
  family: 'gpt-4o' 
});

// Send request with tools
const response = await model.sendRequest(messages, {
  tools: myToolDefinitions,
  toolMode: vscode.LanguageModelChatToolMode.Auto
}, token);

// Handle tool calls yourself
for await (const part of response.stream) {
  if (part instanceof vscode.LanguageModelToolCallPart) {
    // YOU must invoke the tool
    const result = await vscode.lm.invokeTool(part.name, part.input, token);
    // Then send result back to LLM...
  }
}
```

**This IS building your own agent** - you control the loop, tool invocation, and iteration.

#### 2. Chat Participant (Passive - Responds to User)

```typescript
const participant = vscode.chat.createChatParticipant('orchestra.orchestrator', handler);

// Handler only runs when user types "@orchestra"
const handler: vscode.ChatRequestHandler = async (request, context, stream, token) => {
  // You have access to request.model to make LLM calls
  // You can use tools via the chat-extension-utils library
};
```

#### 3. MCP Server (Copilot Calls Your Tools)

```typescript
// Register MCP server definition
vscode.lm.registerMcpServerDefinitionProvider('orchestraProvider', {
  provideMcpServerDefinitions: () => [{
    label: 'Orchestra',
    serverDefinition: { command: 'node', args: ['server.js'] }
  }]
});
```

Your MCP server exposes tools that **Copilot agent mode** can call - but you don't control WHEN.

### What's Missing for the Vision

| Requirement | Available? | Gap |
|-------------|------------|-----|
| Start agent session programmatically | ❌ No | Cannot open chat and send prompt via API |
| Force Copilot to use specific tools | ❌ No | Copilot decides based on prompt |
| Get completion signal from Copilot | ❌ No | No callback when agent "finishes" |
| Pass context between agent sessions | ❌ No | Each chat session is independent |
| Run agent in background | ❌ No | Always requires visible chat UI |
| Access Copilot's built-in tools (@workspace, etc.) | ❌ No | Internal to Copilot |

### The Only Workaround: Build Your Own Agent

If you want **programmatic control**, you must use `vscode.lm.sendRequest()` with tools and build the agent loop yourself:

```typescript
class OrchestraAgent {
  async run(task: string): Promise<void> {
    const [model] = await vscode.lm.selectChatModels({ vendor: 'copilot', family: 'gpt-4o' });
    
    const tools = [
      this.prepareTaskTool,
      this.readFileTool,
      this.editFileTool,
      this.signalCompleteTool
    ];
    
    let messages = [
      vscode.LanguageModelChatMessage.User(ORCHESTRATOR_PROMPT),
      vscode.LanguageModelChatMessage.User(task)
    ];
    
    // Agent loop
    while (true) {
      const response = await model.sendRequest(messages, { tools }, token);
      
      for await (const part of response.stream) {
        if (part instanceof vscode.LanguageModelToolCallPart) {
          if (part.name === 'signal_complete') {
            return; // Agent done
          }
          const result = await this.invokeTool(part);
          messages.push(/* tool result */);
        }
      }
    }
  }
}
```

**Pros**: Full control, can run in background, can manage state
**Cons**: You're building an agent from scratch, uses YOUR Copilot quota, no access to Copilot's built-in tools (@workspace, etc.)

### Summary: The Hard Truth

| What You Want | Reality |
|---------------|---------|
| Extension spins up orchestrator agent | You must BUILD the agent using `vscode.lm.sendRequest()` |
| Extension spins up implementor agent | Same - build it yourself |
| Use Copilot's @workspace, file editing, etc. | ❌ Not accessible - Copilot's tools are internal |
| Agent uses MCP tools | ✅ Only if YOU build the tool-calling loop |
| Keep context between sessions | You must serialize/deserialize yourself |

### Implications for Orchestra Design

Given these constraints, the architecture options become:

| Option | Description | Feasibility |
|--------|-------------|-------------|
| **A. Full Custom Agent** | Build orchestrator + implementor agents using `vscode.lm.sendRequest()` with custom tools | ✅ Possible but significant work |
| **B. MCP + Human Chat** | Expose Orchestra tools via MCP, human uses Copilot agent mode manually | ✅ Lower effort, less automation |
| **C. Hybrid CLI + MCP** | CLI for deterministic ops, MCP for AI-assisted tasks, human triggers | ✅ Pragmatic middle ground |
| **D. Wait for APIs** | Hope Microsoft exposes programmatic agent invocation | ⚠️ No timeline, risky |

### Documentation References

- [Chat Participant API](https://code.visualstudio.com/api/extension-guides/chat) - Nov 2025
- [Language Model API](https://code.visualstudio.com/api/extension-guides/language-model) - Nov 2025  
- [Language Model Tool API](https://code.visualstudio.com/api/extension-guides/tools) - Nov 2025
- [MCP Developer Guide](https://code.visualstudio.com/api/extension-guides/mcp) - Nov 2025

---

## Built-in Tools & Subscription Research (2025-12-01)

### Question 1: Can We Access Copilot's Built-in Tools?

**Answer: ❌ NO - Built-in tools are internal to Copilot**

The tools visible in agent mode (from user's screenshot):

| Tool | What It Does | Accessible? |
|------|--------------|-------------|
| `changes` | Get diffs of changed files | ❌ Internal |
| `edit` | Edit files in workspace | ❌ Internal |
| `extensions` | Search VS Code extensions | ❌ Internal |
| `fetch` | Fetch web content | ❌ Internal |
| `githubRepo` | Search GitHub repos | ❌ Internal |
| `new` | Scaffold new workspace | ❌ Internal |
| `openSimpleBrowser` | Preview localhost | ❌ Internal |
| `problems` | Check for errors | ❌ Internal |
| `runCommands` | Run terminal commands | ❌ Internal |
| `runNotebooks` | Run notebook cells | ❌ Internal |
| `runSubagent` | Run isolated subagent | ❌ Internal |
| `runTasks` | Run VS Code tasks | ❌ Internal |
| `runTests` | Run unit tests | ❌ Internal |
| `search` | Search and read files | ❌ Internal |
| `testFailure` | Get test failure info | ❌ Internal |
| `todos` | Manage todo list | ❌ Internal |
| `usages` | Find symbol usages | ❌ Internal |

From documentation:
> "The list of tools consists of **built-in tools**, tools registered by extensions, and tools from MCP servers. You can contribute to agent mode via **extensions or MCP servers**."

**`vscode.lm.tools` only lists tools registered by extensions - NOT built-in tools.**

### What Building Our Own Tools Looks Like

We must recreate capabilities using VS Code APIs:

```typescript
// Example: Our own "edit" tool
const editFileTool: LanguageModelChatTool = {
  name: 'edit_file',
  description: 'Edit a file in the workspace',
  inputSchema: {
    type: 'object',
    properties: {
      filePath: { type: 'string', description: 'Absolute path to file' },
      oldContent: { type: 'string', description: 'Text to replace' },
      newContent: { type: 'string', description: 'Replacement text' }
    },
    required: ['filePath', 'oldContent', 'newContent']
  }
};

// Implementation using VS Code APIs
class EditFileTool implements vscode.LanguageModelTool<EditParams> {
  async invoke(options: vscode.LanguageModelToolInvocationOptions<EditParams>) {
    const { filePath, oldContent, newContent } = options.input;
    
    const uri = vscode.Uri.file(filePath);
    const document = await vscode.workspace.openTextDocument(uri);
    const text = document.getText();
    const newText = text.replace(oldContent, newContent);
    
    const edit = new vscode.WorkspaceEdit();
    edit.replace(uri, new vscode.Range(0, 0, document.lineCount, 0), newText);
    await vscode.workspace.applyEdit(edit);
    
    return new vscode.LanguageModelToolResult([
      new vscode.LanguageModelTextPart(`File ${filePath} edited successfully`)
    ]);
  }
}
```

### Minimum Tools to Build

| Tool | VS Code APIs to Use |
|------|---------------------|
| `read_file` | `vscode.workspace.openTextDocument()` |
| `edit_file` | `vscode.WorkspaceEdit`, `applyEdit()` |
| `list_files` | `vscode.workspace.fs.readDirectory()` |
| `search_files` | `vscode.workspace.findFiles()` |
| `run_terminal` | `vscode.window.createTerminal()` |
| `get_problems` | `vscode.languages.getDiagnostics()` |
| `run_tests` | `vscode.tests.runTests()` (Testing API) |
| `grep_search` | `vscode.workspace.findFiles()` + text search |
| `git_status` | Terminal or git extension API |
| `signal_complete` | Custom - marks agent done |

### Question 2: Does `vscode.lm.sendRequest()` Use Copilot Subscription?

**Answer: ✅ YES - Uses your GitHub Copilot subscription**

From documentation:
> "Copilot's language models require consent from the user before an extension can use them."

> "VS Code is **transparent to the user regarding how extensions are using language models and how many requests each extension is sending** and how that influences their respective quotas."

> "Making the chat request might fail because... **quota limits were exceeded**"

| Aspect | Answer |
|--------|--------|
| **Model provider** | Copilot (via `vendor: 'copilot'`) |
| **Billing** | Against YOUR GitHub Copilot subscription |
| **Direct LLM API key needed?** | ❌ No - routes through Copilot |
| **Rate limits** | Yes - subject to Copilot quota |
| **Cost transparency** | VS Code shows users which extensions use how many requests |
| **Models available** | `gpt-4o`, `gpt-4o-mini`, `o1`, `o1-mini`, `claude-3.5-sonnet` |
| **Token limits** | `gpt-4o` has 64K input token limit |

### Cost Implications for Custom Agent

If we build a custom agent using `vscode.lm.sendRequest()`:
- Each LLM call counts against user's Copilot quota
- Agentic loops (multiple iterations) = multiple requests
- Tool-calling flows can generate many requests
- User sees usage in VS Code (transparency)

**Alternative: Direct API**
- Use direct OpenAI/Anthropic API keys
- User pays separately
- More control, but more setup
- Not integrated with VS Code's consent/tracking

### Summary: Development Implications

| Aspect | Reality |
|--------|---------|
| **Built-in tools** | Must rebuild from scratch using VS Code APIs |
| **LLM access** | Use Copilot subscription (no separate API key) |
| **Cost** | Each agent iteration uses Copilot quota |
| **Effort** | Significant - need to build ~10+ tools minimum |

**The good news**: VS Code APIs are comprehensive - we CAN build equivalents.
**The bad news**: Substantial development effort, can't "borrow" Copilot's tools.

**User decision**: "The development effort is worth it. The struggle we have with large projects and AI agents vs the benefit we have to leverage them correctly is worth it."

---

## Design Decisions Q&A (2025-12-01)

### Answered Questions

| # | Question | Answer |
|---|----------|--------|
| 1 | **Agent backend**: Copilot-only? Or option for direct Claude API? | Copilot is sufficient, but design to support direct model API calls in future if needed |
| 2 | **Context memory**: Accept structured artifacts as the mechanism? | Needs discussion - RAG or efficient context/memory structure (see below) |
| 3 | **Retry policy**: 3 attempts + human escalation acceptable? | 3 is sufficient, but must be configurable |
| 4 | **v1 notification**: Desktop-only, webhook for v2? | Agree - abstracted, interfaced notification system. Mechanism must be in place to generate notifications |
| 5 | **State persistence**: `.orchestra/state.json` approach acceptable? | Clarification requested (see below) |

### State Persistence Clarification

**Two types of state identified:**

#### A. Execution State (Agent-level)
What's happening *right now* in an active agent session:

```json
{
  "session_id": "abc123",
  "agent_type": "implementor",
  "current_task": 16,
  "phase": "implementing",
  "started_at": "2025-12-01T10:30:00Z",
  "last_tool_call": "edit_file",
  "retry_count": 1,
  "pending_tool_result": null
}
```

**Purpose**: If VS Code crashes mid-agent-run, can we resume? Or at least know where we were?

#### B. Progress State (Orchestra-level)
The overall sprint/task progress (what we already have in `progress.yaml`):

```yaml
current_task: 16
phase: implementation
tasks:
  16:
    status: in_progress
    attempts: 1
    started_at: 2025-12-01T10:30:00Z
```

**Purpose**: Track task completion, verification results, historical data.

#### Recommendation

| State Type | Storage | Format |
|------------|---------|--------|
| **Execution State** | `.orchestra/runtime/session.json` | JSON (ephemeral, per-session) |
| **Progress State** | `.orchestra/progress.yaml` | YAML (persistent, git-tracked) |

Execution state is optional for v1 - we can just restart failed sessions. Progress state we already have.

---

## Context/Memory Deep Dive (2025-12-01)

### The Problem

When building custom agents, we face:
1. **Within-session context**: Agent needs to remember what it did earlier in the same task
2. **Cross-session context**: Orchestrator needs context from previous tasks, implementor needs context from orchestrator's handover
3. **Token limits**: GPT-4o has 64K input tokens - can't dump everything

### Option A: Structured Artifacts Only (Current Approach)

```
.orchestra/handover/
├── current-task.md      # Orchestrator → Implementor
├── task-context.md      # Sprint-level context
└── completion-signal.md # Implementor → Orchestrator
```

**How it works**:
- Agent reads specific files at start
- Agent writes to specific files at end
- No "memory" - just file I/O

**Pros**: Simple, debuggable, git-trackable
**Cons**: No semantic search, fixed structure, manual curation

### Option B: RAG (Retrieval-Augmented Generation)

```
.orchestra/memory/
├── embeddings.db        # Vector database (SQLite + vectors)
├── chunks/              # Original text chunks
└── index.json           # Metadata
```

**How it works**:
- Embed documents (specs, code, previous outputs)
- On each agent turn, query relevant context
- Inject top-K results into prompt

**Pros**: Scales to large codebases, semantic search
**Cons**: Complexity, embedding model needed, latency

### Option C: Hierarchical Summary Memory

```
.orchestra/memory/
├── sprint-summary.md    # High-level sprint context (always loaded)
├── task-summaries/      # Per-task summaries
│   ├── task-001.md
│   └── task-016.md
└── active-context.md    # Current working memory (agent-managed)
```

**How it works**:
- Agents maintain summaries at different granularities
- Always load: sprint summary + current task summary
- Agent can request expansion of specific sections

**Pros**: Token-efficient, hierarchical, agent-controllable
**Cons**: Summaries can lose detail, requires summarization step

### Option D: Hybrid (Structured + Selective RAG)

```
.orchestra/
├── handover/            # Structured artifacts (always loaded)
│   ├── current-task.md
│   └── task-context.md
├── memory/
│   ├── codebase-index/  # RAG for codebase (on-demand)
│   └── history-index/   # RAG for past decisions (on-demand)
└── tools/
    └── query_memory     # Tool for agent to search memory
```

**How it works**:
- Core context via structured files (deterministic)
- Agent has `query_memory` tool for semantic search
- RAG only when agent asks for it

**Pros**: Best of both, agent-controlled, token-efficient
**Cons**: Most complex to build

### Recommendation

**Phase 1 (v1)**: Hierarchical Summary Memory (Option C)
- Simple to implement
- Sufficient for orchestrator/implementor handover
- Agent maintains its own `active-context.md`

**Phase 2 (v2)**: Add RAG for Codebase (evolve to Option D)
- When tasks require deep code understanding
- Agent can query codebase semantically

### Questions for User

1. **How large is typical context needed?** 
   - Just task instructions + relevant code snippets? 
   - Or full feature spec + all related files?

2. **Cross-task memory important?**
   - Does Task 17 need to know details of Task 16's implementation?
   - Or just "Task 16 completed, here's the summary"?

3. **RAG complexity acceptable?**
   - Willing to add embedding model dependency?
   - Or prefer simpler file-based approach?

### User Answers (2025-12-01)

#### Q1: Context Size

> "This depends, and brings up something we have to discuss later - **debugging**."

**Role-based context needs:**

| Role | Context Scope | Notes |
|------|---------------|-------|
| **Orchestrator** | Full spec, codebase awareness, all previous tasks | Needs comprehensive view |
| **Implementor** | Current task + relevant code/spec only | Fresh start prevents "unwanted things from memory" |

**Key insight**: Current orchestra process has implementor context "pinned down good" - keep it minimal and focused.

**Deferred topic**: Debugging workflow - where/when/how does debugging happen?

#### Q2: Cross-Task Memory

> "Implementor basically only needs access to their own task, but access to previous tasks is beneficial for code correctness and especially debugging"

**Decision**: 
- **Default**: Implementor gets current task only
- **Available**: Previous task context accessible when needed (debugging, code patterns)
- **Not loaded by default**: Prevents context pollution

#### Q3: RAG Complexity

> "Yes RAG complexity is acceptable. In the long run it will be worth it."

**Decision**: Plan for RAG, but implement incrementally.

---

## Architecture Decision: Tiered Context Model

Based on answers, the architecture should support:

```
┌─────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │ Sprint Spec │ │ All Tasks   │ │ Codebase RAG (semantic) ││
│  │ (always)    │ │ (summaries) │ │ (on-demand query)       ││
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    IMPLEMENTOR                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │ Current     │ │ Relevant    │ │ Previous Tasks          ││
│  │ Task Only   │ │ Code Files  │ │ (tool: query_history)   ││
│  │ (always)    │ │ (always)    │ │ (on-demand, for debug)  ││
│  └─────────────┘ └─────────────┘ └─────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Implementation Phases

| Phase | Scope | Memory System |
|-------|-------|---------------|
| **v1** | Task loop MVP | Structured artifacts only (current handover files) |
| **v1.5** | + Debugging | Add `query_history` tool (file-based search of past tasks) |
| **v2** | + Scale | RAG for codebase + task history |

### Deferred Discussion: Debugging

When debugging is needed:
- **Who initiates?** Orchestrator detects failure, spawns debugger?
- **What context?** Error logs + relevant code + previous task context?
- **How deep?** Same session retry vs new "debugger" agent role?

---

## References

- `.orchestra/docs/readme.md` - Current orchestrator documentation
- `.orchestra/handover/agent_readme.md` - Implementor onboarding
- `.orchestra/docs/research_log.md` - Issue/learning log
