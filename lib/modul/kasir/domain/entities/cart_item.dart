import 'package:equatable/equatable.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';

class ItemKeranjang extends Equatable {
  final Barang barang;
  final int jumlah;

  const ItemKeranjang({
    required this.barang,
    this.jumlah = 1,
  });

  double get totalHarga => barang.hargaSatuan * jumlah;

  ItemKeranjang copyWith({
    Barang? barang,
    int? jumlah,
  }) {
    return ItemKeranjang(
      barang: barang ?? this.barang,
      jumlah: jumlah ?? this.jumlah,
    );
  }

  @override
  List<Object> get props => [barang, jumlah];
}


