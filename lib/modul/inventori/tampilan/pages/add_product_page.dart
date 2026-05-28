import 'package:mitra/shared/komponen/mitra_text_field.dart';
import 'package:mitra/shared/komponen/mitra_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../controllers/product_provider.dart';
import '../../domain/entities/product.dart';
import '../../../../shared/tema/app_theme.dart';
import '../../../../shared/format/input_validators.dart';

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
}

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barcodeController = TextEditingController();
  String _name = '';
  double _price = 0.0;

  /// Buka halaman scanner kamera dan isi barcode dari hasil scan
  void _scanBarcode() async {
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      _barcodeController.text = result;
    }
  }

  /// Generate barcode otomatis berdasarkan timestamp
  void _generateBarcode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final generated =
        'NB${timestamp.toString().substring(timestamp.toString().length - 8)}';
    _barcodeController.text = generated;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    final barcode = _barcodeController.text.trim();
    final productState = ref.read(productNotifierProvider);
    final existingProduct =
        productState.products.where((p) => p.kodeBarang == barcode).firstOrNull;

    if (existingProduct != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk dengan barcode "$barcode" sudah ada!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final product = Barang(
      idBarang: const Uuid().v4(),
      namaBarang: _name,
      kodeBarang: barcode,
      hargaSatuan: _price,
    );

    final created =
        await ref.read(productNotifierProvider.notifier).addProduct(product);
    if (created && mounted) {
      context.pop();
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Tambah Produk',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel(text: 'Kode Produk'),
                Row(
                  children: [
                    Expanded(
                      child: MitraTextField(
                        controller: _barcodeController,
                        label: '',
                        hint: 'Pindai atau masukkan barcode',
                        validator: InputValidators.required(
                            'Silakan masukkan barcode'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol kamera scanner
                    _IconActionButton(
                      icon: Icons.qr_code_scanner,
                      onPressed: _scanBarcode,
                      tooltip: 'Pindai barcode',
                    ),
                    const SizedBox(width: 8),
                    // Tombol generate otomatis
                    _IconActionButton(
                      icon: Icons.auto_awesome,
                      onPressed: _generateBarcode,
                      tooltip: 'Generate barcode',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ketuk ikon kamera untuk membuka pemindai atau ikon bintang untuk menghasilkan kode baru',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 24),
                const _FieldLabel(text: 'Nama Produk'),
                MitraTextField(
                  label: '',
                  hint: 'e.g. Khong Guan Vanilla',
                  textCapitalization: TextCapitalization.words,
                  validator: InputValidators.required('Silakan masukkan nama'),
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 24),
                const _FieldLabel(text: 'Harga Jual'),
                MitraTextField(
                  label: '',
                  hint: '0',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [ThousandsSeparatorInputFormatter()],
                  customPrefix: const Text(
                    'Rp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  validator: (value) {
                    final error = InputValidators.price(value);
                    if (error != null) return error;
                    final cleanValue = value!.replaceAll(',', '');
                    final parsed = double.tryParse(cleanValue);
                    if (parsed == null) return 'Masukkan angka yang valid';
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
            icon: Icons.add_circle,
            label: 'Tambah Produk',
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon, color: AppTheme.primaryColor),
          onPressed: onPressed,
          padding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}
