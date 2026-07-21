/// The swappable emitter seam between the [SurfaceModel] and each generated
/// surface (fluent extensions now, AI schema in Slice 3, `augment`
/// declarations if/when Dart ships them).
library;

import 'surface_model.dart';

/// Emits generated Dart source for one surface class.
abstract interface class SurfaceEmitter {
  /// Suffix of the generated file this emitter targets (e.g. `_fluent.dart`).
  String get outputSuffix;

  /// Returns formatted Dart source for [cls], or an empty string when the
  /// class yields nothing (no `copyWith`, or every parameter excluded).
  ///
  /// [model] carries the whole read surface for cross-class lookups.
  String emit(SurfaceClass cls, SurfaceModel model);
}
