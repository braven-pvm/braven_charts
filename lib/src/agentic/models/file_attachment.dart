import 'dart:convert';
import 'dart:typed_data';

/// File status enumeration
enum FileStatus {
  pending,
  parsing,
  ready,
  error,
}

/// Represents a file attached to a user message.
///
/// Contains file metadata, content, and processing status.
/// File size is limited to 50 MB (52,428,800 bytes).
class FileAttachment {
  /// Unique identifier for the attachment
  final String id;

  /// Original file name
  final String fileName;

  /// File type/extension (e.g., 'fit', 'csv', 'json', 'yaml')
  final String fileType;

  /// File size in bytes
  final int fileSizeBytes;

  /// File content as binary data
  final Uint8List content;

  /// Processing status of the file
  final FileStatus status;

  /// ID of the loaded data if parsing succeeded
  final String? dataId;

  /// Error message if status is error
  final String? errorMessage;

  /// Maximum allowed file size (50 MB)
  static const int maxFileSizeBytes = 52428800;

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
  })  : status = status ?? FileStatus.pending,
        assert(id.isNotEmpty, 'FileAttachment id cannot be empty'),
        assert(fileName.isNotEmpty, 'fileName cannot be empty'),
        assert(fileType.isNotEmpty, 'fileType cannot be empty'),
        assert(fileSizeBytes >= 0, 'fileSizeBytes cannot be negative'),
        assert(
          _isValidFileType(fileType),
          'fileType must be one of: fit, csv, json, yaml, tcx',
        ),
        assert(
          _isSanitizedPath(fileName),
          'fileName cannot contain path traversal sequences (../ or ..\\)',
        ),
        assert(
          fileSizeBytes <= maxFileSizeBytes,
          'File size must not exceed 50 MB (52,428,800 bytes)',
        );

  /// Validates allowed file types
  static bool _isValidFileType(String fileType) {
    final normalized = fileType.toLowerCase();
    return ['fit', 'csv', 'json', 'yaml', 'tcx'].contains(normalized);
  }

  /// Checks for path traversal attempts
  static bool _isSanitizedPath(String path) {
    return !path.contains('../') && !path.contains('..\\');
  }

  /// Creates a FileAttachment from JSON
  factory FileAttachment.fromJson(Map<String, dynamic> json) {
    final contentData = json['content'];
    final Uint8List content;
    if (contentData is String) {
      content = base64Decode(contentData);
    } else if (contentData is List) {
      content = Uint8List.fromList(contentData.cast<int>());
    } else {
      throw ArgumentError('content must be a String (base64) or List<int>');
    }

    return FileAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileType: json['fileType'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      content: content,
      status: FileStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      dataId: json['dataId'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Converts FileAttachment to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'content': content.toList(),
      'status': status.name,
      if (dataId != null) 'dataId': dataId,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
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
    return FileAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      content: content ?? this.content,
      status: status ?? this.status,
      dataId: dataId ?? this.dataId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileAttachment &&
        other.id == id &&
        other.fileName == fileName &&
        other.fileType == fileType;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      fileName,
      fileType,
    );
  }
}
