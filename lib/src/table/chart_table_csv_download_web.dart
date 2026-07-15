import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> downloadChartTableCsv({
  required String csv,
  required String fileName,
}) async {
  final blob = web.Blob(
    <web.BlobPart>[csv.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(objectUrl);
  return true;
}
