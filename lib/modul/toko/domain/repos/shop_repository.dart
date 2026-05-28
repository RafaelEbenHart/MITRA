import 'package:fpdart/fpdart.dart';
import '../../../../shared/galat/failures.dart';
import '../../domain/entities/shop.dart';

abstract class ShopRepository {
  Future<Either<Failure, DataToko>> getShop();
  Future<Either<Failure, void>> updateShop(DataToko shop);
}
