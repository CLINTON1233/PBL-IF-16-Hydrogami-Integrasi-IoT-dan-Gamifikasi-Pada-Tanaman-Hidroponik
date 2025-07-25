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
import 'dart:convert'; // Add this line

class GamifikasiPage extends StatefulWidget {
  const GamifikasiPage({super.key});

  @override
  State<GamifikasiPage> createState() => _GamifikasiPageState();
}

class _GamifikasiPageState extends State<GamifikasiPage>
    with TickerProviderStateMixin {
  int _bottomNavCurrentIndex = 0;
  bool isAutomaticControl = false;
  Map<String, bool> controls = {
    "A MIX": false,
    "B MIX": false,
    "PH UP": false,
    "PH DOWN": false,
  };

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
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

  // Posisi maskot yang bisa digeser
  Offset _mascotPosition = Offset(0, 0);

  // Peta untuk warna aktif setiap kontrol
  final Map<String, Color> activeColors = {
    "A MIX": const Color(0xFF50B7F2),
    "B MIX": const Color(0xFF2AD5B6),
    "PH UP": const Color(0xFFFBBB00),
    "PH DOWN": Colors.red,
  };

  // MQTT Configuration
  late MqttServerClient client;
  final String broker = 'broker.hivemq.com';
  final int port = 1883;
  final String clientIdentifier =
      'hydrogami_gamifikasi_${DateTime.now().millisecondsSinceEpoch}';
  final String topic = 'gamifikasi/control';

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
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

    connectMQTT(); // MQTT
    _loadUserData(); // Load user data
    _loadRelayStates(); // Add this line
  }

  @override
  void dispose() {
    client.disconnect();
    _pulseController.dispose();
    _rotationController.dispose();
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
      // Coba reconnect setelah 5 detik
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
    // Coba reconnect setelah 3 detik
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

  void publishControl(String device, bool isActive) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      print('MQTT not connected, trying to reconnect...');
      connectMQTT();
      return;
    }

    final builder = MqttClientPayloadBuilder();
    String message = isActive ? "ON" : "OFF";

    // Mapping nama kontrol yang sesuai dengan ESP32
    String mqttDeviceName = device.replaceAll(" ", "_");
    String specificTopic = "$topic/$mqttDeviceName";

    builder.addString(message);
    client.publishMessage(specificTopic, MqttQos.atLeastOnce, builder.payload!);
    print('Published to $specificTopic: $message');

    // Untuk debugging, bisa ditambahkan snackbar
    //if (mounted) {
    // ScaffoldMessenger.of(context).showSnackBar(
    //  SnackBar(
    //    content: Text('Mengirim perintah: $device $message'),
    //    duration: const Duration(seconds: 1),
    //  ),
    // );
    // }
  }

  void _triggerControlAnimation(String controlName) {
    setState(() {
      _activeControl = controlName;
    });

    // Start animations
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    _rotationController.forward().then((_) {
      _rotationController.reset();
    });

    _glowController.repeat(reverse: true);

    // Stop glow after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _glowController.stop();
      _glowController.reset();
      setState(() {
        _activeControl = null;
      });
    });
  }

  // Method untuk menangani perubahan kontrol otomatis
  void _handleAutomaticControlToggle() {
    setState(() {
      isAutomaticControl = !isAutomaticControl;

      if (isAutomaticControl) {
        controls = {
          "A MIX": true,
          "B MIX": true,
          "PH UP": true,
          "PH DOWN": true,
        };
        controls.forEach((key, value) {
          publishControl(key, value);
        });
        _triggerControlAnimation("AUTO_ALL");
      } else {
        controls = {
          "A MIX": false,
          "B MIX": false,
          "PH UP": false,
          "PH DOWN": false,
        };
        controls.forEach((key, value) {
          publishControl(key, value);
        });
      }
    });
    _saveRelayStates(); // Add this line
    publishControl("AUTO", isAutomaticControl);
  }

  // Method untuk menangani kontrol individual
  void _handleIndividualControl(String controlName) {
    if (!isAutomaticControl) {
      setState(() {
        controls[controlName] = !controls[controlName]!;
      });
      publishControl(controlName, controls[controlName]!);
      _saveRelayStates(); // Add this line

      if (controls[controlName]!) {
        _triggerControlAnimation(controlName);
      }
    } else {
      _showCustomSnackBar(
          context, 'Matikan untuk mengontrol manual', Colors.amber);
    }
  }

  Future<void> _handleRefresh() async {
    try {
      // Reconnect MQTT if needed
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        await connectMQTT();
      }

      // Reload user data
      await _loadUserData();

      // Show success message
      _showCustomSnackBar(
          context, 'Data berhasil diperbarui', Colors.green);
    } catch (e) {
      _showCustomSnackBar(context, 'Gagal memperbarui data: $e', Colors.red);

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

      // Try to get fresh data from API
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

  Future<void> _saveRelayStates() async {
    final prefs = await SharedPreferences.getInstance();
    final relayStates =
        controls.map((key, value) => MapEntry(key, value.toString()));
    await prefs.setString('relay_states', jsonEncode(relayStates));
    await prefs.setBool('automatic_control', isAutomaticControl);
  }

  Future<void> _loadRelayStates() async {
    final prefs = await SharedPreferences.getInstance();
    final relayStatesString = prefs.getString('relay_states');
    final automaticControl = prefs.getBool('automatic_control') ?? false;

    if (relayStatesString != null) {
      final relayStates =
          Map<String, String>.from(jsonDecode(relayStatesString));
      setState(() {
        controls =
            relayStates.map((key, value) => MapEntry(key, value == 'true'));
        isAutomaticControl = automaticControl;
      });
    }
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Hitung posisi di bawah AppBar
        top: MediaQuery.of(context).padding.top +
            kToolbarHeight +
            10, // kToolbarHeight adalah tinggi default AppBar
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
                      Icons.info_outline,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'Gamifikasi',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp),
          iconSize: 20.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: const Color(0xFF24D17E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF24D17E).withOpacity(0.1),
                  Colors.white,
                  const Color(0xFF24D17E).withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bagian Level, Reward dan Leaderboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLevelWidget(level: _currentLevel),
                      _buildRewardWidget(coins: _userCoins),
                      _buildLeaderboardWidget(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Enhanced Gamification Graphic with animations
                  _buildEnhancedGameArea(),

                  const SizedBox(height: 20),

                  // Control Automatic Switch with enhanced design
                  _buildAutomaticControlSection(),

                  const SizedBox(height: 20),

                  // Enhanced Control Buttons Section
                  _buildEnhancedControlButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEnhancedGameArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF24D17E).withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _activeControl != null
                  ? (isAutomaticControl
                      ? const Color(0xFF24D17E).withOpacity(0.2)
                      : activeColors[_activeControl!]!.withOpacity(0.2))
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _activeControl != null
                  ? (isAutomaticControl
                      ? 'Mode Kontrol Semua Aktif'
                      : 'Kontrol $_activeControl Aktif')
                  : 'Sistem Siap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _activeControl != null
                    ? (isAutomaticControl
                        ? const Color(0xFF24D17E)
                        : activeColors[_activeControl!])
                    : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Main game area with animations using AspectRatio
          AspectRatio(
            aspectRatio: 1.0, // Square aspect ratio
            child: Stack(
              children: [
                // Background glow effect
                if (_activeControl != null) ...[
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isAutomaticControl
                                      ? const Color(0xFF24D17E)
                                      : activeColors[_activeControl!]!)
                                  .withOpacity(_glowAnimation.value * 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],

                // Main image with pulse animation
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(200),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF24D17E).withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: Image.asset(
                              'assets/skala_easy.png',
                              width: 450,
                              height: 450,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Draggable Mascot
                Positioned(
                  left: _mascotPosition.dx,
                  top: _mascotPosition.dy,
                  child: Draggable(
                    feedback: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAutomaticControl
                              ? const Color(0xFF24D17E)
                              : (_activeControl != null
                                  ? activeColors[_activeControl!]!
                                  : const Color(0xFF24D17E)),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isAutomaticControl
                                    ? const Color(0xFF24D17E)
                                    : (_activeControl != null
                                        ? activeColors[_activeControl!]!
                                        : const Color(0xFF24D17E)))
                                .withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF8FFF9),
                              isAutomaticControl
                                  ? const Color(0xFF24D17E).withOpacity(0.1)
                                  : (_activeControl != null
                                      ? activeColors[_activeControl!]!
                                          .withOpacity(0.1)
                                      : const Color(0xFFE8F8ED))
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/maskot_head.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    childWhenDragging: Container(), // Kosongkan saat didrag
                    onDragEnd: (details) {
                      setState(() {
                        // Update posisi maskot berdasarkan posisi drag
                        RenderBox renderBox =
                            context.findRenderObject() as RenderBox;
                        Offset localOffset =
                            renderBox.globalToLocal(details.offset);
                        _mascotPosition = localOffset;
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isAutomaticControl
                                    ? const Color(0xFF24D17E)
                                    : (_activeControl != null
                                        ? activeColors[_activeControl!]!
                                        : const Color(0xFF24D17E)),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isAutomaticControl
                                          ? const Color(0xFF24D17E)
                                          : (_activeControl != null
                                              ? activeColors[_activeControl!]!
                                              : const Color(0xFF24D17E)))
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFF8FFF9),
                                    isAutomaticControl
                                        ? const Color(0xFF24D17E)
                                            .withOpacity(0.1)
                                        : (_activeControl != null
                                            ? activeColors[_activeControl!]!
                                                .withOpacity(0.1)
                                            : const Color(0xFFE8F8ED))
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Image.asset(
                                  'assets/maskot_head.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.contain,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const GamifikasiProgresPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Floating particles effect
                if (_activeControl != null) ...[
                  ...List.generate(6, (index) {
                    return Positioned(
                      left: 50 + (index * 40.0),
                      top: 100 + (index % 2 * 80.0),
                      child: AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -20 * _glowAnimation.value),
                            child: Opacity(
                              opacity: (1 - _glowAnimation.value) * 0.8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isAutomaticControl
                                      ? const Color(0xFF24D17E)
                                      : activeColors[_activeControl!],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomaticControlSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: isAutomaticControl
            ? Border.all(color: const Color(0xFF24D17E), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isAutomaticControl
                ? const Color(0xFF24D17E).withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            blurRadius: isAutomaticControl ? 15 : 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kontrol Semua Pompa",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                isAutomaticControl
                    ? "Aktif - Semua kontrol menyala"
                    : "Nonaktif - Kontrol manual tersedia",
                style: TextStyle(
                  fontSize: 12,
                  color: isAutomaticControl ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _handleAutomaticControlToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color:
                    isAutomaticControl ? const Color(0xFF24D17E) : Colors.grey,
                boxShadow: [
                  BoxShadow(
                    color: (isAutomaticControl
                            ? const Color(0xFF24D17E)
                            : Colors.grey)
                        .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: isAutomaticControl
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedControlButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tambahkan label "Kontrol Manual" di atas tombol-tombol
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Kontrol Manual',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 2.2,
          ),
          itemCount: controls.keys.length,
          itemBuilder: (context, index) {
            String controlName = controls.keys.elementAt(index);
            return _buildEnhancedControlButton(
              name: controlName,
              isActive: controls[controlName]!,
              activeColor: activeColors[controlName]!,
              isLocked: isAutomaticControl,
              onTap: () => _handleIndividualControl(controlName),
            );
          },
        ),
      ],
    );
  }

  // Peta untuk mencocokkan kontrol dengan ikon
  final Map<String, IconData> controlIcons = {
    "A MIX": Icons.invert_colors,
    "B MIX": Icons.water_drop,
    "PH UP": Icons.arrow_upward,
    "PH DOWN": Icons.arrow_downward,
  };

  Widget _buildEnhancedControlButton({
    required String name,
    required bool isActive,
    required Color activeColor,
    required bool isLocked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [activeColor, activeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade200, Colors.grey.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? activeColor.withOpacity(0.4)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isActive ? 15 : 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Opacity(
          opacity: isLocked ? 0.7 : 1.0,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controlIcons[name],
                        color: isActive ? Colors.white : Colors.black54,
                        size: 24,
                      ),
                    ),
                    if (isLocked)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelWidget({required int level}) {
    return InkWell(
      onTap: () {
        _showCustomSnackBar(
            context, 'Anda telah mencapai Level $level!', Colors.green);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color.fromARGB(192, 16, 134, 77),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
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
              style: const TextStyle(
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
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
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
              style: const TextStyle(
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
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.leaderboard, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text(
              'Leaderboard',
              style: TextStyle(
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF24D17E),
        onTap: (index) {
          setState(() {
            _bottomNavCurrentIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BerandaPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PanduanPage()),
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
            activeIcon: Icon(Icons.home, color: Colors.black),
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.notification_add, color: Colors.black),
            icon: Icon(Icons.notification_add, color: Colors.white),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.assignment, color: Colors.black),
            icon: Icon(Icons.assignment, color: Colors.white),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.person, color: Colors.black),
            icon: Icon(Icons.person, color: Colors.white),
            label: 'Akun',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }
}
