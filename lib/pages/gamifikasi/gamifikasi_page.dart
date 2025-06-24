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

  // MQTT Client
  late MqttServerClient client;
  final String broker = '10.170.16.56';
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
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

  Future<void> _handleRefresh() async {
    try {
      // Reconnect MQTT if needed
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        await connectMQTT();
      }

      // Reload user data
      await _loadUserData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil diperbarui'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui data: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  Future<void> connectMQTT() async {
    client = MqttServerClient(broker, '');
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: false);
    client.onDisconnected = onDisconnected;

    try {
      await client.connect();
      debugPrint('MQTT Connected');
    } catch (e) {
      debugPrint('MQTT Connection failed: $e');
      client.disconnect();
    }
  }

  void onDisconnected() {
    debugPrint('⚠️ MQTT Disconnected');
  }

  void publishControl(String device, bool isActive) {
    if (client.connectionStatus == null ||
        client.connectionStatus!.state != MqttConnectionState.connected) {
      debugPrint('MQTT not connected, trying to reconnect...');
      connectMQTT();
      return;
    }

    final builder = MqttClientPayloadBuilder();
    String message = isActive ? "ON" : "OFF";
    String specificTopic = "$topic/$device";

    builder.addString(message);
    client.publishMessage(specificTopic, MqttQos.atLeastOnce, builder.payload!);
    debugPrint('📤 Published to $specificTopic: $message');
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
                  ? activeColors[_activeControl!]!.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _activeControl != null
                  ? 'Kontrol $_activeControl Aktif'
                  : 'Sistem Siap',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _activeControl != null
                    ? activeColors[_activeControl!]
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
                              activeColors[_activeControl!]!
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
                              width: 450, // Reduced size to fit better
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
                          color: _activeControl != null
                              ? activeColors[_activeControl!]!
                              : const Color(0xFF24D17E),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_activeControl != null
                                    ? activeColors[_activeControl!]!
                                    : const Color(0xFF24D17E))
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
                              _activeControl != null
                                  ? activeColors[_activeControl!]!
                                      .withOpacity(0.1)
                                  : const Color(0xFFE8F8ED)
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
                        // Menghitung posisi relatif terhadap widget yang lebih besar
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
                                color: _activeControl != null
                                    ? activeColors[_activeControl!]!
                                    : const Color(0xFF24D17E),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_activeControl != null
                                          ? activeColors[_activeControl!]!
                                          : const Color(0xFF24D17E))
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
                                    _activeControl != null
                                        ? activeColors[_activeControl!]!
                                            .withOpacity(0.1)
                                        : const Color(0xFFE8F8ED)
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
                      left: 50 + (index * 40.0), // Adjusted spacing
                      top: 100 + (index % 2 * 80.0), // Adjusted spacing
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
                                  color: activeColors[_activeControl!],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                "Kontrol Otomatis",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                isAutomaticControl ? "Aktif" : "Nonaktif",
                style: TextStyle(
                  fontSize: 12,
                  color: isAutomaticControl ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                isAutomaticControl = !isAutomaticControl;
              });
              publishControl("AUTO", isAutomaticControl);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isAutomaticControl ? Colors.green : Colors.grey,
                boxShadow: [
                  BoxShadow(
                    color: (isAutomaticControl ? Colors.green : Colors.grey)
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
              onTap: () {
                setState(() {
                  controls[controlName] = !controls[controlName]!;
                });
                publishControl(controlName, controls[controlName]!);

                // Trigger animation if control is turned on
                if (controls[controlName]!) {
                  _triggerControlAnimation(controlName);
                }
              },
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }

  // Widget untuk Level dengan Ikon
  Widget _buildLevelWidget({required int level}) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anda telah mencapai Level $level!')),
        );
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

  // Widget untuk Reward (Jumlah Koin)
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

  // Fungsi untuk membuat Bottom Navigation Bar
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
