# Orchestrator Role

This folder contains all orchestrator-specific files and scripts.

## Folder Structure

```
orchestrator/
├── .orchestrator-only/      # Hidden from implementor
│   ├── manifest.yaml        # Sprint task definitions
│   ├── progress.yaml        # Sprint progress tracking
│   ├── verification/        # Task verification criteria (YAML files)
│   ├── preflight/           # Pre-task orchestrator checklists
│   └── templates/           # Orchestrator-only templates
├── scripts/                  # Orchestrator automation scripts
│   ├── task-closeout-check.ps1
│   ├── handover-validate.ps1
│   ├── accept-signal-check.ps1
│   ├── task-coverage.ps1
│   └── verification-audit.ps1
└── results/                  # Verification results and screenshots
    ├── task-NNN-results.md
    └── screenshots/
```

## Key Workflows

### Task Closeout Check (MANDATORY before preparing next task)

```powershell
. .\.orchestra\common\scripts\set-env.ps1
.\.orchestra\orchestrator\scripts\task-closeout-check.ps1
```

### Handover Validation (before handing off to implementor)

```powershell
.\.orchestra\orchestrator\scripts\handover-validate.ps1
```

### Accept Signal Check (before verifying implementor's work)

```powershell
.\.orchestra\orchestrator\scripts\accept-signal-check.ps1
```

## Hidden Files (.orchestrator-only/)

The `.orchestrator-only/` folder contains files that the implementor should NOT read:

- **manifest.yaml**: Full sprint task list and mappings
- **progress.yaml**: Sprint progress state
- **verification/**: Hidden acceptance criteria per task
- **preflight/**: Orchestrator prep checklists

This separation prevents implementors from "gaming" the verification criteria.

## Results Storage

After verifying each task:

1. Create `results/task-NNN-results.md` with verification log
2. Save screenshots to `results/screenshots/`
3. Update progress.yaml with commit hash
