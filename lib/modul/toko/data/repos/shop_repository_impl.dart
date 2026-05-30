import 'package:fpdart/fpdart.dart';
import '../../../../infrastruktur/penyimpanan/firebase_database.dart';
import '../../../../shared/galat/failures.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repos/shop_repository.dart';
import '../models/shop_model.dart';

class ShopRepositoryImpl implements ShopRepository {
  static const String shopDoc = 'shop_details';

  @override
  Future<Either<Failure, DataToko>> getShop() async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        // Return default shop if Firebase not available
        return const Right(DataToko(
          namaToko: 'Dinesh Shop',
          alamatBaris1: 'Samrajpet, Mecheri',
          alamatBaris2: 'Salem - 636453',
          nomorTelepon: '+917010674588',
          pesanStruk: 'Thank you, Visit again!!!',
        ));
      }

      final docSnapshot =
          await FirebaseDatabase.shopsCollection().doc(shopDoc).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final shop = ShopModel.fromMap(docSnapshot.data()!).toEntity();
        return Right(shop);
      }

      return const Right(DataToko(
        namaToko: 'Dinesh Shop',
        alamatBaris1: 'Samrajpet, Mecheri',
        alamatBaris2: 'Salem - 636453',
        nomorTelepon: '+917010674588',
        pesanStruk: 'Thank you, Visit again!!!',
        taxPercentage: 11.0,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(DataToko shop) async {
    try {
      if (!FirebaseDatabase.isFirebaseAvailable) {
        return const Left(CacheFailure('Firebase not available'));
      }

      final model = ShopModel.fromEntity(shop);
      await FirebaseDatabase.shopsCollection().doc(shopDoc).set({
        'name': model.namaToko,
        'addressLine1': model.alamatBaris1,
        'addressLine2': model.alamatBaris2,
        'phoneNumber': model.nomorTelepon,
        'footerText': model.pesanStruk,
        'taxPercentage': model.taxPercentage,
      });
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
