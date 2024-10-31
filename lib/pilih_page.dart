import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PilihPage extends StatefulWidget {
  const PilihPage({super.key});

  @override
  State<PilihPage> createState() => _PilihPageState();
}

class _PilihPageState extends State<PilihPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 36, 209, 126),
        elevation: 0,
        toolbarHeight: 0, 
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 25),
              Text(
                'Pilih Tanaman',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color(0xFF29CC74),
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                'Hidroponikmu!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color(0xFF29CC74),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 50),
              // GridView untuk pilihan tanaman
              GridView(
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.63, 
                ),
                children: [
                  _buildTanamanItem('assets/pakcoy.png', 'Pakcoy'),
                  _buildTanamanItem('assets/bayam.png', 'Bayam'),
                  _buildTanamanItem('assets/sawi_hijau.png', 'Sawi Hijau'),
                  _buildTanamanItem('assets/selada.png', 'Selada'),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk item tanaman
  Widget _buildTanamanItem(String imagePath, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          color: const Color(0xFFCFFFD2),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Image.asset(
                  imagePath,
                  width: 140, 
                  height: 140, 
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10), 
        // Tombol untuk nama tanaman
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: const Color(0xFF2ABD77), width: 1),
            ),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF2ABD77),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20), 
      ],
    );
  }
}
