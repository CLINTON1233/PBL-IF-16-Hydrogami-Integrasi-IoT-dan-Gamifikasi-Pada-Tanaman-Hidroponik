import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_progres_page.dart';
import 'package:application_hydrogami/pages/gamifikasi/leaderboard_page.dart';
import 'package:application_hydrogami/pages/gamifikasi/reward_page.dart';
import 'package:flutter/material.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_hydrogami/services/gamifikasi_services.dart';
import 'package:application_hydrogami/services/reward_services.dart';
import 'package:application_hydrogami/services/auto_mission_service.dart';
import 'dart:convert';

class GamifikasiPage extends StatefulWidget {
  const GamifikasiPage({super.key});

  @override
  State<GamifikasiPage> createState() => _GamifikasiPageState();
}

class _GamifikasiPageState extends State<GamifikasiPage>
    with TickerProviderStateMixin {
  int _bottomNavCurrentIndex = 1;

  // Power levels for each pump (0-100)
  Map<String, double> pumpPower = {
    "A MIX": 50.0,
    "B MIX": 50.0,
    "PH UP": 50.0,
    "PH DOWN": 50.0,
  };

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // User data variables
  String _userId = '';
  int _userCoins = 0;
  int _userExp = 0;
  int _currentLevel = 1;

  // Services
  late GamificationService _gamificationService;
  late RewardService _rewardService;

  // Active control for animation
  String? _activeControl;

  // ✅ VARIABLE BARU: Tracking untuk misi otomatis
  final Map<String, bool> _missionCompletionInProgress = {
    'pH': false,
    'TDS': false,
  };

  // Peta untuk warna aktif setiap kontrol
  final Map<String, Color> activeColors = {
    "A MIX": const Color(0xFF50B7F2),
    "B MIX": const Color(0xFF2AD5B6),
    "PH UP": const Color(0xFFFBBB00),
    "PH DOWN": const Color(0xFFFF5252),
  };

  // MQTT Client Configuration
  late MqttServerClient client;
  final String broker = 'broker.hivemq.com';
  final int port = 1883;
  final String clientIdentifier =
      'hydrogami_flutter_client_${DateTime.now().millisecondsSinceEpoch}';
  final String topic = 'gamifikasi/control';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    connectMQTT();
    _loadUserData();
    _loadPumpPower();
  }

  @override
  void dispose() {
    client.disconnect();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> connectMQTT() async {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;

    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      await Future.delayed(const Duration(seconds: 5));
      connectMQTT();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT client connected');
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
      connectMQTT();
    });
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void publishPower(String device, double power) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('MQTT not connected, trying to reconnect...');
      connectMQTT();
      return;
    }

    final builder = MqttClientPayloadBuilder();
    String mqttDeviceName = device.replaceAll(" ", "_");
    String specificTopic = "$topic/$mqttDeviceName/power";
    builder.addString(power.toInt().toString());
    client.publishMessage(specificTopic, MqttQos.atLeastOnce, builder.payload!);
    print('Published to $specificTopic: ${power.toInt()}');
  }

  void _triggerControlAnimation(String controlName) {
    setState(() {
      _activeControl = controlName;
    });

    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    _glowController.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      _glowController.stop();
      _glowController.reset();
      setState(() {
        _activeControl = null;
      });
    });
  }

  // ✅ METHOD BARU: Cek apakah kontrol ini menyelesaikan misi otomatis
  Future<void> _checkMissionCompletion(String controlName) async {
    String? missionParameter;

    try {
      // Tentukan parameter misi berdasarkan kontrol yang ditekan
      if (controlName == "PH UP" || controlName == "PH DOWN") {
        missionParameter = 'pH';
      } else if (controlName == "A MIX" || controlName == "B MIX") {
        missionParameter = 'TDS';
      }

      // Jika kontrol tidak terkait misi, skip
      if (missionParameter == null) return;

      if (!_missionCompletionInProgress[missionParameter]!) {
        _missionCompletionInProgress[missionParameter] = true;

        // Cek apakah ada misi aktif untuk parameter ini
        final activeMission =
            await AutoMissionService.getActiveMission(missionParameter);

        if (activeMission != null && activeMission['id'] != null) {
          // Tandai misi sebagai selesai
          bool success =
              await AutoMissionService.completeMission(activeMission['id']);

          if (success) {
            _showCustomSnackBar(
                context,
                'Misi ${activeMission['nama_misi']} selesai! +50 EXP',
                Colors.green);

            // Update user data setelah dapat EXP
            await _loadUserData();

            print('✅ Mission completed via control: $controlName');
          }
        }

        _missionCompletionInProgress[missionParameter] = false;
      }
    } catch (e) {
      print('❌ Error checking mission completion: $e');
      // Reset state jika error
      if (missionParameter != null) {
        _missionCompletionInProgress[missionParameter] = false;
      }
    }
  }

  // ✅ UPDATE METHOD: Tambah mission completion check
  void _handlePowerChange(String controlName, double newPower) {
    setState(() {
      pumpPower[controlName] = newPower;
    });

    publishPower(controlName, newPower);
    _savePumpPower();
    _triggerControlAnimation(controlName);

    // ✅ CEK APAKAH INI MENYELESAIKAN MISI OTOMATIS
    if (newPower > 0) {
      // Hanya jika pompa diaktifkan (bukan dimatikan)
      _checkMissionCompletion(controlName);
    }
  }

  Future<void> _handleRefresh() async {
    try {
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        await connectMQTT();
      }

      await _loadUserData();
      _showCustomSnackBar(context, 'Data berhasil diperbarui',
          const Color.fromARGB(255, 8, 143, 78));
    } catch (e) {
      _showCustomSnackBar(context, 'Gagal memperbarui data', Colors.red);
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _rewardService = RewardService(token);
    _gamificationService = GamificationService(token);

    try {
      setState(() {
        _userId = prefs.getString('current_user_id') ?? '';
        _userCoins = prefs.getInt('${_userId}_total_coins') ?? 0;
        _userExp = prefs.getInt('${_userId}_current_exp') ?? 0;
        _currentLevel = prefs.getInt('${_userId}_current_level') ?? 1;
      });

      try {
        final gamificationData = await _gamificationService.getGamification();
        setState(() {
          _userCoins = gamificationData.coin;
          _userExp = gamificationData.poin;
          _currentLevel = gamificationData.level;
        });
      } catch (e) {
        print('Using local data: $e');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _savePumpPower() async {
    final prefs = await SharedPreferences.getInstance();
    final powerStates =
        pumpPower.map((key, value) => MapEntry(key, value.toString()));
    await prefs.setString('pump_power', jsonEncode(powerStates));
  }

  Future<void> _loadPumpPower() async {
    final prefs = await SharedPreferences.getInstance();
    final powerStatesString = prefs.getString('pump_power');

    if (powerStatesString != null) {
      final powerStates =
          Map<String, String>.from(jsonDecode(powerStatesString));
      setState(() {
        pumpPower =
            powerStates.map((key, value) => MapEntry(key, double.parse(value)));
      });
    }
  }

  // Custom SnackBar function like in profil_page.dart
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 8, 143, 78),
                const Color.fromARGB(255, 8, 143, 78)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Kontrol Pompa',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            // Navigate to BerandaPage instead of popping
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color.fromARGB(255, 8, 143, 78),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section - Plain white
              Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 16, 16, 16), // Reduced bottom padding
                  child: Column(
                    children: [
                      // Level, Reward and Leaderboard
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLevelWidget(level: _currentLevel),
                          _buildRewardWidget(coins: _userCoins),
                          _buildLeaderboardWidget(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Main Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mascot Button for Mission/Progress
                    _buildMascotButton(),

                    const SizedBox(height: 16), // Reduced spacing

                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 8, 143, 78)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: const Color.fromARGB(255, 8, 143, 78),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Kontrol Kekuatan Pompa',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Text(
                        'Atur kekuatan setiap pompa sesuai kebutuhan',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16), // Reduced spacing

                    // Enhanced Control Buttons Section
                    _buildEnhancedControlButtons(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildMascotButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GamifikasiProgresPage(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color.fromARGB(255, 8, 143, 78).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mascot Image - No animation
            Container(
              width: 60, // Slightly smaller
              height: 60, // Slightly smaller
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color.fromARGB(255, 8, 143, 78),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(6), // Reduced padding
                child: Image.asset(
                  'assets/maskot_head.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12), // Reduced spacing
            // Text and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Misi & Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 16, // Slightly smaller
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6), // Reduced spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, // Reduced padding
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius:
                              BorderRadius.circular(6), // Smaller radius
                        ),
                        child: Text(
                          'NEW',
                          style: GoogleFonts.poppins(
                            fontSize: 9, // Smaller font
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2), // Reduced spacing
                  Text(
                    'Lihat misi otomatis & manual, raih poin EXP!',
                    style: GoogleFonts.poppins(
                      fontSize: 12, // Slightly smaller
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Container(
              padding: const EdgeInsets.all(6), // Reduced padding
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 8, 143, 78).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8), // Smaller radius
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color.fromARGB(255, 8, 143, 78),
                size: 18, // Smaller icon
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...pumpPower.keys.map((controlName) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12), // Reduced spacing
            child: _buildPumpControlCard(controlName),
          );
        }).toList(),
      ],
    );
  }

  final Map<String, IconData> controlIcons = {
    "A MIX": Icons.opacity,
    "B MIX": Icons.water_drop,
    "PH UP": Icons.arrow_circle_up,
    "PH DOWN": Icons.arrow_circle_down,
  };

  Widget _buildPumpControlCard(String controlName) {
    double power = pumpPower[controlName]!;
    Color color = activeColors[controlName]!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16), // Reduced padding
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12), // Smaller radius
                  ),
                  child: Icon(
                    controlIcons[controlName],
                    color: color,
                    size: 24, // Smaller icon
                  ),
                ),
                const SizedBox(width: 12), // Reduced spacing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controlName,
                        style: GoogleFonts.poppins(
                          fontSize: 16, // Slightly smaller
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        power == 0 ? 'Pompa mati' : 'Pompa aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: power == 0
                              ? Colors.redAccent
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, // Reduced padding
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10), // Smaller radius
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 14, // Smaller icon
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${power.toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 14, // Slightly smaller
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Power slider section
          Container(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 16), // Reduced padding
            decoration: BoxDecoration(
              color: color.withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: color,
                    inactiveTrackColor: color.withOpacity(0.2),
                    thumbColor: color,
                    overlayColor: color.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 11,
                      elevation: 3,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 22,
                    ),
                  ),
                  child: Slider(
                    value: power,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (value) {
                      _handlePowerChange(controlName, value);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rendah',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Sedang',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Tinggi',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelWidget({required int level}) {
    return InkWell(
      onTap: () {
        _showCustomSnackBar(context, 'Anda telah mencapai Level $level!',
            const Color.fromARGB(255, 8, 143, 78));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 8, 143, 78),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              'Level $level',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardWidget({required int coins}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RewardPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              'Koin: $coins',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardWidget() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LeaderboardPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.leaderboard, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              'Leaderboard',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
