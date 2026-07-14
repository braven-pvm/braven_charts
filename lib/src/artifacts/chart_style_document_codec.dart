import 'package:flutter/material.dart';

import '../models/annotation_style.dart';
import '../models/legend_style.dart';
import '../theming/styles/label_style.dart';
import 'chart_data_payload.dart';
import 'json_value.dart';

/// JSON-safe codecs shared by built-in annotation and legend models.
abstract final class ChartStyleDocumentCodec {
  static JsonObjectValue encodeTextStyle(TextStyle style) =>
      _object(_encodeTextStyle(style));

  static TextStyle decodeTextStyle(JsonObjectValue value) =>
      _decodeTextStyle(_map(value.toJson()));

  static JsonObjectValue encodeLabelStyle(LabelStyle style) => _object({
    'textStyle': _encodeTextStyle(style.textStyle),
    'backgroundColor': style.backgroundColor.toARGB32(),
    'borderColor': style.borderColor.toARGB32(),
    'borderWidth': _number(style.borderWidth),
    'borderRadius': _number(style.borderRadius),
    'padding': _encodeInsets(style.padding),
    if (style.shadowColor != null) 'shadowColor': style.shadowColor!.toARGB32(),
    if (style.shadowBlurRadius != null)
      'shadowBlurRadius': _number(style.shadowBlurRadius!),
  });

  static LabelStyle decodeLabelStyle(JsonObjectValue value) {
    final map = _map(value.toJson());
    return LabelStyle(
      textStyle: _decodeTextStyle(_requiredMap(map, 'textStyle')),
      backgroundColor: _requiredColor(map, 'backgroundColor'),
      borderColor: _requiredColor(map, 'borderColor'),
      borderWidth: _requiredDouble(map, 'borderWidth'),
      borderRadius: _requiredDouble(map, 'borderRadius'),
      padding: _decodeInsets(_requiredMap(map, 'padding')),
      shadowColor: _optionalColor(map['shadowColor']),
      shadowBlurRadius: _optionalDouble(map['shadowBlurRadius']),
    );
  }

  static JsonObjectValue encodeAnnotationStyle(AnnotationStyle style) =>
      _object({
        'textStyle': _encodeTextStyle(style.textStyle),
        if (style.backgroundColor != null)
          'backgroundColor': style.backgroundColor!.toARGB32(),
        if (style.borderColor != null)
          'borderColor': style.borderColor!.toARGB32(),
        'borderWidth': _number(style.borderWidth),
        if (style.borderRadius != null)
          'borderRadius': _encodeBorderRadius(style.borderRadius!),
        if (style.padding != null) 'padding': _encodeInsets(style.padding!),
      });

  static AnnotationStyle decodeAnnotationStyle(JsonObjectValue value) {
    final map = _map(value.toJson());
    return AnnotationStyle(
      textStyle: _decodeTextStyle(_requiredMap(map, 'textStyle')),
      backgroundColor: _optionalColor(map['backgroundColor']),
      borderColor: _optionalColor(map['borderColor']),
      borderWidth: _requiredDouble(map, 'borderWidth'),
      borderRadius: map['borderRadius'] == null
          ? null
          : _decodeBorderRadius(_requiredMap(map, 'borderRadius')),
      padding: map['padding'] == null
          ? null
          : _decodeInsets(_requiredMap(map, 'padding')),
    );
  }

  static JsonObjectValue encodeLegendStyle(LegendStyle style) => _object({
    'position': style.position.name,
    'orientation': style.orientation.name,
    'textStyle': _encodeTextStyle(style.textStyle),
    if (style.backgroundColor != null)
      'backgroundColor': style.backgroundColor!.toARGB32(),
    if (style.borderColor != null) 'borderColor': style.borderColor!.toARGB32(),
    'borderWidth': _number(style.borderWidth),
    if (style.borderRadius != null)
      'borderRadius': _encodeBorderRadius(style.borderRadius!),
    if (style.padding != null) 'padding': _encodeInsets(style.padding!),
    'itemSpacing': _number(style.itemSpacing),
    'markerSize': _number(style.markerSize),
    'markerShape': style.markerShape.name,
    'markerLineWidth': _number(style.markerLineWidth),
    'markerLabelSpacing': _number(style.markerLabelSpacing),
    'allowDragging': style.allowDragging,
    'opacity': _number(style.opacity),
    'offset': _encodeOffset(style.offset),
  });

