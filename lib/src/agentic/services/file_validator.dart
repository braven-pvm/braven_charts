// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

/// Result of file validation operation
class ValidationResult {
  /// Whether validation succeeded
  final bool success;

  /// Error message if validation failed
  final String? errorMessage;

  const ValidationResult.success()
      : success = true,
        errorMessage = null;

  const ValidationResult.failure(this.errorMessage) : success = false;
}

/// Service for validating file uploads
///
/// Enforces security and correctness requirements:
/// - Size limit: 50 MB (52,428,800 bytes) per FR-018
/// - Allowed formats: FIT, CSV, TCX per FR-019
/// - Path traversal prevention: Rejects filenames with '../' or '..\\'
class FileValidator {
  /// Maximum allowed file size (50 MB)
  static const int maxFileSizeBytes = 52428800;

  /// Allowed file extensions
  static const List<String> allowedFormats = ['fit', 'csv', 'tcx'];

  /// Validates a file for upload
  ///
  /// Checks:
  /// - File size does not exceed 50 MB
  /// - File format is one of: FIT, CSV, TCX
  /// - Filename does not contain path traversal sequences
  ValidationResult validate({
    required String fileName,
    required int fileSizeBytes,
    required Uint8List content,
  }) {
    // Check for path traversal attempts
    if (_hasPathTraversal(fileName)) {
      return const ValidationResult.failure(
        'Invalid filename: path traversal sequences are not allowed',
      );
    }

    // Check file size
    if (fileSizeBytes > maxFileSizeBytes) {
      final sizeMB = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);
      return ValidationResult.failure(
        'File size ($sizeMB MB) exceeds maximum allowed size of 50 MB',
      );
    }

    // Check if content size matches declared size
    if (content.length != fileSizeBytes) {
      return ValidationResult.failure(
        'File size mismatch: declared $fileSizeBytes bytes, actual ${content.length} bytes',
      );
    }

    // Extract file extension
    final extension = _getFileExtension(fileName);
    if (extension == null) {
      return const ValidationResult.failure(
        'Invalid filename: missing file extension',
      );
    }

    // Check if format is allowed (case-insensitive)
    if (!allowedFormats.contains(extension.toLowerCase())) {
      return ValidationResult.failure(
        'Unsupported file format: .$extension. Allowed formats: ${allowedFormats.map((f) => '.$f').join(', ')}',
      );
    }

    return const ValidationResult.success();
  }

  /// Checks for path traversal sequences in filename
  bool _hasPathTraversal(String fileName) {
    return fileName.contains('../') || fileName.contains('..\\');
  }

  /// Extracts file extension from filename
  String? _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return null;
    }
    return fileName.substring(lastDot + 1);
  }
}
