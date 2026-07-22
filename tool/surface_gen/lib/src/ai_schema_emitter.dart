/// Emits `lib/src/ai/generated/surface_definitions.dart` — a JSON-Schema
/// `$defs` block describing every `@chartSurface` class.
///
/// ## What this is, and what it deliberately is NOT
///
/// It is NOT a replacement for `chart_tool_schema.dart`. That file is a flat
/// LLM VOCABULARY: its property names (`bar_waterfall_connector_color`,
/// `pie_label_minimum_sweep`) are snake_case keys invented for the agent
/// protocol and consumed literally by `ChartConfigBuilder`. They are keyed
/// INDEPENDENTLY of class structure — one flat `style` bag flattens dozens of
/// nested config classes — so no amount of generation from the surface model
/// can reproduce them. 52% of that vocabulary lowers onto classes the surface
/// model cannot even see (they have no `copyWith`, so they carry no
/// `@chartSurface`).
///
/// What this emitter produces is the STRUCTURAL half of the same story: a
/// typed, always-current, class-keyed description of the config surface. An
/// agent consults it to learn what a `BarChartSeries` actually is; the tool
/// schema stays the thing it calls. Because it is generated, it cannot drift
/// from the classes — which is exactly the property the hand-written literals
/// do not have.
///
/// ## Exclusion-kind translation
///
/// The fluent emitter drops every `excluded*` kind, because each one is a
/// reason no MUTATION verb can exist. A structural DESCRIPTION has a
/// different question to answer — "can this be constructed?" — so the kinds
/// split:
///
/// | kind | schema | why |
/// |---|---|---|
/// | `excludedFunction` | omitted + parent note | a callback has no JSON form |
/// | `excludedController` | omitted + parent note | a controller has no JSON form |
/// | `excludedDeprecated` | omitted + parent note | documenting it invites its use |
/// | `excludedByAnnotation` | INCLUDED, `x-mutation` | a join key or an OR-shaped pair: constructible, just not re-settable |
/// | `excludedNoCopyWithParam` | INCLUDED, `x-mutation` | `copyWith` cannot lower onto it; the CONSTRUCTOR still takes it |
///
/// The last two are mutation-safety concerns. `BarChartSeries.barWidthPercent`
/// is a required part of building a bar series; hiding it from a construction
/// schema would make the schema wrong.
///
/// ## Coupling translation
///
/// - `combinedSetters` whose members include a required parameter →
///   every member joins `required` (they move as one unit);
///   all-optional groups → `dependentRequired`, so setting one demands the
///   rest. Both get a sentence in the class description.
/// - An assert NOT covered by a combined setter becomes `anyOf: [{required:
///   [a]}, {required: [b]}]` ONLY when the reader proved its condition is a
///   null-alternation (`barWidthPercent != null || barWidthPixels != null`).
///   Every other shape contributes its own assert MESSAGE to the description
///   and no machine constraint: `RangeAnnotation`'s `startX == null || endX ==
///   null || startX < endX` permits both being absent, and
///   `LegendAnnotation`'s `[...].whereType<Object>().length <= 1` means at
///   MOST one — a blanket `anyOf` would have documented both backwards.
/// - `bodyValidationGroups` are imperative validation the reader can see but
///   not decode, so they contribute description ONLY. Promising a machine
///   constraint the emitter cannot derive would be worse than saying so.
library;

import 'emitter.dart';
import 'fluent_emitter.dart';
import 'surface_model.dart';

/// Scalar Dart types with an agreed JSON encoding.
///
/// `Color` is a string because that is what `ChartConfigBuilder` already
/// parses (`'#RRGGBB'` / `'#AARRGGBB'`); inventing a different encoding here
/// would describe a surface nothing accepts.
const Map<String, Map<String, Object?>> _scalarSchemas = {
  'bool': {'type': 'boolean'},
  'int': {'type': 'integer'},
  'double': {'type': 'number'},
  'num': {'type': 'number'},
  'String': {'type': 'string'},
  'Color': {
    'type': 'string',
    'description': 'Color as #RRGGBB or #AARRGGBB.',
  },
  'Duration': {
    'type': 'integer',
    'description': 'Duration in milliseconds.',
  },
  'DateTime': {
    'type': 'string',
    'format': 'date-time',
  },
  'Object': {},
  'dynamic': {},
};

