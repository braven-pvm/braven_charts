import 'dart:convert';
import 'dart:io';

import 'public_docs_support.dart';

const _catalogPath = 'doc/public_catalog.json';
const _readmePath = 'README.md';
const _generatedCatalogPath =
    'example/lib/showcase/generated/public_docs_catalog.g.dart';
const _runtimeCatalogPath =
    'example/lib/showcase/widgets/chart_type_catalog.dart';
const _showcaseAppPath = 'example/lib/showcase/showcase_app.dart';
const _pubspecPath = 'pubspec.yaml';
const _heroMediaPath = 'doc/screenshots/chart_type_strip.png';

const _generatedSections = <String>[
  'FEATURES',
  'FAMILIES',
  'INSTALL',
  'SNIPPETS',
  'GUIDES',
  'GALLERY',
];

void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final check = arguments.contains('--check') || !write;
  final apiDirectoryArguments = arguments
      .where((argument) => argument.startsWith('--api-dir='))
      .toList();
  final apiDirectory = apiDirectoryArguments.isEmpty
      ? null
      : apiDirectoryArguments.single.substring('--api-dir='.length);

  if (write && arguments.contains('--check')) {
    _fail('Use either --write or --check, not both.');
  }
  if (arguments.any(
    (argument) =>
        argument != '--write' &&
        argument != '--check' &&
        !argument.startsWith('--api-dir='),
  )) {
    _fail(
      'Usage: dart run tool/public_docs.dart '
      '[--check|--write] [--api-dir=<dartdoc output>]',
    );
  }
  if (apiDirectoryArguments.length > 1 ||
      apiDirectory != null && apiDirectory.trim().isEmpty) {
    _fail('--api-dir must name one dartdoc output directory.');
  }
  if (write && apiDirectory != null) {
    _fail('--api-dir can only be used with --check.');
  }

  final root = Directory.current;
  final catalog = _readJsonObject(root.file(_catalogPath));
  final errors = _validateCatalog(root, catalog);
  if (errors.isNotEmpty) {
    stderr.writeln('Public documentation catalog is invalid:');
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    exitCode = 1;
    return;
  }

  final generatedCatalog = _generateDartCatalog(root, catalog);
  final readmeSections = <String, String>{
    'FEATURES': _generateFeatures(catalog),
    'FAMILIES': _generateFamilies(catalog),
    'INSTALL': _generateInstall(root),
    'SNIPPETS': _generateSnippets(root, catalog),
    'GUIDES': _generateGuides(catalog),
    'GALLERY': _generateGallery(catalog),
  };

  final stale = <String>[];
  final generatedFile = root.file(_generatedCatalogPath);
  if (write) {
    generatedFile.parent.createSync(recursive: true);
    generatedFile.writeAsStringSync(generatedCatalog);
  } else if (!generatedFile.existsSync() ||
      normalizePublicDocsText(generatedFile.readAsStringSync()) !=
          normalizePublicDocsText(generatedCatalog)) {
    stale.add(_generatedCatalogPath);
  }

  final readmeFile = root.file(_readmePath);
  if (!readmeFile.existsSync()) {
    _fail('Missing $_readmePath.');
  }
  var readme = readmeFile.readAsStringSync();
  for (final section in _generatedSections) {
    final replacement = readmeSections[section]!;
    final updated = _replaceGeneratedSection(readme, section, replacement);
    if (updated == null) {
      _fail(
        'README is missing generated markers for $section. '
        'Expected ${_startMarker(section)} and ${_endMarker(section)}.',
      );
    }
    readme = updated;
  }

  if (write) {
    readmeFile.writeAsStringSync(readme);
    stdout.writeln('Updated $_generatedCatalogPath and $_readmePath.');
    return;
  }

  if (check &&
      normalizePublicDocsText(readmeFile.readAsStringSync()) !=
          normalizePublicDocsText(readme)) {
    stale.add(_readmePath);
  }

  if (stale.isNotEmpty) {
    stderr.writeln(
      'Public documentation outputs are stale: ${stale.join(', ')}.',
    );
    stderr.writeln('Run: dart run tool/public_docs.dart --write');
    exitCode = 1;
    return;
  }

  if (apiDirectory != null) {
    final apiErrors = _validateApiDocumentation(
      Directory(apiDirectory),
      catalog,
    );
    if (apiErrors.isNotEmpty) {
      stderr.writeln('Generated API documentation is incomplete:');
      for (final error in apiErrors) {
        stderr.writeln('  - $error');
      }
      exitCode = 1;
      return;
    }
  }

  stdout.writeln(
    apiDirectory == null
        ? 'Public documentation catalog and generated outputs are current.'
        : 'Public documentation catalog, generated outputs, and API symbols '
              'are current.',
  );
}

