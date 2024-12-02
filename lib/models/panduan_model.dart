import 'package:flutter/material.dart';

class PanduanModel extends StatefulWidget {
  const PanduanModel({super.key});

  @override
  State<PanduanModel> createState() => _PanduanModelState();
}

class _PanduanModelState extends State<PanduanModel> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class Panduan {
  final int idPanduan;
  final String judul;
  final String? deskPanduan;
  final String? gambar;
  final String? video;

  Panduan({
    required this.idPanduan,
    required this.judul,
    this.deskPanduan,
    this.gambar,
    this.video,
  });

  factory Panduan.fromJson(Map<String, dynamic> json) {
    return Panduan(
      idPanduan: json['id_panduan'],
      judul: json['judul'],
      deskPanduan: json['desk_panduan'],
      gambar: json['gambar'],
      video: json['video'],
    );
  }
}
