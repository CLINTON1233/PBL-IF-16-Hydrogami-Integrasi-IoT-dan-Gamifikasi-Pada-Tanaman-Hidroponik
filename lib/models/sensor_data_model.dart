class SensorData {
  final double temperature;
  final double humidity;
  final double light;
  final int soilMoisture;
  final double tds;
  final double ph;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.light,
    required this.soilMoisture,
    required this.tds,
    required this.ph,
  });

  // Convert SensorData to JSON
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'soil_moisture': soilMoisture,
      'tds': tds,
      'ph': ph,
    };
  }

  // Create SensorData from JSON
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: json['temperature']?.toDouble() ?? 0.0,
      humidity: json['humidity']?.toDouble() ?? 0.0,
      light: json['light']?.toDouble() ?? 0.0,
      soilMoisture: json['soil_moisture']?.toInt() ?? 0,
      tds: json['tds']?.toDouble() ?? 0.0,
      ph: json['ph']?.toDouble() ?? 0.0,
    );
  }
}
