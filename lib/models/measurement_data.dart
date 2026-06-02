class MeasurementData {

  final String id;

  final DateTime timestamp;

  final List<double> real;

  final List<double> imag;

  final List<double> freq;

  final Map<String, dynamic>? metadata;

  const MeasurementData({
    required this.id,
    required this.timestamp,
    required this.real,
    required this.imag,
    required this.freq,
    this.metadata,
  });
}