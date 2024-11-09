import 'package:application_hydrogami/gamifikasi_page.dart';
import 'package:application_hydrogami/monitoring_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/login_page.dart';
import 'package:application_hydrogami/notifikasi_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _bottomNavCurrentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row untuk logo dan teks "Hi, Anton!"
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/hydrogami_logo.png',
                          width: 85,
                          height: 85,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Hi, Anton!',
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notification_add,
                              color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const NotifikasiPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.black),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 30),
                        const Icon(
                          Icons.location_on,
                          size: 30,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Batam',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Cerah, Berawan',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.wb_sunny,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '35°C',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(21.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 3 / 4,
                children: <Widget>[
                  _buildCard('Monitoring\nReal-Time', Icons.show_chart),
                  _buildCard('Gamifikasi', Icons.videogame_asset),
                  _buildCard('Panduan', Icons.assignment),
                  _buildCard('Kelola Profile', Icons.person),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Fungsi untuk membuat Card dengan parameter teks dan ikon
  Widget _buildCard(String title, IconData icon) {
    return Card(
      color: const Color(0xFF29CC74),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          // Logika untuk mengarahkan ke halaman yang sesuai
          switch (title) {
            case 'Monitoring\nReal-Time':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MonitoringPage()),
              );
              break;
            case 'Gamifikasi':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GamifikasiPage()),
              );
              break;
            case 'Panduan':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PanduanPage()),
              );
              break;
            case 'Kelola Profile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilPage()),
              );
              break;
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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

          switch (index) {
            case 0: // Beranda
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BerandaPage()),
              );
              break;
            case 1: // Notifikasi
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
              );
              break;
            case 2: // Panduan
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PanduanPage()),
              );
              break;
            case 3: // Profil
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
