import 'package:fpdart/fpdart.dart';
import '../../../../shared/galat/failures.dart';
import '../../../../shared/kontrak/usecase.dart';
import '../entities/product.dart';
import '../repos/product_repository.dart';

class GetProductsUseCase implements UseCase<List<Barang>, NoParams> {
  final ProductRepository repository;

  GetProductsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Barang>>> call(NoParams params) {
    return repository.getProducts();
  }
}

class AddProductUseCase implements UseCase<void, Barang> {
  final ProductRepository repository;

  AddProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Barang params) {
    return repository.addProduct(params);
  }
}

class UpdateProductUseCase implements UseCase<void, Barang> {
  final ProductRepository repository;

  UpdateProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Barang params) {
    return repository.updateProduct(params);
  }
}

class DeleteProductUseCase implements UseCase<void, String> {
  final ProductRepository repository;

  DeleteProductUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteProduct(params);
  }
}

class GetProductByBarcodeUseCase implements UseCase<Barang, String> {
  final ProductRepository repository;

  GetProductByBarcodeUseCase(this.repository);

  @override
  Future<Either<Failure, Barang>> call(String params) {
    return repository.getProductByBarcode(params);
  }
}
