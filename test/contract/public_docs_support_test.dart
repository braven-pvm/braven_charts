import 'package:flutter_test/flutter_test.dart';

import '../../tool/public_docs_support.dart';

void main() {
  group('normalizePublicDocsText', () {
    test('treats LF, CRLF, and CR line endings as equivalent', () {
      const lf = 'first\nsecond\nthird\n';
      const crlf = 'first\r\nsecond\r\nthird\r\n';
      const cr = 'first\rsecond\rthird\r';

      expect(normalizePublicDocsText(crlf), lf);
      expect(normalizePublicDocsText(cr), lf);
    });

    test('preserves meaningful content differences', () {
      const expected = 'first\nsecond\n';
      const stale = 'first\nchanged\n';

      expect(
        normalizePublicDocsText(stale),
        isNot(normalizePublicDocsText(expected)),
      );
    });
  });
}
