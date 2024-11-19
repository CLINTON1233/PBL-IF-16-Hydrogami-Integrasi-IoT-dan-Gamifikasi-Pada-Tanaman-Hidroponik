import 'package:flutter/material.dart';
import 'package:application_hydrogami/beranda_page.dart';
import 'package:application_hydrogami/notifikasi_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:google_fonts/google_fonts.dart';

class GamifikasiPage extends StatefulWidget {
  const GamifikasiPage({super.key});

  @override
  State<GamifikasiPage> createState() => _GamifikasiPageState();
}

class _GamifikasiPageState extends State<GamifikasiPage> {
  int _bottomNavCurrentIndex = 0;
  bool isAutomaticControl = false; // Tambahkan deklarasi ini
  Map<String, bool> controls = {
    "AB MIX": false,
    "WATER": false,
    "PH UP": false,
    "PH DOWN": false,
  };

  // Peta untuk warna aktif setiap kontrol
  final Map<String, Color> activeColors = {
    "AB MIX": const Color(0xFF2AD5B6),
    "WATER": const Color(0xFF50B7F2),
    "PH UP": const Color(0xFFFBBB00),
    "PH DOWN": Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        centerTitle: false,
        title: Text(
          'Gamifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
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
                child: Image.asset(
                  'assets/skala_easy.png',
                  width: 400,
                  height: 400,
                  fit: BoxFit.cover,
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
                    },
                  );
                },
              ),

              // Bagian Misi
              const SizedBox(height: 20), // Spasi sebelum misi
              const Text(
                "Misi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFe9e9e9),
                    child: ListTile(
                      leading:
                          Icon(Icons.task_alt, color: Colors.green.shade600),
                      title: Text(
                        "Misi ${index + 1}",
                        style: const TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        "Detail misi ke-${index + 1}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  );
                },
              ),
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
        // Tambahkan logika jika perlu saat jumlah koin di-tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah Koin Anda: $coins')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tampilkan Leaderboard')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Menggunakan gradien biru ke hijau
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.green], // Warna gradien biru dan hijau
            begin: Alignment.topLeft, // Mulai dari kiri atas
            end: Alignment.bottomRight, // Berakhir di kanan bawah
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
    "AB MIX": Icons.water_drop,
    "WATER": Icons.invert_colors,
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
