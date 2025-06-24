import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/leaderboard_model.dart';

class LeaderboardService {
  final String baseUrl;
  final String? token; 

  LeaderboardService({
    required this.baseUrl,
    this.token,
  });

  Future<List<LeaderboardUser>> getLeaderboard() async {
    final headers = {
      'Accept': 'application/json',
    };

    // Add authorization if token exists
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/leaderboard'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((userJson) => LeaderboardUser.fromJson(userJson)).toList();
    } else {
      throw Exception('Failed to load leaderboard: ${response.statusCode} - ${response.body}');
    }
  }
}