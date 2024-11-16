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
        centerTitle: true,
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
                  _buildBadge("Level 5", Colors.green),
                  _buildBadge("Reward", Colors.orange),
                  _buildBadge("Jumlah Koin: 500", Colors.amber),
                ],
              ),
              const SizedBox(height: 20),

              // Gambar tanaman
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: const DecorationImage(
                    image: AssetImage('assets/tanaman1.jpg'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              // Control Automatic
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Control Automatic"),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToggleButton(
                    "AB Mix",
                    _isABMixOn,
                    Colors.green,
                    (val) => setState(() => _isABMixOn = val),
                  ),
                  _buildToggleButton(
                    "Water",
                    _isWaterOn,
                    Colors.blue,
                    (val) => setState(() => _isWaterOn = val),
                  ),
                  _buildToggleButton(
                    "pH UP",
                    _isPHUpOn,
                    Colors.orange,
                    (val) => setState(() => _isPHUpOn = val),
                  ),
                  _buildToggleButton(
                    "pH DOWN",
                    _isPHDownOn,
                    Colors.yellow,
                    (val) => setState(() => _isPHDownOn = val),
                  ),
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
                shrinkWrap: true, // Agar ListView menyesuaikan konten
                physics:
                    const NeverScrollableScrollPhysics(), // Nonaktifkan scroll ListView
                itemCount: 10, // Contoh jumlah misi
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.task_alt, color: Colors.green),
                      title: Text("Misi ${index + 1}"),
                      subtitle: Text("Detail misi ke-${index + 1}"),
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
      child: Text(
        text,
        style: const TextStyle(color: Colors.black),
      ),
    );
  }

  // Fungsi untuk membuat tombol toggle
  Widget _buildToggleButton(
      String text, bool isActive, Color color, Function(bool) onToggle) {
    return ElevatedButton(
      onPressed: () => onToggle(!isActive),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? color : color.withOpacity(0.5),
      ),
      child: Text(text),
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
          // Sesuaikan navigasi sesuai kebutuhan
        },
        currentIndex: _bottomNavCurrentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            activeIcon: Icon(Icons.home, color: Colors.black),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notification_add, color: Colors.white),
            activeIcon: Icon(Icons.notification_add, color: Colors.black),
            label: 'Notifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment, color: Colors.white),
            activeIcon: Icon(Icons.assignment, color: Colors.black),
            label: 'Panduan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.white),
            activeIcon: Icon(Icons.person, color: Colors.black),
            label: 'Akun',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.white,
      ),
    );
  }
}
