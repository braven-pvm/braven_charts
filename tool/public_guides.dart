import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:markdown/markdown.dart' as markdown;

import 'public_docs_support.dart';

const _catalogPath = 'doc/public_catalog.json';
const _pubspecPath = 'pubspec.yaml';
const _defaultOutputPath = 'example/build/web/guides';

typedef HostedGuide = ({
  String id,
  String title,
  String group,
  String summary,
  String sourcePath,
  String path,
});

typedef GuideAction = ({String label, String url});
typedef GuideHeading = ({int level, String id, String title});

class PublicGuideGenerationResult {
  const PublicGuideGenerationResult({
    required this.guideCount,
    required this.outputDirectory,
    required this.paths,
  });

  final int guideCount;
  final Directory outputDirectory;
  final List<String> paths;
}

void main(List<String> arguments) {
  final outputArguments = arguments
      .where((argument) => argument.startsWith('--output='))
      .toList(growable: false);
  if (arguments.any((argument) => !argument.startsWith('--output=')) ||
      outputArguments.length > 1) {
    stderr.writeln(
      'Usage: dart run tool/public_guides.dart '
      '[--output=$_defaultOutputPath]',
    );
    exitCode = 64;
    return;
  }
  final outputPath = outputArguments.isEmpty
      ? _defaultOutputPath
      : outputArguments.single.substring('--output='.length);
  if (outputPath.trim().isEmpty) {
    stderr.writeln('--output must name a directory.');
    exitCode = 64;
    return;
  }

  try {
    final result = generatePublicGuides(
      root: Directory.current,
      output: Directory(outputPath),
    );
    stdout.writeln(
      'Generated ${result.guideCount} hosted guides in '
      '${result.outputDirectory.path}.',
    );
  } on Object catch (error) {
    stderr.writeln('Public guide generation failed: $error');
    exitCode = 1;
  }
}

PublicGuideGenerationResult generatePublicGuides({
  required Directory root,
  required Directory output,
}) {
  final resolvedRoot = root.absolute;
  final resolvedOutput = output.absolute;
  _requireSafeOutput(resolvedRoot, resolvedOutput);

  final catalogFile = File(
    '${resolvedRoot.path}${Platform.pathSeparator}$_catalogPath',
  );
  final pubspecFile = File(
    '${resolvedRoot.path}${Platform.pathSeparator}$_pubspecPath',
  );
  final catalog = jsonDecode(catalogFile.readAsStringSync());
  if (catalog is! Map<String, dynamic>) {
    throw const FormatException('Public catalog must be a JSON object.');
  }
  final package = readPublicDocsPackageMetadata(pubspecFile);
  final guides = _readHostedGuides(resolvedRoot, catalog);
  final byId = {for (final guide in guides) guide.id: guide};
  final bySource = {for (final guide in guides) guide.sourcePath: guide};
  _validateReferences(catalog, byId);

  final actions = _guideActions(catalog, byId);
  final headingsByGuide = <String, List<GuideHeading>>{};
  final bodiesByGuide = <String, String>{};
  for (final guide in guides) {
    final rendered = _renderMarkdown(
      root: resolvedRoot,
      catalog: catalog,
      guide: guide,
      guidesBySource: bySource,
    );
    headingsByGuide[guide.id] = rendered.headings;
    bodiesByGuide[guide.id] = rendered.html;
  }

  if (resolvedOutput.existsSync()) {
    resolvedOutput.deleteSync(recursive: true);
  }
  resolvedOutput.createSync(recursive: true);

  final generatedPaths = <String>['index.html', 'index.json'];
  _writeText(
    resolvedOutput,
    'index.html',
    _indexHtml(
      catalog: catalog,
      package: package,
      guides: guides,
      headingsByGuide: headingsByGuide,
    ),
  );
  _writeText(
    resolvedOutput,
    'index.json',
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'package': {
        'version': package.version,
        'dart': package.dartConstraint,
        'flutter': package.flutterConstraint,
      },
      'guides': [
        for (final guide in guides)
          {
            'id': guide.id,
            'title': guide.title,
            'group': guide.group,
            'summary': guide.summary,
            'path': guide.path,
            'sourcePath': guide.sourcePath,
            'headings': [
              for (final heading in headingsByGuide[guide.id]!)
                {
                  'level': heading.level,
                  'id': heading.id,
                  'title': heading.title,
                },
            ],
          },
      ],
    }),
  );

  for (final guide in guides) {
    final relativePath = '${guide.path}index.html';
    generatedPaths.add(relativePath);
    final related = guides
        .where(
          (candidate) =>
              candidate.id != guide.id && candidate.group == guide.group,
        )
        .take(4)
        .toList(growable: false);
    _writeText(
      resolvedOutput,
      relativePath,
      _guideHtml(
        catalog: catalog,
        package: package,
        guide: guide,
        body: bodiesByGuide[guide.id]!,
        headings: headingsByGuide[guide.id]!,
        actions: actions[guide.id] ?? const [],
        related: related,
      ),
    );
  }

  return PublicGuideGenerationResult(
    guideCount: guides.length,
    outputDirectory: resolvedOutput,
    paths: List.unmodifiable(generatedPaths),
  );
}

