import 'package:eprobe/models/dataset_point.dart';

class DataSet {
  final String id;
  final String name;
  final String imagePath;
  final List<DatasetPoint> points;

  const DataSet({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.points,
  });

  Map<String, dynamic> toMap({required String sessionId}) {
    return {
      'id': id,
      'name': name,
      'image_path': imagePath,
      'session_id': sessionId, // Vincula o dataset a uma sessão de medição
    };
  }

  factory DataSet.fromMap(Map<String, dynamic> map, List<DatasetPoint> points) {
    return DataSet(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['image_path'] as String,
      points: points,
    );
  }
}