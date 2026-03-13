# Orchestra Prompt Templates

This directory contains the **Handlebars templates** that generate agent prompts for every workflow stage in Orchestra. When the extension activates, these templates are copied to your workspace at `.orchestra/templates/prompts/` where they can be customized.

## How It Works

```
extension/templates/prompts/    →    .orchestra/templates/prompts/
       (bundled source)           (workspace copy, editable by you)
```

1. **On activation**, the extension calls `ensurePromptTemplates()` which copies each template to the workspace **only if it doesn't already exist** — your modifications are never overwritten.
2. **At runtime**, `TemplateLoader` reads templates from `.orchestra/templates/prompts/` in the workspace, compiles them with Handlebars, and caches the result.
3. **`PromptBuilder`** calls `TemplateLoader.render(templateName, context)` with the appropriate context for each workflow stage.

## Directory Structure

```
templates/
└── prompts/
    ├── prepare.hbs                   # Orchestrator: prepare task handover
    ├── implement.hbs                 # Implementor: execute task
    ├── verify.hbs                    # Orchestrator: verify completion
    ├── retry.hbs                     # Implementor: fix verification failures
    ├── sprint-review.hbs             # Controller: review sprint configuration
    ├── handover-review.hbs           # Controller: review task handover
    ├── handover-fix.hbs              # Orchestrator: fix rejected handover
    ├── code-review.hbs               # Controller: single-task code review
    ├── code-review-bulk.hbs          # Controller: bulk code review
    ├── code-review-re-review.hbs     # Controller: re-review after fixes
    ├── code-review-fix.hbs           # Implementor: fix code review issues
    ├── code-review-fix-prepare.hbs   # Orchestrator: prepare code review fix
    ├── code-review-fix-implement.hbs # Implementor: implement code review fix
    ├── _partials/                    # Reusable template fragments
    │   ├── task-header.hbs           # Tool-first action prompt header
    │   ├── spec-protocol.hbs         # Spec-first review protocol + DB access rules
    │   └── stub-hunter-mode.hbs      # Hostile review / stub detection protocol
    ├── _schema/
    │   └── context.schema.json       # JSON Schema for all template context variables
    ├── _docs/                        # Reference documentation for agents/users
    │   └── test-tier-migration-guide.md  # Test tier setup & migration guide
    └── README.md                     # This file (also copied to workspace)
```

## Template ↔ Workflow Stage Mapping

| Template                        | Role         | Stage           | Description                                |
| ------------------------------- | ------------ | --------------- | ------------------------------------------ |
| `prepare.hbs`                   | Orchestrator | PREPARE         | Create handover with verification criteria |
| `implement.hbs`                 | Implementor  | IMPLEMENT       | Execute task from handover                 |
| `verify.hbs`                    | Orchestrator | VERIFY          | Run checks + stub hunt, submit judgment    |
| `retry.hbs`                     | Implementor  | RETRY           | Address verification failures              |
| `sprint-review.hbs`             | Controller   | SPRINT_REVIEW   | Review sprint config for spec alignment    |
| `handover-review.hbs`           | Controller   | HANDOVER_REVIEW | Review handover for spec faithfulness      |
| `handover-fix.hbs`              | Orchestrator | HANDOVER_FIX    | Revise rejected handover                   |
| `code-review.hbs`               | Controller   | CODE_REVIEW     | Single-task code review                    |
| `code-review-bulk.hbs`          | Controller   | CODE_REVIEW     | Bulk code review (multiple tasks)          |
| `code-review-re-review.hbs`     | Controller   | CODE_REVIEW     | Re-review after implementor fixes          |
| `code-review-fix.hbs`           | Implementor  | CODE_REVIEW_FIX | Fix code review issues (overview)          |
| `code-review-fix-prepare.hbs`   | Orchestrator | CODE_REVIEW_FIX | Prepare guidance for code review fix       |
| `code-review-fix-implement.hbs` | Implementor  | CODE_REVIEW_FIX | Implement code review fix                  |

## Context Variables

