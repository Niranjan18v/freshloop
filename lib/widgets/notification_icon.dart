import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/notifications/notifications_screen.dart';

/// Elite Bell Icon with an automated unread notification badge.
/// Syncs in real-time with Firestore to provide instant visual alerts.
class NotificationIcon extends StatelessWidget {
  const NotificationIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey, size: 28),
        onPressed: () {},
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) count = snapshot.data!.docs.length;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, 
                color: count > 0 ? const Color(0xFF111827) : Colors.grey, 
                size: 28,
              ),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const NotificationsScreen())
              ),
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2), // Clean cutout effect
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ]
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, height: 1),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                ),
              ),
          ],
        );
      },
    );
  }
}
