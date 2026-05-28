import 'package:go_router/go_router.dart';
import 'package:mitra/modul/akses/tampilan/splash_page.dart';
import 'package:mitra/modul/kasir/tampilan/home_page.dart';
import 'package:mitra/modul/kasir/tampilan/owner_dashboard_page.dart';
import 'package:mitra/modul/kasir/tampilan/informasi_page.dart';
import 'package:mitra/modul/inventori/tampilan/inventory_report_page.dart'
    as inventory_report_page;
import 'package:mitra/modul/inventori/tampilan/pages/product_list_page.dart';
import 'package:mitra/modul/inventori/tampilan/pages/add_product_page.dart';
import 'package:mitra/modul/inventori/tampilan/pages/edit_product_page.dart';
import 'package:mitra/modul/toko/tampilan/pages/shop_details_page.dart';
import 'package:mitra/modul/pengaturan/tampilan/pages/settings_page.dart';
import 'package:mitra/modul/kasir/tampilan/checkout_page.dart';
import 'package:mitra/modul/inventori/tampilan/add_stock_page.dart';
import 'package:mitra/modul/inventori/tampilan/outgoing_goods_page.dart';
import 'package:mitra/modul/inventori/tampilan/sales_report_page.dart';
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/akses/tampilan/pages/login_page.dart';
import 'package:mitra/modul/akses/tampilan/pages/create_operational_account_page.dart';
import 'package:mitra/modul/akses/tampilan/pages/user_management_page.dart';
import 'package:mitra/modul/akses/domain/entities/user_entity.dart';
import 'package:mitra/shared/format/route_guard.dart';

final router = GoRouter(
  observers: [homeRouteObserver],
  initialLocation: '/splash',
  redirect: (context, state) async {
    final isLoggedIn = await RouteGuard.isAuthenticated();
    final isLoginRoute = state.matchedLocation == '/login';
    final isAuthRoute = state.matchedLocation.startsWith('/auth');
    final isSplashRoute = state.matchedLocation == '/splash';

    // If not logged in, go to login (except for auth and splash routes)
    if (!isLoggedIn && !isLoginRoute && !isAuthRoute && !isSplashRoute) {
      return '/login';
    }

    // Allow login page to be accessed when not logged in
    if (!isLoggedIn && isLoginRoute) {
      return null;
    }

    // If logged in and trying to access login page, redirect based on role
    if (isLoggedIn && isLoginRoute) {
      final currentUser = await RouteGuard.getCurrentUser();
      if (currentUser?.peran == PeranPengguna.pemilik) {
        return '/dashboard/owner';
      }
      return '/';
    }

    // Role-based access control for logged in users
    if (isLoggedIn) {
      final currentUser = await RouteGuard.getCurrentUser();
      final isOperational = currentUser?.peran == PeranPengguna.karyawan;
      final isOwner = currentUser?.peran == PeranPengguna.pemilik;
      if (isOperational &&
          (state.matchedLocation == '/dashboard/owner' ||
              state.matchedLocation.startsWith('/auth/create-operational'))) {
        return '/';
      }

      // Operational users blocked from user management
      if (isOperational && state.matchedLocation == '/auth') {
        return '/';
      }

      // Owner blocked from operational management features
      if (isOwner &&
          (state.matchedLocation == '/' ||
              state.matchedLocation == '/checkout' ||
              state.matchedLocation.startsWith('/checkout') ||
              state.matchedLocation == '/settings' ||
              state.matchedLocation == '/products' ||
              state.matchedLocation.startsWith('/products') ||
              state.matchedLocation == '/inventory/add-stock' ||
              state.matchedLocation.startsWith('/inventory'))) {
        return '/dashboard/owner';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final isFirstUser = state.extra as bool? ?? false;
        return LoginPage(isFirstUser: isFirstUser);
      },
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const UserManagementPage(),
      routes: [
        GoRoute(
          path: 'create-operational',
          builder: (context, state) => const CreateOperationalAccountPage(),
        ),
      ],
    ),

    // Main Routes
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/dashboard/owner',
      builder: (context, state) => const OwnerDashboardPage(),
      routes: [
        GoRoute(
          path: 'informasi',
          builder: (context, state) => const InformasiPage(),
        ),
        GoRoute(
          path: 'informasi/laporan-persediaan',
          builder: (context, state) =>
              inventory_report_page.InventoryReportPage(),
        ),
        GoRoute(
          path: 'informasi/laporan-penjualan',
          builder: (context, state) => const SalesReportPage(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductListPage(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddProductPage(),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final product = state.extra as Barang?;
            if (product == null) {
              // If we land here without extra (e.g. deep link), go back to products for now.
              return const ProductListPage();
            }
            return EditProductPage(product: product);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopDetailsPage(),
    ),
    GoRoute(
      path: '/inventory/add-stock',
      builder: (context, state) {
        final product = state.extra as Barang?;
        return AddStockPage(initialProduct: product);
      },
    ),
    GoRoute(
      path: '/inventory/outgoing',
      builder: (context, state) => const OutgoingGoodsPage(),
    ),
  ],
);
