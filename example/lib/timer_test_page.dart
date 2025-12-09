// Standalone Timer Test - NO chart libraries, just pure Dart Timer.periodic testing
import 'dart:async';

import 'package:flutter/material.dart';

class TimerTestPage extends StatefulWidget {
  const TimerTestPage({super.key});

  @override
  State<TimerTestPage> createState() => _TimerTestPageState();
}

class _TimerTestPageState extends State<TimerTestPage> {
  Timer? _timer;
  int _targetHz = 60;
  int _tickCount = 0;
  DateTime? _lastTick;
  final List<int> _intervals = [];

  String _status = 'Stopped';
  String _measuredHz = '-';
  String _avgInterval = '-';

  void _startTimer() {
    _stopTimer();

    _tickCount = 0;
    _lastTick = null;
    _intervals.clear();

    final intervalMs = (1000 / _targetHz).round();
    setState(() {
      _status = 'Running (target: $_targetHz Hz, ${intervalMs}ms interval)';
    });

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _onTick();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _status = 'Stopped';
    });
  }

  void _onTick() {
    final now = DateTime.now();

    if (_lastTick != null) {
      final interval = now.difference(_lastTick!).inMilliseconds;
      _intervals.add(interval);
      if (_intervals.length > 100) _intervals.removeAt(0);

      // Update UI every 10 ticks
      if (_tickCount % 10 == 0 && _intervals.isNotEmpty) {
        final avg = _intervals.reduce((a, b) => a + b) / _intervals.length;
        final hz = 1000 / avg;
        setState(() {
          _measuredHz = '${hz.toStringAsFixed(1)} Hz';
          _avgInterval = '${avg.toStringAsFixed(1)} ms';
        });
      }
    }

    _lastTick = now;
    _tickCount++;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pure Timer Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Standalone Timer.periodic Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No charts, no RAF, no nothing - just pure Dart Timer.periodic',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Target Hz slider
            Row(
              children: [
                const Text('Target Rate:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _targetHz.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '$_targetHz Hz',
                    onChanged: (v) {
                      setState(() => _targetHz = v.round());
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_targetHz Hz',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Controls
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _startTimer,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _stopTimer,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),

            // Results
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Results',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildResultRow('Status', _status),
                  _buildResultRow('Tick Count', _tickCount.toString()),
                  _buildResultRow('Measured Rate', _measuredHz),
                  _buildResultRow('Avg Interval', _avgInterval),
                  _buildResultRow('Samples', _intervals.length.toString()),
                ],
              ),
            ),

            const Spacer(),

            const Text(
              'This will prove whether Timer.periodic can maintain accurate timing '
              'independent of any chart rendering or browser throttling.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
