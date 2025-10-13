import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/misi_model.dart';

class MisiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/user';

  Future<List<Misi>> getAllMisi() async {
    try {
      print('Fetching missions from: $baseUrl/misi');
      
      final response = await http.get(
        Uri.parse('$baseUrl/misi'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Periksa struktur response
        if (!data.containsKey('data')) {
          throw Exception('Response tidak memiliki field data');
        }
        
        List<dynamic> results = data['data'];
        print('Found ${results.length} missions');
        
        List<Misi> misiList = [];
        
        for (int i = 0; i < results.length; i++) {
          try {
            print('Processing mission $i: ${results[i]}');
            final misi = Misi.fromJson(results[i]);
            misiList.add(misi);
            print('Successfully created mission: ${misi.toString()}');
          } catch (e) {
            print('Error parsing mission at index $i: $e');
            print('Mission data: ${results[i]}');
            // Skip mission yang error, lanjutkan dengan yang lain
            continue;
          }
        }
        
        print('Successfully loaded ${misiList.length} missions');
        return misiList;
        
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error body: ${response.body}');
        throw Exception('Failed to load missions: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getAllMisi: $e');
      throw Exception('Failed to load missions: $e');
    }
  }

  Future<Misi> getMisiDetail(int idMisi) async {
    try {
      print('Fetching mission detail for ID: $idMisi');
      
      final response = await http.get(
        Uri.parse('$baseUrl/misi/$idMisi'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      print('Detail response status: ${response.statusCode}');
      print('Detail response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!data.containsKey('data')) {
          throw Exception('Response tidak memiliki field data');
        }
        
        return Misi.fromJson(data['data']);
      } else {
        throw Exception('Failed to load mission details: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in getMisiDetail: $e');
      throw Exception('Failed to load mission details: $e');
    }
  }

  // Method tambahan untuk testing koneksi
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/misi'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}