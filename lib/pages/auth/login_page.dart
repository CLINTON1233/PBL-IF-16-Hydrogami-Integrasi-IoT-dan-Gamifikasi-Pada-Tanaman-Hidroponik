import 'dart:convert';
import 'package:application_hydrogami/pages/widgets/rounded_button.dart';
import 'package:application_hydrogami/services/auth_services.dart';
import 'package:application_hydrogami/services/globals.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/skala%20and%20plant/pilih_page.dart';
import 'package:application_hydrogami/pages/auth/registrasi_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_hydrogami/pages/beranda_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPasswordVisible = false;

  String email = '';
  String password = '';

  // Tambahkan TextEditingController untuk email dan password
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('https://admin-hydrogami.up.railway.app/api/auth/login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        // Cek apakah user sudah memilih tanaman dan skala
        final hasPlant = prefs.getString('selected_plant') != null;
        final hasScale =
            prefs.getString('selected_scale') != null; // Simpan token
        if (hasPlant && hasScale) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BerandaPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PilihPage()),
          );
        }
      } else {
        _showCustomSnackBar(
            context, 'Login gagal. Periksa kredensial anda', Colors.red);
      }
    } catch (e) {
      _showCustomSnackBar(
          context, 'Terjadi kesalahan saat login', Colors.green);
    }
  }

  loginPressed() async {
    // Mengambil nilai email dan password dari controller
    email = emailController.text;
    password = passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        http.Response response = await AuthServices.login(email, password);
        Map responseMap = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username', responseMap['user']['username']);

          // Cek tokennya ada atau ngga
          String? savedToken = prefs.getString('token');
          print('Token from AuthServices: $savedToken');

          // Cek apakah user sudah memilih tanaman dan skala
          final hasPlant = prefs.getString('selected_plant') != null;
          final hasScale = prefs.getString('selected_scale') != null;

          // Cek apakah ini first time login untuk user ini
          String userKey =
              '${responseMap['user']['username']}_has_completed_setup';
          bool hasCompletedSetup = prefs.getBool(userKey) ?? false;

          if (hasPlant && hasScale && hasCompletedSetup) {
            // User sudah pernah setup sebelumnya, langsung ke beranda
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const BerandaPage(),
              ),
            );
          } else {
            // User belum setup atau user baru, ke halaman pilih
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const PilihPage(),
              ),
            );
          }
        } else {
          if (responseMap.containsKey('email')) {
            _showCustomSnackBar(context, 'Email tidak valid', Colors.red);
          } else if (responseMap.containsKey('password')) {
            _showCustomSnackBar(context, 'Password salah', Colors.red);
          } else {
            _showCustomSnackBar(
                context, 'Terjadi kesalahan, coba lagi', Colors.red);
          }
        }
      } catch (e) {
        _showCustomSnackBar(
            context, 'Terjadi kesalahan, coba lagi', Colors.red);
      }
    } else {
      _showCustomSnackBar(context, 'Isi Semua Field', Colors.red);
    }
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 
            10, 
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
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Container(height: 55, color: const Color(0xFF2ABD77)),
                      const SizedBox(height: 15),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF29CC74),
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
                                      const Icon(Icons.arrow_back,
                                          color: Colors.white, size: 16),
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
                            const SizedBox(height: 10),
                            Text(
                              "Login",
                              style: GoogleFonts.poppins(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              "Login ke akun anda - Nikmati fitur eksklusif dan masih banyak lagi",
                              style: GoogleFonts.poppins(
                                fontSize: 13.0,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Image.asset('assets/logo.png', height: 120.0),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: const BoxDecoration(
                            color: Color(0xFF29CC74),
                            borderRadius:
                                BorderRadius.only(topLeft: Radius.circular(60)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                'Email',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextFormField(
                                controller:
                                    emailController, // Tambahkan controller
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Email Anda',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Kata Sandi',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              TextFormField(
                                controller:
                                    passwordController, // Tambahkan controller
                                obscureText: !_isPasswordVisible,
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 12.0,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Kata Sandi',
                                  hintStyle: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 12.0,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 15),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.black,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible =
                                            !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              RoundedButton(
                                btnText: 'Login',
                                onBtnPressed: () => loginPressed(),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const RegistrasiPage()),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Belum memiliki akun? ',
                                      style: GoogleFonts.poppins(
                                          fontSize: 14, color: Colors.white),
                                      children: [
                                        TextSpan(
                                          text: 'Daftar',
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
          },
        ),
      ),
    );
  }
}