void _requireSafeOutput(Directory root, Directory output) {
  String normalized(String value) {
    final result = value.replaceAll('\\', '/').replaceAll(RegExp('/+'), '/');
    return Platform.isWindows ? result.toLowerCase() : result;
  }

  final rootPath = normalized(root.path);
  final outputPath = normalized(output.path);
  if (outputPath == rootPath || !outputPath.startsWith('$rootPath/')) {
    throw ArgumentError(
      'Guide output must be a child of the repository root: ${output.path}',
    );
  }
}

List<HostedGuide> _readHostedGuides(
  Directory root,
  Map<String, dynamic> catalog,
) {
  final rawGuides = catalog['hostedGuides'];
  if (rawGuides is! List || rawGuides.isEmpty) {
    throw const FormatException('hostedGuides must be a non-empty list.');
  }
  final ids = <String>{};
  final paths = <String>{};
  final sources = <String>{};
  final guides = <HostedGuide>[];
  for (final value in rawGuides) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Every hosted guide must be an object.');
    }
    String field(String name) {
      final result = value[name];
      if (result is! String || result.trim().isEmpty) {
        throw FormatException('Hosted guide ${value['id']}.$name is required.');
      }
      return result;
    }

    final guide = (
      id: field('id'),
      title: field('title'),
      group: field('group'),
      summary: field('summary'),
      sourcePath: field('sourcePath').replaceAll('\\', '/'),
      path: field('path'),
    );
    if (!ids.add(guide.id)) {
      throw FormatException('Duplicate hosted guide ID ${guide.id}.');
    }
    if (!paths.add(guide.path)) {
      throw FormatException('Duplicate hosted guide path ${guide.path}.');
    }
    if (!sources.add(guide.sourcePath)) {
      throw FormatException(
        'Hosted guide source ${guide.sourcePath} is registered twice.',
      );
    }
    if (guide.path.startsWith('/') ||
        guide.path.contains('..') ||
        !guide.path.endsWith('/') ||
        !RegExp(r'^[a-z0-9]+(?:[a-z0-9/-]*[a-z0-9])?/$').hasMatch(guide.path)) {
      throw FormatException(
        'Hosted guide ${guide.id} has an unsafe path ${guide.path}.',
      );
    }
    if (!(guide.sourcePath.startsWith('doc/') ||
        guide.sourcePath.startsWith('docs/guides/'))) {
      throw FormatException(
        'Hosted guide ${guide.id} source must stay under '
        'doc/ or docs/guides/.',
      );
    }
    final source = File(
      '${root.path}${Platform.pathSeparator}'
      '${guide.sourcePath.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!source.existsSync()) {
      throw FormatException(
        'Hosted guide ${guide.id} source is missing: ${guide.sourcePath}.',
      );
    }
    guides.add(guide);
  }
  return guides;
}

