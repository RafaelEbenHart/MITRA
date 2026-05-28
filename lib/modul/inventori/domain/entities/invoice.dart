import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/toko/domain/entities/shop.dart';

class InvoiceItem extends Equatable {
  final String id;
  final Barang product;
  final double quantity;
  final String measureType; // 'weight' or 'amount'
  final double subtotal; // quantity * product.price
  final DateTime?
      expirationDate; // optional expiration date for this stock batch
  final double? discount; // optional discount
  final double? costPrice; // Harga beli per unit
  final double? costPerUnit; // Berapa pcs/kg per cost

  const InvoiceItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.measureType,
    required this.subtotal,
    this.expirationDate,
    this.discount,
    this.costPrice,
    this.costPerUnit,
  });

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        measureType,
        subtotal,
        expirationDate,
        discount,
        costPrice,
        costPerUnit
      ];
}

class Invoice extends Equatable {
  final String id;
  final DateTime createdDate;
  final List<InvoiceItem> items;
  final double totalAmount;
  final String status; // 'pending', 'completed', etc.
  final String? createdBy;
  final DataToko? shop;
  final String? supplierName;
  final String? supplierPhone;
  final String? supplierAddress;
  final double? taxPercentage;

  const Invoice({
    required this.id,
    required this.createdDate,
    required this.items,
    required this.totalAmount,
    this.status = 'completed',
    this.createdBy,
    this.shop,
    this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    this.taxPercentage,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(createdDate);
  String get formattedTime => DateFormat('HH:mm:ss').format(createdDate);

  @override
  List<Object?> get props => [
        id,
        createdDate,
        items,
        totalAmount,
        status,
        createdBy,
        shop,
        supplierName,
        supplierPhone,
        supplierAddress,
        taxPercentage
      ];
}
