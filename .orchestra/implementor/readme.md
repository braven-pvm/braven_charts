# Implementor Role

This folder contains implementor-specific files, scripts, and artifacts.

## Folder Structure

```
implementor/
├── .implementor-only/       # Hidden from orchestrator during handover
│   ├── scripts/             # Implementor validation scripts
│   │   ├── pre-signal-check.ps1
│   │   └── validate-handover.ps1
│   ├── completion-signal.md # Active completion signal (when signaling)
│   └── task-validator.md    # Self-validation checklist
└── artifacts/               # Persistent implementor artifacts
    └── pre-signal/          # Pre-signal check logs
```

## Key Workflows

### Before Starting Work (validate handover)

```powershell
. .\.orchestra\common\scripts\set-env.ps1
.\.orchestra\implementor\.implementor-only\scripts\validate-handover.ps1
```

### Before Signaling Completion (MANDATORY)

```powershell
.\.orchestra\implementor\.implementor-only\scripts\pre-signal-check.ps1
```

This creates an artifact in `artifacts/pre-signal/` that the orchestrator checks.

### Signaling Completion

1. Run pre-signal-check.ps1 and ensure it PASSES
2. Write completion details to `.implementor-only/completion-signal.md`
3. Stage all changes: `git add -A`
4. Signal: "ready for review"

## Hidden Files (.implementor-only/)

The `.implementor-only/` folder contains files that support the implementor's work:

- **scripts/**: Validation and pre-signal check scripts
- **completion-signal.md**: Where you write your completion signal
- **task-validator.md**: Self-check before signaling

## Artifacts

The `artifacts/pre-signal/` folder stores timestamped logs of pre-signal checks.
These prove to the orchestrator that you ran the checks before signaling.

## ⚠️ YOU TOUCH IT, YOU OWN IT

When you CREATE or MODIFY any file, ALL analyzer issues in that file become YOUR responsibility.
No "pre-existing issues" excuses. Run `flutter analyze` on every file you touch and fix everything.
