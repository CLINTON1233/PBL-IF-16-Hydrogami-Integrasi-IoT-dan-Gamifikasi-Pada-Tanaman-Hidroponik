import 'package:flutter/material.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/models/panduan_model.dart';
import 'package:application_hydrogami/services/detail_panduan_services.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class DetailPanduanTanamanPage extends StatefulWidget {
  final int idPanduan;
  const DetailPanduanTanamanPage({super.key, required this.idPanduan});

  @override
  State<DetailPanduanTanamanPage> createState() =>
      _DetailPanduanTanamanPageState();
}

class _DetailPanduanTanamanPageState extends State<DetailPanduanTanamanPage> {
  late Future<Panduan?> panduanDetail;
  int _bottomNavCurrentIndex = 2;

  @override
  void initState() {
    super.initState();
    panduanDetail = DetailPanduanService.fetchPanduanDetail(widget.idPanduan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder<Panduan?>(
        future: panduanDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF29CC74),
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat panduan...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat data panduan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan coba lagi nanti',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final panduan = snapshot.data!;
          return CustomScrollView(
            slivers: [
              // Hero Image Section with fixed image display
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF24D17E),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_sharp,
                    color: Colors.black,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PanduanPage()),
                    );
                  },
                ),
                title: Row(
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Detail Panduan',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Main Hero Image with proper scaling
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF29CC74).withOpacity(0.8),
                              const Color(0xFF20B863).withOpacity(0.9),
                            ],
                          ),
                        ),
                        child: panduan.gambar != null
                            ? ClipRect(
                                child: Transform.scale(
                                  scale: 1.0, // Normal scale, no zoom
                                  child: Image.asset(
                                    'assets/tanaman_panduan.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    alignment: Alignment.center,
                                  ),
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF29CC74),
                                      const Color(0xFF20B863),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.eco_rounded,
                                    size: 80,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                      ),

                      // Subtle gradient overlay for better readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Section
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Title Section with elegant design
                      Container(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category badge with modern styling
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF29CC74).withOpacity(0.15),
                                    const Color(0xFF20B863).withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color:
                                      const Color(0xFF29CC74).withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF29CC74),
                                          const Color(0xFF20B863),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PANDUAN HIDROPONIK',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF29CC74),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Main Title with enhanced typography
                            Text(
                              panduan.judul ?? 'Judul tidak tersedia.',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A202C),
                                height: 1.15,
                                letterSpacing: -0.8,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Reading time with elegant design
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF29CC74)
                                              .withOpacity(0.2),
                                          const Color(0xFF20B863)
                                              .withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: const Color(0xFF29CC74),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Estimasi membaca 5 menit',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF4A5568),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Content Card with premium design
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 28),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              spreadRadius: 0,
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              spreadRadius: 0,
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // YouTube Video Player Section
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Stack(
                                  children: [
                                    // YouTube Thumbnail
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF29CC74)
                                                .withOpacity(0.8),
                                            const Color(0xFF20B863)
                                                .withOpacity(0.9),
                                          ],
                                        ),
                                      ),
                                      child: Image.network(
                                        'https://img.youtube.com/vi/SOal6p91Txk/maxresdefault.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xFF29CC74),
                                                  const Color(0xFF20B863),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons
                                                    .play_circle_outline_rounded,
                                                size: 64,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    // Dark overlay for better button visibility
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.3),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Play Button and Video Info
                                    Center(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final Uri url = Uri.parse(
                                              'https://www.youtube.com/watch?v=SOal6p91Txk');

                                          if (await launcher
                                              .canLaunchUrl(url)) {
                                            await launcher.launchUrl(
                                              url,
                                              mode: launcher.LaunchMode
                                                  .externalApplication,
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.95),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.play_arrow_rounded,
                                            color: const Color(0xFF29CC74),
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // YouTube badge
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              'YouTube',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Video duration badge (optional)
                                    Positioned(
                                      bottom: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.8),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '4:11',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Video Title
                            Text(
                              'Video Panduan',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D3748),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Tonton video berikut untuk dapat memahami panduan ini dengan lebih baik.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Content header with sophisticated styling
                            Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        const Color(0xFF29CC74),
                                        const Color(0xFF20B863),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Langkah-langkah',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A202C),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            // Main content text with premium typography
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                panduan.deskPanduan ??
                                    'Deskripsi tidak tersedia.',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFF2D3748),
                                  fontWeight: FontWeight.w400,
                                  height: 1.9,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom spacing for navigation
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
                  MaterialPageRoute(
                      builder: (context) => const NotifikasiPage()),
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
          elevation: 0,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              activeIcon: Icon(
                Icons.home_rounded,
                color: Colors.black87,
                size: 26,
              ),
              icon: Icon(
                Icons.home_outlined,
                color: Colors.white,
                size: 24,
              ),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(
                Icons.notifications_rounded,
                color: Colors.black87,
                size: 26,
              ),
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
              label: 'Notifikasi',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(
                Icons.menu_book_rounded,
                color: Colors.black87,
                size: 26,
              ),
              icon: Icon(
                Icons.menu_book_outlined,
                color: Colors.white,
                size: 24,
              ),
              label: 'Panduan',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(
                Icons.person_rounded,
                color: Colors.black87,
                size: 26,
              ),
              icon: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
              label: 'Akun',
            ),
          ],
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.white,
        ),
      ),
    );
  }
}
