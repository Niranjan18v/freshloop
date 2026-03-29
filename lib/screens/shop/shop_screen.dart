import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                backgroundColor: Colors.white.withOpacity(0.95),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Shop Marketplace",
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: Color(0xFF111827), 
                          fontSize: 22,
                          letterSpacing: -0.5,
                        )
                      ),
                      Text("Community Pantry Hub", style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    children: [
                      _buildFilterChip("ALL", !_isFilterActive, () => setState(() => _isFilterActive = false)),
                      ...ProductCategory.values.map((cat) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: _buildFilterChip(cat.name.toUpperCase(), _isFilterActive && _selectedCategory == cat, () => setState(() { _isFilterActive = true; _selectedCategory = cat; })),
                      )),
                    ],
                  ),
                ),
              ),

              StreamBuilder<List<Product>>(
                stream: _db.streamPublicMarketplace(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981))));
                  if (snapshot.hasError) return SliverFillRemaining(child: _errorArea(snapshot.error.toString()));
                  final products = snapshot.data ?? [];
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final filtered = products.where((p) => 
                    (!_isFilterActive || p.category == _selectedCategory) && 
                    (p.sellerId != currentUserId) // Hide own products from shop
                  ).toList();
                  if (filtered.isEmpty) return SliverFillRemaining(child: _emptyArea());

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, 
                        crossAxisSpacing: 12, 
                        mainAxisSpacing: 12, 
                        childAspectRatio: 0.65
                      ),
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
    return ChoiceChip(
      label: Text(
        label, 
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF6B7280), 
          fontWeight: FontWeight.w800, 
          fontSize: 10,
          letterSpacing: 0.5,
        )
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB)),
      ),
      showCheckmark: false,
    );
  }

  Widget _shopItemCard(Product p) {
    final daysLeft = p.expiryDate.difference(DateTime.now()).inDays;
    final urgencyColor = daysLeft <= 4 ? Colors.redAccent : const Color(0xFF10B981);
    return GestureDetector(
      onTap: () => _showPublicDetails(p),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(28), 
          boxShadow: [
            BoxShadow(color: const Color(0xFF111827).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
          ],
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity, 
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB), 
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), 
                  gradient: LinearGradient(
                    colors: [urgencyColor.withOpacity(0.1), Colors.white], 
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight
                  ),
                ), 
                child: Center(
                  child: Hero(
                    tag: 'shop_icon_${p.id}',
                    child: Icon(Icons.shopping_basket_rounded, size: 48, color: urgencyColor.withOpacity(0.3))
                  )
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                   Text(
                     p.name, 
                     maxLines: 1, 
                     overflow: TextOverflow.ellipsis, 
                     style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827), letterSpacing: -0.5)
                   ),
                   const SizedBox(height: 6),
                   Row(
                     children: [
                       Text("₹${p.listingPrice}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 18)), 
                       const SizedBox(width: 8), 
                       Text("₹${p.price}", style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w800))
                     ]
                   ),
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
                     decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
                     child: Text(
                       daysLeft <= 0 ? "EXPIRED" : "$daysLeft DAYS LEFT", 
                       style: TextStyle(color: urgencyColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)
                     )
                   ),
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       const Icon(Icons.person_rounded, size: 12, color: Color(0xFF9CA3AF)), 
                       const SizedBox(width: 6), 
                       Expanded(
                         child: Text(
                           p.sellerName ?? 'Seller', 
                           maxLines: 1, 
                           overflow: TextOverflow.ellipsis, 
                           style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.w800)
                         )
                       )
                     ]
                   )
                ]
              ),
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
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.vertical(top: Radius.circular(32))
        ),
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)))
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB), 
                borderRadius: BorderRadius.circular(24), 
                border: Border.all(color: const Color(0xFFE5E7EB))
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24, 
                    backgroundColor: Color(0xFF111827), 
                    child: Icon(Icons.person_rounded, color: Colors.white, size: 28)
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(p.sellerName ?? 'Anonymous Seller', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF111827))), 
                        const Text("Verified FreshLoop Member", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5))
                      ]
                    )
                  ),
                  GestureDetector(
                    onTap: () => _showSellerDetails(p), 
                    child: Container(
                      padding: const EdgeInsets.all(14), 
                      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(18)), 
                      child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18)
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Color(0xFF111827), letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("₹${p.listingPrice}", style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 28)), 
                const SizedBox(width: 14), 
                Text("Original: ₹${p.price}", style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w800))
              ]
            ),
            const Divider(height: 48, thickness: 1.5, color: Color(0xFFF3F4F6)),
            _detailRow(Icons.timer_rounded, "Shelf Life Guarantee", "${p.expiryDateString} (${p.expiryDate.difference(DateTime.now()).inDays} Days Left)", Colors.redAccent),
            _detailRow(Icons.storefront_rounded, "Original Sourced From", p.store, Colors.purpleAccent),
            _detailRow(Icons.category_rounded, "Food Classification", p.category.name.toUpperCase(), Colors.blueAccent),
            _detailRow(Icons.verified_user_rounded, "Health Sync Status", "Active Tracking Enabled", const Color(0xFF10B981)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSellerDetails(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF111827), 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(vertical: 22), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: const [
                    Icon(Icons.person_pin_rounded, size: 20), 
                    SizedBox(width: 10), 
                    Text("SHOW SELLER DETAILS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2))
                  ]
                ),
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
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: p.sellerId != null ? FirebaseFirestore.instance.collection('users').doc(p.sellerId).get() : null,
        builder: (context, snapshot) {
          String name = p.sellerName ?? "FreshLoop User";
          String phone = "Not provided";
          String address = "Not provided";
          String? profileImage;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              content: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            name = userData['name'] ?? name;
            phone = userData['phone'] ?? phone;
            address = userData['address'] ?? address;
            profileImage = userData['profileImage'];
          }

          return AlertDialog(
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
                CircleAvatar(
                  radius: 40, 
                  backgroundColor: const Color(0xFFF3F4F6), 
                  backgroundImage: profileImage != null ? MemoryImage(base64Decode(profileImage)) : null,
                  child: profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                const Text("Community Contributor", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                const Divider(height: 32),
                _profileStat(Icons.person_outline, "Name", name),
                _profileStat(Icons.phone_outlined, "Phone Number", phone),
                _profileStat(Icons.location_on_outlined, "Address", address),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: const Text("User identifies as a Verified FreshLoop Marketplace Partner.", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.bold))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: 1))),
            ],
          );
        }
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