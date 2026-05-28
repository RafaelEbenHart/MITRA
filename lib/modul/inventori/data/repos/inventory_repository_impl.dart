import 'package:fpdart/fpdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/receipt.dart';
import 'package:mitra/modul/toko/data/models/shop_model.dart';
import '../../../../infrastruktur/penyimpanan/firebase_database.dart';
import '../../domain/repos/inventory_repository.dart';
import '../../../../shared/galat/failures.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/inventori/data/models/product_model.dart';
import '../../../../shared/format/route_guard.dart';
import '../models/invoice_model.dart';
import '../models/receipt_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  static const String _invoicesCollection = 'invoices';
  static const String _receiptsCollection = 'receipts';
  static const String _productsCollection = 'products';

  final _firestore = FirebaseFirestore.instance;

  @override
  Future<Either<Failure, Invoice>> createInvoice(
    List<InvoiceItem> items, {
    String? supplierName,
    String? supplierPhone,
    String? supplierAddress,
    double? taxPercentage,
  }) async {
    try {
      final invoiceId = const Uuid().v4();
      final totalAmount =
          items.fold<double>(0.0, (total, item) => total + item.subtotal);

      final currentUser = await RouteGuard.getCurrentUser();
      final createdBy = currentUser?.namaLengkap ?? '';

      // Try to read shop details (optional)
      ShopModel? shopModel;
      try {
        final shopDoc =
            await FirebaseDatabase.shopsCollection().doc('shop_details').get();
        if (shopDoc.exists && shopDoc.data() != null) {
          shopModel = ShopModel.fromMap(shopDoc.data()!);
        }
      } catch (_) {
        shopModel = null;
      }

      final invoiceModel = InvoiceModel(
        id: invoiceId,
        createdDate: DateTime.now(),
        invoiceItems:
            items.map((item) => InvoiceItemModel.fromEntity(item)).toList(),
        totalAmount: totalAmount,
        status: 'completed',
        createdBy: createdBy,
        shopModel: shopModel,
        supplierName: supplierName,
        supplierPhone: supplierPhone,
        supplierAddress: supplierAddress,
        taxPercentage: taxPercentage,
      );

      // Use Firestore transaction to ensure atomicity:
      // 1. READ all product documents first
      // 2. WRITE invoice + all product updates together
      // Firestore requires all reads before any writes
      await _firestore.runTransaction((transaction) async {
        // STEP 1: Read all product documents first (all reads must happen before any writes)
        final productDataMap = <String, Map<String, dynamic>>{};
        for (final item in items) {
          final productRef = _firestore
              .collection(_productsCollection)
              .doc(item.product.idBarang);
          final productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw Exception('Produk tidak ditemukan: ${item.product.idBarang}');
          }

          productDataMap[item.product.idBarang] = productSnapshot.data()!;
        }

        // STEP 2: Validate and prepare all updates
        final productUpdates = <String, Map<String, dynamic>>{};
        final batchEntries = <String, List<Map<String, dynamic>>>{};

        for (final item in items) {
          final productData = productDataMap[item.product.idBarang]!;
          final currentQuantity =
              (productData['currentQuantity'] as num?)?.toDouble() ?? 0.0;
          final newQuantity = currentQuantity + item.quantity;

          // Validate new quantity to prevent negative stock
          if (newQuantity < 0) {
            throw Exception(
                'Stok tidak cukup untuk produk ${productData['name'] ?? item.product.idBarang}. Stok saat ini: $currentQuantity, permintaan: ${item.quantity.abs()}');
          }

          final updateData = {
            'currentQuantity': newQuantity,
            'measureType': item.measureType,
            if (item.costPrice != null) 'latestCostPrice': item.costPrice,
            if (item.costPerUnit != null) 'latestCostPerUnit': item.costPerUnit,
          };

          productUpdates[item.product.idBarang] = updateData;

          // Prepare batch entry if expirationDate is provided
          if (item.expirationDate != null) {
            final batch = {
              'id': const Uuid().v4(),
              'quantity': item.quantity,
              'expirationDate': Timestamp.fromDate(item.expirationDate!),
              'invoiceId': invoiceId,
              'isExpired': false,
              if (item.costPrice != null) 'costPrice': item.costPrice,
              if (item.costPerUnit != null) 'costPerUnit': item.costPerUnit,
            };
            // Add batch to the list, or create new list if product not in map yet
            if (batchEntries.containsKey(item.product.idBarang)) {
              batchEntries[item.product.idBarang]!.add(batch);
            } else {
              batchEntries[item.product.idBarang] = [batch];
            }
          }
        }

        // STEP 3: Now perform all writes (after all reads are complete)
        // Save invoice document
        final invoiceRef =
            _firestore.collection(_invoicesCollection).doc(invoiceId);
        transaction.set(invoiceRef, invoiceModel.toMap());

        // Update product quantities
        for (final item in items) {
          final productRef = _firestore
              .collection(_productsCollection)
              .doc(item.product.idBarang);
          final updateData = productUpdates[item.product.idBarang]!;

          // Add batch entry if available
          if (batchEntries.containsKey(item.product.idBarang)) {
            updateData['batches'] =
                FieldValue.arrayUnion(batchEntries[item.product.idBarang]!);
          }

          transaction.update(productRef, updateData);
        }
      });

      return Right(invoiceModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Invoice>>> getInvoiceHistory() async {
    try {
      final snapshot = await _firestore
          .collection(_invoicesCollection)
          .orderBy('createdDate', descending: true)
          .get();

      final invoices = snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data()).toEntity())
          .toList();

      return Right(invoices);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      final snapshot =
          await _firestore.collection(_invoicesCollection).doc(id).get();

      if (!snapshot.exists) {
        return const Left(CacheFailure('Invoice not found'));
      }

      final invoice = InvoiceModel.fromMap(snapshot.data()!).toEntity();
      return Right(invoice);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      await _firestore.collection(_invoicesCollection).doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProductQuantity(
    String productId,
    double quantity,
    String measureType,
    DateTime? expirationDate,
    String? invoiceId,
  ) async {
    try {
      // Use Firestore transaction to prevent race conditions:
      // Read current quantity, check if valid, then update atomically
      await _firestore.runTransaction((transaction) async {
        await _updateProductQuantityInTransaction(
          transaction,
          productId,
          quantity,
          measureType,
          expirationDate,
          invoiceId,
          null,
          null,
        );
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<void> _updateProductQuantityInTransaction(
    Transaction transaction,
    String productId,
    double quantity,
    String measureType,
    DateTime? expirationDate,
    String? invoiceId,
    double? costPrice,
    double? costPerUnit,
  ) async {
    final productRef =
        _firestore.collection(_productsCollection).doc(productId);
    final productSnapshot = await transaction.get(productRef);

    if (!productSnapshot.exists) {
      throw Exception('Product not found');
    }

    final productData = productSnapshot.data()!;
    final currentQuantity =
        (productData['currentQuantity'] as num?)?.toDouble() ?? 0.0;
    final newQuantity = currentQuantity + quantity;

    // Validate new quantity to prevent negative stock
    if (newQuantity < 0) {
      throw Exception(
          'Stok tidak cukup untuk produk ${productData['name'] ?? productId}. Stok saat ini: $currentQuantity, permintaan: ${quantity.abs()}');
    }

    final updateData = {
      'currentQuantity': newQuantity,
      'measureType': measureType,
      if (costPrice != null) 'latestCostPrice': costPrice,
      if (costPerUnit != null) 'latestCostPerUnit': costPerUnit,
    };

    // If expirationDate provided, add a batch entry to 'batches' array
    if (expirationDate != null) {
      final batch = {
        'id': const Uuid().v4(),
        'quantity': quantity,
        'expirationDate': Timestamp.fromDate(expirationDate),
        'invoiceId': invoiceId,
        'isExpired': false,
        if (costPrice != null) 'costPrice': costPrice,
        if (costPerUnit != null) 'costPerUnit': costPerUnit,
      };
      updateData['batches'] = FieldValue.arrayUnion([batch]);
    }

    // Update product with the new quantity (atomic within transaction)
    transaction.update(productRef, updateData);
  }

  @override
  Future<Either<Failure, Barang?>> getProductWithQuantity(
    String productId,
  ) async {
    try {
      final snapshot =
          await _firestore.collection(_productsCollection).doc(productId).get();

      if (!snapshot.exists) {
        return const Right(null);
      }

      final product = ProductModel.fromMap(snapshot.data()!).toEntity();
      return Right(product);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ============ RECEIPT METHODS (Sales/Outgoing) ============

  @override
  Future<Either<Failure, Receipt>> createReceipt(
    List<ReceiptItem> items, {
    String? paymentMethod,
    double? totalDiscount,
    double? taxPercentage,
  }) async {
    try {
      final receiptId = const Uuid().v4();
      final totalAmount =
          items.fold<double>(0.0, (total, item) => total + item.subtotal);

      final currentUser = await RouteGuard.getCurrentUser();
      final createdBy = currentUser?.namaLengkap ?? '';

      // Try to read shop details (optional)
      ShopModel? shopModel;
      try {
        final shopDoc =
            await FirebaseDatabase.shopsCollection().doc('shop_details').get();
        if (shopDoc.exists && shopDoc.data() != null) {
          shopModel = ShopModel.fromMap(shopDoc.data()!);
        }
      } catch (_) {
        shopModel = null;
      }

      final receiptModel = ReceiptModel(
        id: receiptId,
        createdDate: DateTime.now(),
        receiptItems:
            items.map((item) => ReceiptItemModel.fromEntity(item)).toList(),
        totalAmount: totalAmount,
        status: 'completed',
        createdBy: createdBy,
        shopModel: shopModel,
        paymentMethod: paymentMethod ?? 'cash',
        totalDiscount: totalDiscount,
        taxPercentage: taxPercentage,
      );

      // Use Firestore transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        // STEP 1: Read all product documents first
        final productDataMap = <String, Map<String, dynamic>>{};
        for (final item in items) {
          final productRef = _firestore
              .collection(_productsCollection)
              .doc(item.product.idBarang);
          final productSnapshot = await transaction.get(productRef);

          if (!productSnapshot.exists) {
            throw Exception('Produk tidak ditemukan: ${item.product.idBarang}');
          }

          productDataMap[item.product.idBarang] = productSnapshot.data()!;
        }

        // STEP 2: Validate and prepare all updates
        final productUpdates = <String, Map<String, dynamic>>{};

        for (final item in items) {
          final productData = productDataMap[item.product.idBarang]!;
          final currentQuantity =
              (productData['currentQuantity'] as num?)?.toDouble() ?? 0.0;
          final newQuantity =
              currentQuantity + item.quantity; // item.quantity is negative

          // Validate new quantity to prevent negative stock
          if (newQuantity < 0) {
            throw Exception(
                'Stok tidak cukup untuk produk ${productData['name'] ?? item.product.idBarang}. Stok saat ini: $currentQuantity, permintaan: ${item.quantity.abs()}');
          }

          final updateData = {
            'currentQuantity': newQuantity,
            'measureType': item.measureType,
            if (item.costPrice != null) 'latestCostPrice': item.costPrice,
            if (item.costPerUnit != null) 'latestCostPerUnit': item.costPerUnit,
          };

          productUpdates[item.product.idBarang] = updateData;
        }

        // STEP 3: Now perform all writes
        // Save receipt document
        final receiptRef =
            _firestore.collection(_receiptsCollection).doc(receiptId);
        transaction.set(receiptRef, receiptModel.toMap());

        // Update product quantities
        for (final item in items) {
          final productRef = _firestore
              .collection(_productsCollection)
              .doc(item.product.idBarang);
          final updateData = productUpdates[item.product.idBarang]!;
          transaction.update(productRef, updateData);
        }
      });

      return Right(receiptModel.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Receipt>>> getSalesReceipts() async {
    try {
      final snapshot = await _firestore
          .collection(_receiptsCollection)
          .orderBy('createdDate', descending: true)
          .get();

      final receipts = snapshot.docs
          .map((doc) => ReceiptModel.fromMap(doc.data()).toEntity())
          .toList();

      return Right(receipts);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Receipt>> getReceiptById(String id) async {
    try {
      final snapshot =
          await _firestore.collection(_receiptsCollection).doc(id).get();

      if (!snapshot.exists) {
        return const Left(CacheFailure('Receipt not found'));
      }

      final receipt = ReceiptModel.fromMap(snapshot.data()!).toEntity();
      return Right(receipt);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReceipt(String id) async {
    try {
      await _firestore.collection(_receiptsCollection).doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
