class Notification {
  final int idNotifikasi;
  final int? idSensor;
  final String? jenisSensor;
  final String? pesan;
  final String? status;
  final int dibaca;
  final DateTime waktuDibuat;

  Notification({
    required this.idNotifikasi,
    this.idSensor,
    this.jenisSensor,
    this.pesan,
    this.status,
    required this.dibaca,
    required this.waktuDibuat,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
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
