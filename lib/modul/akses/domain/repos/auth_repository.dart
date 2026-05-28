import '../../domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<AkunPengguna> loginWithEmail(String email, String password);
  Future<AkunPengguna> registerOwner(
      String email, String password, String fullName);
  Future<AkunPengguna> createOperationalAccount(
    String email,
    String password,
    String fullName,
  );
  Future<AkunPengguna> getCurrentUser();
  Future<void> logout();
  Future<List<AkunPengguna>> getAllOperationalAccounts();
  Future<void> deactivateUser(String userId);
  Future<void> activateUser(String userId);
}

