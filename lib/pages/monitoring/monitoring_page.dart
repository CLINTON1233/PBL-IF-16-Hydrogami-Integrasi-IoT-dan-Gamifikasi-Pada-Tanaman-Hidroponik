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
  final String broker = '192.168.114.189';
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

// Fungsi untuk membangun grafik TDS yang lebih informatif
  Widget buildTDSChart() {
    Color determineTDSLineColor(double tdsValue) {
      if (tdsValue < 300 || tdsValue > 2000) return Colors.red; // Bahaya/Kritis
      if ((tdsValue >= 500 && tdsValue <= 700) ||
          (tdsValue >= 1500 && tdsValue <= 2000))
        return Colors.yellow; // Perlu Penyesuaian
      if (tdsValue >= 800 && tdsValue <= 1500) return Colors.green; // Optimal
      return Colors.grey; // Default
    }

    Color lineColor = determineTDSLineColor(currentTDS);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik Total Dissolved Solids (TDS)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartDataTDS,
                      isCurved: true,
                      barWidth: 3,
                      color: lineColor, // Warna garis berubah sesuai kondisi
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, titleMeta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
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
                                fontSize: 10, color: Colors.black54),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 2000, // Sesuaikan range TDS
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Fungsi untuk membangun grafik pH yang lebih informatif
  Widget buildPHChart() {
    Color determinePHLineColor(double phValue) {
      if (phValue < 4.5 || phValue > 10.5) return Colors.red; // Bahaya/Kritis
      if ((phValue >= 5.0 && phValue <= 5.5) ||
          (phValue >= 6.5 && phValue <= 7.0))
        return Colors.yellow; // Perlu Penyesuaian
      if (phValue >= 5.5 && phValue <= 6.5) return Colors.green; // Optimal
      return Colors.grey; // Default
    }

    Color lineColor = determinePHLineColor(currentPH);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grafik pH (Tingkat Keasaman)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartDataPH,
                      isCurved: true,
                      barWidth: 3,
                      color: lineColor, // Warna garis berubah sesuai kondisi
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, titleMeta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.black54),
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
                                fontSize: 10, color: Colors.black54),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: 14, // Sesuaikan range pH
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Widget untuk membuat item legenda
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
      ],
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
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10.0),
            // Grafik TDS
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.white,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Total Padatan Terlarut (TDS)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      height: 150,
                      width: MediaQuery.of(context).size.width * 0.82,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartDataTDS,
                              isCurved: true,
                              barWidth: 2,
                              color: Colors.green,
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
            ),

            const SizedBox(height: 10.0),

