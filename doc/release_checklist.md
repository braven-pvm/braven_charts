# Pub.dev release checklist

Run every validation from a clean release branch before publishing a Braven
Charts release.

## Package identity and ownership

- [ ] Confirm the publishing account still has access to the verified
  publisher that owns `braven_charts`.
- [ ] Confirm the MIT license and copyright holder text.
- [ ] Confirm version, changelog date, repository, issue tracker, description,
  and topics in `pubspec.yaml`.

The first version of a new package must be published interactively. Automated
GitHub publishing can be enabled on pub.dev after the package exists.

## Archive hygiene

- [ ] Run `dart pub publish --dry-run`.
- [ ] Require zero errors and zero warnings.
- [ ] Review every file in the archive list.
- [ ] Confirm no raw data, credentials, internal specs, development archives,
  vendored packages, browser binaries, or generated API docs are included.
- [ ] Keep each screenshot under 4 MB and the total package comfortably below
  pub.dev's archive limits.

## Quality gates

- [ ] `dart format --output=none --set-exit-if-changed lib example/lib test`
- [ ] `flutter analyze lib`
- [ ] Analyze the release-facing example separately.
- [ ] Run the package test suite and focused showcase widget tests.
- [ ] `dart pub global run dartdoc --no-validate-links` completes with zero
  warnings and zero errors.
- [ ] `flutter pub outdated` is reviewed.
- [ ] Run `pana` against a disposable copy of the package and review every lost
  pub point.

## Package page

- [ ] README installation and examples compile against the release version.
- [ ] `example/lib/main.dart` is concise enough for pub.dev's Example tab.
- [ ] The public API has useful `///` documentation.
- [ ] Screenshot 1 is a chart-only flagship hero and works as the package
  thumbnail without relying on showcase application chrome.
- [ ] Every README image is an individual chart or focused animation linked
      to the exact Gallery or detail page that demonstrates it.
- [ ] The README visual index uses three examples per row and includes every
      composition in the Gallery's curated tour without repeating an asset.
- [ ] The remaining screenshot slots prioritize the release's new public APIs,
      then add varied interaction/live examples. Keep Pie, Donut, Concentric,
      Polar, Cartesian, annotations, themes, and baseline fills represented in
      the README visual index without repeating the pubspec assets needlessly.
- [ ] Screenshot descriptions are specific and at most 160 characters.
- [ ] The interaction and live-stream animations show real behavior from the
  deployed showcase, remain below 4 MB each, and render from package-local
  README paths on GitHub and pub.dev.

Pub.dev accepts up to 10 PNG, JPG, GIF, or WebP screenshots, each no larger
than 4 MB. Do not use a standalone logo as a screenshot.

Regenerate the animated GIFs and current Gallery stills with:

```bash
python -m pip install selenium Pillow
python tool/capture_showcase_media.py
```

Use `--capture interaction` for the focused tracking and zoom/pan recordings,
`--capture selection` for Donut selection, `--capture live-stream` for the
buffering sequence, or `--capture tracking` and `--capture zoom-pan` when only
one interaction changed. Use `--capture interaction-still`, `--capture
stills`, `--capture pie`, `--capture bar`, `--capture donut`, `--capture
scatter`, `--capture synchronized`, or `--capture polar` for static media.
Capture browser media from a local release build with `--url
http://127.0.0.1:<port>/` before the public site has the change.

`--capture pie`, `--capture donut`, `--capture bar`, `--capture scatter`,
`--capture range-area`, `--capture synchronized`, `--capture polar`,
`--capture hero`, and `--capture interaction-still`, plus the release-specific
`--capture cartesian-0.10`, do
not take browser screenshots. They mount the same Gallery
configurations in Flutter's deterministic test renderer, call the native
preview API for individual charts, load Flutter's bundled Roboto font, and
write the returned PNG bytes. Multi-chart compositions use a deterministic
Flutter `RepaintBoundary` because no single chart owns the complete image.
Composite Donut and chart-family strips are assembled from native preview bytes
in Flutter. The hero and interaction stills preserve transient tracking state.
Browser recording remains appropriate for animated interaction and live-stream
GIFs.

## Public showcase

- [ ] `flutter build web --release --base-href /braven_charts/` succeeds from
  `example/`.
- [ ] GitHub Pages is configured to use GitHub Actions as its source.
- [ ] The deployed Gallery route loads directly and after a browser refresh.
- [ ] The deployed Pie Charts route loads directly and after a browser refresh.
- [ ] The deployed Donut Charts route loads directly and after a browser refresh.
- [ ] The deployed Concentric Donut route loads directly and after a browser refresh.
- [ ] The deployed Polar Column route loads directly and after a browser refresh.
- [ ] The deployed Candlestick route loads directly and after a browser refresh.
- [ ] The deployed Tracking & Value Display route loads directly and after a browser refresh.
- [ ] Desktop and narrow navigation, pointer interactions, and live demos are
  smoke tested from the public URL.
- [ ] Add the verified public demo URL to package metadata and README.

## Publish and post-publish

- [ ] Tag the exact release commit with the version.
- [ ] Publish without `--force` and review the final archive confirmation.
- [ ] Transfer the package to the verified publisher if applicable.
- [ ] Confirm README, changelog, example, screenshots, license, platforms, and
  generated API docs on pub.dev.
- [ ] Review the pub points report and smoke-test installation in a clean
  Flutter application.

Official references:

- <https://dart.dev/tools/pub/publishing>
- <https://dart.dev/tools/pub/pubspec>
- <https://pub.dev/help/scoring>
- <https://docs.flutter.dev/deployment/web>
