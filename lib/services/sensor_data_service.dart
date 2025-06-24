import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data_model.dart';

class SensorDataService {
  static const String _baseUrl =
      'http://10.0.2.2:8000/api'; // Ganti dengan URL Laravel Anda

  Future<bool> sendSensorData(SensorData data) async {
    try {
      final jsonData = data.toJson();
      print('Sending data: $jsonData'); // Debug 1

      final response = await http.post(
        Uri.parse('$_baseUrl/sensor-data'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(jsonData),
      );

      print('Response status: ${response.statusCode}'); // Debug 2
      print('Response body: ${response.body}'); // Debug 3

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to send data: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending data: $e');
      return false;
    }
  }

  Future<List<SensorData>> getSensorData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/sensor-data'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => SensorData.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error getting data: $e');
      throw e;
    }
  }
}
