import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;
import 'package:mitra/modul/inventori/domain/entities/receipt.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/inventori/tampilan/sales_report_models.dart';

class SalesReportDetailPage extends ConsumerWidget {
  final String title;
  final DateTime reportDate;
  final SalesReportMode mode;
  final List<Receipt> receipts;

  const SalesReportDetailPage({
    super.key,
    required this.title,
    required this.reportDate,
    required this.mode,
    required this.receipts,
  });

  String _formatFullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
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

  double _totalRevenue() {
    return receipts.fold<double>(0.0, (sum, receipt) {
      return sum + receipt.totalAmount;
    });
  }

  double _totalQuantity() {
    return receipts.fold<double>(0.0, (sum, receipt) {
      return sum + receipt.totalQuantity;
    });
  }

  List<Map<String, dynamic>> _aggregateProductSales() {
    final aggregated = <String, Map<String, dynamic>>{};

    for (final receipt in receipts) {
      for (final item in receipt.items) {
        final key = item.product.idBarang;
        final quantity = item.quantity.abs();
        final revenue = item.product.hargaSatuan * quantity;

        if (aggregated.containsKey(key)) {
          aggregated[key]!['quantity'] += quantity;
          aggregated[key]!['revenue'] += revenue;
        } else {
          aggregated[key] = {
            'product': item.product,
            'quantity': quantity,
            'unitCost': item.product.latestCostPrice ?? 0.0,
            'unitPrice': item.product.hargaSatuan,
            'revenue': revenue,
          };
        }
      }
    }

    final salesList = aggregated.values.toList();
    salesList.sort((a, b) {
      final qtyA = a['quantity'] as double;
      final qtyB = b['quantity'] as double;
      return qtyB.compareTo(qtyA);
    });
    return salesList;
  }

  // Helper untuk mendapatkan list item penjualan harian secara flat
  List<Map<String, dynamic>> _getDailySalesItems() {
    final dailyItems = <Map<String, dynamic>>[];
    for (final receipt in receipts) {
      for (final item in receipt.items) {
        dailyItems.add({
          'product': item.product,
          'quantity': item.quantity.abs(),
          'price': item.product.hargaSatuan,
          'createdBy': receipt.createdBy,
          'subtotal': item.quantity.abs() * item.product.hargaSatuan,
        });
      }
    }
    return dailyItems;
  }

