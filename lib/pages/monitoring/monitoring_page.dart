import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:application_hydrogami/services/notifikasi_services.dart';
import 'package:application_hydrogami/services/sensor_data_service.dart';
import 'package:application_hydrogami/services/auto_mission_service.dart';
import 'package:application_hydrogami/models/sensor_data_model.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

// Class untuk manage state misi
class _MissionState {
  final String parameter;
  bool isActive = false;
  DateTime? lastCreated;
  DateTime? lastChecked;

  _MissionState(this.parameter);
}

class _MonitoringPageState extends State<MonitoringPage> {
  int _bottomNavCurrentIndex = 0;
  DateTime? _lastAlertTime;
  final SensorDataService _sensorDataService = SensorDataService();

  // Sensor data variables
  double currentTDS = 0.0;
  double currentPH = 0.0;
  double currentTemp = 0.0;
  double currentHumidity = 0.0;
  double currentLight = 0.0;
  int currentSoilMoisture = 0;

  // MQTT Client Configuration
  late MqttServerClient client;
  final String broker = 'broker.hivemq.com';
  final int port = 1883;
  final String clientIdentifier =
      'hydrogami_flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  final String topic = 'hydrogami/sensor/data';
  
  // Penambahan untuk Indeks Pertumbuhan
  double growthIndex = 0.0;
  String growthStatus = 'Memuat Data...';

  static const Map<String, double> sensorWeights = {
    'pH': 0.25,
    'TDS': 0.25,
    'Temp': 0.20,
    'Light': 0.20,
    'HumidAir': 0.05,
    'HumidSoil': 0.05,
  };

  // Data untuk grafik
  List<FlSpot> chartDataTDS = [];
  List<FlSpot> chartDataPH = [];
  List<FlSpot> chartDataTemp = [];
  List<FlSpot> chartDataHumidity = [];

  int timeCounter = 0;
  final int maxDataPoints = 10;

  // Sistem notifikasi baru
  final List<Map<String, dynamic>> _notifications = [];

  // ✅ SISTEM MISI OTOMATIS BARU - DIPERBAIKI
  final Map<String, _MissionState> _missionStates = {
    'pH': _MissionState('pH'),
    'TDS': _MissionState('TDS'),
  };
  final Duration _missionCheckInterval = Duration(minutes: 5);
  final Duration _missionCooldown = Duration(hours: 6);
  DateTime _lastMissionCheck = DateTime.now().subtract(Duration(minutes: 5));
  DateTime _lastCompletionCheck = DateTime.now().subtract(Duration(minutes: 1));

