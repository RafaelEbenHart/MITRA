import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mitra/modul/toko/tampilan/controllers/shop_provider.dart'
    as shop_provider;
import 'package:mitra/modul/akses/tampilan/controllers/auth_provider.dart'
    as auth_provider;

class OwnerDashboardPage extends ConsumerStatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  ConsumerState<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends ConsumerState<OwnerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor Pemilik',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF997950),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(auth_provider.authNotifierProvider.notifier).logout();
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    context.go('/login');
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Keluar'),
              ),
            ],
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu, color: Colors.black),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Builder(builder: (context) {
                final state = ref.watch(shop_provider.shopNotifierProvider);
                String shopName = '';
                if (state.status == shop_provider.ShopStatus.loaded &&
                    state.shop != null &&
                    state.shop!.namaToko.isNotEmpty) {
                  shopName = state.shop!.namaToko;
                }
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    Text(shopName.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Selamat Datang',
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                );
              }),
            ),

            // Main Features Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.people,
                    title: 'Kelola Karyawan',
                    subtitle: 'Kelola akun operasional',
                    onTap: () => context.push('/auth'),
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildExpandableFeatureCard(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'Informasi',
                    subtitle: 'Laporan persediaan dan penjualan',
                    color: Colors.blue,
                    children: [
                      _buildFeatureChild(
                        context: context,
                        title: 'Laporan Persediaan',
                        subtitle: 'Laporan persediaan otomatis akhir bulan',
                        onTap: () => context.push(
                            '/dashboard/owner/informasi/laporan-persediaan'),
                      ),
                      _buildFeatureChild(
                        context: context,
                        title: 'Laporan Penjualan',
                        subtitle:
                            'Laporan penjualan 1 bulan terakhir dengan ringkasan pendapatan',
                        onTap: () => context.push(
                            '/dashboard/owner/informasi/laporan-penjualan'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context: context,
                    icon: Icons.storefront,
                    title: 'Detail Toko',
                    subtitle: 'Ubah info & alamat bisnis',
                    onTap: () => context.push('/shop'),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChild({
    required BuildContext context,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ]
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          leading: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 32,
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: subtitle != null
              ? Text(subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13))
              : null,
          children: children,
        ),
      ),
    );
  }
}
