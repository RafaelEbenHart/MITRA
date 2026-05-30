import 'package:equatable/equatable.dart';

class DataToko extends Equatable {
  final String namaToko;
  final String alamatBaris1;
  final String alamatBaris2;
  final String nomorTelepon;
  final String pesanStruk;
  final double taxPercentage;

  const DataToko({
    this.namaToko = '',
    this.alamatBaris1 = '',
    this.alamatBaris2 = '',
    this.nomorTelepon = '',
    this.pesanStruk = '',
    this.taxPercentage = 11.0,
  });

  DataToko copyWith({
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? phoneNumber,
    String? footerText,
    double? taxPercentage,
  }) {
    return DataToko(
      namaToko: name ?? this.namaToko,
      alamatBaris1: addressLine1 ?? this.alamatBaris1,
      alamatBaris2: addressLine2 ?? this.alamatBaris2,
      nomorTelepon: phoneNumber ?? this.nomorTelepon,
      pesanStruk: footerText ?? this.pesanStruk,
      taxPercentage: taxPercentage ?? this.taxPercentage,
    );
  }

  @override
  List<Object?> get props => [
        namaToko,
        alamatBaris1,
        alamatBaris2,
        nomorTelepon,
        pesanStruk,
        taxPercentage,
      ];
}
