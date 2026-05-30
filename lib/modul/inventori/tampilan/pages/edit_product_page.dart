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
  late double? _discount;
  DateTime? _discountStart;
  DateTime? _discountEnd;
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _name = widget.product.namaBarang;
    _price = widget.product.hargaSatuan;
    _discount = widget.product.diskon;
    _discountStart = widget.product.diskonMulai;
    _discountEnd = widget.product.diskonSelesai;
    _discountController = TextEditingController(
      text: _discount != null ? _discount.toString() : '',
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickDiscountDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_discountStart ?? now)
          : (_discountEnd ?? _discountStart ?? now),
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _discountStart = picked;
        if (_discountEnd != null && _discountEnd!.isBefore(picked)) {
          _discountEnd = picked;
        }
      } else {
        _discountEnd = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (_discount != null && _discount! > 0) {
      if (_discountStart == null || _discountEnd == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih rentang tanggal diskon terlebih dahulu'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      if (_discountEnd!.isBefore(_discountStart!)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Tanggal selesai harus lebih besar atau sama dengan tanggal mulai'),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }

    final updatedProduct = Barang(
      idBarang: widget.product.idBarang,
      namaBarang: _name,
      kodeBarang: widget.product.kodeBarang,
      hargaSatuan: _price,
      stokSaatIni: widget.product.stokSaatIni,
      measureType: widget.product.measureType,
      latestCostPrice: widget.product.latestCostPrice,
      latestCostPerUnit: widget.product.latestCostPerUnit,
      diskon: _discount,
      diskonMulai: _discountStart,
      diskonSelesai: _discountEnd,
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
                  validator: InputValidators.required('Silakan masukkan nama'),
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 24),

                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child:
                      Text('Harga Beli', style: TextStyle(color: Colors.black)),
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
                                style: TextStyle(color: Colors.black)),
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
                const SizedBox(height: 24),
                const Text('Diskon Produk',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FFF9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1FAE5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.discount_outlined,
                              size: 18, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Atur diskon produk dan rentang tanggal validnya.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Periode diskon',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDiscountDate(isStart: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE5E5EA)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Dari',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text(
                                      _discountStart != null
                                          ? _formatDate(_discountStart!)
                                          : 'Pilih tanggal',
                                      style: TextStyle(
                                        color: _discountStart != null
                                            ? Colors.black87
                                            : Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _pickDiscountDate(isStart: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFE5E5EA)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sampai',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text(
                                      _discountEnd != null
                                          ? _formatDate(_discountEnd!)
                                          : 'Pilih tanggal',
                                      style: TextStyle(
                                        color: _discountEnd != null
                                            ? Colors.black87
                                            : Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(
                              r'^(100(\.0{1,2})?|\d{1,2}(\.\d{1,2})?)?$')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Diskon %',
                          hintText: '0.00',
                          suffixText: '%',
                          helperText: 'Maksimal 100%',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = double.tryParse(
                              value.replaceAll(',', '.').trim());
                          if (parsed == null) {
                            return 'Masukkan angka yang valid';
                          }
                          if (parsed < 0 || parsed > 100) {
                            return 'Diskon harus antara 0-100%';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          final text = value?.trim();
                          _discount = text == null || text.isEmpty
                              ? null
                              : double.parse(text.replaceAll(',', '.'));
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Diskon akan berlaku saat checkout hanya jika tanggal sekarang berada pada rentang ini.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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
      ),
    );
  }
}
