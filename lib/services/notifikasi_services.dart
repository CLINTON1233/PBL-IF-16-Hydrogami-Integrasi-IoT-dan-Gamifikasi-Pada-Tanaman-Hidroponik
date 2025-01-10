import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:application_hydrogami/services/globals.dart';

class NotifikasiModel {
  final int idNotifikasi;
  final int? idSensor;
  final String? jenisSensor;
  final String? pesan;
  final String? status;
  final int dibaca;
  final DateTime waktuDibuat;

  NotifikasiModel({
    required this.idNotifikasi,
    this.idSensor,
    this.jenisSensor,
    this.pesan,
    this.status,
    required this.dibaca,
    required this.waktuDibuat,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    return NotifikasiModel(
      idNotifikasi: json['id_notifikasi'],
      idSensor: json['id_sensor'],
      jenisSensor: json['jenis_sensor'],
      pesan: json['pesan'],
      status: json['status'],
      dibaca: json['dibaca'],
      waktuDibuat: DateTime.parse(json['waktu_dibuat']),
    );
  }
}

class LayananNotifikasi {
  // Mengambil semua notifikasi
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

  // Kirim notifikasi ke backend
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

      if (response.statusCode == 200) {
        final dataResponse = jsonDecode(response.body);
        return dataResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error mengirim notifikasi: $e');
      return false;
    }
  }

  // Menandai notifikasi sebagai dibaca
  static Future<bool> tandaiDibaca(int idNotifikasi) async {
    try {
      final response = await http.put(
        Uri.parse('${baseURL}notifikasi/$idNotifikasi/read'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dataResponse = jsonDecode(response.body);
        return dataResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error menandai notifikasi dibaca: $e');
      return false;
    }
  }

  // Hapus notifikasi
  static Future<bool> hapusNotifikasi(int idNotifikasi) async {
    try {
      final response = await http.delete(
        Uri.parse('${baseURL}notifikasi/$idNotifikasi'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final dataResponse = jsonDecode(response.body);
        return dataResponse['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error menghapus notifikasi: $e');
      return false;
    }
  }
}
