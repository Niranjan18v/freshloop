import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'dart:developer' as dev;

/// Optimized Firestore service with better error handling and simplified query.
class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final String collection = 'products';

  /// Stream of products from Firestore.
  /// Removed orderBy to avoid index-related infinite loading issues.
  Stream<List<Product>> streamProducts() {
    return _db.collection(collection)
        .snapshots()
        .map((snapshot) {
          dev.log('Received Firestore snapshot with ${snapshot.docs.length} docs');
          return snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
        });
  }

  Future<void> saveProduct(Product product) async {
    try {
      await _db.collection(collection).add(product.toMap());
    } catch (e) {
      dev.log('Error saving product: $e');
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection(collection).doc(id).delete();
  }

  Future<List<Product>> getExpiringSoon({int limit = 5}) async {
    final snapshot = await _db.collection(collection).get();
    var list = snapshot.docs.map((doc) => Product.fromSnapshot(doc)).toList();
    return list.take(limit).toList();
  }
}
