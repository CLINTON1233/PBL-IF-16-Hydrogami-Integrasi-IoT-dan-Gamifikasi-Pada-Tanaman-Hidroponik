class Reward {
  final String id;
  final String type;
  final String? subtype;
  final int? amount;
  final int? koinDibutuhkan; // Tambahkan ini
  final String? label;
  final String? color;

  Reward({
    required this.id,
    required this.type,
    this.subtype,
    this.amount,
    this.koinDibutuhkan, // Tambahkan ini
    this.label,
    this.color,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'].toString(),
      type: json['type'],
      subtype: json['subtype'],
      amount: json['amount'],
      koinDibutuhkan: json['koin_dibutuhkan'], // Tambahkan ini
      label: json['label'],
      color: json['color'],
    );
  }
}