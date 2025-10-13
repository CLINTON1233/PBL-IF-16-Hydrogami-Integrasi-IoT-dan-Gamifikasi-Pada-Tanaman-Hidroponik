import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/gamifikasi_model.dart';

class GamificationService {
  final String baseUrl = 'http://10.0.2.2:8000/api'; 
  final String token;

  GamificationService(this.token);

  Future<GamificationModel> getGamification() async {
    final response = await http.get(
      Uri.parse('$baseUrl/gamification'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return GamificationModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to load gamification data: ${response.statusCode}');
    }
  }

  Future<bool> updateGamification(int poin, int coin, int level) async {
    final response = await http.put(
      Uri.parse('$baseUrl/gamification'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'poin': poin,
        'coin': coin,
        'level': level,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to update gamification: ${response.statusCode}');
    }
  }
}