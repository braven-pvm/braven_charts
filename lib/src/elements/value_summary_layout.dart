// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Shared layout and paint pipeline for the Cartesian value summary panel.
///
/// Both summary presentations — the fixed overlay and the draggable
/// annotation-style panel — measure and paint through [ValueSummaryLayout] so
/// content, styling, RTL behavior, and text scaling stay identical between
/// them. Layout results are cached (see [ValueSummaryLayout.layout]) so a
/// stationary panel repaints without re-laying-out text.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import '../models/cartesian_value_summary_config.dart'
    show CartesianValueSummaryContentModel, CartesianValueSummaryRow;
import '../models/cartesian_value_summary_style.dart';
import '../theming/components/cartesian_value_summary_theme.dart';

/// Horizontal gap between a row label and its right-aligned value.
const double _labelValueGap = 12.0;

/// Horizontal gap between a series swatch and the text that follows it.
const double _swatchTextGap = 6.0;

/// The effective, fully-resolved style the summary layout paints with.
///
/// This is the product of `CartesianValueSummaryStyle ×
/// CartesianValueSummaryTheme` via `ChartStyleValue.resolve`, computed once
/// where the theme lives (element construction / render box) via [resolve].
/// Fields are plain nullable values: where the tri-state style allows
/// `ChartStyleValue.none`, `null` means "explicitly cleared" — a null
/// [backgroundColor] paints no surface at all and a null [borderColor] draws
/// no stroke. Cleared values never fall back to a theme default.
@immutable
class ResolvedValueSummaryStyle {
  /// Creates a resolved style. Prefer [resolve] outside of tests.
  const ResolvedValueSummaryStyle({
    this.backgroundColor,
    this.backgroundOpacity,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    required this.titleStyle,
    this.labelStyle,
    this.valueStyle,
    this.accentColor,
    required this.accentVisible,
    required this.accentSize,
    this.shadow,
    this.minWidth,
    this.maxWidth,
    this.rowGap,
  });

  /// Resolves [style] against [theme] with tri-state semantics: an inherited
  /// field takes the theme default, an explicit value overrides it, and a
  /// cleared field resolves to null with no fallback.
  static ResolvedValueSummaryStyle resolve(
    CartesianValueSummaryStyle style,
    CartesianValueSummaryTheme theme,
  ) => ResolvedValueSummaryStyle(
    backgroundColor: style.backgroundColor.resolve(theme.background),
    backgroundOpacity: style.backgroundOpacity.resolve(theme.backgroundOpacity),
    borderColor: style.borderColor.resolve(theme.border),
    borderWidth: style.borderWidth.resolve(theme.borderWidth),
    borderRadius: style.borderRadius.resolve(theme.borderRadius),
    padding: style.padding.resolve(theme.padding),
    titleStyle: theme.titleStyle,
    labelStyle: style.labelStyle.resolve(theme.labelStyle),
    valueStyle: style.textStyle.resolve(theme.valueStyle),
    // The theme has no accent color: an inherited accent defers to the
    // content model's series color, so inherit resolves to null here while
    // [accentVisible] records whether the accent was explicitly cleared.
    accentColor: style.accentColor.resolve(null),
    accentVisible: !style.accentColor.isNone,
    accentSize: theme.accentSize,
    shadow: style.shadow.resolve(theme.shadow),
    minWidth: style.minWidth.resolve(theme.minWidth),
    maxWidth: style.maxWidth.resolve(theme.maxWidth),
    rowGap: style.rowGap.resolve(theme.rowGap),
  );

  /// Panel surface color, or null for a truly transparent panel.
  final Color? backgroundColor;

  /// Opacity applied to [backgroundColor]; null leaves the color unchanged.
  final double? backgroundOpacity;

  /// Panel outline color, or null for no visible stroke.
  final Color? borderColor;

  /// Panel outline width; null (cleared) draws no stroke.
  final double? borderWidth;

  /// Corner radius; null means sharp corners.
  final BorderRadius? borderRadius;

  /// Inner padding; null (cleared) means no padding.
  final EdgeInsets? padding;

  /// Style for the title and section-header text (theme-provided).
  final TextStyle titleStyle;

  /// Style for row labels and the subtitle; null falls back to a bare
  /// [TextStyle] so text still renders when the style was cleared.
  final TextStyle? labelStyle;

  /// Style for row values; null falls back to a bare [TextStyle].
  final TextStyle? valueStyle;

