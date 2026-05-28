import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mitra/shared/tema/app_theme.dart';
import 'package:mitra/modul/akses/tampilan/controllers/auth_provider.dart'
    as auth_provider;
import 'package:mitra/modul/akses/domain/entities/user_entity.dart';
import 'package:mitra/modul/pengaturan/tampilan/controllers/printer_provider.dart';
import 'package:mitra/modul/pengaturan/tampilan/controllers/printer_state.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Re-initialize printer state whenever settings page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(printerNotifierProvider.notifier).initPrinter();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PrinterState>(printerNotifierProvider, (previous, state) {
      if (previous?.errorMessage != state.errorMessage &&
          state.errorMessage != null) {
        final isSuccess = state.errorMessage == 'Printer telah terhubung';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ));
      }
    });

    final state = ref.watch(printerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Management Section
            _buildSectionHeader('Manajemen'),
            _buildListGroup(
              children: [
                _buildExpandableListItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Kelola Produk',
                  subtitle: 'Akses produk, tambah stok, dan tambah produk',
                  children: [
                    _buildListItem(
                      icon: Icons.qr_code_scanner,
                      title: 'Produk',
                      subtitle: 'Kelola stok dan barcode',
                      onTap: () => context.push('/products'),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.inventory_2_outlined,
                      title: 'Tambah Stok',
                      subtitle: 'Catat stok masuk dengan faktur',
                      onTap: () => context.push('/inventory/add-stock'),
                    ),
                    _buildDivider(),
                    _buildListItem(
                      icon: Icons.add_box_outlined,
                      title: 'Tambah Produk',
                      subtitle: 'Buat produk baru dengan kode yang dihasilkan',
                      onTap: () => context.push('/products/add'),
                    ),
                  ],
                ),
                _buildDivider(),
                _buildListItem(
                  icon: Icons.outbox,
                  title: 'Produk Keluar',
                  subtitle: 'Daftar produk yang kadaluwarsa',
                  onTap: () => context.push('/inventory/outgoing'),
                ),
                _buildDivider(),
                Builder(builder: (context) {
                  final authState =
                      ref.watch(auth_provider.authNotifierProvider);
                  if (authState is auth_provider.AuthAuthenticated &&
                      authState.user.peran == PeranPengguna.pemilik) {
                    return _buildListItem(
                      icon: Icons.storefront,
                      title: 'Detail Toko',
                      subtitle: 'Ubah info & alamat bisnis',
                      onTap: () => context.push('/shop'),
                    );
                  }

                  return const SizedBox.shrink();
                }),
              ],
            ),

            const SizedBox(height: 24),

            // Hardware Section
            _buildSectionHeader('Perangkat'),
            _buildListGroup(
              children: [
                _buildListItem(
                  icon: Icons.print,
                  title: 'Perangkat Cetak',
                  subtitleWidget: state.connectedMac != null &&
                          state.errorMessage !=
                              'Tidak dapat terhubung ke perangkat manapun.' &&
                          state.errorMessage !=
                              'Tidak dapat menemukan Perangkat'
                      ? Row(
                          children: [
                            Text(
                              state.connectedName ?? 'Printer terhubung',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.teal[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal[200]!)),
                              child: Text(
                                'TERHUBUNG',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700]),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Tidak ada printer terhubung',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                  trailingWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.status == PrinterStatus.scanning ||
                          state.status == PrinterStatus.connecting)
                        const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        TextButton(
                          onPressed: () => ref
                              .read(printerNotifierProvider.notifier)
                              .refreshPrinter(),
                          child: const Text('Hubungkan'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildListGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: Colors.grey[50], indent: 64);
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? trailingWidget,
    IconData? trailingIcon = Icons.chevron_right,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  if (subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    subtitleWidget,
                  ]
                ],
              ),
            ),
            if (trailingWidget != null)
              trailingWidget
            else if (trailingIcon != null)
              Icon(trailingIcon, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]))
            : null,
        children: children,
      ),
    );
  }
}
