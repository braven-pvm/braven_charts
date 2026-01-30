// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../models/file_attachment.dart';

/// Widget displaying a file attachment as a chip with metadata
///
/// Shows:
/// - File type icon
/// - File name (truncated if long)
/// - File size (formatted as KB/MB)
/// - Status indicator (pending/parsing/ready/error)
/// - Close button to remove the attachment
class FileAttachmentChip extends StatelessWidget {
  const FileAttachmentChip({
    super.key,
    required this.attachment,
    this.onRemove,
  });

  final FileAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: _buildFileTypeIcon(),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _truncateFileName(attachment.fileName),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatFileSize(attachment.fileSizeBytes),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(width: 4),
          _buildStatusIcon(),
        ],
      ),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: _getChipColor(),
    );
  }

  /// Builds the file type icon
  Widget _buildFileTypeIcon() {
    final iconData = _getFileTypeIcon();
    return Icon(
      iconData,
      size: 20,
      color: _getIconColor(),
    );
  }

  /// Gets the icon for the file type
  IconData _getFileTypeIcon() {
    switch (attachment.fileType.toLowerCase()) {
      case 'fit':
        return Icons.fitness_center;
      case 'csv':
        return Icons.table_chart;
      case 'tcx':
        return Icons.route;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Gets the icon color based on file type
  Color _getIconColor() {
    switch (attachment.fileType.toLowerCase()) {
      case 'fit':
        return Colors.blue;
      case 'csv':
        return Colors.green;
      case 'tcx':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Builds the status icon
  Widget _buildStatusIcon() {
    switch (attachment.status) {
      case FileStatus.pending:
        return const Icon(
          Icons.access_time,
          size: 16,
          color: Colors.orange,
        );
      case FileStatus.parsing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case FileStatus.ready:
        return const Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green,
        );
      case FileStatus.error:
        return const Icon(
          Icons.error,
          size: 16,
          color: Colors.red,
        );
    }
  }

  /// Gets the chip background color based on status
  Color _getChipColor() {
    switch (attachment.status) {
      case FileStatus.error:
        return Colors.red[50]!;
      case FileStatus.ready:
        return Colors.green[50]!;
      case FileStatus.parsing:
        return Colors.blue[50]!;
      case FileStatus.pending:
        return Colors.grey[100]!;
    }
  }

  /// Truncates filename if it exceeds 30 characters
  String _truncateFileName(String fileName) {
    const maxLength = 30;
    if (fileName.length <= maxLength) {
      return fileName;
    }
    // Keep extension visible
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      final extension = fileName.substring(lastDot);
      final nameWithoutExt = fileName.substring(0, lastDot);
      if (nameWithoutExt.length + extension.length <= maxLength) {
        return fileName;
      }
      final keepLength = maxLength - extension.length - 3; // 3 for "..."
      return '${nameWithoutExt.substring(0, keepLength)}...$extension';
    }
    return '${fileName.substring(0, maxLength - 3)}...';
  }

  /// Formats file size as KB or MB
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
      return '$mb MB';
    }
  }
}
