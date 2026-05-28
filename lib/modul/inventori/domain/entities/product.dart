import 'package:equatable/equatable.dart';

class Barang extends Equatable {
  final String
      idBarang; // Using barcode as ID usually, but keeping separate ID is safer
  final String namaBarang;
  final String kodeBarang;
  final double hargaSatuan; // Harga jual
  final double?
      stokSaatIni; // Current quantity in stock (null if no invoice yet)
  final String? measureType; // 'weight' or 'amount'
  final List<StockBatch>? batches;
  final double?
      latestCostPrice; // Latest harga beli (from most recent batch, read-only)
  final double?
      latestCostPerUnit; // Latest cost per unit (read-only from latest batch)

  const Barang({
    required this.idBarang,
    required this.namaBarang,
    required this.kodeBarang,
    required this.hargaSatuan,
    this.stokSaatIni,
    this.measureType,
    this.batches,
    this.latestCostPrice,
    this.latestCostPerUnit,
  });

  @override
  List<Object?> get props => [
        idBarang,
        namaBarang,
        kodeBarang,
        hargaSatuan,
        stokSaatIni,
        measureType,
        batches,
        latestCostPrice,
        latestCostPerUnit
      ];
}

class StockBatch extends Equatable {
  final String id;
  final double quantity;
  final DateTime expirationDate;
  final String? invoiceId;
  final bool isExpired;
  final double? costPrice; // Harga beli per unit
  final double? costPerUnit; // Berapa pcs/kg per cost

  const StockBatch({
    required this.id,
    required this.quantity,
    required this.expirationDate,
    this.invoiceId,
    this.isExpired = false,
    this.costPrice,
    this.costPerUnit,
  });

  @override
  List<Object?> get props => [
        id,
        quantity,
        expirationDate,
        invoiceId,
        isExpired,
        costPrice,
        costPerUnit
      ];
}
