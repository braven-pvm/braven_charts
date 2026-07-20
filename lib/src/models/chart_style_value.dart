// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// A tri-state style override that distinguishes "inherit from theme",
/// "use this explicit value", and "explicitly cleared".
///
/// Nullable style fields conflate two different author intents: leaving a
/// value unset (inherit the theme default) and deliberately clearing it (no
/// background, no border). [ChartStyleValue] makes both intents first-class:
///
/// - [ChartStyleValue.inherit] resolves to the theme-provided default;
/// - [ChartStyleValue.value] resolves to the explicit payload;
/// - [ChartStyleValue.none] resolves to `null`, meaning the property is
///   cleared and must not fall back to a theme default.
///
/// The hierarchy is sealed so consumers can switch over the three variants
/// exhaustively. It is currently scoped to the Cartesian value summary style
/// and is not a package-wide styling refactor.
///
/// Example:
/// ```dart
/// const style = CartesianValueSummaryStyle(
///   backgroundColor: ChartStyleValue.value(Color(0xEE1E2430)),
///   borderColor: ChartStyleValue.none(), // truly no stroke
///   // Everything else inherits the theme defaults.
/// );
/// ```
sealed class ChartStyleValue<T> {
  const ChartStyleValue._();

  /// The property inherits the theme-provided default.
  const factory ChartStyleValue.inherit() = ChartStyleInherit<T>;

  /// The property uses the explicit [value], overriding the theme default.
  const factory ChartStyleValue.value(T value) = ChartStyleExplicit<T>;

  /// The property is explicitly cleared and resolves to `null`.
  ///
  /// A cleared value never falls back to the theme default. For surfaces this
  /// means truly transparent; for strokes it means no visible line.
  const factory ChartStyleValue.none() = ChartStyleNone<T>;

  /// Resolves this override against the theme-provided [themeDefault].
  ///
  /// Returns [themeDefault] for [ChartStyleValue.inherit], the explicit
  /// payload for [ChartStyleValue.value], and `null` for
  /// [ChartStyleValue.none].
  T? resolve(T? themeDefault);

  /// Whether this override explicitly clears the property.
  bool get isNone;

  /// Whether this override inherits the theme default.
  bool get isInherit;
}

/// The [ChartStyleValue.inherit] variant.
final class ChartStyleInherit<T> extends ChartStyleValue<T> {
  /// Creates an inherit override.
  const ChartStyleInherit() : super._();

  @override
  T? resolve(T? themeDefault) => themeDefault;

  @override
  bool get isNone => false;

  @override
  bool get isInherit => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChartStyleInherit<T>;

  @override
  int get hashCode => Object.hash(T, 'inherit');

  @override
  String toString() => 'ChartStyleValue<$T>.inherit()';
}

/// The [ChartStyleValue.value] variant carrying an explicit payload.
final class ChartStyleExplicit<T> extends ChartStyleValue<T> {
  /// Creates an explicit-value override.
  const ChartStyleExplicit(this.value) : super._();

  /// The explicit value that overrides the theme default.
  final T value;

  @override
  T? resolve(T? themeDefault) => value;

  @override
  bool get isNone => false;

  @override
  bool get isInherit => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartStyleExplicit<T> && other.value == value;

  @override
  int get hashCode => Object.hash(T, value);

  @override
  String toString() => 'ChartStyleValue<$T>.value($value)';
}

/// The [ChartStyleValue.none] variant that clears the property.
final class ChartStyleNone<T> extends ChartStyleValue<T> {
  /// Creates a cleared override.
  const ChartStyleNone() : super._();

  @override
  T? resolve(T? themeDefault) => null;

  @override
  bool get isNone => true;

  @override
  bool get isInherit => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChartStyleNone<T>;

  @override
  int get hashCode => Object.hash(T, 'none');

  @override
  String toString() => 'ChartStyleValue<$T>.none()';
}
