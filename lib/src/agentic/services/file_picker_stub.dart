import 'dart:typed_data';

/// Stub implementation for non-web platforms.
/// This file is used when dart:html is not available.
class FilePickerResult {
  final String fileName;
  final Uint8List content;

  FilePickerResult({required this.fileName, required this.content});
}

/// Pick a file - stub that always returns null on non-web platforms.
Future<FilePickerResult?> pickFile({List<String>? allowedExtensions}) async {
  // On non-web platforms, this returns null
  // The UI should show a message that file picking is not supported
  return null;
}

/// Whether file picking is supported on this platform.
bool get isFilePickingSupported => false;