Map<String, dynamic> _readJsonObject(File file) {
  if (!file.existsSync()) {
    _fail('Missing ${file.path}.');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    _fail('${file.path} must contain one JSON object.');
  }
  return decoded;
}

List<String> _validateCatalog(Directory root, Map<String, dynamic> catalog) {
  final errors = <String>[];

  if (catalog[r'$schema'] != './public_catalog.schema.json') {
    errors.add(r'$schema must point to ./public_catalog.schema.json.');
  }
  if (!root.file('doc/public_catalog.schema.json').existsSync()) {
    errors.add('Missing doc/public_catalog.schema.json.');
  }
  if (catalog['schemaVersion'] != 1) {
    errors.add('schemaVersion must be 1.');
  }

  for (final key in const [
    'showcaseBaseUrl',
    'repositoryBaseUrl',
    'apiBaseUrl',
    'guidesBaseUrl',
  ]) {
    final value = catalog[key];
    if (value is! String || Uri.tryParse(value)?.hasScheme != true) {
      errors.add('$key must be an absolute URL.');
    }
  }

  final features = _objects(catalog, 'features', errors);
  final families = _objects(catalog, 'chartFamilies', errors);
  final hostedGuides = _objects(catalog, 'hostedGuides', errors);
  final guides = _objects(catalog, 'guides', errors);
  final snippets = _objects(catalog, 'snippets', errors);
  final gallery = _objects(catalog, 'gallery', errors);

  if (features.length != 6) {
    errors.add('features must contain exactly 6 evergreen groups.');
  }
  if (families.length != 12) {
    errors.add('chartFamilies must contain exactly 12 built-in families.');
  }
  if (gallery.length < 12 || gallery.length > 18) {
    errors.add('gallery must contain between 12 and 18 curated entries.');
  }
  final galleryGroupCounts = <String, int>{};
  for (final item in gallery) {
    final group = item['group'];
    if (group is String) {
      galleryGroupCounts.update(group, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  for (final entry in galleryGroupCounts.entries) {
    if (entry.value != 3) {
      errors.add(
        'Gallery group ${entry.key} must contain exactly 3 items; '
        'found ${entry.value}.',
      );
    }
  }
  _requireMediaDimensions(
    root,
    _heroMediaPath,
    field: 'README hero media',
    width: 2400,
    height: 280,
    errors: errors,
  );

  _validateUniqueIds('features', features, errors);
  _validateUniqueIds('chartFamilies', families, errors);
  _validateUniqueIds('hostedGuides', hostedGuides, errors);
  _validateUniqueIds('guides', guides, errors);
  _validateUniqueIds('snippets', snippets, errors);
  _validateUniqueIds('gallery', gallery, errors);

  final runtimeSlugs = <String>{};
  final runtimeCatalog = root.file(_runtimeCatalogPath);
  if (!runtimeCatalog.existsSync()) {
    errors.add('Missing runtime catalog $_runtimeCatalogPath.');
  } else {
    runtimeSlugs.addAll(
      RegExp(
        r"slug:\s*'([^']+)'",
      ).allMatches(runtimeCatalog.readAsStringSync()).map((match) {
        return match.group(1)!;
      }),
    );
    final publicSlugs = families.map((family) => family['page']).toSet();
    if (!const SetEquality<String>().equals(runtimeSlugs, publicSlugs)) {
      errors.add(
        'Public family pages do not match showcaseChartTypes. '
        'public=${_sorted(publicSlugs)} runtime=${_sorted(runtimeSlugs)}',
      );
    }
  }
  final showcaseRoutes = _showcaseRouteSlugs(root, runtimeSlugs, errors);
  final hostedGuideIds = <String>{};
  final hostedGuidePaths = <String>{};
  final hostedGuideSources = <String>{};
  const hostedGuideGroups = {
    'Get started',
    'Chart families',
    'Interaction and display',
    'Data, authoring, and live updates',
    'Workbench, artifacts, and export',
    'API reference',
  };
  for (final guide in hostedGuides) {
    final id = guide['id'];
    for (final field in const [
      'id',
      'title',
      'group',
      'summary',
      'sourcePath',
      'path',
    ]) {
      _requireText('hostedGuides.$id.$field', guide[field], errors);
    }
    if (id is String) hostedGuideIds.add(id);
    final group = guide['group'];
    if (group is String && !hostedGuideGroups.contains(group)) {
      errors.add('hostedGuides.$id.group is not a public guide group.');
    }
    final sourcePath = guide['sourcePath'];
    if (sourcePath is String) {
      if (!(sourcePath.startsWith('doc/') ||
          sourcePath.startsWith('docs/guides/'))) {
        errors.add(
          'hostedGuides.$id.sourcePath must stay under doc/ or docs/guides/.',
        );
      }
      if (!hostedGuideSources.add(sourcePath)) {
        errors.add('Hosted guide source $sourcePath is registered twice.');
      }
      _requireFile(root, sourcePath, 'hostedGuides.$id.sourcePath', errors);
    }
    final path = guide['path'];
    if (path is String) {
      final validPath = RegExp(
        r'^[a-z0-9]+(?:[a-z0-9/-]*[a-z0-9])?/$',
      ).hasMatch(path);
      if (!validPath || path.contains('..') || path.startsWith('/')) {
        errors.add(
          'hostedGuides.$id.path must be a stable relative directory path.',
        );
      }
      if (!hostedGuidePaths.add(path)) {
        errors.add('Hosted guide path $path is registered twice.');
      }
    }
  }

  final primaryAssets = <String>{};
  for (final family in families) {
    final id = family['id'];
    for (final field in const [
      'id',
      'label',
      'group',
      'summary',
      'bestFor',
      'page',
      'guideId',
      'pairAsset',
    ]) {
      _requireText('chartFamilies.$id.$field', family[field], errors);
    }
    final guideId = family['guideId'];
    if (guideId is String && !hostedGuideIds.contains(guideId)) {
      errors.add('chartFamilies.$id.guideId references unknown $guideId.');
    }
    _requireFile(
      root,
      family['pairAsset'],
      'chartFamilies.$id.pairAsset',
      errors,
    );
    _requireMediaDimensions(
      root,
      family['pairAsset'],
      field: 'chartFamilies.$id.pairAsset',
      width: 1944,
      height: 540,
      errors: errors,
    );

    final symbols = family['apiSymbols'];
    if (symbols is! List ||
        symbols.isEmpty ||
        symbols.any((symbol) => symbol is! String || symbol.trim().isEmpty)) {
      errors.add('chartFamilies.$id.apiSymbols must contain public symbols.');
    }

    final primary = family['primaryExample'];
    if (primary is! Map<String, dynamic>) {
      errors.add('chartFamilies.$id.primaryExample must be an object.');
      continue;
    }
    for (final field in const ['title', 'alt', 'asset', 'page']) {
      _requireText(
        'chartFamilies.$id.primaryExample.$field',
        primary[field],
        errors,
      );
    }
    _requireFile(
      root,
      primary['asset'],
      'chartFamilies.$id.primaryExample.asset',
      errors,
    );
    _requireShowcaseRoute(
      showcaseRoutes,
      primary['page'],
      'chartFamilies.$id.primaryExample.page',
      errors,
    );
    if (primary['asset'] is String && !primaryAssets.add(primary['asset'])) {
      errors.add(
        'Primary family media ${primary['asset']} is used more than once.',
      );
    }

    final secondary = family['secondaryExample'];
    if (secondary != null) {
      if (secondary is! Map<String, dynamic>) {
        errors.add('chartFamilies.$id.secondaryExample must be an object.');
      } else {
        for (final field in const ['title', 'asset', 'page']) {
          _requireText(
            'chartFamilies.$id.secondaryExample.$field',
            secondary[field],
            errors,
          );
        }
        _requireFile(
          root,
          secondary['asset'],
          'chartFamilies.$id.secondaryExample.asset',
          errors,
        );
        _requireShowcaseRoute(
          showcaseRoutes,
          secondary['page'],
          'chartFamilies.$id.secondaryExample.page',
          errors,
        );
      }
    }
  }

  for (final feature in features) {
    final id = feature['id'];
    for (final field in const ['id', 'title', 'summary', 'page']) {
      _requireText('features.$id.$field', feature[field], errors);
    }
    if (feature['summary'] is String &&
        _wordCount(feature['summary'] as String) > 20) {
      errors.add('features.$id.summary exceeds 20 words.');
    }
    _requireShowcaseRoute(
      showcaseRoutes,
      feature['page'],
      'features.$id.page',
      errors,
    );
  }

  final guideGroups = guides.map((guide) => guide['group']).toSet();
  const expectedGuideGroups = {
    'Get started',
    'Interaction and display',
    'Data, authoring, and live updates',
    'Workbench, artifacts, and export',
    'API reference',
  };
  if (!const SetEquality<String>().equals(guideGroups, expectedGuideGroups)) {
    errors.add(
      'Guide groups must match the public information architecture. '
      'actual=${_sorted(guideGroups)}',
    );
  }

  for (final guide in guides) {
    final id = guide['id'];
    for (final field in const ['id', 'title', 'group', 'summary']) {
      _requireText('guides.$id.$field', guide[field], errors);
    }
    final hasTarget =
        guide['page'] is String ||
        guide['guideId'] is String ||
        guide.containsKey('apiPath') ||
        guide['snippet'] is String;
    if (!hasTarget) {
      errors.add('guides.$id must define a public destination.');
    }
    final guideId = guide['guideId'];
    if (guideId is String && !hostedGuideIds.contains(guideId)) {
      errors.add('guides.$id.guideId references unknown $guideId.');
    }
    if (guide['page'] != null) {
      _requireShowcaseRoute(
        showcaseRoutes,
        guide['page'],
        'guides.$id.page',
        errors,
      );
    }
  }

  final snippetIds = <String>{};
  for (final snippet in snippets) {
    final id = snippet['id'];
    for (final field in const [
      'id',
      'title',
      'path',
      'startMarker',
      'endMarker',
      'language',
    ]) {
      _requireText('snippets.$id.$field', snippet[field], errors);
    }
    if (id is String) snippetIds.add(id);
    final path = snippet['path'];
    _requireFile(root, path, 'snippets.$id.path', errors);
    if (path is String && root.file(path).existsSync()) {
      final source = root.file(path).readAsStringSync();
      final start = snippet['startMarker'];
      final end = snippet['endMarker'];
      if (start is String && end is String) {
        final startCount = start.allMatches(source).length;
        final endCount = end.allMatches(source).length;
        if (startCount != 1 || endCount != 1) {
          errors.add(
            'snippets.$id markers must each occur once '
            '(start=$startCount end=$endCount).',
          );
        } else {
          final body = _extractSnippet(source, start, end);
          if (body.trim().isEmpty) {
            errors.add('snippets.$id extracted body is empty.');
          }
        }
      }
    }
  }

  for (final guide in guides) {
    final snippet = guide['snippet'];
    if (snippet is String && !snippetIds.contains(snippet)) {
      errors.add('guides.${guide['id']} references unknown snippet $snippet.');
    }
  }

  final galleryAssets = <String>{};
  for (final item in gallery) {
    final id = item['id'];
    for (final field in const [
      'id',
      'title',
      'group',
      'alt',
      'asset',
      'page',
    ]) {
      _requireText('gallery.$id.$field', item[field], errors);
    }
    _requireFile(root, item['asset'], 'gallery.$id.asset', errors);
    final galleryAsset = item['asset'];
    if (galleryAsset is String) {
      _requireMediaDimensions(
        root,
        galleryAsset,
        field: 'gallery.$id.asset',
        width: galleryAsset.toLowerCase().endsWith('.gif') ? 800 : 1920,
        height: galleryAsset.toLowerCase().endsWith('.gif') ? 450 : 1080,
        errors: errors,
      );
    }
    _requireShowcaseRoute(
      showcaseRoutes,
      item['page'],
      'gallery.$id.page',
      errors,
    );
    final asset = item['asset'];
    if (asset is String) {
      if (!galleryAssets.add(asset)) {
        errors.add('Gallery media $asset is used more than once.');
      }
      if (primaryAssets.contains(asset)) {
        errors.add('Gallery media $asset duplicates a family primary.');
      }
    }
  }

  return errors;
}

Set<String> _showcaseRouteSlugs(
  Directory root,
  Set<String> runtimeSlugs,
  List<String> errors,
) {
  final app = root.file(_showcaseAppPath);
  if (!app.existsSync()) {
    errors.add('Missing showcase navigation $_showcaseAppPath.');
    return runtimeSlugs;
  }

  final source = app.readAsStringSync().replaceAll(
    RegExp(r'//.*$', multiLine: true),
    '',
  );
  final routes = <String>{...runtimeSlugs};
  for (final match in RegExp(r'NavDestination\s*\(').allMatches(source)) {
    var depth = 1;
    var cursor = match.end;
    while (cursor < source.length && depth > 0) {
      final character = source[cursor];
      if (character == '(') depth++;
      if (character == ')') depth--;
      cursor++;
    }
    if (depth != 0) {
      errors.add('Could not parse a NavDestination in $_showcaseAppPath.');
      break;
    }

    final block = source.substring(match.end, cursor - 1);
    final route = RegExp(r"routeSlug:\s*'([^']+)'").firstMatch(block)?.group(1);
    if (route != null) {
      routes.add(route);
      continue;
    }

    final label = RegExp(r"label:\s*'([^']+)'").firstMatch(block)?.group(1);
    if (label != null) {
      routes.add(_slugify(label));
    }
  }
  return routes;
}

void _requireShowcaseRoute(
  Set<String> routes,
  Object? value,
  String field,
  List<String> errors,
) {
  if (value is String && value.trim().isNotEmpty && !routes.contains(value)) {
    errors.add(
      '$field points to unknown showcase route $value. '
      'known=${_sorted(routes)}',
    );
  }
}

String _slugify(String value) => value
    .toLowerCase()
    .replaceAll('+', ' ')
    .replaceAll(RegExp('[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'(^-|-$)'), '');

List<String> _validateApiDocumentation(
  Directory apiDirectory,
  Map<String, dynamic> catalog,
) {
  final errors = <String>[];
  for (final path in const ['index.html', 'index.json']) {
    if (!apiDirectory.file(path).existsSync()) {
      errors.add('Missing ${apiDirectory.file(path).path}.');
    }
  }

  final indexFile = apiDirectory.file('index.html');
  if (indexFile.existsSync()) {
    final index = indexFile.readAsStringSync();
    final headEnd = index.indexOf('</head>');
    final head = headEnd < 0 ? index : index.substring(0, headEnd);
    if (!head.contains('#dartdoc-main-content .markdown img') ||
        !head.contains('#dartdoc-main-content .markdown table')) {
      errors.add(
        'index.html is missing responsive Markdown image and table styles.',
      );
    }
    if (RegExp(r'<nav\b', caseSensitive: false).hasMatch(head)) {
      errors.add(
        'index.html injects navigation markup inside <head>; '
        'create it after DOMContentLoaded instead.',
      );
    }
    if (!head.contains("document.createElement('nav')")) {
      errors.add('index.html is missing the Braven documentation navigation.');
    }
  }

  for (final family in _list(catalog, 'chartFamilies')) {
    final familyId = family['id'];
    for (final symbol in family['apiSymbols'] as List) {
      final path = 'braven_charts/$symbol-class.html';
      if (!apiDirectory.file(path).existsSync()) {
        errors.add(
          'chartFamilies.$familyId.apiSymbols references undocumented '
          'class $symbol.',
        );
      }
    }
  }

  for (final guide in _list(catalog, 'guides')) {
    final apiPath = guide['apiPath'];
    if (apiPath is! String) continue;
    final path = apiPath.isEmpty ? 'index.html' : apiPath;
    if (!apiDirectory.file(path).existsSync()) {
      errors.add('guides.${guide['id']}.apiPath points to missing $path.');
    }
  }
  return errors;
}

List<Map<String, dynamic>> _objects(
  Map<String, dynamic> catalog,
  String key,
  List<String> errors,
) {
  final value = catalog[key];
  if (value is! List) {
    errors.add('$key must be a list.');
    return const [];
  }
  final result = <Map<String, dynamic>>[];
  for (var index = 0; index < value.length; index++) {
    final item = value[index];
    if (item is! Map<String, dynamic>) {
      errors.add('$key[$index] must be an object.');
    } else {
      result.add(item);
    }
  }
  return result;
}

void _validateUniqueIds(
  String collection,
  List<Map<String, dynamic>> entries,
  List<String> errors,
) {
  final ids = <String>{};
  for (final entry in entries) {
    final id = entry['id'];
    if (id is! String || id.trim().isEmpty) {
      errors.add('$collection entry is missing an ID.');
    } else if (!ids.add(id)) {
      errors.add('$collection contains duplicate ID $id.');
    }
  }
}

void _requireText(String field, Object? value, List<String> errors) {
  if (value is! String || value.trim().isEmpty) {
    errors.add('$field must be non-empty text.');
  }
}

void _requireFile(
  Directory root,
  Object? value,
  String field,
  List<String> errors,
) {
  if (value is! String || value.trim().isEmpty) return;
  if (!root.file(value).existsSync()) {
    errors.add('$field points to missing file $value.');
  }
}

void _requireMediaDimensions(
  Directory root,
  Object? value, {
  required String field,
  required int width,
  required int height,
  required List<String> errors,
}) {
  if (value is! String || value.trim().isEmpty) return;
  final file = root.file(value);
  if (!file.existsSync()) return;
  final dimensions = _mediaDimensions(file);
  if (dimensions == null) {
    errors.add('$field must be a supported PNG or GIF image.');
    return;
  }
  if (dimensions.width != width || dimensions.height != height) {
    errors.add(
      '$field must be ${width}x$height; '
      'found ${dimensions.width}x${dimensions.height}.',
    );
  }
}

({int width, int height})? _mediaDimensions(File file) {
  final bytes = file.readAsBytesSync();
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    int readBigEndian32(int offset) =>
        bytes[offset] << 24 |
        bytes[offset + 1] << 16 |
        bytes[offset + 2] << 8 |
        bytes[offset + 3];
    return (width: readBigEndian32(16), height: readBigEndian32(20));
  }
  if (bytes.length >= 10 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    final width = bytes[6] | bytes[7] << 8;
    final height = bytes[8] | bytes[9] << 8;
    return (width: width, height: height);
  }
  return null;
}

String _generateDartCatalog(Directory root, Map<String, dynamic> catalog) {
  final features = _list(catalog, 'features');
  final families = _list(catalog, 'chartFamilies');
  final hostedGuides = _list(catalog, 'hostedGuides');
  final guides = _list(catalog, 'guides');
  final snippets = _list(catalog, 'snippets');
  final package = readPublicDocsPackageMetadata(root.file(_pubspecPath));
  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('// Generated by: dart run tool/public_docs.dart --write')
    ..writeln()
    ..writeln(
      'typedef PublicDocsFeatureEntry = ({'
      'String id, String title, String summary, String page});',
    )
    ..writeln(
      'typedef PublicDocsExampleEntry = ({String title, String asset, '
      'String page, String? preset, String? view, bool animated});',
    )
    ..writeln(
      'typedef PublicDocsChartFamilyEntry = ({String id, String label, '
      'String group, String summary, String bestFor, String page, '
      'String guideId, String pairAsset, List<String> apiSymbols, '
      'PublicDocsExampleEntry primaryExample, '
      'PublicDocsExampleEntry? secondaryExample});',
    )
    ..writeln(
      'typedef PublicDocsHostedGuideEntry = ({String id, String title, '
      'String group, String summary, String sourcePath, String path});',
    )
    ..writeln(
      'typedef PublicDocsGuideEntry = ({String id, String title, String group, '
      'String summary, String? page, String? guideId, String? apiPath, '
      'String? snippet});',
    )
    ..writeln(
      'typedef PublicDocsSnippetEntry = ({String id, String title, '
      'String language, String source});',
    )
    ..writeln()
    ..writeln(
      'const publicDocsShowcaseBaseUrl = ${_dart(catalog['showcaseBaseUrl'])};',
    )
    ..writeln(
      'const publicDocsRepositoryBaseUrl = '
      '${_dart(catalog['repositoryBaseUrl'])};',
    )
    ..writeln('const publicDocsApiBaseUrl = ${_dart(catalog['apiBaseUrl'])};')
    ..writeln(
      'const publicDocsGuidesBaseUrl = ${_dart(catalog['guidesBaseUrl'])};',
    )
    ..writeln('const publicDocsPackageVersion = ${_dart(package.version)};')
    ..writeln(
      'const publicDocsDartConstraint = ${_dart(package.dartConstraint)};',
    )
    ..writeln(
      'const publicDocsFlutterConstraint = '
      '${_dart(package.flutterConstraint)};',
    )
    ..writeln()
    ..writeln('const publicDocsFeatures = <PublicDocsFeatureEntry>[');
  for (final feature in features) {
    buffer
      ..writeln('  (')
      ..writeln('    id: ${_dart(feature['id'])},')
      ..writeln('    title: ${_dart(feature['title'])},')
      ..writeln('    summary: ${_dart(feature['summary'])},')
      ..writeln('    page: ${_dart(feature['page'])},')
      ..writeln('  ),');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('const publicDocsChartFamilies = <PublicDocsChartFamilyEntry>[');
  for (final family in families) {
    buffer
      ..writeln('  (')
      ..writeln('    id: ${_dart(family['id'])},')
      ..writeln('    label: ${_dart(family['label'])},')
      ..writeln('    group: ${_dart(family['group'])},')
      ..writeln('    summary: ${_dart(family['summary'])},')
      ..writeln('    bestFor: ${_dart(family['bestFor'])},')
      ..writeln('    page: ${_dart(family['page'])},')
      ..writeln('    guideId: ${_dart(family['guideId'])},')
      ..writeln('    pairAsset: ${_dart(family['pairAsset'])},')
      ..writeln(
        '    apiSymbols: ${_dartStringList(family['apiSymbols'] as List)},',
      )
      ..writeln(
        '    primaryExample: ${_dartExample(family['primaryExample'])},',
      )
      ..writeln(
        '    secondaryExample: '
        '${family['secondaryExample'] == null ? 'null' : _dartExample(family['secondaryExample'])},',
      )
      ..writeln('  ),');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('const publicDocsHostedGuides = <PublicDocsHostedGuideEntry>[');
  for (final guide in hostedGuides) {
    buffer
      ..writeln('  (')
      ..writeln('    id: ${_dart(guide['id'])},')
      ..writeln('    title: ${_dart(guide['title'])},')
      ..writeln('    group: ${_dart(guide['group'])},')
      ..writeln('    summary: ${_dart(guide['summary'])},')
      ..writeln('    sourcePath: ${_dart(guide['sourcePath'])},')
      ..writeln('    path: ${_dart(guide['path'])},')
      ..writeln('  ),');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('const publicDocsGuides = <PublicDocsGuideEntry>[');
  for (final guide in guides) {
    buffer
      ..writeln('  (')
      ..writeln('    id: ${_dart(guide['id'])},')
      ..writeln('    title: ${_dart(guide['title'])},')
      ..writeln('    group: ${_dart(guide['group'])},')
      ..writeln('    summary: ${_dart(guide['summary'])},')
      ..writeln('    page: ${_dartNullable(guide['page'])},')
      ..writeln('    guideId: ${_dartNullable(guide['guideId'])},')
      ..writeln(
        '    apiPath: '
        '${guide.containsKey('apiPath') ? _dart(guide['apiPath']) : 'null'},',
      )
      ..writeln('    snippet: ${_dartNullable(guide['snippet'])},')
      ..writeln('  ),');
  }
  buffer
    ..writeln('];')
    ..writeln()
    ..writeln('const publicDocsSnippets = <PublicDocsSnippetEntry>[');
  for (final snippet in snippets) {
    final source = _snippetSource(root, snippet);
    buffer
      ..writeln('  (')
      ..writeln('    id: ${_dart(snippet['id'])},')
      ..writeln('    title: ${_dart(snippet['title'])},')
      ..writeln('    language: ${_dart(snippet['language'])},')
      ..writeln('    source: ${_dart(source)},')
      ..writeln('  ),');
  }
  buffer.writeln('];');
  return buffer.toString();
}

String _dartExample(Object? value) {
  final example = value as Map<String, dynamic>;
  return '('
      'title: ${_dart(example['title'])}, '
      'asset: ${_dart(example['asset'])}, '
      'page: ${_dart(example['page'])}, '
      'preset: ${_dartNullable(example['preset'])}, '
      'view: ${_dartNullable(example['view'])}, '
      'animated: ${example['animated'] == true}'
      ')';
}

String _generateFeatures(Map<String, dynamic> catalog) {
  final base = catalog['showcaseBaseUrl'] as String;
  final buffer = StringBuffer();
  for (final feature in _list(catalog, 'features')) {
    final url = _showcaseUrl(base, page: feature['page'] as String);
    buffer.writeln('- **[${feature['title']}]($url):** ${feature['summary']}');
  }
  return buffer.toString().trimRight();
}

String _generateFamilies(Map<String, dynamic> catalog) {
  final base = catalog['showcaseBaseUrl'] as String;
  final guidesBase = catalog['guidesBaseUrl'] as String;
  final families = _list(catalog, 'chartFamilies');
  final hostedGuides = {
    for (final guide in _list(catalog, 'hostedGuides'))
      guide['id'] as String: guide,
  };
  final buffer = StringBuffer();

  for (var index = 0; index < families.length; index += 2) {
    final pair = families.skip(index).take(2).toList();
    buffer
      ..writeln(
        '| ${pair.map((family) => '**[${family['label']}](${_showcaseUrl(base, page: family['page'] as String)})**').join(' | ')} |',
      )
      ..writeln('| ${pair.map((_) => '---').join(' | ')} |')
      ..writeln(
        '| ${pair.map((family) {
          final example = family['primaryExample'] as Map<String, dynamic>;
          return '[![${example['alt']} and ${family['secondaryExample']?['title'] ?? 'a second curated example'}](${_rawAsset(family['pairAsset'] as String)})](${_showcaseUrl(base, page: family['page'] as String)})';
        }).join(' | ')} |',
      )
      ..writeln(
        '| ${pair.map((family) {
          final pageUrl = _showcaseUrl(base, page: family['page'] as String);
          final guide = hostedGuides[family['guideId']]!;
          final guideUrl = '$guidesBase${guide['path']}';
          final primary = family['primaryExample'] as Map<String, dynamic>;
          final primaryUrl = _showcaseUrl(base, page: primary['page'] as String, preset: primary['preset'] as String?, view: primary['view'] as String?);
          final secondary = family['secondaryExample'] as Map<String, dynamic>?;
          final secondaryLink = secondary == null ? '' : ' · [${secondary['title']}](${_showcaseUrl(base, page: secondary['page'] as String, preset: secondary['preset'] as String?, view: secondary['view'] as String?)})';
          return '${family['bestFor']}<br>'
              '[${primary['title']}]($primaryUrl)'
              '$secondaryLink<br>'
              '[Open all ${family['label']} examples]($pageUrl) · '
              '[${family['label']} guide]($guideUrl)'
              '';
        }).join(' | ')} |',
      )
      ..writeln();
  }
  return buffer.toString().trimRight();
}

String _generateInstall(Directory root) {
  final package = readPublicDocsPackageMetadata(root.file(_pubspecPath));
  return '''
```yaml
dependencies:
  braven_charts: ^${package.version}
```

Then run `flutter pub get`.

Compatibility: Dart `${package.dartConstraint}` and Flutter `${package.flutterConstraint}`.''';
}

String _generateSnippets(Directory root, Map<String, dynamic> catalog) {
  final buffer = StringBuffer();
  for (final snippet in _list(catalog, 'snippets')) {
    buffer
      ..writeln('### ${snippet['title']}')
      ..writeln()
      ..writeln('```${snippet['language']}')
      ..writeln(_snippetSource(root, snippet))
      ..writeln('```')
      ..writeln();
  }
  return buffer.toString().trimRight();
}

String _generateGuides(Map<String, dynamic> catalog) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final guide in _list(catalog, 'guides')) {
    groups.putIfAbsent(guide['group'] as String, () => []).add(guide);
  }
  final buffer = StringBuffer();
  for (final entry in groups.entries) {
    buffer
      ..writeln('### ${entry.key}')
      ..writeln();
    for (final guide in entry.value) {
      buffer.writeln(
        '- [${guide['title']}](${_guideUrl(catalog, guide)}) — '
        '${guide['summary']}',
      );
    }
    buffer.writeln();
  }
  return buffer.toString().trimRight();
}