  static LegendStyle decodeLegendStyle(JsonObjectValue value) {
    final map = _map(value.toJson());
    return LegendStyle(
      position: _enum(map, 'position', LegendPosition.values),
      orientation: _enum(map, 'orientation', LegendOrientation.values),
      textStyle: _decodeTextStyle(_requiredMap(map, 'textStyle')),
      backgroundColor: _optionalColor(map['backgroundColor']),
      borderColor: _optionalColor(map['borderColor']),
      borderWidth: _requiredDouble(map, 'borderWidth'),
      borderRadius: map['borderRadius'] == null
          ? null
          : _decodeBorderRadius(_requiredMap(map, 'borderRadius')),
      padding: map['padding'] == null
          ? null
          : _decodeInsets(_requiredMap(map, 'padding')),
      itemSpacing: _requiredDouble(map, 'itemSpacing'),
      markerSize: _requiredDouble(map, 'markerSize'),
      markerShape: _enum(map, 'markerShape', LegendMarkerShape.values),
      markerLineWidth: _requiredDouble(map, 'markerLineWidth'),
      markerLabelSpacing: _requiredDouble(map, 'markerLabelSpacing'),
      allowDragging: _requiredBool(map, 'allowDragging'),
      opacity: _requiredDouble(map, 'opacity'),
      offset: _decodeOffset(_requiredMap(map, 'offset')),
    );
  }

  static Map<String, Object?> _encodeTextStyle(TextStyle style) {
    if (style.foreground != null || style.background != null) {
      throw UnsupportedError(
        'TextStyle foreground/background Paint values are not portable.',
      );
    }
    return {
      'inherit': style.inherit,
      if (style.color != null) 'color': style.color!.toARGB32(),
      if (style.backgroundColor != null)
        'backgroundColor': style.backgroundColor!.toARGB32(),
      if (style.fontFamily != null) 'fontFamily': style.fontFamily,
      if (style.fontFamilyFallback != null)
        'fontFamilyFallback': style.fontFamilyFallback,
      if (style.fontSize != null) 'fontSize': _number(style.fontSize!),
      if (style.fontWeight != null)
        'fontWeightIndex': FontWeight.values.indexOf(style.fontWeight!),
      if (style.fontStyle != null) 'fontStyle': style.fontStyle!.name,
      if (style.letterSpacing != null)
        'letterSpacing': _number(style.letterSpacing!),
      if (style.wordSpacing != null) 'wordSpacing': _number(style.wordSpacing!),
      if (style.textBaseline != null) 'textBaseline': style.textBaseline!.name,
      if (style.height != null) 'height': _number(style.height!),
      if (style.leadingDistribution != null)
        'leadingDistribution': style.leadingDistribution!.name,
      if (style.locale != null)
        'locale': {
          'languageCode': style.locale!.languageCode,
          if (style.locale!.scriptCode != null)
            'scriptCode': style.locale!.scriptCode,
          if (style.locale!.countryCode != null)
            'countryCode': style.locale!.countryCode,
        },
      if (style.shadows != null)
        'shadows': [
          for (final shadow in style.shadows!)
            {
              'color': shadow.color.toARGB32(),
              'offset': _encodeOffset(shadow.offset),
              'blurRadius': _number(shadow.blurRadius),
            },
        ],
      if (style.fontFeatures != null)
        'fontFeatures': [
          for (final feature in style.fontFeatures!)
            {'feature': feature.feature, 'value': feature.value},
        ],
      if (style.fontVariations != null)
        'fontVariations': [
          for (final variation in style.fontVariations!)
            {'axis': variation.axis, 'value': _number(variation.value)},
        ],
      if (style.decoration != null)
        'decoration': [
          if (style.decoration!.contains(TextDecoration.underline)) 'underline',
          if (style.decoration!.contains(TextDecoration.overline)) 'overline',
          if (style.decoration!.contains(TextDecoration.lineThrough))
            'lineThrough',
        ],
      if (style.decorationColor != null)
        'decorationColor': style.decorationColor!.toARGB32(),
      if (style.decorationStyle != null)
        'decorationStyle': style.decorationStyle!.name,
      if (style.decorationThickness != null)
        'decorationThickness': _number(style.decorationThickness!),
      if (style.debugLabel != null) 'debugLabel': style.debugLabel,
      if (style.overflow != null) 'overflow': style.overflow!.name,
    };
  }

