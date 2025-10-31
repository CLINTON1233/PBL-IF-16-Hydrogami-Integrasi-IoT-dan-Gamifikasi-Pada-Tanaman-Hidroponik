import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ================================================
// AUTO MISSION TEST PAGE
// ================================================
class AutoMissionTestPage extends StatefulWidget {
  const AutoMissionTestPage({Key? key}) : super(key: key);

  @override
  State<AutoMissionTestPage> createState() => _AutoMissionTestPageState();
}

class _AutoMissionTestPageState extends State<AutoMissionTestPage> {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  bool _isLoading = false;
  String _statusMessage = '';
  Color _statusColor = Colors.blue;
  String? _token;
  List<Map<String, dynamic>> _missions = [];
  
  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
    
    if (_token != null) {
      _showMessage('✅ Token loaded', Colors.green);
      _loadAllMissions();
    } else {
      _showMessage('⚠️ No token found. Please login first.', Colors.orange);
    }
  }

  void _showMessage(String message, Color color) {
    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });
  }

  // ================================================
  // 1. TEST CONNECTION
  // ================================================
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    _showMessage('Testing connection...', Colors.blue);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showMessage('✅ Connected: ${data['message']}', Colors.green);
      } else {
        _showMessage('❌ Connection failed: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================
  // 2. CREATE AUTO MISSION
  // ================================================
  Future<void> _createAutoMission(String type) async {
    if (_token == null) {
      _showMessage('❌ Please login first', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _showMessage('Creating $type mission...', Colors.blue);

    Map<String, dynamic> missionData;

    switch (type) {
      case 'pH':
        missionData = {
          'nama_misi': 'Stabilkan pH Air',
          'deskripsi_misi': 'Jaga pH air tetap di range ideal 5.5-6.5',
          'poin': 50,
          'parameter_type': 'pH',
          'target_value': 6.0,
          'trigger_condition': 'range',
          'trigger_min_value': 5.5,
          'trigger_max_value': 6.5,
        };
        break;
      case 'TDS':
        missionData = {
          'nama_misi': 'Kurangi TDS Air',
          'deskripsi_misi': 'Turunkan TDS di bawah 800 ppm',
          'poin': 30,
          'parameter_type': 'TDS',
          'target_value': 800,
          'trigger_condition': 'below',
          'trigger_min_value': null,
          'trigger_max_value': null,
        };
        break;
      case 'temperature':
        missionData = {
          'nama_misi': 'Jaga Suhu Optimal',
          'deskripsi_misi': 'Pertahankan suhu di atas 25°C',
          'poin': 40,
          'parameter_type': 'temperature',
          'target_value': 25,
          'trigger_condition': 'above',
          'trigger_min_value': null,
          'trigger_max_value': null,
        };
        break;
      case 'humidity':
        missionData = {
          'nama_misi': 'Kontrol Kelembaban',
          'deskripsi_misi': 'Jaga kelembaban 60-80%',
          'poin': 35,
          'parameter_type': 'humidity',
          'target_value': 70,
          'trigger_condition': 'range',
          'trigger_min_value': 60,
          'trigger_max_value': 80,
        };
        break;
      default:
        _showMessage('❌ Invalid mission type', Colors.red);
        setState(() => _isLoading = false);
        return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/misi/auto'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(missionData),
      ).timeout(const Duration(seconds: 10));

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _showMessage('✅ $type mission created!', Colors.green);
        _loadAllMissions(); // Refresh list
      } else if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        _showMessage('⚠️ ${data['message']}', Colors.orange);
      } else {
        _showMessage('❌ Failed: ${response.body}', Colors.red);
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================
  // 3. GET ALL MISSIONS
  // ================================================
  Future<void> _loadAllMissions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/misi'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Get Missions Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _missions = List<Map<String, dynamic>>.from(data['data']);
        });
        _showMessage('✅ Loaded ${_missions.length} missions', Colors.green);
      }
    } catch (e) {
      print('Error loading missions: $e');
    }
  }

  // ================================================
  // 4. GET ACTIVE MISSION
  // ================================================
  Future<void> _getActiveMission(String parameter) async {
    if (_token == null) {
      _showMessage('❌ Please login first', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _showMessage('Checking active $parameter mission...', Colors.blue);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/misi/active?parameter=$parameter'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Active Mission Status: ${response.statusCode}');
      print('Active Mission Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final mission = data['data'];
          _showMessage(
            '✅ Found: ${mission['nama_misi']}\nTarget: ${mission['target_value']}',
            Colors.green,
          );
        } else {
          _showMessage('⚠️ No active $parameter mission', Colors.orange);
        }
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================
  // 5. COMPLETE MISSION
  // ================================================
  Future<void> _completeMission(int missionId) async {
    if (_token == null) {
      _showMessage('❌ Please login first', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _showMessage('Completing mission $missionId...', Colors.blue);

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/user/misi/$missionId/complete'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Complete Status: ${response.statusCode}');
      print('Complete Body: ${response.body}');

      if (response.statusCode == 200) {
        _showMessage('✅ Mission completed!', Colors.green);
        _loadAllMissions(); // Refresh list
      } else {
        _showMessage('❌ Failed: ${response.body}', Colors.red);
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================================================
  // 6. CLEANUP OLD MISSIONS
  // ================================================
  Future<void> _cleanupMissions() async {
    if (_token == null) {
      _showMessage('❌ Please login first', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    _showMessage('Cleaning up old missions...', Colors.blue);

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/misi/auto/cleanup'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Cleanup Status: ${response.statusCode}');
      print('Cleanup Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showMessage('✅ Cleaned: ${data['data']['total']} missions', Colors.green);
        _loadAllMissions(); // Refresh list
      }
    } catch (e) {
      _showMessage('❌ Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Auto Mission Tester',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF24D17E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllMissions,
            tooltip: 'Refresh Missions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Message
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _statusColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(_statusColor == Colors.green 
                      ? Icons.check_circle 
                      : _statusColor == Colors.red
                          ? Icons.error
                          : Icons.info,
                    color: _statusColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: GoogleFonts.poppins(
                        color: _statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF24D17E),
              backgroundColor: Colors.white,
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Token Info
                  _buildSection(
                    title: 'Token Status',
                    icon: Icons.vpn_key,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _token != null ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _token != null 
                            ? '✅ Token: ${_token!.substring(0, 20)}...'
                            : '❌ No token. Please login.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Connection Test
                  _buildSection(
                    title: '1. Connection Test',
                    icon: Icons.wifi,
                    child: _buildButton(
                      label: 'Test API Connection',
                      icon: Icons.wifi,
                      color: Colors.blue,
                      onPressed: _testConnection,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Create Missions
                  _buildSection(
                    title: '2. Create Auto Missions',
                    icon: Icons.add_circle,
                    child: Column(
                      children: [
                        _buildButton(
                          label: 'Create pH Mission',
                          icon: Icons.water_drop,
                          color: const Color(0xFF24D17E),
                          onPressed: () => _createAutoMission('pH'),
                        ),
                        const SizedBox(height: 8),
                        _buildButton(
                          label: 'Create TDS Mission',
                          icon: Icons.science,
                          color: const Color(0xFF24D17E),
                          onPressed: () => _createAutoMission('TDS'),
                        ),
                        const SizedBox(height: 8),
                        _buildButton(
                          label: 'Create Temperature Mission',
                          icon: Icons.thermostat,
                          color: const Color(0xFF24D17E),
                          onPressed: () => _createAutoMission('temperature'),
                        ),
                        const SizedBox(height: 8),
                        _buildButton(
                          label: 'Create Humidity Mission',
                          icon: Icons.water,
                          color: const Color(0xFF24D17E),
                          onPressed: () => _createAutoMission('humidity'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Check Active Missions
                  _buildSection(
                    title: '3. Check Active Missions',
                    icon: Icons.search,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSmallButton('pH', () => _getActiveMission('pH')),
                        _buildSmallButton('TDS', () => _getActiveMission('TDS')),
                        _buildSmallButton('Temp', () => _getActiveMission('temperature')),
                        _buildSmallButton('Humidity', () => _getActiveMission('humidity')),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cleanup
                  _buildSection(
                    title: '4. Maintenance',
                    icon: Icons.cleaning_services,
                    child: _buildButton(
                      label: 'Cleanup Old Missions',
                      icon: Icons.delete_sweep,
                      color: Colors.red,
                      onPressed: _cleanupMissions,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Mission List
                  _buildSection(
                    title: '5. All Missions (${_missions.length})',
                    icon: Icons.list,
                    child: _missions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No missions yet. Create some!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _missions.length,
                            itemBuilder: (context, index) {
                              final mission = _missions[index];
                              final isAuto = mission['is_auto_generated'] == true;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    isAuto ? Icons.auto_awesome : Icons.person,
                                    color: isAuto ? Colors.blue : Colors.grey,
                                  ),
                                  title: Text(
                                    mission['nama_misi'] ?? 'Unknown',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mission['deskripsi_misi'] ?? '',
                                        style: GoogleFonts.poppins(fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isAuto 
                                                  ? Colors.blue.withOpacity(0.2)
                                                  : Colors.grey.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isAuto ? 'AUTO' : 'MANUAL',
                                              style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isAuto ? Colors.blue : Colors.grey,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${mission['poin']} pts',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.orange,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: mission['status_misi'] != 'selesai'
                                      ? IconButton(
                                          icon: const Icon(Icons.check_circle_outline),
                                          color: const Color(0xFF24D17E),
                                          onPressed: () => _completeMission(
                                              mission['id_misi']),
                                        )
                                      : const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF24D17E)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSmallButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12),
      ),
    );
  }
}