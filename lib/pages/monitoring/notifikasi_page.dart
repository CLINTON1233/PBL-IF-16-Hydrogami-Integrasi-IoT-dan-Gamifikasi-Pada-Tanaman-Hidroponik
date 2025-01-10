import 'package:application_hydrogami/services/notifikasi_services.dart';
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
  List<NotifikasiModel> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await LayananNotifikasi.ambilNotifikasi();
      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> handleDeleteNotification(NotifikasiModel notification) async {
    final success =
        await LayananNotifikasi.hapusNotifikasi(notification.idNotifikasi);
    if (success) {
      setState(() {
        notifications.remove(notification);
      });
    }
  }

  Map<String, List<NotifikasiModel>> _categorizeNotifications() {
    final newNotifications = <NotifikasiModel>[];
    final yesterdayNotifications = <NotifikasiModel>[];
    final oneWeek = <NotifikasiModel>[];
    final twoWeeks = <NotifikasiModel>[];
    final threeWeeks = <NotifikasiModel>[];

    for (var notification in notifications) {
      final difference =
          DateTime.now().difference(notification.waktuDibuat).inDays;

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
          iconSize: 20.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: categories.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ...entry.value.map((notification) {
                        final timeAgo = _timeAgo(notification.waktuDibuat);
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
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text(
                                            "Ya, Hapus",
                                            style:
                                                TextStyle(color: Colors.green),
                                          ),
                                          onPressed: () {
                                            handleDeleteNotification(
                                                notification);
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
                                  vertical: 10, horizontal: 16),
                              title: Text(
                                notification.pesan ?? "Default message",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                'Dikirim: $timeAgo',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.grey[600]),
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
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const BerandaPage()));
              break;
            case 1: // Notifikasi
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NotifikasiPage()));
              break;
            case 2: // Panduan
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const PanduanPage()));
              break;
            case 3: // Profil
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const ProfilPage()));
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
            activeIcon: Icon(Icons.notifications, color: Colors.black),
            icon: Icon(Icons.notifications, color: Colors.white),
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
