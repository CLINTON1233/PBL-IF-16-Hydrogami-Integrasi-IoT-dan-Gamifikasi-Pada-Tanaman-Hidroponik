import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_hidroponik_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_sensor_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_tanaman_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_nutrisi_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_panen_page.dart';
import 'package:application_hydrogami/pages/panduan/detail_panduan_phupdown_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class PanduanPage extends StatefulWidget {
  const PanduanPage({super.key});

  @override
  State<PanduanPage> createState() => _PanduanPageState();
}

class _PanduanPageState extends State<PanduanPage>
    with TickerProviderStateMixin {
  int _bottomNavCurrentIndex = 2;
  int? _pressedCardIndex;
  bool _isNavigating = false;

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
            
            Text(
              'Panduan',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white, 
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color:
                  Colors.white), 
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildPanduanCard(
                0,
                'assets/panduan_hidroponik.png',
                'Panduan Merakit Sistem Hidroponik',
                const DetailPanduanHidroponikPage(idPanduan: 1),
              ),
              const SizedBox(height: 16),
              _buildPanduanCard(
                1,
                'assets/panduan_sensor.png',
                'Panduan Pemasangan Sensor IoT',
                const DetailPanduanSensorPage(idPanduan: 2),
              ),
              const SizedBox(height: 16),
              _buildPanduanCard(
                2,
                'assets/tanaman_panduan.png',
                'Panduan Pengelolaan Tanaman',
                const DetailPanduanTanamanPage(idPanduan: 3),
              ),
              const SizedBox(height: 16),
              _buildPanduanCard(
                3,
                'assets/panduanNutrisi.jpg',
                'Panduan Pemberian Nutrisi Tanaman Hidroponik',
                const DetailPanduanNutrisiPage(idPanduan: 4),
              ),
              const SizedBox(height: 16),
              _buildPanduanCard(
                4,
                'assets/phupdown.png',
                'Panduan Pemberian pH Up dan pH Down Tanaman Hidroponik',
                const DetailPanduanPhUpDownPage(idPanduan: 5),
              ),
              const SizedBox(height: 16),
              _buildPanduanCard(
                5,
                'assets/panenPakcoy.jpg',
                'Panduan Memanen Pakcoy',
                const DetailPanduanPanenPage(idPanduan: 6),
              ),
              const SizedBox(height: 20), // Extra padding at bottom
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildPanduanCard(
      int index, String imagePath, String title, Widget detailPage) {
    bool isPressed = _pressedCardIndex == index;

    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _pressedCardIndex = index;
        });
      },
      onTapUp: (_) {
        setState(() {
          _pressedCardIndex = null;
        });
      },
      onTapCancel: () {
        setState(() {
          _pressedCardIndex = null;
        });
      },
      onTap: () async {
        if (_isNavigating) return;

        setState(() {
          _isNavigating = true;
        });

        // Add haptic feedback
        HapticFeedback.lightImpact();

        // Small delay for visual feedback
        await Future.delayed(const Duration(milliseconds: 150));

        if (mounted) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  detailPage,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var begin = const Offset(1.0, 0.0);
                var end = Offset.zero;
                var curve = Curves.easeInOutCubic;
                var tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {
                _isNavigating = false;
              });
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOutCubic,
        transform: Matrix4.identity()
          ..scale(isPressed ? 0.98 : 1.0)
          ..translate(0.0, isPressed ? 2.0 : 0.0),
        margin: const EdgeInsets.only(bottom: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            boxShadow: [
              // Primary shadow - reduced intensity
              BoxShadow(
                color:
                    const Color(0xFF29CC74).withOpacity(isPressed ? 0.1 : 0.15),
                spreadRadius: isPressed ? -2 : 0,
                blurRadius: isPressed ? 15 : 25,
                offset: Offset(0, isPressed ? 3 : 8),
              ),
              // Secondary shadow for depth
              BoxShadow(
                color: Colors.black.withOpacity(isPressed ? 0.03 : 0.06),
                spreadRadius: isPressed ? -1 : 0,
                blurRadius: isPressed ? 8 : 15,
                offset: Offset(0, isPressed ? 1 : 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                // Enhanced image section
                Stack(
                  children: [
                    // Main image
                    Container(
                      height: 200,
                      width: double.infinity,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey.shade400,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),

                    // Gradient overlay for depth
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),

                    // Colorful accent overlay
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF29CC74).withOpacity(0.08),
                            Colors.transparent,
                            const Color(0xFF20B863).withOpacity(0.12),
                          ],
                        ),
                      ),
                    ),

                    // Top badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF29CC74).withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFF29CC74),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PANDUAN',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF29CC74),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Title and action section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pelajari Selengkapnya',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          // Interactive Mulai button
                          _buildMulaiButton(isPressed),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMulaiButton(bool isCardPressed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCardPressed
              ? [
                  const Color(0xFF20B863),
                  const Color(0xFF1DA554),
                ]
              : [
                  const Color(0xFF29CC74),
                  const Color(0xFF20B863),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF29CC74).withOpacity(isCardPressed ? 0.2 : 0.3),
            spreadRadius: 0,
            blurRadius: isCardPressed ? 4 : 8,
            offset: Offset(0, isCardPressed ? 1 : 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mulai',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedRotation(
            turns: isCardPressed ? 0.1 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
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
          items: const [
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.home_rounded),
              icon: Icon(Icons.home_outlined),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              activeIcon: Icon(Icons.notifications_rounded),
              icon: Icon(Icons.notifications_outlined),
              label: 'Notifikasi',
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
    );
  }
}
