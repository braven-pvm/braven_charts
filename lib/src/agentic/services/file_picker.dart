// Conditional export for file picker.
// Uses web implementation when available, falls back to stub otherwise.
export 'file_picker_stub.dart' if (dart.library.html) 'file_picker_web.dart';
