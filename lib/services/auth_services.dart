import 'dart:convert';

import 'package:application_hydrogami/services/globals.dart';
import 'package:http/http.dart' as http;

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
    print(response.body);
    return response;
  }
}
