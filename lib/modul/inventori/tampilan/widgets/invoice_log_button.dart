import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mitra/modul/inventori/tampilan/invoice_preview_page.dart';
import 'package:mitra/modul/inventori/domain/entities/invoice.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_provider.dart';
import 'package:mitra/shared/format/price_formatter.dart';

class InvoiceLogButton extends ConsumerStatefulWidget {
  const InvoiceLogButton({super.key});

  @override
  ConsumerState<InvoiceLogButton> createState() => _InvoiceLogButtonState();
}

class _InvoiceLogButtonState extends ConsumerState<InvoiceLogButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryNotifierProvider);
    final recentInvoices = state.invoiceHistory.take(5).toList();

    return Positioned(
      right: 16,
      top: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded list
          if (_isExpanded && recentInvoices.isNotEmpty)
            Container(
              width: 280,
              constraints: const BoxConstraints(maxHeight: 320),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: recentInvoices.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: Colors.grey[200],
                ),
                itemBuilder: (context, index) {
                  return _buildInvoiceListItem(
                    context,
                    recentInvoices[index],
                  );
                },
              ),
            ),
          // Icon button
          FloatingActionButton.small(
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            backgroundColor: Colors.blue,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _isExpanded ? Icons.close : Icons.receipt_long,
                  color: Colors.white,
                ),
                if (!_isExpanded && recentInvoices.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        recentInvoices.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceListItem(BuildContext context, Invoice invoice) {
    final dateFormat = DateFormat('HH:mm:ss');
    final formattedTime = dateFormat.format(invoice.createdDate);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => InvoicePreviewPage(
                invoice: invoice,
              ),
            ),
          )
              .then((_) {
            // Close the expanded list when returning
            setState(() => _isExpanded = false);
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ID: ${invoice.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${invoice.items.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatIdr(invoice.totalAmount),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
