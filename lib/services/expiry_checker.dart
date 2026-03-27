import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'dart:developer' as dev;

/// Professional Expiry Checker Service for FreshLoop.
/// Categorizes all alerts as 'expiry' for persistent history filtering.
class ExpiryCheckerService {
  static final ExpiryCheckerService _instance = ExpiryCheckerService._internal();
  factory ExpiryCheckerService() => _instance;
  ExpiryCheckerService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifications = NotificationService();

  /// Scans Firestore and triggers both system alerts and 'expiry' history entries.
  Future<void> checkExpiry() async {
    dev.log("── 🛡️ STARTING EXPIRY-TAGGED SCAN ───────────────────────────────");
    
    try {
      final snapshot = await _db.collection('products').get();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown Item';
        final expiryStr = data['expiryDate'] ?? data['expiry'];

        if (expiryStr == null) continue;

        DateTime? expiryDate;
        try {
          if (expiryStr.contains('-')) {
            expiryDate = DateTime.parse(expiryStr);
          } else if (expiryStr.contains('/')) {
            final parts = expiryStr.split('/');
            expiryDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } catch (_) { continue; }

        if (expiryDate == null) continue;

        final normalizedExpiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
        final difference = normalizedExpiry.difference(today).inDays;

        // ── PERSISTENT ALERT LOGIC (Safely Tagged as 'expiry') ───────────────────
        if (difference < 0) {
          await _notifications.sendAndSave(
            title: "❌ Expired: $name",
            body: "$name has already expired. Remove it immediately!",
            type: 'expiry',
          );
        } else if (difference == 0) {
          await _notifications.sendAndSave(
            title: "⚠️ Expires Today: $name",
            body: "$name is expiring today. Use it before it goes to waste!",
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
      dev.log("── ✅ EXPIRY SCAN COMPLETE ──────────────────────────────────");
    } catch (e) {
      dev.log("Expiry Scan Error: $e");
    }
  }
}
