import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Private Multi-User Notification Service.
/// Each user's notification history is stored under 'users/{uid}/notifications'.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── 🛡️ PRIVATE HELPER ──────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _userNotifications {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Authentication required for notifications.");
    return _db.collection('users').doc(user.uid).collection('notifications');
  }

  Future<void> init() async {
    if (kIsWeb) return; // ✅ SKIP INITIALIZATION ON WEB

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      dev.log("Notification Service Init Error: $e");
    }
  }

  // ── 🧹 NOTIFICATION CLEANUP ────────────────────────────────────────
  /// Cancels any future alerts and removes historical records for a specific product.
  Future<void> clearNotificationsForProduct(String productId, String productName) async {
    try {
      // 1. Cancel any active system alerts on non-web
      if (!kIsWeb) {
        await flutterLocalNotificationsPlugin.cancel(productName.hashCode);
      }
      
      // 2. Remove from private Firestore history
      final snapshot = await _userNotifications
          .where('message', isGreaterThanOrEqualTo: productName)
          .get();
      
      for (var doc in snapshot.docs) {
        if (doc['message'].toString().contains(productName)) {
          await doc.reference.delete();
        }
      }
      dev.log("Notifications cleared for $productName");
    } catch (e) {
      dev.log("Cleanup failed: $e");
    }
  }

  /// Fire Local Alert AND Save to PRIVATE Firestore (Guarded against duplicates).
  Future<void> sendAndSave({required String title, required String body, required String type}) async {
    try {
      // 🛡️ REFINED ANTI-SPAM (Allowed recurring alerts after 20 hours)
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(hours: 20));
      
      final existingDocs = await _userNotifications
          .where('title', isEqualTo: title)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .limit(1)
          .get();
          
      if (existingDocs.docs.isNotEmpty) {
        return; // Already notified recently.
      }
    } catch (e) {
      dev.log("Duplicate check failed: $e, continuing.");
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'freshloop_inventory_channel',
      'Inventory Alerts',
      channelDescription: 'Real-time alerts for your products.',
      importance: Importance.max,
      priority: Priority.max, // 🧨 Set to MAX for popup behavior
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true, // 🚨 Encourages heads-up display
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    try {
      if (!kIsWeb) {
        await flutterLocalNotificationsPlugin.show(title.hashCode, title, body, platformDetails);
      }
    } catch (e) {
      dev.log("Notification display failed: $e");
    }

    try {
      await _userNotifications.add({
        'title': title,
        'message': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'pushed': true, // Explicitly marked as shown to system tray.
      });
    } catch (e) {
      dev.log("Sync failed: $e");
    }
  }

  Future<void> notifyOnSave(Product product) async {
    await sendAndSave(
      title: "New Item Tracked!",
      body: "${product.name} is now protected with active expiry tracking.",
      type: 'added',
    );
  }

  // ── 🛰️ BACKGROUND SYNC LOGIC ───────────────────────────────────────
  /// Pulls un-pushed notifications from Firestore into the system tray.
  /// Crucial for showing Shop Alerts in the background without FCM.
  Future<void> syncRemoteNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _userNotifications
          .where('pushed', isNotEqualTo: true)
          .limit(10)
          .get();

      if (snapshot.docs.isEmpty) return;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'FreshLoop Notification';
        final body = data['message'] ?? 'View updates in app.';
        final type = data['type'] ?? 'info';

        // Fire Local Notification
        await _showLocal(title, body, type);

        // Mark as Pushed in DB
        await doc.reference.update({'pushed': true});
      }
      dev.log("── 🛰️ BACKGROUND SYNC COMPLETE ──────────────────────────────");
    } catch (e) {
      dev.log("Background Sync Error: $e");
    }
  }

  Future<void> _showLocal(String title, String body, String type) async {
    if (kIsWeb) return; // 🛡️ NO LOCAL ALERTS ON WEB

    final String channelId = type == 'shop' ? 'freshloop_shop_channel' : 'freshloop_inventory_channel';
    final String channelName = type == 'shop' ? 'Marketplace Alerts' : 'Inventory Alerts';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId, channelName,
      importance: Importance.max,
      priority: Priority.max, // 🧨 Maximum visibility
      showWhen: true,
      enableVibration: true,
      playSound: true,
      fullScreenIntent: true,
    );
    
    await flutterLocalNotificationsPlugin.show(
      title.hashCode, title, body, NotificationDetails(android: androidDetails)
    );
  }

  // ── 🛒 MARKETPLACE PUSH NOTIFICATIONS (CLIENT-SIDE LISTENER) ────────
  void startShopListener([Function(String title, String body)? onNewItemPopup]) {
    final user = _auth.currentUser;
    if (user == null) return;

    bool isInitialLoad = true;

    // Listen to new listings in the global shop
    _db.collection('public_listings').snapshots().listen((snapshot) {
      if (isInitialLoad) {
        isInitialLoad = false;
        return; // Ignore existing items in the shop on app startup
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          // Don't notify the user about their own listings
          if (data['sellerId'] == user.uid) continue;

          final name = data['name'] ?? 'An item';
          final title = '🛒 New Item in Shop!';
          final body = 'The product $name is available in shop.';

          // Fire optional in-app UI callback to show a popup Snackbar
          if (onNewItemPopup != null) {
            onNewItemPopup(title, body);
          }

          // Fire Local Popup Notification
          _showLocal(title, body, 'shop');
        }
      }
    });
  }
}
