// reward_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/reward_model.dart';

class RewardService {
  final String token;
  static const String baseUrl = 'https://admin-hydrogami.up.railway.app/api'; // Ganti dengan URL API Anda

  RewardService(this.token);

  Future<List<Reward>> getGachaRewards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/gacha'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Reward.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load gacha rewards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load gacha rewards: $e');
    }
  }

  Future<List<Reward>> getRedeemRewards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rewards/redeem'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Reward.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load redeem rewards: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load redeem rewards: $e');
    }
  }
}