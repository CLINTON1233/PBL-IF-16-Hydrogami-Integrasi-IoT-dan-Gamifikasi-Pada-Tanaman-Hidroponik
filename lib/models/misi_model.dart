class Misi {
  final int idMisi;
  final int idAdmin;
  final String namaMisi;
  final String deskripsiMisi;
  String statusMisi;
  String tipeMisi;
  final int poin;

  Misi({
    required this.idMisi,
    required this.idAdmin,
    required this.namaMisi,
    required this.deskripsiMisi,
    required this.statusMisi,
    required this.tipeMisi,
    required this.poin,
  });

  factory Misi.fromJson(Map<String, dynamic> json) {
    // Debug print untuk melihat data yang diterima
print('Misi JSON data: $json');
    
    return Misi(
      idMisi: _parseToInt(json['id_misi']),
      idAdmin: _parseToInt(json['id_admin']),
      namaMisi: json['nama_misi']?.toString() ?? '',
      deskripsiMisi: json['deskripsi_misi']?.toString() ?? '',
      statusMisi: json['status_misi']?.toString() ?? 'pending',
      tipeMisi: json ['tipe_misi']?.toString() ?? 'harian',
      poin: _parseToInt(json['poin']),
    );
  }

  // Helper method untuk parsing int dengan null safety
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id_misi': idMisi,
      'id_admin': idAdmin,
      'nama_misi': namaMisi,
      'deskripsi_misi': deskripsiMisi,
      'status_misi': statusMisi,
      'tipe_misi' : tipeMisi,
      'poin': poin,
    };
  }

  @override
  String toString() {
 
   return 'Misi{idMisi: $idMisi, idAdmin: $idAdmin, namaMisi: $namaMisi, deskripsiMisi: $deskripsiMisi, statusMisi: $statusMisi, tipeMisi:$tipeMisi, poin: $poin}';
  }
}