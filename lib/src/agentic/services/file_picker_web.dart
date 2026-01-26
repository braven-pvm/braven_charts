// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Result of a file pick operation.
class FilePickerResult {
  final String fileName;
  final Uint8List content;

  FilePickerResult({required this.fileName, required this.content});
}

/// Pick a file using the browser's file input.
Future<FilePickerResult?> pickFile({List<String>? allowedExtensions}) async {
  final completer = Completer<FilePickerResult?>();

  final input = html.FileUploadInputElement();

  // Set accepted file types
  if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
    input.accept = allowedExtensions.map((ext) => '.$ext').join(',');
  }

  input.onChange.listen((event) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onLoadEnd.listen((event) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(FilePickerResult(
          fileName: file.name,
          content: result,
        ));
      } else if (result is List<int>) {
        completer.complete(FilePickerResult(
          fileName: file.name,
          content: Uint8List.fromList(result),
        ));
      } else {
        completer.complete(null);
      }
    });

    reader.onError.listen((event) {
      completer.complete(null);
    });

    reader.readAsArrayBuffer(file);
  });

  // Handle cancel (user closes dialog without selecting)
  input.onAbort.listen((event) {
    completer.complete(null);
  });

  // Trigger file dialog
  input.click();

  // Also handle the case where user cancels by listening to focus
  // This is a workaround since there's no direct cancel event
  Future.delayed(const Duration(milliseconds: 100), () {
    html.window.onFocus.first.then((_) {
      // Small delay to let onChange fire first if a file was selected
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
    });
  });

  return completer.future;
}

/// Whether file picking is supported on this platform.
bool get isFilePickingSupported => true;
