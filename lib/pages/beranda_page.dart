import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/monitoring/monitoring_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:application_hydrogami/pages/about_us_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  int _notificationCount = 0;
  bool _showLogoutText = false;
  int _bottomNavCurrentIndex = 0;
  String _username = "User";

  double _nutrientLevel = 78.3;
  double _waterConsumption = 11.87;
  double _targetHarvest = 20.0;
  double _growthPercentage = 0.30;
  double _harvestLastWeek = 4.0;
  double _waterLastWeek = 10.0;

  List<Map<String, dynamic>> _plantActivities = [];
  double _revenueLastWeek = 150.0;
  double _foodLastWeek = 75.0;

  List<Map<String, dynamic>> _transactions = [];
  String _selectedTimeFrame = "Monthly";

  // Tambahan untuk fitur lokasi
  String _currentLocation = "Memuat lokasi...";
  bool _isLoadingLocation = true;
  String _currentWeather = "Memuat cuaca...";
  IconData _weatherIcon = Icons.cloud_queue;
  Color _weatherColor = Colors.grey;
  bool _isLoadingWeather = true;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadNotificationCount();
    _loadTransactions();
    _getCurrentLocation();
  }

  // Fungsi untuk mendapatkan data cuaca berdasarkan koordinat
  Future<void> _getWeatherData(double latitude, double longitude) async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final String apiKey = "YOUR_API_KEY";
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weather = data['weather'][0]['main'];
        final description = data['weather'][0]['description'];

        setState(() {
          _currentWeather = _getIndonesianWeather(weather);
          _weatherIcon = _getWeatherIcon(weather);
          _weatherColor = _getWeatherColor(weather);
          _isLoadingWeather = false;
        });
      } else {
        setState(() {
          _currentWeather = "Cerah"; // Default fallback
          _weatherIcon = Icons.wb_sunny;
          _weatherColor = Colors.orange;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print("Error mendapatkan data cuaca: $e");
      setState(() {
        _currentWeather = "Cerah"; // Default fallback
        _weatherIcon = Icons.wb_sunny;
        _weatherColor = Colors.orange;
        _isLoadingWeather = false;
      });
    }
  }

  String _getIndonesianWeather(String englishWeather) {
    switch (englishWeather.toLowerCase()) {
      case 'clear':
        return 'Cerah';
      case 'clouds':
        return 'Berawan';
      case 'rain':
        return 'Hujan';
      case 'drizzle':
        return 'Gerimis';
      case 'thunderstorm':
        return 'Badai Petir';
      case 'snow':
        return 'Salju';
      case 'mist':
      case 'fog':
      case 'haze':
        return 'Berkabut';
      default:
        return englishWeather;
    }
  }

  // Mendapatkan ikon yang sesuai dengan kondisi cuaca
  IconData _getWeatherIcon(String weather) {
    switch (weather.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud_queue;
      default:
        return Icons.cloud_queue;
    }
  }

// Mendapatkan warna yang sesuai dengan kondisi cuaca
  Color _getWeatherColor(String weather) {
    switch (weather.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'clouds':
        return Colors.blueGrey;
      case 'rain':
        return Colors.blue;
      case 'drizzle':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'snow':
        return Colors.lightBlue;
      case 'mist':
      case 'fog':
      case 'haze':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Fungsi untuk mendapatkan lokasi pengguna
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingWeather = true;
    });

    try {
      // Cek permission lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = "Akses lokasi ditolak";
            _isLoadingLocation = false;
            _currentWeather = "Tidak dapat memuat cuaca";
            _isLoadingWeather = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = "Akses lokasi ditolak permanen";
          _isLoadingLocation = false;
          _currentWeather = "Tidak dapat memuat cuaca";
          _isLoadingWeather = false;
        });
        return;
      }

      // Mendapatkan posisi
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Simpan koordinat untuk mendapatkan data cuaca
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Mendapatkan alamat dari koordinat
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentLocation = "${place.subLocality}, ${place.locality}";
          _isLoadingLocation = false;
        });

        // Dapatkan data cuaca setelah mendapatkan lokasi
        await _getWeatherData(position.latitude, position.longitude);
      } else {
        setState(() {
          _currentLocation = "Lokasi tidak ditemukan";
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = "Batam";
        _isLoadingLocation = false;
        _currentWeather = "Cerah";
        _weatherIcon = Icons.wb_sunny;
        _weatherColor = Colors.orange;
        _isLoadingWeather = false;
      });
      print("Error mendapatkan lokasi: $e");
    }
  }

  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationCount = prefs.getInt('unread_notifications') ?? 0;
    });
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
    });
  }

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

      _transactions = _plantActivities;
    });
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: TextButton(
                    child: const Text("Tidak, Batalkan!",
                        style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 40.0),
                  child: TextButton(
                    child:
                        const Text("Ya", style: TextStyle(color: Colors.green)),
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('token');
                        await prefs.remove('username');

                        // debug logging
                        print('Logout successful - all data cleared');

                        // verifikasi token sudah terhapus
                        String? remainingToken = prefs.getString('token');
                        print('Remaining token after logout: $remainingToken');

                        Navigator.of(context).pop(); // Close dialog first

                        // Navigate to login and clear all routes
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logout Berhasil'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        print('Error during logout: $e');
                        Navigator.of(context).pop(); // Close dialog

                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal logout, coba lagi'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
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
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.black,
                                size: 20,
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
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                  const SizedBox(height: 15),
                  _buildLocationWeatherWidget(),

                  const SizedBox(height: 15),
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
                                  Icons.show_chart, 'Monitoring'),
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
                                  Icons.sports_esports, 'Gamifikasi'),
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
                                  Icons.assignment, 'Panduan'),
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
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AboutUsPage()),
                                );
                              },
                              child: _buildCircleMenuWithLabel(
                                  Icons.info, 'About Us'),
                            ),
                            const SizedBox(width: 20),
                            GestureDetector(
                              onTap: _showLogoutConfirmationDialog,
                              child: _buildCircleMenuWithLabel(
                                  Icons.logout, 'Logout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 0),
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
                        _buildTimeFilterButton('Harian'),
                        _buildTimeFilterButton('Mingguan'),
                        _buildTimeFilterButton('Bulanan'),
                      ],
                    ),
                  ),

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

  // Widget untuk menampilkan lokasi dan cuaca
  Widget _buildLocationWeatherWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // Column untuk lokasi
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      _isLoadingLocation
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Memuat lokasi...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _currentLocation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider vertical
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),

          // Column untuk cuaca
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(
                  _weatherIcon,
                  color: _weatherColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cuaca',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      _isLoadingWeather
                          ? Row(
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Memuat...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _currentWeather,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tombol refresh
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
              size: 20,
            ),
            onPressed: _getCurrentLocation,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
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
}


// Fungsi item navigasi khusus (opsional jika dipakai)

