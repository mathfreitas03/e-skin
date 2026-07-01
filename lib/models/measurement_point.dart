import 'dart:convert';

class MeasurementPoint {
  final String id;
  final List<double> real;
  final List<double> imag;
  final List<double> freq;

  const MeasurementPoint({
    required this.id,
    required this.real,
    required this.imag,
    required this.freq,
  });

  Map<String, dynamic> toMap({required String pointId}) {
    return {
      'id': id,
      'point_id': pointId,
      'real': jsonEncode(real),
      'imag': jsonEncode(imag),
      'freq': jsonEncode(freq),
    };
  }

  factory MeasurementPoint.fromMap(Map<String, dynamic> map) {
    return MeasurementPoint(
      id: map['id'] as String,
      real: List<double>.from(jsonDecode(map['real'] as String)),
      imag: List<double>.from(jsonDecode(map['imag'] as String)),
      freq: List<double>.from(jsonDecode(map['freq'] as String)),
    );
  }
}