import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';

/// Clean and professional Profile Screen with dynamic name display and custom display picture support.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _notificationsEnabled = true;

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 50,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImage': base64String,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update image: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snapshot) {
                  String name = "User";
                  String? b64Image;
                  Map<String, dynamic>? dataMap;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    dataMap = snapshot.data!.data() as Map<String, dynamic>;
                    name = dataMap['name'] ?? "User";
                    b64Image = dataMap['profileImage'];
                  }

                  return Column(
                    children: [
                      // Editable Avatar 
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: b64Image != null ? MemoryImage(base64Decode(b64Image)) : null,
                              child: b64Image == null 
                                ? const Icon(Icons.person_rounded, size: 50, color: AppColors.primary)
                                : null,
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isUploading
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(name, style: AppTextStyles.h2),
                      
                      const SizedBox(height: 4),
                      // Display Email from Auth
                      Text(FirebaseAuth.instance.currentUser?.email ?? "no-email@freshloop.com", style: AppTextStyles.subtitle),
                      
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      
                      // User Details Section
                      _userDetailRow(Icons.phone_outlined, "Phone", dataMap?['phone'] ?? "+91 Add Mobile Number"),
                      const SizedBox(height: 14),
                      _userDetailRow(Icons.location_on_outlined, "Location", dataMap?['location'] ?? "Add your address"),
                      const SizedBox(height: 14),
                      _userDetailRow(Icons.calendar_today_outlined, "Member Since", "March 2026"),
                    ],
                  );
                }
              )
            ),

            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildEcoImpactDashboard(),
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
                  _settingsTile(
                    icon: Icons.notifications_none_rounded, 
                    title: "Notifications", 
                    sub: "Alerts for expiring items", 
                    hasSwitch: true, 
                    switchValue: _notificationsEnabled,
                    onSwitchChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Notifications Enabled' : 'Notifications Disabled'), backgroundColor: AppColors.primary));
                    },
                  ),
                  _settingsTile(
                    icon: Icons.security_rounded, 
                    title: "Privacy", 
                    sub: "Manage your data", 
                    hasSwitch: false, 
                    onTap: () {
                      showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Privacy Rules"), content: const Text("Your data is secured locally and on Firebase. You own all of your pantry scans."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK", style: TextStyle(color: AppColors.primary)))]));
                    }
                  ),
                  _settingsTile(
                    icon: Icons.help_outline_rounded, 
                    title: "Support", 
                    sub: "Get help & feedback", 
                    hasSwitch: false, 
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacting Support Center...'), backgroundColor: Color(0xFF3B82F6)));
                    }
                  ),
                  
                  const SizedBox(height: 24),
                  const Text("ACCOUNT", style: AppTextStyles.label),
                  const SizedBox(height: 12),
                  _settingsTile(
                    icon: Icons.logout_rounded, 
                    title: "Logout", 
                    sub: "Sign out of your account", 
                    hasSwitch: false, 
                    onTap: () async {
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

  Widget _userDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon, 
    required String title, 
    required String sub, 
    required bool hasSwitch, 
    bool switchValue = false, 
    ValueChanged<bool>? onSwitchChanged, 
    VoidCallback? onTap, 
    bool isDestructive = false
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        onTap: hasSwitch ? null : onTap,
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
          ? Switch.adaptive(value: switchValue, activeColor: AppColors.primary, onChanged: onSwitchChanged)
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      ),
    );
  }

  Widget _buildEcoImpactDashboard() {
    final FirestoreService db = FirestoreService();
    return StreamBuilder<List<Product>>(
      stream: db.streamSoldHistory(),
      builder: (ctx, historySnap) {
        return StreamBuilder<List<Product>>(
          stream: db.streamActiveProducts(),
          builder: (ctx, activeSnap) {
            final history = historySnap.data ?? [];
            final active = activeSnap.data ?? [];
            
            // 1. Waste Prevented & Revenue 
            int itemsSaved = history.length;
            double totalRevenue = 0.0;
            int totalDonated = 0;
            
            for (var p in history) {
              if (p.status == ProductStatus.donated) {
                totalDonated++;
              } else {
                totalRevenue += (double.tryParse(p.listingPrice.toString()) ?? 0.0);
              }
            }
            
            // 2. Pantry Health Score
            int urgentCount = 0;
            final today = DateTime.now();
            for (var p in active) {
              final days = p.expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;
              if (days <= 3) urgentCount++;
            }
            int totalActive = active.isNotEmpty ? active.length : 1;
            int healthScore = 100 - ((urgentCount / totalActive) * 100).toInt();
            if (active.isEmpty) healthScore = 100;

            // 3. Favorite Category
            Map<String, int> categoryCount = {};
            for (var p in active) {
              categoryCount[p.category.name] = (categoryCount[p.category.name] ?? 0) + 1;
            }
            for (var p in history) {
              categoryCount[p.category.name] = (categoryCount[p.category.name] ?? 0) + 1;
            }
            String favCategory = "N/A";
            if (categoryCount.isNotEmpty) {
              // Find the category with maximum count
              var maxEntry = categoryCount.entries.first;
              for (var entry in categoryCount.entries) {
                if (entry.value > maxEntry.value) maxEntry = entry;
              }
              favCategory = maxEntry.key;
              favCategory = "${favCategory[0].toUpperCase()}${favCategory.substring(1).toLowerCase()}";
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("IMPACT METRICS", style: AppTextStyles.label),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _impactRow(Icons.eco_rounded, Colors.green, "Waste Prevented", "$itemsSaved Items Saved"),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withOpacity(0.1))),
                      _impactRow(Icons.account_balance_wallet_rounded, const Color(0xFF3B82F6), "Lifetime Revenue", "₹${totalRevenue.toStringAsFixed(0)} Earned"),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withOpacity(0.1))),
                      _impactRow(Icons.favorite_rounded, Colors.redAccent, "Total Donations", "$totalDonated Items"),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withOpacity(0.1))),
                      _impactRow(Icons.health_and_safety_rounded, Colors.orange, "Pantry Health", "$healthScore% Fresh"),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: Colors.grey.withOpacity(0.1))),
                      _impactRow(Icons.category_rounded, Colors.purple, "Top Category", favCategory),
                    ],
                  ),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _impactRow(IconData icon, Color color, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: color)),
      ],
    );
  }
}