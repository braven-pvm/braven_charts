// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Typed encoding channels for the grammar-of-graphics spec layer.
///
/// A channel binds one field of a row type to one visual property that the
/// renderer resolves through a SCALE — marker area, a color ramp, opacity, or
/// a categorical palette. Channels are deliberately not available on every
/// mark: only [ScatterMark] carries them, because scatter is the only series
/// family in this package with scale-driven encodings today. That makes the
/// coordinate x geometry validity matrix a COMPILE-TIME property instead of a
/// runtime throw.
library;

/// Reads one value of type `V` out of one row of type `T`.
///
/// Accessors are ordinary Dart functions, so a top-level function or a static
/// method is a constant expression and marks built from them are const.
typedef FieldAccessor<T, V> = V Function(T row);

/// How a channel's data domain maps onto its visual range.
///
/// Every channel has exactly one scale the render pipeline implements today:
///
/// | channel     | native scale        | why |
/// |-------------|---------------------|-----|
/// | `size`      | [ChannelScale.sqrt] | `ScatterSizeEncoding` interpolates marker AREA, so radius grows as the square root of the value — the perceptually correct mapping. |
/// | `colorBy`   | [ChannelScale.linear] | `ScatterColorEncoding` interpolates the ramp linearly in value. |
/// | `opacityBy` | [ChannelScale.linear] | `ScatterOpacityEncoding` interpolates opacity linearly in value. |
///
/// Leaving [Channel.scale] null selects the native scale. Naming the native
/// scale explicitly is accepted and changes nothing. Naming the OTHER one is
/// rejected at lowering time with
/// `GrammarDiagnosticCode.unsupportedChannelScale` rather than silently
/// rendering a different mapping than the one that was asked for.
enum ChannelScale {
  /// The visual property is proportional to the data value.
  linear,

  /// The visual property is proportional to the square root of the value —
  /// equivalently, the marker AREA is proportional to the value.
  sqrt,
}

/// A quantitative encoding channel.
///
/// ```dart
/// ScatterMark<Ride>(
///   x: (row) => row.time,
///   y: (row) => row.power,
///   size: Channel((row) => row.effort, label: 'Effort'),
/// )
/// ```
///
/// [label] names the measure for tooltips, tables and legends. When a matching
/// encoding template is also supplied on the mark, a non-null [label] wins over
/// the template's own label so the channel stays the single place a reader
/// looks for the field's name.
class Channel<T> {
  /// Binds [accessor] to a quantitative visual property.
  const Channel(this.accessor, {this.label, this.scale});

  /// Reads the channel value out of a row.
  final FieldAccessor<T, num> accessor;

  /// Human-readable measure name used by tooltips, tables and legends.
  final String? label;

  /// Optional scale override. Null selects the channel's native scale.
  final ChannelScale? scale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel<T> &&
          other.accessor == accessor &&
          other.label == label &&
          other.scale == scale;

  @override
  int get hashCode => Object.hash(accessor, label, scale);

  @override
  String toString() => 'Channel(label: $label, scale: $scale)';
}

/// A categorical encoding channel.
///
/// The accessor may return any [Object]; the lowering stringifies it into
/// `ChartDataPoint.categoryValue`, which is the key
/// `ScatterCategoryEncoding` matches against.
class CategoryChannel<T> {
  /// Binds [accessor] to the categorical marker encoding.
  const CategoryChannel(this.accessor, {this.label});

  /// Reads the category key out of a row.
  final FieldAccessor<T, Object> accessor;

  /// Human-readable field name used by legends and tables.
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryChannel<T> &&
          other.accessor == accessor &&
          other.label == label;

  @override
  int get hashCode => Object.hash(accessor, label);

  @override
  String toString() => 'CategoryChannel(label: $label)';
}