  Future<Uint8List> _buildReportPdf(
    Map<String, String> shopData,
  ) async {
    final pdf = pw.Document();
    final isMonthly = mode == SalesReportMode.monthly;

    final reportTitleText =
        isMonthly ? 'Laporan Penjualan Bulanan' : 'Laporan Penjualan Harian';

    final now = DateTime.now();
    final reportId =
        'REP-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final displayDate =
        isMonthly ? _formatMonth(reportDate) : _formatFullDate(reportDate);

    final totalRevenue = _totalRevenue();

    // Data tabel
    final headers = isMonthly
        ? [
            'No.',
            'Nama Produk',
            'Barcode',
            'Jumlah',
            'Satuan',
            'Harga Beli',
            'Subtotal'
          ]
        : [
            'No.',
            'Nama Produk',
            'Barcode',
            'Jumlah',
            'Satuan',
            'Harga Jual',
            'Dilayani Oleh',
            'Subtotal'
          ];

    final data = <List<String>>[];

    if (isMonthly) {
      final aggregated = _aggregateProductSales();
      for (int i = 0; i < aggregated.length; i++) {
        final item = aggregated[i];
        final p = item['product'] as Barang;
        final qty = item['quantity'] as double;
        final qtyStr =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);
        final satuan = p.measureType == 'weight' ? 'kg' : 'pcs';

        data.add([
          '${i + 1}',
          p.namaBarang,
          p.kodeBarang,
          qtyStr,
          satuan,
          formatIdr(item['unitCost'] as double),
          formatIdr(item['revenue'] as double),
        ]);
      }
    } else {
      final dailyItems = _getDailySalesItems();
      for (int i = 0; i < dailyItems.length; i++) {
        final item = dailyItems[i];
        final p = item['product'] as Barang;
        final qty = item['quantity'] as double;
        final qtyStr =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);
        final satuan = p.measureType == 'weight' ? 'kg' : 'pcs';
        final createdBy = item['createdBy'] as String?;

        data.add([
          '${i + 1}',
          p.namaBarang,
          p.kodeBarang,
          qtyStr,
          satuan,
          formatIdr(item['price'] as double),
          createdBy?.isNotEmpty == true ? createdBy! : '-',
          formatIdr(item['subtotal'] as double),
        ]);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // ── HEADER: Detail Toko (Kiri) & Judul Laporan (Kanan) ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (shopData['name']?.isNotEmpty == true)
                        pw.Text(
                          shopData['name']!,
                          style: pw.TextStyle(
                              fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                      if (shopData['addressLine1']?.isNotEmpty == true)
                        pw.Text(
                          shopData['addressLine1']!,
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      if (shopData['phoneNumber']?.isNotEmpty == true)
                        pw.Text(
                          'Telepon : ${shopData['phoneNumber']!}',
                          style: pw.TextStyle(
                              fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                pw.Text(
                  reportTitleText.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight
                          .bold), // Font tidak terlalu besar sesuai instruksi
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── THICK DIVIDER ──
            pw.Container(
              height: 6,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 12),

            // ── METADATA: No Laporan & Tanggal ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 300,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfInfoRow('No. Laporan', reportId),
                      pw.SizedBox(height: 4),
                      _pdfInfoRow('Tanggal', displayDate),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── TABEL DATA ──
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: isMonthly
                  ? {
                      0: pw.Alignment.center, // No
                      1: pw.Alignment.centerLeft, // Nama
                      2: pw.Alignment.centerLeft, // Barcode
                      3: pw.Alignment.center, // Jumlah
                      4: pw.Alignment.center, // Satuan
                      5: pw.Alignment.centerRight, // Harga Beli
                      6: pw.Alignment.centerRight, // Subtotal
                    }
                  : {
                      0: pw.Alignment.center, // No
                      1: pw.Alignment.centerLeft, // Nama
                      2: pw.Alignment.centerLeft, // Barcode
                      3: pw.Alignment.center, // Jumlah
                      4: pw.Alignment.center, // Satuan
                      5: pw.Alignment.centerRight, // Harga Jual
                      6: pw.Alignment.center, // Dilayani Oleh
                      7: pw.Alignment.centerRight, // Subtotal
                    },
              headers: headers,
              data: data,
            ),
            pw.SizedBox(height: 8),

            // ── FOOTER TABEL: Total Pendapatan ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 200,
                  child: pw.Table(
                    border:
                        pw.TableBorder.all(width: 0.5, color: PdfColors.black),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              'Total Pendapatan :',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              formatIdr(totalRevenue),
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 9)),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  Future<void> _printReport(Map<String, String> shopData) async {
    final bytes = await _buildReportPdf(shopData);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _shareReport(Map<String, String> shopData) async {
    final bytes = await _buildReportPdf(shopData);
    await Printing.sharePdf(
      bytes: bytes,
      filename: mode == SalesReportMode.daily
          ? 'laporan_penjualan_harian_${reportDate.year}_${reportDate.month}_${reportDate.day}.pdf'
          : 'laporan_penjualan_bulan_${reportDate.year}_${reportDate.month}.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shop_provider.shopNotifierProvider);
    final shopData = <String, String>{};
    if (shopState.shop != null) {
      shopData['name'] = shopState.shop!.namaToko;
      shopData['addressLine1'] = shopState.shop!.alamatBaris1;
      shopData['phoneNumber'] = shopState.shop!.nomorTelepon;
    }

    final totalRevenue = _totalRevenue();
    final totalQty = _totalQuantity();
    final isMonthly = mode == SalesReportMode.monthly;

    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── INFORMASI HEADER UI ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isMonthly
                            ? 'Bulan: ${_formatMonth(reportDate)}'
                            : 'Tanggal: ${_formatFullDate(reportDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildInfoChip(
                            'Jumlah Item',
                            totalQty % 1 == 0
                                ? totalQty.toInt().toString()
                                : totalQty.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── BOX TOTAL PENDAPATAN ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                    Text(
                      formatIdr(totalRevenue),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── TABEL DATA DI UI ──
              Expanded(
                child: (isMonthly
                        ? _aggregateProductSales().isEmpty
                        : _getDailySalesItems().isEmpty)
                    ? Center(
                        child: Text(
                          'Tidak ada data penjualan untuk periode ini.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Card(
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: isMonthly
                                ? _buildMonthlyDataTable(context)
                                : _buildDailyDataTable(context),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),

              // ── ACTION BUTTONS ──
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: receipts.isEmpty
                            ? null
                            : () => _printReport(shopData),
                        icon: const Icon(Icons.print),
                        label: const Text('Cetak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: receipts.isEmpty
                            ? null
                            : () => _shareReport(shopData),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Ekspor PDF'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        )));
  }

  Widget _buildMonthlyDataTable(BuildContext context) {
    final items = _aggregateProductSales();
    return DataTable(
      headingTextStyle: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(fontWeight: FontWeight.bold),
      dataTextStyle: Theme.of(context).textTheme.bodySmall,
      columns: const [
        DataColumn(label: Text('No.')),
        DataColumn(label: Text('Nama Produk')),
        DataColumn(label: Text('Barcode')),
        DataColumn(label: Text('Jumlah')),
        DataColumn(label: Text('Satuan')),
        DataColumn(label: Text('Harga Beli')),
        DataColumn(label: Text('Subtotal')),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final p = item['product'] as Barang;
        final qty = item['quantity'] as double;
        final qtyStr =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);
        final satuan = p.measureType == 'weight' ? 'kg' : 'pcs';

        return DataRow(cells: [
          DataCell(Text('${i + 1}')),
          DataCell(Text(p.namaBarang)),
          DataCell(Text(p.kodeBarang)),
          DataCell(Text(qtyStr)),
          DataCell(Text(satuan)),
          DataCell(Text(formatIdr(item['unitCost'] as double))),
          DataCell(Text(formatIdr(item['revenue'] as double))),
        ]);
      }).toList(),
    );
  }

  Widget _buildDailyDataTable(BuildContext context) {
    final items = _getDailySalesItems();
    return DataTable(
      headingTextStyle: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(fontWeight: FontWeight.bold),
      dataTextStyle: Theme.of(context).textTheme.bodySmall,
      columns: const [
        DataColumn(label: Text('No.')),
        DataColumn(label: Text('Nama Produk')),
        DataColumn(label: Text('Barcode')),
        DataColumn(label: Text('Jumlah')),
        DataColumn(label: Text('Satuan')),
        DataColumn(label: Text('Harga Jual')),
        DataColumn(label: Text('Dilayani Oleh')),
        DataColumn(label: Text('Subtotal')),
      ],
      rows: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final p = item['product'] as Barang;
        final qty = item['quantity'] as double;
        final qtyStr =
            qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(2);
        final satuan = p.measureType == 'weight' ? 'kg' : 'pcs';
        final createdBy = item['createdBy'] as String?;

        return DataRow(cells: [
          DataCell(Text('${i + 1}')),
          DataCell(Text(p.namaBarang)),
          DataCell(Text(p.kodeBarang)),
          DataCell(Text(qtyStr)),
          DataCell(Text(satuan)),
          DataCell(Text(formatIdr(item['price'] as double))),
          DataCell(Text(createdBy?.isNotEmpty == true ? createdBy! : '-')),
          DataCell(Text(formatIdr(item['subtotal'] as double))),
        ]);
      }).toList(),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
