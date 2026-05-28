import '../../domain/entities/invoice.dart';
import 'package:mitra/modul/toko/data/models/shop_model.dart';
import 'product_model.dart';

class InvoiceItemModel extends InvoiceItem {
  @override
  final String id;
  @override
  final ProductModel product;
  @override
  final double quantity;
  @override
  final String measureType;
  @override
  final double subtotal;
  @override
  final DateTime? expirationDate;
  @override
  final double? discount;
  @override
  final double? costPrice;
  @override
  final double? costPerUnit;

  const InvoiceItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.measureType,
    required this.subtotal,
    this.expirationDate,
    this.discount,
    this.costPrice,
    this.costPerUnit,
  }) : super(
          id: id,
          product: product,
          quantity: quantity,
          measureType: measureType,
          subtotal: subtotal,
          expirationDate: expirationDate,
          discount: discount,
          costPrice: costPrice,
          costPerUnit: costPerUnit,
        );

  factory InvoiceItemModel.fromEntity(InvoiceItem item) {
    return InvoiceItemModel(
      id: item.id,
      product: ProductModel.fromEntity(item.product),
      quantity: item.quantity,
      measureType: item.measureType,
      subtotal: item.subtotal,
      expirationDate: item.expirationDate,
      discount: item.discount,
      costPrice: item.costPrice,
      costPerUnit: item.costPerUnit,
    );
  }

  InvoiceItem toEntity() {
    return InvoiceItem(
      id: id,
      product: product.toEntity(),
      quantity: quantity,
      measureType: measureType,
      subtotal: subtotal,
      expirationDate: expirationDate,
      discount: discount,
      costPrice: costPrice,
      costPerUnit: costPerUnit,
    );
  }
}

class InvoiceModel extends Invoice {
  @override
  final String id;
  @override
  final DateTime createdDate;
  final String? createdBy;
  final List<InvoiceItemModel> invoiceItems;
  @override
  final double totalAmount;
  @override
  final String status;
  final ShopModel? shopModel;
  @override
  final String? supplierName;
  @override
  final String? supplierPhone;
  @override
  final String? supplierAddress;
  @override
  final double? taxPercentage;

  const InvoiceModel({
    required this.id,
    required this.createdDate,
    required this.invoiceItems,
    required this.totalAmount,
    required this.status,
    this.createdBy,
    this.shopModel,
    this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    this.taxPercentage,
  }) : super(
          id: id,
          createdDate: createdDate,
          items: invoiceItems,
          totalAmount: totalAmount,
          status: status,
          supplierName: supplierName,
          supplierPhone: supplierPhone,
          supplierAddress: supplierAddress,
          taxPercentage: taxPercentage,
        );

  factory InvoiceModel.fromEntity(Invoice invoice) {
    return InvoiceModel(
      id: invoice.id,
      createdDate: invoice.createdDate,
      invoiceItems: invoice.items
          .map((item) => InvoiceItemModel.fromEntity(item))
          .toList(),
      totalAmount: invoice.totalAmount,
      status: invoice.status,
      createdBy: invoice.createdBy,
      shopModel:
          invoice.shop != null ? ShopModel.fromEntity(invoice.shop!) : null,
    );
  }

  Invoice toEntity() {
    return Invoice(
      id: id,
      createdDate: createdDate,
      items: invoiceItems.map((item) => item.toEntity()).toList(),
      totalAmount: totalAmount,
      status: status,
      createdBy: createdBy,
      shop: shopModel,
      supplierName: supplierName,
      supplierPhone: supplierPhone,
      supplierAddress: supplierAddress,
      taxPercentage: taxPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdDate': createdDate.toIso8601String(),
      'items': invoiceItems.map((item) {
        return {
          'id': item.id,
          'product': item.product.toMap(),
          'quantity': item.quantity,
          'measureType': item.measureType,
          'subtotal': item.subtotal,
          'expirationDate': item.expirationDate?.toIso8601String(),
          'discount': item.discount,
          'costPrice': item.costPrice,
          'costPerUnit': item.costPerUnit,
        };
      }).toList(),
      'createdBy': createdBy ?? '',
      'shop': shopModel?.toMap() ?? {},
      'totalAmount': totalAmount,
      'status': status,
      'supplierName': supplierName ?? '',
      'supplierPhone': supplierPhone ?? '',
      'supplierAddress': supplierAddress ?? '',
      'taxPercentage': taxPercentage ?? 0.0,
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String? ?? '',
      createdDate: DateTime.parse(map['createdDate'] as String? ?? ''),
      invoiceItems: (map['items'] as List?)
              ?.map((item) => InvoiceItemModel(
                    id: item['id'] as String? ?? '',
                    product: ProductModel.fromMap(item['product']),
                    quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
                    measureType: item['measureType'] as String? ?? 'amount',
                    subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0.0,
                    expirationDate: item['expirationDate'] != null &&
                            (item['expirationDate'] as String).isNotEmpty
                        ? DateTime.parse(item['expirationDate'] as String)
                        : null,
                    discount: (item['discount'] as num?)?.toDouble(),
                    costPrice: (item['costPrice'] as num?)?.toDouble(),
                    costPerUnit: (item['costPerUnit'] as num?)?.toDouble(),
                  ))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'completed',
      createdBy: (map['createdBy'] as String?)?.isNotEmpty == true
          ? (map['createdBy'] as String?)
          : null,
      shopModel: map['shop'] != null && (map['shop'] as Map).isNotEmpty
          ? ShopModel.fromMap(Map<String, dynamic>.from(map['shop']))
          : null,
      supplierName: (map['supplierName'] as String?)?.isNotEmpty == true
          ? (map['supplierName'] as String?)
          : null,
      supplierPhone: (map['supplierPhone'] as String?)?.isNotEmpty == true
          ? (map['supplierPhone'] as String?)
          : null,
      supplierAddress: (map['supplierAddress'] as String?)?.isNotEmpty == true
          ? (map['supplierAddress'] as String?)
          : null,
      taxPercentage: (map['taxPercentage'] as num?)?.toDouble(),
    );
  }
}
