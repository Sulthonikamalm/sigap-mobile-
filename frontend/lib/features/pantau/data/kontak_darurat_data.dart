import 'package:flutter/material.dart';

/// Model data kontak darurat.
/// Menyimpan informasi orang yang akan menerima notifikasi pemantauan.
class KontakDarurat {
  final String id;
  final String nama;
  final String nomorHp;
  final String inisial;
  final Color warnaAvatar;
  final bool aktif;

  const KontakDarurat({
    required this.id,
    required this.nama,
    required this.nomorHp,
    required this.inisial,
    required this.warnaAvatar,
    this.aktif = true,
  });
}

/// Data dummy kontak darurat untuk simulasi frontend.
/// Nanti diganti dengan data dari backend/local storage.
final daftarKontakDarurat = [
  const KontakDarurat(
    id: '1',
    nama: 'Mama',
    nomorHp: '0812-3456-7890',
    inisial: 'MA',
    warnaAvatar: Color(0xFF7BA8DC),
  ),
  const KontakDarurat(
    id: '2',
    nama: 'Satpam Kampus',
    nomorHp: '0821-9876-5432',
    inisial: 'SK',
    warnaAvatar: Color(0xFF5B9BD5),
  ),
  const KontakDarurat(
    id: '3',
    nama: 'Sahabat - Rina',
    nomorHp: '0856-1234-5678',
    inisial: 'RI',
    warnaAvatar: Color(0xFF4A90D9),
  ),
];