  /// Explicit accent override; null defers to the model's accent color.
  final Color? accentColor;

  /// False when the accent was explicitly cleared with
  /// `ChartStyleValue.none()` — no accent bar is painted regardless of the
  /// model's series color.
  final bool accentVisible;

  /// Width of the accent bar and series swatches (theme-provided).
  final double accentSize;

  /// Drop shadow behind the panel surface, or null for no shadow.
  final BoxShadow? shadow;

  /// Minimum panel width; null means no minimum.
  final double? minWidth;

  /// Maximum panel width; null means bounded only by the layout caller.
  final double? maxWidth;

  /// Vertical gap between stacked lines; null means no gap.
  final double? rowGap;

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable fields cannot be re-cleared through copyWith; construct a new
  /// instance (or re-[resolve]) to clear a field.
  ResolvedValueSummaryStyle copyWith({
    Color? backgroundColor,
    double? backgroundOpacity,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    Color? accentColor,
    bool? accentVisible,
    double? accentSize,
    BoxShadow? shadow,
    double? minWidth,
    double? maxWidth,
    double? rowGap,
  }) => ResolvedValueSummaryStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    titleStyle: titleStyle ?? this.titleStyle,
    labelStyle: labelStyle ?? this.labelStyle,
    valueStyle: valueStyle ?? this.valueStyle,
    accentColor: accentColor ?? this.accentColor,
    accentVisible: accentVisible ?? this.accentVisible,
    accentSize: accentSize ?? this.accentSize,
    shadow: shadow ?? this.shadow,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    rowGap: rowGap ?? this.rowGap,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedValueSummaryStyle &&
          other.backgroundColor == backgroundColor &&
          other.backgroundOpacity == backgroundOpacity &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius &&
          other.padding == padding &&
          other.titleStyle == titleStyle &&
          other.labelStyle == labelStyle &&
          other.valueStyle == valueStyle &&
          other.accentColor == accentColor &&
          other.accentVisible == accentVisible &&
          other.accentSize == accentSize &&
          other.shadow == shadow &&
          other.minWidth == minWidth &&
          other.maxWidth == maxWidth &&
          other.rowGap == rowGap;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    backgroundOpacity,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    titleStyle,
    labelStyle,
    valueStyle,
    accentColor,
    accentVisible,
    accentSize,
    shadow,
    minWidth,
    maxWidth,
    rowGap,
  ]);
}

/// The role of one placed text run inside a laid-out summary panel.
enum ValueSummaryTextRole {
  /// The panel title.
  title,

  /// The secondary line under the title.
  subtitle,

  /// A multi-series section heading (row with a color and an empty value).
  sectionHeader,

  /// A row label.
  label,

  /// A row value.
  value,
}

/// One placed text run, exposed for tests and semantics construction.
@immutable
class ValueSummaryPlacedText {
  const ValueSummaryPlacedText({
    required this.role,
    required this.text,
    required this.offset,
    required this.size,
  });

  /// What the run represents inside the panel.
  final ValueSummaryTextRole role;

  /// The source (untruncated) text of the run.
  final String text;

  /// Top-left position relative to the panel origin.
  final Offset offset;

  /// Laid-out size of the run (post-ellipsis).
  final Size size;
}

class _PlacedPainter {
  _PlacedPainter({
    required this.role,
    required this.text,
    required this.painter,
    required this.offset,
  });

  final ValueSummaryTextRole role;
  final String text;
  final TextPainter painter;
  final Offset offset;
}

class _PlacedSwatch {
  const _PlacedSwatch({required this.rect, required this.color});

  final Rect rect;
  final Color color;
}

/// An immutable, paintable measurement of one summary content model.
///
/// Produced by [ValueSummaryLayout.layout]; holds laid-out [TextPainter]s so
/// repeated paints of unchanged content do no text layout work.
class ValueSummaryLayoutResult {
  ValueSummaryLayoutResult._({
    required this.size,
    required ResolvedValueSummaryStyle style,
    required Color? accentColor,
    required bool accentOnRight,
    required List<_PlacedPainter> texts,
    required List<_PlacedSwatch> swatches,
  }) : _style = style,
       _accentColor = accentColor,
       _accentOnRight = accentOnRight,
       _texts = texts,
       _swatches = swatches;

  ValueSummaryLayoutResult._empty()
    : size = Size.zero,
      _style = null,
      _accentColor = null,
      _accentOnRight = false,
      _texts = const [],
      _swatches = const [];

