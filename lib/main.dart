import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bike Station App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Bike Station App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _stationCount = 0;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _fetchAndSaveData();
  }

  // 데이터를 가져와 SQLite에 저장하는 메서드
  Future<void> _fetchAndSaveData() async {
    for (int page = 1; page <= 3; page++) {
      final response = await http.get(Uri.parse(
          'http://openapi.seoul.go.kr:8088/647269414464617537384a694b6467/json/bikeList/${(page - 1) * 1000 + 1}/${page * 1000}/'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final bikeList = jsonData['rentBikeStatus']['row'];

        // 데이터 저장
        for (var item in bikeList) {
          final bikeStation = BikeStation(
            stationId: item['stationId'],
            stationName: item['stationName'],
            stationLatitude: double.parse(item['stationLatitude']),
            stationLongitude: double.parse(item['stationLongitude']),
            rackTotCnt: int.parse(item['rackTotCnt']),
            parkingBikeTotCnt: int.parse(item['parkingBikeTotCnt']),
          );
          await _dbHelper.insertBikeStation(bikeStation);
        }
      } else {
        throw Exception('Failed to load data for page $page');
      }

      setState(() {
        print("${(page-1)*1000+1} ~ ${page*1000}번 데이터 저장 완료!");
      });

      // 데이터 로드
      await _loadData();
    }
  }


  // 저장된 데이터를 로드하는 메서드
  Future<void> _loadData() async {
    final stations = await _dbHelper.getBikeStations();
    setState(() {
      _stationCount = stations.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _stationCount == 0
            ? const Text("Loading data...")
            : Text("총 저장된 데이터 개수: $_stationCount"),
      ),
    );
  }
}

// BikeStation 모델 클래스
class BikeStation {
  final String stationId;
  final String stationName;
  final double stationLatitude;
  final double stationLongitude;
  final int rackTotCnt;
  final int parkingBikeTotCnt;

  BikeStation({
    required this.stationId,
    required this.stationName,
    required this.stationLatitude,
    required this.stationLongitude,
    required this.rackTotCnt,
    required this.parkingBikeTotCnt,
  });

  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'stationLatitude': stationLatitude,
      'stationLongitude': stationLongitude,
      'rackTotCnt': rackTotCnt,
      'parkingBikeTotCnt': parkingBikeTotCnt,
    };
  }
}

// SQLite 데이터베이스 헬퍼 클래스
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
            stationLatitude REAL,
            stationLongitude REAL,
            rackTotCnt INTEGER,
            parkingBikeTotCnt INTEGER
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
        stationLatitude: maps[i]['stationLatitude'],
        stationLongitude: maps[i]['stationLongitude'],
        rackTotCnt: maps[i]['rackTotCnt'],
        parkingBikeTotCnt: maps[i]['parkingBikeTotCnt'],
      );
    });
  }

  // DB 연결 종료
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}