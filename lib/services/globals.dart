import 'package:flutter/material.dart';

const String baseURL = "https://admin-hydrogami.up.railway.app/api/"; //emulator localhost
const Map<String, String> headers = {
  "Content-Type": "application/json",
  "Accept": "application/json", // Tambahkan ini
};

errorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Colors.red,
    content: Text(text),
    duration: const Duration(seconds: 1),
  ));
}

successSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: Colors.green,
    content: Text(
      text,
      style: const TextStyle(color: Colors.white),
    ),
    duration: const Duration(seconds: 1),
  ));
}
