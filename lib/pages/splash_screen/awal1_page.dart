import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahkan ini
import 'package:google_fonts/google_fonts.dart';
import 'package:application_hydrogami/pages/splash_screen/awal2_page.dart';

class Awal1Page extends StatefulWidget {
  const Awal1Page({super.key});

  @override
  State<Awal1Page> createState() => _Awal1PageState();
}

class _Awal1PageState extends State<Awal1Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    // Animasi titik-titik
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Awal2Page()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            Image.asset(
              'assets/hydrogami_logo.png',
              width: 400,
              height: 200,
            ),

            // Animasi loading titik-titik tepat di bawah teks
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Opacity(
                        opacity: (index == (_controller.value * 3).floor() % 3)
                            ? 1.0
                            : 0.3,
                        child: const Text(
                          '.',
                          style:
                              TextStyle(fontSize: 50, color: Color(0xFF29CC74)),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Text(
                '',
                style: GoogleFonts.kurale(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF29CC74),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
