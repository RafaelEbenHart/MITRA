import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user_entity.dart';
import '../controllers/auth_provider.dart' as auth_provider;

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    ref.read(auth_provider.authNotifierProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(auth_provider.authNotifierProvider.notifier)
          .getOperationalAccounts();
    });
  }

  void _showConfirmationDialog(AkunPengguna user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan Akun'),
        content: Text(
            'Apakah Anda yakin ingin menonaktifkan akun ${user.namaLengkap}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(auth_provider.authNotifierProvider.notifier)
                  .deactivateUser(user.idPengguna);
              Navigator.pop(context);
            },
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
  }

  void _showActivationDialog(AkunPengguna user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Akun'),
        content: Text(
            'Apakah Anda yakin ingin mengaktifkan kembali akun ${user.namaLengkap}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(auth_provider.authNotifierProvider.notifier)
                  .activateUser(user.idPengguna);
              Navigator.pop(context);
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auth_provider.authNotifierProvider);

    ref.listen<auth_provider.AuthState>(
      auth_provider.authNotifierProvider,
      (previous, state) {
        if (state is auth_provider.OperationalAccountsLoaded &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        } else if (state is auth_provider.AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Karyawan'),
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          if (state is auth_provider.AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is auth_provider.OperationalAccountsLoaded) {
            if (state.accounts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada akun operasional',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Buat akun karyawan pertama kali',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.accounts.length,
              itemBuilder: (context, index) {
                final user = state.accounts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(user.namaLengkap[0].toUpperCase()),
                    ),
                    title: Text(user.namaLengkap),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            user.isActive ? 'Aktif' : 'Nonaktif',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: user.isActive
                              ? Colors.green[100]
                              : Colors.red[100],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        if (user.isActive)
                          PopupMenuItem(
                            child: const Text('Nonaktifkan'),
                            onTap: () => _showConfirmationDialog(user),
                          ),
                        if (!user.isActive)
                          PopupMenuItem(
                            child: const Text('Aktifkan'),
                            onTap: () => _showActivationDialog(user),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (state is auth_provider.AuthError) {
            return Center(
              child: Text('Error: ${state.message}'),
            );
          }

          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/auth/create-operational'),
        tooltip: 'Buat Akun karyawan',
        child: const Icon(Icons.add),
      ),
    );
  }
}

