import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_provider.dart' as auth_provider;

class CreateOperationalAccountPage extends ConsumerStatefulWidget {
  const CreateOperationalAccountPage({super.key});

  @override
  ConsumerState<CreateOperationalAccountPage> createState() =>
      _CreateOperationalAccountPageState();
}

class _CreateOperationalAccountPageState
    extends ConsumerState<CreateOperationalAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty) {
      _showSnackBar('Semua field harus diisi', Colors.red);
      return;
    }

    ref
        .read(auth_provider.authNotifierProvider.notifier)
        .createOperationalAccount(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text.trim(),
        );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auth_provider.authNotifierProvider);
    final isLoading = state is auth_provider.AuthLoading;

    ref.listen<auth_provider.AuthState>(
      auth_provider.authNotifierProvider,
      (previous, state) {
        if (state is auth_provider.OperationalAccountsLoaded &&
            state.message != null) {
          _showSnackBar(state.message!, Colors.green);
          _emailController.clear();
          _passwordController.clear();
          _fullNameController.clear();
          ref
              .read(auth_provider.authNotifierProvider.notifier)
              .getOperationalAccounts();
        } else if (state is auth_provider.AuthError) {
          _showSnackBar(state.message, Colors.red);
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Akun Karyawan'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Buat Akun Karyawan Baru',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Isi form di bawah untuk membuat akun karyawan baru',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _isPasswordVisible = !_isPasswordVisible);
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _handleCreateAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Buat Akun'),
            ),
          ],
        ),
      ),
    );
  }
}
