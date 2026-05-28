import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/toko/domain/entities/shop.dart';

/// Represents a single item in a sales receipt
class ReceiptItem extends Equatable {
  final String id;
  final Barang product;
  final double quantity; // Should be negative for sales
  final String measureType; // 'weight' or 'amount'
  final double subtotal; // quantity * product.price
  final double? discount; // optional discount
  final double? costPrice; // Harga beli per unit (for COGS calculation)
  final double? costPerUnit; // Berapa pcs/kg per cost

  const ReceiptItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.measureType,
    required this.subtotal,
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
        discount,
        costPrice,
        costPerUnit
      ];
}

/// Represents a sales receipt (penjualan/struk)
class Receipt extends Equatable {
  final String id;
  final DateTime createdDate;
  final List<ReceiptItem> items; // All with negative quantities (outgoing)
  final double totalAmount; // Total revenue
  final String status; // 'pending', 'completed', etc.
  final String? createdBy; // Cashier/operator name
  final DataToko? shop;
  final double? totalDiscount;
  final double? taxPercentage;
  final String? paymentMethod; // 'cash', 'card', etc.

  const Receipt({
    required this.id,
    required this.createdDate,
    required this.items,
    required this.totalAmount,
    this.status = 'completed',
    this.createdBy,
    this.shop,
    this.totalDiscount,
    this.taxPercentage,
    this.paymentMethod,
  });

  String get formattedDate => DateFormat('dd/MM/yyyy').format(createdDate);
  String get formattedTime => DateFormat('HH:mm:ss').format(createdDate);

  /// Calculate total quantity sold
  double get totalQuantity =>
      items.fold<double>(0.0, (sum, item) => sum + item.quantity.abs());

  /// Calculate total cost of goods sold
  double get totalCost => items.fold<double>(0.0, (sum, item) {
        final cost = item.costPrice ?? 0;
        return sum + (cost * item.quantity.abs());
      });

  /// Calculate gross profit
  double get grossProfit => totalAmount - totalCost;

  /// Calculate profit margin percentage
  double get profitMargin =>
      totalAmount > 0 ? (grossProfit / totalAmount) * 100 : 0;

  @override
  List<Object?> get props => [
        id,
        createdDate,
        items,
        totalAmount,
        status,
        createdBy,
        shop,
        totalDiscount,
        taxPercentage,
        paymentMethod,
      ];
}
