import 'dart:math';
import 'database_helper.dart';
import 'bike_station.dart';

Future<BikeStation?> findNearestStation(double currentLat, double currentLon) async {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final stations = await dbHelper.getBikeStations();
  BikeStation? nearestStation;
  double nearestDistance = double.infinity;

  for (var station in stations) {
    final centerLat = (station.minY + station.maxY) / 2;
    final centerLon = (station.minX + station.maxX) / 2;
    final distance = calculateDistance(currentLat, currentLon, centerLat, centerLon);

    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearestStation = station;
    }
  }
  return nearestStation;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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