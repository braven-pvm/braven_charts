# Dart format policy

Braven Charts enforces Dart formatting on every Dart file whose repository
content changes after the recorded baseline. Historical formatter drift is
grandfathered until a file is touched, so an unrelated feature branch never
needs to reformat the whole repository.

## Canonical command

Run this from the repository root:

```bash
dart run tool/check_dart_format.dart
```

The command reads `tool/dart_format_baseline.txt`, finds added, copied,
modified, or renamed Dart files under `lib`, `example/lib`, and `test`, and
passes those files to:

```bash
dart format --output=none --set-exit-if-changed
```

Committed changes since the baseline are checked. When the head is `HEAD`, the
local working tree and untracked files are checked as well. Deleted files are
ignored.

Use `--all` only to audit the historical repository baseline. It is expected
to remain red until every grandfathered file has either been touched and
formatted or a separately reviewed one-time formatting change is accepted.

## Adoption inventory

The baseline was recorded at
`367caaf8280dbdea2645d8e8a63f371b78cf1b5c` with Flutter 3.44.0 and Dart
3.12.0. Of 841 tracked Dart files in the configured scopes, 176 differed from
that formatter:

- 66 library files;
- 108 test files;
- 2 example files, including one generated public-documentation catalog.

All 176 contain formatter-level content changes; none are line-ending-only
differences. The checkout had 175 of them as CRLF and one as LF, so a one-time
rewrite would still produce a large, review-hostile diff. This inventory is
why the repository adopted changed-files enforcement instead.

## Baseline governance

The baseline is an immutable commit ID, not a moving branch name. Changing it
can exempt existing content from formatting and therefore requires a dedicated
review with:

1. an inventory of every newly exempt file;
2. the reason it cannot be formatted;
3. CI evidence for both a clean pass and a deliberately misformatted failure.

Do not advance the baseline as part of ordinary feature work.

## CI and release behavior

Package quality CI runs the canonical command from a full checkout. The
pub.dev release checklist runs the same command from a clean release branch.
This makes the automated and manual release policies identical.

The enforcement tool is covered by an isolated temporary-Git-repository test.
That test proves unchanged historical formatting is grandfathered, a changed
misformatted Dart file fails, a corrected file passes, and a new untracked
Dart file is included during local verification.
