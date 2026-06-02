import 'package:eprobe/models/measurement_data.dart';

class MeasurementPoint {

  final String id;

  final String label;

  final double x;
  final double y;

  final List<MeasurementData> measurements;

  const MeasurementPoint({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.measurements,
  });
}