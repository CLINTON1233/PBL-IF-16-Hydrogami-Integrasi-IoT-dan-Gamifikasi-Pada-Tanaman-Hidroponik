import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PageAwal2 extends StatelessWidget {
  const PageAwal2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Spacer(),
          // Logo dan Judul
          Column(
            children: [
              Image.asset(
                'assets/hydrogami_logo.png',
                width: 300,
                height: 150,
              ),
              const SizedBox(height: 8),
              Text(
                'Solusi cerdas hidroponik di era modren.',
                textAlign: TextAlign.center,
                style: GoogleFonts.kurale(
                  color: const Color.fromARGB(255, 9, 195, 77),
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Selamat Datang
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF29CC74),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(60),
                topRight: Radius.circular(0),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Selamat Datang\nDi HydroGami',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kurale(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nikmati cara baru merawat tanaman hidroponik dengan '
                  'mudah dan menyenangkan! Pantau kondisi tanaman secara '
                  'real-time melalui teknologi IoT, dan kumpulkan poin dari '
                  'tantangan gamifikasi seru. Jadilah yang terbaik di leaderboard '
                  'sambil menjaga tanaman Anda tetap sehat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Tombol Masuk dan Daftar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        // Aksi tombol "Masuk" ditekan
                      },
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                            color: Color.fromARGB(255, 9, 195, 77),
                            fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        // Aksi tombol "Daftar" ditekan
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                            color: Color.fromARGB(255, 9, 195, 77),
                            fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