  /// The measured panel size. [Size.zero] when there is nothing to paint.
  final Size size;

  final ResolvedValueSummaryStyle? _style;
  final Color? _accentColor;
  final bool _accentOnRight;
  final List<_PlacedPainter> _texts;
  final List<_PlacedSwatch> _swatches;

  /// The placed text runs, relative to the panel origin.
  List<ValueSummaryPlacedText> get placedTexts => [
    for (final placed in _texts)
      ValueSummaryPlacedText(
        role: placed.role,
        text: placed.text,
        offset: placed.offset,
        size: Size(placed.painter.width, placed.painter.height),
      ),
  ];

  /// Paints the panel with its top-left corner at [origin].
  ///
  /// A cleared background paints no surface (and suppresses the shadow — a
  /// shadow needs a surface to be cast by); a cleared border paints no
  /// stroke. Text contrast on a transparent surface remains the chart
  /// author's responsibility.
  void paint(Canvas canvas, Offset origin) {
    final style = _style;
    if (style == null || size == Size.zero) {
      return;
    }

    final rect = origin & size;
    final rrect = (style.borderRadius ?? BorderRadius.zero).toRRect(rect);

    final background = _effectiveBackground(style);
    final shadow = style.shadow;
    if (background != null && shadow != null) {
      canvas.drawRRect(rrect.shift(shadow.offset), shadow.toPaint());
    }
    if (background != null) {
      canvas.drawRRect(rrect, Paint()..color = background);
    }

    final accentColor = _accentColor;
    if (accentColor != null) {
      canvas.save();
      canvas.clipRRect(rrect);
      final barRect = _accentOnRight
          ? Rect.fromLTWH(
              rect.right - style.accentSize,
              rect.top,
              style.accentSize,
              rect.height,
            )
          : Rect.fromLTWH(rect.left, rect.top, style.accentSize, rect.height);
      canvas.drawRect(barRect, Paint()..color = accentColor);
      canvas.restore();
    }

    for (final swatch in _swatches) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          swatch.rect.shift(origin),
          const Radius.circular(2),
        ),
        Paint()..color = swatch.color,
      );
    }

    for (final placed in _texts) {
      placed.painter.paint(canvas, origin + placed.offset);
    }

    final borderColor = style.borderColor;
    final borderWidth = style.borderWidth;
    if (borderColor != null && borderWidth != null && borderWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth,
      );
    }
  }

  static Color? _effectiveBackground(ResolvedValueSummaryStyle style) {
    final color = style.backgroundColor;
    if (color == null) {
      return null;
    }
    final opacity = style.backgroundOpacity;
    if (opacity == null) {
      return color;
    }
    return color.withValues(alpha: (color.a * opacity).clamp(0.0, 1.0));
  }
}

class _LayoutKey {
  const _LayoutKey(
    this.model,
    this.style,
    this.textScale,
    this.textDirection,
    this.maxWidth,
  );

  final CartesianValueSummaryContentModel model;
  final ResolvedValueSummaryStyle style;
  final double textScale;
  final TextDirection textDirection;
  final double maxWidth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LayoutKey &&
          other.model == model &&
          other.style == style &&
          other.textScale == textScale &&
          other.textDirection == textDirection &&
          other.maxWidth == maxWidth;

  @override
  int get hashCode =>
      Object.hash(model, style, textScale, textDirection, maxWidth);
}

class _CacheEntry {
  const _CacheEntry(this.key, this.result);

  final _LayoutKey key;
  final ValueSummaryLayoutResult result;
}

/// Measures and paints Cartesian value summary panels with a small
/// most-recently-used layout cache.
///
/// The cache is keyed on content-model value equality, the resolved style,
/// text scale, text direction, and the available width (per D10: summary
/// layout stays cached until content, style, text scale, or plot bounds
/// change). A hit returns the identical [ValueSummaryLayoutResult] instance,
/// so repaints of unchanged content never re-run text layout.
class ValueSummaryLayout {
  /// Creates a layout pipeline retaining up to [cacheCapacity] results.
  ValueSummaryLayout({int cacheCapacity = 4})
    : assert(cacheCapacity > 0, 'cacheCapacity must be positive'),
      _cacheCapacity = cacheCapacity;

  final int _cacheCapacity;
  final List<_CacheEntry> _cache = [];

