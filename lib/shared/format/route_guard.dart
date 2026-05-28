import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../modul/akses/domain/entities/user_entity.dart';
import '../../modul/akses/data/models/user_model.dart';

class RouteGuard {
  static Future<AkunPengguna?> getCurrentUser() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) return null;

      final userModel = UserModel.fromJson(doc.data()!);
      return userModel.toEntity();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isOwnerAuthenticated() async {
    try {
      final user = await getCurrentUser();
      return user != null && user.peran == PeranPengguna.pemilik;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isOperationalAuthenticated() async {
    try {
      final user = await getCurrentUser();
      return user != null && user.peran == PeranPengguna.karyawan;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAuthenticated() async {
    return await getCurrentUser() != null;
  }

  static Future<bool> isFirstUser() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').limit(1).get();
      return usersSnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }
}
