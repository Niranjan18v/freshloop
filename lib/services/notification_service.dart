import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import 'dart:developer' as dev;
import 'dart:io';

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
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }

  // ── 🧹 NOTIFICATION CLEANUP ────────────────────────────────────────
  /// Cancels any future alerts and removes historical records for a specific product.
  Future<void> clearNotificationsForProduct(String productId, String productName) async {
    try {
      // 1. Cancel any active system alerts (using hash of name as id)
      await flutterLocalNotificationsPlugin.cancel(productName.hashCode);
      
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

  /// Fire Local Alert AND Save to PRIVATE Firestore.
  Future<void> sendAndSave({required String title, required String body, required String type}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'freshloop_inventory_channel',
      'Inventory Alerts',
      channelDescription: 'Real-time alerts for your products.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    try {
      await flutterLocalNotificationsPlugin.show(title.hashCode, title, body, platformDetails);
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
}
