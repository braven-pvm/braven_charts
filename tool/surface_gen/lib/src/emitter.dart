/// The swappable emitter seam between the [SurfaceModel] and each generated
/// surface (fluent extensions now, AI schema in Slice 3, `augment`
/// declarations if/when Dart ships them).
library;

import 'surface_model.dart';

/// Emits generated Dart source for one surface class or one whole library.
///
/// Both entry points live on the interface: the builder — the only production
/// caller — emits WHOLE LIBRARIES, and an interface that only described
/// per-class emission would be bypassed in production, which is exactly the
/// insurance the "swappable emitter" is supposed to buy. Slice 3's
/// `AiSchemaEmitter` is whole-library by nature.
abstract interface class SurfaceEmitter {
  /// Suffix of the generated file this emitter targets (e.g. `_fluent.dart`).
  String get outputSuffix;

  /// Returns formatted Dart source for [cls], or an empty string when the
  /// class yields nothing (no `copyWith`, or every parameter excluded).
  ///
  /// [model] carries the whole read surface for cross-class lookups.
  String emit(SurfaceClass cls, SurfaceModel model);

  /// Returns the complete generated library for [model] — header, derived
  /// imports and every emittable class — or `null` when nothing is emittable
  /// (the builder then writes no file at all).
  String? emitLibrary(SurfaceModel model);
}
