import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/routes/app_routes.dart';
import 'infrastruktur/penyimpanan/firebase_database.dart';
import 'infrastruktur/injeksi/service_locator.dart' as di;
import 'shared/tema/app_theme.dart';
import 'modul/akses/tampilan/controllers/auth_provider.dart' as auth_provider;
import 'modul/toko/tampilan/controllers/shop_provider.dart' as shop_provider;
import 'modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await FirebaseDatabase.init();
  await di.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // ← Pastikan auth siap lebih dulu sebelum load data lain
      await ref
          .read(auth_provider.authNotifierProvider.notifier)
          .checkCurrentUser();

      // Sekarang load shop dan products (user sudah authenticated)
      ref.read(shop_provider.shopNotifierProvider.notifier).loadShop();
      ref
          .read(product_provider.productNotifierProvider.notifier)
          .loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MITRA',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
