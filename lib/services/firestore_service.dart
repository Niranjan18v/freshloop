import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'notification_service.dart';
import 'dart:developer' as dev;

/// Private Multi-User Firestore Service with Integrated Notification Cleanup.
class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _notifications = NotificationService();

  // 🏠 PRIVATE COLLECTION (USER SPECIFIC)
  CollectionReference<Map<String, dynamic>> get _userProducts {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Auth required.");
    return _db.collection('users').doc(user.uid).collection('products');
  }

  // 🏰 DEDICATED PRIVATE HISTORY
  CollectionReference<Map<String, dynamic>> get _userSoldHistory {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Auth required.");
    return _db.collection('users').doc(user.uid).collection('sold_history');
  }

  // 🌎 GLOBAL PUBLIC MARKETPLACE (ALL USERS CAN SEE)
  CollectionReference<Map<String, dynamic>> get _publicMarketplace {
    return _db.collection('public_listings');
  }

  Stream<List<Product>> streamActiveProducts() {
    return _userProducts
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((s) => s.docs.map((d) => Product.fromSnapshot(d)).toList());
  }

  Stream<List<Product>> streamMarketplaceListing() {
    return _userProducts
        .where('status', whereIn: ['selling', 'donated'])
        .snapshots()
        .map((s) => s.docs.map((d) => Product.fromSnapshot(d)).toList());
  }

  Stream<List<Product>> streamSoldHistory() {
    return _userSoldHistory
        .snapshots()
        .map((s) => s.docs.map((d) => Product.fromSnapshot(d)).toList());
  }

  // 🛍️ STREAM FOR THE SHOP SCREEN (PUBLIC ITEMS) - 🟢 FIXED: Restored restored
  Stream<List<Product>> streamPublicMarketplace() {
    return _publicMarketplace
        .snapshots()
        .map((s) => s.docs.map((d) => Product.fromSnapshot(d)).toList());
  }

  Future<void> saveProduct(Product p) async => await _userProducts.add(p.toMap());
  
  // 🏁 MARK AS SOLD TRANSACTION
  Future<void> finalizeSale(Product p, double listingPrice) async {
    final Map<String, dynamic> soldData = p.toMap();
    soldData['status'] = 'sold';
    soldData['listingPrice'] = listingPrice;
    soldData['soldDate'] = FieldValue.serverTimestamp();

    await _userSoldHistory.add(soldData);
    await _userProducts.doc(p.id).delete();
    await _publicMarketplace.doc(p.id).delete(); // Also remove from shop
    await _notifications.clearNotificationsForProduct(p.id, p.name);
  }

  /// 🍽️ MARKS AS USED
  Future<void> markAsUsed(Product p) async {
    await _userProducts.doc(p.id).delete();
    await _publicMarketplace.doc(p.id).delete();
    await _notifications.clearNotificationsForProduct(p.id, p.name);
  }

  // 🔄 REFACTORED: Now includes notification cleanup - 🟢 FIXED: Added optional name for backward compatibility
  Future<void> deleteProduct(String id, [String? name]) async {
    await _userProducts.doc(id).delete();
    await _publicMarketplace.doc(id).delete();
    if (name != null) {
      await _notifications.clearNotificationsForProduct(id, name);
    }
  }

  // 🔄 SYNC TO PUBLIC MARKETPLACE ON UPDATE
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _userProducts.doc(id).update(data);
    if (data.containsKey('status')) {
      final status = data['status'];
      if (status == 'selling' || status == 'donated') {
        final doc = await _userProducts.doc(id).get();
        if (doc.exists) {
          final pMap = doc.data()!;
          pMap['sellerId'] = _auth.currentUser?.uid;
          pMap['sellerName'] = _auth.currentUser?.displayName ?? 'FreshLoop User';
          pMap['id'] = id;
          await _publicMarketplace.doc(id).set(pMap);
        }
      }
    }
  }
  
  // 🟢 FIXED: Restored correct name for compatibility
  Future<void> deleteSoldRecord(String id) async => await _userSoldHistory.doc(id).delete();
  
  // Alias for history record removal
  Future<void> deleteHistoryRecord(String id) async => await _userSoldHistory.doc(id).delete();
}