/// How each omitted kind is described in the owning class's description.
const Map<SurfaceParamKind, String> _omissionReasons = {
  SurfaceParamKind.excludedFunction: 'callback — no JSON form',
  SurfaceParamKind.excludedController: 'controller — no JSON form',
  SurfaceParamKind.excludedDeprecated: 'deprecated',
};

/// How each INCLUDED-but-unsettable kind is marked on its property.
const Map<SurfaceParamKind, String> _mutationNotes = {
  SurfaceParamKind.excludedByAnnotation:
      'construction-only: force-excluded from the mutation surface '
          '(join key, or an alternative in an OR-shaped constructor pair).',
  SurfaceParamKind.excludedNoCopyWithParam:
      'construction-only: copyWith has no matching parameter, so the value '
          'cannot be changed after construction.',
};

/// Whether [param] is dropped from the structural schema entirely.
bool isOmittedFromSchema(SurfaceParam param) =>
    _omissionReasons.containsKey(param.kind);

/// Whether [param] appears but carries an `x-mutation` caveat.
bool isConstructionOnly(SurfaceParam param) =>
    _mutationNotes.containsKey(param.kind);

/// [SurfaceEmitter] producing the structural `$defs` for the AI surface.
class AiSchemaEmitter implements SurfaceEmitter {
  const AiSchemaEmitter();

  /// The JSON pointer prefix every generated `$ref` uses.
  ///
  /// Consumers mount [emitLibrary]'s map at `$defs` of their root schema.
  static const String refPrefix = r'#/$defs/';

  @override
  String get outputSuffix => '_surface_definitions.dart';

  /// Emits one class's schema as a Dart map literal.
  @override
  String emit(SurfaceClass cls, SurfaceModel model) =>
      _dart(definition(cls, model), 0);

  @override
  String? emitLibrary(SurfaceModel model) {
    final classes = [...model.classes]..sort((a, b) => a.name.compareTo(b.name));
    if (classes.isEmpty) return null;

    final properties = classes.fold<int>(
      0,
      (sum, cls) => sum + _schemaParams(cls).length,
    );

    final buffer = StringBuffer()
      ..writeln('// GENERATED by surface_gen — do not edit.')
      ..writeln('//')
      ..writeln('// Structural JSON-Schema definitions for the '
          '@chartSurface config surface:')
      ..writeln('// ${classes.length} classes, $properties properties.')
      ..writeln('//')
      ..writeln('// ADDITIVE. This does not replace the hand-written tool '
          'schema in')
      ..writeln('// chart_tool_schema.dart, whose flat snake_case vocabulary '
          'is keyed for the')
      ..writeln('// agent protocol rather than for class structure. This is '
          'the structural')
      ..writeln('// companion: what the config classes ARE, always current '
          'because it is')
      ..writeln('// generated.')
      ..writeln('//')
      ..writeln('// Regenerate: dart run build_runner build')
      ..writeln('library;')
      ..writeln()
      ..writeln('/// JSON-Schema definitions for every `@chartSurface` class, '
          'keyed by class')
      ..writeln('/// name.')
      ..writeln('///')
      ..writeln('/// Mount this map at the `\$defs` of a root schema: every '
          'generated')
      ..writeln('/// cross-reference is a `{\'\$ref\': '
          '\'#/\$defs/<ClassName>\'}` pointer.')
      ..writeln('///')
      ..writeln('/// ADDITIVE: `ChartToolSchema.createChartTool` and its '
          'siblings are unchanged')
      ..writeln('/// and keep their hand-written flat snake_case vocabulary. '
          'This map answers a')
      ..writeln('/// different question — what the config CLASSES are — and '
          'is exposed as')
      ..writeln('/// `ChartToolSchema.surfaceDefinitions`.')
      ..writeln('const Map<String, Object?> surfaceDefinitions = '
          '<String, Object?>{');
    for (final cls in classes) {
      buffer
        ..writeln("  '${cls.name}': ${_dart(definition(cls, model), 1)},");
    }
    buffer.writeln('};');
    return formatGenerated(buffer.toString());
  }

  // ---------------------------------------------------------------------
  // Definition construction
  // ---------------------------------------------------------------------

