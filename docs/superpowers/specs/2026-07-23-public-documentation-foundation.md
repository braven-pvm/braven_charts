# Braven Charts public documentation foundation

**Status:** Complete; delivered in
[PR #90](https://github.com/braven-pvm/braven_charts/pull/90) and polished in
[PR #95](https://github.com/braven-pvm/braven_charts/pull/95)

**Date:** 2026-07-23

**Scope:** pub.dev README, package media, public showcase information
architecture, hosted guides, generated API reference, and the release rules
that keep those surfaces aligned.

## Delivery status

The twelve acceptance criteria are implemented: the README has a concise
first-run path and curated family catalog; exact showcase presets and a stable
`?page=docs` hub are registry-driven; hosted Dart API documentation is deployed
under `/api/`; and CI validates catalog, snippet, media, route, and generated
surface drift. PR #90 delivered the foundation at merge commit `6892ee42`;
PR #95 polished the public layouts at merge commit `9dd53664`. Release PR #106
published 0.13.5 with successful package-quality and release-tagger checks.

On 2026-07-24 the public showcase root, Documentation route, hosted `/api/`
reference, and pub.dev package page each returned HTTP 200.

Two improvements remain intentionally separate from this completed
foundation:

- visual regression gates for public surfaces:
  shared-register item `BC-0013`;
- hosted, searchable long-form end-user guides:
  shared-register item `BC-0015`.

## Purpose

Braven Charts is moving faster than its public documentation structure. New
chart families, interaction systems, authoring surfaces, release media, and
long-form guides are currently added to whichever public surface already
exists. The result is individually useful content without a stable hierarchy.

This specification establishes one documentation system with clear jobs:

- pub.dev explains the package, proves its value, and gets a developer to a
  first chart;
- the showcase lets developers choose a chart family and inspect runnable,
  production-shaped examples;
- the documentation hub teaches concepts and routes developers to the right
  guide;
- generated Dart documentation provides exhaustive member-level API reference;
- GitHub stores the source material and contributor-facing contracts.

The goal is not to put less information online. The goal is to put each piece
of information on the surface where it is easiest to find and maintain.

## Current-state evidence

As of 0.13.0:

- `README.md`, which becomes the pub.dev Readme tab, is 887 lines and about
  55,000 characters;
- it has 31 headings, 18 fenced code samples, and a large visual catalog before
  the ordinary package sections are complete;
- release highlights, architecture explanation, chart-family marketing,
  feature inventory, tutorials, API examples, and the visual gallery all
  compete at the same level;
- the showcase already contains 23 navigation destinations, 48 page files, a
  ten-family chart catalog, and 78 package media assets;
- the showcase does not have a documentation home or a hosted generated API
  reference;
- `pubspec.yaml` sends `documentation` to a GitHub Markdown API overview, while
  pub.dev separately generates member-level documentation;
- the Pages workflow deploys only the Flutter showcase build even though CI
  already proves that Dart documentation can be generated.

The package has enough content. The missing foundation is hierarchy,
progressive disclosure, and one registry that prevents public surfaces from
drifting.

## Audience and primary jobs

### Evaluating developer

Primary question: “Can this package create the chart and interaction model I
need?”

They need:

- a visual answer in the first viewport;
- a concise capability summary;
- a chart-family chooser;
- links to exact runnable examples;
- clear platform, version, and maintenance signals.

### Implementing developer

Primary question: “How do I create my first correct chart?”

They need:

- one direct configuration example;
- one typed Grammar example;
- copyable, tested snippets;
- chart-family guides;
- concept guides for axes, interaction, streaming, and Workbench behavior.

### Advanced integrator

Primary question: “What is the exact contract and how does it compose?”

They need:

- detailed guides;
- generated API documentation;
- source links;
- artifact, table, Workbench, performance, and extension boundaries.

### Contributor or maintainer

Primary question: “Which public surfaces must change with this feature?”

They need:

- a public-content registry;
- explicit ownership and completion gates;
- generated sections and drift checks;
- release and media-capture rules.

## Surface contract

| Surface | One job | Content it owns | Content it must not own |
| --- | --- | --- | --- |
| pub.dev Readme | Explain, prove, start | Synopsis, evergreen highlights, curated family sampler, minimal code, documentation routes, compact visual appendix | Full API inventory, release notes, exhaustive feature matrix, long tutorials |
| pub.dev metadata | Package identity | Description, platforms, topics, screenshots, homepage, documentation, repository, issue tracker | Narrative documentation |
| Showcase Gallery | Visual product tour | Curated production-shaped compositions and capability discovery | Exhaustive API prose |
| Showcase chart guides | Runnable learning | Family-specific examples, controls, presets, Data/Source views, exact deep links | General package marketing |
| Showcase documentation hub | Documentation wayfinding | Getting started, guide taxonomy, concepts, recipes, search routes, API entry | Duplicate member-level API descriptions |
| Hosted Dart documentation | Exhaustive reference | Public libraries, classes, constructors, members, categorized API topics | Showcase compositions and release marketing |
| `doc/*.md` | Source material | Long-form guide source and contributor-reviewable contracts | A second unrelated navigation system |
| Changelog | Release history | Version-specific additions, changes, fixes, migrations | Evergreen product synopsis |
| GitHub contributor docs | Maintenance workflow | Architecture, integration, contribution, release, and internal completion rules | Primary end-user landing experience |

This boundary is mandatory. “Current highlights” on pub.dev must not become a
second changelog.

## Public information flow

```text
pub.dev
  ├─ decide whether Braven Charts fits
  ├─ copy a minimal example
  └─ choose a destination
       ├─ runnable chart family ──> showcase chart guide
       ├─ feature or concept ─────> showcase documentation hub
       ├─ exact symbol ───────────> hosted generated API reference
       └─ release/change ─────────> changelog

showcase documentation hub
  ├─ get started
  ├─ chart families
  ├─ interaction and display
  ├─ data, authoring, and live updates
  ├─ Workbench, artifacts, and export
  └─ API reference
```

No public page should force a developer to understand the repository layout
before they can find documentation.

## Pub.dev foundation

### Page order

The README must use this order:

1. Product synopsis
2. Evergreen feature highlights
3. Choose a chart family
4. Install and quick start
5. Documentation routes
6. Package and support links
7. More visual examples
8. License

Installation must no longer appear after the complete media catalog and
feature inventory.

### 1. Product synopsis

The first viewport must answer:

- What is it?
- What does it look like?
- Why is it different?
- Where can I try it?

Required content:

- package name and existing status badges;
- one sentence of no more than 30 words;
- one supporting paragraph of no more than 80 words;
- one chart-only flagship image linked to the exact live showcase example;
- two visible routes: **Open showcase** and **Get started**.

Recommended synopsis:

> Braven Charts is a native Flutter charting system for interactive,
> production-grade data visualization.

Supporting copy should mention the custom Flutter rendering pipeline, chart
family breadth, and typed authoring without enumerating every feature.

The hero must be chart-first, not application-chrome-first. A phone screenshot
can remain in the pub.dev screenshot gallery but should not be the README hero.

The approved hero media contract is one continuous, axis-free editorial strip:

- all ten families appear in one row;
- the canvas is `2400 × 280` (8.57:1);
- plot cells are flat and separated by hairlines, never framed as cards or
  phones;
- labels are compact overlays, not separate title bars;
- charts use richer, production-shaped geometry while omitting axes, grids,
  legends, and interaction chrome.

### 2. Evergreen feature highlights

Use no more than six groups. A group is a stable product capability, not the
latest release item.

Recommended groups:

1. **Ten chart families** — Cartesian, partition-radial, financial, and polar
   families with mixed analytical compositions.
2. **Interaction and selection** — zoom, pan, tracking, tooltips, annotations,
   durable selection, and linked brushing.
3. **Multi-axis analysis** — independent axes, normalization, synchronized
   charts, navigators, and persistent value summaries.
4. **Typed authoring and source** — immutable configuration, checked Grammar,
   fluent modifiers, and generated Dart.
5. **Live and efficient rendering** — cached custom rendering, bounded
   streaming, and frame-coalesced updates.
6. **Product-ready chart surfaces** — Chart/Data/Split/Source Workbench,
   portable artifacts, tables, CSV, themes, accessibility, and state UX.

Each group gets:

- a title;
- one sentence of 20 words or fewer;
- one descriptive deep link to the most relevant showcase or documentation
  route.

Do not add a seventh group for a release. Improve or replace an existing group.

### 3. Choose a chart family

Every built-in family must appear exactly once in the primary family chooser:

- Line
- Area
- Range Area
- Bar
- Scatter
- Candlestick
- Pie
- Donut
- Concentric Donut
- Polar Column / Rose

The primary family chooser uses two families per row on pub.dev. Each family
contains:

- family name;
- one “best for” sentence;
- one deterministic two-up strip containing two equal 16:9 captures;
- a link to the exact family route;
- named links for both curated examples.

Examples:

- Range Area may show an interval composition and link to the forecast fan;
- Bar may show ordinary comparison plus a waterfall or range composition;
- Donut may use an animation because selection-aware center content is
  behavioral;
- Candlestick may show typed OHLC plus a linked analytical overlay.

Exactly two examples are shown for each family. The first proves the family at
a glance; the second demonstrates a materially different data contract,
composition, or analytical use. More examples belong on the family’s showcase
page.

Family strips are generated at `1944 × 540`: two `960 × 540` (16:9) captures
separated by a fixed 24-pixel gutter. This makes the two-image layout
independent of Markdown renderer behavior and keeps every chooser row uniform.

Animation is used only when motion communicates behavior that a still cannot:

- selection;
- tracking;
- zoom or pan;
- live buffering;
- entrance or topology-changing updates.

Animations must respect the existing package-media size gate and have a useful
first frame because pub.dev uses first frames in some static contexts.

### 4. Install and quick start

This section contains:

- `pubspec.yaml` dependency;
- Dart and Flutter minimum versions;
- one direct immutable-configuration example;
- one typed `BravenChart.of(rows)` example;
- links to radial, live, multi-axis, and Workbench examples.

Code budgets:

- direct example: 35 lines or fewer;
- Grammar example: 25 lines or fewer;
- no more than two complete examples in the README;
- every snippet must compile in an automated test;
- advanced options belong behind descriptive links.

The direct example should teach the smallest complete `BravenChartPlus`
composition. It must not include crosshair, tooltip, styling, axes, and
normalization merely to advertise their existence.

The Grammar example should use the same small dataset or same conceptual chart
so developers compare authoring styles rather than unrelated products.

### 5. Documentation routes

Use task-oriented groups rather than one flat list of filenames:

- **Get started**
- **Choose a chart**
- **Interaction and display**
- **Authoring and data**
- **Workbench and portability**
- **API reference**
- **Release and support**

Every link name must describe its destination. Do not use “learn more”, “read
more”, or “click here”.

The main documentation link must point to the showcase documentation hub.
Member-level reference must point to the hosted generated API documentation.

### 6. Package and support links

Keep this compact:

- changelog;
- compatibility/version policy;
- issue tracker;
- contributing;
- repository;
- license.

Do not repeat metadata already visible in pub.dev’s side panel unless the link
is required for the developer journey.

### 7. More visual examples

This is the only broad visual gallery on the README.

Rules:

- place it after install, starter code, and documentation;
- use three items per row as the default at pub.dev’s content width;
- four items per row are allowed only for simple, legible radial or thumbnail
  compositions;
- use 12–18 examples, not the complete media directory;
- group by user question or capability, not by release;
- every image links to an exact route and preset;
- do not repeat the family chooser’s primary image;
- captions stay parallel and concise.

Every gallery asset must be exactly 16:9. Static captures use `1920 × 1080`;
animated captures use `800 × 450`, including their first frame. Rows contain
exactly three images. The initial curation includes three genuine interaction
animations so motion is visible without compromising row consistency.

Recommended groups:

- analytical compositions;
- interaction and live behavior;
- density and navigation;
- business and financial charts;
- uncertainty and ranges;
- radial and polar compositions;
- themes and presentation when a complete three-item row is justified.

The showcase remains the complete catalog.

### README content budgets

These are maintainability limits, not scoring targets:

- synopsis: at most 110 words;
- feature groups: at most 6;
- primary chart-family examples: exactly 20 images, composited into 10 strips;
- full code examples: at most 2;
- final visual appendix: 12–18 images;
- no prose section over 180 words without a link to a deeper guide;
- no public API member inventory;
- target total length: 300–450 Markdown lines.

A longer README requires an explicit documentation review, not an automatic
budget increase.

## Showcase documentation foundation

### Navigation model

The current flat feature rail is useful for development but does not scale as
the public documentation index.

Add a top-level **Documentation** destination after Gallery and Chart Types.
Its stable direct route is:

```text
?page=docs
```

The documentation home uses six task-oriented groups:

1. Get started
2. Chart families
3. Interaction and display
4. Data, authoring, and live updates
5. Workbench, artifacts, and export
6. API reference

Existing interactive pages remain runnable destinations. The documentation
home becomes the stable wayfinding layer over them.

### Documentation home

The first viewport contains:

- “Build your first chart” as the primary action;
- search or quick filtering once the catalog warrants it;
- “Choose a chart family”;
- “Browse API reference”;
- current package version and compatibility.

Below the first viewport:

- task cards for the six documentation groups;
- popular recipes;
- chart-family guide index;
- direct links to generated API documentation and release notes.

The page should use the showcase’s existing visual language. It must not become
a grid of equal-weight cards. Getting started, family selection, and API search
must remain visually dominant.

### Guide taxonomy

#### Get started

- Install
- First direct chart
- First Grammar chart
- Data and series basics
- Interaction basics
- Run the showcase locally

#### Chart families

- Line and Area
- Range Area
- Bar
- Scatter
- Candlestick
- Pie
- Donut
- Concentric Donut
- Polar Column and Rose

#### Interaction and display

- Tracking, tooltips, and value summaries
- Selection and linked brushing
- Zoom, pan, and navigators
- Annotations
- Axes and normalization
- Themes and accessibility
- Loading and empty states

#### Data, authoring, and live updates

- Immutable configuration
- Typed Grammar
- Fluent modifiers
- Generated source
- Live data and buffering
- Performance

#### Workbench, artifacts, and export

- Chart Workbench
- Data tables and CSV
- Portable artifacts
- Hydration and runtime bindings
- Document comparison

#### API reference

- Public libraries
- Core widgets
- Series and data models
- Configuration
- Controllers
- Artifacts and tables
- Generated fluent surface

### Page templates

Every end-user guide should use the same content order:

1. What this solves
2. Runnable example
3. Minimal code
4. Key decisions
5. Common variations
6. Interaction and accessibility
7. Data, Workbench, and artifact behavior where applicable
8. API reference links
9. Related guides

Chart-family pages additionally include:

- best-for and avoid-when guidance;
- data contract;
- one basic composition;
- curated presets;
- family-specific boundaries.

## Generated API reference

### Recommended model

Use the official `dart doc` output rather than building a second API parser in
the Flutter application.

Deploy it in the same GitHub Pages artifact as the showcase:

```text
https://braven-pvm.github.io/braven_charts/       showcase
https://braven-pvm.github.io/braven_charts/api/  generated API reference
```

This keeps the reference in the showcase’s public documentation deployment
without duplicating Dart’s public-library and member model.

The showcase Documentation page links to `/braven_charts/api/`. The generated
reference header links back to the showcase and Documentation home.

### Generation

Add `dartdoc_options.yaml` for:

- package categories;
- category order;
- source links tied to the deployed revision;
- Braven Charts favicon;
- a small header linking to Showcase, Documentation, GitHub, and pub.dev;
- warning policy.

Use existing `doc/*.md` files as category source where their content is
end-user appropriate. Contributor-only documents such as release and
chart-family integration contracts do not become top-level user categories.

The Pages workflow should:

1. resolve package dependencies;
2. analyze and test as already required;
3. build the Flutter showcase with `/braven_charts/` base href;
4. run `dart doc --output=<staging>/api .`;
5. copy or generate the documentation header assets;
6. place the output under `example/build/web/api`;
7. verify `index.html` and `index.json`;
8. upload one Pages artifact.

Generated API files remain build artifacts and must not enter the pub package
archive.

### Why not a custom Flutter API renderer

A custom renderer would need to reproduce public-library discovery, symbol
identity, signatures, inheritance, source linking, Markdown rendering, and
search. It would create a second API truth and a new compatibility burden.

The Flutter showcase should own discovery and curated learning. Dart’s
generator should own exhaustive member reference.

## Public documentation registry

### Source of truth

Add a package-neutral registry under:

```text
doc/public_catalog.json
```

It owns public documentation metadata, not rendering configuration.

Suggested schema:

```json
{
  "schemaVersion": 1,
  "features": [],
  "chartFamilies": [],
  "guides": [],
  "gallery": []
}
```

Each chart family records:

- stable ID and public label;
- group;
- synopsis and best-for copy;
- showcase page and curated presets;
- primary media and optional motion media;
- long-form guide;
- API entry points;
- tested snippet IDs;
- order and release state.

Each feature records:

- stable ID;
- evergreen group;
- concise copy;
- primary showcase or docs route;
- supporting guide;
- optional media.

Each gallery entry records:

- stable ID;
- capability group;
- asset;
- alt text;
- exact page and preset;
- whether it is already used by `pubspec.yaml` or the family chooser.

### Boundary with `showcaseChartTypes`

`showcaseChartTypes` remains the runtime registry for:

- `ChartType`;
- icons and accent colors;
- preview composition;
- Flutter navigation behavior.

`public_catalog.json` owns public copy, links, assets, and documentation
placement. A drift test requires the same stable family slugs in both
registries.

This avoids putting Flutter types into documentation tooling while preventing
the public and runtime catalogs from disagreeing.

### Generated outputs

Add a focused documentation tool that can generate or verify:

- README family chooser;
- README documentation links;
- README visual appendix;
- showcase documentation catalog data;
- link and media manifest;
- version text sourced from `pubspec.yaml`.

Human-authored synopsis and connective copy remain in `README.md`. Generated
blocks use explicit markers and must not be hand-edited.

Recommended command:

```text
dart run tool/public_docs.dart --check
```

An update mode regenerates the blocks locally. CI uses check mode and fails on
drift.

## Tested snippet foundation

README and documentation snippets must come from one tested source.

Recommended layout:

```text
example/lib/snippets/
  basic_line_chart.dart
  basic_grammar_chart.dart
  basic_pie_chart.dart
  live_chart.dart
  multi_axis_chart.dart
  workbench_chart.dart
```

The first two feed README generated blocks. Others feed the documentation hub
and long-form guides.

Tests must instantiate or render each snippet. The documentation tool must fail
if a referenced snippet is missing or not in the approved snippet registry.

Do not keep one untested README copy and another runnable showcase copy.

## Maintenance rules

### New chart family

A family is public-documentation complete only when it has:

- runtime showcase catalog entry;
- public catalog entry;
- detail route;
- primary media;
- concise best-for copy;
- tested basic snippet;
- long-form guide;
- API category/member documentation;
- README generated family entry;
- direct-route test;
- release checklist evidence.

### New feature

A feature does not automatically receive a new README section.

Choose one:

- strengthen one of the six evergreen highlights;
- add a recipe or concept guide;
- add a curated gallery item;
- update an existing chart-family page;
- document it only in the changelog and API reference.

README promotion requires clear value to a first-time evaluator.

### New release

A release updates:

- version and compatibility;
- changelog;
- pub.dev screenshots when the public visual story materially improves;
- evergreen copy only when the product position changes.

Do not paste release notes into “Current highlights”.

### Media

Every public asset must have:

- stable ID;
- source capture route;
- deterministic capture method;
- descriptive alt text;
- one declared primary role;
- file-size validation;
- no duplicate placement in the same README journey.

## Quality and release gates

### Content

- first viewport passes the “what, proof, next action” test;
- feature highlights remain at six or fewer;
- every chart family appears exactly once in the primary chooser;
- every README image has useful alt text and an exact deep link;
- every link name describes its destination;
- no release-log prose appears in evergreen sections;
- long-form detail is progressively disclosed into the showcase or API docs.

### Generated consistency

- public catalog schema validates;
- public and runtime family slugs match;
- README generated blocks are current;
- every catalog route exists;
- every catalog media asset exists;
- no forbidden duplicate media role exists;
- versions in generated text match `pubspec.yaml`;
- tested snippet references exist and pass.

### Build

- `flutter analyze lib`;
- package tests;
- showcase analysis and focused documentation tests;
- README snippet tests;
- `dart doc` with the agreed warning policy;
- release showcase build;
- direct-route smoke tests for Gallery, Chart Types, Documentation, every chart
  family, and `/api/`;
- `index.json` is reachable so Dart documentation search works;
- `dart pub publish --dry-run` confirms generated API output is excluded.

### Visual review

Review pub.dev at its real content width, not only GitHub Markdown preview.

Verify:

- first desktop viewport;
- narrow/mobile pub.dev rendering;
- two-column family cards;
- three-column final gallery;
- animated first frames;
- long captions and alt text;
- dark-mode image legibility;
- showcase Documentation page at phone, tablet, and desktop widths.

## Migration plan

### Phase 1 — Foundation and registry

- approve this information architecture;
- add `public_catalog.json`;
- add schema and drift validation;
- identify primary family and gallery media;
- register tested snippets.

### Phase 2 — Pub.dev restructure

- replace the current README hierarchy;
- preserve only evergreen, decision-useful content;
- generate the family chooser, docs links, and visual appendix;
- validate every deep link against the deployed showcase;
- review the rendered pub.dev-width page locally.

### Phase 3 — Documentation home

- add `?page=docs`;
- implement the six-group information architecture;
- connect existing runnable pages and long-form guides;
- regroup showcase navigation without breaking old slugs.

### Phase 4 — Hosted generated reference

- add `dartdoc_options.yaml`;
- add categories and navigation header;
- extend Pages deployment with `/api/`;
- change `pubspec.yaml` documentation to the public Documentation hub;
- retain pub.dev’s own versioned API reference as an additional canonical
  member reference.

### Phase 5 — Ongoing generation

- generate stable README sections and showcase docs metadata;
- enforce drift in CI;
- migrate duplicated snippets to tested sources;
- update the release checklist and chart-family completion contract.

Each phase is independently reviewable. README restructuring should not wait
for a complete custom documentation renderer because the recommended generated
reference uses the official Dart toolchain.

## Acceptance criteria

The foundation is complete when:

1. a new visitor can explain the package and open a runnable example from the
   first pub.dev viewport;
2. install and first code appear before exhaustive visual material;
3. all ten chart families are represented once in a curated chooser;
4. no family has more than two primary README examples;
5. advanced examples route to exact showcase presets;
6. only two complete starter code samples remain in the README and both are
   tested;
7. documentation links are task-grouped;
8. the broad gallery is last, uses three or four small items per row, and does
   not duplicate primary media;
9. the showcase has one Documentation home with stable direct routing;
10. generated API documentation is deployed under the same Pages site;
11. one public registry drives or verifies links, media, family coverage,
    snippets, and generated README sections;
12. CI fails when any public surface drifts from that registry.

## Approved decisions

Recommended defaults:

1. **Pub.dev role:** concise product entry and starter guide, not exhaustive
   documentation.
2. **README family layout:** two cards per row; one required and at most two
   examples per family.
3. **Final gallery layout:** three per row by default; four only when legible.
4. **Highlights:** six evergreen capability groups.
5. **Showcase route:** `?page=docs`.
6. **API reference:** official `dart doc` hosted at `/api/` in the same Pages
   deployment.
7. **Registry:** package-neutral `doc/public_catalog.json` with a drift test
   against the runtime Flutter catalog.
8. **Generation:** generated README blocks plus tested shared snippets, rather
   than generating all prose.

These defaults were approved and implemented by PR #90. The remaining
long-form guide and visual-regression work is explicitly tracked above rather
than keeping this foundation specification open.
