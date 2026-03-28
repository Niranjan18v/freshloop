import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/notification_icon.dart';
import 'product_detail_screen.dart';

/// Clean, high-performance Products Screen (Pantry View).
/// Displays strictly 'active' products that are NOT currently being sold or donated.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final FirestoreService _db = FirestoreService();
  ProductCategory? _selectedCategory;
  bool _isFilterActive = false;

  int _getDaysLeft(DateTime expiryDate) {
    final today = DateTime.now();
    return expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  Color _getExpiryColor(int days) {
    if (days <= 3) return Colors.redAccent;
    if (days <= 7) return Colors.orange;
    return const Color(0xFF10B981);
  }

  // ── 🍽️ UPDATED: MARK AS USED (FULL CLEANUP) ───────────────────────
  Future<void> _markAsUsed(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Item Finished?", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
        content: Text("Confirm '${p.name}' is finished. This will purge it from inventory and notifications."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Yes, Used", style: TextStyle(fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 🟢 REPLACED: Now calls the atomic markAsUsed (DB + Notifications)
      await _db.markAsUsed(p);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.black, content: Text('Inventory & Notifications Updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Products", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 26)),
        centerTitle: false,
        actions: const [NotificationIcon(), SizedBox(width: 12)],
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildFilterChip("ALL", !_isFilterActive, () => setState(() => _isFilterActive = false)),
                ...ProductCategory.values.map((cat) => _buildFilterChip(cat.name.toUpperCase(), _isFilterActive && _selectedCategory == cat, () => setState(() { _isFilterActive = true; _selectedCategory = cat; }))),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _db.streamActiveProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          final products = snapshot.data ?? [];
          final filtered = products.where((p) => !_isFilterActive || p.category == _selectedCategory).toList();
          filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          final urgent = filtered.where((p) => _getDaysLeft(p.expiryDate) <= 3).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 60),
            children: [
              if (urgent > 0) _buildAlertBanner(urgent),
              const SizedBox(height: 8),
              if (filtered.isEmpty) _buildEmptyState() else ...filtered.map((p) => _buildHighVisibilityCard(p)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.bold, fontSize: 11)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF1F2937),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildAlertBanner(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
      child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24), const SizedBox(width: 12), Text("$count products expiring within 3 days", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))]),
    );
  }

  Widget _buildHighVisibilityCard(Product p) {
    final daysLeft = _getDaysLeft(p.expiryDate);
    final statusColor = _getExpiryColor(daysLeft);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))], border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(data: p.toMap(), docId: p.id))),
          child: Column(
            children: [
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), decoration: BoxDecoration(color: statusColor.withOpacity(0.1)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Icon(Icons.timer_outlined, size: 16, color: statusColor), const SizedBox(width: 8), Text(daysLeft <= 0 ? "EXPIRED" : "$daysLeft DAYS LEFT", style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8))]), Text(p.expiryDateString, style: TextStyle(color: statusColor.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 12))])),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Color(0xFF111827))), const SizedBox(height: 4), Text(p.store, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600))])), GestureDetector(onTap: () => _markAsUsed(p), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(30)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.white), SizedBox(width: 6), Text("Used", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11))])))]),
                    const SizedBox(height: 20),
                    Row(children: [_infoBit(Icons.currency_rupee_rounded, "₹${p.price}"), const SizedBox(width: 24), _infoBit(Icons.category_outlined, p.category.name.toUpperCase())]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBit(IconData icon, String text) {
    return Row(children: [Icon(icon, size: 15, color: const Color(0xFF9CA3AF)), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w700, fontSize: 12))]);
  }

  Widget _buildEmptyState() {
    return Center(child: Column(children: [const SizedBox(height: 100), Icon(Icons.category_outlined, size: 80, color: Colors.grey.shade300), const SizedBox(height: 20), const Text("No active products", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16, fontWeight: FontWeight.bold))]));
  }
}