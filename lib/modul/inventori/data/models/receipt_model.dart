import '../../domain/entities/receipt.dart';
import 'package:mitra/modul/toko/data/models/shop_model.dart';
import 'product_model.dart';

class ReceiptItemModel extends ReceiptItem {
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
  final double? discount;
  @override
  final double? costPrice;
  @override
  final double? costPerUnit;

  const ReceiptItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.measureType,
    required this.subtotal,
    this.discount,
    this.costPrice,
    this.costPerUnit,
  }) : super(
          id: id,
          product: product,
          quantity: quantity,
          measureType: measureType,
          subtotal: subtotal,
          discount: discount,
          costPrice: costPrice,
          costPerUnit: costPerUnit,
        );

  factory ReceiptItemModel.fromEntity(ReceiptItem item) {
    return ReceiptItemModel(
      id: item.id,
      product: ProductModel.fromEntity(item.product),
      quantity: item.quantity,
      measureType: item.measureType,
      subtotal: item.subtotal,
      discount: item.discount,
      costPrice: item.costPrice,
      costPerUnit: item.costPerUnit,
    );
  }

  ReceiptItem toEntity() {
    return ReceiptItem(
      id: id,
      product: product.toEntity(),
      quantity: quantity,
      measureType: measureType,
      subtotal: subtotal,
      discount: discount,
      costPrice: costPrice,
      costPerUnit: costPerUnit,
    );
  }
}

class ReceiptModel extends Receipt {
  @override
  final String id;
  @override
  final DateTime createdDate;
  final String? createdBy;
  final List<ReceiptItemModel> receiptItems;
  @override
  final double totalAmount;
  @override
  final String status;
  final ShopModel? shopModel;
  @override
  final double? totalDiscount;
  @override
  final double? taxPercentage;
  @override
  final String? paymentMethod;

  const ReceiptModel({
    required this.id,
    required this.createdDate,
    required this.receiptItems,
    required this.totalAmount,
    required this.status,
    this.createdBy,
    this.shopModel,
    this.totalDiscount,
    this.taxPercentage,
    this.paymentMethod,
  }) : super(
          id: id,
          createdDate: createdDate,
          items: receiptItems,
          totalAmount: totalAmount,
          status: status,
          createdBy: createdBy,
          shop: shopModel,
          totalDiscount: totalDiscount,
          taxPercentage: taxPercentage,
          paymentMethod: paymentMethod,
        );

  factory ReceiptModel.fromEntity(Receipt receipt) {
    return ReceiptModel(
      id: receipt.id,
      createdDate: receipt.createdDate,
      receiptItems: receipt.items
          .map((item) => ReceiptItemModel.fromEntity(item))
          .toList(),
      totalAmount: receipt.totalAmount,
      status: receipt.status,
      createdBy: receipt.createdBy,
      shopModel:
          receipt.shop != null ? ShopModel.fromEntity(receipt.shop!) : null,
      totalDiscount: receipt.totalDiscount,
      taxPercentage: receipt.taxPercentage,
      paymentMethod: receipt.paymentMethod,
    );
  }

  Receipt toEntity() {
    return Receipt(
      id: id,
      createdDate: createdDate,
      items: receiptItems.map((item) => item.toEntity()).toList(),
      totalAmount: totalAmount,
      status: status,
      createdBy: createdBy,
      shop: shopModel,
      totalDiscount: totalDiscount,
      taxPercentage: taxPercentage,
      paymentMethod: paymentMethod,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdDate': createdDate.toIso8601String(),
      'items': receiptItems.map((item) {
        return {
          'id': item.id,
          'product': item.product.toMap(),
          'quantity': item.quantity,
          'measureType': item.measureType,
          'subtotal': item.subtotal,
          'discount': item.discount,
          'costPrice': item.costPrice,
          'costPerUnit': item.costPerUnit,
        };
      }).toList(),
      'createdBy': createdBy ?? '',
      'shop': shopModel?.toMap() ?? {},
      'totalAmount': totalAmount,
      'status': status,
      'totalDiscount': totalDiscount ?? 0.0,
      'taxPercentage': taxPercentage ?? 0.0,
      'paymentMethod': paymentMethod ?? 'cash',
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      id: map['id'] as String? ?? '',
      createdDate: DateTime.parse(map['createdDate'] as String? ?? ''),
      receiptItems: (map['items'] as List?)
              ?.map((item) => ReceiptItemModel(
                    id: item['id'] as String? ?? '',
                    product: ProductModel.fromMap(item['product']),
                    quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
                    measureType: item['measureType'] as String? ?? 'amount',
                    subtotal: (item['subtotal'] as num?)?.toDouble() ?? 0.0,
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
      totalDiscount: (map['totalDiscount'] as num?)?.toDouble(),
      taxPercentage: (map['taxPercentage'] as num?)?.toDouble(),
      paymentMethod: (map['paymentMethod'] as String?)?.isNotEmpty == true
          ? (map['paymentMethod'] as String?)
          : 'cash',
    );
  }
}
