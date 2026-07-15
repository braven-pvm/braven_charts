# Pub.dev release checklist

This checklist is for Braven Charts 0.1.0. Run every validation from a clean
release branch before publishing.

## Package identity and ownership

- [ ] Confirm `braven_charts` is still available on pub.dev immediately before
  the first publish.
- [ ] Confirm the publishing Google account and intended verified publisher.
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
- [ ] `dart doc` completes without unresolved references.
- [ ] `flutter pub outdated` is reviewed.
- [ ] Run `pana` against a disposable copy of the package and review every lost
  pub point.

## Package page

- [ ] README installation and examples compile against 0.1.0.
- [ ] `example/lib/main.dart` is concise enough for pub.dev's Example tab.
- [ ] The public API has useful `///` documentation.
- [ ] Screenshot 1 is the gallery hero and works as the package thumbnail.
- [ ] Additional screenshots cover multi-axis tracking, annotations, live data,
  and loading/empty states.
- [ ] Screenshot descriptions are specific and at most 160 characters.

Pub.dev accepts up to 10 PNG, JPG, GIF, or WebP screenshots, each no larger
than 4 MB. Do not use a standalone logo as a screenshot.

## Public showcase

- [ ] `flutter build web --release --base-href /braven_charts/` succeeds from
  `example/`.
- [ ] GitHub Pages is configured to use GitHub Actions as its source.
- [ ] The deployed Gallery route loads directly and after a browser refresh.
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
