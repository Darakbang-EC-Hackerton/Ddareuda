import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_helper.dart';
import 'bike_station.dart';

Future<void> fetchAndSaveData() async {
  final DatabaseHelper dbHelper = DatabaseHelper();

  for (int page = 1; page <= 3; page++) {
    final response = await http.get(Uri.parse(
        'http://openapi.seoul.go.kr:8088/647269414464617537384a694b6467/json/bikeList/${(page - 1) * 1000 + 1}/${page * 1000}/'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final bikeList = jsonData['rentBikeStatus']['row'];

      for (var item in bikeList) {
        final bikeStation = BikeStation(
          stationId: item['stationId'],
          stationName: item['stationName'],
          minX: double.parse(item['stationLongitude']) - 0.0001,
          maxX: double.parse(item['stationLongitude']) + 0.0001,
          minY: double.parse(item['stationLatitude']) - 0.0001,
          maxY: double.parse(item['stationLatitude']) + 0.0001,
        );
        await dbHelper.insertBikeStation(bikeStation);
      }
    } else {
      throw Exception('Failed to load data for page $page');
    }
  }
}