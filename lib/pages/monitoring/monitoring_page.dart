import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:application_hydrogami/services/monitoring_subscriber.dart';
import 'dart:math';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int _bottomNavCurrentIndex = 0;

  late MQTTSubscriber mqttSubscriber;
  Map<String, dynamic> sensorData = {
    'temperature': 0.0,
    'humidity': 0.0,
    'light': 0.0,
    'soil_moisture': 0,
    'tds': 0.0,
    'ph': 0.0,
  };

  static const int maxDataPoints = 30;

  List<FlSpot> tdsSpots = [];
  List<FlSpot> phSpots = [];
  int dataPoint = 0;

  @override
  void initState() {
    super.initState();
    mqttSubscriber = MQTTSubscriber(onDataReceived: updateSensorData);
    mqttSubscriber.initialize();
  }

  @override
  void dispose() {
    mqttSubscriber.disconnect();
    super.dispose();
  }

  void updateSensorData(Map<String, dynamic> data) {
    setState(() {
      sensorData = data;
      final timestamp =
          DateTime.now().millisecondsSinceEpoch / 1000; // Konversi ke detik

      // Update TDS spots
      if (tdsSpots.length >= maxDataPoints) {
        tdsSpots.removeAt(0);
        // Geser semua titik ke kiri
        for (int i = 0; i < tdsSpots.length; i++) {
          tdsSpots[i] = FlSpot(i.toDouble(), tdsSpots[i].y);
        }
      }
      tdsSpots.add(FlSpot(tdsSpots.length.toDouble(), data['tds'].toDouble()));

      // Update pH spots
      if (phSpots.length >= maxDataPoints) {
        phSpots.removeAt(0);
        // Geser semua titik ke kiri
        for (int i = 0; i < phSpots.length; i++) {
          phSpots[i] = FlSpot(i.toDouble(), phSpots[i].y);
        }
      }
      phSpots.add(FlSpot(phSpots.length.toDouble(), data['ph'].toDouble()));
    });
  }

  LineChartData _createChartData(List<FlSpot> spots, {double interval = 1.0}) {
    final minY = spots.isEmpty ? 0.0 : spots.map((spot) => spot.y).reduce(min);
    final maxY = spots.isEmpty ? 10.0 : spots.map((spot) => spot.y).reduce(max);
    final padding = (maxY - minY) * 0.1;

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 2,
          color: Colors.black,
          dotData: const FlDotData(show: true), // Tampilkan titik data
          belowBarData: BarAreaData(
            show: true,
            color: Colors.black.withOpacity(0.1),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        show: true,
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, titleMeta) {
              if (value % 5 == 0) {
                // Tampilkan label setiap 5 detik
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, titleMeta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 40,
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        horizontalInterval: interval,
        verticalInterval: 5, // Grid vertikal setiap 5 detik
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.black12,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.black12,
            strokeWidth: 1,
          );
        },
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black12),
      ),
      minY: minY - padding,
      maxY: maxY + padding,
      clipData: FlClipData.all(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Text(
          'Monitoring Real-Time',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Grafik TDS
            Container(
              margin: const EdgeInsets.all(12.0),
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F9FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'GRAFIK TDS AIR',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 150, // Tinggi grafik ditambah
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: tdsSpots,
                            isCurved: true,
                            barWidth: 2,
                            color: Colors.black,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, titleMeta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, titleMeta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(
                          show: true,
                          horizontalInterval: 100,
                          verticalInterval: 1,
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grafik pH
            Container(
              margin: const EdgeInsets.all(12.0),
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'GRAFIK PH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  SizedBox(
                    height: 150,
                    width: MediaQuery.of(context).size.width * 0.9,
                    child: LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: phSpots,
                            isCurved: true,
                            barWidth: 2,
                            color: Colors.black,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, titleMeta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, titleMeta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(
                          show: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data Monitoring
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        title: 'TDS', // Total Dissolved Solids
                        value: sensorData['tds']?.toStringAsFixed(1) ?? '0',
                        unit: 'ppm', // Parts Per Million
                      ),
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        title: 'Suhu', // Temperature
                        value: sensorData['temperature']?.toStringAsFixed(1) ??
                            '0',
                        unit: '°C', // Degrees Celsius
                      ),
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        title: 'pH',
                        value: sensorData['ph']?.toStringAsFixed(1) ?? '0',
                        unit: '', // pH tidak memerlukan satuan
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
// Row 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMonitoringCard(
                        icon: Icons.water_drop,
                        title: 'Kelembaban Tanah', // Soil Moisture
                        value:
                            sensorData['soil_moisture']?.toStringAsFixed(1) ??
                                '0',
                        unit: '%', // Persentase
                      ),
                      _buildMonitoringCard(
                        icon: Icons.water_drop,
                        title: 'Kelembaban Udara', // Air Humidity
                        value:
                            sensorData['humidity']?.toStringAsFixed(1) ?? '0',
                        unit: '%', // Persentase
                      ),
                      _buildMonitoringCard(
                        icon: Icons.brightness_high,
                        title: 'Intensitas Cahaya', // Light Intensity
                        value: sensorData['light']?.toStringAsFixed(1) ?? '0',
                        unit: 'lux', // Illuminance
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25.0),
            // Status Monitoring
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusIndicator(
                    color: const Color(0xFF4CAF50),
                    label: 'Optimal',
                  ),
                  _buildStatusIndicator(
                    color: const Color(0xFFFFEB3B),
                    label: 'Perlu Penyesuaian',
                  ),
                  _buildStatusIndicator(
                    color: const Color(0xFFF44336),
                    label: 'Bahaya/Kritis',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Fungsi untuk membuat card monitoring
  Widget _buildMonitoringCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    double width = 100,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32.0,
            color: const Color(0xFF24D17E),
          ),
          const SizedBox(height: 8.0),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '$value $unit',
            style: const TextStyle(
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membuat indikator status
  Widget _buildStatusIndicator({
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 16.0,
          height: 16.0,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
          ),
        ),
      ],
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
