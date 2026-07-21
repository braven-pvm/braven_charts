/// Regression suite for the Slice 1 independent-review engine findings
/// (E1–E16). Every group here reproduces a failure the reviewer proved
/// empirically against the real fleet, then pins the fix.
///
/// Reader-level findings resolve real sources through `resolveSources`;
/// emitter-level findings build [SurfaceClass] literals directly so the
/// emitted text is asserted verbatim.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:surface_gen/src/emitter.dart';
import 'package:surface_gen/src/fluent_emitter.dart';
import 'package:surface_gen/src/surface_model.dart';
import 'package:surface_gen/src/surface_reader.dart';
import 'package:test/test.dart';

/// The `ChartSurface` annotation contract, mirrored verbatim so the reader's
/// name+shape matching applies exactly as it does against the real
/// `lib/src/meta/chart_surface.dart`.
const String _preamble = '''
class ChartSurface {
  const ChartSurface({
    this.presetFactories = const <String>[],
    this.sealedVariants = const <String>[],
    this.combinedSetters = const <CombinedSetter>[],
    this.excluded = const <String>[],
    this.clearFlags = const <String, String>{},
  });
  final List<String> presetFactories;
  final List<String> sealedVariants;
  final List<CombinedSetter> combinedSetters;
  final List<String> excluded;
  final Map<String, String> clearFlags;
}

class CombinedSetter {
  const CombinedSetter(this.name, this.params);
  final String name;
  final List<String> params;
}

const chartSurface = ChartSurface();
''';

Future<T> _withSource<T>(
  String body,
  Future<T> Function(LibraryElement) action,
) async {
  const asset = 'surface_gen|test/fixtures/inline_fixture.dart';
  return resolveSources({asset: '$_preamble\n$body'}, (resolver) async {
    final library = await resolver.libraryFor(AssetId.parse(asset));
    return action(library);
  });
}

Future<SurfaceModel> _read(String body) => _withSource(
      body,
      (library) => const AnalyzerSurfaceReader().read(library),
    );

Future<void> _expectReadThrows(String body, Matcher matcher) async {
  await _withSource(body, (library) async {
    await expectLater(const AnalyzerSurfaceReader().read(library), matcher);
  });
}

