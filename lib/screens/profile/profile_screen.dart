import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_colors.dart';
import '../login_screen.dart';

/// Clean and professional Profile Screen with dynamic name display.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get current User UID
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profile", style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // ── User Information Card ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),

                  // 2. Fetch and Display Name Dynamically
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Loading...", style: AppTextStyles.h2);
                      }
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        return Text(data['name'] ?? "User", style: AppTextStyles.h2);
                      }
                      return const Text("User", style: AppTextStyles.h2);
                    },
                  ),
                  
                  const SizedBox(height: 4),
                  // Display Email from Auth
                  Text(FirebaseAuth.instance.currentUser?.email ?? "no-email@freshloop.com", style: AppTextStyles.subtitle),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _userStat("12", "Saved"),
                      _userStat("128", "Points"),
                      _userStat("4", "Badges"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Settings & Options ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SETTINGS", style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  _settingsTile(Icons.notifications_none_rounded, "Notifications", "Alerts for expiring items", true, () {}),
                  _settingsTile(Icons.security_rounded, "Privacy", "Manage your data", false, () {}),
                  _settingsTile(Icons.help_outline_rounded, "Support", "Get help & feedback", false, () {}),
                  
                  const SizedBox(height: 24),
                  const Text("ACCOUNT", style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  _settingsTile(
                    Icons.logout_rounded, 
                    "Logout", 
                    "Sign out of your account", 
                    false, 
                    () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }, 
                    isDestructive: true
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _userStat(String val, String lbl) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
        Text(lbl, style: AppTextStyles.label),
      ],
    );
  }

  Widget _settingsTile(IconData icon, String title, String sub, bool hasSwitch, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? AppColors.error.withOpacity(0.1) : AppColors.primaryLight, 
            borderRadius: BorderRadius.circular(14)
          ),
          child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDestructive ? AppColors.error : AppColors.textPrimary)),
        subtitle: Text(sub, style: AppTextStyles.label),
        trailing: hasSwitch 
          ? Switch.adaptive(value: true, activeColor: AppColors.primary, onChanged: (v) {})
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }
}