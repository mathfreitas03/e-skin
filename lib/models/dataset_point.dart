import 'package:eprobe/models/measurement_point.dart';
import 'dart:convert';

class DatasetPoint {
  final String id;
  final String label;
  final double x;
  final double y;
  final DateTime timestamp; // Timestamp movido para cá
  final List<MeasurementPoint> measurements;
  final Map<String, dynamic>? metadata;

  const DatasetPoint({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.timestamp,
    required this.measurements,
    this.metadata,
  });

  Map<String, dynamic> toMap({required String datasetId}) {
    return {
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'timestamp': timestamp.toIso8601String(), // Salva como String ISO8601
      'dataset_id': datasetId,
      'metadata': metadata != null ? jsonEncode(metadata) : null, 
    };
  }

  factory DatasetPoint.fromMap(Map<String, dynamic> map, List<MeasurementPoint> measurements) {
    return DatasetPoint(
      id: map['id'] as String,
      label: map['label'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String), // DateTime
      measurements: measurements,
      metadata: map['metadata'] != null 
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }
}