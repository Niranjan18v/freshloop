import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../services/expiry_checker.dart';
import '../services/notification_service.dart';
import 'dart:developer' as dev;

/// Top-level callback for Workmanager.
/// This runs in a separate isolate and manages background background tasks.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    dev.log("── 🌑 BACKGROUND TASK STARTED: $task ───────────────────────────────");
    
    try {
      // 1. Initialize Firebase inside the background isolate
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      // 2. Initialize Notifications inside the background isolate
      final notifications = NotificationService();
      await notifications.init();
      
      // 3. Perform the Expiry Check
      await ExpiryCheckerService().checkExpiry();
      
      return Future.value(true);
    } catch (e) {
      dev.log("Background Task Error: $e");
      return Future.value(false);
    }
  });
}
