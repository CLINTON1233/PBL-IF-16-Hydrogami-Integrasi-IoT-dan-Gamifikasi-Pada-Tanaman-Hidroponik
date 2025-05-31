import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';
import 'package:application_hydrogami/pages/auth/registrasi_page.dart';

class Awal2Page extends StatelessWidget {
  const Awal2Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 25,
            color: const Color.fromARGB(255, 36, 209, 126),
          ),
          const SizedBox(height: 50),

          Column(
            children: [
              Image.asset(
                'assets/logo.png',
                width: 300,
                height: 200,
              ),
              const SizedBox(height: 2),
              Text(
                'Solusi Cerdas Hidroponik di Era Modern.',
                textAlign: TextAlign.center,
                style: GoogleFonts.kurale(
                  color: const Color.fromARGB(246, 11, 142, 59),
                  fontSize: 16,
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
                  textAlign: TextAlign.justify,
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
                            horizontal: 30, vertical: 12),
                      ),
                      onPressed: () {
                        // Aksi tombol "Masuk" ditekan
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        'Masuk',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                      onPressed: () {
                        // Aksi tombol "Daftar" ditekan
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegistrasiPage()),
                        );
                      },
                      child: const Text(
                        'Daftar',
                        style: TextStyle(color: Colors.black, fontSize: 15),
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
