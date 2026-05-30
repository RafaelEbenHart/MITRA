import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;
import 'package:mitra/shared/format/price_formatter.dart';

class ExpiredProductsReportPage extends ConsumerWidget {
  final List<Map<String, dynamic>> expiredEntries;
  final String? selectedProductName;
  final String reportTitle;

  const ExpiredProductsReportPage({
    super.key,
    required this.expiredEntries,
    this.selectedProductName,
    this.reportTitle = 'Laporan Produk Kadaluwarsa',
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<Uint8List> _buildReportPdf(Map<String, String> shopData) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = _formatDate(now);

    // Generate ID Laporan unik berdasarkan waktu (misal: EXP-20231025-1530)
    final reportId =
        'EXP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    // Hitung subtotal dan total harga
    final totalQuantity = expiredEntries.fold<double>(0, (sum, entry) {
      return sum + (entry['batch'] as StockBatch).quantity;
    });

    final totalHarga = expiredEntries.fold<double>(0, (sum, entry) {
      final product = entry['product'] as Barang;
      final batch = entry['batch'] as StockBatch;
      final costPrice =
          batch.costPrice ?? product.latestCostPrice ?? product.hargaSatuan;
      final costPerUnit = batch.costPerUnit ?? product.latestCostPerUnit ?? 1.0;
      final subtotal = (batch.quantity / costPerUnit) * costPrice;
      return sum + subtotal;
    });

    // ignore: no_leading_underscores_for_local_identifiers
    String _formatCurrency(double value) {
      return formatIdr(value);
    }

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
                      if ((shopData['email'] ?? '').isNotEmpty)
                        pw.Text(
                          'Email : ${shopData['email']!}',
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
                      'Laporan Produk',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Kadaluwarsa',
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

            // ── DIVIDER TEBAL ──
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
            if (selectedProductName != null) ...[
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.SizedBox(
                      width: 80,
                      child: pw.Text('Produk',
                          style: const pw.TextStyle(fontSize: 10))),
                  pw.Text(' : ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(selectedProductName!,
                      style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],

            pw.SizedBox(height: 14),

            // ── TABEL ──
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
                2: pw.Alignment.center, // Jumlah
                3: pw.Alignment.center, // Satuan
                4: pw.Alignment.centerRight, // Harga Beli
                5: pw.Alignment.centerRight, // Per pcs/kg
                6: pw.Alignment.center, // ID Faktur
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(42),
                3: const pw.FixedColumnWidth(42),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(2), // Lebar kolom Per pcs/kg
                6: const pw.FlexColumnWidth(2),
              },
              headers: [
                'No.',
                'Nama Produk',
                'Jumlah',
                'Satuan',
                'Harga Beli',
                'Per pcs/kg',
                'ID Faktur',
              ],
              data: expiredEntries.asMap().entries.map((e) {
                final index = e.key + 1;
                final entry = e.value;
                final product = entry['product'] as Barang;
                final batch = entry['batch'] as StockBatch;
                final satuan = product.measureType == 'weight' ? 'kg' : 'pcs';
                final invoiceId =
                    batch.invoiceId != null && batch.invoiceId!.length >= 8
                        ? batch.invoiceId!.substring(0, 8)
                        : (batch.invoiceId ?? '-');
                final qty = batch.quantity % 1 == 0
                    ? batch.quantity.toInt().toString()
                    : batch.quantity.toStringAsFixed(2);
                final costPrice = batch.costPrice ??
                    product.latestCostPrice ??
                    product.hargaSatuan;
                final costPerUnit =
                    batch.costPerUnit ?? product.latestCostPerUnit;
                final costPerUnitStr = costPerUnit != null
                    ? (product.measureType == 'weight'
                        ? costPerUnit.toStringAsFixed(2)
                        : costPerUnit.toInt().toString())
                    : '';
                return [
                  index.toString(),
                  product.namaBarang,
                  qty,
                  satuan,
                  _formatCurrency(costPrice),
                  costPerUnitStr,
                  invoiceId,
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 8),

            // ── RINGKASAN ──
            pw.Row(
              children: [
                // Sisi kiri kosong
                pw.Expanded(child: pw.SizedBox()),

                // Tabel ringkasan kanan
                pw.SizedBox(
                  width: 220,
                  child: pw.Table(
                    border: pw.TableBorder.all(width: 0.5),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.white),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'TOTAL HARGA',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              _formatCurrency(totalHarga),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            // ── FOOTER: total item ──
            pw.Text(
              'Total item batch: ${expiredEntries.length}  |  Total Jumlah: ${totalQuantity % 1 == 0 ? totalQuantity.toInt() : totalQuantity.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _printReport(Map<String, String> shopData) async {
    final pdfBytes = await _buildReportPdf(shopData);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shop_provider.shopNotifierProvider);
    final shopData = <String, String>{
      'name': '',
      'addressLine1': '',
      'phoneNumber': '',
      'email': '',
    };

    if (shopState.shop != null) {
      shopData['name'] = shopState.shop!.namaToko;
      shopData['addressLine1'] = shopState.shop!.alamatBaris1;
      shopData['phoneNumber'] = shopState.shop!.nomorTelepon;
      // Tambahkan email jika tersedia di model Shop
      // shopData['email'] = shopState.shop!.email;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Produk Kadaluwarsa'),
      ),
      body: SafeArea(
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
                        reportTitle,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menampilkan produk yang sudah kadaluwarsa atau akan kadaluwarsa dalam 7 hari.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Jumlah batch: ${expiredEntries.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: expiredEntries.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada laporan produk kadaluwarsa',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: expiredEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final entry = expiredEntries[index];
                          final product = entry['product'] as Barang;
                          final batch = entry['batch'] as StockBatch;
                          return Card(
                            child: ListTile(
                              title: Text(product.namaBarang),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Barcode: ${product.kodeBarang}'),
                                  Text(
                                      'Jumlah: ${batch.quantity % 1 == 0 ? batch.quantity.toInt() : batch.quantity.toStringAsFixed(2)} ${product.measureType == 'weight' ? 'kg' : 'pcs'}'),
                                  Text(
                                      'Kadaluwarsa: ${_formatDate(batch.expirationDate)}'),
                                  Text(
                                      'Faktur: ${batch.invoiceId != null && batch.invoiceId!.length >= 8 ? batch.invoiceId!.substring(0, 8) : (batch.invoiceId ?? '-')}'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _printReport(shopData),
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final pdfBytes = await _buildReportPdf(shopData);
                          await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename:
                                  'laporan_kadaluwarsa_${DateTime.now().year}_${DateTime.now().month}.pdf');
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
        ),
      ),
    );
  }
}
