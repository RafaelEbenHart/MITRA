import 'package:fpdart/fpdart.dart';
import 'package:mitra/shared/galat/failures.dart';

abstract class UseCase<Result, Params> {
  Future<Either<Failure, Result>> call(Params params);
}

class NoParams {}
