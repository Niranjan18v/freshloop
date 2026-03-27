import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

/// Minimalist Product Details Screen inspired by Notion/Google Fit.
/// Provides a clear view of item lifecycle and quick management actions.
class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const ProductDetailScreen({super.key, required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    // ── Logic: Calculate Status ─────────────────────────────────────────────
    final name = data['name'] ?? 'Unknown Item';
    final expiry = data['expiryDate'] ?? data['expiry'] ?? 'N/A';
    const status = "Fresh"; // For the demo details, we use a static placeholder
    const category = "Fridge & Dairy";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Item Details", style: AppTextStyles.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // ── Product Image Card ──────────────────────────────────────────
            Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 8),
              ),
              child: const Icon(Icons.fastfood_rounded, size: 80, color: AppColors.primary),
            ),

            const SizedBox(height: 32),

            // ── Name & Category ─────────────────────────────────────────────
            Text(name, style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(category, style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),

            const SizedBox(height: 40),

            // ── Main Details Grid ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _detailTile("EXPIRY DATE", expiry, Icons.calendar_today_rounded),
                  _detailTile("STATUS", status, Icons.eco_rounded),
                  _detailTile("QUANTITY", "1 Unit", Icons.shopping_basket_rounded),
                  _detailTile("NOTIFICATIONS", "ON", Icons.notifications_active_rounded),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // ── Management Buttons ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.border)),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(String lbl, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(lbl, style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
