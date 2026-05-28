import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitra/infrastruktur/injeksi/service_locator.dart' as di;
import 'package:mitra/shared/kontrak/usecase.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/modul/inventori/domain/usecases/inventory_usecases.dart';
import 'package:mitra/modul/inventori/domain/usecases/product_usecases.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_state.dart';

export 'inventory_state.dart';

class InventoryNotifier extends StateNotifier<InventoryState> {
  final CreateInvoiceUseCase createInvoiceUseCase;
  final GetInvoiceHistoryUseCase getInvoiceHistoryUseCase;
  final GetSalesReceiptsUseCase getSalesReceiptsUseCase;
  final UpdateProductQuantityUseCase updateProductQuantityUseCase;
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;
  final GetProductsUseCase getProductsUseCase;

  InventoryNotifier({
    required this.createInvoiceUseCase,
    required this.getInvoiceHistoryUseCase,
    required this.getSalesReceiptsUseCase,
    required this.updateProductQuantityUseCase,
    required this.getProductByBarcodeUseCase,
    required this.getProductsUseCase,
  }) : super(const InventoryState(
          items: [],
          invoiceHistory: [],
          salesReceipts: [],
        ));

  Future<void> searchProductByBarcode(String barcode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await getProductByBarcodeUseCase(barcode);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          searchedProduct: null,
        );
      },
      (product) {
        state = state.copyWith(
          isLoading: false,
          searchedProduct: product,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> searchProductByName(String name) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await getProductsUseCase(NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
          searchedProduct: null,
        );
      },
      (products) {
        try {
          final product = products.firstWhere(
            (p) => p.namaBarang.toLowerCase().contains(name.toLowerCase()),
          );
          state = state.copyWith(
            isLoading: false,
            searchedProduct: product,
            errorMessage: null,
          );
        } catch (_) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Produk tidak ditemukan',
            searchedProduct: null,
          );
        }
      },
    );
  }

  void addItemToInvoice(InvoiceItem item) {
    final newItems = List<InvoiceItem>.from(state.items)..add(item);
    state = state.copyWith(
      items: newItems,
      searchedProduct: null,
      errorMessage: null,
    );
  }

  void removeItemFromInvoice(String itemId) {
    final newItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: newItems);
  }

  void updateItemQuantity(String itemId, double quantity) {
    final newItems = state.items.map((item) {
      if (item.id == itemId) {
        final newSubtotal = quantity * item.product.hargaSatuan;
        return InvoiceItem(
          id: item.id,
          product: item.product,
          quantity: quantity,
          measureType: item.measureType,
          subtotal: newSubtotal,
          expirationDate: item.expirationDate,
          discount: item.discount,
          costPrice: item.costPrice,
          costPerUnit: item.costPerUnit,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void updateItem(InvoiceItem item) {
    final newItems = state.items.map((existingItem) {
      return existingItem.id == item.id ? item : existingItem;
    }).toList();
    state = state.copyWith(items: newItems);
  }

  void clearInvoice() {
    state = state.copyWith(
      items: [],
      searchedProduct: null,
      errorMessage: null,
      lastCreatedInvoice: null,
    );
  }

  Future<void> createInvoice({
    String? supplierName,
    String? supplierPhone,
    String? supplierAddress,
    double? taxPercentage,
  }) async {
    if (state.items.isEmpty) {
      state = state.copyWith(errorMessage: 'Tambahkan minimal satu item');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final params = CreateInvoiceParams(
      items: state.items,
      supplierName: supplierName,
      supplierPhone: supplierPhone,
      supplierAddress: supplierAddress,
      taxPercentage: taxPercentage,
    );
    final result = await createInvoiceUseCase(params);
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (invoice) {
        state = state.copyWith(
          isLoading: false,
          items: [],
          searchedProduct: null,
          lastCreatedInvoice: invoice,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> fetchInvoiceHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await getInvoiceHistoryUseCase(NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (invoices) {
        state = state.copyWith(
          isLoading: false,
          invoiceHistory: invoices,
          errorMessage: null,
        );
      },
    );
  }

  Future<void> fetchSalesReceipts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await getSalesReceiptsUseCase(NoParams());
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (receipts) {
        state = state.copyWith(
          isLoading: false,
          salesReceipts: receipts,
          errorMessage: null,
        );
      },
    );
  }

  void resetSearch() {
    state = state.copyWith(searchedProduct: null, errorMessage: null);
  }
}

final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>(
  (ref) => InventoryNotifier(
    createInvoiceUseCase: di.sl<CreateInvoiceUseCase>(),
    getInvoiceHistoryUseCase: di.sl<GetInvoiceHistoryUseCase>(),
    getSalesReceiptsUseCase: di.sl<GetSalesReceiptsUseCase>(),
    updateProductQuantityUseCase: di.sl<UpdateProductQuantityUseCase>(),
    getProductByBarcodeUseCase: di.sl<GetProductByBarcodeUseCase>(),
    getProductsUseCase: di.sl<GetProductsUseCase>(),
  ),
);
