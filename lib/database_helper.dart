import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'bike_station.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bike_station.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE bike_stations(
          stationId TEXT PRIMARY KEY,
          stationName TEXT,
          minX REAL,
          maxX REAL,
          minY REAL,
          maxY REAL
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 테이블이 이미 존재할 경우 삭제하고 재생성합니다.
        await db.execute('DROP TABLE IF EXISTS bike_stations');
        await db.execute('''
        CREATE TABLE bike_stations(
          stationId TEXT PRIMARY KEY,
          stationName TEXT,
          minX REAL,
          maxX REAL,
          minY REAL,
          maxY REAL
        )
      ''');
      },
    );
  }

  // BikeStation 객체를 DB에 삽입
  Future<void> insertBikeStation(BikeStation station) async {
    final db = await database;
    await db.insert(
      'bike_stations',
      station.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BikeStation>> getBikeStations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('bike_stations');
    return List.generate(maps.length, (i) {
      return BikeStation(
          stationId: maps[i]['stationId'],
          stationName: maps[i]['stationName'],
          minX: maps[i]['minX'],
          maxX: maps[i]['maxX'],
          minY: maps[i]['minY'],
          maxY: maps[i]['maxY']
      );
    });
  }

  // DB 연결 종료
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}