import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'sensor_reading.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('iot_project.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sensorType TEXT NOT NULL,
            value REAL NOT NULL,
            timestamp TEXT NOT NULL,
            nodeId INTEGER
          )
        ''');
      },
    );
  }
   // Función para insertar una nueva lectura en la tabla 'readings'
  Future<int> insertReading(Map<String, dynamic> row) async {
    final db = await database;
    return await db.insert('readings', row);
  }
  
  Future<List<SensorReading>> getReadingsByType(String type) async {
    final db = await database;
    final result = await db.query(
      'readings',
      where: 'sensorType = ?',
      whereArgs: [type],
      orderBy: 'id DESC',
    );
    return result.map((map) => SensorReading.fromMap(map)).toList();
  }
    // Función para obtener TODAS las lecturas (temperatura y humedad juntas)
Future<List<SensorReading>> getAllReadings() async {
  final db = await database;
  final result = await db.query(
    'readings',
    orderBy: 'id DESC',
  );
  return result.map((map) => SensorReading.fromMap(map)).toList();
}
}