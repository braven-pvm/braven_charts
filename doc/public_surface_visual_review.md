# Public surface visual review

The public-surface gate checks the five pre-release documentation surfaces
that share release content:

- the current `README.md`, including generated catalog blocks;
- the showcase Documentation route;
- the generated searchable guide index;
- a representative generated long-form guide; and
- the generated dartdoc API home.

It captures each surface at 390 px, 768 px, and 1440 px widths. README media is
served from the checkout, and animated GIFs are pinned to their first frame so
browser timing cannot change the review image. A second README capture at each
width uses dark color-scheme media emulation.

## Run locally

Install the pinned browser-review dependencies once:

```bash
python -m pip install -r tool/requirements-public-surface-visual.txt
```

Build the same artifact used by GitHub Pages:

```bash
cd example
flutter build web --release --base-href /braven_charts/
cd ..
dart run tool/public_guides.dart --output=example/build/web/guides
dart pub global activate dartdoc
dart pub global run dartdoc --validate-links --output example/build/web/api
```

Then run the supported preview and visual check:

```bash
python tool/public_surface_visual_check.py
```

The command first runs `dart run tool/public_docs.dart --check`, so the preview
cannot silently use stale generated README blocks. It then writes screenshots,
the rendered preview, media metadata, geometry measurements, and failures to
`build/public-surface-visual/`.

The gate compares each capture with the reviewed perceptual baselines under
`.github/visual-baselines/public-surfaces/`. It tolerates small browser
antialiasing differences, but structural changes fail the command and write
enhanced images under `build/public-surface-visual/diffs/`.

## Review and approval

1. Open `report.json` and require an empty `failures` array.
2. Review all light captures and the three dark README captures. Check text
   wrapping, card density, equal media cells, navigation, content offsets,
   guide search, long-form typography, tables, code blocks, and the guide
   table of contents.
3. Treat a changed screenshot as intentional only when the corresponding
   source or generated catalog change explains it. Attach the CI artifact to
   the PR review when visual intent is not obvious from code.
4. For an approved change, regenerate locally at the pinned viewports, inspect
   all captures, then explicitly replace the reviewed baselines:

   ```bash
   python tool/public_surface_visual_check.py --update-baselines
   ```

   Baseline replacement is disabled when `CI` is set. Commit baseline changes
   in the same PR as the source change and explain the visual intent.
5. Run the command again without `--update-baselines`; it must pass against the
   newly reviewed files before opening or approving the PR.

The README wrapper is a deterministic GitHub-flavored Markdown approximation,
not a copy of pub.dev's private/current CSS. Keep the post-publish pub.dev smoke
check in the release checklist; this gate catches source, media, and responsive
layout regressions before that final verification.