void _validateReferences(
  Map<String, dynamic> catalog,
  Map<String, HostedGuide> guides,
) {
  for (final collectionName in const ['chartFamilies', 'guides']) {
    final collection = catalog[collectionName];
    if (collection is! List) {
      throw FormatException('$collectionName must be a list.');
    }
    for (final value in collection) {
      if (value is! Map<String, dynamic>) continue;
      final guideId = value['guideId'];
      if (guideId != null &&
          (guideId is! String || !guides.containsKey(guideId))) {
        throw FormatException(
          '$collectionName.${value['id']}.guideId references '
          'unknown guide $guideId.',
        );
      }
    }
  }
}

Map<String, List<GuideAction>> _guideActions(
  Map<String, dynamic> catalog,
  Map<String, HostedGuide> guides,
) {
  final result = <String, List<GuideAction>>{
    for (final id in guides.keys) id: <GuideAction>[],
  };
  final seenUrls = <String, Set<String>>{
    for (final id in guides.keys) id: <String>{},
  };
  final showcaseBase = _absoluteCatalogUrl(catalog, 'showcaseBaseUrl');

  void add(String guideId, String label, String page) {
    final url = Uri.parse(
      showcaseBase,
    ).replace(queryParameters: {'page': page}).toString();
    if (seenUrls[guideId]!.add(url)) {
      result[guideId]!.add((label: label, url: url));
    }
  }

  for (final value in catalog['chartFamilies'] as List) {
    final family = value as Map<String, dynamic>;
    final guideId = family['guideId'] as String;
    add(guideId, 'Open ${family['label']} examples', family['page'] as String);
  }
  for (final value in catalog['guides'] as List) {
    final guide = value as Map<String, dynamic>;
    final guideId = guide['guideId'];
    final page = guide['page'];
    if (guideId is String && page is String) {
      add(guideId, 'Open ${guide['title']}', page);
    }
  }
  return result;
}

({String html, List<GuideHeading> headings}) _renderMarkdown({
  required Directory root,
  required Map<String, dynamic> catalog,
  required HostedGuide guide,
  required Map<String, HostedGuide> guidesBySource,
}) {
  final sourceFile = File(
    '${root.path}${Platform.pathSeparator}'
    '${guide.sourcePath.replaceAll('/', Platform.pathSeparator)}',
  );
  final markdownSource = _withoutFirstHeading(
    normalizePublicDocsText(sourceFile.readAsStringSync()),
  );
  final fragment = html_parser.parseFragment(
    markdown.markdownToHtml(
      markdownSource,
      extensionSet: markdown.ExtensionSet.gitHubWeb,
      encodeHtml: true,
      enableTagfilter: true,
    ),
  );

  final headings = <GuideHeading>[];
  final usedHeadingIds = <String, int>{};
  for (final heading in fragment.querySelectorAll('h2, h3, h4')) {
    final base = slugifyGuideHeading(heading.text);
    final occurrence = usedHeadingIds.update(
      base,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    final id = occurrence == 1 ? base : '$base-$occurrence';
    heading.id = id;
    headings.add((
      level: int.parse(heading.localName!.substring(1)),
      id: id,
      title: heading.text.trim(),
    ));
  }

  for (final element in fragment.querySelectorAll('*')) {
    element.attributes.removeWhere((name, _) {
      final attribute = name.toString().toLowerCase();
      return attribute == 'style' || attribute.startsWith('on');
    });
  }
  for (final anchor in fragment.querySelectorAll('a[href]')) {
    final href = anchor.attributes['href']!;
    anchor.attributes['href'] = _safeGuideLink(
      href: href,
      sourcePath: guide.sourcePath,
      catalog: catalog,
      guidesBySource: guidesBySource,
    );
    final resolved = Uri.tryParse(anchor.attributes['href']!);
    if (resolved?.hasScheme == true) {
      anchor.attributes['rel'] = 'noopener noreferrer';
    }
  }
  if (fragment.querySelector('img') != null) {
    throw FormatException(
      '${guide.sourcePath} contains an image. Register and copy guide media '
      'before hosting it.',
    );
  }

  return (
    html: fragment.nodes
        .map(
          (node) =>
              node is dom.Element ? node.outerHtml : _escape(node.text ?? ''),
        )
        .join('\n'),
    headings: List.unmodifiable(headings),
  );
}

String _withoutFirstHeading(String source) {
  final lines = source.split('\n');
  for (var index = 0; index < lines.length; index++) {
    if (lines[index].trim().isEmpty) continue;
    if (lines[index].startsWith('# ')) {
      lines.removeAt(index);
    }
    break;
  }
  return lines.join('\n').trim();
}

String slugifyGuideHeading(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .trim()
      .replaceAll(RegExp(r'[\s-]+'), '-');
  return slug.isEmpty ? 'section' : slug;
}

String _safeGuideLink({
  required String href,
  required String sourcePath,
  required Map<String, dynamic> catalog,
  required Map<String, HostedGuide> guidesBySource,
}) {
  if (href.startsWith('#')) return href;
  final uri = Uri.tryParse(href);
  if (uri == null) {
    throw FormatException('Invalid link in $sourcePath: $href');
  }
  if (uri.hasScheme) {
    if (!const {'https', 'http', 'mailto'}.contains(uri.scheme.toLowerCase())) {
      throw FormatException('Unsafe link scheme in $sourcePath: $href');
    }
    return href;
  }
  final resolvedPath = _resolveSourcePath(sourcePath, uri.path);
  final hosted = guidesBySource[resolvedPath];
  final fragment = uri.fragment.isEmpty ? '' : '#${uri.fragment}';
  if (hosted != null) {
    return '${_absoluteCatalogUrl(catalog, 'guidesBaseUrl')}'
        '${hosted.path}$fragment';
  }
  return '${_absoluteCatalogUrl(catalog, 'repositoryBaseUrl')}'
      '$resolvedPath$fragment';
}

String _resolveSourcePath(String sourcePath, String relativePath) {
  final segments = sourcePath.split('/')..removeLast();
  for (final segment in relativePath.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isEmpty) {
        throw FormatException(
          'Relative guide link escapes the repository: $relativePath',
        );
      }
      segments.removeLast();
    } else {
      segments.add(segment);
    }
  }
  return segments.join('/');
}

