import '../../domain/entities/shop.dart';

class ShopModel extends DataToko {
  @override
  final String namaToko;
  @override
  final String alamatBaris1;
  @override
  final String alamatBaris2;
  @override
  final String nomorTelepon;
  @override
  final String pesanStruk;

  const ShopModel({
    required this.namaToko,
    required this.alamatBaris1,
    required this.alamatBaris2,
    required this.nomorTelepon,
    required this.pesanStruk,
  }) : super(
          namaToko: namaToko,
          alamatBaris1: alamatBaris1,
          alamatBaris2: alamatBaris2,
          nomorTelepon: nomorTelepon,
          pesanStruk: pesanStruk,
        );

  factory ShopModel.fromEntity(DataToko shop) {
    return ShopModel(
      namaToko: shop.namaToko,
      alamatBaris1: shop.alamatBaris1,
      alamatBaris2: shop.alamatBaris2,
      nomorTelepon: shop.nomorTelepon,
      pesanStruk: shop.pesanStruk,
    );
  }

  DataToko toEntity() => this;

  Map<String, dynamic> toMap() {
    return {
      'name': namaToko,
      'addressLine1': alamatBaris1,
      'addressLine2': alamatBaris2,
      'phoneNumber': nomorTelepon,
      'footerText': pesanStruk,
    };
  }

  factory ShopModel.fromMap(Map<String, dynamic> map) {
    return ShopModel(
      namaToko: (map['name'] as String?) ?? '',
      alamatBaris1: (map['addressLine1'] as String?) ?? '',
      alamatBaris2: (map['addressLine2'] as String?) ?? '',
      nomorTelepon: (map['phoneNumber'] as String?) ?? '',
      pesanStruk: (map['footerText'] as String?) ?? '',
    );
  }
}

