import 'dart:collection';

import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
import 'package:application_hydrogami/pages/monitoring/monitoring_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_hidroponik_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_nutrisi_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_panen_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_phupdown_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_sensor_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_tanaman_page.dart';
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
import 'dart:math';

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
  int _plantAge = 0;
  DateTime? _plantStartDate;
  int _totalHarvests = 0;
  bool _isHarvestDialogShown = false;
  Timer? _plantTimer;
  bool _isDataLoaded = false;
  bool _hasStartedPlanting = false;
  bool _hasCompletedSetup = false;
  int _currentSlide = 0;
  final PageController _pageController = PageController();
  Timer? _carouselTimer;

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
  String _currentLocation = "Memuat...";
  bool _isLoadingLocation = true;
  String _currentWeather = "Memuat...";
  IconData _weatherIcon = Icons.cloud_queue;
  Color _weatherColor = Colors.grey;
  bool _isLoadingWeather = true;
  double? _latitude;
  double? _longitude;

  // Fungsi untuk mendapatkan sapaan berdasarkan waktu
  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Selamat Pagi';
    } else if (hour >= 12 && hour < 15) {
      return 'Selamat Siang';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // Data panduan
  final List<Map<String, dynamic>> _panduanData = [
    {
      'image': 'assets/panduan_hidroponik.png',
      'title': 'Panduan Merakit Sistem Hidroponik',
      'subtitle': 'Pelajari cara merakit sistem hidroponik',
      'page': const DetailPanduanHidroponikPage(idPanduan: 1),
    },
    {
      'image': 'assets/panduan_sensor.png',
      'title': 'Panduan Pemasangan Sensor IoT',
      'subtitle': 'Cara memasang dan konfigurasi sensor',
      'page': const DetailPanduanSensorPage(idPanduan: 2),
    },
    {
      'image': 'assets/tanaman_panduan.png',
      'title': 'Panduan Pengelolaan Tanaman',
      'subtitle': 'Tips mengelola tanaman hidroponik',
      'page': const DetailPanduanTanamanPage(idPanduan: 3),
    },
    {
      'image': 'assets/panduanNutrisi.jpg',
      'title': 'Panduan Pemberian Nutrisi',
      'subtitle': 'Cara memberikan nutrisi yang tepat',
      'page': const DetailPanduanNutrisiPage(idPanduan: 4),
    },
    {
      'image': 'assets/phupdown.png',
      'title': 'Panduan pH Up dan pH Down',
      'subtitle': 'Mengatur pH tanaman hidroponik',
      'page': const DetailPanduanPhUpDownPage(idPanduan: 5),
    },
    {
      'image': 'assets/panenPakcoy.jpg',
      'title': 'Panduan Memanen Pakcoy',
      'subtitle': 'Tips memanen pakcoy dengan benar',
      'page': const DetailPanduanPanenPage(idPanduan: 6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadNotificationCount();
    _loadTransactions();
    _getCurrentLocation();
    _initializePlant();
    _checkSetupStatus();
    _loadPlantData();

    //carousel
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentSlide < _panduanData.length - 1) {
        _currentSlide++;
      } else {
        _currentSlide = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentSlide,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _plantTimer?.cancel();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  //Fungsi inisialisasi tanaman
  Future<void> _initializePlant() async {
    await _loadPlantData();

    if (_plantStartDate == null) {
      _plantStartDate = DateTime.now();
      _plantAge = 1;
      _savePlantData();
    } else {
      await _calculatePlantAge();
    }

    _isDataLoaded = true;
    _startPlantTimer();
  }

  //Fungsi untuk memulai timer
  void _startPlantTimer() {
    _plantTimer?.cancel();

    _plantTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted && _isDataLoaded) {
        _calculatePlantAge();
      }
    });
  }

  //Fungsi menyimpan data tanaman ke shared preference
  Future<void> _savePlantData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        print('Username not found, cannot save plant data');
        return;
      }

      // Gunakan user-specific keys yang sama
      String userSetupKey = '${username}_has_completed_setup';
      String userPlantStartKey = '${username}_plant_start_date';
      String userHarvestsKey = '${username}_total_harvests';
      String userAgeKey = '${username}_plant_age';
      String userPlantingStatusKey = '${username}_has_started_planting';

      await prefs.setInt(userHarvestsKey, _totalHarvests);
      await prefs.setInt(userAgeKey, _plantAge);
      await prefs.setBool(userPlantingStatusKey, _hasStartedPlanting);
      await prefs.setBool(userSetupKey, _hasCompletedSetup);

      if (_plantStartDate != null) {
        await prefs.setString(
            userPlantStartKey, _plantStartDate!.toIso8601String());
      } else {
        await prefs.remove(userPlantStartKey);
      }

      print('Plant data saved successfully for user: $username');
    } catch (e) {
      print('Error saving plant data: $e');
    }
  }

  //Fungsi memuat data tanaman dari shared preference
  Future<void> _loadPlantData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        print('Username not found in preferences');
        setState(() {
          _hasStartedPlanting = false;
          _hasCompletedSetup = false;
          _plantAge = 0;
          _totalHarvests = 0;
        });
        return;
      }

      // Gunakan user-specific keys yang sama seperti saat menyimpan
      String userSetupKey = '${username}_has_completed_setup';
      String userPlantStartKey = '${username}_plant_start_date';
      String userHarvestsKey = '${username}_total_harvests';
      String userAgeKey = '${username}_plant_age';
      String userPlantingStatusKey = '${username}_has_started_planting';

      // Load data dengan user-specific keys
      final startDateString = prefs.getString(userPlantStartKey);
      final savedHarvests = prefs.getInt(userHarvestsKey) ?? 0;
      final savedAge = prefs.getInt(userAgeKey) ?? 0;
      final savedPlantingStatus = prefs.getBool(userPlantingStatusKey) ?? false;
      final savedSetupStatus = prefs.getBool(userSetupKey) ?? false;

      print('Loading data for user: $username');
      print('Setup completed: $savedSetupStatus');
      print('Started planting: $savedPlantingStatus');
      print('Plant age: $savedAge');

      if (mounted) {
        setState(() {
          _totalHarvests = savedHarvests;
          _plantAge = savedAge;
          _hasStartedPlanting = savedPlantingStatus;
          _hasCompletedSetup = savedSetupStatus;

          if (startDateString != null) {
            _plantStartDate = DateTime.parse(startDateString);
          }
        });
      }

      // Hitung ulang setelah loading
      if (_hasStartedPlanting && _plantStartDate != null) {
        await _calculatePlantAge();
      }

      print('Plant data loaded successfully');
    } catch (e) {
      print('Error loading plant data: $e');
      // Set safe default values
      if (mounted) {
        setState(() {
          _plantStartDate = null;
          _plantAge = 0;
          _totalHarvests = 0;
          _hasStartedPlanting = false;
          _hasCompletedSetup = false;
        });
      }
    }
  }

  // Fungsi untuk memastikan setup status terload dengan benar
  Future<void> _checkSetupStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');

    if (username != null) {
      String userSetupKey = '${username}_has_completed_setup';
      bool setupCompleted = prefs.getBool(userSetupKey) ?? false;

      print('Checking setup status for $username: $setupCompleted');

      setState(() {
        _hasCompletedSetup = setupCompleted;
      });
    }
  }

  // Fungsi untuk melakukan panen
  Future<void> _harvestPlant() async {
    _isHarvestDialogShown = false;

    final newTotalHarvests = _totalHarvests + 1;
    final newStartDate = DateTime.now();

    setState(() {
      _totalHarvests = newTotalHarvests;
      _plantStartDate = newStartDate;
      _plantAge = 1; // Reset ke hari ke-1
    });

    // Simpan data setelah setState
    await _savePlantData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.agriculture, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Selamat! Panen ke-$newTotalHarvests berhasil! Tanaman baru dimulai',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Fungsi untuk mendapatkan data cuaca berdasarkan koordinat
// Perbaikan logika penentuan kondisi cuaca
  Future<void> _getWeatherData(double latitude, double longitude) async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      final String apiKey = "868b1df1cdabcdaea216dc9b27717ac0";
      final url =
          'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Raw API Response: $data"); // Debug log

        // Extract weather data
        final weatherMain = data['weather'][0]['main'];
        final weatherDescription = data['weather'][0]['description'];
        final weatherId = data['weather'][0]['id'];

        print("Weather ID: $weatherId"); // Debug log
        print("Weather Main: $weatherMain"); // Debug log
        print("Weather Description: $weatherDescription"); // Debug log

        // PERBAIKAN: Logika penentuan cuaca yang lebih akurat
        String weatherCondition;
        if (weatherId >= 200 && weatherId < 300) {
          weatherCondition = 'Thunderstorm';
        } else if (weatherId >= 300 && weatherId < 600) {
          weatherCondition = 'Rain';
        } else if (weatherId >= 600 && weatherId < 700) {
          weatherCondition = 'Snow';
        } else if (weatherId >= 700 && weatherId < 800) {
          weatherCondition = 'Mist';
        } else if (weatherId == 800) {
          weatherCondition = 'Clear';
        } else if (weatherId >= 801 && weatherId <= 804) {
          // PERBAIKAN: ID 801-804 adalah berbagai tingkat awan
          weatherCondition = 'Clouds';
        } else {
          // Fallback ke weatherMain jika ID tidak dikenali
          weatherCondition = weatherMain;
        }

        print("Determined Weather Condition: $weatherCondition"); // Debug log

        setState(() {
          _currentWeather = _getIndonesianWeather(weatherCondition);
          _weatherIcon = _getWeatherIcon(weatherCondition);
          _weatherColor = _getWeatherColor(weatherCondition);
          _isLoadingWeather = false;
        });

        // Debug log final result
        print("Indonesian Weather: $_currentWeather");
      } else {
        print("API Error: ${response.statusCode}");
        _setDefaultWeather();
      }
    } catch (e) {
      print("Weather Error: $e");
      _setDefaultWeather();
    }
  }

