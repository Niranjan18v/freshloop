import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../core/app_colors.dart';

/// Updated Notification Center screen showing only 'expiry' related notifications.
/// Features Firestore filtering, timestamp sorting, and intelligent icon selection based on content.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Notification Center", style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ── 🛡️ FILTERED FIRESTORE QUERY ──────────────────────────────────────
        // Only fetches 'expiry' notifications, sorted by latest first using timestamp.
        stream: db.collection('notifications')
            .where('type', isEqualTo: 'expiry')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState(snapshot.error.toString());
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF5D8064)));

          final notifications = snapshot.data!.docs
              .map((doc) => AppNotification.fromSnapshot(doc))
              .toList();

          if (notifications.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, i) {
              final note = notifications[i];
              return _notificationCard(context, note);
            },
          );
        },
      ),
    );
  }

  Widget _notificationCard(BuildContext context, AppNotification note) {
    // ── 🧬 DYNAMIC UI LOGIC ──────────────────────────────────────
    // Since 'type' is now filtered as 'expiry', we use the title to pick icons.
    final themeColor = note.title.contains('❌') ? Colors.redAccent : Colors.orangeAccent;
    final icon = note.title.contains('❌') ? Icons.error_outline_rounded : Icons.hourglass_top_rounded;

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
      onDismissed: (_) => FirebaseFirestore.instance.collection('notifications').doc(note.id).delete(),
      child: GestureDetector(
        onTap: () => FirebaseFirestore.instance.collection('notifications').doc(note.id).update({'isRead': true}),
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
            title: Text(note.title, style: TextStyle(fontWeight: note.isRead ? FontWeight.normal : FontWeight.w900, fontSize: 16)),
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
          const Text("You'll see only expiry alerts here.", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Query Error: $error\nEnsure index for 'type' and 'timestamp' is ready.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))));
  }
}
