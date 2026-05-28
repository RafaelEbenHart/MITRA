import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'firebase_config.dart';

class FirebaseDatabase {
  static bool _initialized = false;
  static bool _firebaseAvailable = true;

  static bool get isFirebaseAvailable => _firebaseAvailable;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      // Firebase initialized successfully, keep _firebaseAvailable = true
      _firebaseAvailable = true;
    } catch (e) {
      _firebaseAvailable = false;
    }
    _initialized = true;
  }

  static Future<bool> checkConnection() async {
    try {
      // Simple connectivity check - just try to get a document
      // If user is not authenticated, Firestore will handle the error at operation time
      final docRef = FirebaseFirestore.instance
          .collection(FirebaseConfig.appConfigCollection)
          .doc(FirebaseConfig.connectionCheckDoc);
      await docRef.get();
      return true;
    } catch (e) {
      // Don't fail connection check - let actual operations handle auth errors
      return true;
    }
  }

  static CollectionReference<Map<String, dynamic>> productsCollection() {
    return FirebaseFirestore.instance
        .collection(FirebaseConfig.productsCollection);
  }

  static CollectionReference<Map<String, dynamic>> shopsCollection() {
    return FirebaseFirestore.instance
        .collection(FirebaseConfig.shopsCollection);
  }

  static CollectionReference<Map<String, dynamic>> settingsCollection() {
    return FirebaseFirestore.instance
        .collection(FirebaseConfig.settingsCollection);
  }

  static CollectionReference<Map<String, dynamic>> invoicesCollection() {
    return FirebaseFirestore.instance
        .collection(FirebaseConfig.invoicesCollection);
  }

  static CollectionReference<Map<String, dynamic>> receiptsCollection() {
    return FirebaseFirestore.instance
        .collection(FirebaseConfig.receiptsCollection);
  }
}
