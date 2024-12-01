import 'dart:convert';

import 'package:application_hydrogami/pages/widgets/rounded_button.dart';
import 'package:application_hydrogami/services/auth_services.dart';
import 'package:application_hydrogami/services/globals.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/skala%20and%20plant/pilih_page.dart';
import 'package:application_hydrogami/pages/auth/registrasi_page.dart';
import 'package:http/http.dart' as http;

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

  LoginPressed() async {
    // Mengambil nilai email dan password dari controller
    email = emailController.text;
    password = passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      try {
        http.Response response = await AuthServices.login(email, password);
        Map responseMap = jsonDecode(response.body);

        if (response.statusCode == 200) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => const PilihPage(),
            ),
          );
        } else {
          if (responseMap.containsKey('email')) {
            errorSnackBar(context, 'Email tidak valid');
          } else if (responseMap.containsKey('password')) {
            errorSnackBar(context, 'Password salah');
          } else {
            errorSnackBar(context, 'Terjadi kesalahan, coba lagi');
          }
        }
      } catch (e) {
        errorSnackBar(context, 'Terjadi kesalahan, coba lagi');
      }
    } else {
      errorSnackBar(context, 'Isi Semua Field');
    }
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
                      Container(height: 25, color: const Color(0xFF2ABD77)),
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
                      Image.asset('assets/hydrogami_logo.png', height: 120.0),
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
                                  color: const Color(0xFF2ABD77),
                                  fontSize: 12.0,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Email Anda',
                                  hintStyle: GoogleFonts.poppins(
                                    color: const Color(0xFF2ABD77),
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
                                  color: const Color(0xFF2ABD77),
                                  fontSize: 12.0,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan Kata Sandi',
                                  hintStyle: GoogleFonts.poppins(
                                    color: const Color(0xFF2ABD77),
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
                                      color: const Color(0xFF2ABD77),
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
                                onBtnPressed: () => LoginPressed(),
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