  /// The JSON-Schema object describing [cls].
  Map<String, Object?> definition(SurfaceClass cls, SurfaceModel model) {
    final params = _schemaParams(cls);
    final notes = <String>[];

    final omitted = [
      for (final param in cls.params)
        if (isOmittedFromSchema(param))
          '${param.name} (${_omissionReasons[param.kind]})',
    ];
    if (omitted.isNotEmpty) {
      notes.add('Omitted from this schema: ${omitted.join('; ')}.');
    }

    final required = <String>{
      for (final param in params)
        if (param.isRequired) param.name,
    };
    final dependentRequired = <String, List<String>>{};
    for (final setter in cls.combinedSetters) {
      final members = [
        for (final name in setter.paramNames)
          if (params.any((param) => param.name == name)) name,
      ]..sort();
      if (members.length < 2) continue;
      final anyRequired = members.any(required.contains);
      if (anyRequired) {
        required.addAll(members);
        notes.add('${_and(members)} are validated together and are all '
            'required as a unit (${setter.name}).');
      } else {
        for (final member in members) {
          dependentRequired[member] = [
            for (final other in members)
              if (other != member) other,
          ];
        }
        notes.add('${_and(members)} are validated together: supplying one '
            'requires the others (${setter.name}).');
      }
    }

    final anyOf = <Map<String, Object?>>[];
    for (final entry in cls.asserts) {
      final members = [
        for (final name in entry.params)
          if (params.any((param) => param.name == name)) name,
      ];
      if (members.length < 2) continue;
      final covered = cls.combinedSetters.any(
        (setter) => members.every(setter.paramNames.contains),
      );
      if (covered) continue;
      final complete = members.length == entry.params.length;
      if (entry.isNullAlternation && complete) {
        anyOf.addAll([
          for (final member in members)
            <String, Object?>{
              'required': [member],
            },
        ]);
        notes.add('At least one of ${_and(members)} must be supplied '
            '(constructor assert).');
      } else {
        notes.add('The constructor asserts a relationship between '
            '${_and(members)} that this schema does not express'
            '${entry.message == null ? '' : ': "${entry.message}"'}.');
      }
    }

    for (final group in cls.bodyValidationGroups) {
      final scope = group.isOpaque
          ? 'every parameter'
          : _and(group.params.where(
              (name) => params.any((param) => param.name == name),
            ).toList());
      if (scope.isEmpty) continue;
      notes.add('${_capitalize(group.displayName)} validates $scope in its '
          'body; those checks are imperative and are not expressed as schema '
          'constraints.');
    }
    for (final validation in cls.bodyValidations) {
      notes.add(validation.reason);
    }

    if (cls.isSealed && cls.sealedVariants.isNotEmpty) {
      notes.add('Sealed base; variants: ${cls.sealedVariants.join(', ')}.');
    }
    if (cls.presetFactories.isNotEmpty) {
      notes.add('Preset factories: ${cls.presetFactories.join(', ')}.');
    }

    final requiredList = required.toList()..sort();
    return <String, Object?>{
      'type': 'object',
      'title': cls.name,
      if (notes.isNotEmpty) 'description': notes.join(' '),
      'properties': <String, Object?>{
        for (final param in params) param.name: _property(param, cls, model),
      },
      if (requiredList.isNotEmpty) 'required': requiredList,
      if (dependentRequired.isNotEmpty) 'dependentRequired': dependentRequired,
      if (anyOf.isNotEmpty) 'anyOf': anyOf,
      'additionalProperties': false,
      'x-dartLibrary': cls.libraryUri,
    };
  }

  /// The schema for one parameter.
  Map<String, Object?> _property(
    SurfaceParam param,
    SurfaceClass cls,
    SurfaceModel model,
  ) {
    final combined = cls.combinedSetters
        .where((setter) => setter.paramNames.contains(param.name))
        .map((setter) => setter.name)
        .firstOrNull;
    final schema = <String, Object?>{
      ..._typeSchema(param, model),
    };
    final notes = <String>[
      if (cls.paramNotes[param.name] case final String note) note,
    ];
    if (notes.isNotEmpty) {
      final existing = schema['description'];
      schema['description'] =
          existing == null ? notes.join(' ') : '$existing ${notes.join(' ')}';
    }
    if (_mutationNotes[param.kind] case final String note) {
      schema['x-mutation'] = note;
    } else if (combined != null) {
      // The class couples this parameter to its siblings, so the generated
      // fluent surface has NO individual `withMinorColor`: the group moves
      // through one setter. Naming it here keeps that fact machine-readable
      // instead of leaving it to be re-derived from prose.
      schema['x-combinedSetter'] = combined;
    }
    if (param.defaultCode case final String code) {
      final literal = _defaultLiteral(code, param);
      if (literal != null) {
        schema['default'] = literal;
      } else {
        schema['x-defaultSource'] = code;
      }
    }
    schema['x-dartType'] = param.dartType;
    return schema;
  }

