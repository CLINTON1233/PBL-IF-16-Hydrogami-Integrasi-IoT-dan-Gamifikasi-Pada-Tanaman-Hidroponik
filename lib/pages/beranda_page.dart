import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/monitoring/monitoring_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/services/beranda_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  String userName = 'Guest';
  bool _showLogoutText = false;
  int _bottomNavCurrentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchUserNameFromAPI();
  }

  Future<void> fetchUserNameFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); // Simpan token saat login

      if (token != null) {
        String name = await BerandaServices.getUserDetails(token);
        setState(() {
          userName = name;
        });
      } else {
        setState(() {
          userName = 'Guest';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching user name')),
      );
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(Icons.warning, color: Colors.orange, size: 40),
          content: const Text(
            "Apakah Kamu Yakin ingin Melakukan Logout?",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Tidak, Batalkan!",
                  style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Ya", style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF24D17E),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Text(
              'HYDROGAMI',
              style: GoogleFonts.kurale(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            MouseRegion(
              onEnter: (_) {
                setState(() {
                  _showLogoutText = true;
                });
              },
              onExit: (_) {
                setState(() {
                  _showLogoutText = false;
                });
              },
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.black),
                    onPressed: _showLogoutConfirmationDialog,
                  ),
                  if (_showLogoutText)
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/hydrogami_logo.png',
                          width: 87,
                          height: 87,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Hi $userName!',
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
                        Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.account_circle,
                                  color: Colors.black),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ProfilPage()),
                                );
                              },
                            ),
                          ],
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
                        const SizedBox(width: 50),
                        const Icon(
                          Icons.wb_sunny,
                          size: 25,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 10),
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
                  _buildCard('Gamifikasi', Icons.videogame_asset),
                  _buildCard('Monitoring\nReal-Time', Icons.show_chart),
                  _buildCard('Panduan', Icons.assignment),
                  _buildCard('Kelola Profile', Icons.person),
                ],
              ),
            ),
          ),
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
          switch (title) {
            case 'Gamifikasi':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GamifikasiPage()),
              );
              break;
            case 'Monitoring\nReal-Time':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MonitoringPage()),
              );
              break;
            case 'Panduan':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanduanPage()),
              );
              break;
            case 'Kelola Profile':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilPage()),
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
                  fontFamily: 'Helvetica',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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