Every template receives a context object. The full schema is in `_schema/context.schema.json`. Here are the most commonly used variables:

### `task` — Current Task

| Variable             | Type       | Description                                  |
| -------------------- | ---------- | -------------------------------------------- |
| `task.task_id`       | `number`   | User-facing task number within the sprint    |
| `task.title`         | `string`   | Task title                                   |
| `task.description`   | `string`   | Task description                             |
| `task.category`      | `string?`  | Category (INFRASTRUCTURE, INTEGRATION, etc.) |
| `task.phase_id`      | `string?`  | Phase this task belongs to                   |
| `task.status`        | `string?`  | Current status (PENDING, IMPLEMENT, etc.)    |
| `task.tdd_red_phase` | `boolean?` | Whether this is a TDD red-phase task         |

### `sprint` — Current Sprint

| Variable           | Type      | Description       |
| ------------------ | --------- | ----------------- |
| `sprint.sprint_id` | `string`  | Sprint identifier |
| `sprint.title`     | `string`  | Sprint name       |
| `sprint.status`    | `string?` | Sprint status     |

### `handover` — Task Handover (implement/verify stages)

| Variable                       | Type     | Description                              |
| ------------------------------ | -------- | ---------------------------------------- |
| `handover.title`               | `string` | Task title                               |
| `handover.description`         | `string` | Task description                         |
| `handover.acceptance_criteria` | `array`  | List of `{criterion, verification}`      |
| `handover.file_operations`     | `array`  | List of `{operation, path, description}` |
| `handover.deliverables`        | `array`  | Expected deliverables (strings)          |
| `handover.context_files`       | `array`  | Reference files (strings)                |

### `code_review` — Code Review Context

| Variable                | Type     | Description                            |
| ----------------------- | -------- | -------------------------------------- |
| `code_review.review_id` | `number` | Review ID                              |
| `code_review.status`    | `string` | PENDING, APPROVED, CHANGES_REQUESTED   |
| `code_review.summary`   | `string` | Review summary                         |
| `code_review.issues`    | `array`  | List of `{severity, description, ...}` |

### Stage-Specific Variables

| Variable         | Type      | Used In          | Description                  |
| ---------------- | --------- | ---------------- | ---------------------------- |
| `handoverPath`   | `string?` | implement        | Path to handover file        |
| `feedbackPath`   | `string?` | retry            | Path to feedback file        |
| `retryCount`     | `number?` | retry            | Current retry attempt number |
| `maxRetries`     | `number?` | retry            | Maximum allowed retries      |
| `reviewAttempt`  | `number?` | review stages    | Current review attempt       |
| `pendingCount`   | `number`  | code-review-bulk | Number of pending reviews    |
| `openIssueCount` | `number`  | code-review-fix  | Number of open issues to fix |

## Handlebars Syntax Quick Reference

### Expressions

```handlebars
{{task.title}}
{{! Simple variable }}
{{task.description}}
{{! Nested property }}
```

### Conditionals

```handlebars
{{#if task.category}}
  {{! Truthy check }}
  Category:
  {{task.category}}
{{/if}}

{{#if_eq task.status "IMPLEMENT"}}
  {{! Equality check (custom helper) }}
  Currently implementing...
{{/if_eq}}

{{#unless task.tdd_red_phase}}
  {{! Negated check }}
  Standard verification applies.
{{/unless}}
```

### Iteration

```handlebars
{{#each handover.acceptance_criteria}}
  -
  {{this.criterion}}
{{/each}}
```

### Partials

```handlebars
{{>task-header                           {{! Include a partial with params }}
    tool_description="Get your task"
    tool_name="get_current_task"
    tool_return_description="Returns task details"
}}

{{>spec-protocol                         {{! Spec protocol with variants }}
    protocol_variant="single"
    tool_alternatives="get_task, prepare_task"
}}

{{>stub-hunter-mode                      {{! Stub detection protocol }}
    stub_hunter_mode_variant="legacy"
}}
```

## Custom Helpers

The `TemplateLoader` registers these Handlebars helpers:

| Helper    | Usage                          | Description                              |
| --------- | ------------------------------ | ---------------------------------------- |
| `json`    | `{{json someObject}}`          | Pretty-print as JSON (2-space indent)    |
| `if_eq`   | `{{#if_eq a b}}...{{/if_eq}}`  | Block if `a === b`                       |
| `default` | `{{default value "fallback"}}` | Nullish coalescing (`value ?? fallback`) |
| `add`     | `{{add retryCount 1}}`         | Add two numbers                          |

## Partials

Partials live in `_partials/` and are included via `{{>partial-name}}`. They are registered automatically by filename (without `.hbs`).

### `task-header`

Renders a prominent "START HERE" block directing the agent to use its Orchestra tools first. Accepts:

- `tool_description` — What the tool does
- `tool_name` — Tool to invoke
- `tool_return_description` — What the tool returns

### `spec-protocol`

Renders the mandatory spec-first review protocol and database access prohibition rules. Accepts:

- `protocol_variant` — `"single"` for single-task review, `"bulk"` for bulk review
- `tool_alternatives` — Comma-separated tool names to suggest instead of direct DB access

### `stub-hunter-mode`

Renders the hostile code review / stub detection protocol. The full version includes compilation checks, semantic stub detection, API integration verification, and test fraud detection. Accepts:

- `stub_hunter_mode_variant` — `"legacy"` for the compact code-review variant; omit for the full verification variant with TDD support

## Customizing Templates

### Safe to Edit

You can freely modify any template in your workspace at `.orchestra/templates/prompts/`. Common customizations:

- **Adjust tone**: Change "hostile reviewer" to match your team's style
- **Add project-specific rules**: Insert your coding standards or review checklist
- **Modify acceptance criteria format**: Change how criteria are presented to agents
- **Add custom partials**: Create new `.hbs` files in `_partials/` for reuse

### Example: Adding a Custom Partial

1. Create `.orchestra/templates/prompts/_partials/my-rules.hbs`:

   ```handlebars
   ## Project Rules - All functions must have JSDoc comments - Maximum
   cyclomatic complexity: 10 - No console.log in production code
   ```

2. Include it in any template:

   ```handlebars
   {{>my-rules}}
   ```

### Updating to New Versions

When the extension updates, **new templates** are added automatically but **existing templates are never overwritten**. To pick up upstream changes:

1. Compare your template with the bundled version at `extension/templates/prompts/`
2. Merge changes manually, or delete your workspace copy to get the latest version on next activation

### Dev Mode

Set `devMode: true` in `TemplateLoader` options to bypass template caching. This enables hot-reload during development — edit a template and see changes immediately without restarting.

## Schema Validation

The full context schema is at `_schema/context.schema.json`. Use it to:

- Validate custom templates in your IDE (JSON Schema support)
- Understand all available variables and their types
- Check required vs. optional fields

## Architecture

```
PromptBuilder                    TemplateLoader                   Handlebars
     │                                │                               │
     │  render("prepare", context)    │                               │
     ├───────────────────────────────►│  load from .orchestra/...     │
     │                                │  compile if not cached        │
     │                                ├──────────────────────────────►│
     │                                │  register _partials/          │
     │                                │  register helpers             │
     │   rendered string              │◄──────────────────────────────┤
     │◄───────────────────────────────┤                               │
```

- **`PromptBuilder`** (`src/prompts/PromptBuilder.ts`) — Thin facade. Maps workflow stages to template names and assembles context objects.
- **`TemplateLoader`** (`src/prompts/TemplateLoader.ts`) — Core engine. Manages an isolated Handlebars instance, template cache, helper registration, and partial loading.
- **`ensurePromptTemplates`** (`src/prompts/ensurePromptTemplates.ts`) — Sync logic. Copies bundled templates to workspace on activation. Uses `copyFileIfNew` — never overwrites existing files.
- **`promptTypes.ts`** (`src/prompts/promptTypes.ts`) — TypeScript interfaces for `Task`, `Sprint`, `PromptContext`, `SprintReviewContext`, `CodeReviewContext`.