  @override
  void initState() {
    super.initState();
    // Inisialisasi chart kosong
    for (int i = 0; i < maxDataPoints; i++) {
      chartDataTDS.add(FlSpot(i.toDouble(), 0));
      chartDataPH.add(FlSpot(i.toDouble(), 0));
      chartDataTemp.add(FlSpot(i.toDouble(), 0));
      chartDataHumidity.add(FlSpot(i.toDouble(), 0));
    }
    _loadMissionStates();
    _resetDailyIfNeeded();
    _initMqttClient();
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  // ✅ METHOD: Load mission states dari SharedPreferences
  Future<void> _loadMissionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statesJson = prefs.getString('mission_states');

      if (statesJson != null) {
        final Map<String, dynamic> states =
            Map<String, dynamic>.from(jsonDecode(statesJson));

        for (var entry in states.entries) {
          if (_missionStates.containsKey(entry.key)) {
            final stateData = Map<String, dynamic>.from(entry.value);
            _missionStates[entry.key]!.isActive =
                stateData['isActive'] ?? false;

            if (stateData['lastCreated'] != null) {
              _missionStates[entry.key]!.lastCreated =
                  DateTime.parse(stateData['lastCreated']);
            }

            if (stateData['lastChecked'] != null) {
              _missionStates[entry.key]!.lastChecked =
                  DateTime.parse(stateData['lastChecked']);
            }
          }
        }
      }
    } catch (e) {
      print('Error loading mission states: $e');
    }
  }

  // ✅ METHOD: Save mission states ke SharedPreferences
  Future<void> _saveMissionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statesMap = <String, dynamic>{};

      for (var entry in _missionStates.entries) {
        statesMap[entry.key] = {
          'isActive': entry.value.isActive,
          'lastCreated': entry.value.lastCreated?.toIso8601String(),
          'lastChecked': entry.value.lastChecked?.toIso8601String(),
        };
      }

      await prefs.setString('mission_states', jsonEncode(statesMap));
    } catch (e) {
      print('Error saving mission states: $e');
    }
  }

  // ✅ METHOD: Reset state harian
  Future<void> _resetDailyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastReset = prefs.getString('last_mission_reset');
    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastReset != today) {
      // Reset state misi setiap hari
      for (var missionState in _missionStates.values) {
        missionState.isActive = false;
      }
      await _saveMissionStates();
      await prefs.setString('last_mission_reset', today);

      print('Daily mission state reset completed');
    }
  }

  void _initMqttClient() {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;
    _connectToBroker();
  }

  Future<void> _connectToBroker() async {
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      await Future.delayed(const Duration(seconds: 5));
      _connectToBroker();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      _subscribeToTopic();
    } else {
      print('ERROR: MQTT client connection failed - disconnecting');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    Future.delayed(const Duration(seconds: 3), () {
      _connectToBroker();
    });
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  // ✅ UPDATE: MQTT handler dengan sistem misi otomatis yang diperbaiki
  void _subscribeToTopic() {
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) async {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received MQTT message: $payload');

      try {
        Map<String, dynamic> data = jsonDecode(payload);

        // ✅ UPDATE DATA REAL-TIME
        setState(() {
          currentTDS = data['tds']?.toDouble() ?? 0;
          currentPH = data['ph']?.toDouble() ?? 0;
          currentTemp = data['temperature']?.toDouble() ?? 0;
          currentHumidity = data['humidity']?.toDouble() ?? 0;
          currentLight = data['light']?.toDouble() ?? 0;
          currentSoilMoisture = data['soil_moisture']?.toInt() ?? 0;

          _updateCharts();
          _calculateGrowthIndex();
        });

        // Simpan data sensor ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('current_tds', currentTDS);
        await prefs.setDouble('current_ph', currentPH);

        final sensorData = SensorData(
          temperature: currentTemp,
          humidity: currentHumidity,
          light: currentLight,
          soilMoisture: currentSoilMoisture,
          tds: currentTDS,
          ph: currentPH,
        );

        try {
          final success = await _sensorDataService.sendSensorData(sensorData);
          if (success) {
            print('Data successfully sent to API');
          } else {
            print('Failed to send data to API');
          }
        } catch (apiError) {
          print('API Error: $apiError');
        }

        // ✅ CEK ALERT REAL-TIME
        if (mounted) {
          _checkForAlerts(context);
        }

        // ✅ CEK MISI OTOMATIS DENGAN INTERVAL
        _checkMissionsWithInterval();
      } catch (e) {
        print('Error processing MQTT message: $e');
      }
    });
  }

  // ✅ METHOD: Cek misi dengan interval
  void _checkMissionsWithInterval() {
    final now = DateTime.now();

    // Cek pembuatan misi setiap 5 menit
    if (now.difference(_lastMissionCheck) >= _missionCheckInterval) {
      for (var missionState in _missionStates.values) {
        _evaluateMissionCreation(missionState, now);
        missionState.lastChecked = now;
      }
      _lastMissionCheck = now;
    }

    // Cek penyelesaian misi setiap 1 menit
    if (now.difference(_lastCompletionCheck) >= Duration(minutes: 1)) {
      _checkAutoMissionCompletion();
      _lastCompletionCheck = now;
    }
  }

  // ✅ METHOD: Evaluasi pembuatan misi
  void _evaluateMissionCreation(_MissionState missionState, DateTime now) {
    bool shouldCreateMission = false;
    Map<String, dynamic>? missionData;

    switch (missionState.parameter) {
      case 'pH':
        if ((currentPH < 5.0 || currentPH > 7.0) &&
            !missionState.isActive &&
            (missionState.lastCreated == null ||
                now.difference(missionState.lastCreated!) >=
                    _missionCooldown)) {
          shouldCreateMission = true;
          missionData = _createPHMissionData();
        }
        break;

      case 'TDS':
        if ((currentTDS < 300 || currentTDS > 1500) &&
            !missionState.isActive &&
            (missionState.lastCreated == null ||
                now.difference(missionState.lastCreated!) >=
                    _missionCooldown)) {
          shouldCreateMission = true;
          missionData = _createTDSMissionData();
        }
        break;
    }

    if (shouldCreateMission && missionData != null) {
      _createAutoMission(missionData, missionState, now);
    }
  }

  // ✅ METHOD BARU YANG DIPERBAIKI: Data untuk misi pH dengan field yang benar
  Map<String, dynamic> _createPHMissionData() {
    String status = currentPH < 5.0 ? "terlalu rendah" : "terlalu tinggi";
    String action = currentPH < 5.0 ? "PH UP" : "PH DOWN";

    return {
      'nama_misi': 'Koreksi pH Air', // ✅ DIPERBAIKI: nama -> nama_misi
      'deskripsi_misi': 'Level pH ${currentPH.toStringAsFixed(1)} $status. Sesuaikan menggunakan $action.', // ✅ DIPERBAIKI: deskripsi -> deskripsi_misi
      'poin': 50,
      'parameter_type': 'pH',
      'target_value': 6.0,
      'trigger_condition': currentPH < 5.0 ? 'below' : 'above',
      'trigger_min_value': currentPH < 5.0 ? null : 7.0,
      'trigger_max_value': currentPH < 5.0 ? 5.0 : null,
    };
  }

  // ✅ METHOD BARU YANG DIPERBAIKI: Data untuk misi TDS dengan field yang benar
  Map<String, dynamic> _createTDSMissionData() {
    String status = currentTDS < 300 ? "terlalu rendah" : "terlalu tinggi";
    String action = currentTDS < 300 ? "tambah" : "kurangi";

    return {
      'nama_misi': 'Atur Nutrisi TDS', // ✅ DIPERBAIKI: nama -> nama_misi
      'deskripsi_misi': 'Level TDS ${currentTDS.toStringAsFixed(0)} ppm $status. $action nutrisi A/B Mix.', // ✅ DIPERBAIKI: deskripsi -> deskripsi_misi
      'poin': 50,
      'parameter_type': 'TDS',
      'target_value': 1000.0,
      'trigger_condition': currentTDS < 300 ? 'below' : 'above',
      'trigger_min_value': currentTDS < 300 ? null : 1500,
      'trigger_max_value': currentTDS < 300 ? 300 : null,
    };
  }

  // ✅ METHOD YANG DIPERBAIKI: Pembuatan misi otomatis dengan logging yang lebih baik
  Future<void> _createAutoMission(Map<String, dynamic> missionData,
      _MissionState missionState, DateTime now) async {
    try {
      print('📤 [MISSION] Attempting to create mission with data: $missionData');
      print('📤 [MISSION] Field Check - nama_misi: ${missionData['nama_misi']}');
      print('📤 [MISSION] Field Check - deskripsi_misi: ${missionData['deskripsi_misi']}');
      
      bool success = await AutoMissionService.createAutoMission(missionData);

      if (success) {
        setState(() {
          missionState.isActive = true;
          missionState.lastCreated = now;
        });

        await _saveMissionStates();

        _showMissionSnackBar(context,
            'Misi "${missionData['nama_misi']}" telah dibuat!', Colors.blue);

        print('✅ Auto mission created: ${missionData['nama_misi']}');
      } else {
        print('❌ [MISSION] Failed to create mission. Check field mapping.');
        _showMissionSnackBar(
            context, 'Gagal membuat misi. Periksa data yang dikirim.', Colors.orange);
      }
    } catch (e) {
      print('❌ [MISSION] Error creating auto mission: $e');
      _showMissionSnackBar(context, 'Error membuat misi: $e', Colors.red);
    }
  }

  // ✅ METHOD: Cek penyelesaian misi otomatis
  Future<void> _checkAutoMissionCompletion() async {
    for (var missionState in _missionStates.values) {
      if (missionState.isActive) {
        bool isCompleted = false;

        switch (missionState.parameter) {
          case 'pH':
            // Misi pH selesai jika pH kembali ke range normal
            isCompleted = currentPH >= 5.5 && currentPH <= 6.5;
            break;

          case 'TDS':
            // Misi TDS selesai jika TDS kembali ke range normal
            isCompleted = currentTDS >= 800 && currentTDS <= 1200;
            break;
        }

        if (isCompleted) {
          await _completeAutoMission(missionState);
        }
      }
    }
  }

  // ✅ METHOD: Tandai misi sebagai selesai
  Future<void> _completeAutoMission(_MissionState missionState) async {
    try {
      // Cari misi aktif untuk parameter ini
      final activeMission =
          await AutoMissionService.getActiveMission(missionState.parameter);

      if (activeMission != null && activeMission['id'] != null) {
        bool success =
            await AutoMissionService.completeMission(activeMission['id']);

        if (success) {
          setState(() {
            missionState.isActive = false;
          });

          await _saveMissionStates();

          _showMissionSnackBar(
              context,
              'Misi ${missionState.parameter} berhasil diselesaikan! +50 EXP',
              Colors.green);

          print('✅ Auto mission completed: ${missionState.parameter}');
        }
      } else {
        // Jika tidak ditemukan misi di backend, tetap update state lokal
        setState(() {
          missionState.isActive = false;
        });
        await _saveMissionStates();
        print('ℹ️  Mission state updated locally: ${missionState.parameter}');
      }
    } catch (e) {
      print('❌ Error completing auto mission: $e');
      // Fallback: update state lokal meskipun API error
      setState(() {
        missionState.isActive = false;
      });
      await _saveMissionStates();
    }
  }

  Future<void> _sendDataToApi() async {
    final sensorData = SensorData(
      temperature: currentTemp,
      humidity: currentHumidity,
      light: currentLight,
      soilMoisture: currentSoilMoisture,
      tds: currentTDS,
      ph: currentPH,
    );

    try {
      final success = await _sensorDataService.sendSensorData(sensorData);
      if (success) {
        print('Data berhasil dikirim ke API');
      } else {
        print('Gagal mengirim data ke API');
      }
    } catch (e) {
      print('Error saat mengirim data: $e');
    }
  }

  void _updateCharts() {
    setState(() {
      timeCounter++;

      chartDataTDS[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentTDS);
      chartDataPH[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentPH);
      chartDataTemp[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentTemp);
      chartDataHumidity[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentHumidity);
    });
  }

  // Fungsi perhitungan untuk indeks kualitas pertumbuhan
  double _calculateSensorQuality(String sensorType, double value) {
    // Rentang Optimal (O) dan Kritis (C) untuk pakcoy
    Map<String, List<double>> ranges = {
      'pH': [5.8, 6.5, 5.5, 6.8],
      'TDS': [1000, 1400, 800, 1600],
      'Temp': [20, 25, 16, 30],
      'Light': [15000, 25000, 10000, 30000],
      'HumidAir': [70, 80, 60, 90],
      'HumidSoil': [60, 70, 40, 80],
    };

    if (!ranges.containsKey(sensorType)) return 0.0;

    List<double> r = ranges[sensorType]!;
    double oMin = r[0], oMax = r[1], cMin = r[2], cMax = r[3];

    // Kasus 1: Nilai Optimal (Kualitas 100% atau 1.0)
    if (value >= oMin && value <= oMax) {
      return 1.0;
    }
    // Kasus 2: Nilai Kritis/Di luar (Kualitas 0.0)
    if (value <= cMin || value >= cMax) {
      return 0.0;
    }

    // Kasus 3: Di antara Kritis dan Optimal Bawah (Normalisasi linier naik)
    if (value < oMin) {
      return (value - cMin) / (oMin - cMin);
    }

    // Kasus 4: Di antara Optimal dan Kritis Atas (Normalisasi linier turun)
    if (value > oMax) {
      return (cMax - value) / (cMax - oMax);
    }

    return 0.0;
  }

  void _calculateGrowthIndex() {
    // 1. Dapatkan skor kualitas untuk setiap sensor (0.0 hingga 1.0)
    double qPH = _calculateSensorQuality('pH', currentPH);
    double qTDS = _calculateSensorQuality('TDS', currentTDS);
    double qTemp = _calculateSensorQuality('Temp', currentTemp);
    double qLight = _calculateSensorQuality('Light', currentLight);
    double qHumidAir = _calculateSensorQuality('HumidAir', currentHumidity);
    double qHumidSoil =
        _calculateSensorQuality('HumidSoil', currentSoilMoisture.toDouble());

    // 2. Hitung Indeks Kualitas (Rata-rata Tertimbang)
    double index = (qPH * sensorWeights['pH']!) +
        (qTDS * sensorWeights['TDS']!) +
        (qTemp * sensorWeights['Temp']!) +
        (qLight * sensorWeights['Light']!) +
        (qHumidAir * sensorWeights['HumidAir']!) +
        (qHumidSoil * sensorWeights['HumidSoil']!);

    // 3. Update variabel state
    setState(() {
      growthIndex = index * 100;
      growthStatus = growthIndex >= 70.0 ? 'Sehat' : 'Perlu Perhatian';
    });
  }

  void _checkForAlerts(BuildContext context) {
    final now = DateTime.now();
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!) < const Duration(seconds: 30)) {
      return;
    }

    // Batasi jumlah notifikasi maksimal
    if (_notifications.length >= 3) return;

    if (currentPH < 5.0 || currentPH > 7.0) {
      final message =
          'Nilai pH ${currentPH.toStringAsFixed(1)} di luar range optimal (5.5-6.5)!';
      _showAlert(context, 'Peringatan pH', message, Colors.orange);
      _sendNotification('pH Sensor', message, 'warning');
      _lastAlertTime = now;
    }

    if (currentTDS < 300 || currentTDS > 1500) {
      final message =
          'Nilai TDS ${currentTDS.toStringAsFixed(0)} ppm di luar range optimal (800-1500 ppm)!';
      _showAlert(context, 'Peringatan Nutrisi', message, Colors.orange);
      _sendNotification('TDS Sensor', message, 'warning');
      _lastAlertTime = now;
    }

    if (currentTemp < 15 || currentTemp > 35) {
      final message =
          'Suhu ${currentTemp.toStringAsFixed(1)}°C di luar range optimal (20-30°C)!';
      _showAlert(context, 'Peringatan Suhu', message, Colors.orange);
      _sendNotification('Suhu Sensor', message, 'danger');
      _lastAlertTime = now;
    }
  }

  Future<void> _sendNotification(
      String sensorType, String message, String status) async {
    try {
      final success = await LayananNotifikasi.kirimNotifikasi(
        idSensor: '1',
        jenisSensor: sensorType,
        pesan: message,
        status: status,
      );

      if (success) {
        print('Notifikasi berhasil dikirim');
      } else {
        print('Gagal mengirim notifikasi');
      }
    } catch (e) {
      print('Error mengirim notifikasi: $e');
    }
  }

  void _showAlert(
      BuildContext context, String title, String message, Color color) {
    _showCustomSnackBar(context, message, color);
  }

  // Custom SnackBar function untuk alert biasa
  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ✅ METHOD: Custom SnackBar untuk notifikasi misi (Overlay)
  void _showMissionSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + kToolbarHeight + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 8, 143, 78),
                Color.fromARGB(255, 8, 143, 78)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Monitoring Real-Time',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 20.0,
            bottom: 30.0,
          ),
          children: [
            _buildGrowthCard(),
            const SizedBox(height: 24),
            _buildPHChart(),
            const SizedBox(height: 24),
            _buildMainChart(),
            const SizedBox(height: 24),
            _buildTemperatureHumidityChart(),
            const SizedBox(height: 24),
            _buildSensorCardsGrid(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildGrowthCard() {
    Color statusColor = growthIndex >= 70.0 ? Colors.green : Colors.red;
    String statusText = growthIndex >= 70.0 ? 'Sehat' : 'Perlu Perhatian';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Indeks Kualitas Lingkungan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Icon(
            Icons.eco_rounded,
            size: 40,
            color: Color.fromARGB(255, 8, 143, 78),
          ),
          const SizedBox(height: 8),
          Text(
            '${growthIndex.toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          Text(
            'Kualitas Pertumbuhan Potensial',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Indeks ini dihitung berdasarkan rata-rata tertimbang dari 6 sensor.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPHChart() {
    return _buildChart(
      title: 'Kadar pH',
      currentValue: currentPH,
      unit: 'pH',
      chartData: chartDataPH,
      color: Colors.purple,
      minY: 0,
      maxY: 8,
      interval: 2,
    );
  }

  Widget _buildMainChart() {
    return _buildChart(
      title: 'Kadar TDS',
      currentValue: currentTDS,
      unit: 'ppm',
      chartData: chartDataTDS,
      color: Colors.blue,
      minY: 0,
      maxY: 2000,
      interval: 500,
    );
  }

  Widget _buildTemperatureHumidityChart() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suhu & Kelembaban',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suhu: ${currentTemp.toStringAsFixed(1)}°C | Kelembaban: ${currentHumidity.toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < maxDataPoints &&
                            index % 2 == 0) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              index.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: maxDataPoints.toDouble() - 1,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartDataTemp,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.orange,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: chartDataHumidity,
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.teal,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.teal.withOpacity(0.1),
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

  Widget _buildChart({
    required String title,
    required double currentValue,
    required String unit,
    required List<FlSpot> chartData,
    required Color color,
    required double minY,
    required double maxY,
    required double interval,
  }) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terkini: ${currentValue.toStringAsFixed(1)} $unit',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < maxDataPoints &&
                            index % 2 == 0) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              index.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: maxDataPoints.toDouble() - 1,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
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

  Widget _buildSensorCardsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil Pembacaan Sensor',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildSensorDetailCard(
              title: 'Kadar TDS',
              value: currentTDS.toStringAsFixed(1),
              unit: 'ppm',
              icon: Icons.opacity,
              color: Colors.blue.shade50,
              iconColor: Colors.blue,
              status: determineSensorStatus('TDS', currentTDS),
            ),
            _buildSensorDetailCard(
              title: 'Kadar pH',
              value: currentPH.toStringAsFixed(1),
              unit: 'pH',
              icon: Icons.blur_circular,
              color: Colors.purple.shade50,
              iconColor: Colors.purple,
              status: determineSensorStatus('pH', currentPH),
            ),
            _buildSensorDetailCard(
              title: 'Suhu',
              value: currentTemp.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.orange.shade50,
              iconColor: Colors.orange,
              status: determineSensorStatus('Suhu', currentTemp),
            ),
            _buildSensorDetailCard(
              title: 'Kelembaban Udara',
              value: currentHumidity.toStringAsFixed(1),
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.teal.shade50,
              iconColor: Colors.teal,
              status:
                  determineSensorStatus('Kelembaban Udara', currentHumidity),
            ),
            _buildSensorDetailCard(
              title: 'Kelembaban Tanah',
              value: currentSoilMoisture.toString(),
              unit: '%',
              icon: Icons.landscape,
              color: Colors.brown.shade50,
              iconColor: Colors.brown,
              status: determineSensorStatus(
                  'Kelembaban Tanah', currentSoilMoisture.toDouble()),
            ),
            _buildSensorDetailCard(
              title: 'Intensitas Cahaya',
              value: currentLight.toStringAsFixed(1),
              unit: 'Lux',
              icon: Icons.light_mode,
              color: Colors.amber.shade50,
              iconColor: Colors.amber,
              status: determineSensorStatus('Intensitas Cahaya', currentLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorDetailCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required Color status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unit,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status,
                      border: Border.all(
                        color: Colors.grey[500]!,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Widget
  Widget _buildBottomNavigation() {
    return Container(
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            onTap: (index) {
              setState(() {
                _bottomNavCurrentIndex = index;
              });

              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BerandaPage()),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GamifikasiPage()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PanduanPage()),
                  );
                  break;
                case 3:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilPage()),
                  );
                  break;
              }
            },
            currentIndex: _bottomNavCurrentIndex,
            items: const [
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.home_rounded),
                icon: Icon(Icons.home_outlined),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.tune_rounded),
                icon: Icon(Icons.tune_outlined),
                label: 'Kontrol',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.book_rounded),
                icon: Icon(Icons.book_outlined),
                label: 'Panduan',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.person_rounded),
                icon: Icon(Icons.person_outline_rounded),
                label: 'Akun',
              ),
            ],
            selectedItemColor: const Color.fromARGB(255, 8, 143, 78),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }

  Color determineSensorStatus(String sensorType, double value) {
    switch (sensorType) {
      case 'Suhu':
        if (value < 10 || value > 40) return Colors.red;
        if ((value >= 15 && value < 19) || (value > 30 && value <= 35))
          return Colors.yellow;
        if (value >= 19 && value <= 30) return Colors.green;
        return Colors.black;

      case 'TDS':
        if (value < 300 || value > 2000) return Colors.red;
        if ((value >= 500 && value < 800) || (value > 1500 && value <= 2000))
          return Colors.yellow;
        if (value >= 800 && value <= 1500) return Colors.green;
        return Colors.black;

      case 'pH':
        if (value < 4.0 || value > 7.5) return Colors.red;
        if ((value >= 5.0 && value < 5.5) || (value > 6.5 && value <= 7.0))
          return Colors.yellow;
        if (value >= 5.5 && value <= 6.5) return Colors.green;
        return Colors.black;

      case 'Kelembaban Tanah':
        if (value <= 30 || value > 90) return Colors.red;
        if ((value >= 40 && value < 50) || (value > 80 && value <= 90))
          return Colors.yellow;
        if (value >= 50 && value <= 80) return Colors.green;
        return Colors.black;

      case 'Kelembaban Udara':
        if (value < 30 || value > 90) return Colors.red;
        if ((value >= 40 && value < 60) || (value > 80 && value <= 90))
          return Colors.yellow;
        if (value >= 60 && value <= 80) return Colors.green;
        return Colors.black;

      case 'Intensitas Cahaya':
        if (value < 1000 || value > 50000) return Colors.red;
        if ((value >= 2000 && value < 10000) ||
            (value > 25000 && value <= 40000)) return Colors.yellow;
        if (value >= 10000 && value <= 25000) return Colors.green;
        return Colors.black;

      default:
        return Colors.black;
    }
  }
}