// Fungsi untuk set default weather ketika error
  void _setDefaultWeather() {
    setState(() {
      _currentWeather = "Tidak dapat memuat data";
      _weatherIcon = Icons.error;
      _weatherColor = Colors.grey;
      _isLoadingWeather = false;
    });
  }

// Fungsi penerjemahan yang diperbaiki
  String _getIndonesianWeather(String englishWeather) {
    switch (englishWeather.toLowerCase()) {
      case 'clear':
        return 'Cerah';
      case 'clouds':
        return 'Berawan';
      case 'few clouds':
        return 'Sedikit Berawan';
      case 'scattered clouds':
        return 'Berawan Tersebar';
      case 'broken clouds':
        return 'Berawan Sebagian';
      case 'overcast clouds':
        return 'Mendung';
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

// Fungsi untuk mendapatkan icon cuaca berdasarkan kondisi
  IconData _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'overcast clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

// Fungsi untuk mendapatkan warna berdasarkan kondisi cuaca
  Color _getWeatherColor(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'clouds':
        return Colors.grey;
      case 'overcast clouds':
        return Colors.blueGrey;
      case 'rain':
        return Colors.blue;
      case 'drizzle':
        return Colors.lightBlue;
      case 'thunderstorm':
        return Colors.deepPurple;
      case 'snow':
        return Colors.lightBlue.shade100;
      case 'mist':
      case 'fog':
      case 'haze':
        return Colors.grey.shade400;
      default:
        return Colors.grey;
    }
  }

// Fungsi untuk mendapatkan lokasi 
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingWeather = true;
      _currentLocation = "Mendeteksi lokasi...";
    });

    try {
      // Cek permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _handleLocationError("Akses lokasi ditolak");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _handleLocationError("Akses lokasi ditolak permanen");
        return;
      }

      //Timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10), 
      );

      print(
          "Current Position: ${position.latitude}, ${position.longitude}"); // DEBUG

      // cek apakah di batam
      if (_isInBatam(position.latitude, position.longitude)) {
        print("Location detected: Batam region"); 
        _setBatamLocation(position);
        return;
      }

      // jika tidak di batam, gunakan koordinat sesuai yang dideteksi
      print(
          "Location detected: Outside Batam, using actual coordinates"); // DEBUG

      // Coba geocoding untuk nama lokasi
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude,
            localeIdentifier: "id_ID");

        if (placemarks.isNotEmpty) {
          _processPlacemark(placemarks.first, position);
        } else {
          setState(() {
            _currentLocation =
                "Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}";
            _isLoadingLocation = false;
          });
          _getWeatherData(position.latitude, position.longitude);
        }
      } catch (geocodingError) {
        print("Geocoding failed: $geocodingError"); // DEBUG
        // Gunakan koordinat mentah jika geocoding gagal
        setState(() {
          _currentLocation =
              "Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}";
          _isLoadingLocation = false;
        });
        _getWeatherData(position.latitude, position.longitude);
      }
    } catch (e) {
      print("Location Error: $e"); // DEBUG
      _handleLocationError("Error sistem", e);
    }
  }