String _generateGallery(Map<String, dynamic> catalog) {
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final item in _list(catalog, 'gallery')) {
    groups.putIfAbsent(item['group'] as String, () => []).add(item);
  }
  final base = catalog['showcaseBaseUrl'] as String;
  final buffer = StringBuffer();
  for (final entry in groups.entries) {
    buffer
      ..writeln('### ${entry.key}')
      ..writeln();
    for (var index = 0; index < entry.value.length; index += 3) {
      final row = entry.value.skip(index).take(3).toList();
      buffer
        ..writeln('| ${row.map((item) => item['title']).join(' | ')} |')
        ..writeln('| ${row.map((_) => '---').join(' | ')} |')
        ..writeln(
          '| ${row.map((item) {
            final url = _showcaseUrl(base, page: item['page'] as String, preset: item['preset'] as String?, view: item['view'] as String?, mode: item['mode'] as String?);
            return '[![${item['alt']}](${_rawAsset(item['asset'] as String)})]($url)';
          }).join(' | ')} |',
        )
        ..writeln();
    }
  }
  return buffer.toString().trimRight();
}

String _guideUrl(Map<String, dynamic> catalog, Map<String, dynamic> guide) {
  if (guide['guideId'] is String) {
    final hostedGuide = _list(
      catalog,
      'hostedGuides',
    ).firstWhere((candidate) => candidate['id'] == guide['guideId']);
    return '${catalog['guidesBaseUrl']}${hostedGuide['path']}';
  }
  if (guide.containsKey('apiPath')) {
    return '${catalog['apiBaseUrl']}${guide['apiPath']}';
  }
  if (guide['page'] is String) {
    return _showcaseUrl(
      catalog['showcaseBaseUrl'] as String,
      page: guide['page'] as String,
    );
  }
  return '#quick-start';
}

