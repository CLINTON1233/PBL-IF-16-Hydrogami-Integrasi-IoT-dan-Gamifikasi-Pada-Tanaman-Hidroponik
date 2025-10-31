import 'dart:convert';
import 'package:application_hydrogami/pages/widgets/rounded_button.dart';
import 'package:application_hydrogami/services/auth_services.dart';
import 'package:application_hydrogami/services/globals.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({super.key});

  @override
  RegistrasiPageState createState() => RegistrasiPageState();
}

class RegistrasiPageState extends State<RegistrasiPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _poinController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Fungsi untuk menyimpan data user termasuk tanggal bergabung
  Future<void> _saveUserData(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Simpan data user
    await prefs.setString('username', username);
    await prefs.setString('email', email);
    
    // Simpan tanggal bergabung saat registrasi
    final now = DateTime.now();
    final formattedDate = "${now.day} ${_getMonthName(now.month)} ${now.year}";
    await prefs.setString('join_date', formattedDate);
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Januari';
      case 2: return 'Februari';
      case 3: return 'Maret';
      case 4: return 'April';
      case 5: return 'Mei';
      case 6: return 'Juni';
      case 7: return 'Juli';
      case 8: return 'Agustus';
      case 9: return 'September';
      case 10: return 'Oktober';
      case 11: return 'November';
      case 12: return 'Desember';
      default: return '';
    }
  }

  void createAccountPressed() async {
    String username = _usernameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    int poin = _poinController.text.isEmpty
        ? 0
        : int.parse(_poinController.text.trim());

    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showCustomSnackBar(context, 'Semua field harus diisi', Colors.red);
      return;
    }

    if (password.length < 6) {
      _showCustomSnackBar(
          context, 'Password harus lebih dari 6 karakter', Colors.red);
      return;
    }

    if (password != confirmPassword) {
      _showCustomSnackBar(context, 'Password tidak sama', Colors.red);
      return;
    }

    bool emailValid =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(email);

    if (!emailValid) {
      _showCustomSnackBar(context, 'Email tidak valid', Colors.red);
      return;
    }

    try {
      http.Response response =
          await AuthServices.register(username, email, password, poin);

      Map responseMap = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Simpan data user ke SharedPreferences
        await _saveUserData(username, email);
        
        _showCustomSnackBar(context, 'Pendaftaran berhasil', Colors.green);
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        });
      } else {
        _showCustomSnackBar(
          context,
          responseMap['message'] ?? 'Terjadi kesalahan, coba lagi!',
          Colors.red,
        );
      }
    } catch (e) {
      _showCustomSnackBar(
        context,
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        Colors.red,
      );
    }
  }

  // Custom SnackBar function like in profil_page.dart
  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor:  const Color.fromARGB(255, 8, 143, 78),
          elevation: 0,
          toolbarHeight: 0,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 8, 143, 78),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/ic_back.png',
                                width: 16,
                                height: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Kembali',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Registrasi",
                      style: GoogleFonts.poppins(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      "Buat akun anda - Nikmati layanan kami dengan fitur-fitur terkini",
                      style: GoogleFonts.poppins(
                        fontSize: 13.0,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/logo.png',
                height: 120.0,
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color:  const Color.fromARGB(255, 8, 143, 78),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(60),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _usernameController,
                        label: "Username",
                        hint: "Masukkan Username",
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _emailController,
                        label: "Email",
                        hint: "Masukkan Email Anda",
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _passwordController,
                        label: "Kata Sandi",
                        hint: "Masukkan Kata Sandi",
                        isPasswordVisible: _isPasswordVisible,
                        toggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: "Konfirmasi Kata Sandi",
                        hint: "Konfirmasi Kata Sandi",
                        isPasswordVisible: _isConfirmPasswordVisible,
                        toggleVisibility: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      RoundedButton(
                        btnText: 'Daftar',
                        onBtnPressed: createAccountPressed,
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Sudah memiliki akun? ',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Login',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 12.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 12.0,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isPasswordVisible,
    required VoidCallback toggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextFormField(
          controller: controller,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 12.0,
          ),
          obscureText: !isPasswordVisible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 12.0,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}