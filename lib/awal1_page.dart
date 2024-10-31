import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrogami2/awal2_page.dart';

class Awal1Page extends StatelessWidget {
  const Awal1Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            Image.asset(
              'assets/hydrogami_logo.png',
              width: 320,
              height: 170,
            ),
            Text(
              'Solusi cerdas hidroponik di era modern.',
              textAlign: TextAlign.center,
              style: GoogleFonts.kurale(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF29CC74),
              ),
            ),
            const Spacer(),
            // Tombol Mulai
            ElevatedButton(
              onPressed: () {
                // Navigasi ke Page awal 2
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Awal2Page()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29CC74),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5, // Tambahkan efek bayangan
                shadowColor: Colors.black.withOpacity(0.2), // Warna bayangan
              ),
              child: Text(
                'Mulai',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                'Selamat Datang di HydroGami',
                style: GoogleFonts.kurale(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF29CC74),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
