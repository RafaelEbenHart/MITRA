import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithEmail(String email, String password);
  Future<UserModel> registerOwner(
      String email, String password, String fullName);
  Future<UserModel> createOperationalAccount(
    String email,
    String password,
    String fullName,
  );
  Future<UserModel> getCurrentUser();
  Future<void> logout();
  Future<List<UserModel>> getAllOperationalAccounts();
  Future<void> deactivateUser(String userId);
  Future<void> activateUser(String userId);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  @override
  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = await _getUserFromFirestore(userCredential.user!.uid);
      if (!user.isActive) {
        throw Exception('akun ini telah di nonaktifkan');
      }
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel> registerOwner(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Check if this is the first user (Owner)
      final usersSnapshot = await _firestore.collection('users').limit(1).get();
      if (usersSnapshot.docs.isNotEmpty) {
        throw Exception('hanya satu akun owner yang diperbolehkan');
      }

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        id: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        role: PeranPengguna.pemilik,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel> createOperationalAccount(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      // Verify current user is Owner
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        throw Exception('tidak ada user yang login');
      }

      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!currentUserDoc.exists) {
        throw Exception('user tidak ditemukan');
      }

      final currentUserData = UserModel.fromJson(currentUserDoc.data()!);
      if (currentUserData.role != PeranPengguna.pemilik) {
        throw Exception('hanya owner yang dapat membuat akun operasional');
      }

      // Create new user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        role: PeranPengguna.karyawan,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toJson());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('tidak ada user yang login');
      }
      return _getUserFromFirestore(user.uid);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<List<UserModel>> getAllOperationalAccounts() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['operational', 'kasir', 'karyawan']).get();

      return snapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> activateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
      });
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw Exception('user tidak ditemukan');
    }
    return UserModel.fromJson(doc.data()!);
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // Newer Firebase SDK uses this
      case 'invalid-email':
        return 'email atau password salah';
      case 'user-disabled':
        return 'akun ini telah di nonaktifkan';
      case 'too-many-requests':
        return 'terlalu banyak percobaan login, coba lagi nanti';
      case 'email-already-in-use':
        return 'email sudah terdaftar';
      case 'weak-password':
        return 'password terlalu lemah';
      case 'operation-not-allowed':
        return 'operasi tidak diizinkan, hubungi admin';
      default:
        return 'email atau password salah';
    }
  }
}
