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
}