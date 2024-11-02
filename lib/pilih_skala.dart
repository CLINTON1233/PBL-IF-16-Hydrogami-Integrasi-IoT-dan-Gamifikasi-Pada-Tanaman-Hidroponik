import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PilihSkalaPage extends StatefulWidget {
  const PilihSkalaPage({super.key});

  @override
  State<PilihSkalaPage> createState() => _PilihSkalaPageState();
}

class _PilihSkalaPageState extends State<PilihSkalaPage> {
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
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'Pilih Skala Hidroponikmu!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: const Color(0xFF29CC74),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              buildCard(
                'High',
                '20-30 pipa',
                '50-100 benih',
                'Luas, cocok untuk produksi besar atau penggunaan komersial',
                'Lebih tinggi, perlu sistem pengelolaan nutrisi dan irigasi yang teratur',
                'Memerlukan pemantauan dan perawatan yang lebih intensif',
                const Color.fromARGB(255, 16, 199, 101),
              ),
              const SizedBox(height: 20),
              buildCard(
                'Medium',
                '10-20 pipa',
                '20-50 benih',
                'Sedang, cocok untuk hobi atau produksi kecil-menengah',
                'Sedang, bisa dikelola dengan perawatan mingguan',
                'Pengelolaan yang lebih ringan namun tetap butuh pemantauan rutin',
                const Color.fromARGB(255, 16, 199, 101),
              ),
              const SizedBox(height: 20),
              buildCard(
                'Easy',
                '5-10 pipa',
                '5-20 benih',
                'Kecil, cocok untuk pemula atau lahan terbatas',
                'Rendah, cukup dengan perawatan mingguan atau dua kali seminggu',
                'Sangat mudah, bisa dikelola dengan perawatan minim',
                const Color.fromARGB(255, 16, 199, 101),
              ),
              const SizedBox(
                  height: 40), // Jarak tambahan di bawah kartu terakhir
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCard(String title, String pipa, String benih, String area,
      String nutrisi, String pengelolaan, Color borderColor) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFFFD2), // Latar belakang putih
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: borderColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '• Jumlah Pipa: $pipa',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF20934E),
              ),
              textAlign: TextAlign.justify,
            ),
            Text(
              '• Jumlah Benih: $benih',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF20934E),
              ),
              textAlign: TextAlign.justify,
            ),
            Text(
              '• Cakupan Area: $area',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF20934E),
              ),
              textAlign: TextAlign.justify,
            ),
            Text(
              '• Kebutuhan Air & Nutrisi: $nutrisi',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF20934E),
              ),
              textAlign: TextAlign.justify,
            ),
            Text(
              '• Pengelolaan: $pengelolaan',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF20934E),
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
