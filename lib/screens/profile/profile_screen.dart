import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Minimalist and professional Profile Screen inspired by modern SaaS apps.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  const Text("Niranjan V", style: AppTextStyles.h2),
                  const SizedBox(height: 4),
                  const Text("food.saver@freshloop.com", style: AppTextStyles.subtitle),
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
                  _settingsTile(Icons.notifications_none_rounded, "Notifications", "Alerts for expiring items", true),
                  _settingsTile(Icons.security_rounded, "Privacy", "Manage your data", false),
                  _settingsTile(Icons.help_outline_rounded, "Support", "Get help & feedback", false),
                  
                  const SizedBox(height: 24),
                  const Text("ACCOUNT", style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  _settingsTile(Icons.logout_rounded, "Logout", "Sign out of your account", false, isDestructive: true),
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

  Widget _settingsTile(IconData icon, String title, String sub, bool hasSwitch, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: isDestructive ? AppColors.error.withOpacity(0.1) : AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
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