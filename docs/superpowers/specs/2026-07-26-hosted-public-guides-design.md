# Hosted public guides design

**Status:** Approved for implementation under shared-register item `BC-0015`

**Date:** 2026-07-26

## Purpose

Publish the curated end-user Markdown already registered by Braven Charts as
searchable, stable guide pages in the existing GitHub Pages artifact. Keep the
showcase responsible for runnable examples, Dartdoc responsible for exhaustive
member reference, and GitHub responsible for contributor-facing source.

## User job

An implementing developer should be able to find a guide by task or chart
family, open a durable URL, read it without understanding the repository
layout, and move directly to the relevant runnable example or API reference.

## Options considered

### A. Generated static HTML under `/guides/` — selected

Generate a static index plus one HTML page per cataloged guide during the
Pages build.

Advantages:

- stable, crawlable, shareable direct URLs;
- useful content before Flutter boots and without application state;
- conventional document semantics for keyboard and screen-reader users;
- one small search index rather than another application data layer;
- guide deployment can be verified independently of showcase routing;
- Markdown source remains contributor-reviewable in the repository.

Costs:

- the generator must own safe Markdown-to-HTML conversion, heading anchors,
  link rewriting, templates, and drift checks;
- shared navigation and visual tokens must be maintained beside the Dartdoc
  header and showcase shell.

### B. Render Markdown inside the Flutter showcase — rejected

This would reuse the showcase shell but add a runtime Markdown renderer,
increase the web bundle and startup cost, weaken no-JavaScript and search
behavior, and make direct document URLs depend on Flutter query-state routing.
It would also turn the showcase into a second documentation engine rather than
the runnable learning layer defined by the foundation specification.

## Catalog model

`doc/public_catalog.json` remains the only public documentation registry.

Add:

- `guidesBaseUrl` — the deployed `/guides/` root;
- `hostedGuides` — canonical guide identity, title, group, summary, source
  file, and stable output path;
- `guideId` references from chart families and task guides.

The normalized relation allows several public destinations to share one guide
without generating duplicate content. For example, “Portable chart artifacts”
and “Data tables and CSV” can both reference the canonical Chart Artifacts
guide.

The generator must fail when:

- an ID or output path is duplicated;
- a referenced guide does not exist;
- a source file is missing;
- a path is absolute, traverses upward, or is not a stable directory path;
- cataloged source and generated relationships drift.

Only `hostedGuides` source files are rendered. Relative links to another
hosted source become hosted guide URLs. Links to non-hosted repository
documents remain GitHub source links so contributor, architecture, release,
and integration contracts do not leak into the end-user guide system.

## URL contract

```text
/braven_charts/guides/
/braven_charts/guides/chart-families/line-area/
/braven_charts/guides/chart-grammar/
/braven_charts/guides/chart-artifacts/
```

Every output is a directory with an `index.html`, preserving stable trailing
slash URLs and ordinary heading fragments. Guide paths are explicit catalog
data; they are never derived from filenames.

## Rendering and sanitization

Use the Dart-maintained `markdown` package with GitHub-flavored extensions,
HTML encoding enabled, and tag filtering enabled. Parse the generated fragment
with the Dart-maintained `html` package before templating.

The renderer:

- assigns deterministic GitHub-style IDs to headings;
- rewrites relative Markdown links through the catalog source map;
- allows only `https`, `http`, `mailto`, local heading fragments, and
  catalog-controlled relative destinations;
- adds `rel="noopener noreferrer"` to external links;
- rejects unsafe schemes and unexpected local images;
- preserves fenced code, tables, lists, blockquotes, and inline code;
- removes the source H1 because the catalog title owns page identity.

Each page includes:

- global links to Showcase, Documentation, Guides, API, pub.dev, and GitHub;
- breadcrumb and catalog summary;
- readable long-form content with a constrained line length;
- generated table of contents;
- runnable-example and API actions when the catalog supplies them;
- related guides from the same catalog group;
- a “View source on GitHub” link.

## Search and filtering

The guide index renders all catalog entries as semantic links grouped by the
six public guide groups. A labelled native search field filters title, group,
summary, and source headings in the browser. Results remain useful with
JavaScript disabled because the complete grouped index is server-rendered.

The search status uses an `aria-live="polite"` region. Empty results explain
how to recover and provide a clear-search action. Keyboard focus remains
visible and all interactive targets meet the existing 48-pixel showcase
minimum.

The generator also emits `index.json` so CI can verify guide identity, paths,
groups, and relationships without scraping HTML.

## Showcase integration

Generated catalog data exposes package version, Dart constraint, Flutter
constraint, guide base URL, and hosted guide relationships.

The Documentation first viewport replaces inventory counts with:

- current package version;
- supported Dart range;
- supported Flutter range.

The page gains a labelled guide search. Hosted guide actions open the static
guide URL; runnable examples and generated API links remain explicit secondary
destinations rather than being replaced.

README family and task-guide links use the same hosted URLs. Existing showcase
example links and `/api/` links remain unchanged.

## Build and verification

The Pages workflow generates guides into
`example/build/web/guides/` after the Flutter release build and before artifact
upload.

Required gates:

- catalog/schema and generated-output drift checks;
- generator unit tests for sanitization, link rewriting, stable anchors,
  duplicate paths, and metadata;
- Documentation widget tests for metadata, search, hosted links, keyboard
  semantics, and responsive layout;
- release web build and generated guide artifact checks;
- direct-route checks for the guide index and every guide;
- phone, tablet, and desktop screenshots of the guide index and a
  representative long-form page;
- horizontal-overflow, header/content, table/code scrolling, focus, label,
  and `aria-live` geometry/semantics checks;
- publish archive verification that generated HTML remains a build artifact.

## Accepted boundaries

- This is not a custom API renderer; symbol identity and exhaustive member
  search remain Dartdoc’s responsibility.
- Static guide search is intentionally catalog/content search, not full-text
  API search.
- Exact pub.dev CSS parity and post-publish live smoke remain release-process
  checks.
