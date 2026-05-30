import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitra/modul/kasir/domain/entities/cart_item.dart';
import 'package:mitra/modul/kasir/domain/entities/billing_tab.dart';
import 'package:mitra/modul/inventori/domain/usecases/product_usecases.dart';
import 'package:mitra/modul/inventori/domain/usecases/inventory_usecases.dart';
import 'package:mitra/modul/inventori/domain/entities/receipt.dart';
import 'package:mitra/infrastruktur/penyimpanan/firebase_database.dart';
import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/shared/format/printer_config.dart';
import 'package:mitra/infrastruktur/injeksi/service_locator.dart' as di;
import 'package:uuid/uuid.dart';

class BillingState {
  final List<BillingTab> tabs;
  final int currentTabIndex;
  final String? error;
  final bool isPrinting;
  final bool printSuccess;

  const BillingState({
    this.tabs = const [],
    this.currentTabIndex = -1,
    this.error,
    this.isPrinting = false,
    this.printSuccess = false,
  });

  BillingTab? get currentTab =>
      currentTabIndex >= 0 && currentTabIndex < tabs.length
          ? tabs[currentTabIndex]
          : null;

  List<ItemKeranjang> get cartItems => currentTab?.items ?? [];
  double get totalAmount => currentTab?.totalAmount ?? 0;
  bool get canCreateTab => tabs.length < 5;
  int get totalItems => currentTab?.totalItems ?? 0;

  BillingState copyWith({
    List<BillingTab>? tabs,
    int? currentTabIndex,
    String? error,
    bool clearError = false,
    bool? isPrinting,
    bool? printSuccess,
  }) {
    return BillingState(
      tabs: tabs ?? this.tabs,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      error: clearError ? null : (error ?? this.error),
      isPrinting: isPrinting ?? this.isPrinting,
      printSuccess: printSuccess ?? this.printSuccess,
    );
  }
}

class BillingNotifier extends StateNotifier<BillingState> {
  final GetProductByBarcodeUseCase getProductByBarcodeUseCase;
  final CreateReceiptUseCase createReceiptUseCase;

  BillingNotifier({
    required this.getProductByBarcodeUseCase,
    required this.createReceiptUseCase,
  }) : super(const BillingState());

  void initializeTabs() {
    if (state.currentTab != null) return;

    final firstTab = BillingTab(
      id: const Uuid().v4(),
      name: 'Pesanan 1',
      items: const [],
      createdAt: DateTime.now(),
    );

    state = state.copyWith(tabs: [firstTab], currentTabIndex: 0);
  }

  void createTab([String? name]) {
    if (!state.canCreateTab) {
      state = state.copyWith(
          error: 'Maksimal 5 pesanan. Hapus pesanan lama terlebih dahulu.');
      return;
    }

    final newTab = BillingTab(
      id: const Uuid().v4(),
      name: name ?? 'Pesanan ${state.tabs.length + 1}',
      items: const [],
      createdAt: DateTime.now(),
    );

    final updated = [...state.tabs, newTab];
    state = state.copyWith(
        tabs: updated, currentTabIndex: updated.length - 1, error: null);
  }

  void deleteTab(int tabIndex) {
    if (state.tabs.length <= 1) {
      state = state.copyWith(error: 'Harus ada minimal 1 pesanan');
      return;
    }

    final updated = [...state.tabs]..removeAt(tabIndex);
    int newIndex = state.currentTabIndex;
    if (newIndex >= updated.length) newIndex = updated.length - 1;

    state =
        state.copyWith(tabs: updated, currentTabIndex: newIndex, error: null);
  }

