import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/product_usecases.dart';
import '../../../../infrastruktur/injeksi/service_locator.dart' as di;
import '../../../../shared/kontrak/usecase.dart';

enum ProductStatus { initial, loading, loaded, error, success }

class ProductState {
  final ProductStatus status;
  final List<Barang> products;
  final String? message;

  const ProductState({
    this.status = ProductStatus.initial,
    this.products = const [],
    this.message,
  });

  ProductState copyWith({
    ProductStatus? status,
    List<Barang>? products,
    String? message,
    bool clearMessage = false,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final GetProductsUseCase getProductsUseCase;
  final AddProductUseCase addProductUseCase;
  final UpdateProductUseCase updateProductUseCase;
  final DeleteProductUseCase deleteProductUseCase;

  ProductNotifier({
    required this.getProductsUseCase,
    required this.addProductUseCase,
    required this.updateProductUseCase,
    required this.deleteProductUseCase,
  }) : super(const ProductState());

  Future<bool> loadProducts([String? successMessage]) async {
    state = state.copyWith(status: ProductStatus.loading, clearMessage: true);
    final result = await getProductsUseCase(NoParams());
    return result.fold(
      (failure) {
        state = state.copyWith(
            status: ProductStatus.error, message: failure.message);
        return false;
      },
      (products) {
        state = state.copyWith(
          status: ProductStatus.loaded,
          products: products,
          message: successMessage,
        );
        return true;
      },
    );
  }

  Future<bool> addProduct(Barang product) async {
    state = state.copyWith(status: ProductStatus.loading, clearMessage: true);
    final result = await addProductUseCase(product);
    return result.fold((failure) {
      state =
          state.copyWith(status: ProductStatus.error, message: failure.message);
      return false;
    }, (_) async {
      await loadProducts('Produk berhasil ditambahkan');
      return true;
    });
  }

  Future<bool> updateProduct(Barang product) async {
    state = state.copyWith(status: ProductStatus.loading, clearMessage: true);
    final result = await updateProductUseCase(product);
    return result.fold((failure) {
      state =
          state.copyWith(status: ProductStatus.error, message: failure.message);
      return false;
    }, (_) async {
      await loadProducts('Produk berhasil diperbarui');
      return true;
    });
  }

  Future<bool> deleteProduct(String id) async {
    state = state.copyWith(status: ProductStatus.loading, clearMessage: true);
    final result = await deleteProductUseCase(id);
    return result.fold((failure) {
      state =
          state.copyWith(status: ProductStatus.error, message: failure.message);
      return false;
    }, (_) async {
      await loadProducts('Produk berhasil dihapus');
      return true;
    });
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(
    getProductsUseCase: di.sl<GetProductsUseCase>(),
    addProductUseCase: di.sl<AddProductUseCase>(),
    updateProductUseCase: di.sl<UpdateProductUseCase>(),
    deleteProductUseCase: di.sl<DeleteProductUseCase>(),
  ),
);


