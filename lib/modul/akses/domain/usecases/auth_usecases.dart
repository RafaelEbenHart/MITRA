import '../entities/user_entity.dart';
import '../repos/auth_repository.dart';

class LoginWithEmailUseCase {
  final AuthRepository repository;

  LoginWithEmailUseCase(this.repository);

  Future<AkunPengguna> call(String email, String password) async {
    return await repository.loginWithEmail(email, password);
  }
}

class RegisterOwnerUseCase {
  final AuthRepository repository;

  RegisterOwnerUseCase(this.repository);

  Future<AkunPengguna> call(
    String email,
    String password,
    String fullName,
  ) async {
    return await repository.registerOwner(email, password, fullName);
  }
}

class CreateOperationalAccountUseCase {
  final AuthRepository repository;

  CreateOperationalAccountUseCase(this.repository);

  Future<AkunPengguna> call(
    String email,
    String password,
    String fullName,
  ) async {
    return await repository.createOperationalAccount(
      email,
      password,
      fullName,
    );
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<AkunPengguna> call() async {
    return await repository.getCurrentUser();
  }
}

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> call() async {
    await repository.logout();
  }
}

class GetAllOperationalAccountsUseCase {
  final AuthRepository repository;

  GetAllOperationalAccountsUseCase(this.repository);

  Future<List<AkunPengguna>> call() async {
    return await repository.getAllOperationalAccounts();
  }
}

class DeactivateUserUseCase {
  final AuthRepository repository;

  DeactivateUserUseCase(this.repository);

  Future<void> call(String userId) async {
    await repository.deactivateUser(userId);
  }
}

class ActivateUserUseCase {
  final AuthRepository repository;

  ActivateUserUseCase(this.repository);

  Future<void> call(String userId) async {
    await repository.activateUser(userId);
  }
}
