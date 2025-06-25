import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:application_hydrogami/services/notifikasi_services.dart';
import 'package:application_hydrogami/services/sensor_data_service.dart';
import 'package:application_hydrogami/models/sensor_data_model.dart';
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
  final SensorDataService _sensorDataService = SensorDataService();

  // MQTT Client Configuration
  late MqttServerClient client;
  final String broker = 'broker.hivemq.com'; // Broker online gratis
  final int port = 1883;
  final String clientIdentifier =
      'hydrogami_flutter_client_${DateTime.now().millisecondsSinceEpoch}'; // Client ID unik
  final String topic =
      'hydrogami/sensor/data'; // Sesuai dengan topik di Arduino

  // Data sensor real-time
  double currentTDS = 0;
  double currentPH = 0;
  double currentTemp = 0;
  double currentHumidity = 0;
  double currentLight = 0;
  int currentSoilMoisture = 0;
  int relayWater = 0;
  int relayAbMix = 0;
  int relayPhUp = 0;
  int relayPhDown = 0;

  // Data untuk grafik
  List<FlSpot> chartDataTDS = [];
  List<FlSpot> chartDataPH = [];
  List<FlSpot> chartDataTemp = [];
  List<FlSpot> chartDataHumidity = [];

  int timeCounter = 0;
  final int maxDataPoints = 10;

  @override
  void initState() {
    super.initState();
    // Inisialisasi chart kosong
    for (int i = 0; i < maxDataPoints; i++) {
      chartDataTDS.add(FlSpot(i.toDouble(), 0));
      chartDataPH.add(FlSpot(i.toDouble(), 0));
      chartDataTemp.add(FlSpot(i.toDouble(), 0));
      chartDataHumidity.add(FlSpot(i.toDouble(), 0));
    }
    _initMqttClient();
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  // Inisialisasi MQTT Client
  void _initMqttClient() {
    client = MqttServerClient(broker, clientIdentifier);
    client.port = port;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;

    // Set secure jika diperlukan (untuk broker yang membutuhkan SSL)
    // client.secure = true;
    // client.securityContext = SecurityContext.defaultContext;

    // Connect ke broker
    _connectToBroker();
  }

  Future<void> _connectToBroker() async {
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
      // Coba reconnect setelah 5 detik
      await Future.delayed(Duration(seconds: 5));
      _connectToBroker();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      _subscribeToTopic();
    } else {
      print('ERROR: MQTT client connection failed - disconnecting');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('Connected to MQTT broker');
  }

  void _onDisconnected() {
    print('Disconnected from MQTT broker');
    // Coba reconnect setelah 3 detik
    Future.delayed(Duration(seconds: 3), () {
      _connectToBroker();
    });
  }

  void _onSubscribed(String topic) {
    print('Subscribed to topic: $topic');
  }

  void _pong() {
    print('Ping response received');
  }

  void _subscribeToTopic() {
    client.subscribe(topic, MqttQos.atMostOnce);

    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) async {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received MQTT message: $payload'); // Debug logging

      try {
        // Parse JSON data
        Map<String, dynamic> data = jsonDecode(payload);

        // Update state dengan data baru
        setState(() {
          currentTDS = data['tds']?.toDouble() ?? 0;
          currentPH = data['ph']?.toDouble() ?? 0;
          currentTemp = data['temperature']?.toDouble() ?? 0;
          currentHumidity = data['humidity']?.toDouble() ?? 0;
          currentLight = data['light']?.toDouble() ?? 0;
          currentSoilMoisture = data['soil_moisture']?.toInt() ?? 0;
          relayWater = data['relay_water']?.toInt() ?? 0;
          relayAbMix = data['relay_ab_mix']?.toInt() ?? 0;
          relayPhUp = data['relay_ph_up']?.toInt() ?? 0;
          relayPhDown = data['relay_ph_down']?.toInt() ?? 0;

          // Update grafik
          _updateCharts();
        });

        // Buat objek SensorData dari data yang diterima
        final sensorData = SensorData(
          temperature: currentTemp,
          humidity: currentHumidity,
          light: currentLight,
          soilMoisture: currentSoilMoisture,
          tds: currentTDS,
          ph: currentPH,
        );

        // Kirim data ke API (dengan error handling)
        try {
          final success = await _sensorDataService.sendSensorData(sensorData);
          if (success) {
            print('Data successfully sent to API');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Data terkirim ke server'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            print('Failed to send data to API');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mengirim data ke server'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (apiError) {
          print('API Error: $apiError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error API: $apiError'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        // Cek notifikasi alert
        if (mounted) {
          _checkForAlerts(context);
        }
      } catch (e) {
        print('Error processing MQTT message: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Format data sensor tidak valid'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _sendDataToApi() async {
    final sensorData = SensorData(
      temperature: currentTemp,
      humidity: currentHumidity,
      light: currentLight,
      soilMoisture: currentSoilMoisture,
      tds: currentTDS,
      ph: currentPH,
    );

    try {
      final success = await _sensorDataService.sendSensorData(sensorData);
      if (success) {
        print('Data berhasil dikirim ke API');
      } else {
        print('Gagal mengirim data ke API');
      }
    } catch (e) {
      print('Error saat mengirim data: $e');
    }
  }

  void _updateCharts() {
    setState(() {
      timeCounter++;

      // Geser data ke kiri
      for (int i = 0; i < maxDataPoints - 1; i++) {
        chartDataTDS[i] = FlSpot(i.toDouble(), chartDataTDS[i + 1].y);
        chartDataPH[i] = FlSpot(i.toDouble(), chartDataPH[i + 1].y);
        chartDataTemp[i] = FlSpot(i.toDouble(), chartDataTemp[i + 1].y);
        chartDataHumidity[i] = FlSpot(i.toDouble(), chartDataHumidity[i + 1].y);
      }

      // Tambahkan data baru di akhir
      chartDataTDS[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentTDS);
      chartDataPH[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentPH);
      chartDataTemp[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentTemp);
      chartDataHumidity[maxDataPoints - 1] =
          FlSpot((maxDataPoints - 1).toDouble(), currentHumidity);
    });
  }

  void _checkForAlerts(BuildContext context) {
    final now = DateTime.now();
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!) < Duration(seconds: 30)) {
      return; // Jangan tampilkan alert terlalu sering
    }

    if (currentPH < 5.0 || currentPH > 7.0) {
      final message =
          'Nilai pH ${currentPH.toStringAsFixed(1)} di luar range optimal (5.5-6.5)!';
      _showAlert(context, 'Peringatan pH', message, Colors.orange);
      _sendNotification('pH Sensor', message, 'warning');
      _lastAlertTime = now;
    }

    if (currentTDS < 300 || currentTDS > 1500) {
      final message =
          'Nilai TDS ${currentTDS.toStringAsFixed(0)} ppm di luar range optimal (800-1500 ppm)!';
      _showAlert(context, 'Peringatan Nutrisi', message, Colors.orange);
      _sendNotification('TDS Sensor', message, 'warning');
      _lastAlertTime = now;
    }

    if (currentTemp < 15 || currentTemp > 35) {
      final message =
          'Suhu ${currentTemp.toStringAsFixed(1)}°C di luar range optimal (20-30°C)!';
      _showAlert(context, 'Peringatan Suhu', message, Colors.orange);
      _sendNotification('Suhu Sensor', message, 'danger');
      _lastAlertTime = now;
    }
  }

// Fungsi baru untuk mengirim notifikasi
  Future<void> _sendNotification(
      String sensorType, String message, String status) async {
    try {
      final success = await LayananNotifikasi.kirimNotifikasi(
        idSensor: '1', // Anda bisa menyesuaikan ID sensor
        jenisSensor: sensorType,
        pesan: message,
        status: status,
      );

      if (success) {
        print('Notifikasi berhasil dikirim');
      } else {
        print('Gagal mengirim notifikasi');
      }
    } catch (e) {
      print('Error mengirim notifikasi: $e');
    }
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
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 20.0,
                bottom: 30.0,
              ),
              children: [
                _buildPHChart(),
                const SizedBox(height: 24),
                _buildMainChart(),
                const SizedBox(height: 24),
                _buildTemperatureHumidityChart(),
                const SizedBox(height: 24),
                _buildSensorCardsGrid(),
                const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildPHChart() {
    return _buildChart(
      title: 'pH Levels',
      currentValue: currentPH,
      unit: 'pH',
      chartData: chartDataPH,
      color: Colors.purple,
      minY: 0,
      maxY: 14,
      interval: 2,
    );
  }

  Widget _buildMainChart() {
    return _buildChart(
      title: 'TDS Levels',
      currentValue: currentTDS,
      unit: 'ppm',
      chartData: chartDataTDS,
      color: Colors.blue,
      minY: 0,
      maxY: 2000,
      interval: 500,
    );
  }

  Widget _buildTemperatureHumidityChart() {
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
            'Suhu & Kelembaban',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suhu: ${currentTemp.toStringAsFixed(1)}°C | Kelembaban: ${currentHumidity.toStringAsFixed(1)}%',
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
                  horizontalInterval: 10,
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
                      interval: 10,
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
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartDataTemp,
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.orange,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: chartDataHumidity,
                    isCurved: true,
                    color: Colors.teal,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.teal,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.teal.withOpacity(0.1),
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

  Widget _buildChart({
    required String title,
    required double currentValue,
    required String unit,
    required List<FlSpot> chartData,
    required Color color,
    required double minY,
    required double maxY,
    required double interval,
  }) {
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
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current: ${currentValue.toStringAsFixed(1)} $unit',
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
                  horizontalInterval: interval,
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
                      interval: interval,
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
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
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
              status: determineSensorStatus('TDS', currentTDS),
            ),
            _buildSensorDetailCard(
              title: 'pH Level',
              value: currentPH.toStringAsFixed(1),
              unit: 'pH',
              icon: Icons.blur_circular,
              color: Colors.purple.shade50,
              iconColor: Colors.purple,
              status: determineSensorStatus('pH', currentPH),
            ),
            _buildSensorDetailCard(
              title: 'Suhu',
              value: currentTemp.toStringAsFixed(1),
              unit: '°C',
              icon: Icons.thermostat,
              color: Colors.orange.shade50,
              iconColor: Colors.orange,
              status: determineSensorStatus('Suhu', currentTemp),
            ),
            _buildSensorDetailCard(
              title: 'Kelembaban Udara',
              value: currentHumidity.toStringAsFixed(1),
              unit: '%',
              icon: Icons.water_drop,
              color: Colors.teal.shade50,
              iconColor: Colors.teal,
              status:
                  determineSensorStatus('Kelembaban Udara', currentHumidity),
            ),
            _buildSensorDetailCard(
              title: 'Kelembaban Tanah',
              value: currentSoilMoisture.toString(),
              unit: '%',
              icon: Icons.landscape,
              color: Colors.brown.shade50,
              iconColor: Colors.brown,
              status: determineSensorStatus(
                  'Kelembaban Tanah', currentSoilMoisture.toDouble()),
            ),
            _buildSensorDetailCard(
              title: 'Intensitas Cahaya',
              value: currentLight.toStringAsFixed(1),
              unit: 'Lux',
              icon: Icons.light_mode,
              color: Colors.amber.shade50,
              iconColor: Colors.amber,
              status: determineSensorStatus('Intensitas Cahaya', currentLight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRelayIndicator({
    required String label,
    required bool status,
    required Color activeColor,
  }) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: status ? activeColor : Colors.grey[300],
            border: Border.all(
              color: Colors.grey[500]!,
              width: 1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          status ? 'ON' : 'OFF',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey[600],
          ),
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
    required Color status,
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
                  const SizedBox(height: 4),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: status,
                      border: Border.all(
                        color: Colors.grey[500]!,
                        width: 1,
                      ),
                    ),
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
        if (value <= 0 || value > 100) return Colors.red;
        if ((value >= 30 && value <= 40) || (value >= 70 && value <= 80))
          return Colors.yellow;
        if (value >= 50 && value <= 70) return Colors.green;
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

class _ChartData {
  _ChartData(this.x, this.y);
  final int x;
  final double y;
}