  static TextStyle _decodeTextStyle(Map<String, Object?> map) => TextStyle(
    inherit: _requiredBool(map, 'inherit'),
    color: _optionalColor(map['color']),
    backgroundColor: _optionalColor(map['backgroundColor']),
    fontFamily: _optionalString(map['fontFamily']),
    fontFamilyFallback: _optionalStringList(map['fontFamilyFallback']),
    fontSize: _optionalDouble(map['fontSize']),
    fontWeight: map['fontWeightIndex'] == null
        ? null
        : _fontWeight(_requiredInt(map, 'fontWeightIndex')),
    fontStyle: _optionalEnum(map['fontStyle'], FontStyle.values),
    letterSpacing: _optionalDouble(map['letterSpacing']),
    wordSpacing: _optionalDouble(map['wordSpacing']),
    textBaseline: _optionalEnum(map['textBaseline'], TextBaseline.values),
    height: _optionalDouble(map['height']),
    leadingDistribution: _optionalEnum(
      map['leadingDistribution'],
      TextLeadingDistribution.values,
    ),
    locale: map['locale'] == null
        ? null
        : _decodeLocale(_requiredMap(map, 'locale')),
    shadows: map['shadows'] == null
        ? null
        : [
            for (final item in _requiredList(map, 'shadows'))
              _decodeShadow(_map(item)),
          ],
    fontFeatures: map['fontFeatures'] == null
        ? null
        : [
            for (final item in _requiredList(map, 'fontFeatures'))
              _decodeFontFeature(_map(item)),
          ],
    fontVariations: map['fontVariations'] == null
        ? null
        : [
            for (final item in _requiredList(map, 'fontVariations'))
              _decodeFontVariation(_map(item)),
          ],
    decoration: map['decoration'] == null
        ? null
        : _decodeDecoration(_requiredList(map, 'decoration')),
    decorationColor: _optionalColor(map['decorationColor']),
    decorationStyle: _optionalEnum(
      map['decorationStyle'],
      TextDecorationStyle.values,
    ),
    decorationThickness: _optionalDouble(map['decorationThickness']),
    debugLabel: _optionalString(map['debugLabel']),
    overflow: _optionalEnum(map['overflow'], TextOverflow.values),
  );

  static Locale _decodeLocale(Map<String, Object?> map) => Locale.fromSubtags(
    languageCode: _requiredString(map, 'languageCode'),
    scriptCode: _optionalString(map['scriptCode']),
    countryCode: _optionalString(map['countryCode']),
  );

  static Shadow _decodeShadow(Map<String, Object?> map) => Shadow(
    color: _requiredColor(map, 'color'),
    offset: _decodeOffset(_requiredMap(map, 'offset')),
    blurRadius: _requiredDouble(map, 'blurRadius'),
  );

  static FontFeature _decodeFontFeature(Map<String, Object?> map) =>
      FontFeature(_requiredString(map, 'feature'), _requiredInt(map, 'value'));

  static FontVariation _decodeFontVariation(Map<String, Object?> map) =>
      FontVariation(
        _requiredString(map, 'axis'),
        _requiredDouble(map, 'value'),
      );

  static TextDecoration _decodeDecoration(List<Object?> values) {
    final decorations = <TextDecoration>[];
    for (final value in values) {
      switch (value) {
        case 'underline':
          decorations.add(TextDecoration.underline);
        case 'overline':
          decorations.add(TextDecoration.overline);
        case 'lineThrough':
          decorations.add(TextDecoration.lineThrough);
        default:
          throw FormatException('Unknown text decoration: $value.');
      }
    }
    return decorations.isEmpty
        ? TextDecoration.none
        : TextDecoration.combine(decorations);
  }

  static Map<String, Object?> _encodeOffset(Offset value) => {
    'dx': _number(value.dx),
    'dy': _number(value.dy),
  };

  static Offset _decodeOffset(Map<String, Object?> value) =>
      Offset(_requiredDouble(value, 'dx'), _requiredDouble(value, 'dy'));

