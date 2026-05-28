import 'package:fpdart/fpdart.dart';
import '../../../../shared/galat/failures.dart';
import '../../../../shared/kontrak/usecase.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repos/shop_repository.dart';

class GetShopUseCase implements UseCase<DataToko, NoParams> {
  final ShopRepository repository;

  GetShopUseCase(this.repository);

  @override
  Future<Either<Failure, DataToko>> call(NoParams params) {
    return repository.getShop();
  }
}

class UpdateShopUseCase implements UseCase<void, DataToko> {
  final ShopRepository repository;

  UpdateShopUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DataToko params) {
    return repository.updateShop(params);
  }
}
