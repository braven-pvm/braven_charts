// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Scrollbar Showcase - Dual-Purpose Scrollbars (Pan + Zoom)
///
/// Demonstrates Phase 5 features:
/// - Pan via center drag (User Story 2)
/// - Zoom via edge resize (User Story 3)
/// - Visual limit feedback: flash animation + cursor changes
/// - Callbacks: onPanChanged, onZoomChanged, onViewportChanged
/// - Configuration: enableResizeHandles, zoom limits, auto-hide
///
/// This is the definitive test for 010-dual-purpose-scrollbars implementation.
library;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/theming/components/scrollbar_config.dart';
import 'package:braven_charts/src/theming/components/scrollbar_theme.dart';
import 'package:flutter/material.dart' hide ScrollbarTheme;

class ScrollbarShowcaseScreen extends StatefulWidget {
  const ScrollbarShowcaseScreen({super.key});

  @override
  State<ScrollbarShowcaseScreen> createState() => _ScrollbarShowcaseScreenState();
}

class _ScrollbarShowcaseScreenState extends State<ScrollbarShowcaseScreen> {
  // Event tracking
  String lastEvent = 'No events yet';
  List<String> eventLog = [];
  int eventCount = 0;

  // Configuration state
  bool showXScrollbar = true;
  bool showYScrollbar = true;
  bool enableResizeHandles = true;
  bool autoHide = false;
  double minZoomRatio = 0.01; // 1% minimum
  double maxZoomRatio = 1.0; // 100% maximum
  double edgeGripWidth = 8.0;
  double thickness = 16.0;

  // Chart state tracking
  double currentZoomX = 1.0;
  double currentZoomY = 1.0;
  Offset? lastPanOffset;
  Map<String, dynamic>? currentViewport;

