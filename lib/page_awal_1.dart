import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrogami2/page_awal_2.dart';

class PageAwal1 extends StatelessWidget {
  const PageAwal1({super.key});

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
              width: 300,
              height: 150,
            ),
            Text(
              'Solusi cerdas hidroponik di era modern.',
              textAlign: TextAlign.center,
              style: GoogleFonts.kurale(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: Colors.green,
              ),
            ),
            const Spacer(),
            // Tombol Mulai
            ElevatedButton(
              onPressed: () {
                // Navigasi ke Page awal 2
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PageAwal2()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF29CC74),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Mulai',
                style: GoogleFonts.roboto(
                  fontSize: 18,
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
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
