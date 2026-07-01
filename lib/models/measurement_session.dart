import 'package:eprobe/models/dataset.dart';

class MeasurementSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<DataSet> datasets;

  const MeasurementSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.datasets,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MeasurementSession.fromMap(Map<String, dynamic> map, List<DataSet> datasets) {
    return MeasurementSession(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      datasets: datasets,
    );
  }
}