# Orchestra Implementation

> **Navigation**: [Specification Index](../readme.md)

---

## Overview

This folder contains the detailed implementation plans for Orchestra, organized by phase.

## Phase Summary

| Phase | Name | Status | Description |
|-------|------|--------|-------------|
| 1 | [CLI Tool](phase-1-cli/readme.md) | Planning | Command-line orchestration tool |
| 2 | [MCP Server](phase-2-mcp/readme.md) | Not Started | Agent tool interface |
| 3 | [VS Code Extension](phase-3-extension/readme.md) | Not Started | Full orchestration engine |
| 4 | [RAG Memory](phase-4-rag/readme.md) | Not Started | Semantic search memory |

## Progress Tracking

```
Phase 1: CLI Tool
├── [ ] Design Complete
├── [ ] Implementation Complete
├── [ ] Testing Complete
└── [ ] Documentation Complete

Phase 2: MCP Server
├── [ ] Design Complete
├── [ ] Implementation Complete
├── [ ] Testing Complete
└── [ ] Documentation Complete

Phase 3: VS Code Extension
├── [ ] Design Complete
├── [ ] Implementation Complete
├── [ ] Testing Complete
└── [ ] Documentation Complete

Phase 4: RAG Memory
├── [ ] Design Complete
├── [ ] Implementation Complete
├── [ ] Testing Complete
└── [ ] Documentation Complete
```

## Dependencies

```
Phase 1 (CLI) ──────► Phase 2 (MCP) ──────► Phase 3 (Extension)
                                                    │
                                                    ▼
                                            Phase 4 (RAG)
```

- **Phase 1** creates `src/core/` - the reusable service layer
- **Phase 2** wraps core services as MCP tools
- **Phase 3** embeds MCP server + adds VS Code UI
- **Phase 4** adds RAG memory to core services

## Technology Stack

| Phase | Language | Key Dependencies |
|-------|----------|------------------|
| 1 | TypeScript | commander.js, js-yaml, chalk, simple-git |
| 2 | TypeScript | @modelcontextprotocol/sdk, Phase 1 core |
| 3 | TypeScript | vscode, Phase 2 MCP |
| 4 | TypeScript | langchain, vectordb, Phase 3 |

**Why TypeScript everywhere?**
- Shared `core/` library across all phases
- No language boundary translation
- Single toolchain (Node.js/npm)
- Direct embedding in VS Code extension

## Project Structure

```
tools/orchestra/
├── package.json              # Shared dependencies
├── tsconfig.json             # TypeScript config
├── src/
│   ├── cli.ts                # CLI entry (Phase 1)
│   ├── commands/             # CLI commands (Phase 1)
│   ├── core/                 # SHARED SERVICES (all phases)
│   │   ├── manifest.ts
│   │   ├── progress.ts
│   │   ├── verification.ts
│   │   ├── templates.ts
│   │   ├── git.ts
│   │   └── types.ts
│   ├── mcp/                  # MCP server (Phase 2)
│   └── extension/            # VS Code extension (Phase 3)
└── tests/
```

## Getting Started

Start with [Phase 1: CLI Tool](phase-1-cli/readme.md).
