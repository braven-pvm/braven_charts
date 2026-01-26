class Metric {
  final String name;
  final double value;
  final String unit;
  final DateTime? timestamp;

  const Metric({
    required this.name,
    required this.value,
    required this.unit,
    this.timestamp,
  });

  Metric copyWith({
    String? name,
    double? value,
    String? unit,
    DateTime? timestamp,
  }) {
    return Metric(
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  factory Metric.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    return Metric(
      name: (json['name'] ?? '').toString(),
      value: value is num ? value.toDouble() : 0.0,
      unit: (json['unit'] ?? '').toString(),
      timestamp: json['timestamp'] is String
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }
}
