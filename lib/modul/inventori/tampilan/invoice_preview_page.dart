import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;

class InvoicePreviewPage extends ConsumerWidget {
  final Invoice invoice;

  const InvoicePreviewPage({
    super.key,
    required this.invoice,
  });

  Future<Uint8List> _buildInvoicePdf(
      Invoice invoice, Map<String, String> shopData) async {
    final pdf = pw.Document();
    final shopName = invoice.shop != null && invoice.shop!.namaToko.isNotEmpty
        ? invoice.shop!.namaToko
        : shopData['name'] ?? '';
    final addressLine1 =
        invoice.shop != null && invoice.shop!.alamatBaris1.isNotEmpty
            ? invoice.shop!.alamatBaris1
            : shopData['addressLine1'] ?? '';
    final phoneNumber =
        invoice.shop != null && invoice.shop!.nomorTelepon.isNotEmpty
            ? invoice.shop!.nomorTelepon
            : shopData['phoneNumber'] ?? '';

    // Calculate totals with correct cost calculation
    double subtotalSum = 0;
    for (final item in invoice.items) {
      final costPerUnit =
          item.costPerUnit ?? item.product.latestCostPerUnit ?? 1.0;
      final costPrice = item.costPrice ??
          item.product.latestCostPrice ??
          item.product.hargaSatuan;
      final itemSubtotal = (item.quantity / costPerUnit) * costPrice;
      subtotalSum += itemSubtotal;
    }

    double totalDiscount = invoice.items.fold(0, (sum, item) {
      final costPerUnit =
          item.costPerUnit ?? item.product.latestCostPerUnit ?? 1.0;
      final costPrice = item.costPrice ??
          item.product.latestCostPrice ??
          item.product.hargaSatuan;
      final itemSubtotal = (item.quantity / costPerUnit) * costPrice;
      if (item.discount != null && item.discount! > 0) {
        return sum + (itemSubtotal * item.discount! / 100);
      }
      return sum;
    });
    final taxPercent = invoice.taxPercentage ?? 0.0;
    double taxAmount = (subtotalSum - totalDiscount) * taxPercent / 100;
    double grandTotal = subtotalSum - totalDiscount + taxAmount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header: Shop info (left) + Title (right)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (shopName.isNotEmpty)
                        pw.Text(shopName,
                            style: pw.TextStyle(
                                fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      if (addressLine1.isNotEmpty)
                        pw.Text(addressLine1,
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      if (phoneNumber.isNotEmpty)
                        pw.Text('Telepon : $phoneNumber',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.Text(
                  'Faktur Produk Masuk',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            // Thick divider
            pw.Container(
              height: 6,
              color: PdfColors.black,
            ),
            pw.SizedBox(height: 12),
            // Info rows: Supplier info (left) | Invoice info (right)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfInfoRow('Nama Penjual/Distributor',
                          invoice.supplierName ?? ''),
                      pw.SizedBox(height: 4),
                      _pdfInfoRow('No. Telp', invoice.supplierPhone ?? ''),
                      pw.SizedBox(height: 4),
                      _pdfInfoRow('Alamat', invoice.supplierAddress ?? ''),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.SizedBox(
                  width: 180,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfInfoRow('No. Faktur',
                          invoice.id.substring(0, 8).toUpperCase()),
                      pw.SizedBox(height: 4),
                      _pdfInfoRow('Tanggal', invoice.formattedDate),
                      if (invoice.createdBy != null &&
                          invoice.createdBy!.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        _pdfInfoRow('Dibuat oleh', invoice.createdBy!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            // Items Table
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.white),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center, // Satuan
                4: pw.Alignment.centerRight, // Harga Beli
                5: pw.Alignment.centerRight, // Per pcs/kg
                6: pw.Alignment.center, // Disc
                7: pw.Alignment.centerRight, // Subtotal
              },
              headers: [
                'No.',
                'Nama Barang',
                'Jumlah',
                'Satuan',
                'Harga Beli',
                'Per pcs/kg',
                'Disc. %',
                'Subtotal'
              ],
              data: invoice.items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                final isWeight = item.measureType == 'weight';
                final measureLabel = isWeight ? 'kg' : 'pcs';

                // Cek format angka berdasarkan satuan
                final qtyString = isWeight
                    ? item.quantity.abs().toStringAsFixed(2)
                    : item.quantity.abs().toInt().toString();

                // Calculate correct subtotal
                final costPerUnit =
                    item.costPerUnit ?? item.product.latestCostPerUnit ?? 1.0;
                final costPrice = item.costPrice ??
                    item.product.latestCostPrice ??
                    item.product.hargaSatuan;
                final calculatedSubtotal =
                    (item.quantity / costPerUnit) * costPrice;

                // Format costPerUnit for display: Pcs tanpa .00, Weight dengan .00
                final costPerUnitStr = item.measureType == 'weight'
                    ? costPerUnit.toStringAsFixed(2)
                    : costPerUnit.toInt().toString();

                return [
                  '$index',
                  item.product.namaBarang,
                  qtyString,
                  measureLabel,
                  item.costPrice != null
                      ? formatIdr(item.costPrice!)
                      : (item.product.latestCostPrice != null
                          ? formatIdr(item.product.latestCostPrice!)
                          : 'N/A'),
                  costPerUnitStr,
                  item.discount != null
                      ? '${item.discount!.toStringAsFixed(2)}%'
                      : '-',
                  formatIdr(calculatedSubtotal),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 12),
            // Bottom section: Catatan (left) + Totals (right)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Catatan :',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _pdfTotalRow('Total :', formatIdr(subtotalSum)),
                      _pdfTotalRow('Diskon :', formatIdr(totalDiscount)),
                      _pdfTotalRow(
                          'Pajak (${taxPercent.toStringAsFixed(0)}%) :',
                          formatIdr(taxAmount)),
                      pw.Container(height: 1, color: PdfColors.black),
                      _pdfTotalRow('GRAND TOTAL :', formatIdr(grandTotal),
                          bold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),
            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Text('Pembeli', style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 48),
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('Penjual/Distributor',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 48),
                    pw.Container(width: 120, height: 1, color: PdfColors.black),
                  ],
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
          width: 130,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Text(': ', style: const pw.TextStyle(fontSize: 9)),
        pw.Expanded(
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ),
      ],
    );
  }

  pw.Widget _pdfTotalRow(String label, String value, {bool bold = false}) {
    final style = bold
        ? pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
        : const pw.TextStyle(fontSize: 9);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  Future<void> _printInvoicePdf(
      Invoice invoice, Map<String, String> shopData) async {
    final pdfBytes = await _buildInvoicePdf(invoice, shopData);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shop_provider.shopNotifierProvider);
    final shopName = invoice.shop != null && invoice.shop!.namaToko.isNotEmpty
        ? invoice.shop!.namaToko
        : shopState.shop != null
            ? shopState.shop!.namaToko
            : '';
    final addressLine1 =
        invoice.shop != null && invoice.shop!.alamatBaris1.isNotEmpty
            ? invoice.shop!.alamatBaris1
            : shopState.shop != null
                ? shopState.shop!.alamatBaris1
                : '';
    final phoneNumber =
        invoice.shop != null && invoice.shop!.nomorTelepon.isNotEmpty
            ? invoice.shop!.nomorTelepon
            : shopState.shop != null
                ? shopState.shop!.nomorTelepon
                : '';
    final shopData = {
      'name': shopName,
      'addressLine1': addressLine1,
      'phoneNumber': phoneNumber,
    };

    // Calculate totals with correct cost calculation
    double subtotalSum = 0;
    for (final item in invoice.items) {
      final costPerUnit =
          item.costPerUnit ?? item.product.latestCostPerUnit ?? 1.0;
      final costPrice = item.costPrice ??
          item.product.latestCostPrice ??
          item.product.hargaSatuan;
      final itemSubtotal = (item.quantity / costPerUnit) * costPrice;
      subtotalSum += itemSubtotal;
    }

    double totalDiscount = invoice.items.fold(0, (sum, item) {
      final costPerUnit =
          item.costPerUnit ?? item.product.latestCostPerUnit ?? 1.0;
      final costPrice = item.costPrice ??
          item.product.latestCostPrice ??
          item.product.hargaSatuan;
      final itemSubtotal = (item.quantity / costPerUnit) * costPrice;
      if (item.discount != null && item.discount! > 0) {
        return sum + (itemSubtotal * item.discount! / 100);
      }
      return sum;
    });
    final taxPercent = invoice.taxPercentage ?? 0.0;
    double taxAmount = (subtotalSum - totalDiscount) * taxPercent / 100;
    double grandTotal = subtotalSum - totalDiscount + taxAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau Faktur'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Shop info (left) + Title (right) ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (shopName.isNotEmpty)
                            Text(
                              shopName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          if (addressLine1.isNotEmpty)
                            Text(
                              addressLine1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          if (phoneNumber.isNotEmpty)
                            Text(
                              'Telepon : $phoneNumber',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'Faktur Produk Masuk',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Thick divider ──
                Container(
                  height: 6,
                  color: Colors.black,
                ),
                const SizedBox(height: 12),
                // ── Info rows: Supplier (left) | Invoice details (right) ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(context, 'Nama Penjual/Distributor',
                              invoice.supplierName ?? ''),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                              context, 'No. Telp', invoice.supplierPhone ?? ''),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                              context, 'Alamat', invoice.supplierAddress ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(context, 'Id. Faktur',
                              invoice.id.substring(0, 8).toUpperCase()),
                          const SizedBox(height: 4),
                          _buildInfoRow(
                              context, 'Tanggal', invoice.formattedDate),
                          if (invoice.createdBy != null &&
                              invoice.createdBy!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                context, 'Dibuat oleh', invoice.createdBy!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Items Table ──
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    border: TableBorder.all(color: Colors.black54, width: 0.5),
                    headingRowColor:
                        MaterialStateProperty.all(Colors.grey[200]),
                    headingTextStyle: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    dataTextStyle: Theme.of(context).textTheme.bodySmall,
                    columnSpacing: 16,
                    columns: const [
                      DataColumn(label: Text('No.')),
                      DataColumn(label: Text('Nama Barang')),
                      DataColumn(label: Text('Jumlah')),
                      DataColumn(label: Text('Satuan')),
                      DataColumn(label: Text('Harga Beli')),
                      DataColumn(label: Text('Per pcs/kg')), // Kolom baru
                      DataColumn(label: Text('Disc. %')),
                      DataColumn(label: Text('Subtotal')),
                    ],
                    rows: invoice.items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;
                      final isWeight = item.measureType == 'weight';
                      final measureLabel = isWeight ? 'kg' : 'pcs';

                      // Cek format angka berdasarkan satuan
                      final qtyString = isWeight
                          ? item.quantity.abs().toStringAsFixed(2)
                          : item.quantity.abs().toInt().toString();

                      // Calculate correct subtotal
                      final costPerUnit = item.costPerUnit ??
                          item.product.latestCostPerUnit ??
                          1.0;
                      final costPrice = item.costPrice ??
                          item.product.latestCostPrice ??
                          item.product.hargaSatuan;
                      final calculatedSubtotal =
                          (item.quantity / costPerUnit) * costPrice;

                      // Format costPerUnit for display
                      final costPerUnitStr = costPerUnit % 1 == 0
                          ? costPerUnit.toInt().toString()
                          : costPerUnit.toStringAsFixed(2);

                      return DataRow(cells: [
                        DataCell(Text('$index')),
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              item.product.namaBarang,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ),
                        DataCell(Text(qtyString)),
                        DataCell(Text(measureLabel)),
                        DataCell(Text(
                          item.costPrice != null
                              ? formatIdr(item.costPrice!)
                              : (item.product.latestCostPrice != null
                                  ? formatIdr(item.product.latestCostPrice!)
                                  : 'N/A'),
                        )),
                        DataCell(Text(costPerUnitStr)),
                        DataCell(Text(
                          item.discount != null
                              ? '${item.discount!.toStringAsFixed(2)}%'
                              : '-',
                        )),
                        DataCell(Text(
                          formatIdr(calculatedSubtotal),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Bottom section: Catatan (left) + Totals (right) ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catatan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catatan :',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Totals box
                    SizedBox(
                      width: 240,
                      child: Column(
                        children: [
                          _buildTotalRow(
                              context, 'Total :', formatIdr(subtotalSum)),
                          _buildTotalRow(
                              context, 'Diskon :', formatIdr(totalDiscount)),
                          _buildTotalRow(
                              context,
                              'Pajak (${taxPercent.toStringAsFixed(0)}%) :',
                              formatIdr(taxAmount)),
                          const Divider(color: Colors.black, thickness: 1),
                          _buildTotalRow(
                            context,
                            'GRAND TOTAL :',
                            formatIdr(grandTotal),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // ── Signatures ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSignatureBlock(context, 'Pembeli'),
                    _buildSignatureBlock(context, 'Penjual/Distributor'),
                  ],
                ),
                const SizedBox(height: 24),
                // ── Action Buttons ──
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _printInvoicePdf(invoice, shopData);
                        },
                        child: const Text('Cetak'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final pdfBytes =
                              await _buildInvoicePdf(invoice, shopData);
                          await Printing.sharePdf(
                              bytes: pdfBytes,
                              filename: 'faktur_${invoice.id}.pdf');
                        },
                        child: const Text('Ekspor PDF'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            softWrap: true,
          ),
        ),
        Text(': ', style: Theme.of(context).textTheme.bodySmall),
        Flexible(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(BuildContext context, String label, String value,
      {bool bold = false}) {
    final style = bold
        ? Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _buildSignatureBlock(BuildContext context, String label) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 48),
        Container(
          width: 120,
          height: 1,
          color: Colors.black54,
        ),
      ],
    );
  }
}
