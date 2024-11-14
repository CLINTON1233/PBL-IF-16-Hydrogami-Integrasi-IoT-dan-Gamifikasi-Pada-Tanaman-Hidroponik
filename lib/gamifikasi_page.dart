import 'package:application_hydrogami/beranda_page.dart';
import 'package:application_hydrogami/notifikasi_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:flutter/material.dart';

class GamifikasiPage extends StatefulWidget {
  const GamifikasiPage({super.key});

  @override
  State<GamifikasiPage> createState() => _GamifikasiPageState();
}

class _GamifikasiPageState extends State<GamifikasiPage> {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Bagian Level, Reward, Jumlah Koin
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Level 5", style: TextStyle(color: Colors.white)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text("Reward", style: TextStyle(color: Colors.white)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text("Jumlah Koin : 500"),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Gambar tanaman
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: DecorationImage(
                  image: AssetImage(
                      'assets/hydrogami_logo2.png'), // tambahkan gambar tanaman di sini
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),
            // Control Automatic
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Control Automatic"),
                Switch(value: true, onChanged: (val) {}),
              ],
            ),
            SizedBox(height: 20),
            // Kontrol AB Mix, Water, pH UP, pH DOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text("AB Mix"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: Text("Water"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: Text("pH UP"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                  child: Text("pH DOWN"),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Fungsi untuk membuat BottomNavigationBar
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

          // Menangani navigasi berdasarkan indeks
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
