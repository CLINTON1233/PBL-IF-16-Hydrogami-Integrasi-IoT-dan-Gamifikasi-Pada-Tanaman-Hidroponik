import 'package:application_hydrogami/beranda_page.dart';
import 'package:application_hydrogami/notifikasi_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailPanduanTanamanPage extends StatefulWidget {
  const DetailPanduanTanamanPage({super.key});

  @override
  State<DetailPanduanTanamanPage> createState() =>
      _DetailPanduanTanamanPageState();
}

class _DetailPanduanTanamanPageState extends State<DetailPanduanTanamanPage> {
  int _bottomNavCurrentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Text(
          'Panduan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp),
          iconSize: 20.0,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/hydrogami_logo2.png',
              width: 30,
              height: 30,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul diletakkan di luar card
              Center(
                child: Text(
                  'Panduan Pengelolaan Tanaman',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                color: Colors.white, // Mengubah warna card menjadi putih
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/tanamanDetail.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Berikut adalah panduan untuk pengelolaan tanaman hidroponik:\n'
                        '\n'
                        '1. Persiapan\n'
                        '\n'
                        'Pilih jenis tanaman: Pilih jenis tanaman yang cocok untuk sistem hidroponik. Beberapa tanaman yang populer adalah selada, bayam, kangkung, dan tomat ceri.\n'
                        'Siapkan sistem hidroponik: Pastikan sistem hidroponik Anda sudah siap digunakan, termasuk wadah, pompa air, dan larutan nutrisi.\n'
                        'Siapkan benih atau bibit: Pilih benih atau bibit yang berkualitas baik dan sehat.\n'
                        'Sterilisasi: Sterilisasi semua peralatan dan wadah yang akan digunakan untuk mencegah pertumbuhan jamur dan bakteri.\n'
                        '\n'
                        '2. Penanaman\n'
                        '\n'
                        'Penanaman: Tanam benih atau bibit ke dalam media tanam hidroponik sesuai dengan petunjuk yang diberikan.\n'
                        'Pencahayaan: Pastikan tanaman menerima cahaya matahari yang cukup atau gunakan lampu tumbuh.\n'
                        'Suhu dan kelembaban: Jaga suhu dan kelembaban yang optimal untuk pertumbuhan tanaman.\n'
                        '\n'
                        '3. Pemeliharaan\n'
                        '\n'
                        'Pemberian nutrisi: Berikan larutan nutrisi secara teratur sesuai dengan kebutuhan tanaman.\n'
                        'Pengaturan pH: Pertahankan pH larutan nutrisi dalam rentang yang ideal untuk tanaman.\n'
                        'Pemberian air: Pastikan tanaman mendapatkan air yang cukup, tetapi hindari genangan air.\n'
                        'Pembersihan: Bersihkan sistem hidroponik secara berkala untuk mencegah penumpukan kotoran dan alga.\n'
                        'Pemantauan: Pantau pertumbuhan tanaman secara teratur dan lakukan tindakan yang diperlukan jika ada masalah.\n'
                        '\n'
                        '4. Panen\n'
                        '\n'
                        'Panen: Panen tanaman saat sudah mencapai ukuran dan kualitas yang diinginkan.\n'
                        'Penyimpanan: Simpan hasil panen dengan benar untuk menjaga kesegaran dan kualitasnya.\n'
                        '\n'
                        'Tips:\n'
                        '\n'
                        'Pilih sistem hidroponik yang sesuai: Pilih sistem hidroponik yang sesuai dengan kebutuhan dan ruang Anda.\n'
                        'Gunakan larutan nutrisi yang tepat: Gunakan larutan nutrisi yang diformulasikan khusus untuk tanaman hidroponik.\n'
                        'Perhatikan pH larutan nutrisi: pH larutan nutrisi sangat penting untuk penyerapan nutrisi oleh tanaman.\n'
                        'Jaga kebersihan sistem: Kebersihan sistem sangat penting untuk mencegah pertumbuhan jamur dan bakteri.\n'
                        'Pantau pertumbuhan tanaman: Pantau pertumbuhan tanaman secara teratur dan lakukan tindakan yang diperlukan jika ada masalah.\n'
                        'Pelajari lebih lanjut: Pelajari lebih lanjut tentang hidroponik untuk meningkatkan pengetahuan dan keterampilan Anda.\n'
                        '\n'
                        'Catatan:\n'
                        '\n'
                        'Panduan ini hanya memberikan gambaran umum tentang pengelolaan tanaman hidroponik.'
                        'Detail pengelolaan mungkin bervariasi tergantung pada jenis tanaman dan sistem hidroponik yang Anda gunakan.'
                        'Pastikan Anda memahami risiko yang terkait dengan penggunaan pupuk dan larutan nutrisi.'
                        'Selalu ikuti instruksi produsen untuk setiap produk yang Anda gunakan.'
                        '\n',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Fungsi untuk membuat BottomNavigationBar
  Widget _buildBottomNavigation() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF24D17E),
        onTap: (index) {
          setState(() {
            _bottomNavCurrentIndex = index;
          });

          // Menangani navigasi berdasarkan indeks
          switch (index) {
            case 0: // Beranda
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BerandaPage()),
              );
              break;
            case 1: // Notifikasi
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
              );
              break;
            case 2: // Panduan
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PanduanPage()),
              );
              break;
            case 3: // Profil
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
            activeIcon: Icon(
              Icons.home,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.home,
              color: Colors.white,
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.notification_add,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.notification_add,
              color: Colors.white,
            ),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.assignment,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.assignment,
              color: Colors.white,
            ),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(
              Icons.person,
              color: Colors.black,
            ),
            icon: Icon(
              Icons.person,
              color: Colors.white,
            ),
            label: 'Akun',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }
}
