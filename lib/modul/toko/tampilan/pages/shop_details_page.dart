import 'package:mitra/shared/komponen/mitra_text_field.dart';
import 'package:mitra/shared/komponen/mitra_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/shop.dart';
import '../controllers/shop_provider.dart' as shop_provider;
import '../../../../shared/tema/app_theme.dart';
import '../../../../shared/format/input_validators.dart';

class ShopDetailsPage extends ConsumerStatefulWidget {
  const ShopDetailsPage({super.key});

  @override
  ConsumerState<ShopDetailsPage> createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends ConsumerState<ShopDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _address1Controller;
  late TextEditingController _phoneController;
  late TextEditingController _footerController;
  late TextEditingController _taxPercentageController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _address1Controller = TextEditingController();
    _phoneController = TextEditingController();
    _footerController = TextEditingController();
    _taxPercentageController = TextEditingController(text: '11');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shop_provider.shopNotifierProvider.notifier).loadShop();
    });
  }

  void _updateControllers(DataToko shop) {
    if (_nameController.text.isEmpty && shop.namaToko.isNotEmpty) {
      _nameController.text = shop.namaToko;
      _address1Controller.text = shop.alamatBaris1;
      _phoneController.text = shop.nomorTelepon;
      _footerController.text = shop.pesanStruk;
      _taxPercentageController.text = shop.taxPercentage
          .toStringAsFixed(shop.taxPercentage % 1 == 0 ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _address1Controller.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final taxValue =
          double.tryParse(_taxPercentageController.text.replaceAll(',', '.')) ??
              0.0;

      final shop = DataToko(
        namaToko: _nameController.text,
        alamatBaris1: _address1Controller.text,
        nomorTelepon: _phoneController.text,
        pesanStruk: _footerController.text,
        taxPercentage: taxValue.clamp(0.0, 100.0),
      );

      ref.read(shop_provider.shopNotifierProvider.notifier).updateShop(shop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopState = ref.watch(shop_provider.shopNotifierProvider);

    ref.listen<shop_provider.ShopState>(
      shop_provider.shopNotifierProvider,
      (previous, next) {
        if (next.status == shop_provider.ShopStatus.loaded &&
            next.shop != null) {
          _updateControllers(next.shop!);
        } else if (next.status == shop_provider.ShopStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('detail toko berhasil disimpan'),
            backgroundColor: Colors.green,
          ));
          context.pop();
        } else if (next.status == shop_provider.ShopStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.message ?? 'Terjadi kesalahan'),
            backgroundColor: Colors.red,
          ));
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Toko'),
      ),
      body: shopState.status == shop_provider.ShopStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Informasi Umum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        )),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(
                      'Detail ini akan muncul pada struk digital dan cetak Anda.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 24),
                    MitraTextField(
                      controller: _nameController,
                      label: 'Nama Toko',
                      hint: 'TOKOKU',
                      maxLength: 50,
                      validator: InputValidators.required('Wajib diisi'),
                    ),
                    const SizedBox(height: 15),
                    MitraTextField(
                      controller: _address1Controller,
                      label: 'Alamat',
                      hint: 'JALAN RAYA NO. 123, JAKARTA',
                      maxLength: 150,
                      maxLines: 2,
                      validator: InputValidators.required('Wajib diisi'),
                    ),
                    const SizedBox(height: 15),
                    MitraTextField(
                      controller: _phoneController,
                      label: 'Nomor Telepon',
                      hint: '08273xxxxxx',
                      maxLength: 12,
                      keyboardType: TextInputType.phone,
                      validator: InputValidators.required('Wajib diisi'),
                    ),
                    const SizedBox(height: 15),
                    MitraTextField(
                      controller: _taxPercentageController,
                      label: 'PPN (%)',
                      hint: '11',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^(100(\.0{1,2})?|\d{1,2}(\.\d{1,2})?)?$')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        final tax = double.tryParse(value.replaceAll(',', '.'));
                        if (tax == null || tax < 0 || tax > 100) {
                          return 'Pajak harus antara 0 dan 100%';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    MitraTextField(
                      controller: _footerController,
                      label: 'Teks Footer Struk',
                      hint: 'Terima kasih, datang lagi!',
                      maxLines: 2,
                      maxLength: 60,
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: MitraButton(
            onPressed: _saveShop,
            icon: Icons.save,
            label: 'Simpan Detail',
          ),
        ),
      ),
    );
  }
}