// Helper Functions
  bool _isInBatam(double lat, double lon) {
    bool inBatam = lat >= 0.9 && lat <= 1.3 && lon >= 103.8 && lon <= 104.3;
    print(
        "Checking Batam coordinates: lat=$lat, lon=$lon, inBatam=$inBatam"); // DEBUG
    return inBatam;
  }

  void _setBatamLocation(Position position) {
    print(
        "Setting Batam location with coordinates: ${position.latitude}, ${position.longitude}"); // DEBUG
    setState(() {
      _currentLocation = "Batam";
      _isLoadingLocation = false;
    });
    _getWeatherData(position.latitude, position.longitude);
  }

  void _processPlacemark(Placemark place, Position position) {
    String locationName;

    print("Placemark data: ${place.toString()}"); // DEBUG
    if (place.locality?.isNotEmpty == true) {
      locationName = place.locality!;
    } else if (place.subLocality?.isNotEmpty == true) {
      locationName = place.subLocality!;
    } else if (place.administrativeArea?.isNotEmpty == true) {
      locationName = place.administrativeArea!;
    } else {
      locationName = "Unknown Location";
    }

    // Override jika Mountain View terdeteksi 
    if (locationName.contains("Mountain View") ||
        position.latitude > 35 &&
            position.latitude < 40 &&
            position.longitude < -120) {
      print("Mountain View detected, overriding to Batam"); // DEBUG
      locationName = "Batam";
      // Gunakan koordinat Batam yang sebenarnya
      _getWeatherData(1.0456, 104.0305);
    } else {
      _getWeatherData(position.latitude, position.longitude);
    }

    setState(() {
      _currentLocation = locationName;
      _isLoadingLocation = false;
    });
  }

  void _handleLocationError(String message, [dynamic error]) {
    print("Location error: $message, $error"); // DEBUG
    setState(() {
      _currentLocation = "Batam"; // Default ke Batam
      _isLoadingLocation = false;
    });
    // Gunakan koordinat Batam sebagai fallback
    _getWeatherData(1.0456, 104.0305);
    if (error != null) print("Error details: $error");
  }

  //fungsi untuk notifikasi
  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationCount = prefs.getInt('unread_notifications') ?? 0;
    });
  }

  //fungsi untuk load username
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

  //fungsi mulai menanam
  Future<void> _startPlanting() async {
    setState(() {
      _hasStartedPlanting = true;
      _plantStartDate = DateTime.now();
      _plantAge = 1;
    });

    // menyimpan data setelah menanam
    await _savePlantData();

    // pesan sukses
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.grass, color: Colors.white),
              SizedBox(width: 10),
              Text('Penanaman dimulai!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

// fungsi menghitung umur tanaman
  Future<void> _calculatePlantAge() async {
    if (_plantStartDate != null) {
      final now = DateTime.now();
      final difference = now.difference(_plantStartDate!).inDays;
      final newAge = difference == 0 ? 1 : difference + 1;

      // update state jika umur berubah
      if (_plantAge != newAge) {
        setState(() {
          _plantAge = newAge;
        });
      }

      // Panen dialog ketika tanaman berumur 60 hari
      if (_plantAge >= 60 && !_isHarvestDialogShown) {
        _isHarvestDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showHarvestDialog();
          }
        });
      }
    }
  }

