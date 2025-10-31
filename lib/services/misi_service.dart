import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/misi_model.dart';

class MisiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/user';

  // Method untuk mendapatkan headers
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<List<Misi>> getAllMisi() async {
    try {
      print('Fetching missions from: $baseUrl/misi');
      
      final response = await http.get(
        Uri.parse('$baseUrl/misi'),
        headers: await _getHeaders(),
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
        headers: await _getHeaders(),
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

  // ✅ NEW: Method untuk menyelesaikan misi
  Future<bool> completeMission(int missionId) async {
    try {
      print('Completing mission ID: $missionId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/misi/$missionId/complete'),
        headers: await _getHeaders(),
      );

      print('Complete mission response status: ${response.statusCode}');
      print('Complete mission response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else if (response.statusCode == 404) {
        print('Mission not found: $missionId');
        return false;
      } else {
        print('Failed to complete mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error completing mission: $e');
      return false;
    }
  }

  // ✅ NEW: Method untuk cleanup misi expired
  Future<bool> cleanupExpiredMissions() async {
    try {
      print('Cleaning up expired missions...');
      
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/api/admin/misi/auto/cleanup'),
        headers: await _getHeaders(),
      );

      print('Cleanup response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Cleanup result: ${result['message']}');
        return result['success'] == true;
      } else {
        print('Cleanup failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error cleaning up missions: $e');
      return false;
    }
  }

  // ✅ NEW: Method untuk mendapatkan misi aktif berdasarkan parameter
  Future<Misi?> getActiveMissionByParameter(String parameter) async {
    try {
      print('Fetching active mission for parameter: $parameter');
      
      final response = await http.get(
        Uri.parse('$baseUrl/misi/active?parameter=$parameter'),
        headers: await _getHeaders(),
      );

      print('Active mission response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Misi.fromJson(data['data']);
        }
        return null;
      } else {
        print('Failed to get active mission: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting active mission: $e');
      return null;
    }
  }

  // ✅ NEW: Method untuk membuat misi otomatis (untuk testing)
  Future<bool> createAutoMission(Map<String, dynamic> missionData) async {
    try {
      print('Creating auto mission: $missionData');
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/admin/misi/auto'),
        headers: await _getHeaders(),
        body: json.encode(missionData),
      );

      print('Create auto mission response status: ${response.statusCode}');
      print('Create auto mission response body: ${response.body}');

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return result['success'] == true;
      } else {
        print('Failed to create auto mission: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error creating auto mission: $e');
      return false;
    }
  }

  // Method tambahan untuk testing koneksi
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/misi'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}