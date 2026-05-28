import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../../../infrastruktur/injeksi/service_locator.dart' as di;

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final AkunPengguna user;

  const AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});
}

class OperationalAccountsLoaded extends AuthState {
  final List<AkunPengguna> accounts;
  final String? message;

  const OperationalAccountsLoaded({required this.accounts, this.message});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required this.loginWithEmailUseCase,
    required this.registerOwnerUseCase,
    required this.createOperationalAccountUseCase,
    required this.getCurrentUserUseCase,
    required this.logoutUseCase,
    required this.getAllOperationalAccountsUseCase,
    required this.deactivateUserUseCase,
    required this.activateUserUseCase,
  }) : super(const AuthInitial());

  final LoginWithEmailUseCase loginWithEmailUseCase;
  final RegisterOwnerUseCase registerOwnerUseCase;
  final CreateOperationalAccountUseCase createOperationalAccountUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final LogoutUseCase logoutUseCase;
  final GetAllOperationalAccountsUseCase getAllOperationalAccountsUseCase;
  final DeactivateUserUseCase deactivateUserUseCase;
  final ActivateUserUseCase activateUserUseCase;

  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await loginWithEmailUseCase(email, password);
      state = AuthAuthenticated(user: user);
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  Future<void> registerOwner(
    String email,
    String password,
    String fullName,
  ) async {
    state = const AuthLoading();
    try {
      final user = await registerOwnerUseCase(email, password, fullName);
      state = AuthAuthenticated(user: user);
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  Future<void> createOperationalAccount(
    String email,
    String password,
    String fullName,
  ) async {
    state = const AuthLoading();
    try {
      await createOperationalAccountUseCase(email, password, fullName);
      final accounts = await getAllOperationalAccountsUseCase();
      state = OperationalAccountsLoaded(
        accounts: accounts,
        message: 'Akun operasional berhasil dibuat',
      );
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  Future<void> checkCurrentUser() async {
    state = const AuthLoading();
    try {
      final user = await getCurrentUserUseCase();
      state = AuthAuthenticated(user: user);
    } catch (e) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> logout() async {
    state = const AuthLoading();
    try {
      await logoutUseCase();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  Future<void> getOperationalAccounts() async {
    state = const AuthLoading();
    try {
      final accounts = await getAllOperationalAccountsUseCase();
      state = OperationalAccountsLoaded(accounts: accounts);
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  Future<void> deactivateUser(String userId) async {
    state = const AuthLoading();
    try {
      await deactivateUserUseCase(userId);
      final accounts = await getAllOperationalAccountsUseCase();
      state = OperationalAccountsLoaded(
        accounts: accounts,
        message: 'Akun berhasil dinonaktifkan',
      );
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  Future<void> activateUser(String userId) async {
    state = const AuthLoading();
    try {
      await activateUserUseCase(userId);
      final accounts = await getAllOperationalAccountsUseCase();
      state = OperationalAccountsLoaded(
        accounts: accounts,
        message: 'Akun berhasil diaktifkan',
      );
    } catch (e) {
      state = AuthError(message: _extractErrorMessage(e.toString()));
    }
  }

  String _extractErrorMessage(String errorString) {
    if (errorString.startsWith('Exception: ')) {
      return errorString.substring('Exception: '.length);
    }
    return errorString;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    loginWithEmailUseCase: di.sl<LoginWithEmailUseCase>(),
    registerOwnerUseCase: di.sl<RegisterOwnerUseCase>(),
    createOperationalAccountUseCase: di.sl<CreateOperationalAccountUseCase>(),
    getCurrentUserUseCase: di.sl<GetCurrentUserUseCase>(),
    logoutUseCase: di.sl<LogoutUseCase>(),
    getAllOperationalAccountsUseCase: di.sl<GetAllOperationalAccountsUseCase>(),
    deactivateUserUseCase: di.sl<DeactivateUserUseCase>(),
    activateUserUseCase: di.sl<ActivateUserUseCase>(),
  ),
);


