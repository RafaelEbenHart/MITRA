import 'package:equatable/equatable.dart';

enum PeranPengguna { pemilik, karyawan }

class AkunPengguna extends Equatable {
  final String idPengguna;
  final String email;
  final String namaLengkap;
  final PeranPengguna peran;
  final DateTime createdAt;
  final bool isActive;

  const AkunPengguna({
    required this.idPengguna,
    required this.email,
    required this.namaLengkap,
    required this.peran,
    required this.createdAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [idPengguna, email, namaLengkap, peran, createdAt, isActive];
}
