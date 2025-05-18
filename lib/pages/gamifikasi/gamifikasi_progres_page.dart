import 'package:application_hydrogami/pages/gamifikasi/reward_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/gamifikasi/leaderboard_page.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';

class GamifikasiProgresPage extends StatefulWidget {
  const GamifikasiProgresPage({super.key});

  @override
  State<GamifikasiProgresPage> createState() => _GamifikasiProgresPageState();
}

class _GamifikasiProgresPageState extends State<GamifikasiProgresPage> {
  int _bottomNavCurrentIndex = 0;

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
              'Gamifikasi Progress',
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
              MaterialPageRoute(builder: (context) => const GamifikasiPage()),
            );
          },
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        // crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            color: const Color(0xFF24D17E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildRewardWidget(coins: 500),
                IconButton(
                    onPressed: () {
                      //! ke arah informasi upgrade pet
                    },
                    icon: const Icon(Icons.info),
                    color: Colors.grey[700]),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            // padding: const EdgeInsets.all(5),
            color: const Color(0xFF24D17E),
            child: Center(
              child: Text(
                'Level 2',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
            ),
          ),
          Container(
            color: const Color(0xFF24D17E),
            width: double.infinity,
            // padding: EdgeInsets.symmetric(vertical: ),
            child: Image.asset(
              'assets/logo.png',
              height: 150,
            ),
          ),
          Container(
            color: const Color(0xFF24D17E),
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Center(
              child: Text('750 Exp',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800])),
            ),
          ),
          Container(
            // Background hijau
            width: double.infinity,
            decoration: const BoxDecoration(
                color: Color(0xFF24D17E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                )),
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress bar
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.7, // Persentase progress
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4), // Jarak antara bar dan teks
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: 200', // 200 bisa di ganti
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    Text(
                      'Max: 1000',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          //? bagian mission

          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Missions',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    _buildLeaderboardWidget(),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    //button daily,
                    TombolDailyWeekly(),

                    //button weekly
                  ],
                )
              ],
            ),
          ),

          _missionCard(
            icon: Icons.opacity, // Bisa ganti dengan asset jika ada
            iconColor: Colors.lightBlue,
            title: 'Water the plants',
            coins: 250,
            exp: 100,
            progress: 1,
            total: 3,
          ),

          _missionCard(
            icon: Icons.opacity_rounded, // Bisa ganti dengan asset jika ada
            iconColor: Colors.deepOrangeAccent,
            title: 'pH Control',
            coins: 250,
            exp: 100,
            progress: 3,
            total: 3,
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
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
        currentIndex: _bottomNavCurrentIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
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

  Widget _missionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int coins,
    required int exp,
    required int progress,
    required int total,
  }) {
    double progressPercent = progress / total;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon misi
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),

            // Expanded: kolom berisi judul, coin/exp, progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),

                  // Row berisi coin dan exp
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('$coins'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Text('$exp'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Progress bar

                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress / total,
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                          minHeight: 20,
                        ),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '$progress' == '$total'
                                ? 'Claim the Reward!!'
                                : '$progress / $total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color.fromARGB(255, 80, 80,
                                  80), // Atur agar kontras dengan bar
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Icon panah
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: '$progress' == '$total'
                    ? Colors.green[400]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                    '$progress' == '$total'
                        ? Icons.card_giftcard
                        : Icons.arrow_forward,
                    color: Colors.white),
                iconSize: 25,
                onPressed: () {
                  //? link untuk kehlmn gamifikasi
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TombolDailyWeekly extends StatefulWidget {
  @override
  _TombolDailyWeeklyState createState() => _TombolDailyWeeklyState();
}

class _TombolDailyWeeklyState extends State<TombolDailyWeekly> {
  bool isDailySelected = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Daily button
        GestureDetector(
          onTap: () {
            setState(() {
              isDailySelected = true;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            margin: EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: isDailySelected ? Color(0xFF24D17E) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Text(
              'Daily',
              style: TextStyle(
                color: isDailySelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Weekly button
        GestureDetector(
          onTap: () {
            setState(() {
              isDailySelected = false;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: !isDailySelected ? Color(0xFF24D17E) : Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Text(
              'Weekly',
              style: TextStyle(
                color: !isDailySelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
