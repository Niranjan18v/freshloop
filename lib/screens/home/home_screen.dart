import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Added for Haptics
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/profile_screen.dart';
import '../products/products_screen.dart';
import '../shop/shop_screen.dart';
import '../add/add_product_screen.dart'; 
import '../products/product_detail_screen.dart';
import '../../widgets/notification_icon.dart';

/// FreshLoop Home: Redesigned with restored high-fidelity Image Slides.
/// features Elegant Empty States for a complete, professional dashboard.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _controller = PageController(viewportFraction: 0.9);
  int currentPage = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_controller.hasClients) {
        currentPage = (currentPage + 1) % 3;
        _controller.animateToPage(currentPage, duration: const Duration(milliseconds: 1000), curve: Curves.fastOutSlowIn);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int _getDaysLeft(dynamic expiry) {
    if (expiry == null) return 999;
    DateTime? expiryDate;
    if (expiry is Timestamp) expiryDate = expiry.toDate();
    else if (expiry is String && expiry.isNotEmpty) {
      try {
        if (expiry.contains('/')) {
          final p = expiry.split('/');
          expiryDate = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        } else expiryDate = DateTime.parse(expiry);
      } catch (_) { return 999; }
    }
    if (expiryDate == null) return 999;
    final today = DateTime.now();
    return expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: _vibrantBlob(300, const Color(0xFF10B981).withOpacity(0.08))),
          Positioned(bottom: 100, left: -80, child: _vibrantBlob(250, const Color(0xFFf59e0b).withOpacity(0.05))),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF111827).withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF10B981), Color(0xFF047857)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "FreshLoop",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: -0.5,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              "Pantry Intelligence",
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const NotificationIcon(),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), 
                          child: Hero(
                            tag: 'profile_avatar_main', 
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                              builder: (context, snapshot) {
                                String? b64Image;
                                if (snapshot.hasData && snapshot.data!.exists) {
                                  final data = snapshot.data!.data() as Map<String, dynamic>;
                                  b64Image = data['profileImage'];
                                }
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFF3F4F6), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 22, 
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    backgroundImage: b64Image != null ? MemoryImage(base64Decode(b64Image)) : null,
                                    child: b64Image == null ? const Icon(Icons.person_rounded, color: Color(0xFF9CA3AF)) : null,
                                  ),
                                );
                              }
                            )
                          )
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => currentPage = i),
                    children: [
                      _restoredSlide("Your Products", "Manage inventory", "assets/images/products.png", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
                      _restoredSlide("Shop Deals", "Buy discounted items", "assets/images/sales.png", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
                      _restoredSlide("Expiring Soon", "Use items before waste", "assets/images/expiring_soon.png", () {}),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              _sliverHeader("CRITICAL ATTENTION", Icons.bolt_rounded, Colors.redAccent),
              _streamedSliverInventory(true, 3),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              _sliverHeader("FRESH INVENTORY", Icons.eco_outlined, Colors.green),
              _streamedSliverInventory(false, 4),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111827), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                    child: const Text("ACCESS FULL PANTRY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _restoredSlide(String title, String subtitle, String imgPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), image: DecorationImage(image: AssetImage(imgPath), fit: BoxFit.cover), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)), Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }

  Widget _streamedSliverInventory(bool isUrgent, int limit) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final List<Map<String, dynamic>> products = snapshot.data!.docs.map((doc) => {'id': doc.id, 'data': doc.data() as Map<String, dynamic>}).toList();
        final filtered = products.where((p) {
          final data = p['data'] as Map<String, dynamic>;
          final status = data['status'] ?? 'active';
          if (status != 'active' && status != 'selling') return false;
          final d = _getDaysLeft(data['expiryDate'] ?? data['expiry']);
          return isUrgent ? (d <= 3) : (d > 3);
        }).toList()..sort((a,b) => _getDaysLeft(a['data']['expiryDate'] ?? a['data']['expiry']).compareTo(_getDaysLeft(b['data']['expiryDate'] ?? b['data']['expiry'])));
        
        final result = filtered.take(limit).toList();

        // 🟢 RESTORED: Beautiful Empty State with "ADD" CTA for New Users
        if (result.isEmpty) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(child: _buildEmptySection(isUrgent, products.isEmpty)),
          );
        }

        return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 20), sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) => _craftedProductCard(result[i]['id'], result[i]['data'] as Map<String, dynamic>, isUrgent), childCount: result.length)));
      },
    );
  }

  // ── 🎨 INTELLIGENT EMPTY STATES (NEW USER READY) ─────────────────────
  Widget _buildEmptySection(bool isUrgent, bool isNewAccount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: (isUrgent ? Colors.green : (isNewAccount ? Colors.amber : Colors.grey)).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(isUrgent ? Icons.auto_awesome : (isNewAccount ? Icons.rocket_launch_rounded : Icons.info_outline), color: isUrgent ? Colors.green : (isNewAccount ? Colors.amber : Colors.grey), size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isUrgent ? "Everything is Fresh!" : (isNewAccount ? "Welcome Aboard!" : "Pure Pantry"), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 16)), 
            const SizedBox(height: 2),
            Text(isUrgent ? "No products expiring within 3 days." : (isNewAccount ? "Track your first item to start saving!" : "Add more items to see them here."), style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            
            // 🚀 NEW USER CALL TO ACTION
            if (!isUrgent && isNewAccount)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddProductScreen())),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [Text("TRACK ITEM", style: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 10)]),
                ),
              ),
          ])),
        ],
      ),
    );
  }

  Widget _vibrantBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: size / 2, spreadRadius: size * 0.1)]));
  }

  Widget _sliverHeader(String title, IconData icon, Color color) {
    return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), sliver: SliverToBoxAdapter(child: Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: color, letterSpacing: 1.5))])));
  }

  Widget _craftedProductCard(String id, Map<String, dynamic> data, bool isUrgent) {
    final days = _getDaysLeft(data['expiryDate'] ?? data['expiry']);
    final color = isUrgent ? Colors.redAccent : const Color(0xFF10B981);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))]),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact(); // ✅ Added Haptics
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(data: data, docId: id)));
        },
        child: Row(
          children: [
            Hero( // ✅ Added Hero tag
              tag: 'product_icon_$id',
              child: Container(
                height: 60, width: 60, 
                decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18)), 
                child: Icon(Icons.shopping_bag_outlined, color: color, size: 28)
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))), const SizedBox(height: 4), Text(data['store'] ?? 'Supermarket', style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold))])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(days <= 0 ? "EXPIRED" : "$days DAYS LEFT", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5))),
          ],
        ),
      ),
    );
  }
}