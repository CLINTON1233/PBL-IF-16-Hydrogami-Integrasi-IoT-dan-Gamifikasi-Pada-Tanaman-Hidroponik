// notifikasi_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/services/notifikasi_services.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  // Add these missing variables
  bool isLoading = false;
  List<NotifikasiModel> notifications = [];
  bool hasNewNotifications = false;
  int _bottomNavCurrentIndex = 1; // 1 for Notifications page  // ...

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await fetchNotifications();
    setState(() => isLoading = false);
  }

  Future<void> fetchNotifications() async {
    try {
      final result = await LayananNotifikasi.ambilNotifikasi();
      setState(() {
        notifications = result;
        hasNewNotifications = result.any((n) => n.dibaca == 0);
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat notifikasi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> handleDeleteNotification(NotifikasiModel notification) async {
    final success =
        await LayananNotifikasi.hapusNotifikasi(notification.idNotifikasi);
    if (success) {
      setState(() {
        notifications
            .removeWhere((n) => n.idNotifikasi == notification.idNotifikasi);
        hasNewNotifications = notifications.any((n) => n.dibaca == 0);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notifikasi berhasil dihapus'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus notifikasi'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> markAsRead(NotifikasiModel notification) async {
    if (notification.dibaca == 0) {
      final success =
          await LayananNotifikasi.tandaiDibaca(notification.idNotifikasi);
      if (success) {
        setState(() {
          final index = notifications
              .indexWhere((n) => n.idNotifikasi == notification.idNotifikasi);
          if (index != -1) {
            notifications[index] = NotifikasiModel(
              idNotifikasi: notification.idNotifikasi,
              idSensor: notification.idSensor,
              jenisSensor: notification.jenisSensor,
              pesan: notification.pesan,
              status: notification.status,
              dibaca: 1,
              waktuDibuat: notification.waktuDibuat,
            );
            hasNewNotifications = notifications.any((n) => n.dibaca == 0);
          }
        });
      }
    }
  }

  Map<String, List<NotifikasiModel>> _categorizeNotifications() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final newNotifications = notifications.where((n) {
      return n.waktuDibuat.isAfter(now.subtract(const Duration(hours: 24)));
    }).toList();

    final yesterdayNotifications = notifications.where((n) {
      return n.waktuDibuat.isAfter(yesterday) && n.waktuDibuat.isBefore(today);
    }).toList();

    final thisWeek = notifications.where((n) {
      return n.waktuDibuat.isAfter(now.subtract(const Duration(days: 7))) &&
          !newNotifications.contains(n) &&
          !yesterdayNotifications.contains(n);
    }).toList();

    final older = notifications.where((n) {
      return !newNotifications.contains(n) &&
          !yesterdayNotifications.contains(n) &&
          !thisWeek.contains(n);
    }).toList();

    return {
      if (newNotifications.isNotEmpty) 'Hari Ini': newNotifications,
      if (yesterdayNotifications.isNotEmpty) 'Kemarin': yesterdayNotifications,
      if (thisWeek.isNotEmpty) 'Minggu Ini': thisWeek,
      if (older.isNotEmpty) 'Lebih Lama': older,
    };
  }

  String _timeAgo(DateTime time) {
    final duration = DateTime.now().difference(time);

    if (duration.inDays > 0) {
      return '${duration.inDays} hari lalu';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam lalu';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit lalu';
    }
    return 'Baru saja';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return Colors.blue;
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
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 40, height: 40),
            const SizedBox(width: 10),
            Text(
              'Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            if (hasNewNotifications)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BerandaPage()),
          ),
        ),
        // actions dihapus seluruhnya

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off,
                          size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada notifikasi',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    children: [
                      ...categories.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                entry.key,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            ...entry.value.map((notification) {
                              return Dismissible(
                                key: Key(notification.idNotifikasi.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Hapus Notifikasi'),
                                      content: const Text(
                                          'Apakah Anda yakin ingin menghapus notifikasi ini?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text('Hapus',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) =>
                                    handleDeleteNotification(notification),
                                child: InkWell(
                                  onTap: () => markAsRead(notification),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                      border: notification.dibaca == 0
                                          ? Border.all(
                                              color: const Color(0xFF24D17E),
                                              width: 1)
                                          : null,
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                                  notification.status)
                                              .withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIconForSensor(
                                              notification.jenisSensor),
                                          color: _getStatusColor(
                                              notification.status),
                                        ),
                                      ),
                                      title: Text(
                                        notification.pesan,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: notification.dibaca == 0
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        _timeAgo(notification.waktuDibuat),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: notification.dibaca == 0
                                          ? Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  IconData _getIconForSensor(String? jenisSensor) {
    switch (jenisSensor?.toLowerCase()) {
      case 'ph sensor':
        return Icons.water_drop;
      case 'suhu sensor':
        return Icons.thermostat;
      case 'tds sensor':
        return Icons.science;
      default:
        return Icons.sensors;
    }
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _bottomNavCurrentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF24D17E),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.white,
      onTap: (index) {
        setState(() => _bottomNavCurrentIndex = index);
        switch (index) {
          case 0:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const BerandaPage()));
            break;
          case 1:
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotifikasiPage()));
            break;
          case 2:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const PanduanPage()));
            break;
          case 3:
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const ProfilPage()));
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
          label: 'Profil',
        ),
      ],
    );
  }
}
