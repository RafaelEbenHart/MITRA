import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mitra/modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;
import 'inventory_report_detail_page.dart';

class InventoryReportPage extends ConsumerWidget {
  const InventoryReportPage({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(product_provider.productNotifierProvider);

    if (productState.status == product_provider.ProductStatus.loading) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Laporan Persediaan'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (productState.status == product_provider.ProductStatus.error) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Laporan Persediaan'), centerTitle: true),
        body: Center(
            child: Text(productState.message ?? 'Gagal memuat data produk')),
      );
    }

    final now = DateTime.now();
    final reportItems = [
      {
        'title': 'Laporan Persediaan Bulan ${_formatMonth(now)}',
        'subtitle': 'Ringkasan stok per bulan (masuk & keluar disertakan)',
        'type': 'inventory',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Persediaan'),
        centerTitle: true,
      ),
      body: Padding(
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
                      'Daftar Laporan Persediaan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih laporan untuk melihat detail persediaan dan aliran produk masuk/keluar.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: reportItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = reportItems[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['title'] as String),
                      subtitle: Text(item['subtitle'] as String),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => InventoryReportDetailPage(
                            reportDate: now,
                            title: item['title'] as String,
                          ),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
