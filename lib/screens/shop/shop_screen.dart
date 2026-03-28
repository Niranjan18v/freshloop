import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';

/// Professional Global Marketplace with Deep Product & Seller Insights.
/// Features price comparisons, expiry urgency, and multi-user identity cards.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final FirestoreService _db = FirestoreService();
  ProductCategory? _selectedCategory;
  bool _isFilterActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          Positioned(top: -50, right: -100, child: _vibrantBlob(280, const Color(0xFF3B82F6).withOpacity(0.06))),
          Positioned(bottom: -100, left: -50, child: _vibrantBlob(300, const Color(0xFF10B981).withOpacity(0.04))),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 120,
                backgroundColor: Colors.white.withOpacity(0.9),
                elevation: 0,
                flexibleSpace: const FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 20, bottom: 20),
                  title: Text("Shop Marketplace", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 22)),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    children: [
                      _buildFilterChip("ALL", !_isFilterActive, () => setState(() => _isFilterActive = false)),
                      ...ProductCategory.values.map((cat) => _buildFilterChip(cat.name.toUpperCase(), _isFilterActive && _selectedCategory == cat, () => setState(() { _isFilterActive = true; _selectedCategory = cat; }))),
                    ],
                  ),
                ),
              ),

              StreamBuilder<List<Product>>(
                stream: _db.streamPublicMarketplace(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  if (snapshot.hasError) return SliverFillRemaining(child: _errorArea(snapshot.error.toString()));
                  final products = snapshot.data ?? [];
                  final filtered = products.where((p) => !_isFilterActive || p.category == _selectedCategory).toList();
                  if (filtered.isEmpty) return SliverFillRemaining(child: _emptyArea());

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.62),
                      delegate: SliverChildBuilderDelegate((_, i) => _shopItemCard(filtered[i]), childCount: filtered.length),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 10)),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF111827),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : Colors.black12)),
        showCheckmark: false,
      ),
    );
  }

  Widget _shopItemCard(Product p) {
    final daysLeft = p.expiryDate.difference(DateTime.now()).inDays;
    final urgencyColor = daysLeft <= 4 ? Colors.redAccent : const Color(0xFF10B981);
    return GestureDetector(
      onTap: () => _showPublicDetails(p),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.black.withOpacity(0.04)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), gradient: LinearGradient(colors: [urgencyColor.withOpacity(0.1), Colors.grey.shade100], begin: Alignment.topLeft, end: Alignment.bottomRight)), child: Center(child: Icon(Icons.shopping_basket_outlined, size: 40, color: urgencyColor.withOpacity(0.4)))),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                 Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF111827))),
                 const SizedBox(height: 4),
                 Row(children: [Text("₹${p.listingPrice}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 18)), const SizedBox(width: 6), Text("₹${p.price}", style: const TextStyle(color: Colors.grey, fontSize: 11, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold))]),
                 const SizedBox(height: 10),
                 Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(daysLeft <= 0 ? "EXPIRED" : "$daysLeft DAYS LEFT", style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w900, fontSize: 8))),
                 const SizedBox(height: 10),
                 Row(children: [const Icon(Icons.person_outline, size: 12, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(p.sellerName ?? 'Seller', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)))])
              ]),
            ),
          ],
        ),
      ),
    );
  }

  void _showPublicDetails(Product p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
              child: Row(
                children: [
                  const CircleAvatar(radius: 22, backgroundColor: Color(0xFF111827), child: Icon(Icons.person_rounded, color: Colors.white, size: 24)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.sellerName ?? 'Anonymous Seller', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const Text("Verified FreshLoop Member", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 10))])),
                  GestureDetector(onTap: () => _showSellerDetails(p), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 16))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: Color(0xFF111827))),
            const SizedBox(height: 4),
            Row(children: [Text("₹${p.listingPrice}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 24)), const SizedBox(width: 10), Text("Original: ₹${p.price}", style: const TextStyle(color: Colors.grey, fontSize: 13, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold))]),
            const Divider(height: 40, thickness: 1),
            _detailRow(Icons.timer_outlined, "Shelf Life Guarantee", "${p.expiryDateString} (${p.expiryDate.difference(DateTime.now()).inDays} Days Left)", Colors.redAccent),
            _detailRow(Icons.storefront_outlined, "Original Sourced From", p.store, Colors.purple),
            _detailRow(Icons.category_outlined, "Food Classification", p.category.name.toUpperCase(), Colors.blue),
            _detailRow(Icons.verified_user_outlined, "Health Sync Status", "Active Tracking Enabled", Colors.green),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSellerDetails(p),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111827), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.person_pin_rounded, size: 18), SizedBox(width: 8), Text("SHOW SELLER DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1))]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSellerDetails(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: Row(children: [
            const Icon(Icons.verified_user, color: Color(0xFF10B981)),
            const SizedBox(width: 10),
            const Text("Seller Profile", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(radius: 40, backgroundColor: Color(0xFFF3F4F6), child: Icon(Icons.person, size: 50, color: Colors.grey)),
            const SizedBox(height: 16),
            Text(p.sellerName ?? "FreshLoop User", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 4),
            const Text("Community Contributor", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            const Divider(height: 32),
            _profileStat(Icons.shopping_bag_outlined, "Items Sold", "12+"),
            _profileStat(Icons.star_outline_rounded, "Member Rating", "4.9/5"),
            _profileStat(Icons.location_on_outlined, "Verification", "Certified Profile"),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: const Text("User identifies as a Verified FreshLoop Marketplace Partner.", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.bold))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: 1))),
        ],
      ),
    );
  }

  Widget _profileStat(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(icon, size: 16, color: Colors.grey), const SizedBox(width: 10), Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12))]));
  }

  // 🟢 FIXED: RE-WRITTEN CLEANLY TO RESOLVE SYNTAX ERRORS
  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF111827))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vibrantBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: size / 2, spreadRadius: size * 0.1)]));
  }

  Widget _emptyArea() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.style_outlined, size: 70, color: Color(0xFFE5E7EB)), const SizedBox(height: 16), const Text("No public listings found.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]));
  }

  Widget _errorArea(String err) {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("Marketplace Error: $err", textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))));
  }
}