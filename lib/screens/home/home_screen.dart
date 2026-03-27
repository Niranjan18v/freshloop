import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/profile_screen.dart';
import '../products/products_screen.dart';
import '../shop/shop_screen.dart';
import '../products/product_detail_screen.dart';
import '../../widgets/notification_icon.dart';

/// The Home Screen: showing a preview of inventory (3 urgent, 4 fresh).
/// Upgraded with 'Safe Date Handling' to prevent crashes during Timestamp migration.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _controller = PageController();
  int currentPage = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      currentPage = (currentPage + 1) % 3;
      _controller.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── 🛡️ SAFE DATE CONVERSION FUNCTION ──────────────────────────────────────
  /// Safely converts dynamic Firestore data (String or Timestamp) into days left.
  /// Prevents: type 'Timestamp' is not a subtype of type 'String?' crashes.
  int _getDaysLeft(dynamic expiry) {
    if (expiry == null) return 999;
    
    DateTime? expiryDate;

    if (expiry is Timestamp) {
      expiryDate = expiry.toDate();
    } else if (expiry is String && expiry.isNotEmpty) {
      try {
        if (expiry.contains('/')) {
          final parts = expiry.split('/');
          expiryDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          expiryDate = DateTime.parse(expiry);
        }
      } catch (_) { return 999; }
    }

    if (expiryDate == null) return 999;

    final today = DateTime.now();
    return expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // ── 🏷️ THE CAPSULE HEADER ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4E9E6),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: Color(0xFF5D8064), size: 28),
                      const SizedBox(width: 10),
                      const Text("FRESHLOOP", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black, letterSpacing: 0.5)),
                      const Spacer(),
                      const NotificationIcon(),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFF2D3436), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => currentPage = i),
                  children: [
                    _slideCard("Your Products", "Manage inventory", "assets/images/products.png", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()))),
                    _slideCard("Shop Deals", "Buy discounted items", "assets/images/sales.png", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()))),
                    _slideCard("Expiring Soon", "Use items before waste", "assets/images/expiring_soon.png", () {}),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: currentPage == i ? 18 : 8,
                  decoration: BoxDecoration(color: currentPage == i ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
                )),
              ),

              const SizedBox(height: 14),

              _sectionHeader("⏰ Expiring Soon"),
              _streamedInventory(true, 3),

              const SizedBox(height: 14),

              _sectionHeader("🟢 Fresh Products"),
              _streamedInventory(false, 4),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D8064),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen())),
                    child: const Text("Show More", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2D3436))),
      ),
    );
  }

  Widget _streamedInventory(bool isUrgent, int limit) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final List<Map<String, dynamic>> allProducts = snapshot.data!.docs.map((doc) => {
          'id': doc.id,
          'data': doc.data() as Map<String, dynamic>
        }).toList();

        final List<Map<String, dynamic>> filteredList = allProducts.where((p) {
          final Map<String, dynamic> data = p['data'] as Map<String, dynamic>;
          final days = _getDaysLeft(data['expiryDate'] ?? data['expiry']);
          return isUrgent ? (days <= 3) : (days > 3);
        }).toList();

        filteredList.sort((a, b) {
          final daysA = _getDaysLeft((a['data'] as Map<String, dynamic>)['expiryDate'] ?? (a['data'] as Map<String, dynamic>)['expiry']);
          final daysB = _getDaysLeft((b['data'] as Map<String, dynamic>)['expiryDate'] ?? (b['data'] as Map<String, dynamic>)['expiry']);
          return daysA.compareTo(daysB);
        });

        final List<Map<String, dynamic>> resultList = filteredList.take(limit).toList();

        if (resultList.isEmpty) return const SizedBox.shrink();

        return Column(
          children: resultList.map((p) => _productCard(p['id'].toString(), p['data'] as Map<String, dynamic>, isUrgent)).toList(),
        );
      },
    );
  }

  Widget _productCard(String id, Map<String, dynamic> data, bool isUrgent) {
    final days = _getDaysLeft(data['expiryDate'] ?? data['expiry']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(data: data, docId: id))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 60, height: 60,
                color: (isUrgent ? Colors.red : Colors.green).withOpacity(0.08),
                child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(days <= 0 ? "Expired" : "$days days left", style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isUrgent ? Colors.redAccent : Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _slideCard(String title, String subtitle, String img, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.grey.shade300,
          image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Colors.black54, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}