  /// Number of cached layout results, for tests.
  int get debugCacheLength => _cache.length;

  /// Lays out [model] with [style], returning a paintable result.
  ///
  /// [maxWidth] bounds the panel (typically derived from the plot rect);
  /// the tighter of it and the style's own maximum wins. [textScale] scales
  /// every text run linearly and [textDirection] mirrors the panel content
  /// for RTL. A model with no rows produces a zero-size result that paints
  /// nothing at all.
  ValueSummaryLayoutResult layout(
    CartesianValueSummaryContentModel model,
    ResolvedValueSummaryStyle style, {
    required double maxWidth,
    required double textScale,
    required TextDirection textDirection,
  }) {
    final key = _LayoutKey(model, style, textScale, textDirection, maxWidth);
    for (var index = 0; index < _cache.length; index++) {
      if (_cache[index].key == key) {
        final entry = _cache.removeAt(index);
        _cache.insert(0, entry);
        return entry.result;
      }
    }

    final result = _build(model, style, maxWidth, textScale, textDirection);
    _cache.insert(0, _CacheEntry(key, result));
    if (_cache.length > _cacheCapacity) {
      _cache.removeLast();
    }
    return result;
  }

  ValueSummaryLayoutResult _build(
    CartesianValueSummaryContentModel model,
    ResolvedValueSummaryStyle style,
    double maxWidth,
    double textScale,
    TextDirection textDirection,
  ) {
    if (model.rows.isEmpty) {
      return ValueSummaryLayoutResult._empty();
    }

    final scaler = TextScaler.linear(textScale);
    final padding = style.padding ?? EdgeInsets.zero;
    final rowGap = style.rowGap ?? 0.0;
    final titleStyle = style.titleStyle;
    final labelStyle = style.labelStyle ?? const TextStyle();
    final valueStyle = style.valueStyle ?? const TextStyle();

    final accentColor = style.accentVisible
        ? (style.accentColor ?? model.accentColor)
        : null;
    final accentInset = accentColor != null ? style.accentSize : 0.0;
    final swatchSize = style.accentSize;

    final styleMax = style.maxWidth ?? double.infinity;
    final outerMax = math.min(styleMax, maxWidth);
    final outerMin = math.min(style.minWidth ?? 0.0, outerMax);
    final chrome = padding.horizontal + accentInset;
    final contentMax = math.max(0.0, outerMax - chrome);

    TextPainter measure(String text, TextStyle textStyle) => TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: textDirection,
      textScaler: scaler,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: contentMax);

    final title = (model.title?.isNotEmpty ?? false)
        ? measure(model.title!, titleStyle)
        : null;
    final subtitle = (model.subtitle?.isNotEmpty ?? false)
        ? measure(model.subtitle!, labelStyle)
        : null;

    final lines = <_Line>[];
    for (final row in model.rows) {
      if (_isSectionHeader(row)) {
        lines.add(
          _Line.section(row, measure(row.label, titleStyle)),
        );
      } else {
        lines.add(
          _Line.row(
            row,
            measure(row.label, labelStyle),
            measure(row.value, valueStyle),
          ),
        );
      }
    }

    // Natural content width: widest line, bounded by contentMax.
    var natural = 0.0;
    if (title != null) natural = math.max(natural, title.width);
    if (subtitle != null) natural = math.max(natural, subtitle.width);
    for (final line in lines) {
      final swatchExtent = line.hasSwatch ? swatchSize + _swatchTextGap : 0.0;
      natural = line.isSection
          ? math.max(natural, swatchExtent + line.label.width)
          : math.max(
              natural,
              swatchExtent +
                  line.label.width +
                  _labelValueGap +
                  line.value!.width,
            );
    }
    final contentWidth = natural
        .clamp(math.max(0.0, outerMin - chrome), math.max(0.0, contentMax))
        .toDouble();

    // Final pass: constrain each run to the space it actually gets.
    title?.layout(maxWidth: contentWidth);
    subtitle?.layout(maxWidth: contentWidth);
    for (final line in lines) {
      final swatchExtent = line.hasSwatch ? swatchSize + _swatchTextGap : 0.0;
      final available = math.max(0.0, contentWidth - swatchExtent);
      if (line.isSection) {
        line.label.layout(maxWidth: available);
      } else {
        final value = line.value!;
        value.layout(maxWidth: available);
        line.label.layout(
          maxWidth: math.max(0.0, available - value.width - _labelValueGap),
        );
      }
    }

