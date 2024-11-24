import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/skala%20and%20plant/konfirmasi_pilih_page.dart';

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
              const SizedBox(height: 45),
              Text(
                'Pilih Tanaman',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  color: const Color.fromARGB(232, 8, 166, 82),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Hidroponikmu!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color.fromARGB(232, 8, 166, 82),
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
                  crossAxisSpacing: 13,
                  mainAxisSpacing: 13,
                  childAspectRatio: 0.65,
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
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFCFFFD2),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            imagePath,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        // Tombol untuk nama tanaman
        ElevatedButton(
          onPressed: () {
            if (title == 'Pakcoy') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KonfirmasiPilihPage(),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF2ABD77), width: 1),
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
