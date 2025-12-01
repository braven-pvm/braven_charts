# Orchestra Implementation Plan

> **Navigation**: [Index](readme.md) | **Prev**: [Example Files](06-appendices/example-files.md)

---

## Overview

This document outlines the implementation plan for Orchestra based on the decisions captured in `.orchestra/docs/solution-options.md`.

## Chosen Architecture

Based on the brainstorming and Q&A sessions, the recommended architecture is:

```
Orchestra = VS Code Extension + MCP Server + CLI + Drop-in Folder
```

| Component | Purpose |
|-----------|---------|
| **VS Code Extension** | Orchestration engine, dashboard, state management |
| **MCP Server** | Agent tool interface (prepare_task, signal_complete, etc.) |
| **CLI** | Human orchestrator interface, automation scripts |
| **Drop-in Folder** | `.orchestra/` state store, git-trackable |

## Key Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Agent backend** | Copilot (via `vscode.lm`) | Sufficient for now, no separate API key needed |
| **Context memory** | Tiered model | Structured artifacts + optional RAG |
| **Retry policy** | 3 attempts, configurable | Sufficient with escalation path |
| **Notifications** | Abstracted interface | Desktop v1, webhook v2 |
| **State persistence** | Dual: session + progress | Ephemeral runtime + git-tracked progress |
| **RAG complexity** | Accepted | Worth it long-term, phase in incrementally |

## Implementation Phases

### Phase 1: CLI Tool MVP

**Goal**: Replace manual orchestrator operations with scriptable commands.

**Language**: TypeScript (Node.js) - shared with future VS Code extension

**Deliverables**:
```
tools/orchestra/
├── package.json
├── tsconfig.json
├── src/
│   ├── cli.ts                # CLI entry point (commander.js)
│   ├── commands/
│   │   ├── init.ts           # Initialize sprint from spec
│   │   ├── prepare.ts        # Prepare task for implementor
│   │   ├── verify.ts         # Run verification checks
│   │   ├── complete.ts       # Commit and advance
│   │   └── status.ts         # Show current state
│   └── core/                 # REUSABLE IN EXTENSION
│       ├── manifest.ts       # Manifest parsing/writing
│       ├── progress.ts       # Progress tracking
│       ├── verification.ts   # Verification engine
│       ├── templates.ts      # Template processing
│       ├── git.ts            # Git operations
│       └── types.ts          # Shared type definitions
└── tests/
```

**Key Insight**: The `src/core/` folder becomes the shared library that both CLI and VS Code extension import.

**Commands**:
```bash
orchestra init --spec specs/011/spec.md    # Initialize sprint
orchestra prepare --task 3                  # Prepare task handover
orchestra verify                            # Run verification
orchestra complete "feat: add config"       # Complete and advance
orchestra status                            # Show progress
```

**Success Criteria**:
- [ ] `orchestra init` generates manifest from spec
- [ ] `orchestra prepare` generates handover from templates
- [ ] `orchestra verify` runs all checks, returns structured report
- [ ] `orchestra complete` updates progress, prepares next task
- [ ] All operations idempotent and safe to retry

---

### Phase 2: MCP Server

**Goal**: Expose Orchestra operations as tools for Copilot/agents.

**Deliverables**:
```
tools/orchestra-mcp/
├── server.ts             # MCP server entry point
├── tools/
│   ├── prepare_task.ts
│   ├── signal_complete.ts
│   ├── get_context.ts
│   ├── validate_handover.ts
│   ├── log_issue.ts
│   └── request_help.ts
└── package.json
```

**Tools Exposed**:
| Tool | Purpose | Who Uses |
|------|---------|----------|
| `prepare_task` | Get current task details | Orchestrator |
| `signal_complete` | Mark task done, trigger verification | Implementor |
| `get_context` | Retrieve relevant context | Both |
| `validate_handover` | Check handover completeness | Implementor |
| `log_issue` | Record issues/blockers | Both |
| `request_help` | Escalate to human | Both |

**Success Criteria**:
- [ ] MCP server starts and registers with VS Code
- [ ] Tools callable from Copilot agent mode
- [ ] Tools read/write `.orchestra/` state correctly
- [ ] `signal_complete` triggers verification flow

---

### Phase 3: VS Code Extension

**Goal**: Full orchestration engine with custom agents.

**Deliverables**:
```
extensions/orchestra/
├── src/
│   ├── extension.ts           # Entry point
│   ├── orchestration/
│   │   ├── engine.ts          # Phase transitions
│   │   ├── state.ts           # State management
│   │   └── retry.ts           # Retry logic
│   ├── agents/
│   │   ├── orchestrator.ts    # Orchestrator agent
│   │   ├── implementor.ts     # Implementor agent
│   │   └── tools/             # Custom LM tools
│   │       ├── read_file.ts
│   │       ├── edit_file.ts
│   │       ├── run_terminal.ts
│   │       └── ...
│   ├── ui/
│   │   ├── dashboard.ts       # WebView dashboard
│   │   └── notifications.ts   # Notification system
│   └── mcp/
│       └── server.ts          # Embedded MCP server
├── package.json
└── tsconfig.json
```

