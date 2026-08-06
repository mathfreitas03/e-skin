import 'package:eprobe/models/dataset.dart';
import 'package:eprobe/models/dataset_point.dart';
import 'package:eprobe/models/measurement_point.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DB {
  DB._();

  static final DB instance = DB._();   
  static Database? _database;   

  Future<Database> get getDatabase async {
  if (_database != null) return _database!;
  _database = await _initDatabase();
  return _database!;
}

  _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'eprobe.db'),
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> closeAndReset() async {
    if (_database != null) {
      if (_database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    }
  }

  _onCreate(db, db_version) async{
    await db.execute(_dataset);
    await db.execute(_measurement_data);
    await db.execute(_measurement_point);
    await db.execute(_measurement_session);
  }
  
  String get _measurement_session => '''
  CREATE TABLE measurement_session (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
  ''';

  String get _dataset => '''
  CREATE TABLE dataset (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    image_path TEXT NOT NULL,
    session_id TEXT NOT NULL,
    FOREIGN KEY (session_id)
      REFERENCES measurement_session(id)
      ON DELETE CASCADE
  )
  ''';

  String get _measurement_point => '''
  CREATE TABLE measurement_point (
    id TEXT PRIMARY KEY,
    label TEXT,
    x REAL,
    y REAL,
    timestamp TEXT,
    dataset_id TEXT,
    metadata TEXT
  )
''';

String get _measurement_data => '''
  CREATE TABLE measurement_data (
    id TEXT PRIMARY KEY,
    point_id TEXT,
    real TEXT,
    imag TEXT,
    freq TEXT
  )
''';


Future<List<DataSet>> getDataSetsFromCurrentSession() async {
  final db = await getDatabase;
  
  // 1. Busca a sessão mais recente criada no banco (LIMIT 1)
  final List<Map<String, dynamic>> latestSession = await db.query(
    'measurement_session',
    orderBy: 'created_at DESC',
    limit: 1,
  );

  if (latestSession.isEmpty) {
    return [];
  }

  String currentSessionId = latestSession.first['id'];

  final List<Map<String, dynamic>> datasetsMap = await db.query(
    'dataset',
    where: 'session_id = ?',
    whereArgs: [currentSessionId],
  );
  
  List<DataSet> datasets = [];

  for (var datasetRow in datasetsMap) {
    String datasetId = datasetRow['id'];

    final List<Map<String, dynamic>> pointsMap = await db.query(
      'measurement_point',
      where: 'dataset_id = ?',
      whereArgs: [datasetId],
    );

    List<DatasetPoint> points = [];

    for (var pointRow in pointsMap) {
      String pointId = pointRow['id'];

      final List<Map<String, dynamic>> measurementsMap = await db.query(
        'measurement_data',
        where: 'point_id = ?',
        whereArgs: [pointId],
      );

      List<MeasurementPoint> measurements = measurementsMap
          .map((m) => MeasurementPoint.fromMap(m))
          .toList();

      points.add(DatasetPoint.fromMap(pointRow, measurements));
    }

    datasets.add(DataSet.fromMap(datasetRow, points));
  }

  return datasets;
}
}
