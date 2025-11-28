# Verification Framework Patches

This folder contains documentation of patches applied to the speckit system to integrate verification requirements.

## Quick Start for Agents

**To apply all patches automatically**, read and follow:
→ **[apply-patches.md](./apply-patches.md)**

## Purpose

When speckit is updated, these patches may need to be reapplied. Each patch document contains:

1. **Original Content**: What the file looked like before patching
2. **Patch Content**: What was added (marked clearly)
3. **Final Result**: What the section looks like after patching
4. **Reapplication Instructions**: How to reapply if overwritten

## Patch Files

| Patch File | Target File | Description |
|------------|-------------|-------------|
| [tasks-template-patch.md](./tasks-template-patch.md) | `.specify/templates/tasks-template.md` | Adds Task Type Classification, Verification Artifacts section |
| [speckit-prompt-patch.md](./speckit-prompt-patch.md) | `.github/prompts/speckit.tasks.prompt.md` | Adds verification enforcement to task generation rules |

## Reapplication Workflow

If speckit is updated and overwrites our customizations:

1. Check each target file for missing verification sections
2. Refer to the patch documentation to see what was added
3. Apply the documented additions to the new file version
4. Verify the patches work with the updated speckit

## Patch Philosophy

- **Additive Only**: We only ADD content, never remove original speckit content
- **Clear Markers**: All additions are marked with `<!-- VERIFICATION FRAMEWORK PATCH -->` comments
- **Minimal Changes**: Smallest possible additions to achieve verification integration
- **Documented Locations**: Exact line references for where patches go

## Quick Check

To verify patches are applied, search for:
```
<!-- VERIFICATION FRAMEWORK PATCH -->
```

If this marker is missing from the target files, reapply the patches.
