import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';

class ProductModel extends Barang {
  @override
  final String idBarang;
  @override
  final String namaBarang;
  @override
  final String kodeBarang;
  @override
  final double hargaSatuan;
  @override
  final double? stokSaatIni;
  @override
  final String? measureType;
  @override
  final List<StockBatch>? batches;
  @override
  final double? latestCostPrice;
  @override
  final double? latestCostPerUnit;

  const ProductModel({
    required this.idBarang,
    required this.namaBarang,
    required this.kodeBarang,
    required this.hargaSatuan,
    this.stokSaatIni,
    this.measureType,
    this.batches,
    this.latestCostPrice,
    this.latestCostPerUnit,
  }) : super(
          idBarang: idBarang,
          namaBarang: namaBarang,
          kodeBarang: kodeBarang,
          hargaSatuan: hargaSatuan,
          stokSaatIni: stokSaatIni,
          measureType: measureType,
          batches: batches,
          latestCostPrice: latestCostPrice,
          latestCostPerUnit: latestCostPerUnit,
        );

  factory ProductModel.fromEntity(Barang product) {
    return ProductModel(
      idBarang: product.idBarang,
      namaBarang: product.namaBarang,
      kodeBarang: product.kodeBarang,
      hargaSatuan: product.hargaSatuan,
      stokSaatIni: product.stokSaatIni,
      measureType: product.measureType,
      batches: (product.batches != null) ? product.batches : null,
      latestCostPrice: product.latestCostPrice,
      latestCostPerUnit: product.latestCostPerUnit,
    );
  }

  Barang toEntity() {
    return Barang(
      idBarang: idBarang,
      namaBarang: namaBarang,
      kodeBarang: kodeBarang,
      hargaSatuan: hargaSatuan,
      stokSaatIni: stokSaatIni,
      measureType: measureType,
      batches: batches,
      latestCostPrice: latestCostPrice,
      latestCostPerUnit: latestCostPerUnit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': idBarang,
      'name': namaBarang,
      'barcode': kodeBarang,
      'price': hargaSatuan,
      'currentQuantity': stokSaatIni,
      'measureType': measureType,
      'latestCostPrice': latestCostPrice,
      'latestCostPerUnit': latestCostPerUnit,
      'batches': batches
          ?.map((b) => {
                'id': b.id,
                'quantity': b.quantity,
                'expirationDate': b.expirationDate.toIso8601String(),
                'invoiceId': b.invoiceId,
                'isExpired': b.isExpired,
                'costPrice': b.costPrice,
                'costPerUnit': b.costPerUnit,
              })
          .toList(),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      idBarang: map['id'] as String? ?? '',
      namaBarang: map['name'] as String? ?? '',
      kodeBarang: map['barcode'] as String? ?? '',
      hargaSatuan: (map['price'] as num?)?.toDouble() ?? 0.0,
      stokSaatIni: (map['currentQuantity'] as num?)?.toDouble(),
      measureType: map['measureType'] as String?,
      latestCostPrice: (map['latestCostPrice'] as num?)?.toDouble(),
      latestCostPerUnit: (map['latestCostPerUnit'] as num?)?.toDouble(),
      batches: (map['batches'] as List?)
          ?.map((b) => StockBatch(
                id: b['id'] as String? ?? '',
                quantity: (b['quantity'] as num?)?.toDouble() ?? 0.0,
                expirationDate: b['expirationDate'] is String
                    ? DateTime.parse(b['expirationDate'] as String)
                    : (b['expirationDate'] as Timestamp).toDate(),
                invoiceId: b['invoiceId'] as String?,
                isExpired: b['isExpired'] as bool? ?? false,
                costPrice: (b['costPrice'] as num?)?.toDouble(),
                costPerUnit: (b['costPerUnit'] as num?)?.toDouble(),
              ))
          .toList(),
    );
  }
}

