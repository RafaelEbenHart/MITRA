import 'package:mitra/shared/komponen/mitra_text_field.dart';
import 'package:mitra/shared/komponen/mitra_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/product_provider.dart';
import '../../domain/entities/product.dart';
import '../../../../shared/tema/app_theme.dart';
import '../../../../shared/format/input_validators.dart';
import '../../../../shared/format/price_formatter.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;

    final numericValue = newValue.text.replaceAll(',', '');
    if (double.tryParse(numericValue) == null) return oldValue;

    final formatted = _formatNumber(numericValue);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatNumber(String value) {
    final parts = value.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';
    final formattedInteger = _addCommas(integerPart);
    return decimalPart.isNotEmpty
        ? '$formattedInteger.$decimalPart'
        : formattedInteger;
  }

  String _addCommas(String value) {
    final reversed = value.split('').reversed.join();
    final withCommas = reversed.replaceAllMapped(
        RegExp(r'.{3}'), (match) => '${match.group(0)},');
    return withCommas.split('').reversed.join().replaceFirst(',', '');
  }

  static String formatString(String value) {
    if (value.isEmpty) return value;
    final numericValue = value.replaceAll(',', '');
    return _formatNumberStatic(numericValue);
  }

  static String _formatNumberStatic(String value) {
    final parts = value.split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '';
    final formattedInteger = _addCommasStatic(integerPart);
    return decimalPart.isNotEmpty
        ? '$formattedInteger.$decimalPart'
        : formattedInteger;
  }

  static String _addCommasStatic(String value) {
    final reversed = value.split('').reversed.join();
    final withCommas = reversed.replaceAllMapped(
        RegExp(r'.{3}'), (match) => '${match.group(0)},');
    return withCommas.split('').reversed.join().replaceFirst(',', '');
  }
}

class EditProductPage extends ConsumerStatefulWidget {
  final Barang product;
  const EditProductPage({super.key, required this.product});

  @override
  ConsumerState<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends ConsumerState<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late double _price;

  @override
  void initState() {
    super.initState();
    _name = widget.product.namaBarang;
    _price = widget.product.hargaSatuan;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final updatedProduct = Barang(
      idBarang: widget.product.idBarang,
      namaBarang: _name,
      kodeBarang: widget.product.kodeBarang,
      hargaSatuan: _price,
      stokSaatIni: widget.product.stokSaatIni,
      measureType: widget.product.measureType,
      latestCostPrice: widget.product.latestCostPrice,
      latestCostPerUnit: widget.product.latestCostPerUnit,
    );

    final success = await ref
        .read(productNotifierProvider.notifier)
        .updateProduct(updatedProduct);
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProductState>(productNotifierProvider, (previous, next) {
      if (next.message != null && next.message!.isNotEmpty) {
        final isError = next.status == ProductStatus.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message!),
              backgroundColor: isError ? Colors.red : Colors.green,
            ),
          );
          ref.read(productNotifierProvider.notifier).clearMessage();
        });
      }
    });

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 32, color: Theme.of(context).primaryColor),
            onPressed: () => context.pop(),
          ),
          title: const Text('Ubah Produk',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Barcode details (immutable block)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            color: AppTheme.primaryColor, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('KODE PRODUK',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.7))),
                            const SizedBox(height: 2),
                            Text(widget.product.kodeBarang,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'google-fonts')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  MitraTextField(
                    initialValue: _name,
                    label: 'Nama Produk',
                    textCapitalization: TextCapitalization.words,
                    validator:
                        InputValidators.required('Silakan masukkan nama'),
                    onSaved: (value) => _name = value!,
                  ),
                  const SizedBox(height: 24),

                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Harga Beli',
                        style: TextStyle(color: Color(0xFF4C669A))),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.product.latestCostPrice != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Harga Beli:',
                                  style: TextStyle(color: Colors.grey)),
                              Text(
                                formatIdr(widget.product.latestCostPrice!),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'Belum ada data harga beli. Tambahkan stok untuk mengatur harga beli.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        if (widget.product.latestCostPrice != null)
                          const SizedBox(height: 8),
                        if (widget.product.latestCostPerUnit != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Per:',
                                  style: TextStyle(color: Colors.grey)),
                              Text(
                                '${widget.product.measureType == 'weight' ? widget.product.latestCostPerUnit!.toStringAsFixed(2) : widget.product.latestCostPerUnit!.toInt().toString()} ${widget.product.measureType == 'weight' ? 'kg' : 'pcs'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  MitraTextField(
                    initialValue: ThousandsSeparatorInputFormatter.formatString(
                        _price.toStringAsFixed(2)),
                    label: 'Harga Jual',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      prefixText: 'Rp',
                      prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black),
                    ),
                    validator: (value) {
                      final error = InputValidators.price(value);
                      if (error != null) return error;
                      final cleanValue = value!.replaceAll(',', '');
                      final parsed = double.tryParse(cleanValue);
                      if (parsed == null) return 'Please enter a valid number';
                      if (parsed > 5000000) {
                        return 'Harga maksimal Rp 5.000.000';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        _price = double.parse(value!.replaceAll(',', '')),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: MitraButton(
              onPressed: _submit,
              icon: Icons.save,
              label: 'Simpan Perubahan',
            ),
          ),
        ));
  }
}
