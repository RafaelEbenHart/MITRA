import 'package:fpdart/fpdart.dart';
import '../../../../shared/galat/failures.dart';
import '../../domain/entities/product.dart';

abstract class ProductRepository {
  Future<Either<Failure, List<Barang>>> getProducts();
  Future<Either<Failure, Barang>> getProductByBarcode(String barcode);
  Future<Either<Failure, void>> addProduct(Barang product);
  Future<Either<Failure, void>> updateProduct(Barang product);
  Future<Either<Failure, void>> deleteProduct(String id);
}