//Fungsi menampilkan dialog ketika saat panen
  void _showHarvestDialog() {
    if (_isHarvestDialogShown && !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Confetti efek
            ...List.generate(50, (index) => _buildConfetti(index)),
            // Dialog
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.orange,
                    size: 50,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Selamat!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tanaman pakcoy Anda sudah siap dipanen!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Umur tanaman: $_plantAge hari',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Apakah Anda ingin menanam lagi?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _isHarvestDialogShown = false;
                    Navigator.of(context).pop();
                    _showPostponeMessage();
                  },
                  child: Text(
                    'Nanti Saja',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _harvestPlant();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Ya, Tanam!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

// Fungsi untuk menampilkan pesan ketika memilih Nanti Saja
  void _showPostponeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tekan tombol panen sebelum menanam kembali.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Panen',
          textColor: Colors.white,
          onPressed: () {
            _harvestPlant();
          },
        ),
      ),
    );
  }

//reset umur tanaman
  Future<void> _resetPlant() async {
    final newStartDate = DateTime.now();

    setState(() {
      _plantStartDate = newStartDate;
      _plantAge = 1; // Mulai dari hari ke-1
      _isHarvestDialogShown = false;
    });

    // Simpan data tanpa await di setState
    _savePlantData();
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Hi, Selamat Datang',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            '${_getGreeting()}, $_username!',
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
                    padding: EdgeInsets.fromLTRB(20, 10, 20, 5),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      // Jika ingin judul, bisa isi di sini
                    ),
                  ),

                  _buildCarouselPanduan(),

                  // Menu Container (horizontal scroll)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                                  Icons.info, 'Tentang Kami'),
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
                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
                                  _buildPlantAgeItem(),
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

                  const SizedBox(height: 10),

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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                                  'Memuat...',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
                                    fontSize: 12,
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

  // Widget untuk menampilkan umur tanaman
  Widget _buildPlantAgeItem() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: !_hasStartedPlanting
                    ? Colors.grey.withOpacity(0.2)
                    : _plantAge >= 60
                        ? Colors.green.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                !_hasStartedPlanting
                    ? Icons.grass
                    : _plantAge >= 60
                        ? Icons.agriculture
                        : Icons.eco,
                color: !_hasStartedPlanting
                    ? Colors.grey
                    : _plantAge >= 60
                        ? Colors.green
                        : Colors.blue,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !_hasStartedPlanting
                        ? 'Tanaman Pakcoy'
                        : _plantAge >= 60
                            ? 'Status Tanaman'
                            : 'Umur Pakcoy',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    !_hasStartedPlanting
                        ? 'Belum ditanam'
                        : _plantAge >= 60
                            ? 'Siap dipanen!'
                            : '$_plantAge hari',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: !_hasStartedPlanting
                          ? Colors.grey
                          : _plantAge >= 60
                              ? Colors.green
                              : Colors.blue,
                    ),
                  ),
                  if (_totalHarvests > 0) ...[
                    Text(
                      'Total panen: $_totalHarvests kali',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (_hasStartedPlanting &&
                      _plantAge > 0 &&
                      _plantAge < 60) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${60 - _plantAge} hari lagi sampai panen',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: _plantAge / 60,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _plantAge >= 45 ? Colors.orange : Colors.blue,
                      ),
                      minHeight: 2,
                    ),
                  ],

                  // Tombol tanam sekarang
                  if (!_hasStartedPlanting && _hasCompletedSetup) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _startPlanting();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size(0, 0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.grass, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Tanam',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_hasStartedPlanting && _plantAge >= 60) ...[
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showHarvestDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size(0, 0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.agriculture,
                              size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Panen',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Tombol Reset, muncul jika sudah menanam
            if (_hasStartedPlanting) ...[
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Reset Tanaman'),
                        content: const Text(
                          'Apakah Anda yakin ingin memulai penanaman baru? '
                          'Umur tanaman akan direset ke hari ke-1.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Batal'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _resetPlant();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tanaman baru dimulai!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Reset Tanaman',
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // Widget untuk membuat efek confetti
  Widget _buildConfetti(int index) {
    final random = Random(index);
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange
    ];

    return Positioned(
      left: random.nextDouble() * 300,
      top: random.nextDouble() * 500,
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1500 + random.nextInt(1000)),
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(
              (random.nextDouble() - 0.5) * 100 * value, // Horizontal movement
              value * 400, // Vertical fall
            ),
            child: Transform.rotate(
              angle: value * 6.28 * 3, // 3 rotations
              child: Opacity(
                opacity: 1 - (value * 0.8), // Fade out effect
                child: Container(
                  width: random.nextDouble() * 6 + 4, // Random size 4-10
                  height: random.nextDouble() * 6 + 4,
                  decoration: BoxDecoration(
                    color: colors[random.nextInt(colors.length)],
                    shape: random.nextBool()
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                  ),
                ),
              ),
            ),
          );
        },
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

  // Implementasi dalam widget utama
  Widget buildPlantSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menggunakan _buildPlantAgeItem dengan tombol panen
          _buildPlantAgeItem(),
          const SizedBox(height: 10),
          _buildSummaryItem(
            'Air Terpakai Minggu Lalu',
            '${_waterLastWeek.toStringAsFixed(1)} L',
            Icons.water,
            isConsumption: true,
          ),
        ],
      ),
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

  // Widget Carousel
  Widget _buildCarouselPanduan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carousel Container
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentSlide = index;
                  });
                },
                itemCount: _panduanData.length,
                itemBuilder: (context, index) {
                  final panduan = _panduanData[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => panduan['page'],
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        // Background Image
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(panduan['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Gradient Overlay
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),

                        // Content
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                panduan['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                panduan['subtitle'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _panduanData.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentSlide == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentSlide == index
                      ? const Color(0xFF24D17E)
                      : Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
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