  void _logEvent(String event) {
    setState(() {
      lastEvent = event;
      eventCount++;
      eventLog.insert(0, '[$eventCount] $event');
      if (eventLog.length > 30) {
        eventLog.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scrollbar Showcase - Pan + Zoom'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Instructions',
            onPressed: () => _showInstructions(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Chart area
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Status bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100,
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.blue.shade200,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dashboard, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '📊 Scrollbar Status',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildStatusChip(
                            'X-Scrollbar',
                            showXScrollbar ? 'ON' : 'OFF',
                            showXScrollbar ? Colors.green : Colors.grey,
                          ),
                          _buildStatusChip(
                            'Y-Scrollbar',
                            showYScrollbar ? 'ON' : 'OFF',
                            showYScrollbar ? Colors.green : Colors.grey,
                          ),
                          _buildStatusChip(
                            'Zoom (Edge Resize)',
                            enableResizeHandles ? 'ENABLED' : 'DISABLED',
                            enableResizeHandles ? Colors.orange : Colors.grey,
                          ),
                          _buildStatusChip(
                            'X-Zoom',
                            '${(currentZoomX * 100).toInt()}%',
                            Colors.blue,
                          ),
                          _buildStatusChip(
                            'Y-Zoom',
                            '${(currentZoomY * 100).toInt()}%',
                            Colors.purple,
                          ),
                          _buildStatusChip(
                            'Events',
                            '$eventCount',
                            Colors.indigo,
                          ),
                        ],
                      ),
                      if (lastPanOffset != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last Pan: dx=${lastPanOffset!.dx.toStringAsFixed(1)}, dy=${lastPanOffset!.dy.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Chart
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BravenChart(
                          key: const ValueKey('scrollbar_showcase_chart'),
                          chartType: ChartType.line,
                          series: [
                            ChartSeries(
                              id: 'data-1',
                              name: 'Series 1',
                              points: _generateTestData(100, seed: 1),
                            ),
                            ChartSeries(
                              id: 'data-2',
                              name: 'Series 2',
                              points: _generateTestData(100, seed: 2),
                            ),
                          ],
                          theme: ChartTheme.defaultLight.copyWith(
                            scrollbarTheme: ScrollbarTheme.defaultLight.copyWith(
                              xAxisScrollbar: ScrollbarConfig(
                                enableResizeHandles: enableResizeHandles,
                                autoHide: autoHide,
                                minZoomRatio: minZoomRatio,
                                maxZoomRatio: maxZoomRatio,
                                edgeGripWidth: edgeGripWidth,
                                thickness: thickness,
                                autoHideDelay: const Duration(seconds: 2),
                              ),
                              yAxisScrollbar: ScrollbarConfig(
                                enableResizeHandles: enableResizeHandles,
                                autoHide: autoHide,
                                minZoomRatio: minZoomRatio,
                                maxZoomRatio: maxZoomRatio,
                                edgeGripWidth: edgeGripWidth,
                                thickness: thickness,
                                autoHideDelay: const Duration(seconds: 2),
                              ),
                            ),
                          ),
                          interactionConfig: InteractionConfig(
                            enabled: true,
                            showXScrollbar: showXScrollbar,
                            showYScrollbar: showYScrollbar,
                            enableZoom: true,
                            enablePan: true,
                            // Callbacks to track events
                            onPanChanged: (offset) {
                              _logEvent('PAN: dx=${offset.dx.toStringAsFixed(1)}, dy=${offset.dy.toStringAsFixed(1)}');
                              setState(() {
                                lastPanOffset = offset;
                              });
                            },
                            onZoomChanged: (zoomX, zoomY) {
                              _logEvent('ZOOM: X=${(zoomX * 100).toInt()}%, Y=${(zoomY * 100).toInt()}%');
                              setState(() {
                                currentZoomX = zoomX;
                                currentZoomY = zoomY;
                              });
                            },
                            onViewportChanged: (viewport) {
                              final minX = viewport['minX'] ?? 0.0;
                              final maxX = viewport['maxX'] ?? 0.0;
                              final minY = viewport['minY'] ?? 0.0;
                              final maxY = viewport['maxY'] ?? 0.0;
                              _logEvent(
                                'VIEWPORT: X[${minX.toStringAsFixed(1)} → ${maxX.toStringAsFixed(1)}] '
                                'Y[${minY.toStringAsFixed(1)} → ${maxY.toStringAsFixed(1)}]',
                              );
                              setState(() {
                                currentViewport = viewport;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Instructions footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 How to Test:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '• PAN: Drag center of scrollbar handle (cursor: ✋ grab)',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• ZOOM: Drag edges of scrollbar handle (cursor: ↔ resize)',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• LIMIT FEEDBACK: Zoom to 1% or 100% to see flash animation + 🚫 cursor',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• JUMP: Click scrollbar track to jump viewport to that position',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Control panel
          Container(
            width: 360,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                left: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Configuration section
                  const Text(
                    '⚙️ Configuration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Scrollbar Visibility:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SwitchListTile(
                    title: const Text('Show X-Scrollbar (Horizontal)'),
                    subtitle: const Text('Bottom scrollbar for horizontal pan/zoom'),
                    value: showXScrollbar,
                    dense: true,
                    onChanged: (value) => setState(() => showXScrollbar = value),
                  ),
                  SwitchListTile(
                    title: const Text('Show Y-Scrollbar (Vertical)'),
                    subtitle: const Text('Right scrollbar for vertical pan/zoom'),
                    value: showYScrollbar,
                    dense: true,
                    onChanged: (value) => setState(() => showYScrollbar = value),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Zoom Configuration:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Resize Handles'),
                    subtitle: Text(
                      enableResizeHandles ? '✅ Drag edges to zoom' : '❌ Edge resize disabled (pan only)',
                    ),
                    value: enableResizeHandles,
                    dense: true,
                    onChanged: (value) => setState(() => enableResizeHandles = value),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Min Zoom: ${(minZoomRatio * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Slider(
                    value: minZoomRatio,
                    min: 0.01,
                    max: 0.5,
                    divisions: 49,
                    label: '${(minZoomRatio * 100).toInt()}%',
                    onChanged: (value) => setState(() => minZoomRatio = value),
                  ),
                  Text(
                    'Max Zoom: ${(maxZoomRatio * 100).toInt()}%',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Slider(
                    value: maxZoomRatio,
                    min: 0.1,
                    max: 1.0,
                    divisions: 90,
                    label: '${(maxZoomRatio * 100).toInt()}%',
                    onChanged: (value) => setState(() => maxZoomRatio = value),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Visual Configuration:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SwitchListTile(
                    title: const Text('Auto-Hide'),
                    subtitle: const Text('Hide scrollbar after 2s of inactivity'),
                    value: autoHide,
                    dense: true,
                    onChanged: (value) => setState(() => autoHide = value),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Edge Grip Width: ${edgeGripWidth.toInt()}px',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Slider(
                    value: edgeGripWidth,
                    min: 4,
                    max: 16,
                    divisions: 12,
                    label: '${edgeGripWidth.toInt()}px',
                    onChanged: (value) => setState(() => edgeGripWidth = value),
                  ),
                  Text(
                    'Scrollbar Thickness: ${thickness.toInt()}px',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Slider(
                    value: thickness,
                    min: 8,
                    max: 24,
                    divisions: 16,
                    label: '${thickness.toInt()}px',
                    onChanged: (value) => setState(() => thickness = value),
                  ),
                  const Divider(),
                  // Presets
                  const SizedBox(height: 8),
                  const Text(
                    '🎨 Presets:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Default'),
                        onPressed: () => setState(() {
                          showXScrollbar = true;
                          showYScrollbar = true;
                          enableResizeHandles = true;
                          autoHide = false;
                          minZoomRatio = 0.01;
                          maxZoomRatio = 1.0;
                          edgeGripWidth = 8.0;
                          thickness = 16.0;
                          _logEvent('PRESET: Default configuration loaded');
                        }),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.panorama_horizontal, size: 16),
                        label: const Text('Pan Only'),
                        onPressed: () => setState(() {
                          showXScrollbar = true;
                          showYScrollbar = true;
                          enableResizeHandles = false;
                          autoHide = false;
                          _logEvent('PRESET: Pan-only mode (zoom disabled)');
                        }),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.zoom_in, size: 16),
                        label: const Text('Zoom Focus'),
                        onPressed: () => setState(() {
                          showXScrollbar = true;
                          showYScrollbar = true;
                          enableResizeHandles = true;
                          minZoomRatio = 0.05;
                          maxZoomRatio = 0.8;
                          edgeGripWidth = 12.0;
                          _logEvent('PRESET: Zoom focus (5%-80% range, wider grip)');
                        }),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.visibility_off, size: 16),
                        label: const Text('Auto-Hide'),
                        onPressed: () => setState(() {
                          autoHide = true;
                          _logEvent('PRESET: Auto-hide enabled (2s delay)');
                        }),
                      ),
                    ],
                  ),
                  const Divider(),
                  // Event log
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📋 Event Log:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        onPressed: () {
                          setState(() {
                            eventLog.clear();
                            eventCount = 0;
                            lastEvent = 'Log cleared';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade700),
                    ),
                    child: eventLog.isEmpty
                        ? const Center(
                            child: Text(
                              'Interact with scrollbars to see events...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: eventLog.length,
                            itemBuilder: (context, index) {
                              final event = eventLog[index];
                              Color eventColor = const Color(0xFF00FF00);
                              if (event.contains('ZOOM')) {
                                eventColor = const Color(0xFFFF9800);
                              } else if (event.contains('PAN')) {
                                eventColor = const Color(0xFF2196F3);
                              } else if (event.contains('VIEWPORT')) {
                                eventColor = const Color(0xFF9C27B0);
                              } else if (event.contains('PRESET')) {
                                eventColor = const Color(0xFFFFEB3B);
                              }

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  event,
                                  style: TextStyle(
                                    color: eventColor,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Feature checklist
                  const Text(
                    '✅ Feature Checklist:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem('Pan via center drag', 'Drag middle of handle'),
                  _buildFeatureItem('Zoom via edge resize', 'Drag left/right edges'),
                  _buildFeatureItem('Flash animation at limits', 'Zoom to 1% or 100%'),
                  _buildFeatureItem('Cursor feedback', 'Hover over edges (resize ↔)'),
                  _buildFeatureItem('Forbidden cursor at limit', 'Try to zoom beyond limits'),
                  _buildFeatureItem('onPanChanged callback', 'Check event log after pan'),
                  _buildFeatureItem('onZoomChanged callback', 'Check event log after zoom'),
                  _buildFeatureItem('Track click jump', 'Click scrollbar track'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInstructions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Scrollbar Showcase Instructions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This screen demonstrates Phase 5 features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('📊 User Story 2: Pan via Scrollbar'),
              const SizedBox(height: 4),
              const Text('• Drag center of scrollbar handle to pan'),
              const Text('• Cursor shows ✋ grab icon'),
              const Text('• onPanChanged fires with delta offset'),
              const SizedBox(height: 12),
              const Text('🔍 User Story 3: Zoom via Edge Resize'),
              const SizedBox(height: 4),
              const Text('• Drag left/right edges of handle to zoom'),
              const Text('• Cursor shows ↔ resize icon'),
              const Text('• onZoomChanged fires with zoom ratio'),
              const SizedBox(height: 12),
              const Text('⚠️ Zoom Limit Feedback (T091A-T091B):'),
              const SizedBox(height: 4),
              const Text('• Zoom to 1% minimum or 100% maximum'),
              const Text('• Handle flashes (0.8 → 0.4 → 0.8 opacity)'),
              const Text('• Cursor changes to 🚫 forbidden'),
              const SizedBox(height: 12),
              const Text('🎯 Track Click Jump (T073):'),
              const SizedBox(height: 4),
              const Text('• Click scrollbar track area'),
              const Text('• Viewport animates to click position'),
              const Text('• 300ms ease-out animation'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Pro Tip:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Watch the event log (right panel) to see all callbacks firing in real-time!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It!'),
          ),
        ],
      ),
    );
  }

  List<ChartDataPoint> _generateTestData(int count, {int seed = 1}) {
    final points = <ChartDataPoint>[];
    for (int i = 0; i < count; i++) {
      final x = i.toDouble();
      final y = 100 + (i * 2) + ((i * seed) % 30) - (i * i * 0.05);
      points.add(ChartDataPoint(x: x, y: y));
    }
    return points;
  }
}
