import 'dart:math';

class EcgDataGenerator {
  final double heartRateBpm;
  final int samplesPerSecond;

  EcgDataGenerator({this.heartRateBpm = 75, this.samplesPerSecond = 250});

  List<Point<double>> generateEcgData(double durationInSeconds) {
    List<Point<double>> dataPoints = [];
    final double beatDuration = 60.0 / heartRateBpm; // Duration of one cycle in seconds
    final int samplesPerBeat = (beatDuration * samplesPerSecond).round();
    final int totalSamples = (durationInSeconds * samplesPerSecond).round();

    // A simple template for a single beat
    List<double> singleBeatTemplate = _generateSingleBeatTemplate(samplesPerBeat);

    for (int i = 0; i < totalSamples; i++) {
      int beatIndex = i % samplesPerBeat;
      double y = singleBeatTemplate[beatIndex];
      double x = i / samplesPerSecond; // Time in seconds
      dataPoints.add(Point<double>(x, y));
    }

    return dataPoints;
  }

  List<double> _generateSingleBeatTemplate(int samplesPerBeat) {
    List<double> template = List.filled(samplesPerBeat, 0.0);

    // Define key points in the cycle (approximate percentages of the beat duration)
    int pStart = (samplesPerBeat * 0.05).round();
    int pPeak = (samplesPerBeat * 0.10).round();
    int pEnd = (samplesPerBeat * 0.15).round();
    int qPeak = (samplesPerBeat * 0.20).round();
    int rPeak = (samplesPerBeat * 0.22).round();
    int sPeak = (samplesPerBeat * 0.24).round();
    int tStart = (samplesPerBeat * 0.35).round();
    int tPeak = (samplesPerBeat * 0.45).round();
    int tEnd = (samplesPerBeat * 0.55).round();
    // Rest is the flat line (isoelectric period)

    // P-wave
    _addWave(template, pStart, pEnd, pPeak, 0.2);
    // QRS complex
    _addWave(template, pEnd, qPeak, qPeak, -0.4); // Q
    _addWave(template, qPeak, rPeak, rPeak, 3.0); // R
    _addWave(template, rPeak, sPeak, sPeak, -0.6); // S
    // T-wave
    _addWave(template, tStart, tEnd, tPeak, 0.5);

    return template;
  }

  void _addWave(List<double> template, int start, int end, int peakPos, double amplitude) {
    for (int i = start; i < end; i++) {
      // Use a simple sine wave shape for a smooth transition
      double phase = (i - start) / (end - start) * pi;
      template[i] += sin(phase) * amplitude;
    }
  }
}
