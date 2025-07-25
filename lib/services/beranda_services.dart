import 'dart:convert';
import 'package:http/http.dart' as http;

class BerandaServices {
  static Future<String> getUserDetails(String token) async {
    final url = Uri.parse('https://admin-hydrogami.up.railway.app/api/user');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['username']; // Asumsi API mengembalikan field 'username'
    } else {
      throw Exception('Failed to fetch user details');
    }
  }
}
