import 'package:flutter/material.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';

class ProductSearchCard extends StatelessWidget {
  final Barang product;
  final VoidCallback onAddTap;

  const ProductSearchCard({
    super.key,
    required this.product,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produk Ditemukan',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Nama: ${product.namaBarang}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Barcode: ${product.kodeBarang}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAddTap,
                child: const Text('Pilih Produk'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

