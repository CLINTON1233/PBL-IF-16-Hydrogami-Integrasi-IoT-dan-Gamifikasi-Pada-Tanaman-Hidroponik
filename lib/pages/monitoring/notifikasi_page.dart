import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  int _bottomNavCurrentIndex = 1;

  List<Map<String, dynamic>> notifications = [
    {
      'message':
          'Suhu lingkungan melebihi 30°C. Pastikan sirkulasi udara baik untuk mencegah stress pada tanaman.',
      'time': DateTime.now().subtract(const Duration(hours: 1)), // Baru saja
    },
    {
      'message':
          'Kadar air terlalu tinggi. Kurangi irigasi untuk mencegah akar tanaman tergenang air.',
      'time': DateTime.now().subtract(const Duration(hours: 3)), // Baru saja
    },
    {
      'message':
          'Kelembaban tanah di bawah batas ideal. Segera tambahkan air untuk menjaga kelembaban tanaman tetap optimal.',
      'time': DateTime.now().subtract(const Duration(days: 1)), // Kemarin
    },
    {
      'message':
          'Nutrisi tanaman kurang. Segera tambahkan nutrisi untuk menjaga nutrisi tanaman.',
      'time': DateTime.now().subtract(const Duration(days: 1)), // Kemarin
    },
    {
      'message': 'Kelembaban tanah di bawah batas ideal. Segera tambahkan air.',
      'time': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'message':
          'pH air terlalu asam (pH 5.2). Periksa sistem dan tambahkan buffer.',
      'time': DateTime.now().subtract(const Duration(days: 10)),
    },
    {
      'message': 'Suhu lingkungan melebihi 30°C. Periksa sirkulasi udara.',
      'time': DateTime.now().subtract(const Duration(days: 16)),
    },
    {
      'message': 'Kadar air terlalu tinggi. Kurangi irigasi segera.',
      'time': DateTime.now().subtract(const Duration(days: 22)),
    },
    // Notifikasi baru untuk 2 minggu terakhir
    {
      'message': 'Nutrisi tanaman rendah. Tambahkan pupuk segera.',
      'time': DateTime.now().subtract(const Duration(days: 12)),
    },
    {
      'message': 'Intensitas cahaya terlalu rendah. Sesuaikan pencahayaan.',
      'time': DateTime.now().subtract(const Duration(days: 14)),
    },
    // Notifikasi baru untuk 3 minggu terakhir
    {
      'message':
          'Kelembaban udara terlalu rendah. Periksa sistem humidifikasi.',
      'time': DateTime.now().subtract(const Duration(days: 19)),
    },
    {
      'message': 'Kadar oksigen di air menurun. Tambahkan aerator.',
      'time': DateTime.now().subtract(const Duration(days: 21)),
    },
  ];

  void removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categorizeNotifications();

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: categories.entries.map((entry) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menambahkan SizedBox untuk jarak
                const SizedBox(height: 16),
                Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600, // Ganti font weight menjadi 600
                  ),
                ),
                ...entry.value.map((notification) {
                  final timeAgo = _timeAgo(notification['time']);
                  return GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Icon(Icons.warning,
                                color: Colors.orange, size: 40),
                            content: const SingleChildScrollView(
                              child: Text(
                                "Apakah Kamu Yakin ingin Menghapus Notifikasi ini?",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    child: const Text(
                                      "Tidak, Batalkan!",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Tutup dialog
                                    },
                                  ),
                                  TextButton(
                                    child: const Text(
                                      "Ya, Hapus",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        notifications.remove(notification);
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        title: Text(
                          notification['message'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Dikirim: $timeAgo',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.notifications,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Map<String, List<Map<String, dynamic>>> _categorizeNotifications() {
    final newNotifications = <Map<String, dynamic>>[];
    final yesterdayNotifications = <Map<String, dynamic>>[];
    final oneWeek = <Map<String, dynamic>>[];
    final twoWeeks = <Map<String, dynamic>>[];
    final threeWeeks = <Map<String, dynamic>>[];

    for (var notification in notifications) {
      final difference = DateTime.now().difference(notification['time']).inDays;

      if (difference == 0) {
        newNotifications.add(notification); // Baru saja
      } else if (difference == 1) {
        yesterdayNotifications.add(notification); // Semalam
      } else if (difference <= 7) {
        oneWeek.add(notification); // 1 Minggu Terakhir
      } else if (difference <= 14) {
        twoWeeks.add(notification); // 2 Minggu Terakhir
      } else if (difference <= 21) {
        threeWeeks.add(notification); // 3 Minggu Terakhir
      }
    }

    return {
      'Baru Saja': newNotifications,
      'Kemarin': yesterdayNotifications,
      '1 Minggu Terakhir': oneWeek,
      '2 Minggu Terakhir': twoWeeks,
      '3 Minggu Terakhir': threeWeeks,
    };
  }

  String _timeAgo(DateTime time) {
    final duration = DateTime.now().difference(time);
    if (duration.inDays >= 1) {
      return '${duration.inDays} hari yang lalu';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} jam yang lalu';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
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
