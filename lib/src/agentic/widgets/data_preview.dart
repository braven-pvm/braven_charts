// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart' hide DataColumn;

import '../tools/data_store.dart';

/// Widget showing data preview after file parsing
///
/// Displays:
/// - File name
/// - Row count
/// - Scrollable column list with:
///   - Column name
///   - Data type (number/string/datetime/boolean)
///   - Nullable flag
///   - Statistics for numeric columns (min/max/mean/null_count)
class DataPreview extends StatelessWidget {
  const DataPreview({
    super.key,
    required this.dataId,
  });

  final String dataId;

  @override
  Widget build(BuildContext context) {
    final store = DataStore();
    final frame = store.get(dataId);

    if (frame == null) {
      return const Card(
        margin: EdgeInsets.all(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Data not found',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 1,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with file name and row count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    frame.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    '${frame.rowCount} rows',
                    style: const TextStyle(fontSize: 12),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Column list
            const Text(
              'Columns',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            // Scrollable column list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: frame.columns.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final column = frame.columns[index];
                  return _buildColumnItem(context, column);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnItem(BuildContext context, DataColumn column) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column name and type
          Row(
            children: [
              Icon(
                _getTypeIcon(column.type),
                size: 14,
                color: _getTypeColor(column.type),
              ),
              const SizedBox(width: 6),
              Text(
                column.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(column.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  column.type,
                  style: TextStyle(
                    color: _getTypeColor(column.type),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              if (column.nullable) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'nullable',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                          fontSize: 10,
                        ),
                  ),
                ),
              ],
            ],
          ),
          // Statistics for numeric columns
          if (column.type == 'number' && column.stats.min != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildStatChip(
                    context,
                    'Min',
                    _formatNumber(column.stats.min!),
                  ),
                  _buildStatChip(
                    context,
                    'Max',
                    _formatNumber(column.stats.max!),
                  ),
                  if (column.stats.mean != null)
                    _buildStatChip(
                      context,
                      'Mean',
                      _formatNumber(column.stats.mean!),
                    ),
                  if (column.stats.nullCount > 0)
                    _buildStatChip(
                      context,
                      'Nulls',
                      column.stats.nullCount.toString(),
                      color: Colors.orange,
                    ),
                ],
              ),
            ),
          ],
          // Sample values (if available)
          if (column.sampleValues.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                'Samples: ${column.sampleValues.take(3).map((v) => v.toString()).join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? Colors.blue[800],
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'number':
        return Icons.tag;
      case 'string':
        return Icons.text_fields;
      case 'datetime':
        return Icons.access_time;
      case 'boolean':
        return Icons.toggle_on;
      default:
        return Icons.help_outline;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'number':
        return Colors.blue;
      case 'string':
        return Colors.green;
      case 'datetime':
        return Colors.purple;
      case 'boolean':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(num value) {
    if (value is int || value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}
