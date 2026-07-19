import 'dart:ui';

import 'package:braven_charts/src/utils/dashed_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createDashedPath', () {
    test('returns the source path for an empty solid pattern', () {
      final source = Path()..lineTo(22, 0);

      expect(createDashedPath(source, const []), same(source));
    });

    test('alternates painted and skipped distances along each contour', () {
      final source = Path()..lineTo(22, 0);

      final dashed = createDashedPath(source, const [4, 2]);
      final lengths = dashed
          .computeMetrics()
          .map((metric) => metric.length)
          .toList();

      expect(lengths, hasLength(4));
      expect(lengths, everyElement(closeTo(4, 0.001)));
    });

    test('restarts the pattern for each disconnected contour', () {
      final source = Path()
        ..lineTo(5, 0)
        ..moveTo(0, 10)
        ..lineTo(5, 10);

      final dashed = createDashedPath(source, const [3, 2]);
      final lengths = dashed
          .computeMetrics()
          .map((metric) => metric.length)
          .toList();

      expect(lengths, hasLength(2));
      expect(lengths, everyElement(closeTo(3, 0.001)));
    });

    test('rejects malformed patterns', () {
      final source = Path()..lineTo(20, 0);

      expect(() => createDashedPath(source, const [4]), throwsArgumentError);
      expect(() => createDashedPath(source, const [4, 0]), throwsArgumentError);
      expect(
        () => createDashedPath(source, const [4, double.nan]),
        throwsArgumentError,
      );
    });
  });
}