  static Map<String, Object?> _encodeInsets(EdgeInsets value) => {
    'left': _number(value.left),
    'top': _number(value.top),
    'right': _number(value.right),
    'bottom': _number(value.bottom),
  };

  static EdgeInsets _decodeInsets(Map<String, Object?> value) =>
      EdgeInsets.fromLTRB(
        _requiredDouble(value, 'left'),
        _requiredDouble(value, 'top'),
        _requiredDouble(value, 'right'),
        _requiredDouble(value, 'bottom'),
      );

  static Map<String, Object?> _encodeBorderRadius(BorderRadius value) => {
    'topLeft': _encodeRadius(value.topLeft),
    'topRight': _encodeRadius(value.topRight),
    'bottomLeft': _encodeRadius(value.bottomLeft),
    'bottomRight': _encodeRadius(value.bottomRight),
  };

  static BorderRadius _decodeBorderRadius(Map<String, Object?> value) =>
      BorderRadius.only(
        topLeft: _decodeRadius(_requiredMap(value, 'topLeft')),
        topRight: _decodeRadius(_requiredMap(value, 'topRight')),
        bottomLeft: _decodeRadius(_requiredMap(value, 'bottomLeft')),
        bottomRight: _decodeRadius(_requiredMap(value, 'bottomRight')),
      );

  static Map<String, Object?> _encodeRadius(Radius value) => {
    'x': _number(value.x),
    'y': _number(value.y),
  };

  static Radius _decodeRadius(Map<String, Object?> value) => Radius.elliptical(
    _requiredDouble(value, 'x'),
    _requiredDouble(value, 'y'),
  );

  static Object _number(double value) =>
      ChartNumberDocument.fromDouble(value).toJson();

  static JsonObjectValue _object(Map<String, Object?> value) =>
      JsonValue.fromJson(value) as JsonObjectValue;

  static Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('Expected JSON object.');
  }

  static Map<String, Object?> _requiredMap(
    Map<String, Object?> map,
    String key,
  ) => _map(map[key]);

  static List<Object?> _requiredList(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is List<Object?>) return value;
    if (value is List) return List<Object?>.from(value);
    throw FormatException('Expected list at $key.');
  }

  static String _requiredString(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is String) return value;
    throw FormatException('Expected string at $key.');
  }

  static String? _optionalString(Object? value) {
    if (value == null || value is String) return value as String?;
    throw const FormatException('Expected optional string.');
  }

  static List<String>? _optionalStringList(Object? value) {
    if (value == null) return null;
    if (value is! List) throw const FormatException('Expected string list.');
    return [
      for (final item in value)
        if (item is String)
          item
        else
          throw const FormatException('Expected string list item.'),
    ];
  }

  static bool _requiredBool(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is bool) return value;
    throw FormatException('Expected bool at $key.');
  }

  static int _requiredInt(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is int) return value;
    throw FormatException('Expected integer at $key.');
  }

  static double _requiredDouble(Map<String, Object?> map, String key) =>
      _optionalDouble(map[key]) ??
      (throw FormatException('Expected chart number at $key.'));

  static double? _optionalDouble(Object? value) =>
      value == null ? null : ChartNumberDocument.fromJson(value).asDouble;

  static Color _requiredColor(Map<String, Object?> map, String key) =>
      _optionalColor(map[key]) ??
      (throw FormatException('Expected ARGB color at $key.'));

  static Color? _optionalColor(Object? value) {
    if (value == null) return null;
    if (value is int) return Color(value);
    throw const FormatException('Expected ARGB color integer.');
  }

  static FontWeight _fontWeight(int index) {
    if (index < 0 || index >= FontWeight.values.length) {
      throw const FormatException('Invalid font-weight index.');
    }
    return FontWeight.values[index];
  }

  static T _enum<T extends Enum>(
    Map<String, Object?> map,
    String key,
    List<T> values,
  ) =>
      _optionalEnum(map[key], values) ??
      (throw FormatException('Expected enum at $key.'));

  static T? _optionalEnum<T extends Enum>(Object? value, List<T> values) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('Expected enum name.');
    for (final candidate in values) {
      if (candidate.name == value) return candidate;
    }
    throw FormatException('Unknown enum value: $value.');
  }
}
