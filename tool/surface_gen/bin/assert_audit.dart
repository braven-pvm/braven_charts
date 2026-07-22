/// One-shot audit: every constructor-initializer `assert` in `lib/src` that
/// references two or more of its own constructor parameters.
///
/// These are the parameters `surface_gen` refuses to expose as individual
/// fluent setters (see the "assert-coupled parameters" diagnostic in
/// `surface_reader.dart`); each needs a `CombinedSetter` before its class can
/// be annotated. Run from the package root:
///
///   dart run tool/surface_gen/bin/assert_audit.dart <libSrcPath>
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

void main(List<String> args) {
  final root = Directory(args.isEmpty ? 'lib/src' : args.first);
  final findings = <String>[];
  var classes = 0;

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final unit = parseString(content: entity.readAsStringSync()).unit;
    final constructors = _Constructors();
    unit.accept(constructors);
    for (final member in constructors.found) {
      final params = <String>{
        for (final parameter in member.parameters.parameters)
          if (parameter.name != null) parameter.name!.lexeme,
      };
      final groups = <String>{};
      for (final initializer in member.initializers) {
        if (initializer is! AssertInitializer) continue;
        final visitor = _Ids();
        initializer.condition.accept(visitor);
        final hit = (visitor.names.intersection(params).toList())..sort();
        if (hit.length >= 2) groups.add(hit.join(', '));
      }
      if (groups.isEmpty) continue;
      classes++;
      final owner = member.typeName?.name ?? '<class>';
      final name =
          member.name == null ? owner : '$owner.${member.name!.lexeme}';
      for (final group in groups) {
        findings.add('${entity.path.replaceAll(r'\', '/')}  $name  [$group]');
      }
    }
  }

  findings.sort();
  // ignore: avoid_print
  print(findings.join('\n'));
  // ignore: avoid_print
  print('\n${findings.length} multi-parameter assert(s) across $classes '
      'constructor(s).');
}

class _Constructors extends RecursiveAstVisitor<void> {
  final List<ConstructorDeclaration> found = [];

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    found.add(node);
    super.visitConstructorDeclaration(node);
  }
}

class _Ids extends RecursiveAstVisitor<void> {
  final Set<String> names = <String>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
