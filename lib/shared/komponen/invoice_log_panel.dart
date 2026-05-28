import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_provider.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/shared/format/price_formatter.dart';

class InvoiceLogPanel extends ConsumerStatefulWidget {
  const InvoiceLogPanel({super.key});

  @override
  ConsumerState<InvoiceLogPanel> createState() => _InvoiceLogPanelState();
}

class _InvoiceLogPanelState extends ConsumerState<InvoiceLogPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryNotifierProvider);
    return Positioned(
      right: 12,
      top: 80,
      width: 300,
      child: Builder(
        builder: (context) {
          final recentInvoices = state.invoiceHistory.take(5).toList();

          if (recentInvoices.isEmpty) {
            return const SizedBox.shrink();
          }

          return Material(
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_isExpanded)
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.receipt,
                                    size: 18, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Invoice Log',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  if (_isExpanded)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: recentInvoices.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final invoice = recentInvoices[index];
                          return _buildInvoiceItem(context, invoice);
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceItem(BuildContext context, Invoice invoice) {
    final dateFormat = DateFormat('HH:mm:ss');
    final formattedTime = dateFormat.format(invoice.createdDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${invoice.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${invoice.items.length} item',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${formatIdr(invoice.totalAmount)}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
