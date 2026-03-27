import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/notification_model.dart';
import 'dart:developer' as dev;

/// Professional Notification Service with Persistent 'Notification Center' integration.
/// Updated to track specific notification types: 'expiry' and 'added' for filtering.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// ✅ Fire Local Alert AND Save to Firestore.
  /// Categorizes as 'expiry' or 'added' based on the intent.
  Future<void> sendAndSave({required String title, required String body, required String type}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'notification_center_channel',
      'FreshLoop Feed',
      channelDescription: 'Persistent notifications for your inventory history.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    try {
      await flutterLocalNotificationsPlugin.show(title.hashCode, title, body, platformDetails);
    } catch (e) {
      dev.log("System alert failed: $e");
    }

    try {
      await _db.collection('notifications').add({
        'title': title,
        'message': body,
        'type': type, // Filterable field: 'expiry' or 'added'
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      dev.log("Firestore notification sync failed: $e");
    }
  }

  Future<void> notifyOnSave(Product product) async {
    await sendAndSave(
      title: "Inventory Protected!",
      body: "${product.name} has been added with expiry tracking.",
      type: 'added', // Correctly tagged for internal filtering
    );
  }
}
