import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bike_station.dart';

Future<void> searchRoute(BikeStation startStation, BikeStation endStation) async {
  final startLat = (startStation.minY + startStation.maxY) / 2;
  final startLon = (startStation.minX + startStation.maxX) / 2;
  final endLat = (endStation.minY + endStation.maxY) / 2;
  final endLon = (endStation.minX + endStation.maxX) / 2;

  final response = await http.get(Uri.parse(
      'https://router.project-osrm.org/route/v1/bicycle/$startLon,$startLat;$endLon,$endLat?overview=false&steps=true'));

  if (response.statusCode == 200) {
    print(response.body);
  } else {
    throw Exception('Failed to load route data');
  }
}