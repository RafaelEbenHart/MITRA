import '../../domain/repos/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AkunPengguna> loginWithEmail(String email, String password) async {
    try {
      final userModel = await remoteDataSource.loginWithEmail(email, password);
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AkunPengguna> registerOwner(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final userModel =
          await remoteDataSource.registerOwner(email, password, fullName);
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AkunPengguna> createOperationalAccount(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final userModel = await remoteDataSource.createOperationalAccount(
        email,
        password,
        fullName,
      );
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AkunPengguna> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentUser();
      return userModel.toEntity();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  Future<List<AkunPengguna>> getAllOperationalAccounts() async {
    try {
      final userModels = await remoteDataSource.getAllOperationalAccounts();
      return userModels.map((model) => model.toEntity()).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deactivateUser(String userId) async {
    await remoteDataSource.deactivateUser(userId);
  }

  @override
  Future<void> activateUser(String userId) async {
    await remoteDataSource.activateUser(userId);
  }
}