  /// The type half of a property schema.
  Map<String, Object?> _typeSchema(SurfaceParam param, SurfaceModel model) {
    switch (param.kind) {
      case SurfaceParamKind.triState:
        return _triState(param, model);
      case SurfaceParamKind.enumType:
        return <String, Object?>{
          'type': 'string',
          'enum': [...param.enumValues],
        };
      case SurfaceParamKind.nestedConfig:
        final name = stripNullability(param.dartType);
        if (model.tryByName(name) != null) {
          return <String, Object?>{r'$ref': '$refPrefix$name'};
        }
        return _opaque(name);
      case SurfaceParamKind.listValue:
        return <String, Object?>{
          'type': 'array',
          'items': _argumentSchema(_typeArguments(param.dartType).firstOrNull,
              param, model),
        };
      case SurfaceParamKind.mapValue:
        final args = _typeArguments(param.dartType);
        return <String, Object?>{
          'type': 'object',
          'additionalProperties': _argumentSchema(
              args.length > 1 ? args[1] : null, param, model),
        };
      case SurfaceParamKind.value:
      case SurfaceParamKind.excludedByAnnotation:
      case SurfaceParamKind.excludedNoCopyWithParam:
      case SurfaceParamKind.excludedFunction:
      case SurfaceParamKind.excludedController:
      case SurfaceParamKind.excludedDeprecated:
        return _valueSchema(stripNullability(param.dartType), param, model);
    }
  }

  /// The `{value | none | inherit}` union for a `ChartStyleValue<X>` field.
  Map<String, Object?> _triState(SurfaceParam param, SurfaceModel model) {
    final payload = param.triStatePayloadType ?? 'Object';
    return <String, Object?>{
      'description':
          'Tri-state style value. Supply a $payload to override, the string '
          '"none" to clear the property outright, or the string "inherit" to '
          'fall back to the active theme.',
      'oneOf': <Map<String, Object?>>[
        {
          'title': 'value',
          ..._valueSchema(stripNullability(payload), param, model),
        },
        {'title': 'none', 'const': 'none'},
        {'title': 'inherit', 'const': 'inherit'},
      ],
    };
  }

  /// Schema for a bare (non-collection) type NAME.
  Map<String, Object?> _valueSchema(
    String type,
    SurfaceParam param,
    SurfaceModel model,
  ) {
    if (_scalarSchemas[type] case final Map<String, Object?> scalar) {
      return <String, Object?>{...scalar};
    }
    if (type.startsWith('List<')) {
      return <String, Object?>{
        'type': 'array',
        'items': _argumentSchema(_typeArguments(type).firstOrNull, param, model),
      };
    }
    if (type.startsWith('Map<')) {
      final args = _typeArguments(type);
      return <String, Object?>{
        'type': 'object',
        'additionalProperties':
            _argumentSchema(args.length > 1 ? args[1] : null, param, model),
      };
    }
    if (type.startsWith('Set<')) {
      return <String, Object?>{
        'type': 'array',
        'uniqueItems': true,
        'items': _argumentSchema(_typeArguments(type).firstOrNull, param, model),
      };
    }
    final nested = model.tryByName(type);
    if (nested != null) {
      return <String, Object?>{r'$ref': '$refPrefix$type'};
    }
    if (param.enumValues.isNotEmpty) {
      return <String, Object?>{
        'type': 'string',
        'enum': [...param.enumValues],
      };
    }
    return _opaque(type);
  }

  /// Schema for a type ARGUMENT (`List<X>`'s `X`).
  Map<String, Object?> _argumentSchema(
    String? type,
    SurfaceParam param,
    SurfaceModel model,
  ) {
    if (type == null || type.isEmpty) return const <String, Object?>{};
    return _valueSchema(stripNullability(type.trim()), param, model);
  }

