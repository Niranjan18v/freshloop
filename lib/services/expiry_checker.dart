import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'dart:developer' as dev;

/// Private Multi-User Expiry Checker Service.
/// Scans only the current authenticated user's 'users/{uid}/products' collection.
class ExpiryCheckerService {
  static final ExpiryCheckerService _instance = ExpiryCheckerService._internal();
  factory ExpiryCheckerService() => _instance;
  ExpiryCheckerService._internal();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final NotificationService _notifications = NotificationService();

  /// Scans the PRIVATE product library and triggers localized alerts.
  Future<void> checkExpiry() async {
    final user = _auth.currentUser;
    if (user == null) {
      dev.log("── 🛡️ SCAN SKIPPED: NO AUTHENTICATED USER ───────────────────────");
      return;
    }

    dev.log("── 🛡️ STARTING PRIVATE SCAN FOR USER: ${user.uid} ──────────────");
    
    try {
      // 🏰 TARGET PRIVATE SUBCOLLECTION
      final snapshot = await _db.collection('users').doc(user.uid).collection('products').get();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown Item';
        
        // 📅 HYBRID DATE PARSING
        final rawExpiry = data['expiryDate'] ?? data['expiry'];
        if (rawExpiry == null) continue;

        DateTime? expiryDate;
        if (rawExpiry is Timestamp) {
          expiryDate = rawExpiry.toDate();
        } else if (rawExpiry is String && rawExpiry.isNotEmpty) {
          try {
            if (rawExpiry.contains('/')) {
              final parts = rawExpiry.split('/');
              expiryDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            } else {
              expiryDate = DateTime.parse(rawExpiry);
            }
          } catch (_) { continue; }
        }

        if (expiryDate == null) continue;

        final normalizedExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
        final difference = normalizedExpiry.difference(today).inDays;

        if (difference < 0) {
          await _notifications.sendAndSave(
            title: "❌ Expired: $name",
            body: "$name has expired. Remove it from your inventory.",
            type: 'expiry',
          );
        } else if (difference == 0) {
          await _notifications.sendAndSave(
            title: "⚠️ Expires Today: $name",
            body: "$name expires today! Use it before waste.",
            type: 'expiry',
          );
        } else if (difference <= 3) {
          await _notifications.sendAndSave(
            title: "⏳ Expiring Soon: $name",
            body: "$name will expire in $difference days.",
            type: 'expiry',
          );
        }
      }
      dev.log("── ✅ PRIVATE SCAN COMPLETE ──────────────────────────────────");
    } catch (e) {
      dev.log("Critical Expiry Scan Error: $e");
    }
  }
}
