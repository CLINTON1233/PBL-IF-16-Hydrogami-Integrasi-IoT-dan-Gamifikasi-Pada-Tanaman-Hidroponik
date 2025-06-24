class LeaderboardUser {
  final int id;
  final String username;
  final int poin;
  final int coin;
  final int level;
  final DateTime createdAt;

  LeaderboardUser({
    required this.id,
    required this.username,
    required this.poin,
    required this.coin,
    required this.level,
    required this.createdAt,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      id: json['id'],
      username: json['username'],
      poin: json['poin'],
      coin: json['coin'],
      level: json['level'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
