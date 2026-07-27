import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/public_guides.dart';

void main() {
  test('generates searchable guides with safe links and stable headings', () {
    final fixture = _fixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    final result = generatePublicGuides(
      root: fixture,
      output: Directory('${fixture.path}${Platform.pathSeparator}build/guides'),
    );

    expect(result.guideCount, 2);
    final index = _read(fixture, 'build/guides/index.html');
    final first = _read(fixture, 'build/guides/first/index.html');
    final manifest = jsonDecode(_read(fixture, 'build/guides/index.json'));
    expect(index, contains('Search guides'));
    expect(index, contains('data-search='));
    expect(first, contains('id="same-heading"'));
    expect(first, contains('id="same-heading-2"'));
    expect(
      first,
      contains(
        'class="table-of-contents" aria-labelledby="toc-title" tabindex="0"',
      ),
    );
    expect(first, contains('max-height: calc(100vh - 112px);'));
    expect(first, contains('overflow-y: auto;'));
    expect(first, contains('max-height: none;'));
    expect(first, contains('overflow-y: visible;'));
    expect(first, contains('https://docs.example/guides/second/#target'));
    expect(
      first,
      contains('https://github.com/example/repo/blob/master/doc/unhosted.md'),
    );
    expect(first, contains('&lt;script&gt;alert'));
    expect(first, isNot(contains('<script>alert')));
    expect((manifest['guides'] as List), hasLength(2));
  });

  test('rejects unsafe link schemes', () {
    final fixture = _fixture(
      firstSource: '# First\n\n[Unsafe](javascript:alert(1))\n',
    );
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      () => generatePublicGuides(
        root: fixture,
        output: Directory(
          '${fixture.path}${Platform.pathSeparator}build/guides',
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects duplicate guide paths', () {
    final fixture = _fixture(duplicatePath: true);
    addTearDown(() => fixture.deleteSync(recursive: true));

    expect(
      () => generatePublicGuides(
        root: fixture,
        output: Directory(
          '${fixture.path}${Platform.pathSeparator}build/guides',
        ),
      ),
      throwsFormatException,
    );
  });
}

Directory _fixture({
  bool duplicatePath = false,
  String firstSource = '''
# First

## Same heading

## Same heading

[Hosted](second.md#target)

[Repository](unhosted.md)

<script>alert("encoded")</script>
''',
}) {
  final root = Directory.systemTemp.createTempSync('braven-public-guides-');
  Directory('${root.path}${Platform.pathSeparator}doc').createSync();
  File('${root.path}${Platform.pathSeparator}pubspec.yaml').writeAsStringSync(
    '''
name: fixture
version: 1.2.3
environment:
  sdk: ">=3.9.0 <4.0.0"
  flutter: ">=3.35.0"
''',
  );
  File(
    '${root.path}${Platform.pathSeparator}doc/public_catalog.json',
  ).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'showcaseBaseUrl': 'https://docs.example/',
      'repositoryBaseUrl': 'https://github.com/example/repo/blob/master/',
      'apiBaseUrl': 'https://docs.example/api/',
      'guidesBaseUrl': 'https://docs.example/guides/',
      'chartFamilies': <Object>[],
      'guides': <Object>[],
      'hostedGuides': [
        {
          'id': 'first',
          'title': 'First guide',
          'group': 'Chart families',
          'summary': 'First summary',
          'sourcePath': 'doc/first.md',
          'path': 'first/',
        },
        {
          'id': 'second',
          'title': 'Second guide',
          'group': 'Chart families',
          'summary': 'Second summary',
          'sourcePath': 'doc/second.md',
          'path': duplicatePath ? 'first/' : 'second/',
        },
      ],
    }),
  );
  File(
    '${root.path}${Platform.pathSeparator}doc/first.md',
  ).writeAsStringSync(firstSource);
  File(
    '${root.path}${Platform.pathSeparator}doc/second.md',
  ).writeAsStringSync('# Second\n\n## Target\n');
  return root;
}

String _read(Directory root, String path) => File(
  '${root.path}${Platform.pathSeparator}'
  '${path.replaceAll('/', Platform.pathSeparator)}',
).readAsStringSync();
