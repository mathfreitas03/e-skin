import 'package:eprobe/models/measurement_point.dart';

class DataSet {

  final String id;
  final String name;
  final String imagePath;
 // final DateTime createdAt;
  final List<MeasurementPoint> points;

  const DataSet({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.points,
    // required this.createdAt,
  });
}