void main() {
  const emitter = FluentEmitter();

  // =========================================================================
  // E1 — copyWith cross-check (ChartTheme's deprecated private-backed params)
  // =========================================================================

  group('E1 copyWith cross-check', () {
    const chartThemeShape = '''
@chartSurface
class FixtureTheme {
  const FixtureTheme({
    this.backgroundColor = 0,
    this.legacyTag = 'x',
    @Deprecated('Use gridStyle.majorColor instead') int? gridColor,
    @Deprecated('Use axisStyle.lineColor instead') int? axisColor,
  })  : _gridColor = gridColor,
        _axisColor = axisColor;

  final int backgroundColor;
  final String legacyTag;
  final int? _gridColor;
  final int? _axisColor;

  @Deprecated('Use gridStyle.majorColor instead')
  int get gridColor => _gridColor ?? 0;

  @Deprecated('Use axisStyle.lineColor instead')
  int get axisColor => _axisColor ?? 0;

  FixtureTheme copyWith({int? backgroundColor}) =>
      FixtureTheme(backgroundColor: backgroundColor ?? this.backgroundColor);
}
''';

    test('a ctor param with no same-named copyWith param is dropped and '
        'recorded', () async {
      final model = await _read(chartThemeShape);
      final cls = model.byName('FixtureTheme');
      expect(
        cls.params.singleWhere((p) => p.name == 'legacyTag').kind,
        SurfaceParamKind.excludedNoCopyWithParam,
      );
    });

    test('parameter-level @Deprecated is recorded and skipped', () async {
      final model = await _read(chartThemeShape);
      final cls = model.byName('FixtureTheme');
      for (final name in ['gridColor', 'axisColor']) {
        expect(
          cls.params.singleWhere((p) => p.name == name).kind,
          SurfaceParamKind.excludedDeprecated,
          reason: name,
        );
      }
    });

    test('the emitted extension names only real copyWith parameters', () async {
      final model = await _read(chartThemeShape);
      final source = emitter.emitLibrary(model)!;
      expect(source, contains('withBackgroundColor'));
      expect(source, isNot(contains('gridColor')));
      expect(source, isNot(contains('axisColor')));
      expect(source, isNot(contains('legacyTag')));
    });
  });

  // =========================================================================
  // E2 — import derivation from the analyzer's library origins
  // =========================================================================

  group('E2 derived imports', () {
    const cls = SurfaceClass(
      name: 'FixtureStyle',
      libraryUri: 'package:braven_charts/src/models/fixture_style.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureStyle',
      params: [
        SurfaceParam(
          name: 'color',
          dartType: 'Color',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: false,
          typeOrigins: {'Color': 'dart:ui'},
        ),
        SurfaceParam(
          name: 'labelStyle',
          dartType: 'TextStyle',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: false,
          typeOrigins: {
            'TextStyle': 'package:flutter/src/painting/text_style.dart',
          },
        ),
        SurfaceParam(
          name: 'fade',
          dartType: 'Duration',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: false,
          typeOrigins: {'Duration': 'dart:core'},
        ),
        SurfaceParam(
          name: 'trigger',
          dartType: 'TooltipTriggerMode',
          kind: SurfaceParamKind.enumType,
          isRequired: false,
          isNullable: false,
          typeOrigins: {
            'TooltipTriggerMode':
                'package:braven_charts/src/models/tooltip_config.dart',
          },
        ),
      ],
    );

    test('the flutter import shows exactly the flutter-origin names used', () {
      final source = emitter.emitLibrary(const SurfaceModel([cls]))!;
      expect(
        source,
        contains("import 'package:flutter/widgets.dart' show Color, TextStyle;"),
      );
    });

    test('dart:core names never appear in the show clause', () {
      final source = emitter.emitLibrary(const SurfaceModel([cls]))!;
      expect(source, isNot(contains('Duration,')));
      expect(source, isNot(contains('show Duration')));
    });

    test('a braven_charts name that flutter also defines is not shown', () {
      final source = emitter.emitLibrary(const SurfaceModel([cls]))!;
      expect(source, isNot(contains('TooltipTriggerMode,')));
      expect(source, isNot(contains('TooltipTriggerMode;')));
    });

    test('no flutter import when no signature has a flutter-origin type', () {
      const plain = SurfaceClass(
        name: 'FixturePlain',
        libraryUri: 'package:braven_charts/src/models/fixture_plain.dart',
        isConstConstructible: true,
        hasCopyWith: true,
        copyWithReturnType: 'FixturePlain',
        params: [
          SurfaceParam(
            name: 'count',
            dartType: 'int',
            kind: SurfaceParamKind.value,
            isRequired: false,
            isNullable: false,
            typeOrigins: {'int': 'dart:core'},
          ),
        ],
      );
      final source = emitter.emitLibrary(const SurfaceModel([plain]))!;
      expect(source, isNot(contains('package:flutter/')));
    });
  });

  // =========================================================================
  // E3 — slicing copyWith guard (ChartSeries shape)
  // =========================================================================

  group('E3 slicing copyWith guard', () {
    test('an annotated base whose subclass overrides copyWith fails', () async {
      await _expectReadThrows(
        '''
@chartSurface
class FixtureSeries {
  const FixtureSeries({this.id = ''});
  final String id;
  FixtureSeries copyWith({String? id}) => FixtureSeries(id: id ?? this.id);
}

class FixtureLine extends FixtureSeries {
  const FixtureLine({super.id, this.width = 1.0});
  final double width;
  @override
  FixtureLine copyWith({String? id, double? width}) =>
      FixtureLine(id: id ?? this.id, width: width ?? this.width);
}
''',
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('slicing copyWith'))
              .having((e) => e.message, 'message', contains('FixtureSeries'))
              .having((e) => e.message, 'message', contains('FixtureLine'))
              .having(
                (e) => e.message,
                'message',
                contains('ChartSurfaceExempt'),
              ),
        ),
      );
    });

    test('a subclass that does not override copyWith is fine', () async {
      final model = await _read('''
@chartSurface
class FixtureStyle {
  const FixtureStyle({this.opacity = 1.0});
  final double opacity;
  FixtureStyle copyWith({double? opacity}) =>
      FixtureStyle(opacity: opacity ?? this.opacity);
}

class FixtureTintedStyle extends FixtureStyle {
  const FixtureTintedStyle() : super(opacity: 0.5);
}
''');
      expect(model.byName('FixtureStyle').copyWithReturnType, 'FixtureStyle');
    });
  });

  // =========================================================================
  // E4 — combined setters strip nullability
  // =========================================================================

  group('E4 combined setters strip nullability', () {
    const axis = SurfaceClass(
      name: 'FixtureAxis',
      libraryUri: 'package:braven_charts/src/models/fixture_axis.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureAxis',
      combinedSetters: [
        CombinedSetterModel('withVisibleRange', ['min', 'max']),
      ],
      params: [
        SurfaceParam(
          name: 'min',
          dartType: 'double?',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: true,
        ),
        SurfaceParam(
          name: 'max',
          dartType: 'double?',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: true,
        ),
      ],
    );

    test('the combined signature is non-nullable', () {
      final source = emitter.emit(axis, const SurfaceModel([axis]));
      expect(source, contains('withVisibleRange(double min, double max)'));
      expect(source, isNot(contains('double? min')));
    });

    test('a group with no clear support says so in the dartdoc', () {
      final source = emitter.emit(axis, const SurfaceModel([axis]));
      expect(source, contains('cannot unset'));
    });

    test('a group whose members have clear flags gains clear verbs', () {
      const withFlags = SurfaceClass(
        name: 'FixtureAxis',
        libraryUri: 'package:braven_charts/src/models/fixture_axis.dart',
        isConstConstructible: true,
        hasCopyWith: true,
        copyWithReturnType: 'FixtureAxis',
        combinedSetters: [
          CombinedSetterModel('withVisibleRange', ['min', 'max']),
        ],
        params: [
          SurfaceParam(
            name: 'min',
            dartType: 'double?',
            kind: SurfaceParamKind.value,
            isRequired: false,
            isNullable: true,
            clearFlag: 'clearMin',
          ),
          SurfaceParam(
            name: 'max',
            dartType: 'double?',
            kind: SurfaceParamKind.value,
            isRequired: false,
            isNullable: true,
            clearFlag: 'clearMax',
          ),
        ],
      );
      final source = emitter.emit(withFlags, const SurfaceModel([withFlags]));
      expect(source, contains('clearMin() => copyWith(clearMin: true)'));
      expect(source, contains('clearMax() => copyWith(clearMax: true)'));
    });
  });

  // =========================================================================
  // E5 — verb vocabulary split: tri-state suppress is `withoutX`
  // =========================================================================

  group('E5 verb vocabulary', () {
    const style = SurfaceClass(
      name: 'FixtureStyle',
      libraryUri: 'package:braven_charts/src/models/fixture_style.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureStyle',
      params: [
        SurfaceParam(
          name: 'shadow',
          dartType: 'ChartStyleValue<BoxShadow>',
          kind: SurfaceParamKind.triState,
          isRequired: false,
          isNullable: false,
          triStatePayloadType: 'BoxShadow',
        ),
      ],
    );

    test('tri-state suppress is withoutX, never clearX', () {
      final source = emitter.emit(style, const SurfaceModel([style]));
      expect(source, contains('withoutShadow()'));
      expect(
        source,
        contains('copyWith(shadow: const ChartStyleValue<BoxShadow>.none())'),
      );
      expect(source, isNot(contains('clearShadow')));
    });

    test('inheritX is unchanged', () {
      final source = emitter.emit(style, const SurfaceModel([style]));
      expect(source, contains('inheritShadow()'));
    });
  });

  // =========================================================================
  // E6 — clearFlags derived from the copyWith signature
  // =========================================================================

  group('E6 derived clear flags', () {
    const scatterShape = '''
@chartSurface
class FixtureScatterSeries {
  const FixtureScatterSeries({
    this.markerStyle,
    this.renderConfig,
    this.colorBy,
    this.sizeBy,
    this.opacityBy,
    this.categoryBy,
  });

  final String? markerStyle;
  final String? renderConfig;
  final String? colorBy;
  final String? sizeBy;
  final String? opacityBy;
  final String? categoryBy;

  FixtureScatterSeries copyWith({
    String? markerStyle,
    bool clearMarkerStyle = false,
    String? renderConfig,
    bool clearRenderConfig = false,
    String? colorBy,
    bool clearColorBy = false,
    String? sizeBy,
    bool clearSizeBy = false,
    String? opacityBy,
    bool clearOpacityBy = false,
    String? categoryBy,
    bool clearCategoryBy = false,
  }) {
    return FixtureScatterSeries(
      markerStyle: clearMarkerStyle ? null : (markerStyle ?? this.markerStyle),
      renderConfig: clearRenderConfig ? null : (renderConfig ?? this.renderConfig),
      colorBy: clearColorBy ? null : (colorBy ?? this.colorBy),
      sizeBy: clearSizeBy ? null : (sizeBy ?? this.sizeBy),
      opacityBy: clearOpacityBy ? null : (opacityBy ?? this.opacityBy),
      categoryBy: clearCategoryBy ? null : (categoryBy ?? this.categoryBy),
    );
  }
}
''';

    test('every `bool clearFoo` copyWith flag is derived automatically',
        () async {
      final model = await _read(scatterShape);
      final cls = model.byName('FixtureScatterSeries');
      expect(
        {for (final p in cls.params) p.name: p.clearFlag},
        {
          'markerStyle': 'clearMarkerStyle',
          'renderConfig': 'clearRenderConfig',
          'colorBy': 'clearColorBy',
          'sizeBy': 'clearSizeBy',
          'opacityBy': 'clearOpacityBy',
          'categoryBy': 'clearCategoryBy',
        },
      );
    });

    test('derived flags produce clear verbs', () async {
      final model = await _read(scatterShape);
      final source = emitter.emitLibrary(model)!;
      expect(source, contains('clearMarkerStyle() => copyWith('));
      expect(source, contains('clearCategoryBy() => copyWith('));
    });

    test('annotation metadata overrides the derived flag', () async {
      final model = await _read('''
@ChartSurface(clearFlags: {'label': 'resetLabel'})
class FixtureOverride {
  const FixtureOverride({this.label});
  final String? label;
  FixtureOverride copyWith({
    String? label,
    bool clearLabel = false,
    bool resetLabel = false,
  }) => FixtureOverride(label: (clearLabel || resetLabel) ? null : label ?? this.label);
}
''');
      expect(
        model.byName('FixtureOverride').params.single.clearFlag,
        'resetLabel',
      );
    });
  });

  // =========================================================================
  // E7 — assert-coupled parameter safety
  // =========================================================================

  group('E7 assert-coupled parameters', () {
    const barShape = '''
@chartSurface
class FixtureBarSeries {
  const FixtureBarSeries({this.minWidth = 4.0, this.maxWidth = 100.0})
      : assert(minWidth >= 0, 'minWidth must be non-negative'),
        assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth');
  final double minWidth;
  final double maxWidth;
  FixtureBarSeries copyWith({double? minWidth, double? maxWidth}) =>
      FixtureBarSeries(
        minWidth: minWidth ?? this.minWidth,
        maxWidth: maxWidth ?? this.maxWidth,
      );
}
''';

    test('an uncovered multi-param assert fails with a named diagnostic',
        () async {
      await _expectReadThrows(
        barShape,
        throwsA(
          isA<StateError>()
              .having(
                (e) => e.message,
                'message',
                contains('assert-coupled parameters'),
              )
              .having((e) => e.message, 'message', contains('FixtureBarSeries'))
              .having((e) => e.message, 'message', contains('maxWidth'))
              .having((e) => e.message, 'message', contains('minWidth'))
              .having((e) => e.message, 'message', contains('CombinedSetter')),
        ),
      );
    });

    test('a covering combinedSetter satisfies the guard and records the group',
        () async {
      final model = await _read('''
@ChartSurface(
  combinedSetters: [CombinedSetter('withWidthBounds', ['minWidth', 'maxWidth'])],
)
class FixtureBarSeries {
  const FixtureBarSeries({this.minWidth = 4.0, this.maxWidth = 100.0})
      : assert(minWidth >= 0, 'minWidth must be non-negative'),
        assert(maxWidth >= minWidth, 'maxWidth must be >= minWidth');
  final double minWidth;
  final double maxWidth;
  FixtureBarSeries copyWith({double? minWidth, double? maxWidth}) =>
      FixtureBarSeries(
        minWidth: minWidth ?? this.minWidth,
        maxWidth: maxWidth ?? this.maxWidth,
      );
}
''');
      expect(
        model.byName('FixtureBarSeries').assertGroups,
        [
          ['maxWidth', 'minWidth'],
        ],
      );
    });

    test('a NON-CONST constructor\'s asserts couple just as hard', () async {
      // Task 6 finding: the whole annotation family
      // (`RangeAnnotation`, `ChordAnnotation`, `TrendAnnotation`, ...) has a
      // non-const unnamed constructor, because it defaults `id` through
      // `super(id: id ?? ChartAnnotation.generateId())`. The asserts are
      // identical to a const class's and fail at runtime identically, so the
      // guard must see them there too.
      await _expectReadThrows(
        '''
@chartSurface
class FixtureRange {
  FixtureRange({this.startX, this.endX})
      : assert(
          startX == null || endX == null || startX < endX,
          'startX must be less than endX',
        );
  final double? startX;
  final double? endX;
  FixtureRange copyWith({double? startX, double? endX}) =>
      FixtureRange(startX: startX ?? this.startX, endX: endX ?? this.endX);
}
''',
        throwsA(
          isA<StateError>()
              .having(
                (e) => e.message,
                'message',
                contains('assert-coupled parameters'),
              )
              .having((e) => e.message, 'message', contains('FixtureRange'))
              .having((e) => e.message, 'message', contains('endX'))
              .having((e) => e.message, 'message', contains('startX')),
        ),
      );
    });

    test('single-parameter asserts are not coupling', () async {
      final model = await _read('''
@chartSurface
class FixtureGap {
  const FixtureGap({this.gap = 2.0}) : assert(gap >= 0, 'gap');
  final double gap;
  FixtureGap copyWith({double? gap}) => FixtureGap(gap: gap ?? this.gap);
}
''');
      expect(model.byName('FixtureGap').assertGroups, isEmpty);
    });
  });

  // =========================================================================
  // E8 — nested updaters
  // =========================================================================

  group('E8 nested updaters', () {
    const owner = SurfaceClass(
      name: 'FixtureOwner',
      libraryUri: 'package:braven_charts/src/models/fixture_owner.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureOwner',
      params: [
        SurfaceParam(
          name: 'crosshair',
          dartType: 'CrosshairConfig',
          kind: SurfaceParamKind.nestedConfig,
          isRequired: false,
          isNullable: false,
        ),
        SurfaceParam(
          name: 'tooltip',
          dartType: 'TooltipConfig?',
          kind: SurfaceParamKind.nestedConfig,
          isRequired: false,
          isNullable: true,
        ),
      ],
    );

    test('non-nullable nested configs gain an update verb', () {
      final source = emitter.emit(owner, const SurfaceModel([owner]));
      expect(source, contains('FixtureOwner updateCrosshair('));
      expect(
        source,
        contains('CrosshairConfig Function(CrosshairConfig current) update'),
      );
      expect(source, contains('copyWith(crosshair: update(crosshair))'));
    });

    test('nullable nested configs get no update verb in v1', () {
      final source = emitter.emit(owner, const SurfaceModel([owner]));
      expect(source, isNot(contains('updateTooltip')));
    });
  });

  // =========================================================================
  // E9 — sealed-variant constructor helpers
  // =========================================================================

  group('E9 sealed variant helpers', () {
    const sealedBase = SurfaceClass(
      name: 'FixturePresentation',
      libraryUri: 'package:braven_charts/src/models/fixture_summary.dart',
      isConstConstructible: true,
      hasCopyWith: false,
      isSealed: true,
      sealedVariants: ['FixtureOverlay', 'FixtureAnnotation'],
      factories: [
        SurfaceFactoryModel('overlay', [
          SurfaceParam(
            name: 'placement',
            dartType: 'ChartOverlayPlacement',
            kind: SurfaceParamKind.enumType,
            isRequired: false,
            isNullable: false,
            defaultCode: 'ChartOverlayPlacement.topLeft',
          ),
        ]),
        SurfaceFactoryModel('annotation', [
          SurfaceParam(
            name: 'placement',
            dartType: 'ChartOverlayPlacement',
            kind: SurfaceParamKind.enumType,
            isRequired: false,
            isNullable: false,
            defaultCode: 'ChartOverlayPlacement.topLeft',
          ),
          SurfaceParam(
            name: 'draggable',
            dartType: 'bool',
            kind: SurfaceParamKind.value,
            isRequired: false,
            isNullable: false,
            defaultCode: 'false',
          ),
        ]),
      ],
      params: [],
    );

    const owner = SurfaceClass(
      name: 'FixtureSummaryConfig',
      libraryUri: 'package:braven_charts/src/models/fixture_summary.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureSummaryConfig',
      params: [
        SurfaceParam(
          name: 'presentation',
          dartType: 'FixturePresentation',
          kind: SurfaceParamKind.nestedConfig,
          isRequired: false,
          isNullable: false,
        ),
      ],
    );

    const model = SurfaceModel([sealedBase, owner]);

    test('one helper per sealed factory, named with<Factory><Param>', () {
      final source = emitter.emit(owner, model);
      expect(source, contains('withOverlayPresentation({'));
      expect(
        source,
        contains('ChartOverlayPlacement placement = '
            'ChartOverlayPlacement.topLeft'),
      );
      expect(
        source,
        contains(
          'presentation: FixturePresentation.overlay(placement: placement)',
        ),
      );
      expect(source, contains('withAnnotationPresentation({'));
      expect(source, contains('bool draggable = false'));
    });

    test('the reset semantics are documented', () {
      final source = emitter.emit(owner, model);
      expect(source, contains('Omitted parameters take their defaults.'));
    });

    test('the sealed base itself emits nothing', () {
      expect(emitter.emit(sealedBase, model), isEmpty);
    });

    test('the update escape hatch is emitted alongside', () {
      expect(emitter.emit(owner, model), contains('updatePresentation('));
    });

    test('sealed factories are read from the source, defaults included',
        () async {
      final model = await _read('''
@ChartSurface(sealedVariants: ['FixtureOverlay'])
sealed class FixturePresentation {
  const FixturePresentation._();
  const factory FixturePresentation.overlay({int placement}) = FixtureOverlay;
}

final class FixtureOverlay extends FixturePresentation {
  const FixtureOverlay({this.placement = 3}) : super._();
  final int placement;
}
''');
      final factory = model.byName('FixturePresentation').factories.single;
      expect(factory.name, 'overlay');
      expect(factory.params.single.name, 'placement');
      expect(factory.params.single.defaultCode, '3');
    });
  });

  // =========================================================================
  // E10 — generic classes
  // =========================================================================

  group('E10 generic classes', () {
    test('type parameters are read', () async {
      final model = await _read('''
@chartSurface
class FixtureSpec<T extends num> {
  const FixtureSpec({this.value});
  final T? value;
  FixtureSpec<T> copyWith({T? value}) => FixtureSpec<T>(value: value ?? this.value);
}
''');
      expect(model.byName('FixtureSpec').typeParameters, ['T extends num']);
    });

    test('the extension carries the type parameters', () async {
      final model = await _read('''
@chartSurface
class FixtureSpec<T extends num> {
  const FixtureSpec({this.value});
  final T? value;
  FixtureSpec<T> copyWith({T? value}) => FixtureSpec<T>(value: value ?? this.value);
}
''');
      final source = emitter.emitLibrary(model)!;
      expect(
        source,
        contains(
          'extension FixtureSpecFluent<T extends num> on FixtureSpec<T> {',
        ),
      );
      expect(source, contains('FixtureSpec<T> withValue(T value)'));
    });
  });

  // =========================================================================
  // E11 — non-exported classes
  // =========================================================================

  group('E11 barrel reachability', () {
    const hidden = SurfaceClass(
      name: 'FixtureHidden',
      libraryUri: 'package:braven_charts/src/models/fixture_hidden.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureHidden',
      params: [
        SurfaceParam(
          name: 'value',
          dartType: 'int',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: false,
        ),
      ],
    );

    test('emitting a class absent from the barrel fails loudly', () {
      const guarded = FluentEmitter(exportedNames: {'SomethingElse'});
      expect(
        () => guarded.emitLibrary(const SurfaceModel([hidden])),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('FixtureHidden'))
              .having((e) => e.message, 'message', contains('not exported')),
        ),
      );
    });

    test('an exported class passes the guard', () {
      const guarded = FluentEmitter(exportedNames: {'FixtureHidden'});
      expect(guarded.emitLibrary(const SurfaceModel([hidden])), isNotNull);
    });
  });

  // =========================================================================
  // E12 — emitter seam
  // =========================================================================

  group('E12 emitter seam', () {
    test('emitLibrary is reachable through the SurfaceEmitter interface', () {
      const probe = SurfaceEmitterProbe(FluentEmitter());
      expect(probe.emitAnything(const SurfaceModel([])), isNull);
    });
  });

  // =========================================================================
  // E13 — `is`-prefixed bool naming
  // =========================================================================

  group('E13 is-prefixed booleans', () {
    test('withIsXOrdered becomes withXOrdered', () {
      const cls = SurfaceClass(
        name: 'FixtureSeries',
        libraryUri: 'package:braven_charts/src/models/fixture_series.dart',
        isConstConstructible: true,
        hasCopyWith: true,
        copyWithReturnType: 'FixtureSeries',
        params: [
          SurfaceParam(
            name: 'isXOrdered',
            dartType: 'bool',
            kind: SurfaceParamKind.value,
            isRequired: false,
            isNullable: false,
          ),
          SurfaceParam(
            name: 'island',
            dartType: 'bool',
            kind: SurfaceParamKind.value,
            isRequired: false,
            isNullable: false,
          ),
        ],
      );
      final source = emitter.emit(cls, const SurfaceModel([cls]));
      expect(source, contains('withXOrdered(bool value)'));
      expect(source, isNot(contains('withIsXOrdered')));
      expect(source, contains('withIsland(bool value)'));
    });
  });

  // =========================================================================
  // E15 — the nullable gap is documented and counted
  // =========================================================================

  group('E15 nullable gap', () {
    const cls = SurfaceClass(
      name: 'FixtureConfig',
      libraryUri: 'package:braven_charts/src/models/fixture_config.dart',
      isConstConstructible: true,
      hasCopyWith: true,
      copyWithReturnType: 'FixtureConfig',
      params: [
        SurfaceParam(
          name: 'label',
          dartType: 'String?',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: true,
        ),
        SurfaceParam(
          name: 'title',
          dartType: 'String?',
          kind: SurfaceParamKind.value,
          isRequired: false,
          isNullable: true,
          clearFlag: 'clearTitle',
        ),
      ],
    );

    test('a nullable param with no clear verb documents the gap', () {
      final source = emitter.emit(cls, const SurfaceModel([cls]));
      expect(
        source,
        contains(
          "/// No clear verb: this class's copyWith cannot unset\n"
          '  /// [FixtureConfig.label]; construct a new instance to reset it.',
        ),
      );
    });

    test('a nullable param WITH a clear verb carries no gap note', () {
      final source = emitter.emit(cls, const SurfaceModel([cls]));
      final titleDoc = source.split('withTitle').first;
      expect(titleDoc.split('No clear verb').length - 1, 1);
    });

    test('the gap count is reported', () {
      expect(countParamsWithoutClearVerb(const SurfaceModel([cls])), 1);
    });
  });

  // =========================================================================
  // E16 — mutation-testing gaps
  // =========================================================================

  group('E16 inherited copyWith', () {
    const inheritedShape = '''
@chartSurface
class FixtureBase {
  const FixtureBase({this.opacity = 1.0});
  final double opacity;
  FixtureBase copyWith({double? opacity}) =>
      FixtureBase(opacity: opacity ?? this.opacity);
}

@chartSurface
class FixtureDerived extends FixtureBase {
  const FixtureDerived({super.opacity, this.tint = 0});
  final int tint;
}
''';

    test('an inherited copyWith is detected (hasCopyWith stays true)',
        () async {
      final model = await _read(inheritedShape);
      final derived = model.byName('FixtureDerived');
      expect(derived.hasCopyWith, isTrue);
      expect(derived.copyWithReturnType, 'FixtureBase');
    });

    test('an inherited base-typed copyWith fails loudly instead of silently '
        'emitting nothing', () async {
      final model = await _read(inheritedShape);
      expect(
        () => emitter.emit(
          model.byName('FixtureDerived'),
          model,
        ),
        throwsA(
          isA<StateError>()
              .having((e) => e.message, 'message', contains('FixtureDerived'))
              .having((e) => e.message, 'message', contains('copyWith returns')),
        ),
      );
    });
  });
}

/// Probe proving `emitLibrary` lives on the [SurfaceEmitter] interface (E12).
class SurfaceEmitterProbe {
  const SurfaceEmitterProbe(this.emitter);

  final SurfaceEmitter emitter;

  String? emitAnything(SurfaceModel model) => emitter.emitLibrary(model);
}
