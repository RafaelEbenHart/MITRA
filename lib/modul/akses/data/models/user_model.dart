import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String fullName;
  @JsonKey(fromJson: _roleFromJson, toJson: _roleToJson)
  final PeranPengguna role;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  AkunPengguna toEntity() => AkunPengguna(
        idPengguna: id,
        email: email,
        namaLengkap: fullName,
        peran: role,
        createdAt: createdAt,
        isActive: isActive,
      );

  factory UserModel.fromEntity(AkunPengguna entity) => UserModel(
        id: entity.idPengguna,
        email: entity.email,
        fullName: entity.namaLengkap,
        role: entity.peran,
        createdAt: entity.createdAt,
        isActive: entity.isActive,
      );

  static PeranPengguna _roleFromJson(String? value) {
    if (value == null) return PeranPengguna.karyawan;

    final normalized = value.toLowerCase();
    if (normalized == 'pemilik' || normalized == 'owner') {
      return PeranPengguna.pemilik;
    }
    if (normalized == 'kasir' ||
        normalized == 'karyawan' ||
        normalized == 'operational') {
      return PeranPengguna.karyawan;
    }

    return PeranPengguna.values.firstWhere(
      (e) => e.toString() == 'PeranPengguna.$normalized',
      orElse: () => PeranPengguna.karyawan,
    );
  }

  static String _roleToJson(PeranPengguna role) {
    return role.toString().split('.').last;
  }
}
