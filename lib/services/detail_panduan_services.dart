import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:application_hydrogami/models/panduan_model.dart';

class DetailPanduanService {
  static Future<Panduan?> fetchPanduanDetail(int idPanduan) async {
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:8000/api/user/panduan/$idPanduan'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return Panduan.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      // Error handling jika terjadi kesalahan
      print('Error: $e');
      return null;
    }
  }
}
