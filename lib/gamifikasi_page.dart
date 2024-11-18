import 'package:application_hydrogami/beranda_page.dart';
import 'package:application_hydrogami/notifikasi_page.dart';
import 'package:application_hydrogami/panduan_page.dart';
import 'package:application_hydrogami/profil_page.dart';
import 'package:flutter/material.dart';

class GamifikasiPage extends StatefulWidget {
  const GamifikasiPage({super.key});

  @override
  State<GamifikasiPage> createState() => _GamifikasiPageState();
}

class _GamifikasiPageState extends State<GamifikasiPage> {
  int _bottomNavCurrentIndex = 0;

  // Status toggle untuk kontrol
  bool _isABMixOn = false;
  bool _isWaterOn = false;
  bool _isPHUpOn = false;
  bool _isPHDownOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Gamifikasi',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Level, Reward, Jumlah Koin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBadge("Level 5", const Color(0xFF2ABD77)),
                  _buildBadge(
                      "Reward", const Color.fromARGB(255, 169, 165, 165)),
                  _buildBadge("Jumlah Koin: 500", Colors.orange),
                ],
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: const DecorationImage(
                      image: AssetImage('assets/tanaman1.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Control Automatic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Control Automatic",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Switch(
                    value: _isABMixOn,
                    onChanged: (val) {
                      setState(() {
                        _isABMixOn = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Kontrol AB Mix, Water, pH UP, pH DOWN
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _customToggleButton(
                        textTop: "AB",
                        textBottom: "MIX",
                        isActive: _isABMixOn,
                        activeColor: const Color(0xFF2AD5B6),
                        inactiveColor: const Color(0xFF2AD5B6).withOpacity(0.3),
                        onToggle: (val) => setState(() => _isABMixOn = val),
                      ),
                      _customToggleButton(
                        textTop: "Water",
                        textBottom: "",
                        isActive: _isWaterOn,
                        activeColor: const Color(0xFF50B7F2),
                        inactiveColor: const Color(0xFF50B7F2).withOpacity(0.5),
                        onToggle: (val) => setState(() => _isWaterOn = val),
                      ),
                      _customToggleButton(
                        textTop: "PH",
                        textBottom: "UP",
                        isActive: _isPHUpOn,
                        activeColor: const Color(0xFFFBBB00),
                        inactiveColor: const Color(0xFFFBBB00).withOpacity(0.5),
                        onToggle: (val) => setState(() => _isPHUpOn = val),
                      ),
                      _customToggleButton(
                        textTop: "PH",
                        textBottom: "DOWN",
                        isActive: _isPHDownOn,
                        activeColor: const Color(0xFFD9D9D9),
                        inactiveColor: const Color(0xFFD9D9D9).withOpacity(0.5),
                        onToggle: (val) => setState(() => _isPHDownOn = val),
                      ),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              // Bagian misi
              const Text(
                "Misi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFe9e9e9),
                    child: ListTile(
                      leading:
                          Icon(Icons.task_alt, color: Colors.green.shade600),
                      title: Text(
                        "Misi ${index + 1}",
                        style: const TextStyle(color: Colors.black),
                      ),
                      subtitle: Text(
                        "Detail misi ke-${index + 1}",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Fungsi untuk membuat badge
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
          )),
    );
  }

  Widget _customToggleButton({
    required String textTop,
    required String textBottom,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required Function(bool) onToggle,
  }) {
    return GestureDetector(
      onTap: () => onToggle(!isActive),
      child: InkWell(
        onTap: () => onToggle(!isActive),
        splashColor: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 85,
          height: 90,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: Offset(2, 2),
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                textTop,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                textBottom,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
