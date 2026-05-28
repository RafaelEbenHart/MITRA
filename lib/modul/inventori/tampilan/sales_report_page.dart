import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mitra/infrastruktur/injeksi/service_locator.dart' as di;
import 'package:mitra/shared/kontrak/usecase.dart';
import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;
import 'package:mitra/modul/inventori/domain/entities/receipt.dart';
import 'package:mitra/modul/inventori/domain/usecases/inventory_usecases.dart';
import 'package:mitra/modul/inventori/tampilan/sales_report_detail_page.dart';

import 'sales_report_models.dart';

final salesReceiptsProvider = FutureProvider.autoDispose<List<Receipt>>(
  (ref) async {
    final result = await di.sl<GetSalesReceiptsUseCase>()(NoParams());
    return result.fold(
      (failure) => throw Exception('Tidak dapat memuat laporan penjualan.'),
      (receipts) => receipts,
    );
  },
);

class SalesReportPage extends ConsumerStatefulWidget {
  const SalesReportPage({super.key});

  @override
  ConsumerState<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends ConsumerState<SalesReportPage> {
  SalesReportMode _selectedMode = SalesReportMode.monthly;

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

  String _formatFullDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
  }

  double _receiptRevenue(Receipt receipt) {
    return receipt.totalAmount;
  }

  double _receiptQuantity(Receipt receipt) {
    return receipt.totalQuantity;
  }

  List<Map<String, dynamic>> _buildMonthlyReports(List<Receipt> receipts) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final receipt in receipts) {
      final year = receipt.createdDate.year;
      final month = receipt.createdDate.month;
      final key = '$year-$month';
      final reportDate = DateTime(year, month);
      final revenue = _receiptRevenue(receipt);
      final quantity = _receiptQuantity(receipt);

      if (grouped.containsKey(key)) {
        grouped[key]!['receiptCount'] += 1;
        grouped[key]!['quantity'] += quantity;
        grouped[key]!['revenue'] += revenue;
        grouped[key]!['receipts'].add(receipt);
      } else {
        grouped[key] = {
          'title': 'Laporan Penjualan Bulan ${_formatMonth(reportDate)}',
          'subtitle': '${receipt.items.length} produk',
          'reportDate': reportDate,
          'receiptCount': 1,
          'quantity': quantity,
          'revenue': revenue,
          'receipts': [receipt],
        };
      }
    }

    final reports = grouped.values.toList();
    reports.sort((a, b) {
      final first = a['reportDate'] as DateTime;
      final second = b['reportDate'] as DateTime;
      return second.compareTo(first);
    });
    return reports;
  }

  List<Map<String, dynamic>> _buildDailyReports(List<Receipt> receipts) {
    final grouped = <String, Map<String, dynamic>>{};

    for (final receipt in receipts) {
      final reportDate = DateTime(
        receipt.createdDate.year,
        receipt.createdDate.month,
        receipt.createdDate.day,
      );
      final key = DateFormat('yyyy-MM-dd').format(reportDate);
      final revenue = _receiptRevenue(receipt);
      final quantity = _receiptQuantity(receipt);

      if (grouped.containsKey(key)) {
        grouped[key]!['receiptCount'] += 1;
        grouped[key]!['quantity'] += quantity;
        grouped[key]!['revenue'] += revenue;
        grouped[key]!['receipts'].add(receipt);
      } else {
        grouped[key] = {
          'title': 'Laporan Penjualan Harian ${_formatFullDate(reportDate)}',
          'subtitle': '${receipt.items.length} produk',
          'reportDate': reportDate,
          'receiptCount': 1,
          'quantity': quantity,
          'revenue': revenue,
          'receipts': [receipt],
        };
      }
    }

    final reports = grouped.values.toList();
    reports.sort((a, b) {
      final first = a['reportDate'] as DateTime;
      final second = b['reportDate'] as DateTime;
      return second.compareTo(first);
    });
    return reports;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: const Text('Laporan Penjualan'),
              centerTitle: true,
              bottom: TabBar(
                onTap: (index) {
                  setState(() {
                    _selectedMode = index == 0
                        ? SalesReportMode.monthly
                        : SalesReportMode.daily;
                  });
                },
                tabs: const [
                  Tab(text: 'Bulanan'),
                  Tab(text: 'Harian'),
                ],
              ),
            ),
            body: ref.watch(salesReceiptsProvider).when(
                  data: (receipts) {
                    final reportItems = _selectedMode == SalesReportMode.monthly
                        ? _buildMonthlyReports(receipts)
                        : _buildDailyReports(receipts);
                    final totalRevenue = receipts.fold<double>(
                      0.0,
                      (sum, receipt) => sum + _receiptRevenue(receipt),
                    );

                    final shopState =
                        ref.watch(shop_provider.shopNotifierProvider);
                    final shopData = <String, String>{
                      'name': '',
                      'addressLine1': '',
                      'phoneNumber': '',
                    };

                    if (shopState.shop != null) {
                      shopData['name'] = shopState.shop!.namaToko;
                      shopData['addressLine1'] = shopState.shop!.alamatBaris1;
                      shopData['phoneNumber'] = shopState.shop!.nomorTelepon;
                    }

                    final reportTitle = _selectedMode == SalesReportMode.monthly
                        ? 'Daftar Laporan Penjualan Bulanan'
                        : 'Daftar Laporan Penjualan Harian';

                    return SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reportTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pilih periode laporan untuk melihat riwayat penjualan dan detail transaksi.',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 12),
                                    if (shopData['name']!.isNotEmpty) ...[
                                      Text('Toko: ${shopData['name']}'),
                                      if (shopData['addressLine1']!.isNotEmpty)
                                        Text(shopData['addressLine1']!),
                                      if (shopData['phoneNumber']!.isNotEmpty)
                                        Text('Tel: ${shopData['phoneNumber']}'),
                                      const SizedBox(height: 12),
                                    ],
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _buildInfoChip('Total Pendapatan',
                                            formatIdr(totalRevenue)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: reportItems.isEmpty
                                  ? Center(
                                      child: Text(
                                        _selectedMode == SalesReportMode.monthly
                                            ? 'Tidak ada laporan penjualan bulanan tersedia.'
                                            : 'Tidak ada laporan penjualan harian tersedia.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: reportItems.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final item = reportItems[index];
                                        final reportDate =
                                            item['reportDate'] as DateTime;
                                        final quantity =
                                            item['quantity'] as double;
                                        return Card(
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SalesReportDetailPage(
                                                    title:
                                                        item['title'] as String,
                                                    reportDate: reportDate,
                                                    mode: _selectedMode,
                                                    receipts:
                                                        List<Receipt>.from(
                                                      item['receipts']
                                                          as List<Receipt>,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['title'] as String,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade300),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Table(
                                                      columnWidths: const {
                                                        0: FlexColumnWidth(1),
                                                        1: FlexColumnWidth(1),
                                                      },
                                                      children: [
                                                        TableRow(
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              child: Text(
                                                                'Total pendapatan',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              child: Text(
                                                                formatIdr(item[
                                                                        'revenue']
                                                                    as double),
                                                                textAlign:
                                                                    TextAlign
                                                                        .right,
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(
                                                    '${quantity % 1 == 0 ? quantity.toInt() : quantity.toStringAsFixed(2)} jumlah',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(error is Exception
                        ? error.toString().replaceFirst('Exception: ', '')
                        : 'Terjadi kesalahan saat memuat data.'),
                  ),
                )));
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
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
