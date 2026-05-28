import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modul/inventori/data/repos/product_repository_impl.dart';
import '../../modul/inventori/domain/repos/product_repository.dart';
import '../../modul/inventori/domain/usecases/product_usecases.dart';
import '../../modul/toko/data/repos/shop_repository_impl.dart';
import '../../modul/toko/domain/repos/shop_repository.dart';
import '../../modul/toko/domain/usecases/shop_usecases.dart';
import '../../modul/pengaturan/data/repos/printer_repository_impl.dart';
import '../../modul/pengaturan/domain/repos/printer_repository.dart';
import '../../modul/inventori/data/repos/inventory_repository_impl.dart';
import '../../modul/inventori/domain/repos/inventory_repository.dart';
import '../../modul/inventori/domain/usecases/inventory_usecases.dart';
import '../../modul/akses/data/datasources/auth_remote_data_source.dart';
import '../../modul/akses/data/repos/auth_repository_impl.dart';
import '../../modul/akses/domain/repos/auth_repository.dart';
import '../../modul/akses/domain/usecases/auth_usecases.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Product use cases
  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByBarcodeUseCase(sl()));

  // Inventory Use Cases
  sl.registerLazySingleton(() => CreateInvoiceUseCase(sl()));
  sl.registerLazySingleton(() => CreateReceiptUseCase(sl()));
  sl.registerLazySingleton(() => GetInvoiceHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetSalesReceiptsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductQuantityUseCase(sl()));
  sl.registerLazySingleton(() => GetProductWithQuantityUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(),
  );

  // Inventory Repository
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(),
  );

  // Features - Shop
  // Use cases
  sl.registerLazySingleton(() => GetShopUseCase(sl()));
  sl.registerLazySingleton(() => UpdateShopUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(),
  );

  // Features - Settings / Printer
  sl.registerLazySingleton<PrinterRepository>(
    () => PrinterRepositoryImpl(),
  );

  // Features - Auth
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => RegisterOwnerUseCase(sl()));
  sl.registerLazySingleton(() => CreateOperationalAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetAllOperationalAccountsUseCase(sl()));
  sl.registerLazySingleton(() => DeactivateUserUseCase(sl()));
  sl.registerLazySingleton(() => ActivateUserUseCase(sl()));
}
