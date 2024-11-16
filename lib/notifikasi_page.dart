import 'package:application_hydrogami/beranda_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Paket untuk format tanggal dan waktu

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  // Menambahkan variabel untuk menyimpan indeks BottomNavigation
  int _bottomNavCurrentIndex = 1;

  // Contoh data notifikasi dengan waktu yang berbeda
  final List<Map<String, dynamic>> notifications = [
    {
      'message':
          'Kelembaban tanah di bawah batas ideal. Segera tambahkan air untuk menjaga kelembaban tanaman tetap optimal.',
      'time': DateTime(2021, 4, 4, 16, 0),
    },
    {
      'message':
          'pH air terlalu asam (pH 5.2). Periksa sistem dan tambahkan buffer untuk menyeimbangkan pH.',
      'time': DateTime(2021, 4, 4, 16, 0),
    },
    {
      'message':
          'Suhu lingkungan melebihi 30°C. Pastikan sirkulasi udara baik untuk mencegah stres pada tanaman.',
      'time': DateTime(2021, 4, 4, 16, 0),
    },
    {
      'message':
          'Kadar air terlalu tinggi. Kurangi irigasi untuk mencegah akar tanaman tergenang air.',
      'time': DateTime(2021, 4, 4, 16, 0),
    },
    {
      'message':
          'Kadar air terlalu tinggi. Kurangi irigasi untuk mencegah akar tanaman tergenang air.',
      'time': DateTime(2021, 4, 4, 16, 0),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp),
          iconSize: 20.0,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/hydrogami_logo2.png',
              width: 30,
              height: 30,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final time = notification['time'];
          final message = notification['message'];
          final timeAgo = _timeAgo(time); // Menghitung waktu lalu

          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3), // Bayangan bawah
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                leading: const Icon(
                  Icons.notifications,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
                title: Text(
                  message,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w400),
                ),
                subtitle: Text(
                  'Dikirim pada: ${DateFormat('dd MMM yyyy, HH:mm').format(time)} ($timeAgo)',
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w300),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          _buildBottomNavigation(), // Menggunakan bottom navigation bar
    );
  }

  String _timeAgo(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inDays >= 365) {
      return '${(duration.inDays / 365).floor()} tahun yang lalu';
    } else if (duration.inDays >= 30) {
      return '${(duration.inDays / 30).floor()} bulan yang lalu';
    } else if (duration.inDays >= 7) {
      return '${(duration.inDays / 7).floor()} minggu yang lalu';
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} hari yang lalu';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} jam yang lalu';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
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