    // Vertical stacking and horizontal placement.
    final isRtl = textDirection == TextDirection.rtl;
    final contentLeft = padding.left + (isRtl ? 0.0 : accentInset);
    final contentRight = contentLeft + contentWidth;

    final texts = <_PlacedPainter>[];
    final swatches = <_PlacedSwatch>[];
    var y = padding.top;
    var isFirst = true;

    void advance(double height) {
      y += height;
      isFirst = false;
    }

    double lineStart() {
      if (!isFirst) y += rowGap;
      return y;
    }

    void placeFullLine(
      ValueSummaryTextRole role,
      String text,
      TextPainter painter, {
      double indent = 0.0,
    }) {
      final top = lineStart();
      final x = isRtl
          ? contentRight - indent - painter.width
          : contentLeft + indent;
      texts.add(
        _PlacedPainter(
          role: role,
          text: text,
          painter: painter,
          offset: Offset(x, top),
        ),
      );
      advance(painter.height);
    }

    if (title != null) {
      placeFullLine(ValueSummaryTextRole.title, model.title!, title);
    }
    if (subtitle != null) {
      placeFullLine(ValueSummaryTextRole.subtitle, model.subtitle!, subtitle);
    }

    for (final line in lines) {
      final swatchExtent = line.hasSwatch ? swatchSize + _swatchTextGap : 0.0;
      if (line.isSection) {
        final painter = line.label;
        final top = lineStart();
        final lineHeight = math.max(painter.height, swatchSize);
        if (line.hasSwatch) {
          final swatchLeft = isRtl
              ? contentRight - swatchSize
              : contentLeft;
          swatches.add(
            _PlacedSwatch(
              rect: Rect.fromLTWH(
                swatchLeft,
                top + (lineHeight - swatchSize) / 2,
                swatchSize,
                swatchSize,
              ),
              color: line.row.color!,
            ),
          );
        }
        final x = isRtl
            ? contentRight - swatchExtent - painter.width
            : contentLeft + swatchExtent;
        texts.add(
          _PlacedPainter(
            role: ValueSummaryTextRole.sectionHeader,
            text: line.row.label,
            painter: painter,
            offset: Offset(x, top + (lineHeight - painter.height) / 2),
          ),
        );
        advance(lineHeight);
      } else {
        final label = line.label;
        final value = line.value!;
        final top = lineStart();
        final lineHeight = math.max(
          math.max(label.height, value.height),
          line.hasSwatch ? swatchSize : 0.0,
        );
        if (line.hasSwatch) {
          final swatchLeft = isRtl
              ? contentRight - swatchSize
              : contentLeft;
          swatches.add(
            _PlacedSwatch(
              rect: Rect.fromLTWH(
                swatchLeft,
                top + (lineHeight - swatchSize) / 2,
                swatchSize,
                swatchSize,
              ),
              color: line.row.color!,
            ),
          );
        }
        final labelX = isRtl
            ? contentRight - swatchExtent - label.width
            : contentLeft + swatchExtent;
        final valueX = isRtl ? contentLeft : contentRight - value.width;
        texts.add(
          _PlacedPainter(
            role: ValueSummaryTextRole.label,
            text: line.row.label,
            painter: label,
            offset: Offset(labelX, top + (lineHeight - label.height) / 2),
          ),
        );
        texts.add(
          _PlacedPainter(
            role: ValueSummaryTextRole.value,
            text: line.row.value,
            painter: value,
            offset: Offset(valueX, top + (lineHeight - value.height) / 2),
          ),
        );
        advance(lineHeight);
      }
    }

    final size = Size(contentWidth + chrome, y + padding.bottom);
    return ValueSummaryLayoutResult._(
      size: size,
      style: style,
      accentColor: accentColor,
      accentOnRight: isRtl,
      texts: texts,
      swatches: swatches,
    );
  }

  /// A section-header row carries a series color and an empty value; it
  /// renders as a section title, never as a label with a blank value.
  static bool _isSectionHeader(CartesianValueSummaryRow row) =>
      row.color != null && row.value.isEmpty;
}

class _Line {
  _Line.section(this.row, this.label) : value = null, isSection = true;

  _Line.row(this.row, this.label, TextPainter this.value) : isSection = false;

  final CartesianValueSummaryRow row;
  final TextPainter label;
  final TextPainter? value;
  final bool isSection;

  bool get hasSwatch => row.color != null;
}
