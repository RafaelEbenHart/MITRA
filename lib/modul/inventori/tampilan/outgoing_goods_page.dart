import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitra/modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;
import 'expired_products_report_page.dart';

class OutgoingGoodsPage extends ConsumerStatefulWidget {
  const OutgoingGoodsPage({super.key});

  @override
  ConsumerState<OutgoingGoodsPage> createState() => _OutgoingGoodsPageState();
}

class _OutgoingGoodsPageState extends ConsumerState<OutgoingGoodsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(product_provider.productNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk Keluar (Kadaluwarsa)'),
      ),
      body: Builder(builder: (context) {
        if (state.status == product_provider.ProductStatus.loading &&
            state.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final expiredBatches = <Map<String, dynamic>>[];
        final now = DateTime.now();

        for (final p in state.products) {
          if (p.batches != null) {
            for (final b in p.batches!) {
              final daysLeft = b.expirationDate.difference(now).inDays;
              // consider a wider range so we can bucket by 7-day windows
              if (daysLeft <= 0) {
                expiredBatches.add({
                  'product': p,
                  'batch': b,
                  'daysLeft': daysLeft,
                });
              }
            }
          }
        }

        // helper: floor division for negative numbers
        int floorDiv(int a, int b) {
          if (b == 0) return 0;
          if (a >= 0) return a ~/ b;
          return -(((-a + b - 1) ~/ b));
        }

        // Apply search first (search product name, barcode or invoice id)
        final searched = _searchQuery.isEmpty
            ? expiredBatches
            : expiredBatches.where((entry) {
                final product = entry['product'];
                final batch = entry['batch'];
                final invoiceId = (batch.invoiceId ?? '').toLowerCase();
                return product.name.toLowerCase().contains(_searchQuery) ||
                    product.barcode.toLowerCase().contains(_searchQuery) ||
                    invoiceId.contains(_searchQuery);
              }).toList();

        if (searched.isEmpty) {
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Laporan Produk Keluar',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('Tidak ada hasil pencarian.'),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Produk Keluar',
                    hintText: 'Cari nama produk atau ID faktur',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          );
        }

        // Group searched entries into 7-day buckets relative to today
        final Map<int, List<Map<String, dynamic>>> buckets = {};
        for (final entry in searched) {
          final daysLeft = entry['daysLeft'] as int;
          final idx = floorDiv(daysLeft, 7);
          buckets.putIfAbsent(idx, () => []).add(entry);
        }

        final sortedKeys = buckets.keys.toList()..sort();

        // UI: list of buckets (reports)
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Laporan Produk Keluar (Per 7 hari)',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Menampilkan produk yang sudah kadaluwarsa dalam rentang 7 hari.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Cari Produk Keluar',
                  hintText: 'Cari nama produk atau ID faktur',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sortedKeys.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final key = sortedKeys[index];
                  final entries = buckets[key]!;
                  final start = now.add(Duration(days: key * 7));
                  final end = start.add(const Duration(days: 6));
                  String format(DateTime d) =>
                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                  final title = '${format(start)} - ${format(end)}';

                  return Card(
                    child: ListTile(
                      title: Text('Rentang: $title'),
                      subtitle: Text('Jumlah batch: ${entries.length}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ExpiredProductsReportPage(
                            expiredEntries: entries,
                          ),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