  /// A type the schema cannot decompose, named rather than hidden.
  Map<String, Object?> _opaque(String type) => <String, Object?>{
        'description':
            'Opaque `$type` value: this type is not part of the modelled '
            'config surface and has no canonical JSON encoding.',
        'x-dartType': type,
      };
}

/// The parameters that reach the structural schema.
List<SurfaceParam> _schemaParams(SurfaceClass cls) => [
      for (final param in cls.params)
        if (!isOmittedFromSchema(param)) param,
    ];

/// Splits `Map<String, List<int>>` into `['String', 'List<int>']`.
List<String> _typeArguments(String type) {
  final open = type.indexOf('<');
  if (open < 0) return const [];
  final close = type.lastIndexOf('>');
  if (close <= open) return const [];
  final inner = type.substring(open + 1, close);
  final parts = <String>[];
  var depth = 0;
  var start = 0;
  for (var i = 0; i < inner.length; i++) {
    final ch = inner[i];
    if (ch == '<') depth++;
    if (ch == '>') depth--;
    if (ch == ',' && depth == 0) {
      parts.add(inner.substring(start, i).trim());
      start = i + 1;
    }
  }
  parts.add(inner.substring(start).trim());
  return parts;
}

/// A JSON literal for [code], or `null` when the default is an expression
/// only Dart can evaluate.
///
/// Never EVALUATES anything: the reader hands over source text, and only the
/// shapes that are unambiguously JSON are translated. An enum member lowers to
/// its NAME, matching how the enum property is typed.
Object? _defaultLiteral(String code, SurfaceParam param) {
  final trimmed = code.trim();
  if (param.kind == SurfaceParamKind.triState) {
    // `const ChartStyleValue<Color>.inherit()` is one of the union's own
    // members, so it lowers to that member's literal rather than to an opaque
    // source string.
    if (trimmed.endsWith('.inherit()')) return 'inherit';
    if (trimmed.endsWith('.none()')) return 'none';
    return null;
  }
  if (trimmed == 'null') return null;
  if (trimmed == 'true') return true;
  if (trimmed == 'false') return false;
  final number = num.tryParse(trimmed);
  if (number != null) return number;
  if (trimmed.length >= 2 &&
      (trimmed.startsWith("'") && trimmed.endsWith("'") ||
          trimmed.startsWith('"') && trimmed.endsWith('"')) &&
      !trimmed.substring(1, trimmed.length - 1).contains(r'$')) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  final empty = trimmed.replaceAll(RegExp(r'\s'), '');
  if (empty == '[]' || empty == 'const[]') return const <Object?>[];
  if (empty == '{}' || empty == 'const{}') {
    return param.kind == SurfaceParamKind.mapValue
        ? const <String, Object?>{}
        : const <Object?>[];
  }
  if (param.kind == SurfaceParamKind.enumType) {
    final dot = trimmed.lastIndexOf('.');
    if (dot > 0) {
      final member = trimmed.substring(dot + 1);
      if (param.enumValues.contains(member)) return member;
    }
  }
  return null;
}

/// Renders a JSON value as a Dart `const`-compatible literal.
String _dart(Object? value, int depth) {
  if (value == null) return 'null';
  if (value is bool || value is num) return '$value';
  if (value is String) return "'${_escape(value)}'";
  if (value is List) {
    if (value.isEmpty) return '<Object?>[]';
    return '<Object?>[${value.map((item) => _dart(item, depth + 1)).join(', ')}]';
  }
  if (value is Map) {
    if (value.isEmpty) return '<String, Object?>{}';
    final entries = value.entries
        .map((entry) =>
            "'${_escape('${entry.key}')}': ${_dart(entry.value, depth + 1)}")
        .join(', ');
    return '<String, Object?>{$entries}';
  }
  throw ArgumentError.value(value, 'value', 'not a JSON value');
}

String _escape(String value) => value
    .replaceAll(r'\', r'\\')
    .replaceAll("'", r"\'")
    .replaceAll(r'$', r'\$')
    .replaceAll('\n', r'\n');

String _and(List<String> names) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;
  return '${names.take(names.length - 1).join(', ')} and ${names.last}';
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
