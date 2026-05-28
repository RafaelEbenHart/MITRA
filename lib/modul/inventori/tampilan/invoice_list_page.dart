import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_provider.dart';
import 'package:mitra/modul/inventori/tampilan/invoice_preview_page.dart';
import 'package:intl/intl.dart';
import 'package:mitra/shared/format/price_formatter.dart';

class InvoiceListPage extends ConsumerStatefulWidget {
  const InvoiceListPage({super.key});

  @override
  ConsumerState<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends ConsumerState<InvoiceListPage> {
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
    final state = ref.watch(inventoryNotifierProvider);
    final notifier = ref.read(inventoryNotifierProvider.notifier);
    final invoices = state.invoiceHistory;
    final filteredInvoices = _searchQuery.isEmpty
        ? invoices
        : invoices.where((invoice) {
            return invoice.id.toLowerCase().contains(_searchQuery);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Faktur'),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari Faktur',
                    hintText: 'Cari berdasarkan ID faktur',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Builder(builder: (context) {
                  if (state.isLoading && invoices.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (filteredInvoices.isEmpty) {
                    return Center(
                      child: Text(_searchQuery.isEmpty
                          ? 'Belum ada faktur'
                          : 'Tidak ada faktur yang cocok.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredInvoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final invoice = filteredInvoices[index];
                      return Card(
                        child: ListTile(
                          title:
                              Text('ID Faktur: ${invoice.id.substring(0, 8)}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm')
                                    .format(invoice.createdDate),
                              ),
                              if (invoice.createdBy != null &&
                                  invoice.createdBy!.isNotEmpty)
                                Text('Dibuat oleh: ${invoice.createdBy!}'),
                            ],
                          ),
                          trailing: Text(formatIdr(invoice.totalAmount)),
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (_) =>
                                  InvoicePreviewPage(invoice: invoice),
                            ))
                                .then((_) {
                              notifier.fetchInvoiceHistory();
                            });
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
