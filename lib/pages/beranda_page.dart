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
import 'package:application_hydrogami/pages/gamifikasi/reward_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:math';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

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
  Timer? _dataUpdateTimer;

  double _nutrientLevel = 78.3;
  double _waterConsumption = 11.87;
  double _growthPercentage = 0.30;
  double _waterLastWeek = 10.0;
  double _currentTDS = 0;
  double _currentPH = 0;

  List<Map<String, dynamic>> _plantActivities = [];
  double _revenueLastWeek = 150.0;
  double _foodLastWeek = 75.0;

  List<Map<String, dynamic>> _transactions = [];
  String _selectedTimeFrame = "Monthly";

  // Relay statuses synced with GamifikasiPage
  Map<String, bool> _relayStatuses = {
    "A MIX": false,
    "B MIX": false,
    "PH UP": false,
    "PH DOWN": false,
  };

  // MQTT Configuration
  late MqttServerClient client;
  final String broker = 'broker.hivemq.com';
  final int port = 1883;
  final String clientIdentifier =
      'hydrogami_beranda_${DateTime.now().millisecondsSinceEpoch}';
  final String topic = 'hydrogami/sensor/data';

  // Location and weather
  String _currentLocation = "Memuat...";
  bool _isLoadingLocation = true;
  String _currentWeather = "Memuat...";
  IconData _weatherIcon = Icons.cloud_queue;
  Color _weatherColor = Colors.grey;
  bool _isLoadingWeather = true;
  double? _latitude;
  double? _longitude;

  // Fungsi untuk mengkonversi TDS (ppm) ke persentase nutrisi
  double _convertTdsToPercentage(double tdsValue) {
    // Range optimal TDS untuk hidroponik sayuran daun (seperti pakcoy):
    // Minimum: 800 ppm (0%)
    // Maksimum: 1500 ppm (100%)
    // Rumus: (tdsValue - min) / (max - min) * 100

    const double minTDS = 1000;
    const double maxTDS = 1400;

    // Jika nilai di bawah minimum, kita tetap beri nilai 0% (tapi bisa disesuaikan)
    if (tdsValue <= minTDS) return 0;

    // Jika nilai di atas maksimum, kita beri nilai 100% (tapi bisa disesuaikan)
    if (tdsValue >= maxTDS) return 100;

    // Hitung persentase
    return ((tdsValue) / (maxTDS)) * 100;
  }

// Fungsi untuk menghitung konsumsi air berdasarkan tingkat nutrisi
  double _calculateWaterConsumption(double nutrientPercentage) {
    // Asumsi dasar:
    // - Pada 0% nutrisi, konsumsi air minimal (misal 5L)
    // - Pada 100% nutrisi, konsumsi air maksimal (misal 15L)
    // Ini bisa disesuaikan dengan kebutuhan tanaman dan sistem

    const double minWater = 5.0;
    const double maxWater = 15.0;

    return minWater + (nutrientPercentage / 100) * (maxWater - minWater);
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
    _initializeMQTT();
    _loadRelayStates();
    _loadSensorData(); // Tambahkan ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToSensorTopics();
    });

    _dataUpdateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateNutrientAndWaterData();
    });

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
    _dataUpdateTimer?.cancel();
    _plantTimer?.cancel();
    _carouselTimer?.cancel();
    _pageController.dispose();
    client.disconnect();
    super.dispose();
  }

  // Initialize MQTT
  Future<void> _initializeMQTT() async {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;

    try {
      await client.connect();
      _subscribeToTopics();
    } catch (e) {
      print('MQTT Connection Exception: $e');
      client.disconnect();
      Future.delayed(const Duration(seconds: 5), () {
        _initializeMQTT();
      });
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
    _subscribeToTopics();
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    Future.delayed(const Duration(seconds: 3), () {
      _initializeMQTT();
    });
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void _subscribeToTopics() {
    _relayStatuses.keys.forEach((control) {
      String mqttDeviceName = control.replaceAll(" ", "_");
      String specificTopic = "$topic/$mqttDeviceName";
      client.subscribe(specificTopic, MqttQos.atLeastOnce);
    });

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = c[0].topic;

      String controlName = topic.split('/').last.replaceAll("_", " ");
      setState(() {
        _relayStatuses[controlName] = payload == "ON";
      });

      // Save the updated relay states
      _saveRelayStates(); // Add this line

      print('Received message: $payload for $controlName');
    });
  }

