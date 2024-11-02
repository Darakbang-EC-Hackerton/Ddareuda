class BikeStation {
  final String stationId;
  final String stationName;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  BikeStation({
    required this.stationId,
    required this.stationName,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  Map<String, dynamic> toMap() {
    return {
      'stationId': stationId,
      'stationName': stationName,
      'minX': minX,
      'maxX': maxX,
      'minY': minY,
      'maxY': maxY,
    };
  }
}