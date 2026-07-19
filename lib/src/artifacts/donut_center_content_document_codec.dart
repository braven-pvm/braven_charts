import '../models/donut_chart_config.dart';
import '../models/pie_chart_config.dart';
import 'chart_style_document_codec.dart';
import 'json_value.dart';

/// Shared portable adapter for series-owned and composition-owned Donut center
/// content.
abstract final class DonutCenterContentDocumentCodec {
  /// Encodes text-first center content and an optional formatter descriptor.
  static Map<String, Object?> encode(
    DonutCenterContent content, {
    JsonObjectValue? valueFormatter,
  }) => {
    'isVisible': content.isVisible,
    if (content.label != null) 'label': content.label,
    'valueMode': content.valueMode.name,
    if (content.customValue != null) 'customValue': content.customValue,
    if (content.labelStyle != null)
      'labelStyle': ChartStyleDocumentCodec.encodeLabelStyle(
        content.labelStyle!,
      ).toJson(),
    if (content.valueStyle != null)
      'valueStyle': ChartStyleDocumentCodec.encodeLabelStyle(
        content.valueStyle!,
      ).toJson(),
    if (valueFormatter != null) 'valueFormatter': valueFormatter.toJson(),
  };

  /// Decodes center content using a host-resolved numeric formatter.
  static DonutCenterContent decode(
    Map<String, Object?> value, {
    RadialValueFormatter? valueFormatter,
    String path = r'$.style.centerContent',
  }) {
    final isVisible = value['isVisible'];
    if (isVisible is! bool) {
      throw FormatException('Center visibility must be a boolean at $path.');
    }
    final label = _optionalString(value['label'], '$path.label');
    final customValue = _optionalString(
      value['customValue'],
      '$path.customValue',
    );
    return DonutCenterContent(
      isVisible: isVisible,
      label: label,
      valueMode: _requiredEnum(
        value['valueMode'],
        DonutCenterValueMode.values,
        '$path.valueMode',
      ),
      customValue: customValue,
      labelStyle: value['labelStyle'] == null
          ? null
          : ChartStyleDocumentCodec.decodeLabelStyle(
              _jsonObject(value['labelStyle'], '$path.labelStyle'),
            ),
      valueStyle: value['valueStyle'] == null
          ? null
          : ChartStyleDocumentCodec.decodeLabelStyle(
              _jsonObject(value['valueStyle'], '$path.valueStyle'),
            ),
      valueFormatter: valueFormatter,
    );
  }
}

String? _optionalString(Object? value, String path) {
  if (value == null) return null;
  if (value is String) return value;
  throw FormatException('Expected a string at $path.');
}

T _requiredEnum<T extends Enum>(Object? raw, List<T> values, String path) {
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
  }
  throw FormatException('Unknown enum value "$raw" at $path.');
}

JsonObjectValue _jsonObject(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('Expected an object at $path.');
  }
  return JsonValue.fromJson(value, path: path) as JsonObjectValue;
}
