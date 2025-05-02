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

class GamifikasiPage extends StatefulWidget {
  const GamifikasiPage({super.key});

  @override
  State<GamifikasiPage> createState() => _GamifikasiPageState();
}

class _GamifikasiPageState extends State<GamifikasiPage> {
  int _bottomNavCurrentIndex = 0;
  bool isAutomaticControl = false;
  Map<String, bool> controls = {
    "WATER": false,
    "AB MIX": false,
    "PH UP": false,
    "PH DOWN": false,
  };

  // Peta untuk warna aktif setiap kontrol
  final Map<String, Color> activeColors = {
    "WATER": const Color(0xFF50B7F2),
    "AB MIX": const Color(0xFF2AD5B6),
    "PH UP": const Color(0xFFFBBB00),
    "PH DOWN": Colors.red,
  };
  // MQTT Client
  late MqttServerClient client;
  final String broker = '192.168.205.189';
  final String topic = 'gamifikasi/control'; // Ganti sesuai topik kamu

  @override
  void initState() {
    super.initState();
    connectMQTT(); // MQTT
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

  // Perbaikan pada fungsi publishControl:
  void publishControl(String device, bool isActive) {
    if (client.connectionStatus == null ||
        client.connectionStatus!.state != MqttConnectionState.connected) {
      debugPrint('MQTT not connected, trying to reconnect...');
      connectMQTT();
      return;
    }

    final builder = MqttClientPayloadBuilder();
    // Format pesan MQTT agar bisa dipahami ESP32
    String message = isActive ? "ON" : "OFF";
    // Kirim topik spesifik untuk setiap device
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Level, Reward dan Leaderboard
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLevelWidget(level: 5),
                  _buildRewardWidget(coins: 500),
                  _buildLeaderboardWidget(),
                ],
              ),
              const SizedBox(height: 8),

              // Gamification Graphic
              Center(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/skala_easy.png',
                      width: 400,
                      height: 400,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 0,
                      top: 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF24D17E),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu,
                              color: Colors.white, size: 20),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const GamifikasiProgresPage()),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 1),

              // Control Automatic Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Control Automatic",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isAutomaticControl = !isAutomaticControl;
                      });
                      publishControl("AUTO", isAutomaticControl); // MQTT
                    },
                    child: Icon(
                      isAutomaticControl ? Icons.toggle_on : Icons.toggle_off,
                      color: isAutomaticControl ? Colors.green : Colors.grey,
                      size: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Control Buttons Section
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                ),
                itemCount: controls.keys.length,
                itemBuilder: (context, index) {
                  String controlName = controls.keys.elementAt(index);
                  return _buildControlButton(
                    name: controlName,
                    isActive: controls[controlName]!,
                    activeColor: activeColors[controlName]!,
                    onTap: () {
                      setState(() {
                        controls[controlName] = !controls[controlName]!;
                      });
                      publishControl(
                          controlName, controls[controlName]!); // MQTT
                    },
                  );
                },
              ),

              // Bagian Misi
              const SizedBox(height: 10), // Spasi sebelum misi
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Widget untuk Level dengan Ikon
  Widget _buildLevelWidget({required int level}) {
    return InkWell(
      onTap: () {
        // Tambahkan logika jika perlu saat level di-tap
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
            const Icon(Icons.grade,
                color: Colors.white, size: 20), // Ikon Level
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
        // Navigasi ke halaman RewardPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RewardPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFC107),
              Color(0xFFFF9800)
            ], // Warna Kuning dan Orange
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
        // Navigasi ke halaman RewardPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LeaderboardPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Menggunakan gradien biru ke hijau
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

  // Tambahkan peta untuk mencocokkan kontrol dengan ikon
  final Map<String, IconData> controlIcons = {
    "WATER": Icons.invert_colors,
    "AB MIX": Icons.water_drop,
    "PH UP": Icons.arrow_upward,
    "PH DOWN": Icons.arrow_downward,
  };

  // Widget untuk Control Button
  Widget _buildControlButton({
    required String name,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                controlIcons[name],
                color: isActive ? Colors.white : Colors.black,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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

          // Navigasi halaman berdasarkan index
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
            activeIcon: Icon(
              Icons.home,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.home,
              color: Colors.white,
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.notification_add,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.notification_add,
              color: Colors.white,
            ),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.assignment,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.assignment,
              color: Colors.white,
            ),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.person,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.person,
              color: Colors.white,
            ),
            label: 'Akun',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }
}
