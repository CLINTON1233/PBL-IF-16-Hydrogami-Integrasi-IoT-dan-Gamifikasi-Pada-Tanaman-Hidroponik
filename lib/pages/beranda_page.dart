import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/monitoring/monitoring_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _notificationCount = 0;
  bool _showLogoutText = false;
  int _bottomNavCurrentIndex = 0;
  String _location = "Batam";
  String _weatherDescription = "Cerah, Berawan";
  String _temperature = "35°C";
  String _username = "User";

  // Data hidroponik untuk tampilan baru
  double _nutrientLevel = 78.3; // dalam persen
  double _waterConsumption = 11.87; // dalam liter
  double _targetHarvest = 20.0; // dalam kg
  double _growthPercentage = 0.30; // persentase pertumbuhan tanaman
  double _harvestLastWeek = 4.0; // dalam kg
  double _waterLastWeek = 10.0; // dalam liter

  // Tambahkan variabel yang kurang
  List<Map<String, dynamic>> _plantActivities = [];
  double _revenueLastWeek = 150.0; // Default revenue value
  double _foodLastWeek = 75.0; // Default food expense value

  // Data transaksi
  List<Map<String, dynamic>> _transactions = [];
  String _selectedTimeFrame = "Monthly";

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchWeather();
    _loadNotificationCount();
    _loadTransactions();
  }

  // Fungsi untuk mengambil jumlah notifikasi dari SharedPreferences atau API
  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil jumlah notifikasi yang belum dibaca dari SharedPreferences
      _notificationCount = prefs.getInt('unread_notifications') ?? 0;
    });
  }

  // Tambahkan fungsi ini
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
    });
  }

  Future<void> _fetchWeather() async {
    const apiKey = "ffd2fbe25253293c332f670ca067a7ea";
    const city = "Batam";
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherDescription = data['weather'][0]['description'];
          _temperature = "${data['main']['temp'].toStringAsFixed(1)}°C";
        });
      } else {
        print("Failed to load weather data");
      }
    } catch (e) {
      print("Error fetching weather: $e");
    }
  }

  // Mock data untuk transaksi
  void _loadTransactions() {
    setState(() {
      _plantActivities = [
        {
          'title': 'Panen Pakcoy',
          'date': '18:27 - April 30',
          'category': 'Panen',
          'amount': 4.0,
          'isExpense': false,
          'icon': Icons.eco,
          'color': Colors.green
        },
        {
          'title': 'Isi Nutrisi',
          'date': '17:00 - April 24',
          'category': 'Nutrisi',
          'amount': 1.5,
          'isExpense': true,
          'icon': Icons.opacity,
          'color': Colors.blue
        },
        {
          'title': 'Pengecekan pH',
          'date': '8:30 - April 15',
          'category': 'Perawatan',
          'amount': 6.7,
          'isExpense': false,
          'icon': Icons.science,
          'color': Colors.purple
        },
      ];

      // Assign plant activities to transactions
      _transactions = _plantActivities;
    });
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: TextButton(
                    child: const Text("Tidak, Batalkan!",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup dialog
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 40.0),
                  child: TextButton(
                    child:
                        const Text("Ya", style: TextStyle(color: Colors.green)),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs
                          .remove('username'); // Hapus username saat logout

                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF24D17E),
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   backgroundColor: const Color(0xFF24D17E),
      //   title: Row(
      //     children: [
      //       const SizedBox(width: 10),
      //       Text(
      //         'HYDROGAMI',
      //         style: GoogleFonts.kurale(
      //           fontSize: 20,
      //           fontWeight: FontWeight.bold,
      //           color: Colors.black,
      //         ),
      //       ),
      //       const Spacer(),
      //       MouseRegion(
      //         onEnter: (_) {
      //           setState(() {
      //             _showLogoutText = true;
      //           });
      //         },
      //         onExit: (_) {
      //           setState(() {
      //             _showLogoutText = false;
      //           });
      //         },
      //         child: Column(
      //           children: [
      //             IconButton(
      //               icon: const Icon(Icons.logout, color: Colors.black),
      //               onPressed: _showLogoutConfirmationDialog,
      //             ),
      //             if (_showLogoutText)
      //               const Text(
      //                 'Logout',
      //                 style: TextStyle(
      //                   color: Colors.black,
      //                   fontSize: 12,
      //                 ),
      //               ),
      //           ],
      //         ),
      //       ),
      //     ],
      //   ),
      // ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, Selamat Datang',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Selamat Pagi, $_username!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 36, // Ukuran latar belakang lebih kecil
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white, // Latar putih
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.black,
                                size: 20, // Ukuran ikon lebih kecil
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotifikasiPage(),
                                  ),
                                );
                              },
                              padding: EdgeInsets
                                  .zero, // Hapus padding default agar pas di tengah
                              constraints:
                                  const BoxConstraints(), // Hilangkan batas default
                            ),
                          ),
                          if (_notificationCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  _notificationCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Balance and Expense Sections
                  Row(
                    children: [
                      _buildInfoColumn(
                          'Tingkat Nutrisi',
                          '${_nutrientLevel.toStringAsFixed(1)}%',
                          Icons.water_drop_outlined),
                      const SizedBox(width: 15),
                      _buildInfoColumn(
                          'Konsumsi Air',
                          '${_waterConsumption.toStringAsFixed(1)}L',
                          Icons.water,
                          isExpense: true),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${(_growthPercentage * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_targetHarvest.toStringAsFixed(1)} kg',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _growthPercentage,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_growthPercentage * 100).toInt()}% Pertumbuhan Tanaman, Terlihat Baik.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content Area (White Background)
            Container(
              // Beri tinggi minimal supaya konten tidak terlalu kecil
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                ),
              ),
              child: Column(
                children: [
                  // Judul MENU (di luar padding Container menu)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // Jika ingin judul, bisa isi di sini
                    ),
                  ),

                  // Menu Container (horizontal scroll)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24D17E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => MonitoringPage()),
                                );
                              },
                              child: _buildCircleMenuWithLabel(
                                  Icons.monitor_heart, 'Monitoring'),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => GamifikasiPage()),
                                );
                              },
                              child: _buildCircleMenuWithLabel(
                                  Icons.emoji_events, 'Gamifikasi'),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => PanduanPage()),
                                );
                              },
                              child: _buildCircleMenuWithLabel(
                                  Icons.menu_book, 'Panduan'),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfilPage()),
                                );
                              },
                              child: _buildCircleMenuWithLabel(
                                  Icons.person, 'Kelola Profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF24D17E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildSavingGoalWidget(),
                            const VerticalDivider(
                              color: Color(0xFF24D17E),
                              thickness: 1,
                              width: 30,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSummaryItem(
                                    'Panen Minggu Lalu',
                                    '${_harvestLastWeek.toStringAsFixed(1)} kg',
                                    Icons.eco,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildSummaryItem(
                                    'Air Terpakai Minggu Lalu',
                                    '${_waterLastWeek.toStringAsFixed(1)} L',
                                    Icons.water,
                                    isConsumption: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Time Filter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTimeFilterButton('Daily'),
                        _buildTimeFilterButton('Weekly'),
                        _buildTimeFilterButton('Monthly'),
                      ],
                    ),
                  ),

                  // Transactions List
                  // NOTE: Gunakan shrinkWrap dan physics supaya list ikut scroll SingleChildScrollView
                  ListView.builder(
                    padding: const EdgeInsets.all(20),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildCircleMenuWithLabel(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF24D17E),
          child: Icon(
            icon,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Widget Info Column (Balance/Expense)
  Widget _buildInfoColumn(String title, String amount, IconData icon,
      {bool isExpense = false}) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: isExpense ? Colors.red[100] : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget for Tank level circle
  Widget _buildSavingGoalWidget() {
    return Container(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.lightBlue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_drop,
              color: Colors.lightBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            "Level Air",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            "Tanaman",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Panen/Air Terpakai items
  Widget _buildSummaryItem(String title, String amount, IconData icon,
      {bool isConsumption = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isConsumption
                ? Colors.blue.withOpacity(0.2)
                : Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isConsumption ? Colors.blue : Colors.green,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isConsumption ? Colors.blue : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Time Filter Button Widget
  Widget _buildTimeFilterButton(String title) {
    final isSelected = _selectedTimeFrame == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeFrame = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF24D17E)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          // Icon Circle
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activity['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'],
              color: activity['color'],
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          // Title and Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  activity['date'],
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Category Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              activity['category'],
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 15),
          // Value
          Text(
            activity['category'] == 'Panen'
                ? "${activity['amount'].toStringAsFixed(1)} kg"
                : activity['category'] == 'Nutrisi'
                    ? "${activity['amount'].toStringAsFixed(1)} L"
                    : "pH ${activity['amount'].toStringAsFixed(1)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: activity['isExpense'] ? Colors.blue : Colors.green,
            ),
          ),
        ],
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
              Icons.notifications,
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

// Fungsi item navigasi khusus (opsional jika dipakai)
}
