import 'dart:ui' show TextDirection;

import 'package:braven_charts/src/utils/text_direction_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveChartTextDirection', () {
    test('detects Arabic and Hebrew text', () {
      expect(resolveChartTextDirection('الإيرادات'), TextDirection.rtl);
      expect(resolveChartTextDirection('הכנסות'), TextDirection.rtl);
    });

    test('keeps Latin text left-to-right', () {
      expect(resolveChartTextDirection('Revenue 96'), TextDirection.ltr);
    });

    test('uses the ambient fallback for neutral numeric content', () {
      expect(
        resolveChartTextDirection('96%', fallback: TextDirection.rtl),
        TextDirection.rtl,
      );
    });
  });
}
