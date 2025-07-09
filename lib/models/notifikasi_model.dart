import 'dart:convert';

class NotifikasiModel {
  final String id;
  final int? idSensor;
  final String? jenisSensor;
  final String pesan;
  final String status;
  final bool dibaca;
  final DateTime waktuDibuat;

  NotifikasiModel({
    required this.id,
    this.idSensor,
    this.jenisSensor,
    required this.pesan,
    required this.status,
    required this.dibaca,
    required this.waktuDibuat,
  });

  factory NotifikasiModel.fromJson(Map<String, dynamic> json) {
    // Deteksi apakah data masih string → jika ya, decode dulu
    final dynamic rawData = json['data'];
    final Map<String, dynamic> dataParsed =
        rawData is String ? jsonDecode(rawData) : rawData;

    return NotifikasiModel(
      id: json['id']?.toString() ?? '',
      idSensor: dataParsed['id_sensor'] != null
          ? int.tryParse(dataParsed['id_sensor'].toString())
          : null,
      jenisSensor: json['type']?.toString(),
      pesan: dataParsed['message'] ?? 'No message',
      status: dataParsed['status'] ?? 'info',
      dibaca: json['read_at'] != null,
      waktuDibuat: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_sensor': idSensor,
        'jenis_sensor': jenisSensor,
        'pesan': pesan,
        'status': status,
        'read_at': dibaca ? DateTime.now().toIso8601String() : null,
        'created_at': waktuDibuat.toIso8601String(),
      };
}