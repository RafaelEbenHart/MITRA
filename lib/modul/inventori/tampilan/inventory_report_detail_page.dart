import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;
import 'package:mitra/modul/akses/tampilan/controllers/auth_provider.dart'
    as auth_provider;
import 'package:mitra/modul/akses/domain/entities/user_entity.dart';
import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_provider.dart';

class InventoryReportDetailPage extends ConsumerWidget {
  final DateTime reportDate;
  final String title;

  const InventoryReportDetailPage({
    super.key,
    required this.reportDate,
    required this.title,
  });

  /// Simple retry untuk handle auth delay di fresh install
  void _retryLoadProductsIfNeeded(WidgetRef ref, int attempt) {
    if (attempt >= 3) return; // Max 3 attempts

    Future.delayed(Duration(milliseconds: 500 * (attempt + 1)), () {
      final state = ref.read(product_provider.productNotifierProvider);
      // Jika masih kosong, retry
      if (state.products.isEmpty &&
          state.status != product_provider.ProductStatus.loading) {
        ref
            .read(product_provider.productNotifierProvider.notifier)
            .loadProducts();
        _retryLoadProductsIfNeeded(ref, attempt + 1);
      }
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  double _totalProductQuantity(Barang product) {
    final batchQuantity = product.batches
            ?.fold<double>(0, (sum, batch) => sum + batch.quantity) ??
        0;
    return product.stokSaatIni ?? batchQuantity;
  }

  String _formatQuantity(double quantity) {
    return quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(2);
  }

  Future<Uint8List> _buildReportPdf(
    List<Barang> inventoryProducts,
    DateTime generatedAt,
    String reportTitle,
    Map<String, String> shopData,
    List<Map<String, dynamic>> incomingEntries,
    List<Map<String, dynamic>> outgoingEntries,
  ) async {
    final pdf = pw.Document();
    final reportMonth = _formatMonth(reportDate);
    final formattedDate = _formatDate(generatedAt);
    final reportId =
        'INV-${generatedAt.year}${generatedAt.month.toString().padLeft(2, '0')}${generatedAt.day.toString().padLeft(2, '0')}-${generatedAt.hour.toString().padLeft(2, '0')}${generatedAt.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // ── HEADER: Info toko kiri + judul laporan kanan ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Kolom kiri: detail toko
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if ((shopData['name'] ?? '').isNotEmpty)
                        pw.Text(
                          shopData['name']!,
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if ((shopData['addressLine1'] ?? '').isNotEmpty)
                        pw.Text(
                          shopData['addressLine1']!,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if ((shopData['phoneNumber'] ?? '').isNotEmpty)
                        pw.Text(
                          'Telepon : ${shopData['phoneNumber']!}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                // Kolom kanan: judul laporan
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Laporan',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Persediaan',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),
            pw.Container(
              height: 6,
              color: PdfColors.black,
            ),

            pw.SizedBox(height: 10),

            // ── INFO ID LAPORAN & TANGGAL ──
            pw.Row(
              children: [
                pw.SizedBox(
                    width: 80,
                    child: pw.Text('ID Laporan',
                        style: const pw.TextStyle(fontSize: 10))),
                pw.Text(' : ', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(reportId, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.SizedBox(
                    width: 80,
                    child: pw.Text('Tanggal',
                        style: const pw.TextStyle(fontSize: 10))),
                pw.Text(' : ', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),

            pw.SizedBox(height: 14),

            // ── TABEL PERSEDIAAN ──
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center, // No
                1: pw.Alignment.centerLeft, // Nama Produk
                2: pw.Alignment.centerLeft, // Barcode
                3: pw.Alignment.center, // Jumlah
                4: pw.Alignment.center, // Satuan
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(50),
                4: const pw.FixedColumnWidth(42),
              },
              headers: [
                'No.',
                'Nama Produk',
                'Barcode',
                'Jumlah',
                'Satuan',
              ],
              data: inventoryProducts.asMap().entries.map((e) {
                final index = e.key + 1;
                final product = e.value;
                final satuan = product.measureType == 'weight' ? 'kg' : 'pcs';
                final qty = _totalProductQuantity(product);
                return [
                  index.toString(),
                  product.namaBarang,
                  product.kodeBarang,
                  qty % 1 == 0
                      ? qty.toInt().toString()
                      : qty.toStringAsFixed(2),
                  satuan,
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 8),

            if (incomingEntries.isNotEmpty) pw.SizedBox(height: 16),
            if (incomingEntries.isNotEmpty)
              pw.Text('Produk Masuk Bulan $reportMonth',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (incomingEntries.isNotEmpty) pw.SizedBox(height: 8),
            if (incomingEntries.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                headers: [
                  'No',
                  'Nama',
                  'Barcode',
                  'Faktur(8)',
                  'Jumlah',
                  'Satuan',
                  'Harga Beli',
                  'Per Pcs/kg',
                  'Subtotal'
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                data: incomingEntries.asMap().entries.map((e) {
                  final index = e.key + 1;
                  final entry = e.value;
                  final prod = entry['product'] as Barang;
                  final invoiceId = entry['invoiceId'] as String;
                  final cost = entry['costPrice'] as double;
                  final costPerUnit = entry['costPerUnit'] as double? ?? 0;
                  final qty = entry['quantity'] as double;
                  final satuan = prod.measureType == 'weight' ? 'kg' : 'pcs';
                  final subtotal = cost * qty;
                  final costStr = formatIdr(cost);
                  final costPerUnitStr = costPerUnit;
                  final subtotalStr = formatIdr(subtotal);
                  return [
                    index.toString(),
                    prod.namaBarang,
                    prod.kodeBarang,
                    invoiceId.length > 8
                        ? invoiceId.substring(0, 8)
                        : invoiceId,
                    qty % 1 == 0
                        ? qty.toInt().toString()
                        : qty.toStringAsFixed(2),
                    satuan,
                    costStr,
                    costPerUnitStr,
                    subtotalStr,
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Total',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    flex: 8,
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    incomingEntries
                        .fold<double>(
                            0, (sum, e) => sum + (e['quantity'] as double))
                        .toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 8),
                  ),
                ],
              ),
            ],
            if (outgoingEntries.isNotEmpty) pw.SizedBox(height: 16),
            if (outgoingEntries.isNotEmpty)
              pw.Text('Produk Keluar Bulan $reportMonth',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (outgoingEntries.isNotEmpty) pw.SizedBox(height: 8),
            if (outgoingEntries.isNotEmpty) ...[
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                headers: [
                  'No',
                  'Nama',
                  'Barcode',
                  'ID Laporan(8)',
                  'Jumlah',
                  'Satuan',
                  'Harga Beli',
                  'Per Pcs/kg',
                  'Subtotal'
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
                cellStyle: const pw.TextStyle(fontSize: 8),
                data: outgoingEntries.asMap().entries.map((e) {
                  final index = e.key + 1;
                  final entry = e.value;
                  final prod = entry['product'] as Barang;
                  final invoiceId = entry['invoiceId'] as String;
                  final cost = entry['costPrice'] as double;
                  final costPerUnit = entry['costPerUnit'] as double? ?? 0;
                  final qty = entry['quantity'] as double;
                  final satuan = prod.measureType == 'weight' ? 'kg' : 'pcs';
                  final subtotal = cost * qty;
                  final costStr = formatIdr(cost);
                  final costPerUnitStr = costPerUnit;
                  final subtotalStr = formatIdr(subtotal);
                  return [
                    index.toString(),
                    prod.namaBarang,
                    prod.kodeBarang,
                    invoiceId.isNotEmpty && invoiceId.length > 8
                        ? invoiceId.substring(0, 8)
                        : invoiceId,
                    qty % 1 == 0
                        ? qty.toInt().toString()
                        : qty.toStringAsFixed(2),
                    satuan,
                    costStr,
                    costPerUnitStr,
                    subtotalStr,
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Total',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                    flex: 8,
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    outgoingEntries
                        .fold<double>(
                            0, (sum, e) => sum + (e['quantity'] as double))
                        .toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 8),
                  ),
                  pw.SizedBox(width: 60),
                  pw.Spacer(),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    formatIdr(outgoingEntries.fold<double>(
                        0,
                        (sum, e) =>
                            sum +
                            ((e['costPrice'] as double) *
                                (e['quantity'] as double)))),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 8),
                  ),
                ],
              ),
            ],
          ];
        },
      ),
    );
    return pdf.save();
  }

  Future<void> _printInventoryReport(
    BuildContext context,
    WidgetRef ref,
    List<Barang> inventoryProducts,
    Map<String, String> shopData,
  ) async {
    final now = DateTime.now();
    final inventoryState = ref.read(inventoryNotifierProvider);
    final products =
        ref.read(product_provider.productNotifierProvider).products;
    final incomingEntries = <Map<String, dynamic>>[];
    for (final inv in inventoryState.invoiceHistory) {
      if (inv.createdDate.year == reportDate.year &&
          inv.createdDate.month == reportDate.month) {
        for (final item in inv.items) {
          // Only include products that still exist (not deleted)
          if (products.any((p) => p.idBarang == item.product.idBarang)) {
            incomingEntries.add({
              'product': item.product,
              'invoiceId': inv.id,
              'quantity': item.quantity,
              'subtotal': item.subtotal,
              'costPrice': item.costPrice ??
                  item.product.latestCostPrice ??
                  item.product.hargaSatuan,
              'costPerUnit': item.costPerUnit ?? item.product.latestCostPerUnit,
            });
          }
        }
      }
    }

    final outgoingEntries = <Map<String, dynamic>>[];
    for (final p in products) {
      if (p.batches != null) {
        for (final b in p.batches!) {
          if (b.expirationDate.year == reportDate.year &&
              b.expirationDate.month == reportDate.month) {
            outgoingEntries.add({
              'product': p,
              'batch': b,
              'invoiceId': b.invoiceId ?? '',
              'kode': b.id,
              'quantity': b.quantity,
              'costPrice': b.costPrice ?? p.latestCostPrice ?? p.hargaSatuan,
              'costPerUnit': b.costPerUnit ?? p.latestCostPerUnit ?? 0,
            });
          }
        }
      }
    }

    final pdfBytes = await _buildReportPdf(
      inventoryProducts,
      now,
      title,
      shopData,
      incomingEntries,
      outgoingEntries,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(auth_provider.authNotifierProvider);

    // Pastikan user sudah authenticated
    if (authState is! auth_provider.AuthAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: SafeArea(child: Builder(builder: (context) {
          final state = ref.watch(product_provider.productNotifierProvider);

          // Load products if not loaded yet
          if (state.status == product_provider.ProductStatus.initial) {
            Future.microtask(() {
              ref
                  .read(product_provider.productNotifierProvider.notifier)
                  .loadProducts();
            });
          }

          // If products empty after load, trigger retry (fresh install auth delay)
          if ((state.status == product_provider.ProductStatus.loaded ||
                  state.status == product_provider.ProductStatus.success) &&
              state.products.isEmpty) {
            Future.microtask(() => _retryLoadProductsIfNeeded(ref, 0));
            // Show loading while retrying
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == product_provider.ProductStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == product_provider.ProductStatus.error) {
            return Center(
              child: Text(state.message ?? 'Gagal memuat data produk'),
            );
          }

          // Show loading if products still empty (shouldn't happen, but safety)
          if (state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = state.products;
          final inventoryProducts = products
              .where((product) => _totalProductQuantity(product) > 0)
              .toList();
          final totalQty = inventoryProducts.fold<double>(
            0,
            (sum, product) => sum + _totalProductQuantity(product),
          );

          final shopState = ref.watch(shop_provider.shopNotifierProvider);
          final shopData = <String, String>{};
          if (shopState.shop != null) {
            shopData['name'] = shopState.shop!.namaToko;
            shopData['addressLine1'] = shopState.shop!.alamatBaris1;
            shopData['phoneNumber'] = shopState.shop!.nomorTelepon;
            shopData['footerText'] = shopState.shop!.pesanStruk;
          }

          final authState = ref.read(auth_provider.authNotifierProvider);
          final hideShopDetails =
              authState is auth_provider.AuthAuthenticated &&
                  authState.user.peran == PeranPengguna.karyawan;

          return ref.watch(invoiceHistoryProvider).when(
                data: (invoiceHistory) => Builder(
                  builder: (context) {
                    final incomingEntries = <Map<String, dynamic>>[];
                    for (final inv in invoiceHistory) {
                      if (inv.createdDate.year == reportDate.year &&
                          inv.createdDate.month == reportDate.month) {
                        for (final item in inv.items) {
                          // Only include products that still exist (not deleted)
                          if (products.any(
                              (p) => p.idBarang == item.product.idBarang)) {
                            incomingEntries.add({
                              'product': item.product,
                              'invoiceId': inv.id,
                              'quantity': item.quantity,
                              'subtotal': item.subtotal,
                              'costPrice': item.costPrice ??
                                  item.product.latestCostPrice ??
                                  item.product.hargaSatuan,
                              'costPerUnit': item.costPerUnit ??
                                  item.product.latestCostPerUnit,
                            });
                          }
                        }
                      }
                    }

                    final totalIncomingQty = incomingEntries.fold<double>(
                        0, (s, e) => s + (e['quantity'] as double));

                    final outgoingEntries = <Map<String, dynamic>>[];
                    for (final p in products) {
                      if (p.batches != null) {
                        for (final b in p.batches!) {
                          if (b.expirationDate.year == reportDate.year &&
                              b.expirationDate.month == reportDate.month) {
                            outgoingEntries.add({
                              'product': p,
                              'batch': b,
                              'invoiceId': b.invoiceId ?? '',
                              'kode': b.id,
                              'quantity': b.quantity,
                              'costPrice': b.costPrice ??
                                  p.latestCostPrice ??
                                  p.hargaSatuan,
                            });
                          }
                        }
                      }
                    }

                    final expiredQty = outgoingEntries.fold<double>(
                        0, (s, e) => s + (e['quantity'] as double));

                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!hideShopDetails && shopData.isNotEmpty) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shopData['name'] ?? '',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    if ((shopData['addressLine1'] ?? '')
                                        .isNotEmpty)
                                      Text(shopData['addressLine1']!),
                                    if ((shopData['phoneNumber'] ?? '')
                                        .isNotEmpty)
                                      Text('Tel: ${shopData['phoneNumber']!}'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Laporan Persediaan Bulan ${_formatMonth(reportDate)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Menampilkan stok saat ini berdasarkan inventaris.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _buildSummaryChip(
                                        label: 'Produk terdaftar',
                                        value:
                                            inventoryProducts.length.toString(),
                                      ),
                                      _buildSummaryChip(
                                        label: 'Total stok',
                                        value: totalQty % 1 == 0
                                            ? totalQty.toInt().toString()
                                            : totalQty.toStringAsFixed(2),
                                      ),
                                      _buildSummaryChip(
                                        label: 'Produk Masuk',
                                        value: totalIncomingQty % 1 == 0
                                            ? totalIncomingQty
                                                .toInt()
                                                .toString()
                                            : totalIncomingQty
                                                .toStringAsFixed(2),
                                      ),
                                      _buildSummaryChip(
                                        label: 'Produk Keluar',
                                        value: expiredQty % 1 == 0
                                            ? expiredQty.toInt().toString()
                                            : expiredQty.toStringAsFixed(2),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView(
                              children: [
                                // ── Produk Masuk ──
                                if (incomingEntries.isNotEmpty)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Produk Masuk Bulan ${_formatMonth(reportDate)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columnSpacing: 12,
                                              columns: const [
                                                DataColumn(label: Text('No')),
                                                DataColumn(label: Text('Nama')),
                                                DataColumn(
                                                    label: Text('Barcode')),
                                                DataColumn(
                                                    label: Text('Faktur (8)')),
                                                DataColumn(
                                                    label: Text('Jumlah')),
                                                DataColumn(
                                                    label: Text('Satuan')),
                                                DataColumn(
                                                    label: Text('Harga Beli')),
                                                DataColumn(
                                                    label: Text('Per Pcs/kg')),
                                                DataColumn(
                                                    label: Text('Subtotal')),
                                              ],
                                              rows: incomingEntries
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                final idx = entry.key + 1;
                                                final e = entry.value;
                                                final prod =
                                                    e['product'] as Barang;
                                                final invoiceId =
                                                    e['invoiceId'] as String;
                                                final cost =
                                                    e['costPrice'] as double;
                                                final costPerUnit =
                                                    (e['costPerUnit']
                                                            as double?) ??
                                                        0;
                                                final qty =
                                                    e['quantity'] as double;
                                                final satuan =
                                                    prod.measureType == 'weight'
                                                        ? 'kg'
                                                        : 'pcs';
                                                final subtotal = cost * qty;
                                                final invoiceDisplay =
                                                    invoiceId.length > 8
                                                        ? invoiceId.substring(
                                                            0, 8)
                                                        : invoiceId;
                                                final costStr = formatIdr(cost);
                                                final subtotalStr =
                                                    formatIdr(subtotal);
                                                return DataRow(cells: [
                                                  DataCell(
                                                      Text(idx.toString())),
                                                  DataCell(SizedBox(
                                                    width: 100,
                                                    child: Text(prod.namaBarang,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                  )),
                                                  DataCell(
                                                      Text(prod.kodeBarang)),
                                                  DataCell(
                                                      Text(invoiceDisplay)),
                                                  DataCell(Text(
                                                      _formatQuantity(qty))),
                                                  DataCell(Text(satuan)),
                                                  DataCell(Text(costStr)),
                                                  DataCell(Text(
                                                      costPerUnit.toString())),
                                                  DataCell(Text(subtotalStr)),
                                                ]);
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // ── Produk Keluar ──
                                if (outgoingEntries.isNotEmpty)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Produk Keluar Bulan ${_formatMonth(reportDate)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: DataTable(
                                              columnSpacing: 12,
                                              columns: const [
                                                DataColumn(label: Text('No')),
                                                DataColumn(label: Text('Nama')),
                                                DataColumn(
                                                    label: Text('Barcode')),
                                                DataColumn(
                                                    label:
                                                        Text('ID Laporan (8)')),
                                                DataColumn(
                                                    label: Text('Jumlah')),
                                                DataColumn(
                                                    label: Text('Satuan')),
                                                DataColumn(
                                                    label: Text('Harga Beli')),
                                                DataColumn(
                                                    label: Text('Per Pcs/kg')),
                                                DataColumn(
                                                    label: Text('Subtotal')),
                                              ],
                                              rows: outgoingEntries
                                                  .asMap()
                                                  .entries
                                                  .map((entry) {
                                                final idx = entry.key + 1;
                                                final e = entry.value;
                                                final prod =
                                                    e['product'] as Barang;
                                                final invoiceId =
                                                    (e['invoiceId'] as String);
                                                final cost =
                                                    e['costPrice'] as double;
                                                final costPerUnit =
                                                    (e['costPerUnit']
                                                            as double?) ??
                                                        0;
                                                final qty =
                                                    e['quantity'] as double;
                                                final satuan =
                                                    prod.measureType == 'weight'
                                                        ? 'kg'
                                                        : 'pcs';
                                                final subtotal = cost * qty;
                                                final invoiceDisplay = invoiceId
                                                            .isNotEmpty &&
                                                        invoiceId.length > 8
                                                    ? invoiceId.substring(0, 8)
                                                    : invoiceId;
                                                final costStr = formatIdr(cost);
                                                final subtotalStr =
                                                    formatIdr(subtotal);
                                                return DataRow(cells: [
                                                  DataCell(
                                                      Text(idx.toString())),
                                                  DataCell(SizedBox(
                                                    width: 100,
                                                    child: Text(prod.namaBarang,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                  )),
                                                  DataCell(
                                                      Text(prod.kodeBarang)),
                                                  DataCell(
                                                      Text(invoiceDisplay)),
                                                  DataCell(Text(
                                                      _formatQuantity(qty))),
                                                  DataCell(Text(satuan)),
                                                  DataCell(Text(costStr)),
                                                  DataCell(Text(
                                                      costPerUnit.toString())),
                                                  DataCell(Text(subtotalStr)),
                                                ]);
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // ── Persediaan Saat Ini ──
                                Text(
                                  'Persediaan Saat Ini',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columnSpacing: 12,
                                      columns: const [
                                        DataColumn(label: Text('No')),
                                        DataColumn(label: Text('Barcode')),
                                        DataColumn(label: Text('Produk')),
                                        DataColumn(label: Text('Jumlah')),
                                        DataColumn(label: Text('Satuan')),
                                      ],
                                      rows: inventoryProducts
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        final index = entry.key + 1;
                                        final product = entry.value;
                                        final totalQty =
                                            _totalProductQuantity(product);
                                        final satuan =
                                            product.measureType == 'weight'
                                                ? 'kg'
                                                : 'pcs';
                                        return DataRow(cells: [
                                          DataCell(Text(index.toString())),
                                          DataCell(Text(product.kodeBarang)),
                                          DataCell(SizedBox(
                                            width: 120,
                                            child: Text(product.namaBarang,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          )),
                                          DataCell(
                                              Text(_formatQuantity(totalQty))),
                                          DataCell(Text(satuan)),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: inventoryProducts.isEmpty
                                        ? null
                                        : () => _printInventoryReport(
                                              context,
                                              ref,
                                              inventoryProducts,
                                              shopData,
                                            ),
                                    icon: const Icon(Icons.print),
                                    label: const Text('Cetak'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: inventoryProducts.isEmpty
                                        ? null
                                        : () async {
                                            final now = DateTime.now();
                                            final incomingEntries =
                                                <Map<String, dynamic>>[];
                                            for (final inv in invoiceHistory) {
                                              if (inv.createdDate.year ==
                                                      reportDate.year &&
                                                  inv.createdDate.month ==
                                                      reportDate.month) {
                                                for (final item in inv.items) {
                                                  incomingEntries.add({
                                                    'product': item.product,
                                                    'invoiceId': inv.id,
                                                    'quantity': item.quantity,
                                                    'subtotal': item.subtotal,
                                                    'costPrice': item
                                                            .costPrice ??
                                                        item.product
                                                            .latestCostPrice ??
                                                        item.product
                                                            .hargaSatuan,
                                                    'costPerUnit': item
                                                            .costPerUnit ??
                                                        item.product
                                                            .latestCostPerUnit,
                                                  });
                                                }
                                              }
                                            }
                                            final outgoingEntries =
                                                <Map<String, dynamic>>[];
                                            final products = ref
                                                .read(product_provider
                                                    .productNotifierProvider)
                                                .products;
                                            for (final p in products) {
                                              if (p.batches != null) {
                                                for (final b in p.batches!) {
                                                  if (b.expirationDate.year ==
                                                          reportDate.year &&
                                                      b.expirationDate.month ==
                                                          reportDate.month) {
                                                    outgoingEntries.add({
                                                      'product': p,
                                                      'batch': b,
                                                      'invoiceId':
                                                          b.invoiceId ?? '',
                                                      'kode': b.id,
                                                      'quantity': b.quantity,
                                                      'costPrice': b
                                                              .costPrice ??
                                                          p.latestCostPrice ??
                                                          p.hargaSatuan,
                                                      'costPerUnit': b
                                                              .costPerUnit ??
                                                          p.latestCostPerUnit ??
                                                          0,
                                                    });
                                                  }
                                                }
                                              }
                                            }
                                            final pdfBytes =
                                                await _buildReportPdf(
                                              inventoryProducts,
                                              now,
                                              title,
                                              shopData,
                                              incomingEntries,
                                              outgoingEntries,
                                            );
                                            await Printing.sharePdf(
                                              bytes: pdfBytes,
                                              filename:
                                                  'laporan_persediaan_${reportDate.year}_${reportDate.month}.pdf',
                                            );
                                          },
                                    icon: const Icon(Icons.download),
                                    label: const Text('Ekspor PDF'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Error: ${error.toString()}'),
                ),
              );
        })));
  }
}

Widget _buildSummaryChip({
  required String label,
  required String value,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
