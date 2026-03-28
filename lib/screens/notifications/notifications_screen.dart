import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../core/app_colors.dart';
import '../../main.dart'; // 🚀 Added to access MainNavigation Key

/// Private Multi-User Notification Center.
/// Strictly isolated to the current user's history under 'users/{uid}/notifications'.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Please log in to see notifications."));
    
    final notificationRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notification Center", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ── 🛡️ PRIVATE ISOLATED QUERY ──────────────────────────────────────
        stream: notificationRef
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

          final notifications = snapshot.data!.docs
              .map((doc) => AppNotification.fromSnapshot(doc))
              .toList();

          if (notifications.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              final note = notifications[i];
              return _notificationCard(context, note, notificationRef);
            },
          );
        },
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification note, CollectionReference ref) {
    final isShop = note.type == 'shop';
    final themeColor = isShop ? Colors.blueAccent : (note.title.contains('❌') ? Colors.redAccent : Colors.orangeAccent);
    final icon = isShop ? Icons.shopping_bag_rounded : (note.title.contains('❌') ? Icons.error_outline_rounded : Icons.hourglass_top_rounded);

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.all(8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.doc(note.id).delete(),
      child: GestureDetector(
        onTap: () {
          // 1. Mark as Read in DB
          ref.doc(note.id).update({'isRead': true});

          // 2. Specialized Navigation for SHOP ITEMS
          if (note.type == 'shop') {
            Navigator.pop(context); // Close notifications
            
            MainNavigation.navKey.currentState?.setTabIndex(1);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: note.isRead ? Colors.white70 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
            border: note.isRead ? null : Border.all(color: themeColor.withOpacity(0.1), width: 1.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: themeColor, size: 24),
            ),
            title: Text(note.title, style: TextStyle(fontWeight: note.isRead ? FontWeight.normal : FontWeight.w900, fontSize: 16, color: const Color(0xFF1F2937))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(note.message, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 10),
                Text(DateFormat('hh:mm a • dd MMM').format(note.timestamp), style: const TextStyle(color: Colors.black26, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: note.isRead ? null : Container(width: 8, height: 8, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text("No Alerts Found", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("You'll see only your private alerts here.", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Query Error: $error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
  }
}