// Fungsi untuk menerima update data sensor dari MQTT
  void _updateSensorData(double tds, double ph) {
    setState(() {
      _currentTDS = tds;
      _currentPH = ph;

      // Update nilai nutrisi dan air
      _nutrientLevel = _convertTdsToPercentage(_currentTDS);
      _waterConsumption = _calculateWaterConsumption(_nutrientLevel);

      // Jika tanaman sudah mulai ditanam, update pertumbuhan
      if (_hasStartedPlanting) {
        _updateGrowthBasedOnConditions();
      }
    });
  }

  void _subscribeToSensorTopics() {
    // Subscribe ke topik sensor
    client.subscribe('hydrogami/sensor/data', MqttQos.atLeastOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      try {
        final data = json.decode(payload);
        final tds = data['tds']?.toDouble() ?? 0;
        final ph = data['ph']?.toDouble() ?? 0;

        // Update data sensor
        _updateSensorData(tds, ph);
      } catch (e) {
        print('Error processing sensor data: $e');
      }
    });
  }

// Fungsi untuk update pertumbuhan berdasarkan kondisi nutrisi dan pH
  void _updateGrowthBasedOnConditions() {
    // Progres pertumbuhan berdasarkan umur tanaman (maksimal 50 hari)
    setState(() {
      _growthPercentage =
          min(_plantAge / 50, 1.0); // Progres linier berdasarkan umur
    });

    // Simpan data jika diperlukan
    _savePlantData();
  }

  Future<void> _saveRelayStates() async {
    final prefs = await SharedPreferences.getInstance();
    final relayStates =
        _relayStatuses.map((key, value) => MapEntry(key, value.toString()));
    await prefs.setString('relay_states', jsonEncode(relayStates));
  }

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

  // Update nutrient and water data
  void _updateNutrientAndWaterData() {
    _loadSensorData();
  }

  // Initialize plant
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

  // Start plant timer
  void _startPlantTimer() {
    _plantTimer?.cancel();

    _plantTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted && _isDataLoaded) {
        _calculatePlantAge();
      }
    });
  }

  Future<void> _loadSensorData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTDS = prefs.getDouble('current_tds') ?? 0;
      _nutrientLevel = _convertTdsToPercentage(_currentTDS);
      _waterConsumption = _calculateWaterConsumption(_nutrientLevel);
    });
  }

  // Save plant data
  Future<void> _savePlantData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        print('Username not found, cannot save plant data');
        return;
      }

      String userSetupKey = '${username}_has_completed_setup';
      String userPlantStartKey = '${username}_plant_start_date';
      String userHarvestsKey = '${username}_total_harvests';
      String userAgeKey = '${username}_plant_age';
      String userPlantingStatusKey = '${username}_has_started_planting';
      String userGrowthPercentageKey =
          '${username}_growth_percentage'; // Tambah kunci untuk growthPercentage

      await prefs.setInt(userHarvestsKey, _totalHarvests);
      await prefs.setInt(userAgeKey, _plantAge);
      await prefs.setBool(userPlantingStatusKey, _hasStartedPlanting);
      await prefs.setBool(userSetupKey, _hasCompletedSetup);
      await prefs.setDouble(userGrowthPercentageKey,
          _growthPercentage); // Simpan growthPercentage

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

  Future<void> _loadRelayStates() async {
    final prefs = await SharedPreferences.getInstance();
    final relayStatesString = prefs.getString('relay_states');

    if (relayStatesString != null) {
      final relayStates =
          Map<String, String>.from(jsonDecode(relayStatesString));
      setState(() {
        _relayStatuses =
            relayStates.map((key, value) => MapEntry(key, value == 'true'));
      });
    }
  }

  // Load plant data
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
          _growthPercentage = 0; // Reset growthPercentage
        });
        return;
      }

      String userSetupKey = '${username}_has_completed_setup';
      String userPlantStartKey = '${username}_plant_start_date';
      String userHarvestsKey = '${username}_total_harvests';
      String userAgeKey = '${username}_plant_age';
      String userPlantingStatusKey = '${username}_has_started_planting';
      String userGrowthPercentageKey =
          '${username}_growth_percentage'; // Tambah kunci untuk growthPercentage

      final startDateString = prefs.getString(userPlantStartKey);
      final savedHarvests = prefs.getInt(userHarvestsKey) ?? 0;
      final savedAge = prefs.getInt(userAgeKey) ?? 0;
      final savedPlantingStatus = prefs.getBool(userPlantingStatusKey) ?? false;
      final savedSetupStatus = prefs.getBool(userSetupKey) ?? false;
      final savedGrowthPercentage = prefs.getDouble(userGrowthPercentageKey) ??
          0; // Muat growthPercentage

      print('Loading data for user: $username');
      print('Setup completed: $savedSetupStatus');
      print('Started planting: $savedPlantingStatus');
      print('Plant age: $savedAge');
      print('Growth percentage: $savedGrowthPercentage');

      if (mounted) {
        setState(() {
          _totalHarvests = savedHarvests;
          _plantAge = savedAge;
          _hasStartedPlanting = savedPlantingStatus;
          _hasCompletedSetup = savedSetupStatus;
          _growthPercentage = savedGrowthPercentage; // Set growthPercentage
          if (startDateString != null) {
            _plantStartDate = DateTime.parse(startDateString);
          }
        });
      }

      if (_hasStartedPlanting && _plantStartDate != null) {
        await _calculatePlantAge();
      }

      print('Plant data loaded successfully');
    } catch (e) {
      print('Error loading plant data: $e');
      if (mounted) {
        setState(() {
          _plantStartDate = null;
          _plantAge = 0;
          _totalHarvests = 0;
          _hasStartedPlanting = false;
          _hasCompletedSetup = false;
          _growthPercentage = 0; // Reset growthPercentage
        });
      }
    }
  }

  // Check setup status
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

  // Harvest plant
  Future<void> _harvestPlant() async {
    _isHarvestDialogShown = false;

    final newTotalHarvests = _totalHarvests + 1;
    final newStartDate = DateTime.now();

    setState(() {
      _totalHarvests = newTotalHarvests;
      _plantStartDate = newStartDate;
      _plantAge = 1;
      _growthPercentage = 0; // Reset progres pertumbuhan
    });

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

  // Set default weather
  void _setDefaultWeather() {
    setState(() {
      _currentWeather = "Tidak dapat memuat data";
      _weatherIcon = Icons.error;
      _weatherColor = Colors.grey;
      _isLoadingWeather = false;
    });
  }

  // Get weather data
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
        final weatherMain = data['weather'][0]['main'];
        final weatherDescription = data['weather'][0]['description'];
        final weatherId = data['weather'][0]['id'];

        String weatherCondition;

        if (weatherId >= 200 && weatherId < 300) {
          weatherCondition = 'Thunderstorm';
        } else if ((weatherId >= 300 && weatherId < 600) ||
            weatherMain == 'Rain') {
          weatherCondition = 'Rain';
        } else if (weatherId >= 600 && weatherId < 700) {
          weatherCondition = 'Snow';
        } else if (weatherId >= 700 && weatherId < 800) {
          weatherCondition = 'Mist';
        } else if (weatherId == 800) {
          weatherCondition = 'Clear';
        } else if ((weatherId >= 801 && weatherId <= 804) ||
            weatherMain == 'Clouds') {
          if (weatherDescription.contains('few clouds')) {
            weatherCondition = 'Few clouds';
          } else if (weatherDescription.contains('scattered clouds')) {
            weatherCondition = 'Scattered clouds';
          } else if (weatherDescription.contains('broken clouds')) {
            weatherCondition = 'Broken clouds';
          } else if (weatherDescription.contains('overcast clouds')) {
            weatherCondition = 'Overcast clouds';
          } else {
            weatherCondition = 'Clouds';
          }
        } else {
          weatherCondition = weatherMain;
        }

        setState(() {
          _currentWeather = _getIndonesianWeather(weatherCondition);
          _weatherIcon = _getWeatherIcon(weatherCondition);
          _weatherColor = _getWeatherColor(weatherCondition);
          _isLoadingWeather = false;
        });
      } else {
        print("API Error: ${response.statusCode}");
        _setDefaultWeather();
      }
    } catch (e) {
      print("Weather Error: $e");
      _setDefaultWeather();
    }
  }

  // Translate weather to Indonesian
  String _getIndonesianWeather(String englishWeather) {
    switch (englishWeather.toLowerCase()) {
      case 'clear':
        return 'Cerah';
      case 'clouds':
        return 'Berawan';
      case 'few clouds':
        return 'Sedikit Berawan';
      case 'scattered clouds':
        return 'Awan Tersebar';
      case 'broken clouds':
        return 'Berawan Sebagian';
      case 'overcast clouds':
        return 'Mendung';
      case 'rain':
        return 'Hujan';
      case 'light rain':
        return 'Hujan Ringan';
      case 'moderate rain':
        return 'Hujan Sedang';
      case 'heavy rain':
        return 'Hujan Lebat';
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

  // Get weather icon
  IconData _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'few clouds':
        return Icons.wb_cloudy;
      case 'scattered clouds':
      case 'broken clouds':
        return Icons.cloud;
      case 'overcast clouds':
        return Icons.cloud_queue;
      case 'rain':
      case 'light rain':
      case 'moderate rain':
        return Icons.beach_access;
      case 'heavy rain':
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

  // Get weather color
  Color _getWeatherColor(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'clear':
        return Colors.orange;
      case 'few clouds':
        return Colors.lightBlue;
      case 'scattered clouds':
        return Colors.blueGrey;
      case 'broken clouds':
      case 'clouds':
        return Colors.grey;
      case 'overcast clouds':
        return Colors.blueGrey.shade700;
      case 'rain':
      case 'light rain':
        return Colors.blue.shade300;
      case 'moderate rain':
        return Colors.blue;
      case 'heavy rain':
        return Colors.blue.shade900;
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

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingWeather = true;
      _currentLocation = "Mendeteksi lokasi...";
    });

    try {
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      print("Current Position: ${position.latitude}, ${position.longitude}");

      if (_isInBatam(position.latitude, position.longitude)) {
        print("Location detected: Batam region");
        _setBatamLocation(position);
        return;
      }

      print("Location detected: Outside Batam, using actual coordinates");

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
        print("Geocoding failed: $geocodingError");
        setState(() {
          _currentLocation =
              "Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}";
          _isLoadingLocation = false;
        });
        _getWeatherData(position.latitude, position.longitude);
      }
    } catch (e) {
      print("Location Error: $e");
      _handleLocationError("Error sistem", e);
    }
  }

  // Helper Functions for Location
  bool _isInBatam(double lat, double lon) {
    bool inBatam = lat >= 0.9 && lat <= 1.3 && lon >= 103.8 && lon <= 104.3;
    print("Checking Batam coordinates: lat=$lat, lon=$lon, inBatam=$inBatam");
    return inBatam;
  }

  void _setBatamLocation(Position position) {
    print(
        "Setting Batam location with coordinates: ${position.latitude}, ${position.longitude}");
    setState(() {
      _currentLocation = "Batam";
      _isLoadingLocation = false;
    });
    _getWeatherData(position.latitude, position.longitude);
  }

  void _processPlacemark(Placemark place, Position position) {
    String locationName;

    print("Placemark data: ${place.toString()}");
    if (place.locality?.isNotEmpty == true) {
      locationName = place.locality!;
    } else if (place.subLocality?.isNotEmpty == true) {
      locationName = place.subLocality!;
    } else if (place.administrativeArea?.isNotEmpty == true) {
      locationName = place.administrativeArea!;
    } else {
      locationName = "Unknown Location";
    }

    if (locationName.contains("Mountain View") ||
        position.latitude > 35 &&
            position.latitude < 40 &&
            position.longitude < -120) {
      print("Mountain View detected, overriding to Batam");
      locationName = "Batam";
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
    print("Location error: $message, $error");
    setState(() {
      _currentLocation = "Batam";
      _isLoadingLocation = false;
    });
    _getWeatherData(1.0456, 104.0305);
    if (error != null) print("Error details: $error");
  }

  // Load notification count
  Future<void> _loadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationCount = prefs.getInt('unread_notifications') ?? 0;
    });
  }

  // Load username
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "User";
    });
  }

  // Load transactions
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

  // Start planting
  Future<void> _startPlanting() async {
    setState(() {
      _hasStartedPlanting = true;
      _plantStartDate = DateTime.now();
      _plantAge = 1;
    });

    await _savePlantData();

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

  // Calculate plant age
  Future<void> _calculatePlantAge() async {
    if (_plantStartDate != null) {
      final now = DateTime.now();
      final difference = now.difference(_plantStartDate!).inDays;
      final newAge = difference == 0 ? 1 : difference + 1;

      if (_plantAge != newAge) {
        setState(() {
          _plantAge = newAge;
        });
      }

      if (_plantAge >= 50 && !_isHarvestDialogShown) {
        _isHarvestDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showHarvestDialog();
          }
        });
      }
    }
  }

  // Show harvest dialog
  void _showHarvestDialog() {
    if (_isHarvestDialogShown && !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            ...List.generate(50, (index) => _buildConfetti(index)),
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LEVEL PANEN!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Panen ke-${_totalHarvests + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selamat! Tanaman Anda telah mencapai masa panen',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Umur $_plantAge hari',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF24D17E),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await _harvestPlant();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF24D17E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Panen Sekarang',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _isHarvestDialogShown = false;
                      Navigator.of(context).pop();
                      _showPostponeMessage();
                    },
                    child: Text(
                      'Tunda Panen',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Show postpone message
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

  // Reset plant
  Future<void> _resetPlant() async {
    final newStartDate = DateTime.now();

    setState(() {
      _plantStartDate = newStartDate;
      _plantAge = 1;
      _growthPercentage = 0; // Reset progres pertumbuhan
      _isHarvestDialogShown = false;
    });

    _savePlantData();
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'LOGOUT',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Konfirmasi Logout',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Anda akan keluar dari akun ini dan perlu login kembali untuk mengaksesnya',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('token');
                        await prefs.remove('username');
                        await prefs.remove('current_user_id');
                        await prefs.remove('id');
                        await prefs.remove('email');

                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );

                        _showCustomSnackBar(
                            context, 'Logout berhasil', Colors.green);
                      } catch (e) {
                        Navigator.of(context).pop();
                        _showCustomSnackBar(
                            context, 'Gagal logout', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF24D17E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Show reset plant dialog
  void _showResetPlantDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.refresh,
                size: 80,
                color: Colors.amber,
              ),
              const SizedBox(height: 16),
              Text(
                'RESET TANAMAN',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Konfirmasi Reset',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apakah Anda yakin ingin memulai penanaman baru? Umur tanaman akan direset ke hari ke-1.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                      ),
                    ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF24D17E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
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
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_getGreeting()}, $_username!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.black,
                            size: 20,
                          ),
                          onPressed: _showLogoutConfirmationDialog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildLocationWeatherWidget(),
                  const SizedBox(height: 15),
                  // Card for nutrient, water, and relays
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildInfoCard(
                              'Tingkat Nutrisi',
                              '${_nutrientLevel.toStringAsFixed(1)}%',
                              Icons.water_drop_outlined,
                              const Color.fromARGB(255, 255, 255, 255),
                              'Optimal: 71.4-100%',
                            ),
                            const SizedBox(width: 15),
                            _buildInfoCard(
                              'Konsumsi Air',
                              '${_waterConsumption.toStringAsFixed(1)} L',
                              Icons.water,
                              const Color.fromARGB(255, 252, 252, 252),
                              'Hari ini',
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildProgressCard(
                          'Pertumbuhan Tanaman',
                          _growthPercentage,
                          const Color.fromARGB(255, 255, 255, 255),
                          Icons.eco,
                          'Hari ke-$_plantAge',
                          valueText:
                              '${(_growthPercentage * 100).toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: 15),
                        _buildRelayStatusCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main Content Area
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
                  _buildCarouselPanduan(),
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
                            const SizedBox(width: 20),
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
                                      builder: (context) => RewardPage()),
                                );
                              },
                              child: _buildCircleMenuWithLabel(
                                  Icons.card_giftcard_rounded, 'Reward'),
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
                          ],
                        ),
                      ),
                    ),
                  ),
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
                                    'Air Terpakai Hari Ini', // Ubah label
                                    '${_waterConsumption.toStringAsFixed(1)} L', // Gunakan _waterConsumption
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

  // Info Card Widget
  Widget _buildInfoCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Progress Card Widget
  Widget _buildProgressCard(
      String title, double value, Color color, IconData icon, String status,
      {String? valueText}) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              Text(
                valueText ?? '${(value * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelayStatusCard() {
    final Map<String, Color> relayColors = {
      "A MIX": const Color.fromARGB(255, 20, 94, 136),
      "B MIX": const Color.fromARGB(255, 23, 168, 142),
      "PH UP": const Color.fromARGB(255, 167, 130, 20),
      "PH DOWN": const Color.fromARGB(255, 184, 37, 27),
    };

    final Map<String, IconData> relayIcons = {
      "A MIX": Icons.invert_colors,
      "B MIX": Icons.water_drop,
      "PH UP": Icons.arrow_upward,
      "PH DOWN": Icons.arrow_downward,
    };

    final activeRelays = _relayStatuses.entries.where((e) => e.value).toList();
    final inactiveRelays =
        _relayStatuses.entries.where((e) => !e.value).toList();

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.power, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Status Pompa',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeRelays.isNotEmpty)
            _buildStatusRow('ON', activeRelays, relayColors, relayIcons, true),
          if (activeRelays.isNotEmpty && inactiveRelays.isNotEmpty)
            const SizedBox(height: 8),
          if (inactiveRelays.isNotEmpty)
            _buildStatusRow(
                'OFF', inactiveRelays, relayColors, relayIcons, false),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String title, List<MapEntry<String, bool>> relays,
      Map<String, Color> colors, Map<String, IconData> icons, bool isActive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Status label
        SizedBox(
          width: 40,
          child: Row(
            children: [
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color.fromARGB(255, 255, 255, 255),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Relay chips dalam satu baris
        Expanded(
          child: Row(
            children: relays.map((relay) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[relay.key],
                      size: 14,
                      color: colors[relay.key]!.withOpacity(isActive ? 1 : 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      relay.key,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Location and Weather Widget
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
          Container(
            height: 30,
            width: 1,
            color: Colors.white.withOpacity(0.5),
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
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

  // Circle Menu Widget
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

  // Saving Goal Widget
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

  // Plant Age Item Widget
  Widget _buildPlantAgeItem() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: !_hasStartedPlanting
                  ? Colors.grey.withOpacity(0.2)
                  : _plantAge >= 50
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              !_hasStartedPlanting
                  ? Icons.grass
                  : _plantAge >= 50
                      ? Icons.agriculture
                      : Icons.eco,
              color: !_hasStartedPlanting
                  ? Colors.grey
                  : _plantAge >= 50
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
                      : _plantAge >= 50
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
                      : _plantAge >= 50
                          ? 'Siap dipanen!'
                          : '$_plantAge hari',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: !_hasStartedPlanting
                        ? Colors.grey
                        : _plantAge >= 50
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
                if (_hasStartedPlanting && _plantAge > 0 && _plantAge < 50) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${50 - _plantAge} hari lagi sampai panen',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: _growthPercentage, // Gunakan _growthPercentage
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _plantAge >= 45 ? Colors.orange : Colors.blue,
                    ),
                    minHeight: 2,
                  ),
                ],
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
                ] else if (_hasStartedPlanting && _plantAge >= 50) ...[
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
                        Icon(Icons.agriculture, size: 16, color: Colors.white),
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
          if (_hasStartedPlanting) ...[
            IconButton(
              onPressed: () {
                _showResetPlantDialog();
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
    ]);
  }

  // Confetti Widget
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
              (random.nextDouble() - 0.5) * 100 * value,
              value * 400,
            ),
            child: Transform.rotate(
              angle: value * 6.28 * 3,
              child: Opacity(
                opacity: 1 - (value * 0.8),
                child: Container(
                  width: random.nextDouble() * 6 + 4,
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

  // Summary Item Widget
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

  // Carousel Widget
  Widget _buildCarouselPanduan() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  // Transaction Item Widget
  Widget _buildTransactionItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
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

  // Bottom Navigation Widget
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
