import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/product_provider.dart';
import '../../domain/entities/product.dart';
import '../../../../shared/tema/app_theme.dart';
import '../../../../shared/format/price_formatter.dart';

class _FilterOption {
  final String value;
  final String label;
  final IconData icon;

  const _FilterOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

const _filterOptions = [
  _FilterOption(value: 'none', label: 'Semua Produk', icon: Icons.apps_rounded),
  _FilterOption(
      value: 'expiry',
      label: 'Kedaluwarsa Terdekat',
      icon: Icons.event_busy_rounded),
];

class _FilterDropdown extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({required this.selectedValue, required this.onChanged});

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _closeDropdown();
    _animController.dispose();
    super.dispose();
  }

  bool get _isOpen => _overlayEntry != null;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: offset.dy + size.height + 6,
            left: offset.dx,
            width: size.width,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _filterOptions.map((option) {
                        final isSelected = option.value == widget.selectedValue;
                        return InkWell(
                          onTap: () {
                            widget.onChanged(option.value);
                            _closeDropdown();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                      .withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  option.icon,
                                  size: 18,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey[500],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_rounded,
                                      size: 16, color: AppTheme.primaryColor),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() {});
  }

  Future<void> _closeDropdown() async {
    if (_overlayEntry == null) return;
    await _animController.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final current = _filterOptions.firstWhere(
      (o) => o.value == widget.selectedValue,
      orElse: () => _filterOptions.first,
    );

    return GestureDetector(
      key: _key,
      onTap: _toggleDropdown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isOpen
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isOpen
                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(current.icon,
                size: 16,
                color: _isOpen ? AppTheme.primaryColor : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              current.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isOpen ? AppTheme.primaryColor : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _isOpen ? AppTheme.primaryColor : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key});

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterMode = 'none';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(productNotifierProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _scanQR(List<Barang> products) async {
    final barcode = await context.push<String>('/scanner');
    if (barcode != null && barcode.isNotEmpty) {
      final matchedProduct =
          products.where((p) => p.kodeBarang == barcode).firstOrNull;
      if (matchedProduct != null) {
        _searchController.text = matchedProduct.namaBarang;
      } else {
        _searchController.text = barcode;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey[100]!;
    final state = ref.watch(productNotifierProvider);

    ref.listen<ProductState>(productNotifierProvider, (previous, next) {
      if (next.message != null && next.message!.isNotEmpty) {
        final isError = next.status == ProductStatus.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message!),
              backgroundColor: isError ? Colors.red : Colors.green,
            ),
          );
          ref.read(productNotifierProvider.notifier).clearMessage();
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Manajemen Produk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Cari nama atau kode produk',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner,
                            color: AppTheme.primaryColor),
                        onPressed: () => _scanQR(state.products),
                        padding: const EdgeInsets.all(15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterDropdown(
                      selectedValue: _filterMode,
                      onChanged: (val) => setState(() => _filterMode = val),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Ketuk ikon untuk membuka pemindai kamera',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4C669A))),
              ],
            ),
          ),
          Expanded(
            child: Builder(builder: (context) {
              if (state.status == ProductStatus.loading &&
                  state.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.products.isEmpty) {
                if (state.status == ProductStatus.error) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const Center(
                    child: Text('Belum ada produk. Tambahkan sekarang!'));
              }

              final filteredProducts = state.products
                  .where((product) =>
                      product.namaBarang.toLowerCase().contains(_searchQuery) ||
                      product.kodeBarang.toLowerCase().contains(_searchQuery))
                  .toList();

              if (_filterMode == 'expiry') {
                DateTime? earliestExpiration(Barang p) {
                  if (p.batches == null || p.batches!.isEmpty) return null;
                  final active = p.batches!
                      .where((b) => !b.isExpired)
                      .map((b) => b.expirationDate)
                      .toList();
                  if (active.isEmpty) return null;
                  active.sort();
                  return active.first;
                }

                filteredProducts.sort((a, b) {
                  final aDate = earliestExpiration(a);
                  final bDate = earliestExpiration(b);
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return aDate.compareTo(bDate);
                });
              }

              if (filteredProducts.isEmpty) {
                return const Center(
                    child: Text(
                        'Tidak ada produk yang cocok dengan pencarian Anda.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 100),
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  final measureLabel =
                      product.measureType == 'weight' ? 'kg' : 'pcs';
                  final hasQuantity = product.stokSaatIni != null;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.namaBarang,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatIdr(product.hargaSatuan),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600]),
                                  ),
                                  if (hasQuantity) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.green[200]!),
                                      ),
                                      child: Text(
                                        'Jumlah: ${product.stokSaatIni! % 1 == 0 ? product.stokSaatIni!.toInt() : product.stokSaatIni} $measureLabel',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (product.batches != null) ...[
                                      const SizedBox(height: 8),
                                      Builder(builder: (context) {
                                        final now = DateTime.now();
                                        final today = DateTime(
                                            now.year, now.month, now.day);
                                        final activeBatches =
                                            product.batches!.where((b) {
                                          final batchDate = DateTime(
                                            b.expirationDate.year,
                                            b.expirationDate.month,
                                            b.expirationDate.day,
                                          );
                                          return !b.isExpired &&
                                              batchDate.isAfter(today);
                                        }).toList();
                                        if (activeBatches.isEmpty)
                                          return const SizedBox();
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            dividerColor: Colors.transparent,
                                            dividerTheme:
                                                const DividerThemeData(
                                                    color: Colors.transparent),
                                          ),
                                          child: ExpansionTile(
                                            title: const Text('Detail'),
                                            children: activeBatches.map((b) {
                                              final daysLeft = b.expirationDate
                                                  .difference(DateTime.now())
                                                  .inDays;
                                              return ListTile(
                                                dense: true,
                                                title: Text(
                                                    '${b.quantity % 1 == 0 ? b.quantity.toInt() : b.quantity} $measureLabel'),
                                                subtitle: Text(
                                                    'Kadaluwarsa dalam $daysLeft hari'),
                                              );
                                            }).toList(),
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        color: AppTheme.primaryColor, size: 20),
                                    constraints: const BoxConstraints(),
                                    padding: const EdgeInsets.all(8),
                                    onPressed: () {
                                      context.push(
                                          '/products/edit/${product.idBarang}',
                                          extra: product);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
