import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  int _bottomNavCurrentIndex = 3;
  final Color _primaryColor = const Color(0xFF24D17E); // Warna utama baru

  final List<Map<String, dynamic>> teamMembers = [
    {
      'name': 'Hamdani Arif, S.Pd., M.Sc',
      'position': 'Project Manager',
      'avatar': 'assets/pakhamdani.jpg',
      'desc': 'Bertanggung jawab atas keseluruhan proyek dan strategi pengembangan',
      'color': const Color(0xFF24D17E), // Diubah
    },
    {
      'name': 'Clinton Alfaro',
      'position': 'Fullstack Developer',
      'avatar': 'assets/clinton.jpg',
      'desc': 'Mengembangkan aplikasi mobile dan integrasi perangkat keras',
      'color': const Color.fromARGB(255, 235, 143, 5),
    },
    {
      'name': 'Nania Prima Citra A',
      'position': 'Website Developer',
      'avatar': 'assets/nania.jpg',
      'desc': 'Mengembangkan aplikasi web dan mobile yang ramah pengguna',
      'color': const Color.fromARGB(255, 192, 14, 14),
    },
    {
      'name': 'Citra Miranda P.S',
      'position': 'Mobile Developer',
      'avatar': 'assets/citra.jpg',
      'desc': 'Mengembangkan aplikasi web dan integrasi perangkat keras',
      'color': const Color.fromARGB(255, 20, 221, 204),
    },
    {
      'name': 'Yurisha Anindya',
      'position': 'Mobile Developer',
      'avatar': 'assets/yurisha.jpg',
      'desc': 'Mengembangkan aplikasi mobile dan desain antarmuka pengguna',
      'color': const Color.fromARGB(255, 51, 88, 255),
    },
  ];

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hydrogami@polibatam.ac.id',
      queryParameters: {'subject': 'Pertanyaan tentang HydroGami'},
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Tentang Kami',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
       
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildSectionTitle('Visi Kami', Icons.remove_red_eye),
                  const SizedBox(height: 16),
                  _buildVisionCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Misi Kami', Icons.flag),
                  const SizedBox(height: 16),
                  _buildMissionCard(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Fitur Unggulan', Icons.star),
                  const SizedBox(height: 16),
                  _buildFeaturesGrid(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Teknologi', Icons.engineering),
                  const SizedBox(height: 16),
                  _buildTechnologyList(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Tim Kami', Icons.people),
                  const SizedBox(height: 16),
                  _buildTeamList(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Kontak', Icons.contact_page_rounded),
                  const SizedBox(height: 16),
                  _buildContactCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryColor, // Diubah
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        image: const DecorationImage(
          image: AssetImage('assets/tanaman_panduan.png'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HydroGami',
              style: GoogleFonts.poppins(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Solusi Hidroponik Modern Berbasis IoT',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 28), // Diubah
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildVisionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Menjadi platform terdepan dalam sistem monitoring hidroponik berbasis IoT yang mengintegrasikan teknologi dan gamifikasi untuk menciptakan pengalaman bercocok tanam yang modern, edukatif, dan berkelanjutan.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMissionItem(
              'Mengembangkan sistem monitoring tanaman hidroponik secara real-time dengan teknologi sensor IoT yang akurat dan andal.'
            ),
            const SizedBox(height: 12),
            _buildMissionItem(
              'Menyediakan platform yang interaktif dengan elemen gamifikasi untuk meningkatkan motivasi pengguna dalam merawat tanaman.'
            ),
            const SizedBox(height: 12),
            _buildMissionItem(
              'Meningkatkan kesadaran akan pentingnya pertanian berkelanjutan melalui fitur edukasi dan tips perawatan tanaman.'
            ),
            const SizedBox(height: 12),
            _buildMissionItem(
              'Membangun antarmuka pengguna yang intuitif dan mudah digunakan bagi berbagai tingkat pengalaman.'
            ),
            const SizedBox(height: 12),
            _buildMissionItem(
              'Mendorong inovasi di bidang pertanian urban melalui penerapan teknologi terkini.'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: _primaryColor), // Diubah
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid() {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.sensors, 'title': 'Monitoring Real-time', 'desc': 'Pantau kondisi tanaman'},
      {'icon': Icons.auto_awesome, 'title': 'Otomatisasi', 'desc': 'Sistem nutrisi dan penyiraman otomatis'},
      {'icon': Icons.notifications, 'title': 'Notifikasi', 'desc': 'Peringatan kondisi tanaman'},
      {'icon': Icons.analytics, 'title': 'Analisis Data', 'desc': 'Statistik pertumbuhan tanaman'},
      {'icon': Icons.games, 'title': 'Gamifikasi', 'desc': 'Sistem reward untuk motivasi pengguna'},
      {'icon': Icons.school, 'title': 'Edukasi', 'desc': 'Panduan lengkap bercocok tanam'},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: features.map((Map<String, dynamic> feature) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1), // Diubah
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(feature['icon'] as IconData, color: _primaryColor, size: 24), // Diubah
                ),
                const SizedBox(height: 12),
                Text(
                  feature['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  feature['desc'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTechnologyList() {
    final List<Map<String, dynamic>> technologies = [
      {'icon': Icons.phone_android, 'name': 'Flutter', 'desc': 'Framework pengembangan aplikasi mobile'},
      {'icon': Icons.code, 'name': 'Laravel', 'desc': 'Backend service untuk pemrosesan data'},
      {'icon': Icons.cloud, 'name': 'REST API', 'desc': 'Penyimpanan data dan autentikasi'},
      {'icon': Icons.sensors, 'name': 'IoT Sensors', 'desc': 'Sensor untuk memantau kondisi tanaman'},
    ];

    return Column(
      children: technologies.map((Map<String, dynamic> tech) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1), // Diubah
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tech['icon'] as IconData, color: _primaryColor), // Diubah
              ),
              title: Text(
                tech['name'] as String,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              subtitle: Text(
                tech['desc'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamList() {
    return Column(
      children: teamMembers.map((Map<String, dynamic> member) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage: AssetImage(member['avatar'] as String),
                    backgroundColor: (member['color'] as Color).withOpacity(0.1),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member['position'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: member['color'] as Color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member['desc'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1), // Diubah
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.email, color: _primaryColor), // Diubah
              ),
              title: Text(
                'Email',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('clintonalfaro@gmail.com'),
              onTap: _launchEmail,
            ),
            const Divider(height: 1),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1), // Diubah
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: _primaryColor), // Diubah
              ),
              title: Text(
                'Lokasi',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('Politeknik Negeri Batam'),
            ),
          ],
        ),
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
        backgroundColor: _primaryColor, // Diubah
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