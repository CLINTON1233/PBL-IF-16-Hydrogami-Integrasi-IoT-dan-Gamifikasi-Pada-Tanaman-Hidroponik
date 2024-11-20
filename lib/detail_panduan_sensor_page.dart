import 'package:application_hydrogami/beranda_page.dart';
import 'package:application_hydrogami/notifikasi_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailPanduanSensorPage extends StatefulWidget {
  const DetailPanduanSensorPage({super.key});

  @override
  State<DetailPanduanSensorPage> createState() =>
      _DetailPanduanSensorPageState();
}

class _DetailPanduanSensorPageState extends State<DetailPanduanSensorPage> {
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
                  'Panduan Pemasangan Sensor IoT',
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
                          'assets/sensorDetail.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Berikut ini adalah panduan dalam pemasangan sensor IoT:\n'
                        '1. Siapkan Komponen\n'
                        'Arduino UNO R3: Mikrokontroler utama yang akan memproses data dari sensor dan mengendalikan perangkat.\n'
                        'WEMOS: Modul Wi-Fi untuk mengirim data ke cloud.\n'
                        'DHT11: Sensor suhu dan kelembaban.\n'
                        'PH Sensor: Sensor untuk mengukur pH larutan.\n'
                        'Relay: Perangkat untuk mengontrol perangkat listrik seperti pompa air.\n'
                        'Pompa AC 220V: Pompa air untuk mengalirkan larutan.\n'
                        'Baterai: Sumber daya untuk sistem.\n'
                        'Kabel: Untuk menghubungkan semua komponen.\n\n'
                        '2. Hubungkan Sensor ke Arduino UNO R3\n'
                        'DHT11:\n'
                        'Hubungkan pin data DHT11 ke pin digital Arduino UNO R3.\n'
                        'Hubungkan pin VCC DHT11 ke pin 5V Arduino UNO R3.\n'
                        'Hubungkan pin GND DHT11 ke pin GND Arduino UNO R3.\n\n'
                        'PH Sensor:\n'
                        'Hubungkan pin VCC PH Sensor ke pin 5V Arduino UNO R3.\n'
                        'Hubungkan pin GND PH Sensor ke pin GND Arduino UNO R3.\n'
                        'Hubungkan pin output PH Sensor ke pin analog Arduino UNO R3.\n\n'
                        '3. Hubungkan Relay ke Arduino UNO R3\n'
                        'Relay:\n'
                        'Hubungkan pin IN Relay ke pin digital Arduino UNO R3.\n'
                        'Hubungkan pin VCC Relay ke pin 5V Arduino UNO R3.\n'
                        'Hubungkan pin GND Relay ke pin GND Arduino UNO R3.\n\n'
                        '4. Hubungkan WEMOS ke Arduino UNO R3\n'
                        'WEMOS:\n'
                        'Hubungkan pin TX WEMOS ke pin RX Arduino UNO R3.\n'
                        'Hubungkan pin RX WEMOS ke pin TX Arduino UNO R3.\n'
                        'Hubungkan pin GND WEMOS ke pin GND Arduino UNO R3.\n'
                        'Hubungkan pin VCC WEMOS ke pin 5V Arduino UNO R3.\n\n'
                        '5. Hubungkan Pompa AC 220V ke Relay\n'
                        'Pompa AC 220V:\n'
                        'Hubungkan terminal pompa ke terminal NO (Normally Open) pada relay.\n'
                        'Hubungkan terminal netral pompa ke terminal netral pada sumber daya.\n'
                        'Pastikan tegangan pompa sesuai dengan tegangan sumber daya.\n\n'
                        '6. Hubungkan Baterai ke Arduino UNO R3\n'
                        'Baterai:\n'
                        'Hubungkan terminal positif baterai ke pin VCC Arduino UNO R3.\n'
                        'Hubungkan terminal negatif baterai ke pin GND Arduino UNO R3.\n\n'
                        '7. Konfigurasi Arduino UNO R3\n'
                        'Kode Program: Tulis kode program untuk membaca data dari sensor, memproses data, dan mengendalikan relay.\n'
                        'Library: Pastikan Anda telah menginstal library yang diperlukan untuk sensor dan modul Wi-Fi.\n\n'
                        '8. Upload Kode Program\n'
                        'Upload: Upload kode program ke Arduino UNO R3.\n\n'
                        '9. Konfigurasi WEMOS\n'
                        'Koneksi Wi-Fi: Konfigurasi WEMOS untuk terhubung ke jaringan Wi-Fi Anda.\n'
                        'Koneksi Cloud: Konfigurasi WEMOS untuk mengirim data ke platform cloud yang Anda pilih.\n\n'
                        '10. Uji Sistem\n'
                        'Uji: Uji sistem dengan menjalankan program dan memeriksa apakah data sensor terkirim ke cloud dan relay berfungsi dengan benar.\n\n'
                        'Tips:\n'
                        'Pastikan semua koneksi kabel terpasang dengan benar dan aman.\n'
                        'Gunakan kabel yang sesuai untuk setiap komponen.\n'
                        'Pastikan tegangan baterai sesuai dengan kebutuhan Arduino UNO R3 dan komponen lainnya.\n'
                        'Gunakan library yang tepat untuk sensor dan modul Wi-Fi.\n'
                        'Lakukan pengujian secara menyeluruh sebelum menggunakan sistem.\n'
                        'Dokumentasikan konfigurasi dan kode program Anda untuk referensi di masa mendatang.\n\n'
                        'Catatan:\n'
                        'Panduan ini hanya memberikan gambaran umum tentang pemasangan sensor IoT.'
                        'Detail konfigurasi dan kode program mungkin bervariasi tergantung pada sensor, modul Wi-Fi, dan platform cloud yang Anda gunakan.'
                        ' Pastikan Anda memahami risiko yang terkait dengan penggunaan listrik dan komponen elektronik.'
                        'Selalu ikuti instruksi produsen untuk setiap komponen.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
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
