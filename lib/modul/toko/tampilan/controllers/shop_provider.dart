import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/shop.dart';
import '../../domain/usecases/shop_usecases.dart';
import '../../../../infrastruktur/injeksi/service_locator.dart' as di;
import '../../../../shared/kontrak/usecase.dart';

enum ShopStatus { initial, loading, loaded, error, success }

class ShopState {
  final ShopStatus status;
  final DataToko? shop;
  final String? message;

  const ShopState({
    this.status = ShopStatus.initial,
    this.shop,
    this.message,
  });

  ShopState copyWith({
    ShopStatus? status,
    DataToko? shop,
    String? message,
    bool clearMessage = false,
  }) {
    return ShopState(
      status: status ?? this.status,
      shop: shop ?? this.shop,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class ShopNotifier extends StateNotifier<ShopState> {
  final GetShopUseCase getShopUseCase;
  final UpdateShopUseCase updateShopUseCase;

  ShopNotifier({
    required this.getShopUseCase,
    required this.updateShopUseCase,
  }) : super(const ShopState());

  Future<bool> loadShop() async {
    state = state.copyWith(status: ShopStatus.loading, clearMessage: true);
    final result = await getShopUseCase(NoParams());
    return result.fold((failure) {
      state =
          state.copyWith(status: ShopStatus.error, message: failure.message);
      return false;
    }, (shop) {
      state = state.copyWith(status: ShopStatus.loaded, shop: shop);
      return true;
    });
  }

  Future<bool> updateShop(DataToko shop) async {
    state = state.copyWith(status: ShopStatus.loading, clearMessage: true);
    final result = await updateShopUseCase(shop);
    return result.fold((failure) {
      state =
          state.copyWith(status: ShopStatus.error, message: failure.message);
      return false;
    }, (_) async {
      await loadShop();
      state = state.copyWith(status: ShopStatus.success);
      return true;
    });
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}

final shopNotifierProvider = StateNotifierProvider<ShopNotifier, ShopState>(
  (ref) => ShopNotifier(
    getShopUseCase: di.sl<GetShopUseCase>(),
    updateShopUseCase: di.sl<UpdateShopUseCase>(),
  ),
);


