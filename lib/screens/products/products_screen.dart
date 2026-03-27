import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/notification_icon.dart';
import 'product_detail_screen.dart';
import 'dart:developer' as dev;

/// Elite Products Screen with advanced search and real-time Notification access.
/// Upgraded to handle 'doc.id' and 'Timestamp' based expiry properly.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();
  
  String _searchQuery = '';
  ProductCategory _selectedCategory = ProductCategory.other;
  bool _isCategoryFilterActive = false;

  int _getDaysLeft(DateTime expiryDate) {
    final today = DateTime.now();
    return expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("My Inventory", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D3436))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: const [
          NotificationIcon(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12, width: 1.2)),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: const InputDecoration(hintText: "Search your products...", prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF5D8064)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _categoryChip("All", ! _isCategoryFilterActive, () => setState(() => _isCategoryFilterActive = false)),
                ...ProductCategory.values.map((cat) => _categoryChip(cat.name.toUpperCase(), _isCategoryFilterActive && _selectedCategory == cat, () => setState(() { _isCategoryFilterActive = true; _selectedCategory = cat; }))),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _db.streamProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error, color: Colors.red), Text(snapshot.error.toString())]);
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF5D8064)));
                final allProducts = snapshot.data ?? [];
                
                // Real-time sorting by expiry date in memory (Fallback to doc.id for stable identification)
                final filtered = allProducts.where((p) {
                  final matchesName = p.name.toLowerCase().contains(_searchQuery);
                  final matchesCategory = ! _isCategoryFilterActive || p.category == _selectedCategory;
                  return matchesName && matchesCategory;
                }).toList();
                
                filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

                if (filtered.isEmpty) return _buildEmptyState();
                
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _productItem(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ActionChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
        backgroundColor: isSelected ? const Color(0xFF5D8064) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black12)),
        onPressed: onTap,
      ),
    );
  }

  Widget _productItem(Product product) {
    final days = _getDaysLeft(product.expiryDate);
    final themeColor = days <= 3 ? Colors.redAccent : Colors.green;
    final dynamic rawPrice = product.price;
    String displayPrice = 'N/A';
    if (rawPrice is num) { displayPrice = '₹${rawPrice.toStringAsFixed(0)}'; } 
    else if (rawPrice is String) { displayPrice = rawPrice.startsWith('₹') ? rawPrice : '₹$rawPrice'; }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          // ── 🎯 NAVIGATING WITH doc.id ──────────────────────────────────
          // Correctly passing both document ID and full data map.
          dev.log("Navigating to item details: docId=${product.id}");
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(data: product.toMap(), docId: product.id)));
        },
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: themeColor.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
          child: Icon(Icons.inventory_2_rounded, color: themeColor, size: 24),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        subtitle: Text("${product.expiryDateString} • $displayPrice", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: themeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Text(days <= 0 ? "Expired" : "$days d", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.eco_outlined, size: 60, color: Colors.grey), SizedBox(height: 16), Text("No products found!", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 18))]));
  }
}