import 'dart:convert';
import 'package:application_hydrogami/services/globals.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthServices {
  //Register
  static Future<http.Response> register(
      String username, String email, String password, int poin) async {
    Map data = {
      "username": username,
      "email": email,
      "password": password,
      "poin": poin,
    };
    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'auth/register');

    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );
    print(response.body);
    return response;
  }

//Login

  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      return true;
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  static Future<http.Response> login(String email, String password) async {
    Map data = {
      "email": email,
      "password": password,
    };
    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'auth/login');

    http.Response response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      // Parse response dan simpan token
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['token'] != null) {
        await saveToken(jsonResponse['token']);
      }
    }
    return response;
  }

  static Future<http.Response> updateProfile(String token,
      {String? username,
      String? email,
      String? currentPassword,
      String? password}) async {
    Map<String, dynamic> data = {};

    // Hanya tambahkan field yang akan diupdate
    if (username != null) data["username"] = username;
    if (email != null) data["email"] = email;

    if (password != null && password.isNotEmpty) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception('Current password is required to update password');
      }
      data["current_password"] = currentPassword;
      data["password"] = password;
    }

    var body = json.encode(data);
    var url = Uri.parse(baseURL + 'update-profile');

    try {
      http.Response response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      return response;
    } catch (e) {
      print('Error in updateProfile: $e');
      throw e;
    }
  }
}
