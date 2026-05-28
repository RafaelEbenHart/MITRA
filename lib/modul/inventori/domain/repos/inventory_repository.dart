import 'package:fpdart/fpdart.dart';
import '../../../../shared/galat/failures.dart';
import '../entities/invoice.dart';
import '../entities/receipt.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';

abstract class InventoryRepository {
  /// Create invoice for incoming stock (additions)
  Future<Either<Failure, Invoice>> createInvoice(
    List<InvoiceItem> items, {
    String? supplierName,
    String? supplierPhone,
    String? supplierAddress,
    double? taxPercentage,
  });

  /// Get all incoming invoices (stock additions only)
  Future<Either<Failure, List<Invoice>>> getInvoiceHistory();

  /// Get invoice by ID
  Future<Either<Failure, Invoice>> getInvoiceById(String id);

  /// Delete invoice
  Future<Either<Failure, void>> deleteInvoice(String id);

  /// Create receipt for sales (outgoing)
  Future<Either<Failure, Receipt>> createReceipt(
    List<ReceiptItem> items, {
    String? paymentMethod,
    double? totalDiscount,
    double? taxPercentage,
  });

  /// Get all sales receipts
  Future<Either<Failure, List<Receipt>>> getSalesReceipts();

  /// Get receipt by ID
  Future<Either<Failure, Receipt>> getReceiptById(String id);

  /// Delete receipt
  Future<Either<Failure, void>> deleteReceipt(String id);

  /// Update product quantity
  Future<Either<Failure, void>> updateProductQuantity(
    String productId,
    double quantity,
    String measureType,
    DateTime? expirationDate,
    String? invoiceId,
  );

  /// Get product with quantity
  Future<Either<Failure, Barang?>> getProductWithQuantity(String productId);
}
