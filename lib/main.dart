import 'package:application_hydrogami/pages/splash_screen/awal1_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HydroGami',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const Awal1Page(),
    );
  }
}