String _absoluteCatalogUrl(Map<String, dynamic> catalog, String key) {
  final value = catalog[key];
  final uri = value is String ? Uri.tryParse(value) : null;
  if (uri == null || !uri.isAbsolute || uri.scheme != 'https') {
    throw FormatException('$key must be an absolute HTTPS URL.');
  }
  return value as String;
}

void _writeText(Directory output, String relativePath, String contents) {
  final file = File(
    '${output.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

String _indexHtml({
  required Map<String, dynamic> catalog,
  required PublicDocsPackageMetadata package,
  required List<HostedGuide> guides,
  required Map<String, List<GuideHeading>> headingsByGuide,
}) {
  const groups = [
    'Get started',
    'Chart families',
    'Interaction and display',
    'Data, authoring, and live updates',
    'Workbench, artifacts, and export',
    'API reference',
  ];
  final guideBase = _absoluteCatalogUrl(catalog, 'guidesBaseUrl');
  final sections = StringBuffer();
  for (final group in groups) {
    final groupGuides = guides
        .where((guide) => guide.group == group)
        .toList(growable: false);
    if (groupGuides.isEmpty) continue;
    sections.writeln(
      '<section class="guide-group" data-guide-group>'
      '<div class="group-heading"><p class="eyebrow">Guide group</p>'
      '<h2>${_escape(group)}</h2>'
      '<p>${groupGuides.length} curated '
      '${groupGuides.length == 1 ? 'guide' : 'guides'}</p></div>'
      '<div class="guide-list">',
    );
    for (final guide in groupGuides) {
      final headingText = headingsByGuide[guide.id]!
          .map((heading) => heading.title)
          .join(' ');
      final haystack =
          '${guide.title} ${guide.group} ${guide.summary} '
                  '$headingText'
              .toLowerCase();
      sections.writeln(
        '<article class="guide-row" data-guide-card '
        'data-search="${_attribute(haystack)}">'
        '<div><p class="guide-kind">${_escape(guide.group)}</p>'
        '<h3><a href="$guideBase${guide.path}">'
        '${_escape(guide.title)}</a></h3>'
        '<p>${_escape(guide.summary)}</p></div>'
        '<a class="row-action" href="$guideBase${guide.path}" '
        'aria-label="Read ${_attribute(guide.title)}">Read guide '
        '<span aria-hidden="true">→</span></a></article>',
      );
    }
    sections.writeln('</div></section>');
  }

  return _document(
    catalog: catalog,
    package: package,
    title: 'Braven Charts guides',
    description:
        'Search curated Braven Charts guides by chart family, task, or capability.',
    bodyClass: 'guide-index',
    body:
        '''
<main id="main-content" class="page-shell">
  <header class="index-hero">
    <p class="eyebrow">Braven Charts documentation</p>
    <h1>Find the guide for the chart you need to build</h1>
    <p class="lede">Search ${guides.length} curated guides, then move directly to a runnable example or exact API reference.</p>
    <div class="compatibility" aria-label="Package compatibility">
      <span>v${_escape(package.version)}</span>
      <span>Dart ${_escape(package.dartConstraint)}</span>
      <span>Flutter ${_escape(package.flutterConstraint)}</span>
    </div>
  </header>
  <section class="search-panel" aria-labelledby="guide-search-label">
    <label id="guide-search-label" for="guide-search">Search guides</label>
    <div class="search-control">
      <input id="guide-search" type="search" autocomplete="off"
        placeholder="Try “selection”, “gauge”, or “artifacts”"
        aria-controls="guide-results" aria-describedby="guide-search-help">
      <button id="clear-search" type="button">Clear search</button>
    </div>
    <p id="guide-search-help">Matches titles, groups, summaries, and section headings.</p>
    <p id="search-status" role="status" aria-live="polite">${guides.length} guides shown</p>
  </section>
  <div id="guide-results">
    $sections
  </div>
  <section id="empty-results" class="empty-results" hidden>
    <h2>No guides match that search</h2>
    <p>Try a chart family, interaction, authoring method, or export task.</p>
    <button type="button" data-clear-search>Show all guides</button>
  </section>
</main>
<script>
(() => {
  const input = document.querySelector('#guide-search');
  const clear = document.querySelector('#clear-search');
  const cards = [...document.querySelectorAll('[data-guide-card]')];
  const groups = [...document.querySelectorAll('[data-guide-group]')];
  const status = document.querySelector('#search-status');
  const empty = document.querySelector('#empty-results');
  const apply = () => {
    const query = input.value.trim().toLowerCase();
    let visible = 0;
    cards.forEach((card) => {
      const match = !query || card.dataset.search.includes(query);
      card.hidden = !match;
      if (match) visible += 1;
    });
    groups.forEach((group) => {
      group.hidden = !group.querySelector('[data-guide-card]:not([hidden])');
    });
    empty.hidden = visible !== 0;
    status.textContent = visible === 1 ? '1 guide shown' : visible + ' guides shown';
  };
  const reset = () => {
    input.value = '';
    apply();
    input.focus();
  };
  input.addEventListener('input', apply);
  clear.addEventListener('click', reset);
  document.querySelectorAll('[data-clear-search]').forEach((button) => {
    button.addEventListener('click', reset);
  });
})();
</script>''',
  );
}

String _guideHtml({
  required Map<String, dynamic> catalog,
  required PublicDocsPackageMetadata package,
  required HostedGuide guide,
  required String body,
  required List<GuideHeading> headings,
  required List<GuideAction> actions,
  required List<HostedGuide> related,
}) {
  final guideBase = _absoluteCatalogUrl(catalog, 'guidesBaseUrl');
  final repository = _absoluteCatalogUrl(catalog, 'repositoryBaseUrl');
  final actionHtml = actions.isEmpty
      ? ''
      : '<div class="guide-actions">${actions.take(3).map((action) {
          return '<a class="action-link" href="${_attribute(action.url)}">'
              '${_escape(action.label)}</a>';
        }).join()}</div>';
  final toc = headings.where((heading) => heading.level <= 3).toList();
  final tocHtml = toc.isEmpty
      ? ''
      : '''
<nav class="table-of-contents" aria-labelledby="toc-title" tabindex="0">
  <p id="toc-title" class="toc-title">On this page</p>
  <ol>
    ${toc.map((heading) => '<li class="toc-level-${heading.level}"><a href="#${heading.id}">${_escape(heading.title)}</a></li>').join()}
  </ol>
</nav>''';
  final relatedHtml = related.isEmpty
      ? ''
      : '''
<section class="related-guides" aria-labelledby="related-title">
  <p class="eyebrow">Continue learning</p>
  <h2 id="related-title">Related guides</h2>
  <ul>
    ${related.map((item) => '<li><a href="$guideBase${item.path}">${_escape(item.title)}</a><span>${_escape(item.summary)}</span></li>').join()}
  </ul>
</section>''';

  return _document(
    catalog: catalog,
    package: package,
    title: '${guide.title} | Braven Charts guides',
    description: guide.summary,
    bodyClass: 'guide-detail',
    body:
        '''
<main id="main-content" class="page-shell">
  <nav class="breadcrumbs" aria-label="Breadcrumb">
    <a href="$guideBase">Guides</a>
    <span aria-hidden="true">/</span>
    <span>${_escape(guide.group)}</span>
  </nav>
  <header class="guide-hero">
    <p class="eyebrow">${_escape(guide.group)}</p>
    <h1>${_escape(guide.title)}</h1>
    <p class="lede">${_escape(guide.summary)}</p>
    $actionHtml
  </header>
  <div class="guide-layout">
    $tocHtml
    <article class="guide-content">
      $body
      <p class="source-link"><a href="$repository${guide.sourcePath}">View this guide’s source on GitHub</a></p>
    </article>
  </div>
  $relatedHtml
</main>''',
  );
}

