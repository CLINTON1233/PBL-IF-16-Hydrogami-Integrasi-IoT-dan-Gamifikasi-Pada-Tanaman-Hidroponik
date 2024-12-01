import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int _bottomNavCurrentIndex = 0;

  final List<Map<String, dynamic>> leaderboardData = [
    {"name": "Anton", "exp": 500},
    {"name": "Kris", "exp": 400},
    {"name": "Jhon", "exp": 300},
    {"name": "Andera", "exp": 150},
    {"name": "Thomas", "exp": 100},
    {"name": "Edward", "exp": 50},
    {"name": "Jonatan", "exp": 45},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        centerTitle: false,
        title: Text(
          'Leaderboard',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header Leaderboard
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF24D17E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/profile_leaderboard.png'),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Rebecca Max",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "750 Exp",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Tombol Tab Mingguan dan Setiap Hari
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTabButton("Mingguan", isSelected: true),
                    const SizedBox(width: 8),
                    _buildTabButton("Setiap Hari", isSelected: false),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Daftar Leaderboard
          Expanded(
            child: ListView.builder(
              itemCount: leaderboardData.length,
              itemBuilder: (context, index) {
                final data = leaderboardData[index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFF3F3F3),
                        ),
                        child: Center(
                          child: Text(
                            (index + 2).toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        data["name"],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        "${data["exp"]} Exp",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: index == 0
                          ? const Icon(Icons.star,
                              color: Colors.amber, size: 24)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Fungsi untuk membuat tombol tab
  Widget _buildTabButton(String title, {required bool isSelected}) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.white : const Color(0xFF24D17E),
        foregroundColor: isSelected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(title),
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
