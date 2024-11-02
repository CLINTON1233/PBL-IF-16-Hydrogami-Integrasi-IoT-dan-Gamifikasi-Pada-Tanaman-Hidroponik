import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrogami2/pilih_skala.dart';

class KonfirmasiPilihPage extends StatefulWidget {
  const KonfirmasiPilihPage({super.key});

  @override
  State<KonfirmasiPilihPage> createState() => _KonfirmasiPilihPageState();
}

class _KonfirmasiPilihPageState extends State<KonfirmasiPilihPage> {
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
          padding: const EdgeInsets.symmetric(horizontal: 55),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                'Kamu Yakin Memilih',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color(0xFF29CC74),
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Pakcoy?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color(0xFF29CC74),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/pakcoy2.png',
                width: 400,
                height: 500,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Tidak
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Kembali ke halaman sebelumnya
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                            color: Color(0xFF2ABD77), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      elevation: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_back_ios,
                            color: Color(0xFF2ABD77), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Tidak',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF2ABD77),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol Ya dengan ikon di sebelah kanan
                  ElevatedButton(
                    onPressed: () {
                      // Navigasi ke halaman berikutnya
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PilihSkalaPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                            color: Color(0xFF2ABD77), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 10),
                      elevation: 2,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Ya',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF2ABD77),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10), // Jarak antara teks dan ikon
                        const Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF2ABD77), size: 18),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
