import 'package:application_hydrogami/pages/beranda_page.dart';
import 'package:application_hydrogami/pages/monitoring/notifikasi_page.dart';
import 'package:application_hydrogami/pages/panduan/panduan_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isLoading = false;

  int _bottomNavCurrentIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _usernameController.text = prefs.getString('username') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');

        if (token == null || token.isEmpty) {
          _showCustomSnackBar(context, 'Tolong login kembali', Colors.amber);
          return;
        }

        // Tentukan field mana yang akan diupdate
        Map<String, dynamic> updates = {};

        // Check apakah username berubah
        final storedUsername = prefs.getString('username') ?? '';
        if (_usernameController.text != storedUsername) {
          updates['username'] = _usernameController.text;
        }

        // Check apakah email berubah
        final storedEmail = prefs.getString('email') ?? '';
        if (_emailController.text != storedEmail) {
          updates['email'] = _emailController.text;
        }

        // Check apakah ada password baru
        String? newPassword;
        if (_newPasswordController.text.isNotEmpty) {
          if (_currentPasswordController.text.isEmpty) {
            _showCustomSnackBar(
                context, 'Perlu memperbarui kata sandi', Colors.red);
            return;
          }
          newPassword = _newPasswordController.text;
        }

        final response = await AuthServices.updateProfile(
          token,
          username: updates['username'],
          email: updates['email'],
          currentPassword: _currentPasswordController.text.isNotEmpty
              ? _currentPasswordController.text
              : null,
          password: newPassword,
        );

        var responseBody = json.decode(response.body);

        if (response.statusCode == 200) {
          // Update local storage jika berhasil
          if (updates['username'] != null) {
            await prefs.setString('username', updates['username']);
          }
          if (updates['email'] != null) {
            await prefs.setString('email', updates['email']);
          }

          _showCustomSnackBar(
              context, 'Profil berhasil diperbarui', Colors.green);

          // Clear password fields after successful update
          _currentPasswordController.clear();
          _newPasswordController.clear();
          // Tambahkan navigasi ke BerandaPage
          //Navigator.pushReplacement(
          // context,
          // MaterialPageRoute(builder: (context) => const BerandaPage()),
          // );
        } else {
          _showCustomSnackBar(
              context,
              'Gagal memperbarui profil: ${responseBody['message']}',
              Colors.red);
        }
      } catch (e) {
        print('Error updating profile: $e');
        _showCustomSnackBar(
          context, 'Terjadi error: $e', Colors.red);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        // Hitung posisi di bawah AppBar
        top: MediaQuery.of(context).padding.top +
            kToolbarHeight +
            10, // kToolbarHeight adalah tinggi default AppBar
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                      onPressed: () {
                        overlayEntry.remove();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF24D17E),
        elevation: 2,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'Kelola Profil',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp),
          iconSize: 20.0,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BerandaPage()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                const SizedBox(height: 20),
                buildTextFieldWithValidation(
                  'Nama',
                  'Masukkan Nama Anda',
                  _usernameController,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan nama Anda';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                buildTextFieldWithValidation(
                  'Email',
                  'Masukkan Email Anda',
                  _emailController,
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan email Anda';
                    }
                    if (!value.contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                buildTextFieldWithValidation(
                  'Password Saat Ini',
                  'Masukkan Password Saat Ini',
                  _currentPasswordController,
                  (value) {
                    if (_newPasswordController.text.isNotEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'isi untuk memperbarui password baru';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                buildTextFieldWithValidation(
                  'Password Baru',
                  'Masukkan Password Baru',
                  _newPasswordController,
                  (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Password baru harus minimal 6 karakter';
                    }
                    return null;
                  },
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24D17E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // Build Text Field
  Widget buildTextFieldWithValidation(
    String labelText,
    String placeholder,
    TextEditingController controller,
    String? Function(String?) validator, {
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              validator: validator,
              style: GoogleFonts.poppins(fontSize: 12),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF24D17E),
                  fontSize: 12,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Fungsi untuk membuat Bottom Navigation Bar
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

          // Navigasi halaman berdasarkan index
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const BerandaPage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const NotifikasiPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PanduanPage()),
              );
              break;
            case 3:
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
