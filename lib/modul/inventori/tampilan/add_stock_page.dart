import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_provider.dart';
import 'package:mitra/modul/inventori/tampilan/widgets/product_search_card.dart';
import 'package:mitra/modul/inventori/tampilan/widgets/invoice_item_row.dart';
import 'package:mitra/modul/inventori/tampilan/invoice_preview_page.dart';
import 'package:mitra/modul/inventori/tampilan/invoice_list_page.dart';
import 'package:mitra/modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;

class AddStockPage extends ConsumerStatefulWidget {
  final Barang? initialProduct;

  const AddStockPage({super.key, this.initialProduct});

  @override
  ConsumerState<AddStockPage> createState() => _AddStockPageState();
}

class _AddStockPageState extends ConsumerState<AddStockPage> {
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _dialogQtyController;
  late TextEditingController _supplierNameController;
  late TextEditingController _supplierPhoneController;
  late TextEditingController _supplierAddressController;
  late TextEditingController _taxPercentageController;
  bool _useBarcodeScanner = false;
  late MobileScannerController _scannerController;
  bool _didResetOnAppear = false;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController();
    _nameController = TextEditingController();
    _dialogQtyController = TextEditingController();
    _supplierNameController = TextEditingController();
    _supplierPhoneController = TextEditingController();
    _supplierAddressController = TextEditingController();
    _taxPercentageController = TextEditingController(text: '0');
    _scannerController = MobileScannerController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resetPageState();
      _didResetOnAppear = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didResetOnAppear && ModalRoute.of(context)?.isCurrent == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _resetPageState();
        _didResetOnAppear = true;
      });
    }
  }

  void _resetPageState() {
    if (!mounted) return;
    setState(() {
      _useBarcodeScanner = false;
    });

    _supplierPhoneController.clear();
    _supplierAddressController.clear();

    final notifier = ref.read(inventoryNotifierProvider.notifier);
    notifier.clearInvoice();
    notifier.fetchInvoiceHistory();
    if (widget.initialProduct != null) {
      notifier.searchProductByBarcode(widget.initialProduct!.kodeBarang);
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _dialogQtyController.dispose();
    _supplierNameController.dispose();
    _supplierPhoneController.dispose();
    _supplierAddressController.dispose();
    _taxPercentageController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _searchProduct(InventoryNotifier notifier) {
    if (_barcodeController.text.isNotEmpty) {
      notifier.searchProductByBarcode(_barcodeController.text);
    } else if (_nameController.text.isNotEmpty) {
      notifier.searchProductByName(_nameController.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan barcode atau nama produk')),
      );
    }
  }

  void _handleBarcodeScan(String barcode, InventoryNotifier notifier) {
    _barcodeController.text = barcode;
    _scannerController.stop();
    setState(() {
      _useBarcodeScanner = false;
    });
    _searchProduct(notifier);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryNotifierProvider);
    ref.listen<InventoryState>(inventoryNotifierProvider, (previous, next) {
      if (previous?.lastCreatedInvoice != next.lastCreatedInvoice &&
          next.lastCreatedInvoice != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Delay mutations to avoid modifying providers during build
          ref
              .read(product_provider.productNotifierProvider.notifier)
              .loadProducts();
          ref.read(inventoryNotifierProvider.notifier).fetchInvoiceHistory();
        });
      }
    });
    final notifier = ref.read(inventoryNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Stok'),
        actions: [
          IconButton(
            tooltip: 'Daftar Faktur',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const InvoiceListPage(),
              ));
            },
            icon: const Icon(Icons.receipt_long),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detail Faktur',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nama Penjual/Distributor',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _supplierNameController,
                        decoration: InputDecoration(
                          hintText:
                              'Masukkan nama penjual atau distributor (Opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No. Telepon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _supplierPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Masukkan nomor telepon (Opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Alamat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _supplierAddressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Masukkan alamat penjual atau distributor (Opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Pajak (%)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _taxPercentageController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.percent),
                          suffixText: '%',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cari Produk',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (!_useBarcodeScanner) ...[
                        TextField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Kode Produk',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.qr_code),
                          ),
                          onSubmitted: (_) => _searchProduct(notifier),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Atau',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Produk',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.search),
                          ),
                          onSubmitted: (_) => _searchProduct(notifier),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _searchProduct(notifier),
                                icon: const Icon(Icons.search),
                                label: const Text('Cari'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _useBarcodeScanner = true;
                                  });
                                },
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Pindai'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_useBarcodeScanner) ...[
                        SizedBox(
                          height: 300,
                          child: MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              if (barcodes.isNotEmpty) {
                                final barcode = barcodes.first.rawValue;
                                if (barcode != null) {
                                  _handleBarcodeScan(barcode, notifier);
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            _scannerController.stop();
                            setState(() {
                              _useBarcodeScanner = false;
                            });
                          },
                          child: const Text('Batal Pindai'),
                        ),
                      ],
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (state.searchedProduct != null)
                ProductSearchCard(
                  product: state.searchedProduct!,
                  onAddTap: () {
                    _showQuantityDialog(context);
                  },
                ),
              const SizedBox(height: 16),
              if (state.items.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Produk (${state.items.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.items.length,
                          itemBuilder: (context, index) {
                            final item = state.items[index];
                            return InvoiceItemRow(
                              item: item,
                              onQuantityChanged: (qty) {
                                notifier.updateItemQuantity(item.id, qty);
                              },
                              onFieldChanged: (fieldType, value) {
                                _handleItemFieldChange(
                                    context, notifier, item, fieldType, value);
                              },
                              onRemove: () {
                                notifier.removeItemFromInvoice(item.id);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: .0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final taxValue = double.tryParse(
                                _taxPercentageController.text
                                    .replaceAll(',', '.'),
                              ) ??
                              0.0;

                          notifier.createInvoice(
                            supplierName:
                                _supplierNameController.text.isNotEmpty
                                    ? _supplierNameController.text
                                    : null,
                            supplierPhone:
                                _supplierPhoneController.text.isNotEmpty
                                    ? _supplierPhoneController.text
                                    : null,
                            supplierAddress:
                                _supplierAddressController.text.isNotEmpty
                                    ? _supplierAddressController.text
                                    : null,
                            taxPercentage: taxValue > 0 ? taxValue : null,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Buat Faktur'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else if (state.lastCreatedInvoice != null) ...[
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Faktur Berhasil Dibuat',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ID: ${state.lastCreatedInvoice!.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                MaterialPageRoute(
                                  builder: (context) => InvoicePreviewPage(
                                    invoice: state.lastCreatedInvoice!,
                                  ),
                                ),
                              )
                                  .then((_) {
                                notifier.clearInvoice();
                              });
                            },
                            child: const Text('Lihat Faktur'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context,
      [String? overrideMeasureType]) {
    _dialogQtyController.clear();
    DateTime? selectedExpiry;
    final maxDate = DateTime.now().add(const Duration(days: 365 * 3));
    final TextEditingController discountController = TextEditingController();
    final TextEditingController costPriceController = TextEditingController();
    final TextEditingController costPerUnitController = TextEditingController();
    final product = ref.read(inventoryNotifierProvider).searchedProduct;
    String measureType = overrideMeasureType ?? product?.measureType ?? 'pcs';

    if (product == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Masukkan Informasi Stok'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 700),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dialogQtyController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Masukkan jumlah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Satuan',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _SmoothDropdown(
                      value: measureType.isEmpty ? 'pcs' : measureType,
                      accentColor: const Color(0xFF997950),
                      locked: product.batches?.isNotEmpty ?? false,
                      items: const [
                        _SmoothDropdownItem(
                            value: 'pcs', label: 'Pcs (Satuan)'),
                        _SmoothDropdownItem(
                            value: 'weight', label: 'Kg (Timbangan)'),
                      ],
                      onChanged: product.batches?.isEmpty ?? true
                          ? (value) {
                              if (value != null) {
                                setState(() => measureType = value);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Harga Beli',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: costPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Masukkan harga beli',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Per Berapa Pcs/Kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: costPerUnitController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'e.g. 5',
                        suffixText: measureType == 'weight' ? 'kg' : 'pcs',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tanggal Kadaluwarsa',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: maxDate,
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedExpiry = picked;
                                });
                              }
                            },
                            child: Text(selectedExpiry == null
                                ? 'Pilih Tanggal'
                                : '${selectedExpiry!.day.toString().padLeft(2, '0')}/${selectedExpiry!.month.toString().padLeft(2, '0')}/${selectedExpiry!.year}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Diskon (%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: discountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        suffixText: '%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedExpiry == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pilih tanggal kadaluwarsa')),
                    );
                    return;
                  }

                  if (selectedExpiry!.isAfter(maxDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Tanggal maksimal 3 tahun dari sekarang')),
                    );
                    return;
                  }

                  final qtyText = _dialogQtyController.text.trim();
                  final normalizedQtyText = qtyText.replaceAll(',', '.');
                  final qty = double.tryParse(normalizedQtyText);

                  if (ref.read(inventoryNotifierProvider).searchedProduct ==
                      null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Pilih produk terlebih dahulu')),
                    );
                    return;
                  }

                  if (qty == null || qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Masukkan jumlah yang valid')),
                    );
                    return;
                  }

                  final costPriceText = costPriceController.text.trim();
                  final normalizedCostPrice =
                      costPriceText.replaceAll(',', '.');
                  final costPrice = costPriceText.isNotEmpty
                      ? double.tryParse(normalizedCostPrice)
                      : null;

                  if (costPriceText.isNotEmpty &&
                      (costPrice == null || costPrice <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Masukkan harga beli yang valid')),
                    );
                    return;
                  }

                  final costPerUnitText = costPerUnitController.text.trim();
                  final normalizedCostPerUnit =
                      costPerUnitText.replaceAll(',', '.');
                  final costPerUnit = costPerUnitText.isNotEmpty
                      ? double.tryParse(normalizedCostPerUnit)
                      : null;

                  if (costPerUnitText.isNotEmpty &&
                      (costPerUnit == null || costPerUnit <= 0)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Masukkan nilai pcs/kg yang valid')),
                    );
                    return;
                  }

                  final discountText = discountController.text.trim();
                  final normalizedDiscount = discountText.replaceAll(',', '.');
                  final discount = discountText.isNotEmpty
                      ? double.tryParse(normalizedDiscount)
                      : null;

                  // ── Hitung subtotal berdasarkan costPrice & costPerUnit ──
                  double subtotal;
                  if (costPrice != null &&
                      costPerUnit != null &&
                      costPerUnit > 0) {
                    final pricePerUnit = costPrice / costPerUnit;
                    subtotal = qty * pricePerUnit;
                  } else if (costPrice != null) {
                    subtotal = qty * costPrice;
                  } else {
                    subtotal = qty * product.hargaSatuan;
                  }

                  final item = InvoiceItem(
                    id: const Uuid().v4(),
                    product: product,
                    quantity: qty,
                    measureType: measureType,
                    subtotal: subtotal,
                    expirationDate: selectedExpiry,
                    discount: discount,
                    costPrice: costPrice,
                    costPerUnit: costPerUnit,
                  );

                  final notifier = ref.read(inventoryNotifierProvider.notifier);
                  notifier.addItemToInvoice(item);

                  _barcodeController.clear();
                  _nameController.clear();
                  _dialogQtyController.clear();
                  notifier.resetSearch();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.namaBarang} ditambahkan'),
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  Navigator.pop(context);
                },
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleItemFieldChange(
    BuildContext context,
    InventoryNotifier notifier,
    InvoiceItem item,
    String fieldType,
    dynamic value,
  ) {
    final newQuantity =
        fieldType == 'quantity' ? value as double : item.quantity;
    final newCostPrice =
        fieldType == 'costPrice' ? value as double : item.costPrice;
    final newCostPerUnit =
        fieldType == 'costPerUnit' ? value as double : item.costPerUnit;

    double newSubtotal = item.subtotal;
    if (fieldType == 'quantity' ||
        fieldType == 'costPrice' ||
        fieldType == 'costPerUnit') {
      if (newCostPrice != null &&
          newCostPerUnit != null &&
          newCostPerUnit > 0) {
        final pricePerUnit = newCostPrice / newCostPerUnit;
        newSubtotal = newQuantity * pricePerUnit;
      } else if (newCostPrice != null) {
        newSubtotal = newQuantity * newCostPrice;
      } else {
        newSubtotal = newQuantity * item.product.hargaSatuan;
      }
    }

    final updatedItem = InvoiceItem(
      id: item.id,
      product: item.product,
      quantity: newQuantity,
      measureType:
          fieldType == 'measureType' ? value as String : item.measureType,
      subtotal: newSubtotal,
      expirationDate: fieldType == 'expirationDate'
          ? value as DateTime
          : item.expirationDate,
      discount: fieldType == 'discount' ? value as double : item.discount,
      costPrice: newCostPrice,
      costPerUnit: newCostPerUnit,
    );

    notifier.updateItem(updatedItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${fieldType.replaceAll('_', ' ')} diperbarui'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

class _SmoothDropdownItem {
  final String value;
  final String label;
  const _SmoothDropdownItem({required this.value, required this.label});
}

class _SmoothDropdown extends StatefulWidget {
  final String value;
  final List<_SmoothDropdownItem> items;
  final ValueChanged<String?>? onChanged;
  final Color accentColor;
  final bool locked;

  const _SmoothDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.accentColor,
    this.locked = false,
  });

  @override
  State<_SmoothDropdown> createState() => _SmoothDropdownState();
}