// Grafik pH
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.white,
              child: Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                padding: const EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'pH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SizedBox(
                      height: 150,
                      width: MediaQuery.of(context).size.width * 0.82,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartDataPH,
                              isCurved: true,
                              barWidth: 2,
                              color: Colors.green,
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
                        title: 'TDS',
                        value: currentTDS.toStringAsFixed(1),
                        unit: 'ppm',
                      ),
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        title: 'Suhu',
                        value: currentTemp.toStringAsFixed(1),
                        unit: '°C',
                      ),
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        title: 'PH',
                        value: currentPH.toStringAsFixed(1),
                        unit: 'ph',
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
                        title: 'Kelembaban Tanah',
                        value: currentSoilMoisture.toStringAsFixed(1),
                        unit: '%',
                      ),
                      _buildMonitoringCard(
                        icon: Icons.water_drop,
                        title: 'Kelembaban Udara',
                        value: currentHumidity.toStringAsFixed(1),
                        unit: '%',
                      ),
                      _buildMonitoringCard(
                        icon: Icons.brightness_high,
                        title: 'Intensitas Cahaya',
                        value: currentLight.toStringAsFixed(1),
                        unit: 'Lux',
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

  Widget _buildMonitoringCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    double width = 100,
  }) {
    Color determineBackgroundColor(
        BuildContext context, String title, double value) {
      // Function to show alert based on sensor conditions
      void jadwalkanAlertSensor(
          String pesan, Color warna, String jenisSensor, String status) {
        // Cek apakah sudah cukup waktu berlalu sejak alert terakhir
        final sekarang = DateTime.now();
        if (_lastAlertTime == null ||
            sekarang.difference(_lastAlertTime!) > const Duration(minutes: 5)) {
          _lastAlertTime = sekarang;

          // Kirim notifikasi ke backend
          LayananNotifikasi.kirimNotifikasi(
            idSensor: '1', // Ganti dengan ID sensor yang sebenarnya
            jenisSensor: jenisSensor,
            pesan: pesan,
            status: status,
          ).then((berhasil) {
            if (berhasil) {
              debugPrint('Notifikasi berhasil disimpan ke database');
            } else {
              debugPrint('Gagal menyimpan notifikasi ke database');
            }
          });

          // Tampilkan alert lokal
          if (context.mounted) {
            // Gunakan post frame callback untuk menunda pemanggilan showSnackBar
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAlert(
                context,
                'Peringatan Sensor $title',
                pesan,
                warna,
              );
            });
          }
        }
      }

      switch (title) {
        case 'Suhu':
          if (value < 10) {
            jadwalkanAlertSensor(
              'Suhu terlalu rendah ($value°C). Suhu optimal adalah 19-27°C',
              Colors.red,
              'Suhu',
              'Kritis',
            );
            return Colors.red;
          }
          if (value > 40) {
            jadwalkanAlertSensor(
              'Suhu terlalu tinggi ($value°C). Suhu optimal adalah 19-27°C',
              Colors.red,
              'Suhu',
              'Kritis',
            );
            return Colors.red;
          }
          if ((value >= 15 && value <= 20) || (value >= 31 && value <= 35)) {
            jadwalkanAlertSensor(
              'Suhu mendekati batas ($value°C). Pertahankan suhu antara 19-27°C',
              Colors.orange,
              'Suhu',
              'Peringatan',
            );
            return Colors.yellow;
          }
          if (value >= 19 && value <= 30) return Colors.green;
          break;

        case 'TDS':
          if (value < 300) {
            jadwalkanAlertSensor(
              'Kadar nutrisi terlalu rendah ($value ppm). Level optimal adalah 800-1500 ppm',
              Colors.red,
              'TDS',
              'Kritis',
            );
            return Colors.red;
          }
          if (value > 2000) {
            jadwalkanAlertSensor(
              'Kadar nutrisi terlalu tinggi ($value ppm). Level optimal adalah 800-1500 ppm',
              Colors.red,
              'TDS',
              'Kritis',
            );
            return Colors.red;
          }
          if ((value >= 500 && value <= 700) ||
              (value >= 1500 && value <= 2000)) {
            jadwalkanAlertSensor(
              'Kadar nutrisi mendekati batas ($value ppm). Pertahankan level antara 800-1500 ppm',
              Colors.orange,
              'TDS',
              'Peringatan',
            );
            return Colors.yellow;
          }
          if (value >= 800 && value <= 1500) return Colors.green;
          break;

        case 'PH':
          if (value < 4.0) {
            jadwalkanAlertSensor(
              'pH terlalu asam ($value). Level optimal adalah 5.5-6.5',
              Colors.red,
              'PH',
              'Kritis',
            );
            return Colors.red;
          }
          if (value > 6.5) {
            jadwalkanAlertSensor(
              'pH terlalu basa ($value). Level optimal adalah 5.5-6.5',
              Colors.red,
              'PH',
              'Kritis',
            );
            return Colors.red;
          }
          if ((value >= 5.0 && value <= 5.5) ||
              (value >= 6.7 && value <= 7.0)) {
            jadwalkanAlertSensor(
              'pH mendekati batas ($value). Pertahankan pH antara 5.5-6.5',
              Colors.orange,
              'PH',
              'Peringatan',
            );
            return Colors.yellow;
          }
          if (value >= 5.5 && value <= 6.5) return Colors.green;
          break;

        case 'Kelembaban Tanah':
          if (value == 0.0 || value < 0 || value > 1000) {
            jadwalkanAlertSensor(
              'Kelembaban tanah tidak normal ($value%). Level optimal adalah 500-900%',
              Colors.red,
              'Kelembaban Tanah',
              'Kritis',
            );
            return Colors.red;
          }
          if ((value >= 300 && value <= 400) || (value >= 70 && value <= 80)) {
            jadwalkanAlertSensor(
              'Kelembaban tanah mendekati batas ($value%). Pertahankan level antara 500-900%',
              Colors.orange,
              'Kelembaban Tanah',
              'Peringatan',
            );
            return Colors.yellow;
          }
          if (value >= 500 && value <= 900) return Colors.green;
          break;

        case 'Kelembaban Udara':
          if (value < 30) {
            jadwalkanAlertSensor(
              'Kelembaban udara terlalu rendah ($value%). Level optimal adalah 60-75%',
              Colors.red,
              'Kelembaban Udara',
              'Kritis',
            );
            return Colors.red;
          }
          if (value > 90) {
            jadwalkanAlertSensor(
              'Kelembaban udara terlalu tinggi ($value%). Level optimal adalah 60-75%',
              Colors.red,
              'Kelembaban Udara',
              'Kritis',
            );
            return Colors.red;
          }
          if ((value >= 40 && value <= 50) || (value >= 80 && value <= 90)) {
            jadwalkanAlertSensor(
              'Kelembaban udara mendekati batas ($value%). Pertahankan level antara 60-75%',
              Colors.orange,
              'Kelembaban Udara',
              'Peringatan',
            );
            return Colors.yellow;
          }
          if (value >= 60 && value <= 75) return Colors.green;
          break;

        case 'Intensitas Cahaya':
          if (value < 1000) {
            jadwalkanAlertSensor(
              'Intensitas cahaya terlalu rendah ($value Lux). Level optimal adalah 10000-25000 Lux',
              Colors.red,
              'Intensitas Cahaya',
              'Kritis',
            );
            return Colors.red;
          }
          if (value > 50000) {
            jadwalkanAlertSensor(
              'Intensitas cahaya terlalu tinggi ($value Lux). Level optimal adalah 10000-25000 Lux',
              Colors.red,
              'Intensitas Cahaya',
              'Kritis',
            );
            return Colors.red;
          }
          if ((value >= 2000 && value <= 5000) ||
              (value >= 30000 && value <= 40000)) {
            jadwalkanAlertSensor(
              'Intensitas cahaya mendekati batas ($value Lux). Pertahankan level antara 10000-25000 Lux',
              Colors.orange,
              'Intensitas Cahaya',
              'Peringatan',
            );
            return Colors.yellow;
          }
          if (value >= 10000 && value <= 25000) return Colors.green;
          break;
      }
      return Colors.grey;
    }

    double numericValue = double.tryParse(value) ?? 0;
    Color backgroundColor =
        determineBackgroundColor(context, title, numericValue);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32.0,
            color: backgroundColor,
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

// Data class untuk grafik
class _ChartData {
  _ChartData(this.x, this.y);
  final int x;
  final double y;
}
