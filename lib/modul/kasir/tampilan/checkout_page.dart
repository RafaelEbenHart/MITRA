import 'package:mitra/shared/komponen/mitra_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/modul/akses/tampilan/controllers/auth_provider.dart'
    as auth_provider;
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;
import 'package:mitra/modul/kasir/tampilan/controllers/billing_provider.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  double _productDiscountFor(dynamic item) {
    final discount = item.barang.diskon ?? 0.0;
    final start = item.barang.diskonMulai;
    final end = item.barang.diskonSelesai;
    if (discount <= 0) return 0.0;

    // Normalize values that are stored as fractions (e.g. 0.1 meaning 10%)
    // If discount is between 0 (exclusive) and 1 (inclusive), assume it's a fraction.
    double normalized = discount;
    if (discount > 0 && discount <= 1) {
      normalized = discount * 100;
    }

    final now = DateTime.now();

    // If both dates are null, treat discount as always active
    if (start == null && end == null) return normalized.clamp(0.0, 100.0);

    // If only start is provided, active from start onwards
    if (start != null && end == null) {
      if (now.isBefore(start)) return 0.0;
      return normalized.clamp(0.0, 100.0);
    }

    // If only end is provided, active until end
    if (start == null && end != null) {
      if (now.isAfter(end)) return 0.0;
      return normalized.clamp(0.0, 100.0);
    }

    // Both start and end provided — check range
    if (now.isBefore(start!) || now.isAfter(end!)) return 0.0;
    return normalized.clamp(0.0, 100.0);
  }

  @override
  void initState() {
    super.initState();
    // Load shop dipanggil sekali saja di sini, bukan di dalam build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopState = ref.read(shop_provider.shopNotifierProvider);
      if (shopState.shop == null &&
          shopState.status != shop_provider.ShopStatus.loading) {
        ref.read(shop_provider.shopNotifierProvider.notifier).loadShop();
      }
    });
  }

  double _itemTotal(int index, dynamic cartItem) {
    final disc = _productDiscountFor(cartItem);
    final unitPrice = (cartItem.barang.hargaSatuan as num).toDouble();
    final qty = (cartItem.jumlah as num).toDouble();
    final discountedUnit = unitPrice * (1 - disc / 100);
    return discountedUnit * qty;
  }

  double _subtotal(List<dynamic> cartItems) {
    double sum = 0;
    for (int i = 0; i < cartItems.length; i++) {
      sum += _itemTotal(i, cartItems[i]);
    }
    return sum;
  }

  double _ppnAmount(List<dynamic> cartItems, double ppnRate) =>
      _subtotal(cartItems) * ppnRate;

  double _grandTotal(List<dynamic> cartItems, double ppnRate) =>
      _subtotal(cartItems) + _ppnAmount(cartItems, ppnRate);

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    final billingNotifier = ref.read(billingNotifierProvider.notifier);
    final billingState = ref.watch(billingNotifierProvider);
    final shopState = ref.watch(shop_provider.shopNotifierProvider);
    final authState = ref.read(auth_provider.authNotifierProvider);

    // ref.listen sekarang berada langsung di dalam build method — sudah benar
    ref.listen<BillingState>(billingNotifierProvider, (previous, state) {
      if (previous?.printSuccess != true && state.printSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Transaksi berhasil disimpan.'),
            backgroundColor: Colors.green));
        context.go('/');
      }
      if (previous?.error != state.error && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.error!),
          backgroundColor: Colors.red,
        ));
      }
    });

    final createdBy = authState is auth_provider.AuthAuthenticated
        ? authState.user.namaLengkap
        : '';

    final cartItems = billingState.cartItems;
    final ppnPercent = shopState.shop?.taxPercentage ?? 11.0;
    final ppnRate = ppnPercent / 100;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.go('/');
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                size: 28, color: Theme.of(context).primaryColor),
            onPressed: () => context.go('/'),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Scrollable content ──
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cartItems.isEmpty)
                        const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: 24),
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Tidak ada produk dalam pesanan',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Kembali ke halaman utama untuk menambahkan produk.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            SizedBox(height: 24),
                          ],
                        )
                      else ...[
                        // ── Preview Pesanan ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preview Pesanan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: cartItems.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = cartItems[index];
                                  final disc = _productDiscountFor(item);
                                  final unitPrice =
                                      (item.barang.hargaSatuan as num)
                                          .toDouble();
                                  final qty = (item.jumlah as num).toDouble();
                                  final originalUnit = unitPrice;
                                  final discountedUnit =
                                      unitPrice * (1 - disc / 100);
                                  final discountedTotal = discountedUnit * qty;

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${item.jumlah} x ${item.barang.namaBarang}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  if (disc > 0) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Diskon ${disc.toStringAsFixed(disc % 1 == 0 ? 0 : 1)}%',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                if (disc > 0)
                                                  Text(
                                                    formatIdr(originalUnit),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                      decoration: TextDecoration
                                                          .lineThrough,
                                                    ),
                                                  ),
                                                // Show discounted unit price (green)
                                                Text(
                                                  formatIdr(discountedUnit),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: disc > 0
                                                        ? Colors.green
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                if (qty > 1)
                                                  Text(
                                                    formatIdr(discountedTotal),
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600]),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (cartItems.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.05),
                        blurRadius: 10,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    formatIdr(_subtotal(cartItems)),
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PPN (${ppnPercent.toStringAsFixed(ppnPercent % 1 == 0 ? 0 : 1)}%)',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    formatIdr(_ppnAmount(cartItems, ppnRate)),
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL KESELURUHAN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[400],
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    formatIdr(_grandTotal(cartItems, ppnRate)),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        MitraButton(
                          onPressed: () {
                            final s = (shopState.status ==
                                        shop_provider.ShopStatus.loaded &&
                                    shopState.shop != null)
                                ? shopState.shop
                                : null;
                            if (s != null) {
                              billingNotifier.printReceipt(
                                shopName: s.namaToko,
                                address: s.alamatBaris1,
                                phone: s.nomorTelepon,
                                footer: s.pesanStruk,
                                createdBy: createdBy,
                                taxPercentage: ppnPercent,
                                discountRates: List.generate(
                                  cartItems.length,
                                  (index) =>
                                      _productDiscountFor(cartItems[index]),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Detail toko belum dimuat'),
                                      backgroundColor: Colors.red));
                            }
                          },
                          label: 'Cetak Struk',
                          icon: Icons.print,
                          isLoading: billingState.isPrinting,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
