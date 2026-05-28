import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:mitra/modul/kasir/tampilan/controllers/billing_provider.dart';
import 'package:mitra/modul/inventori/tampilan/controllers/product_provider.dart'
    as product_provider;
import 'package:mitra/modul/inventori/domain/entities/product.dart';
import 'package:mitra/modul/akses/tampilan/controllers/auth_provider.dart'
    as auth_provider;
import 'package:mitra/modul/akses/domain/entities/user_entity.dart';
import 'package:mitra/shared/tema/app_theme.dart';
import 'package:mitra/shared/format/price_formatter.dart';
import 'package:mitra/shared/komponen/mitra_button.dart';
import 'package:mitra/modul/kasir/domain/entities/cart_item.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

final RouteObserver<ModalRoute<void>> homeRouteObserver =
    RouteObserver<ModalRoute<void>>();

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver
    implements RouteAware {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );

  final bool _isCameraOn = true;

  bool _isMenuOpen = false;
  OverlayEntry? _menuOverlay;
  final GlobalKey _menuButtonKey = GlobalKey();
  late AnimationController _menuAnimController;
  Animation<double>? _menuScaleAnim;
  Animation<double>? _menuFadeAnim;

  BillingNotifier get billingNotifier =>
      ref.read(billingNotifierProvider.notifier);

  final Map<String, DateTime> _lastScanTimes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _initializeMenuAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(auth_provider.authNotifierProvider);
      if (authState is auth_provider.AuthAuthenticated) {
        final billingState = ref.read(billingNotifierProvider);
        if (billingState.currentTab == null) {
          billingNotifier.initializeTabs();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    homeRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    homeRouteObserver.unsubscribe(this);
    _menuAnimController.dispose();
    _removeMenuOverlay();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isCameraOn && mounted) _scannerController.start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _scannerController.stop();
    }
  }

  @override
  void didPopNext() {
    if (_isCameraOn && mounted) {
      _scannerController.start();
    }
  }

  @override
  void didPush() {}

  @override
  void didPushNext() {}

  @override
  void didPop() {}

  void _initializeMenuAnimations() {
    _menuScaleAnim ??= CurvedAnimation(
      parent: _menuAnimController,
      curve: Curves.easeOutBack,
    );
    _menuFadeAnim ??= CurvedAnimation(
      parent: _menuAnimController,
      curve: Curves.easeOut,
    );
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    final authState = ref.read(auth_provider.authNotifierProvider);
    final isOwner = authState is auth_provider.AuthAuthenticated &&
        authState.user.peran == PeranPengguna.pemilik;

    final renderBox =
        _menuButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    setState(() => _isMenuOpen = true);
    _initializeMenuAnimations();

    _menuOverlay = OverlayEntry(
      builder: (context) => _CustomDropdownMenu(
        top: offset.dy + size.height + 8,
        right: MediaQuery.of(context).size.width - offset.dx - size.width,
        scaleAnimation: _menuScaleAnim!,
        fadeAnimation: _menuFadeAnim!,
        isOwner: isOwner,
        onClose: _closeMenu,
        onSettings: () async {
          _closeMenu();
          _scannerController.stop();
          await context.push('/settings');
          if (_isCameraOn && mounted) _scannerController.start();
        },
        onUsers: () {
          _closeMenu();
          _scannerController.stop();
          context.push('/auth');
        },
        onLogout: () {
          _closeMenu();
          _showLogoutConfirmDialog();
        },
      ),
    );

    Overlay.of(context).insert(_menuOverlay!);
    _menuAnimController.forward(from: 0);
  }

  void _closeMenu() {
    _menuAnimController.reverse().then((_) {
      _removeMenuOverlay();
      if (mounted) setState(() => _isMenuOpen = false);
    });
  }

  void _removeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black38,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar dari Akun?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Apakah kamu yakin ingin keluar? Kamu harus masuk kembali untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ref
                            .read(auth_provider.authNotifierProvider.notifier)
                            .logout();
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted && context.mounted) {
                            context.go('/login');
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    final now = DateTime.now();

    final billingState = ref.read(billingNotifierProvider);
    if (billingState.currentTab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buat pesanan terlebih dahulu sebelum memindai'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final rawValue = barcode.rawValue!;

        if (_lastScanTimes.containsKey(rawValue)) {
          final lastScan = _lastScanTimes[rawValue]!;
          if (now.difference(lastScan).inSeconds < 2) {
            continue;
          }
        }

        _lastScanTimes[rawValue] = now;

        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate();
        }

        if (mounted) {
          billingNotifier.scanBarcode(rawValue);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.55;
    final scannerHeight = screenHeight - panelHeight + 24;
    final billingNotifier = ref.read(billingNotifierProvider.notifier);
    final billingState = ref.watch(billingNotifierProvider);

    ref.listen<BillingState>(billingNotifierProvider, (previous, state) {
      if (previous?.error != state.error && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (previous?.printSuccess != true && state.printSuccess == true) {
        if (_isCameraOn && mounted) {
          Future.microtask(() => _scannerController.start());
        }
      }
    });

    ref.listen<auth_provider.AuthState>(auth_provider.authNotifierProvider,
        (previous, state) {
      if (previous is! auth_provider.AuthAuthenticated &&
          state is auth_provider.AuthAuthenticated) {
        if (billingState.currentTab == null) {
          billingNotifier.initializeTabs();
        }
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: scannerHeight,
            child: _buildScannerSection(),
          ),
          Positioned(
            top: scannerHeight - 24,
            left: 0,
            right: 0,
            height: panelHeight,
            child: _buildBottomPanel(billingState),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    final topPadding = MediaQuery.of(context).padding.top + 16;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── PERUBAHAN 2: hapus overlay border scanner (kotak putih & sudut coklat) ──
          if (_isCameraOn)
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            )
          else
            _buildCameraOffState(),
          // Border scanner dihapus sepenuhnya dari sini
          Positioned(
            top: topPadding,
            right: 16,
            child: GestureDetector(
              key: _menuButtonKey,
              onTap: _toggleMenu,
              child: _buildActionButton(
                child: AnimatedRotation(
                  turns: _isMenuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: const Icon(Icons.menu, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required Widget child, bool isActive = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.black45,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildCameraOffState() {
    return Container(
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child:
                const Icon(Icons.videocam_off, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kamera dimatikan',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Nyalakan kamera untuk mulai memindai barcode dan item secara otomatis.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(BillingState state) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTabBar(state),
            VerticalDivider(width: 1, thickness: 1, color: Colors.grey[200]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── PERUBAHAN 3: label "Tab Penjualan" sejajar dengan "Item Terpindai" ──
                  if (state.currentTab != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Item Terpindai',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${state.totalItems} item total',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'TOTAL HARGA',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1.2),
                              ),
                              Text(
                                formatIdr(state.totalAmount),
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Buat pesanan baru untuk mulai menambah produk',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: state.currentTab != null
                            ? () => _showAddProductDialog(context)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Tambah Produk',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: state.currentTab == null
                        ? _buildNoTabCart()
                        : (state.cartItems.isEmpty
                            ? _buildEmptyCart()
                            : ListView.separated(
                                padding: const EdgeInsets.only(
                                    left: 12, right: 12, top: 0, bottom: 12),
                                itemCount: state.cartItems.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final item = state.cartItems[index];
                                  return _buildCartItemCard(context, item);
                                },
                              )),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 50),
                    child: SizedBox(
                      width: double.infinity,
                      child: MitraButton(
                        onPressed: state.cartItems.isEmpty
                            ? null
                            : () async {
                                final invalidItems = state.cartItems.where(
                                  (item) =>
                                      item.barang.stokSaatIni == null ||
                                      item.barang.stokSaatIni! <= 0,
                                );
                                if (invalidItems.isNotEmpty) {
                                  final invalidItem = invalidItems.first;
                                  final productName =
                                      invalidItem.barang.namaBarang;
                                  final message =
                                      invalidItem.barang.stokSaatIni == null
                                          ? 'Stok $productName belum ada'
                                          : 'Stok $productName habis';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                                _scannerController.stop();
                                await context.push('/checkout');
                                if (_isCameraOn && mounted) {
                                  _scannerController.start();
                                }
                              },
                        label: 'Tinjau Pesanan',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BillingState state) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          // ── PERUBAHAN 1: label "Tab Penjualan" sejajar dengan "Item Terpindai" ──
          // Tinggi header disesuaikan agar baseline-nya sama (padding top 14 + 2 line text ≈ sama)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tab Penjualan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${state.tabs.length} tab aktif',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  ...List.generate(
                    state.tabs.length,
                    (index) => _buildTabButton(context, index, state),
                  ),
                  if (state.canCreateTab) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: billingNotifier.createTab,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add,
                                color: AppTheme.primaryColor, size: 18),
                            SizedBox(height: 2),
                            Text(
                              'Tambah',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, int index, BillingState state) {
    final tab = state.tabs[index];
    final isActive = state.currentTabIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => billingNotifier.switchTab(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.name,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tab.items.length} item',
                      style: TextStyle(
                        color: isActive ? Colors.white70 : Colors.grey[600],
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.tabs.length > 1)
                GestureDetector(
                  onTap: () {
                    if (tab.items.isNotEmpty) {
                      _showDeleteTabDialog(context, index);
                    } else {
                      billingNotifier.deleteTab(index);
                    }
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 14,
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteTabDialog(BuildContext context, int tabIndex) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pesanan?'),
        content: const Text('Pesanan ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              billingNotifier.deleteTab(tabIndex);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTabCart() {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.note_add_outlined,
                  size: 36, color: Colors.grey[300]),
            ),
            const SizedBox(height: 12),
            const Text('Tidak ada pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Buat pesanan baru dengan mengklik tombol "Tambah" untuk memulai menambahkan produk.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daftar kosong',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Belum ada Produk',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, ItemKeranjang item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.barang.namaBarang,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  formatIdr(item.barang.hargaSatuan),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _circularIconButton(
                    icon: Icons.remove,
                    onPressed: () {
                      if (item.jumlah > 1) {
                        billingNotifier.updateQuantity(
                            item.barang.idBarang, item.jumlah - 1);
                      } else {
                        billingNotifier
                            .removeProductFromCart(item.barang.idBarang);
                      }
                    }),
                SizedBox(
                  width: 26,
                  child: Text(
                    '${item.jumlah}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                _circularIconButton(
                    icon: Icons.add,
                    onPressed: () {
                      billingNotifier.updateQuantity(
                          item.barang.idBarang, item.jumlah + 1);
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circularIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, size: 20, color: Colors.grey[600]),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final queryController = TextEditingController();
    List<Barang> suggestions = [];
    bool hasSearched = false;

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        final availableHeight = MediaQuery.of(dialogContext).size.height -
            MediaQuery.of(dialogContext).viewInsets.bottom -
            140;

        return StatefulBuilder(
          builder: (dialogContext, setState) => AlertDialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            title: const Text('Tambah Produk'),
            contentPadding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 20,
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: availableHeight.clamp(260.0, 380.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      labelText: 'Nama atau Kode Produk',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      final query = value.trim().toLowerCase();
                      final matches = ref
                          .read(product_provider.productNotifierProvider)
                          .products
                          .where((p) {
                        final lowerName = p.namaBarang.toLowerCase();
                        final lowerBarcode = p.kodeBarang.toLowerCase();
                        return query.isNotEmpty &&
                            (lowerName.contains(query) ||
                                lowerBarcode.contains(query));
                      }).toList();
                      setState(() {
                        hasSearched = query.isNotEmpty;
                        suggestions = matches;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (hasSearched && suggestions.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Tidak ada produk yang cocok. Coba kata kunci lain.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (suggestions.isNotEmpty) ...[
                    const Text(
                      'Hasil Pencarian',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = suggestions[index];
                          return ListTile(
                            title: Text(product.namaBarang),
                            subtitle: Text(product.kodeBarang),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                billingNotifier.addProductToCart(product);
                                Navigator.of(dialogContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${product.namaBarang} berhasil ditambahkan ke keranjang'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomDropdownMenu extends StatelessWidget {
  final double top;
  final double right;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;
  final bool isOwner;
  final VoidCallback onClose;
  final VoidCallback onSettings;
  final VoidCallback onUsers;
  final VoidCallback onLogout;

  const _CustomDropdownMenu({
    required this.top,
    required this.right,
    required this.scaleAnimation,
    required this.fadeAnimation,
    required this.isOwner,
    required this.onClose,
    required this.onSettings,
    required this.onUsers,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: top,
          right: right,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              alignment: Alignment.topRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Pengaturan',
                          iconColor: Colors.blueGrey,
                          onTap: onSettings,
                        ),
                        if (isOwner) ...[
                          _MenuDivider(),
                          _MenuItem(
                            icon: Icons.people_outline,
                            label: 'Manajemen Pengguna',
                            iconColor: Colors.indigo,
                            onTap: onUsers,
                          ),
                        ],
                        _MenuDivider(),
                        _MenuItem(
                          icon: Icons.logout,
                          label: 'Keluar',
                          iconColor: Colors.red,
                          labelColor: Colors.red,
                          onTap: onLogout,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _pressed ? Colors.grey.shade100 : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: widget.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.labelColor ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }
}
