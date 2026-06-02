import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mitra/modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;
import 'package:mitra/modul/akses/tampilan/controllers/auth_provider.dart'
    as auth_provider;
import 'inventory_provider.dart';
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
    final authState = ref.watch(auth_provider.authNotifierProvider);
    final productState = ref.watch(product_provider.productNotifierProvider);

    // Pastikan auth sudah ready dan products sudah diload
    ref.listen(auth_provider.authNotifierProvider, (previous, next) {
      if (next is auth_provider.AuthAuthenticated &&
          productState.status == product_provider.ProductStatus.initial) {
        Future.microtask(() => ref
            .read(product_provider.productNotifierProvider.notifier)
            .loadProducts());
      }
    });

    // Jika user belum authenticated, tampilkan loading
    if (authState is! auth_provider.AuthAuthenticated) {
      return Scaffold(
        appBar:
            AppBar(title: const Text('Laporan Persediaan'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Load products jika belum
    if (productState.status == product_provider.ProductStatus.initial) {
      Future.microtask(() => ref
          .read(product_provider.productNotifierProvider.notifier)
          .loadProducts());
      return Scaffold(
        appBar:
            AppBar(title: const Text('Laporan Persediaan'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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

    // Generate list dari semua bulan yang ada invoices
    final invoiceHistoryState = ref.watch(invoiceHistoryProvider);

    return invoiceHistoryState.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Persediaan'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Persediaan'),
          centerTitle: true,
        ),
        body: Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
      data: (invoiceHistory) {
        // Group invoices by month-year
        final uniqueMonths = <String, DateTime>{};
        for (final inv in invoiceHistory) {
          final key =
              '${inv.createdDate.year}-${inv.createdDate.month.toString().padLeft(2, '0')}';
          if (!uniqueMonths.containsKey(key)) {
            uniqueMonths[key] = inv.createdDate;
          }
        }

        // Sort by date descending (newest first)
        final sortedMonths = uniqueMonths.values.toList()
          ..sort((a, b) => b.compareTo(a));

        // Generate items for each month
        final reportItems = sortedMonths
            .map((month) => {
                  'title': 'Laporan Persediaan Bulan ${_formatMonth(month)}',
                  'subtitle':
                      'Ringkasan stok per bulan (masuk & keluar disertakan)',
                  'type': 'inventory',
                  'reportDate': month,
                })
            .toList();

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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  child: reportItems.isEmpty
                      ? const Center(
                          child: Text('Tidak ada laporan persediaan'),
                        )
                      : ListView.separated(
                          itemCount: reportItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = reportItems[index];
                            return Card(
                              child: ListTile(
                                title: Text(item['title'] as String),
                                subtitle: Text(item['subtitle'] as String),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  final reportDate =
                                      item['reportDate'] as DateTime;
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => InventoryReportDetailPage(
                                      reportDate: reportDate,
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
      },
    );
  }
}
