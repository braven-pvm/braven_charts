## Linked issue

Closes #

## Outcome

Describe the behavior delivered for package consumers or maintainers. Do not use the commit list as the summary.

## Scope

- In scope:
- Confirmed out of scope:

## Implementation

Explain the important runtime path, API, state, or architectural decisions. Include migration notes when public behavior changes.

## Verification

| Check | Command or scenario | Result |
| --- | --- | --- |
| Static analysis | `flutter analyze lib` | |
| Automated tests | `flutter test <relevant paths>` | |
| Full regression suite | `flutter test` | |
| Manual or visual verification | Describe platform, viewport, and exercised states | |

Attach before/after images or a recording for user-visible changes. Mark genuinely inapplicable rows as `N/A` with a reason; do not silently delete failed or skipped gates.

## Compatibility and risk

- Public API or artifact compatibility:
- Platform-specific behavior:
- Performance or rendering risk:
- Residual risk, deferred work, or follow-up issues:

## Review checklist

- [ ] The linked issue is implementation-ready and this PR satisfies its acceptance criteria.
- [ ] The diff stays within the documented scope and preserves unrelated work.
- [ ] Tests prove the requested behavior and relevant failure modes, not only construction or non-null results.
- [ ] Touched Dart files analyze with no errors, warnings, or infos.
- [ ] Public API documentation, examples, changelog, and migration guidance are updated where applicable.
- [ ] Visual changes include evidence for representative themes, sizes, and interaction states.
- [ ] Breaking changes are explicitly identified and justified.
- [ ] Verification failures, skipped checks, and residual risks are recorded above.
