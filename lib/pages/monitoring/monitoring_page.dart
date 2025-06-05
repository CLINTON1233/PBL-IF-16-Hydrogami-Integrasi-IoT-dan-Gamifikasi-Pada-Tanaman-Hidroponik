import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:application_hydrogami/services/notifikasi_services.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int _bottomNavCurrentIndex = 0;

  DateTime? _lastAlertTime;

  // MQTT Client
  late MqttServerClient client;
  final String broker = '10.170.5.195';
  final String clientIdentifier = 'flutter_client';

  // Data sensor real-time
  double currentTDS = 0;
  double currentPH = 0;
  double currentTemp = 0;
  double currentHumidity = 0;
  double currentLight = 0;
  int currentSoilMoisture = 0;

  // Data untuk grafik TDS
  List<FlSpot> chartDataTDS = [];
  List<FlSpot> chartDataPH = [];

  int timeCounter = 0;
  final int maxDataPoints = 10;

  // bool _showTDS = true; // Toggle untuk grafik (pakai TDS sebagai default)
  // String _selectedTab = 'Grafik TDS'; // Tab yang aktif

  @override
  void initState() {
    super.initState();
    // Inisialisasi chart kosong
    for (int i = 0; i < maxDataPoints; i++) {
      chartDataTDS.add(FlSpot(i.toDouble(), 0));
      chartDataPH.add(FlSpot(i.toDouble(), 0));
    }
    setupMqttClient();
    connectClient();
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  // Setup MQTT Client
  void setupMqttClient() {
    client = MqttServerClient.withPort(broker, clientIdentifier, 1883);
    client.logging(on: true);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
    client.keepAlivePeriod = 60;
    client.onBadCertificate = (cert) => true;
  }

  List<SnackBar> _snackBarQueue = [];
  bool _isSnackBarShowing = false;

  void _showAlert(
      BuildContext context, String title, String message, Color color) {
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: const Duration(seconds: 10),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    );

    _snackBarQueue.add(snackBar);
    _processSnackBarQueue(context);
  }

  void _processSnackBarQueue(BuildContext context) {
    if (!_isSnackBarShowing && _snackBarQueue.isNotEmpty) {
      _isSnackBarShowing = true;
      final snackBar = _snackBarQueue.removeAt(0);

      ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
        _isSnackBarShowing = false;
        _processSnackBarQueue(context);
      });
    }
  }

  // Connect ke MQTT Broker
  void connectClient() async {
    try {
      await client.connect('try', 'try');
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      subscribeToTopic();
    } else {
      print('ERROR: MQTT client connection failed - disconnecting');
      client.disconnect();
    }
  }

  // Subscribe ke topic
  void subscribeToTopic() {
    const topic = 'sensor/data';
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message: $payload');

      // Parse JSON data
      Map<String, dynamic> data = jsonDecode(payload);

      setState(() {
        currentTDS = data['tds']?.toDouble() ?? 0;
        currentPH = data['ph']?.toDouble() ?? 0;
        currentTemp = data['temperature']?.toDouble() ?? 0;
        currentHumidity = data['humidity']?.toDouble() ?? 0;
        currentLight = data['light']?.toDouble() ?? 0;
        currentSoilMoisture = data['soil_moisture']?.toInt() ?? 0;

        // Update grafik
        updateCharts(currentTDS, currentPH);
      });
    });
  }

  // Update data grafik
  void updateCharts(double tdsValue, double phValue) {
    setState(() {
      timeCounter++;

      // Geser data ke kiri dan tambahkan data baru di akhir
      for (int i = 0; i < maxDataPoints - 1; i++) {
        chartDataTDS[i] = FlSpot(i.toDouble(), chartDataTDS[i + 1].y);
        chartDataPH[i] = FlSpot(i.toDouble(), chartDataPH[i + 1].y);
      }

      // Tambahkan data baru
      chartDataTDS[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), tdsValue);
      chartDataPH[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), phValue);
    });
  }

  // MQTT Callback functions
  void onConnected() {
    print('Connected to MQTT broker');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void onSubscribeFail(String topic) {
    print('Failed to subscribe to topic: $topic');
  }

  void pong() {
    print('Ping response received');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 45,
              height: 45,
            ),
            const SizedBox(width: 10),
            Text(
              'Monitoring Real-Time',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
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
      // Menggunakan Stack untuk menumpuk konten dan bottom navigation bar
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content dalam ListView untuk memungkinkan scrolling
            ListView(
              padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 20.0,
                  bottom:
                      30.0 // Tambahkan padding di bawah untuk BottomNavigationBar
                  ),
              children: [
                _buildPHChart(),
                const SizedBox(height: 24),
                _buildMainChart(),
                const SizedBox(height: 24),
                _buildSensorCardsGrid(),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Widget baru untuk grafik pH di bagian atas
  Widget _buildPHChart() {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'pH Levels',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current pH: ${currentPH.toStringAsFixed(1)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < maxDataPoints &&
                            index % 2 == 0) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              index.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: maxDataPoints.toDouble() - 1,
                minY: 0,
                maxY: 14,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartDataPH,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.purple,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainChart() {
    return Container(
      width: double.infinity,
      height: 200, // Reduced from 220 to 200
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TDS Levels',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8), // Reduced from 16 to 8
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 400,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22, // Reduced from 30 to 22
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 &&
                            index < maxDataPoints &&
                            index % 2 == 0) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              index.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35, // Reduced from 40 to 35
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: maxDataPoints.toDouble() - 1,
                minY: 0,
                maxY: 2000,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartDataTDS,
                    isCurved: true,
                    color: Colors
                        .blue, // Changed color to blue to distinguish from pH chart
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3, // Reduced from 4 to 3
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor:
                              Colors.blue, // Changed color to match line
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue
                          .withOpacity(0.1), // Changed color to match line
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCardsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor Readings',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildSensorDetailCard(
              title: 'TDS Level',
              value: currentTDS.toStringAsFixed(1),
              unit: 'ppm',
              icon: Icons.opacity,
              color: Colors.blue.shade50,
              iconColor: Colors.blue,
            ),
            _buildSensorDetailCard(
              title: 'pH Level',
              value: currentPH.toStringAsFixed(1),
              unit: 'pH',
              icon: Icons.blur_circular,
              color: Colors.purple.shade50,
              iconColor: Colors.purple,
            ),
            _buildSensorDetailCard(
              title: 'Suhu',
              value: currentTemp.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.orange.shade50,
              iconColor: Colors.orange,
            ),
            _buildSensorDetailCard(
              title: 'Kelembaban Udara',
              value: currentHumidity.toStringAsFixed(2),
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.teal.shade50,
              iconColor: Colors.teal,
            ),
            _buildSensorDetailCard(
              title: 'Kelembaban Tanah',
              value: currentSoilMoisture.toStringAsFixed(0),
              unit: '%',
              icon: Icons.landscape,
              color: Colors.brown.shade50,
              iconColor: Colors.brown,
            ),
            _buildSensorDetailCard(
              title: 'Intensitas Cahaya',
              value: currentLight.toStringAsFixed(2),
              unit: 'Lux',
              icon: Icons.light_mode,
              color: Colors.amber.shade50,
              iconColor: Colors.amber,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorDetailCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 18,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unit,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
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

  // Function to evaluate sensor status
  Color determineSensorStatus(String sensorType, double value) {
    switch (sensorType) {
      case 'Suhu':
        if (value < 10 || value > 40) return Colors.red;
        if ((value >= 15 && value <= 20) || (value >= 31 && value <= 35))
          return Colors.yellow;
        if (value >= 19 && value <= 30) return Colors.green;
        return Colors.black;

      case 'TDS':
        if (value < 300 || value > 2000) return Colors.red;
        if ((value >= 500 && value <= 700) || (value >= 1500 && value <= 2000))
          return Colors.yellow;
        if (value >= 800 && value <= 1500) return Colors.green;
        return Colors.black;

      case 'pH':
        if (value < 4.0 || value > 7.5) return Colors.red;
        if ((value >= 5.0 && value <= 5.5) || (value >= 6.7 && value <= 7.0))
          return Colors.yellow;
        if (value >= 5.5 && value <= 6.5) return Colors.green;
        return Colors.black;

      case 'Kelembaban Tanah':
        if (value <= 0 || value > 1000) return Colors.red;
        if ((value >= 300 && value <= 400) || (value >= 70 && value <= 80))
          return Colors.yellow;
        if (value >= 500 && value <= 900) return Colors.green;
        return Colors.black;

      case 'Kelembaban Udara':
        if (value < 30 || value > 90) return Colors.red;
        if ((value >= 40 && value <= 50) || (value >= 80 && value <= 90))
          return Colors.yellow;
        if (value >= 60 && value <= 75) return Colors.green;
        return Colors.black;

      case 'Intensitas Cahaya':
        if (value < 1000 || value > 50000) return Colors.red;
        if ((value >= 2000 && value <= 5000) ||
            (value >= 30000 && value <= 40000)) return Colors.yellow;
        if (value >= 10000 && value <= 25000) return Colors.green;
        return Colors.black;

      default:
        return Colors.black;
    }
  }
}

// Data class untuk grafik
class _ChartData {
  _ChartData(this.x, this.y);
  final int x;
  final double y;
}