  void switchTab(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= state.tabs.length) return;
    state = state.copyWith(currentTabIndex: tabIndex, error: null);
  }

  Future<String?> scanBarcode(String barcode) async {
    if (state.currentTab == null) {
      state = state.copyWith(
          error: 'Buat pesanan terlebih dahulu sebelum menambah produk');
      return null;
    }

    final result = await getProductByBarcodeUseCase(barcode);
    return result.fold((failure) {
      state = state.copyWith(error: 'Produk tidak ditemukan: $barcode');
      return null;
    }, (product) {
      final successMsg = addProductToCart(product);
      if (successMsg == null) {
        final maxQuantity = product.measureType == 'weight' ? 100 : 200;
        final currentTab = state.currentTab;
        if (currentTab != null && currentTab.items.length >= 30) {
          state = state.copyWith(
              error:
                  'Keranjang penuh (max 30 item). Selesaikan pesanan terlebih dahulu.');
        } else {
          state = state.copyWith(
              error:
                  'Tidak bisa menambah ${product.namaBarang}. Kuantitas melebihi batas ($maxQuantity).');
        }
        return null;
      }
      return successMsg;
    });
  }

  String? addProductToCart(dynamic product, {int maxItems = 30}) {
    if (state.currentTab == null) {
      state = state.copyWith(
          error: 'Buat pesanan terlebih dahulu sebelum menambah produk');
      return null;
    }

    final currentItems = state.currentTab!.items;
    final totalCurrentItems = currentItems.length;

    // Check jika sudah mencapai max items (30)
    final existingIndex = currentItems
        .indexWhere((item) => item.barang.idBarang == product.idBarang);

    if (existingIndex < 0 && totalCurrentItems >= maxItems) {
      return null; // Keranjang penuh
    }

    // Validasi batas quantity berdasarkan measureType
    final maxQuantity = product.measureType == 'weight' ? 100 : 200;

    List<ItemKeranjang> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List<ItemKeranjang>.from(currentItems);
      final existingItem = updatedItems[existingIndex];
      final newQuantity = existingItem.jumlah + 1;

      // Check apakah quantity melebihi batas
      if (newQuantity > maxQuantity) {
        return null; // Quantity melebihi batas
      }

      updatedItems[existingIndex] = existingItem.copyWith(jumlah: newQuantity);
    } else {
      updatedItems = [...currentItems, ItemKeranjang(barang: product)];
    }

    final updatedTab = state.currentTab!.copyWith(items: updatedItems);
    final tabs = [...state.tabs];
    tabs[state.currentTabIndex] = updatedTab;

    state = state.copyWith(tabs: tabs, error: null);

    if (existingIndex >= 0) {
      return '${product.namaBarang} berhasil ditambahkan ke keranjang';
    } else {
      return '${product.namaBarang} berhasil ditambahkan ke keranjang';
    }
  }

  void removeProductFromCart(String productId) {
    if (state.currentTab == null) return;
    final updatedItems = state.currentTab!.items
        .where((item) => item.barang.idBarang != productId)
        .toList();
    final updatedTab = state.currentTab!.copyWith(items: updatedItems);
    final tabs = [...state.tabs];
    tabs[state.currentTabIndex] = updatedTab;
    state = state.copyWith(tabs: tabs);
  }

  void updateQuantity(String productId, int quantity) {
    if (state.currentTab == null) return;
    if (quantity <= 0) {
      removeProductFromCart(productId);
      return;
    }

    final index = state.currentTab!.items
        .indexWhere((item) => item.barang.idBarang == productId);
    if (index >= 0) {
      final items = List<ItemKeranjang>.from(state.currentTab!.items);
      items[index] = items[index].copyWith(jumlah: quantity);
      final updatedTab = state.currentTab!.copyWith(items: items);
      final tabs = [...state.tabs];
      tabs[state.currentTabIndex] = updatedTab;
      state = state.copyWith(tabs: tabs);
    }
  }

  void clearCart() {
    if (state.currentTab == null) return;
    final updatedTab = state.currentTab!.copyWith(items: const []);
    final tabs = [...state.tabs];
    tabs[state.currentTabIndex] = updatedTab;
    state = state.copyWith(tabs: tabs);
  }

  Future<void> printReceipt({
    required String shopName,
    required String address,
    String? phone,
    required String createdBy,
    String? footer,
    required double taxPercentage,
    required List<double> discountRates,
  }) async {
    if (state.currentTab == null || state.cartItems.isEmpty) {
      state = state.copyWith(error: 'Tidak ada produk untuk dicetak');
      return;
    }

    state = state.copyWith(isPrinting: true, printSuccess: false, error: null);

    try {
      final helper = PrinterHelper();
      final isConnected = await _ensurePrinterConnected();
      if (!isConnected) {
        state = state.copyWith(
          isPrinting: false,
          error:
              'Printer tidak terhubung. Pastikan printer Bluetooth terpasang atau periksa pengaturan printer.',
        );
        return;
      }

      final receiptItems = <ReceiptItem>[];
      final printerItems = <Map<String, dynamic>>[];
      double subtotal = 0.0;
      double totalDiscount = 0.0;

      for (final entry in state.cartItems.asMap().entries) {
        final index = entry.key;
        final cartItem = entry.value;
        final originalTotal = cartItem.totalHarga;
        final discountPercent =
            index < discountRates.length ? discountRates[index] : 0.0;
        final clampedDiscount = discountPercent.clamp(0.0, 100.0);
        final discountedTotal = originalTotal * (1 - clampedDiscount / 100);
        final discountValue = originalTotal - discountedTotal;

        subtotal += discountedTotal;
        totalDiscount += discountValue;

        printerItems.add({
          'name': cartItem.barang.namaBarang,
          'qty': cartItem.jumlah.toDouble(),
          'measureType': cartItem.barang.measureType ?? 'amount',
          'price': formatIdr(cartItem.barang.hargaSatuan),
          'discount': formatIdr(discountValue),
          'total': formatIdr(discountedTotal),
        });

        receiptItems.add(ReceiptItem(
          id: const Uuid().v4(),
          product: cartItem.barang,
          quantity: -cartItem.jumlah.toDouble(),
          measureType: cartItem.barang.measureType ?? 'amount',
          subtotal: discountedTotal,
          discount: clampedDiscount,
          costPrice: cartItem.barang.latestCostPrice,
          costPerUnit: cartItem.barang.latestCostPerUnit,
        ));
      }

      final taxAmount = subtotal * (taxPercentage / 100);
      final totalAmount = subtotal + taxAmount;

      await helper.print_format(
        shopName: shopName,
        address: address,
        phone: phone ?? '',
        items: printerItems,
        subtotal: formatIdr(subtotal),
        totalDiscount: formatIdr(totalDiscount),
        taxLabel:
            'PPN ${taxPercentage.toStringAsFixed(taxPercentage % 1 == 0 ? 0 : 1)}%',
        taxAmount: formatIdr(taxAmount),
        total: formatIdr(totalAmount),
        createdBy: createdBy,
        footer: footer ?? '',
      );

      final params = CreateReceiptParams(
        items: receiptItems,
        totalDiscount: totalDiscount,
        taxPercentage: taxPercentage,
      );
      final createResult = await createReceiptUseCase(params);

      createResult.fold((failure) {
        state = state.copyWith(
            isPrinting: false,
            error: 'Gagal menyimpan penjualan: ${failure.message}');
      }, (receipt) {
        state = state.copyWith(isPrinting: false, printSuccess: true);
        clearCart();
      });
    } catch (e) {
      state = state.copyWith(isPrinting: false, error: 'Print gagal: $e');
    }
  }

  Future<Map<String, String>?> _getSavedPrinterData() async {
    if (!FirebaseDatabase.isFirebaseAvailable) return null;
    try {
      final doc =
          await FirebaseDatabase.settingsCollection().doc('printer_data').get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      final mac = (data['printer_mac'] as String?)?.trim();
      final name = (data['printer_name'] as String?)?.trim();
      if (mac == null || mac.isEmpty) return null;
      return {
        'printer_mac': mac,
        'printer_name': name ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> _ensurePrinterConnected() async {
    final helper = PrinterHelper();
    if (helper.isConnected) return true;

    if (!await helper.checkPermission()) {
      return false;
    }

    final savedPrinter = await _getSavedPrinterData();
    if (savedPrinter != null) {
      final connected =
          await helper.connect(savedPrinter['printer_mac'] as String);
      if (connected) return true;
    }

    final devices = await helper.getBondedDevices();
    for (final device in devices) {
      final connected = await helper.connect(device.macAdress);
      if (connected) return true;
    }

    return false;
  }
}

final billingNotifierProvider =
    StateNotifierProvider<BillingNotifier, BillingState>(
        (ref) => BillingNotifier(
              getProductByBarcodeUseCase: di.sl<GetProductByBarcodeUseCase>(),
              createReceiptUseCase: di.sl<CreateReceiptUseCase>(),
            ));
