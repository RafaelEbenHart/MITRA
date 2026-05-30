import 'package:equatable/equatable.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/modul/inventori/domain/entities/receipt.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';

class InventoryState extends Equatable {
  final List<InvoiceItem> items;
  final Barang? searchedProduct;
  final List<Barang> searchedProducts;
  final List<Invoice> invoiceHistory;
  final List<Receipt> salesReceipts;
  final bool isLoading;
  final String? errorMessage;
  final Invoice? lastCreatedInvoice;

  const InventoryState({
    required this.items,
    this.searchedProduct,
    this.searchedProducts = const [],
    required this.invoiceHistory,
    this.salesReceipts = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastCreatedInvoice,
  });

  InventoryState copyWith({
    List<InvoiceItem>? items,
    Barang? searchedProduct,
    List<Barang>? searchedProducts,
    List<Invoice>? invoiceHistory,
    List<Receipt>? salesReceipts,
    bool? isLoading,
    String? errorMessage,
    Invoice? lastCreatedInvoice,
  }) {
    return InventoryState(
      items: items ?? this.items,
      searchedProduct: searchedProduct ?? this.searchedProduct,
      searchedProducts: searchedProducts ?? this.searchedProducts,
      invoiceHistory: invoiceHistory ?? this.invoiceHistory,
      salesReceipts: salesReceipts ?? this.salesReceipts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastCreatedInvoice: lastCreatedInvoice ?? this.lastCreatedInvoice,
    );
  }

  double get totalAmount {
    return items.fold<double>(0.0, (sum, item) => sum + item.subtotal);
  }

  @override
  List<Object?> get props => [
        items,
        searchedProduct,
        searchedProducts,
        invoiceHistory,
        salesReceipts,
        isLoading,
        errorMessage,
        lastCreatedInvoice,
        totalAmount,
      ];
}
