// notifikasi_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:application_hydrogami/services/globals.dart';

class NotifikasiModel {
  final int idNotifikasi;
  final int? idSensor;
  final String? jenisSensor;
  final String pesan;
  final String status;
  final int dibaca;
  final DateTime waktuDibuat;

  NotifikasiModel({
    required this.idNotifikasi,
    this.idSensor,
    this.jenisSensor,
    required this.pesan,
    required this.status,
    required this.dibaca,
    required this.waktuDibuat,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'] ?? 0,
      idSensor: json['id_sensor'],
      jenisSensor: json['jenis_sensor'],
      pesan: json['pesan'] ?? 'No message',
      status: json['status'] ?? 'info',
      dibaca: json['dibaca'] ?? 0,
      waktuDibuat: DateTime.parse(json['waktu_dibuat']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id_sensor': idSensor,
        'jenis_sensor': jenisSensor,
        'pesan': pesan,
        'status': status,
        'dibaca': dibaca,
      };
}

class LayananNotifikasi {
  static Future<List<NotifikasiModel>> ambilNotifikasi() async {
    try {
      final response = await http.get(
        Uri.parse('${baseURL}notifikasi'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return (data['data'] as List)
              .map((item) => NotifikasiModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error mengambil notifikasi: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> ambilDataSensor() async {
    try {
      final response = await http.get(
        Uri.parse('${baseURL}sensor_data'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error mengambil data sensor: $e');
      return [];
    }
  }

  static Future<bool> generateNotificationsFromSensorData() async {
    try {
      final sensorData = await ambilDataSensor();

      for (var data in sensorData) {
        // Contoh logika notifikasi berdasarkan nilai sensor
        if (data['ph'] < 6.5 || data['ph'] > 8.5) {
          await kirimNotifikasi(
            idSensor: data['id_sensor'].toString(),
            jenisSensor: 'pH Sensor',
            pesan: 'Nilai pH ${data['ph']} diluar range normal (6.5-8.5)',
            status: 'warning',
          );
        }

        if (data['suhu'] > 30) {
          await kirimNotifikasi(
            idSensor: data['id_sensor'].toString(),
            jenisSensor: 'Suhu Sensor',
            pesan: 'Suhu air ${data['suhu']}°C terlalu tinggi',
            status: 'danger',
          );
        }

        // Tambahkan kondisi notifikasi lainnya sesuai kebutuhan
      }

      return true;
    } catch (e) {
      print('Error generate notifikasi: $e');
      return false;
    }
  }

  static Future<bool> kirimNotifikasi({
    required String idSensor,
    required String jenisSensor,
    required String pesan,
    required String status,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${baseURL}notifikasi'),
        headers: headers,
        body: jsonEncode({
          'id_sensor': idSensor,
          'jenis_sensor': jenisSensor,
          'pesan': pesan,
          'status': status,
          'dibaca': 0,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error mengirim notifikasi: $e');
      return false;
    }
  }

  static Future<bool> tandaiDibaca(int idNotifikasi) async {
    try {
      final response = await http.put(
        Uri.parse('${baseURL}notifikasi/$idNotifikasi/read'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error menandai notifikasi dibaca: $e');
      return false;
    }
  }

  static Future<bool> hapusNotifikasi(int idNotifikasi) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseURL}notifikasi/$idNotifikasi'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error menghapus notifikasi: $e');
      return false;
    }
  }
}
