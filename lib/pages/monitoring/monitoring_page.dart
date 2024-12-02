import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart'; // Import library chart

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  int _bottomNavCurrentIndex = 0;

  // Data untuk grafik TDS
  List<FlSpot> chartDataTDS = [
    const FlSpot(1, 400),
    const FlSpot(2, 500),
    const FlSpot(3, 600),
    const FlSpot(4, 700),
    const FlSpot(5, 650),
    const FlSpot(6, 800),
    const FlSpot(7, 900),
    const FlSpot(8, 950),
    const FlSpot(9, 950),
    const FlSpot(10, 900),
  ];

  // Data untuk grafik pH
  List<FlSpot> chartDataPH = [
    const FlSpot(1, 7),
    const FlSpot(2, 6.5),
    const FlSpot(3, 6),
    const FlSpot(4, 5.5),
    const FlSpot(5, 5.8),
    const FlSpot(6, 6),
    const FlSpot(7, 6.5),
    const FlSpot(8, 6.8),
    const FlSpot(9, 6.8),
    const FlSpot(10, 6.5),
  ];
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
                    'TDS Tanaman Pakcoy Selama 10 Hari',
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
                            spots: chartDataTDS,
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
                    'PH Tanaman Pakcoy Selama 10 Hari',
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
                            spots: chartDataPH,
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
                        title: 'TDS',
                        value: '256',
                        unit: 'PPM',
                      ),
                      _buildMonitoringCard(
                        icon: Icons.water_drop,
                        title: 'Air',
                        value: '16',
                        unit: 'Lux',
                      ),
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        title: 'PH',
                        value: '7.2',
                        unit: 'PH',
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
                        title: 'Kelembaban',
                        value: '62',
                        unit: '%',
                        width: 150,
                      ),
                      _buildMonitoringCard(
                        icon: Icons.brightness_high,
                        title: 'Intensitas',
                        value: '1000',
                        unit: 'Cd',
                        width: 150,
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

// Data class untuk grafik
class _ChartData {
  _ChartData(this.x, this.y);
  final int x;
  final double y;
}
