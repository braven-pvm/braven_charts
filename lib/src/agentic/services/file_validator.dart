// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:typed_data';

/// Result of file validation operation
class ValidationResult {
  /// Whether validation succeeded
  final bool success;

  /// Error message if validation failed
  final String? errorMessage;

  /// Warning message for large files (40-50MB)
  final String? warningMessage;

  const ValidationResult.success({this.warningMessage})
      : success = true,
        errorMessage = null;

  const ValidationResult.failure(this.errorMessage)
      : success = false,
        warningMessage = null;
}

/// Service for validating file uploads
///
/// Enforces security and correctness requirements:
/// - Size limit: 50 MB (52,428,800 bytes) per FR-018
/// - Allowed formats: FIT, CSV, TCX per FR-019
/// - Executable content detection: Rejects executable files per FR-019
/// - Path traversal prevention: Rejects filenames with '../' or '..\\'
/// - Large file warning: Warns for files 40-50MB
class FileValidator {
  /// Maximum allowed file size (50 MB)
  static const int maxFileSizeBytes = 52428800;

  /// Large file warning threshold (40 MB)
  static const int largeFileThresholdBytes = 41943040; // 40 MB

  /// Allowed file extensions
  static const List<String> allowedFormats = ['fit', 'csv', 'tcx'];

  /// Validates a file for upload
  ///
  /// Checks:
  /// - File size does not exceed 50 MB
  /// - File format is one of: FIT, CSV, TCX
  /// - File content is not executable (PE, ELF, Mach-O, scripts)
  /// - Filename does not contain path traversal sequences
  /// - Warns for large files (40-50 MB)
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

    // Check for executable content (FR-019)
    if (_isExecutableContent(content)) {
      return const ValidationResult.failure(
        'File contains executable content and cannot be uploaded for security reasons',
      );
    }

    // Check for large file warning (40-50 MB)
    String? warning;
    if (fileSizeBytes >= largeFileThresholdBytes) {
      warning = 'Large file may take longer to process';
    }

    return ValidationResult.success(warningMessage: warning);
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

  /// Checks if file content contains executable signatures (FR-019)
  ///
  /// Detects:
  /// - PE (Windows executables): MZ header (0x4D5A)
  /// - ELF (Linux executables): Magic bytes (0x7F454C46)
  /// - Mach-O (macOS executables): Magic bytes (0xFEEDFACE, 0xFEEDFACF, 0xCEFAEDFE, 0xCFFAEDFE)
  /// - Script shebangs: #! at start
  /// - Windows batch: @echo off (case-insensitive)
  bool _isExecutableContent(Uint8List content) {
    if (content.isEmpty) {
      return false;
    }

    // Check for PE header (Windows .exe, .dll)
    if (content.length >= 2) {
      if (content[0] == 0x4D && content[1] == 0x5A) {
        // MZ signature
        return true;
      }
    }

    // Check for ELF header (Linux executables)
    if (content.length >= 4) {
      if (content[0] == 0x7F && content[1] == 0x45 && content[2] == 0x4C && content[3] == 0x46) {
        // ELF signature
        return true;
      }
    }

    // Check for Mach-O headers (macOS executables)
    if (content.length >= 4) {
      final magic = (content[0] << 24) | (content[1] << 16) | (content[2] << 8) | content[3];
      if (magic == 0xFEEDFACE || // 32-bit Mach-O
          magic == 0xFEEDFACF || // 64-bit Mach-O
          magic == 0xCEFAEDFE || // 32-bit reverse byte order
          magic == 0xCFFAEDFE) {
        // 64-bit reverse byte order
        return true;
      }
    }

    // Check for script shebangs (#!)
    if (content.length >= 2) {
      if (content[0] == 0x23 && content[1] == 0x21) {
        // #! shebang
        return true;
      }
    }

    // Check for Windows batch file markers (@echo off)
    if (content.length >= 9) {
      final firstLine = String.fromCharCodes(content.take(100).toList());
      if (firstLine.toLowerCase().contains('@echo off')) {
        return true;
      }
    }

    return false;
  }
}
