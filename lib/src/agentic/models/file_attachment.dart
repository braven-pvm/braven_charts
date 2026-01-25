import 'dart:typed_data';

/// File status enumeration
enum FileStatus {
  pending,
  parsing,
  ready,
  error,
}

/// Stub implementation for FileAttachment model
/// This will be implemented in the green phase of TDD
class FileAttachment {
  final String id;
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final Uint8List content;
  final FileStatus status;
  final String? dataId;
  final String? errorMessage;

  /// Creates a new FileAttachment instance
  FileAttachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.content,
    FileStatus? status,
    this.dataId,
    this.errorMessage,
  }) : status = status ?? FileStatus.pending;

  /// Creates a FileAttachment from JSON
  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('FileAttachment.fromJson not yet implemented');
  }

  /// Converts FileAttachment to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('FileAttachment.toJson not yet implemented');
  }

  /// Creates a copy with modified values
  FileAttachment copyWith({
    String? id,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    Uint8List? content,
    FileStatus? status,
    String? dataId,
    String? errorMessage,
  }) {
    throw UnimplementedError('FileAttachment.copyWith not yet implemented');
  }
}
