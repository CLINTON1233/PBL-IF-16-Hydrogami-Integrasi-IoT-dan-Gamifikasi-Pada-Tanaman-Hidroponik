import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/gamifikasi/gamifikasi_page.dart';
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
  int _bottomNavCurrentIndex = 0;
  final Color _primaryColor = const Color(0xFF24D17E);
  final Color _secondaryColor = const Color(0xFF1BB96A);

  final List<Map<String, dynamic>> teamMembers = [
    {
      'name': 'Hamdani Arif, S.Pd., M.Sc',
      'position': 'Project Manager',
      'avatar': 'assets/pakhamdani.jpg',
      'desc':
          'Bertanggung jawab atas keseluruhan proyek dan strategi pengembangan',
      'color': const Color(0xFF24D17E),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        title: Text(
          'Tentang Kami',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildVisionMissionSection(),
                  const SizedBox(height: 24),
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  _buildTechnologySection(),
                  const SizedBox(height: 24),
                  _buildTeamSection(),
                  const SizedBox(height: 24),
                  _buildContactSection(),
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
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _secondaryColor],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: 0.15,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/tanaman_panduan.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                Text(
                  'HydroGami',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Solusi Hidroponik Modern Berbasis IoT',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildVisionMissionSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Visi
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0.2),
                            _primaryColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.visibility,
                          color: _primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Visi Kami',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Menjadi platform terdepan dalam sistem monitoring hidroponik berbasis IoT yang mengintegrasikan teknologi dan gamifikasi untuk menciptakan pengalaman bercocok tanam yang modern, edukatif, dan berkelanjutan.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.7,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          // Misi
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0.2),
                            _primaryColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.flag, color: _primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Misi Kami',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMissionItem(
                    'Mengembangkan sistem monitoring tanaman hidroponik secara real-time dengan teknologi sensor IoT yang akurat dan andal.'),
                _buildMissionItem(
                    'Menyediakan platform yang interaktif dengan elemen gamifikasi untuk meningkatkan motivasi pengguna dalam merawat tanaman.'),
                _buildMissionItem(
                    'Meningkatkan kesadaran akan pentingnya pertanian berkelanjutan melalui fitur edukasi dan tips perawatan tanaman.'),
                _buildMissionItem(
                    'Membangun antarmuka pengguna yang intuitif dan mudah digunakan bagi berbagai tingkat pengalaman.'),
                _buildMissionItem(
                    'Mendorong inovasi di bidang pertanian urban melalui penerapan teknologi terkini.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final List<Map<String, dynamic>> features = [
      {
        'icon': Icons.sensors,
        'title': 'Monitoring Real-time',
        'desc': 'Pantau kondisi tanaman',
        'color': const Color(0xFF24D17E)
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'Otomatisasi',
        'desc': 'Sistem nutrisi otomatis',
        'color': const Color(0xFFFF9800)
      },
      {
        'icon': Icons.notifications_active,
        'title': 'Notifikasi',
        'desc': 'Peringatan kondisi tanaman',
        'color': const Color(0xFFE91E63)
      },
      {
        'icon': Icons.analytics,
        'title': 'Analisis Data',
        'desc': 'Statistik pertumbuhan',
        'color': const Color(0xFF2196F3)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Fitur Unggulan', Icons.star),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTechnologySection() {
    final List<Map<String, dynamic>> technologies = [
      {
        'icon': Icons.phone_android,
        'name': 'Flutter',
        'desc': 'Framework aplikasi mobile'
      },
      {'icon': Icons.code, 'name': 'Laravel', 'desc': 'Backend service'},
      {'icon': Icons.cloud, 'name': 'REST API', 'desc': 'Penyimpanan data'},
      {
        'icon': Icons.sensors,
        'name': 'IoT Sensors',
        'desc': 'Sensor monitoring'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Teknologi', Icons.engineering),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: technologies.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> tech = entry.value;
              bool isLast = index == technologies.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _primaryColor.withOpacity(0.15),
                            _primaryColor.withOpacity(0.05)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(tech['icon'] as IconData,
                          color: _primaryColor, size: 24),
                    ),
                    title: Text(
                      tech['name'] as String,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
                  if (!isLast)
                    Divider(
                        height: 1,
                        indent: 80,
                        endIndent: 20,
                        color: Colors.grey[200]),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tim Kami', Icons.people),
        const SizedBox(height: 16),
        ...teamMembers.map((member) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (member['color'] as Color).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage(member['avatar'] as String),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  (member['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member['position'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: member['color'] as Color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            member['desc'] as String,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                              height: 1.4,
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
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Kontak', Icons.contact_page_rounded),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.15),
                        _primaryColor.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.email_outlined,
                      color: _primaryColor, size: 24),
                ),
                title: Text(
                  'Email',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'clintonalfaro@gmail.com',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
                onTap: _launchEmail,
              ),
              Divider(
                  height: 1,
                  indent: 80,
                  endIndent: 20,
                  color: Colors.grey[200]),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.15),
                        _primaryColor.withOpacity(0.05)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.location_on_outlined,
                      color: _primaryColor, size: 24),
                ),
                title: Text(
                  'Lokasi',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Politeknik Negeri Batam',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Bottom Navigation Widget
  Widget _buildBottomNavigation() {
    return Container(
      color: Colors.white, // tambahin ini biar latar belakangnya full putih
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            onTap: (index) {
              setState(() {
                _bottomNavCurrentIndex = index;
              });

              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BerandaPage()),
                  );
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GamifikasiPage()),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PanduanPage()),
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
                activeIcon: Icon(Icons.home_rounded),
                icon: Icon(Icons.home_outlined),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.tune_rounded),
                icon: Icon(Icons.tune_outlined),
                label: 'Kontrol',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.book_rounded),
                icon: Icon(Icons.book_outlined),
                label: 'Panduan',
              ),
              BottomNavigationBarItem(
                activeIcon: Icon(Icons.person_rounded),
                icon: Icon(Icons.person_outline_rounded),
                label: 'Akun',
              ),
            ],
            selectedItemColor: const Color(0xFF24D17E),
            unselectedItemColor: Colors.grey[400],
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