class _SmoothDropdownState extends State<_SmoothDropdown>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;
  late Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expandAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _arrowAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    if (widget.locked || widget.onChanged == null) return;
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _select(String value) {
    widget.onChanged?.call(value);
    setState(() => _isOpen = false);
    _animController.reverse();
  }

  String get _currentLabel => widget.items
      .firstWhere(
        (i) => i.value == widget.value,
        orElse: () => widget.items.first,
      )
      .label;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.locked || widget.onChanged == null;
    final borderColor = _isOpen ? widget.accentColor : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDisabled ? Colors.grey.shade300 : borderColor,
                width: _isOpen ? 1.5 : 1.0,
              ),
              borderRadius: _isOpen
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    )
                  : BorderRadius.circular(8),
              color: isDisabled ? Colors.grey.shade100 : Colors.transparent,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _currentLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDisabled ? Colors.grey : null,
                        ),
                  ),
                ),
                if (widget.locked)
                  const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
                else
                  RotationTransition(
                    turns: _arrowAnim,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: widget.accentColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnim,
          axisAlignment: -1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: widget.accentColor, width: 1.5),
                right: BorderSide(color: widget.accentColor, width: 1.5),
                bottom: BorderSide(color: widget.accentColor, width: 1.5),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              color: Theme.of(context).dialogBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = item.value == widget.value;
                final isLast = index == widget.items.length - 1;
                return InkWell(
                  onTap: () => _select(item.value),
                  borderRadius: isLast
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        )
                      : BorderRadius.zero,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.accentColor.withOpacity(0.08)
                          : Colors.transparent,
                      border: !isLast
                          ? Border(
                              bottom: BorderSide(color: Colors.grey.shade200))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isSelected ? widget.accentColor : null,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded,
                              size: 16, color: widget.accentColor),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
