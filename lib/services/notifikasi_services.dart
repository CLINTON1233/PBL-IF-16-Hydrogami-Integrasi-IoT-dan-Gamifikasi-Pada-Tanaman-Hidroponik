import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:application_hydrogami/models/notifikasi_model.dart'; // Import model
import 'package:application_hydrogami/services/globals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LayananNotifikasi {
  static const String baseURL = 'https://admin-hydrogami.up.railway.app/api/';
  static const bool debugMode = true;

  // Method untuk mendapatkan headers dengan auth token dan logging
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (debugMode) {
        print(
            '[NotifikasiService] Token: ${token.isNotEmpty ? '*****' + token.substring(token.length - 5) : 'KOSONG'}');
      }

      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        ...headers,
      };
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error get headers: $e');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers,
      };
    }
  }

  // Helper method untuk handle response
  static dynamic _handleResponse(http.Response response) {
    if (debugMode) {
      print('[NotifikasiService] Status Code: ${response.statusCode}');
      print('[NotifikasiService] Response Body: ${response.body}');
    }

    try {
      final data = json.decode(response.body);
      return data;
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error parsing JSON: $e');
      return null;
    }
  }

  // Ambil semua notifikasi
  static Future<List<NotifikasiModel>> ambilNotifikasi() async {
    try {
      print('Mengambil notifikasi dari ${baseURL}notifikasi');
      final response = await http.get(
        Uri.parse('${baseURL}notifikasi'),
        headers: await _getHeaders(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data != null && data['success']) {
        final List<dynamic> items = data['data'] ?? [];
        print('Parsed items: $items');
        
        return items.map((item) => NotifikasiModel.fromJson(item)).toList();
      } else {
        throw Exception(data?['message'] ?? 'Gagal memuat notifikasi');
      }
    } catch (e) {
      print('Error ambilNotifikasi: $e');
      rethrow;
    }
  }

  // Ambil data sensor
  static Future<List<Map<String, dynamic>>> ambilDataSensor() async {
    try {
      final response = await http.get(
        Uri.parse('${baseURL}sensor_data'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);

      if (response.statusCode == 200 && data != null && data['success']) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data?['message'] ?? 'Gagal memuat data sensor');
      }
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error ambilDataSensor: $e');
      rethrow;
    }
  }

  // Generate notifikasi otomatis dari data sensor
  static Future<bool> generateNotificationsFromSensorData() async {
    try {
      final sensorData = await ambilDataSensor();
      bool anyNotificationSent = false;

      for (var data in sensorData) {
        // Cek pH
        if (data['ph'] < 6.5 || data['ph'] > 8.5) {
          await kirimNotifikasi(
            idSensor: data['id_sensor'].toString(),
            jenisSensor: 'pH Sensor',
            pesan: 'Nilai pH ${data['ph']} diluar range normal (6.5-8.5)',
            status: 'warning',
          );
          anyNotificationSent = true;
        }

        // Cek suhu
        if (data['suhu'] > 30) {
          await kirimNotifikasi(
            idSensor: data['id_sensor'].toString(),
            jenisSensor: 'Suhu Sensor',
            pesan: 'Suhu air ${data['suhu']}°C terlalu tinggi',
            status: 'danger',
          );
          anyNotificationSent = true;
        }
      }

      return anyNotificationSent;
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error generateNotifications: $e');
      return false;
    }
  }

  // Kirim notifikasi baru
  static Future<bool> kirimNotifikasi({
    required String idSensor,
    required String jenisSensor,
    required String pesan,
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseURL}notifikasi'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'type': jenisSensor,
          'notifiable_type': 'sensor',
          'notifiable_id': idSensor,
          'data': {
            'message': pesan,
            'status': status,
            'id_sensor': idSensor,
          },
        }),
      );

      final data = _handleResponse(response);
      return response.statusCode == 200 && data != null;
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error kirimNotifikasi: $e');
      return false;
    }
  }

  // Tandai notifikasi sebagai sudah dibaca
  static Future<bool> tandaiDibaca(String id) async { // Ubah parameter ke String
    try {
      final response = await http.put(
        Uri.parse('${baseURL}notifikasi/$id/read'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      return response.statusCode == 200 && data != null && data['success'];
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error tandaiDibaca: $e');
      return false;
    }
  }

  // Hapus notifikasi tertentu
  static Future<bool> hapusNotifikasi(String id) async { // Ubah parameter ke String
    try {
      final response = await http.delete(
        Uri.parse('${baseURL}notifikasi/$id'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);
      return response.statusCode == 200 && data != null && data['success'];
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error hapusNotifikasi: $e');
      return false;
    }
  }

  // Hapus semua notifikasi
  static Future<bool> hapusSemuaNotifikasi() async {
    try {
      if (debugMode) print('[NotifikasiService] Menghapus semua notifikasi...');

      final response = await http.delete(
        Uri.parse('${baseURL}notifikasi'),
        headers: await _getHeaders(),
      );

      if (debugMode) {
        print('[NotifikasiService] Response status: ${response.statusCode}');
        print('[NotifikasiService] Response body: ${response.body}');
      }

      final data = _handleResponse(response);
      return response.statusCode == 200 && data != null && data['success'];
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error hapusSemuaNotifikasi: $e');
      return false;
    }
  }

  // Hitung notifikasi yang belum dibaca
  static Future<int> hitungNotifikasiBelumDibaca() async {
    try {
      final response = await http.get(
        Uri.parse('${baseURL}notifikasi/unread-count'),
        headers: await _getHeaders(),
      );

      final data = _handleResponse(response);

      if (response.statusCode == 200 && data != null && data['success']) {
        return data['data']['unread_count'] ?? 0;
      }
      return 0;
    } catch (e) {
      if (debugMode) print('[NotifikasiService] Error hitungNotifikasiBelumDibaca: $e');
      return 0;
    }
  }
}