String _document({
  required Map<String, dynamic> catalog,
  required PublicDocsPackageMetadata package,
  required String title,
  required String description,
  required String bodyClass,
  required String body,
}) {
  final showcase = _absoluteCatalogUrl(catalog, 'showcaseBaseUrl');
  final guides = _absoluteCatalogUrl(catalog, 'guidesBaseUrl');
  final api = _absoluteCatalogUrl(catalog, 'apiBaseUrl');
  final repository = _absoluteCatalogUrl(catalog, 'repositoryBaseUrl');
  final repositoryRoot = repository.replaceFirst('/blob/master/', '');
  return '''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="${_attribute(description)}">
  <title>${_escape(title)}</title>
  <style>$_guideCss</style>
</head>
<body class="$bodyClass">
  <a class="skip-link" href="#main-content">Skip to content</a>
  <header class="site-header">
    <nav aria-label="Primary">
      <a class="brand" href="$showcase">Braven Charts</a>
      <div class="site-links">
        <a href="$showcase">Showcase</a>
        <a href="$showcase?page=docs">Documentation</a>
        <a aria-current="${bodyClass == 'guide-index' ? 'page' : 'false'}" href="$guides">Guides</a>
        <a href="$api">API</a>
        <a href="https://pub.dev/packages/braven_charts">pub.dev</a>
        <a href="$repositoryRoot">GitHub</a>
      </div>
      <span class="package-version">v${_escape(package.version)}</span>
    </nav>
  </header>
  $body
</body>
</html>
''';
}

