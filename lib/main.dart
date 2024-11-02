import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'bike_station.dart';

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
  bool _isLoading = true;
  BikeStation? _nearestStationOfStart;
  BikeStation? _nearestStationOfEnd;
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
            minX: double.parse(item['stationLongitude']) - 0.0001,
            maxX: double.parse(item['stationLongitude']) + 0.0001,
            minY: double.parse(item['stationLatitude']) - 0.0001,
            maxY: double.parse(item['stationLatitude']) + 0.0001,
          );
          await _dbHelper.insertBikeStation(bikeStation);
        }
      } else {
        throw Exception('Failed to load data for page $page');
      }

      setState(() {
        print("${(page - 1) * 1000 + 1} ~ ${page * 1000}번 데이터 저장 완료!");
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _search() async {
    _nearestStationOfStart = await findNearestStation(37.631855, 127.077707);
    _nearestStationOfEnd = await findNearestStation(37.628308, 127.090843);
    final response = await http.get(Uri.parse('https://router.project-osrm.org/route/v1/bicycle/127.077964,37.631779;127.090394,37.628897?overview=false&steps=true'));
    print(response.body);
  }

  // 가장 가까운 대여소를 찾는 메서드
  Future<BikeStation?> findNearestStation(double currentLat, double currentLon) async {
    final stations = await _dbHelper.getBikeStations();
    BikeStation? nearestStation;
    double nearestDistance = double.infinity;

    for (var station in stations) {
      final centerLat = (station.minY + station.maxY) / 2;
      final centerLon = (station.minX + station.maxX) / 2;

      final distance = _calculateDistance(currentLat, currentLon, centerLat, centerLon);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestStation = station;
      }
    }
    return nearestStation;
  }

  // 두 지점 사이의 거리 계산 (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // 지구의 반지름 (미터)
    final phi1 = lat1 * (3.141592653589793 / 180);
    final phi2 = lat2 * (3.141592653589793 / 180);
    final deltaPhi = (lat2 - lat1) * (3.141592653589793 / 180);
    final deltaLambda = (lon2 - lon1) * (3.141592653589793 / 180);

    final a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
        (cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // 미터 단위
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator() // 로딩 인디케이터
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _search,
              child: const Text("경로 검색"),
            ),
            const SizedBox(height: 20),
            if (_nearestStationOfStart != null) ...[
              Text("출발 대여소"),
              Text("위도: ${(_nearestStationOfStart!.minY + _nearestStationOfStart!.maxY) / 2}"),
              Text("경도: ${(_nearestStationOfStart!.minX + _nearestStationOfStart!.maxX) / 2}"),
            ],
            if (_nearestStationOfEnd != null) ...[
              Text("도착 대여소"),
              Text("위도: ${(_nearestStationOfEnd!.minY + _nearestStationOfEnd!.maxY) / 2}"),
              Text("경도: ${(_nearestStationOfEnd!.minX + _nearestStationOfEnd!.maxX) / 2}"),
            ],
            if (_nearestStationOfStart == null && _nearestStationOfEnd == null)
              const Text("가장 가까운 대여소가 없습니다."),
          ],
        ),
      ),
    );
  }
}