**Custom Tools to Build**:
| Tool | VS Code API |
|------|-------------|
| `read_file` | `vscode.workspace.openTextDocument()` |
| `edit_file` | `vscode.WorkspaceEdit` |
| `list_files` | `vscode.workspace.fs.readDirectory()` |
| `search_files` | `vscode.workspace.findFiles()` |
| `run_terminal` | `vscode.window.createTerminal()` |
| `get_problems` | `vscode.languages.getDiagnostics()` |
| `run_tests` | `vscode.tests.runTests()` |
| `signal_complete` | Custom - marks agent done |

**Success Criteria**:
- [ ] Extension activates on `.orchestra/` detection
- [ ] Can spawn orchestrator agent programmatically
- [ ] Can spawn implementor agent programmatically
- [ ] Agents use custom tools successfully
- [ ] State persists across sessions
- [ ] Dashboard shows progress

---

### Phase 4: RAG Memory

**Goal**: Semantic search across codebase and history.

**Deliverables**:
```
.orchestra/memory/
├── embeddings.db        # Vector database
├── chunks/              # Original text chunks
└── index.json           # Metadata
```

**Tools Added**:
| Tool | Purpose |
|------|---------|
| `query_codebase` | Semantic search in project files |
| `query_history` | Search past task context |

**Success Criteria**:
- [ ] Codebase indexed on initialization
- [ ] Agents can query semantically
- [ ] Relevant context retrieved accurately
- [ ] Token usage stays within limits

---

## Context Model

### Orchestrator Context

| Layer | Content | Loading |
|-------|---------|---------|
| **Always** | Sprint spec, manifest, progress | Automatic |
| **Summaries** | All task summaries | Automatic |
| **On-demand** | Full task details, code files | Via tools |

### Implementor Context

| Layer | Content | Loading |
|-------|---------|---------|
| **Always** | Current task only | Automatic |
| **Always** | Relevant code files | Automatic |
| **On-demand** | Previous tasks | Via `query_history` tool |

**Key Principle**: Implementor starts fresh to prevent context pollution.

---

## Workflow: Full Task Loop

```
┌──────────────────────────────────────────────────────────────────┐
│  1. DISCOVERY                                                     │
│     Extension detects SpecKit branch → loads manifest             │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  2. PREPARE                                                       │
│     Extension → spawns Orchestrator Agent                         │
│     Orchestrator → prepares handover → terminates                 │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  3. IMPLEMENT                                                     │
│     Extension → spawns Implementor Agent                          │
│     Implementor → implements → signals complete                   │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  4. GATE CHECK                                                    │
│     Extension → runs deterministic checks (files, tests, etc.)    │
│     PASS → continue │ FAIL → back to step 3 (retry)              │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  5. VERIFY                                                        │
│     Extension → spawns Orchestrator Agent (with prior context)    │
│     Orchestrator → verifies per hidden criteria                   │
│     PASS → continue │ FAIL → feedback to Implementor (step 3)    │
└───────────────────────────────┬──────────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────────┐
│  6. COMPLETE                                                      │
│     Extension → archives task, updates progress                   │
│     Extension → prepares next task → back to step 2              │
└──────────────────────────────────────────────────────────────────┘
```

---

## Retry Policy

```yaml
retry_policy:
  max_attempts: 3
  escalate_after: 2           # Notify human after 2 failures
  same_error_threshold: 2     # If same error twice, escalate
  cooldown_seconds: 0         # No delay between retries
```

---

## Notification Interface

```typescript
interface OrchestraNotifier {
  notify(event: OrchestraEvent): Promise<void>;
}

type OrchestraEvent = 
  | { type: 'task_started'; taskId: number }
  | { type: 'task_completed'; taskId: number }
  | { type: 'task_failed'; taskId: number; attempt: number; error: string }
  | { type: 'escalation'; taskId: number; reason: string }
  | { type: 'sprint_completed'; sprintId: string };
```

**v1 Implementation**: `DesktopNotifier` using `vscode.window.showInformationMessage()`

**v2 Implementation**: `WebhookNotifier` posting to Discord/Slack/Telegram

---

## State Persistence

### Runtime State (Ephemeral)

```
.orchestra/runtime/session.json
```

```json
{
  "session_id": "abc123",
  "agent_type": "implementor",
  "current_task": 16,
  "phase": "implementing",
  "started_at": "2025-12-01T10:30:00Z",
  "retry_count": 1
}
```

### Progress State (Git-tracked)

```
.orchestra/orchestrator/.orchestrator-only/progress.yaml
```

```yaml
current_task: 16
tasks:
  16:
    status: in_progress
    attempts: 1
    started_at: 2025-12-01T10:30:00Z
```

---

## Open Items

### Deferred: Debugging Workflow

| Question | Status |
|----------|--------|
| Who initiates debugging? | TBD |
| What context for debugging? | TBD |
| Same session retry vs debugger agent? | TBD |

### Future Considerations

1. **Multi-agent**: Separate agent instances for orchestrator/implementor
2. **Cross-project templates**: Sharing templates across repos
3. **Metrics dashboard**: Historical success rates, failure patterns
4. **Direct API option**: Swap Copilot for direct Claude/GPT API

---

## Next Steps

| # | Step | Owner | Status |
|---|------|-------|--------|
| 1 | Finalize Phase 1 CLI design | TBD | Not started |
| 2 | Prototype `orchestra verify` | TBD | Not started |
| 3 | Prototype `orchestra prepare` | TBD | Not started |
| 4 | Test CLI on real sprint | TBD | Not started |
| 5 | Design MCP tool schemas | TBD | Not started |
| 6 | Prototype MCP server | TBD | Not started |
