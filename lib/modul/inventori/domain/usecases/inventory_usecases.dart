import 'package:fpdart/fpdart.dart';
import '../../../../shared/galat/failures.dart';
import '../../../../shared/kontrak/usecase.dart';
import '../entities/invoice.dart';
import '../entities/receipt.dart';
import '../repos/inventory_repository.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';

class CreateInvoiceUseCase extends UseCase<Invoice, CreateInvoiceParams> {
  final InventoryRepository repository;

  CreateInvoiceUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(CreateInvoiceParams params) {
    return repository.createInvoice(
      params.items,
      supplierName: params.supplierName,
      supplierPhone: params.supplierPhone,
      supplierAddress: params.supplierAddress,
      taxPercentage: params.taxPercentage,
    );
  }
}

class CreateInvoiceParams {
  final List<InvoiceItem> items;
  final String? supplierName;
  final String? supplierPhone;
  final String? supplierAddress;
  final double? taxPercentage;

  CreateInvoiceParams({
    required this.items,
    this.supplierName,
    this.supplierPhone,
    this.supplierAddress,
    this.taxPercentage,
  });
}

class GetInvoiceHistoryUseCase extends UseCase<List<Invoice>, NoParams> {
  final InventoryRepository repository;

  GetInvoiceHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Invoice>>> call(NoParams params) {
    return repository.getInvoiceHistory();
  }
}

class GetInvoiceByIdUseCase extends UseCase<Invoice, String> {
  final InventoryRepository repository;

  GetInvoiceByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Invoice>> call(String params) {
    return repository.getInvoiceById(params);
  }
}

class UpdateProductQuantityUseCase
    extends UseCase<void, UpdateProductQuantityParams> {
  final InventoryRepository repository;

  UpdateProductQuantityUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateProductQuantityParams params) {
    return repository.updateProductQuantity(
      params.productId,
      params.quantity,
      params.measureType,
      params.expirationDate,
      params.invoiceId,
    );
  }
}

class UpdateProductQuantityParams {
  final String productId;
  final double quantity;
  final String measureType;
  final DateTime? expirationDate;
  final String? invoiceId;

  UpdateProductQuantityParams({
    required this.productId,
    required this.quantity,
    required this.measureType,
    this.expirationDate,
    this.invoiceId,
  });
}

class GetProductWithQuantityUseCase extends UseCase<Barang?, String> {
  final InventoryRepository repository;

  GetProductWithQuantityUseCase(this.repository);

  @override
  Future<Either<Failure, Barang?>> call(String params) {
    return repository.getProductWithQuantity(params);
  }
}

// ============ RECEIPT USE CASES (Sales/Outgoing) ============

class CreateReceiptUseCase extends UseCase<Receipt, CreateReceiptParams> {
  final InventoryRepository repository;

  CreateReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(CreateReceiptParams params) {
    return repository.createReceipt(
      params.items,
      paymentMethod: params.paymentMethod,
      totalDiscount: params.totalDiscount,
      taxPercentage: params.taxPercentage,
    );
  }
}

class CreateReceiptParams {
  final List<ReceiptItem> items;
  final String? paymentMethod;
  final double? totalDiscount;
  final double? taxPercentage;

  CreateReceiptParams({
    required this.items,
    this.paymentMethod,
    this.totalDiscount,
    this.taxPercentage,
  });
}

class GetSalesReceiptsUseCase extends UseCase<List<Receipt>, NoParams> {
  final InventoryRepository repository;

  GetSalesReceiptsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Receipt>>> call(NoParams params) {
    return repository.getSalesReceipts();
  }
}

class GetReceiptByIdUseCase extends UseCase<Receipt, String> {
  final InventoryRepository repository;

  GetReceiptByIdUseCase(this.repository);

  @override
  Future<Either<Failure, Receipt>> call(String params) {
    return repository.getReceiptById(params);
  }
}

class DeleteReceiptUseCase extends UseCase<void, String> {
  final InventoryRepository repository;

  DeleteReceiptUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteReceipt(params);
  }
}
