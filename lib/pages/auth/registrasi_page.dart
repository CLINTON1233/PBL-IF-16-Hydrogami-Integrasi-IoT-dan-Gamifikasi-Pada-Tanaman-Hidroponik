import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/auth/login_page.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({super.key});

  @override
  RegistrasiPageState createState() => RegistrasiPageState();
}

class RegistrasiPageState extends State<RegistrasiPage> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Agar keyboard tidak menyebabkan overflow
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 36, 209, 126),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Tidak bisa digeser
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                        'assets/hydrogami_logo.png',
                        height: 120.0,
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: const BoxDecoration(
                            color: Color(0xFF29CC74),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(60),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(
                                  label: "Nama",
                                  hint: "Masukkan Nama Anda",
                                ),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  label: "Email",
                                  hint: "Masukkan Email Anda",
                                ),
                                const SizedBox(height: 10),
                                _buildPasswordField(
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
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginPage()),
                                    );
                                  },
                                  child: Text(
                                    'Daftar',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF29CC74),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginPage()),
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

  Widget _buildTextField({
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
          style: GoogleFonts.poppins(
            color: const Color(0xFF2ABD77),
            fontSize: 12.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF2ABD77),
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
          obscureText: !isPasswordVisible,
          style: GoogleFonts.poppins(
            color: const Color(0xFF2ABD77),
            fontSize: 12.0,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF2ABD77),
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
                color: const Color(0xFF2ABD77),
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
      ],
    );
  }
}