String _showcaseUrl(
  String base, {
  required String page,
  String? preset,
  String? view,
  String? mode,
}) {
  final parameters = <String, String>{'page': page};
  if (preset != null) parameters['preset'] = preset;
  if (view != null) parameters['view'] = view;
  if (mode != null) parameters['mode'] = mode;
  return Uri.parse(base).replace(queryParameters: parameters).toString();
}

String _rawAsset(String path) =>
    'https://raw.githubusercontent.com/braven-pvm/braven_charts/master/$path';

String _snippetSource(Directory root, Map<String, dynamic> snippet) {
  final source = root.file(snippet['path'] as String).readAsStringSync();
  return _extractSnippet(
    source,
    snippet['startMarker'] as String,
    snippet['endMarker'] as String,
  );
}

String _extractSnippet(String source, String startMarker, String endMarker) {
  final start = source.indexOf(startMarker) + startMarker.length;
  final end = source.indexOf(endMarker, start);
  return source
      .substring(start, end)
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .trim();
}

String? _replaceGeneratedSection(
  String source,
  String section,
  String replacement,
) {
  final startMarker = _startMarker(section);
  final endMarker = _endMarker(section);
  final start = source.indexOf(startMarker);
  final end = source.indexOf(endMarker);
  if (start < 0 || end < 0 || end < start) return null;
  final contentStart = start + startMarker.length;
  return '${source.substring(0, contentStart)}\n'
      '$replacement\n'
      '${source.substring(end)}';
}

String _startMarker(String section) => '<!-- BEGIN GENERATED: $section -->';

String _endMarker(String section) => '<!-- END GENERATED: $section -->';

List<Map<String, dynamic>> _list(Map<String, dynamic> catalog, String key) =>
    (catalog[key] as List).cast<Map<String, dynamic>>();

String _dart(Object? value) {
  if (value is! String) {
    _fail('Expected a String while generating Dart, got $value.');
  }
  return jsonEncode(value).replaceAll(r'$', r'\$');
}

String _dartNullable(Object? value) => value == null ? 'null' : _dart(value);

String _dartStringList(List<dynamic> values) =>
    '<String>[${values.map(_dart).join(', ')}]';

int _wordCount(String value) =>
    value.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

String _sorted(Set<Object?> values) {
  final strings = values.map((value) => '$value').toList()..sort();
  return strings.join(', ');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

extension on Directory {
  File file(String relativePath) =>
      File('$path${Platform.pathSeparator}$relativePath');
}

final class SetEquality<T> {
  const SetEquality();

  bool equals(Set<Object?> left, Set<Object?> right) {
    if (left.length != right.length) return false;
    return left.every(right.contains);
  }
}
