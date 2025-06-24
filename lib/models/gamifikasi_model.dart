class GamificationModel {
  final int poin;
  final int coin;
  final int level;

  GamificationModel({
    required this.poin,
    required this.coin,
    required this.level,
  });

  factory GamificationModel.fromJson(Map<String, dynamic> json) {
    return GamificationModel(
      poin: json['poin'],
      coin: json['coin'],
      level: json['level'],
    );
  }

  GamificationModel copyWith({
    int? poin,
    int? coin,
    int? level,
  }) {
    return GamificationModel(
      poin: poin ?? this.poin,
      coin: coin ?? this.coin,
      level: level ?? this.level,
    );
  }
}