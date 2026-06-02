import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../infrastruktur/penyimpanan/firebase_database.dart';
import '../../../../shared/galat/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repos/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  bool _isProductBatchExpired(StockBatch batch) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final batchDate = DateTime(
      batch.expirationDate.year,
      batch.expirationDate.month,
      batch.expirationDate.day,
    );
    return !batchDate.isAfter(today);
  }

  @override
  Future<Either<Failure, List<Barang>>> getProducts() async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        return const Right([]);
      }

      // Ensure user is authenticated before querying
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return const Right([]);
      }

      final querySnapshot = await FirebaseDatabase.productsCollection().get();

      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()).toEntity())
          .toList();

      final updatedProducts = <Barang>[];

      for (final product in products) {
        final batches = product.batches ?? [];
        final expiredBatches = batches
            .where((b) => !b.isExpired && _isProductBatchExpired(b))
            .toList();

        if (expiredBatches.isEmpty) {
          updatedProducts.add(product);
          continue;
        }

        final reducedQuantity = expiredBatches.fold<double>(
            0.0, (sum, batch) => sum + batch.quantity);
        final updatedBatches = batches
            .map((b) => !b.isExpired && _isProductBatchExpired(b)
                ? StockBatch(
                    id: b.id,
                    quantity: b.quantity,
                    expirationDate: b.expirationDate,
                    invoiceId: b.invoiceId,
                    isExpired: true,
                    costPrice: b.costPrice,
                    costPerUnit: b.costPerUnit,
                  )
                : b)
            .toList();

        final updatedProduct = Barang(
          idBarang: product.idBarang,
          namaBarang: product.namaBarang,
          kodeBarang: product.kodeBarang,
          hargaSatuan: product.hargaSatuan,
          stokSaatIni: ((product.stokSaatIni ?? 0) - reducedQuantity)
              .clamp(0.0, double.infinity),
          measureType: product.measureType,
          batches: updatedBatches,
          latestCostPrice: product.latestCostPrice,
          latestCostPerUnit: product.latestCostPerUnit,
          diskon: product.diskon,
          diskonMulai: product.diskonMulai,
          diskonSelesai: product.diskonSelesai,
        );

        await updateProduct(updatedProduct);
        updatedProducts.add(updatedProduct);
      }

      return Right(updatedProducts);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Barang>> getProductByBarcode(String barcode) async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        return const Left(CacheFailure('Firebase not available'));
      }

      // Ensure user is authenticated before querying
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return const Left(CacheFailure('User not authenticated'));
      }

      final querySnapshot = await FirebaseDatabase.productsCollection()
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Left(CacheFailure('Product not found'));
      }

      final product =
          ProductModel.fromMap(querySnapshot.docs.first.data()).toEntity();
      return Right(product);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addProduct(Barang product) async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        return const Left(CacheFailure('Firebase not available'));
      }

      final model = ProductModel.fromEntity(product);
      await FirebaseDatabase.productsCollection()
          .doc(model.idBarang)
          .set(model.toMap());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProduct(Barang product) async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        return const Left(CacheFailure('Firebase not available'));
      }

      final model = ProductModel.fromEntity(product);
      await FirebaseDatabase.productsCollection()
          .doc(model.idBarang)
          .update(model.toMap());
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProduct(String id) async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        return const Left(CacheFailure('Firebase not available'));
      }

      await FirebaseDatabase.productsCollection().doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