String _escape(String value) => const HtmlEscape().convert(value);

String _attribute(String value) => _escape(value).replaceAll('`', '&#96;');

const _guideCss = r'''
:root {
  color-scheme: light dark;
  --background: #fbf9ff;
  --surface: #ffffff;
  --surface-soft: #f3f0fb;
  --text: #22202a;
  --text-weak: #625f6a;
  --brand: #59549b;
  --brand-strong: #403b7f;
  --border: #cbc6d3;
  --code: #10182b;
  --code-text: #edf2ff;
  --focus: #0b72d0;
}
* { box-sizing: border-box; }
html { scroll-behavior: smooth; }
body {
  margin: 0;
  background: var(--background);
  color: var(--text);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-size: 18px;
  line-height: 1.6;
}
a { color: #075fb7; text-underline-offset: 3px; }
a:hover { color: #034988; }
a:focus-visible, button:focus-visible, input:focus-visible,
.table-of-contents:focus-visible {
  outline: 3px solid var(--focus);
  outline-offset: 3px;
}
.skip-link {
  position: fixed;
  left: 16px;
  top: -80px;
  z-index: 20;
  padding: 12px 16px;
  background: var(--surface);
  border: 2px solid var(--focus);
}
.skip-link:focus { top: 16px; }
.site-header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: color-mix(in srgb, var(--background) 94%, transparent);
  border-bottom: 1px solid var(--border);
  backdrop-filter: blur(12px);
}
.site-header nav {
  min-height: 64px;
  max-width: 1240px;
  margin: 0 auto;
  padding: 8px 24px;
  display: flex;
  align-items: center;
  gap: 24px;
}
.brand { color: var(--text); font-weight: 800; text-decoration: none; white-space: nowrap; }
.site-links { display: flex; align-items: center; gap: 20px; flex: 1; }
.site-links a { min-height: 48px; display: inline-flex; align-items: center; }
.site-links [aria-current="page"] { font-weight: 800; }
.package-version { color: var(--text-weak); font-size: 14px; white-space: nowrap; }
.page-shell { width: min(1180px, calc(100% - 48px)); margin: 0 auto; padding: 56px 0 80px; }
.eyebrow {
  margin: 0 0 8px;
  color: var(--brand-strong);
  font-size: 13px;
  line-height: 1.4;
  font-weight: 800;
  letter-spacing: .08em;
  text-transform: uppercase;
}
h1, h2, h3, h4 { line-height: 1.2; letter-spacing: -.025em; }
h1 { max-width: 850px; margin: 0; font-size: clamp(36px, 6vw, 64px); }
h2 { margin: 48px 0 16px; font-size: clamp(28px, 4vw, 36px); }
h3 { margin: 32px 0 12px; font-size: 24px; }
.lede { max-width: 760px; margin: 16px 0 0; color: var(--text-weak); font-size: 20px; line-height: 1.55; }
.compatibility { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 24px; }
.compatibility span {
  padding: 6px 12px;
  border: 1px solid var(--border);
  border-radius: 999px;
  background: var(--surface);
  font-size: 14px;
}
.search-panel {
  margin: 48px 0 56px;
  padding: 24px;
  background: var(--surface-soft);
  border: 1px solid var(--border);
  border-radius: 20px;
}
.search-panel label { display: block; margin-bottom: 8px; font-weight: 800; }
.search-control { display: grid; grid-template-columns: 1fr auto; gap: 12px; }
.search-control input {
  width: 100%;
  min-height: 52px;
  padding: 0 16px;
  color: var(--text);
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  font: inherit;
}
button, .action-link {
  min-height: 48px;
  padding: 10px 16px;
  color: var(--brand-strong);
  background: var(--surface);
  border: 1px solid var(--brand);
  border-radius: 12px;
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}
.search-panel p { margin: 8px 0 0; color: var(--text-weak); font-size: 14px; }
.guide-group { margin-top: 56px; }
.group-heading { display: grid; grid-template-columns: 1fr auto; align-items: end; gap: 8px 24px; }
.group-heading .eyebrow { grid-column: 1 / -1; }
.group-heading h2 { margin: 0; }
.group-heading > p:last-child { margin: 0; color: var(--text-weak); }
.guide-list { margin-top: 20px; border-top: 1px solid var(--border); }
.guide-row {
  min-height: 144px;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  align-items: center;
  gap: 24px;
  padding: 24px 8px;
  border-bottom: 1px solid var(--border);
}
.guide-row h3 { margin: 2px 0 6px; }
.guide-row h3 a { color: var(--text); }
.guide-row p { max-width: 72ch; margin: 0; color: var(--text-weak); }
.guide-row .guide-kind { color: var(--brand-strong); font-size: 13px; font-weight: 700; }
.row-action { min-height: 48px; display: inline-flex; align-items: center; gap: 8px; white-space: nowrap; }
.empty-results { padding: 48px 24px; text-align: center; border: 1px dashed var(--border); border-radius: 20px; }
.breadcrumbs { display: flex; gap: 10px; color: var(--text-weak); font-size: 15px; }
.guide-hero { padding: 40px 0 48px; border-bottom: 1px solid var(--border); }
.guide-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 24px; }
.action-link { display: inline-flex; align-items: center; text-decoration: none; }
.guide-layout { display: grid; grid-template-columns: 220px minmax(0, 1fr); gap: 56px; align-items: start; }
.table-of-contents {
  position: sticky;
  top: 88px;
  max-height: calc(100vh - 112px);
  margin-top: 48px;
  padding-right: 16px;
  overflow-y: auto;
  border-right: 1px solid var(--border);
  scrollbar-color: var(--border) transparent;
  scrollbar-gutter: stable;
  scrollbar-width: thin;
}
.toc-title { margin: 0 0 12px; font-weight: 800; }
.table-of-contents ol { margin: 0; padding: 0; list-style: none; }
.table-of-contents li { margin: 8px 0; font-size: 14px; line-height: 1.35; }
.table-of-contents .toc-level-3 { padding-left: 12px; }
.guide-content { min-width: 0; max-width: 78ch; padding-top: 8px; }
.guide-content p, .guide-content li { max-width: 76ch; }
.guide-content pre {
  max-width: 100%;
  overflow-x: auto;
  padding: 20px;
  color: var(--code-text);
  background: var(--code);
  border-radius: 14px;
  font-size: 15px;
  line-height: 1.55;
}
.guide-content :not(pre) > code {
  overflow-wrap: anywhere;
  padding: 2px 6px;
  background: var(--surface-soft);
  border: 1px solid var(--border);
  border-radius: 5px;
  font-size: .9em;
}
.guide-content table {
  display: block;
  width: max-content;
  max-width: 100%;
  overflow-x: auto;
  border-collapse: collapse;
  font-size: 16px;
}
.guide-content th, .guide-content td { padding: 10px 12px; border: 1px solid var(--border); text-align: left; }
.guide-content th { background: var(--surface-soft); }
.guide-content blockquote { margin: 24px 0; padding: 4px 20px; border-left: 4px solid var(--brand); color: var(--text-weak); }
.source-link { margin-top: 56px; padding-top: 24px; border-top: 1px solid var(--border); }
.related-guides { margin-top: 72px; padding-top: 40px; border-top: 1px solid var(--border); }
.related-guides h2 { margin-top: 0; }
.related-guides ul { margin: 0; padding: 0; list-style: none; display: grid; grid-template-columns: repeat(2, 1fr); gap: 16px; }
.related-guides li { padding: 20px; background: var(--surface); border: 1px solid var(--border); border-radius: 14px; }
.related-guides li a { display: block; font-weight: 800; }
.related-guides li span { display: block; margin-top: 6px; color: var(--text-weak); font-size: 15px; }
[hidden] { display: none !important; }
@media (max-width: 860px) {
  .site-header { position: static; }
  .site-header nav { align-items: flex-start; flex-wrap: wrap; gap: 4px 16px; }
  .site-links { order: 3; flex: 0 0 100%; flex-wrap: wrap; gap: 4px 18px; }
  .package-version { margin-left: auto; }
  .page-shell { width: min(100% - 32px, 760px); padding-top: 40px; }
  .guide-layout { grid-template-columns: 1fr; gap: 16px; }
  .guide-content { order: 1; }
  .table-of-contents {
    order: 2;
    position: static;
    max-height: none;
    margin-top: 32px;
    padding: 16px;
    overflow-y: visible;
    border: 1px solid var(--border);
    border-radius: 14px;
    scrollbar-gutter: auto;
  }
}
@media (max-width: 600px) {
  body { font-size: 17px; }
  .site-header nav { padding-inline: 16px; }
  .search-panel { padding: 16px; }
  .search-control { grid-template-columns: 1fr; }
  .guide-row { grid-template-columns: 1fr; gap: 12px; padding: 24px 0; }
  .row-action { justify-self: start; }
  .group-heading { grid-template-columns: 1fr; }
  .related-guides ul { grid-template-columns: 1fr; }
}
@media (prefers-color-scheme: dark) {
  :root {
    --background: #13121a;
    --surface: #1c1a25;
    --surface-soft: #262331;
    --text: #f2eff9;
    --text-weak: #c7c1d0;
    --brand: #b9b2ff;
    --brand-strong: #d0cbff;
    --border: #5d5868;
    --focus: #69b7ff;
  }
  a { color: #8bc7ff; }
  a:hover { color: #b9ddff; }
}
''';
