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
}
