import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';

/// Premium Marketplace with Synchronized Dynamic Pricing Displays.
class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final FirestoreService _db = FirestoreService();
  int selectedTab = 0; 

  int _getDaysLeft(DateTime expiryDate) {
    final today = DateTime.now();
    return expiryDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  Color _getUrgencyColor(int days) {
    if (days <= 4) return Colors.redAccent;
    if (days <= 11) return Colors.orange;
    if (days <= 21) return Colors.amber;
    return const Color(0xFF10B981);
  }

  // 🏁 THE SALE MIGRATION TRANSACTION ──────────────────────────────
  Future<void> _processSale(Product p) async {
    final lp = double.tryParse(p.listingPrice.toString()) ?? (double.tryParse(p.price.toString()) ?? 0.0);
    try {
      await _db.finalizeSale(p, lp);
      if (mounted) {
        setState(() => selectedTab = 2);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(elevation: 10, behavior: SnackBarBehavior.floating, backgroundColor: Colors.black, content: Text('🎉 SUCCESS: Item moved to history.', style: TextStyle(fontWeight: FontWeight.bold))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase Error: $e')));
    }
  }

  Future<void> _processDonate(Product p) async {
    await _db.finalizeDonation(p);
    if (mounted) {
      setState(() => selectedTab = 2);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF3B82F6), content: Text('🤝 Success! Item moved to donation history.')));
    }
  }

  // 💰 DYNAMIC PRICING ENGINE (EXPIRY-BASED)
  Future<void> _processListing(Product p) async {
    final days = _getDaysLeft(p.expiryDate);
    final original = double.tryParse(p.price.toString()) ?? 0.0;
    
    double discount = 0.0;
    if (days < 4) discount = 0.40;
    else if (days < 11) discount = 0.30;
    else if (days < 16) discount = 0.20;
    else if (days < 21) discount = 0.10;
    else discount = 0.05;

    final maxPrice = original * (1 - discount);
    final controller = TextEditingController(text: maxPrice.toStringAsFixed(2));

    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Confirm Listing Price", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text("${(discount * 100).toInt()}% Minimum Discount Applied", style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
      ]),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(prefixText: "₹ ", labelText: "Listing Price (Max ₹${maxPrice.toStringAsFixed(2)})")),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            final val = double.tryParse(controller.text) ?? 0.0;
            if (val > (maxPrice + 0.01)) return; 
            Navigator.pop(ctx, true);
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
          child: const Text("List Now"),
        ),
      ],
    ));

    if (confirmed == true) {
      await _db.updateProduct(p.id, { 'status': 'selling', 'listingPrice': double.tryParse(controller.text) ?? 0.0 });
      if (mounted) setState(() => selectedTab = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.white,
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
                    "Marketplace Info",
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF111827), 
                      fontSize: 22,
                      letterSpacing: -0.5,
                    )
                  ),
                  Text("Manage Listings & Sales", style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _compactTab("AVAILABLE", 0),
                  _compactTab("LISTED", 1),
                  _compactTab("HISTORY", 2),
                ],
              ),
            ),
          ),

          if (selectedTab == 2)
            SliverToBoxAdapter(child: _buildFinancialHeader()),

          StreamBuilder<List<Product>>(
            key: ValueKey("SyncStream_vprice_$selectedTab"),
            stream: selectedTab == 0 ? _db.streamActiveProducts() : (selectedTab == 1 ? _db.streamMarketplaceListing() : _db.streamSoldHistory()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
              
              final products = snapshot.data ?? [];
              List<Product> items = [];
              if (selectedTab == 0) items = products.where((p) => _getDaysLeft(p.expiryDate) < 28 && p.status != ProductStatus.selling && p.status != ProductStatus.donated).toList();
              else if (selectedTab == 2) items = products..sort((a,b) => (b.soldDate ?? DateTime.now()).compareTo(a.soldDate ?? DateTime.now()));
              else items = products;

              if (items.isEmpty) return SliverFillRemaining(child: _blankState());

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final p = items[i];
                      if (selectedTab == 2) {
                        return Dismissible(
                          key: Key(p.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) => _db.deleteSoldRecord(p.id),
                          background: Container(margin: const EdgeInsets.only(bottom: 12), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.delete_outline, color: Colors.white, size: 24)),
                          child: _compactLifecycleCard(p),
                        );
                      }
                      return _compactLifecycleCard(p);
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHeader() {
    return StreamBuilder<List<Product>>(
      stream: _db.streamSoldHistory(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        double totalRevenue = 0.0;
        int totalDonated = 0;
        
        for (var p in products) {
          if (p.status == ProductStatus.donated) {
            totalDonated++;
          } else {
            totalRevenue += (double.tryParse(p.listingPrice.toString()) ?? 0.0);
          }
        }
        
        return Container(
          margin: const EdgeInsets.all(16), 
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF111827), Color(0xFF374151)]), borderRadius: BorderRadius.circular(24)), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text("TOTAL REVENUE", style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)), 
                  const SizedBox(height: 4), 
                  Text("₹${totalRevenue.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))
                ]
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text("TOTAL DONATIONS", style: TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)), 
                  const SizedBox(height: 4), 
                  Text("$totalDonated Items", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))
                ]
              ),
            ]
          )
        );
      },
    );
  }

  Widget _compactLifecycleCard(Product p) {
    final isHistory = selectedTab == 2;
    final isDonated = p.status == ProductStatus.donated;
    final isSold = p.status == ProductStatus.sold;
    final isListedForSale = p.status == ProductStatus.selling;
    
    final days = _getDaysLeft(p.expiryDate);
    final urgencyColor = _getUrgencyColor(days);
    
    // 🎨 RESPECTFUL COLORS FOR DONATION
    final cardBg = isDonated 
        ? const Color(0xFFEFF6FF) 
        : (isSold ? Colors.white : urgencyColor.withOpacity(0.05));
    
    final accentColor = isDonated ? const Color(0xFF3B82F6) : urgencyColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(
          color: isDonated 
              ? const Color(0xFFBFDBFE) 
              : accentColor.withOpacity(isHistory ? 0.0 : 0.2),
          width: isDonated ? 1.5 : 1.0,
        )
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        p.name, 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827))
                      )
                    ),
                    if (!isHistory) 
                       Text("$days days left", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 9)),
                    if (isDonated)
                       const Icon(Icons.handshake_rounded, color: Color(0xFF3B82F6), size: 16),
                  ],
                ),
                Text(p.store, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(
                          isDonated ? "GIFTED & DONATED" : (isSold ? "SALE PRICE" : (isListedForSale ? "LISTED PRICE" : "ORIGINAL VALUE")), 
                          style: TextStyle(
                            color: isDonated ? const Color(0xFF3B82F6) : Colors.grey, 
                            fontSize: 8, 
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          )
                        ),
                        Text(
                          isDonated ? "Impact Item" : "₹${(isSold || isListedForSale) ? p.listingPrice : p.price}", 
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 15, 
                            color: isDonated ? const Color(0xFF1D4ED8) : const Color(0xFF111827)
                          )
                        ),
                      ]
                    ),
                    if (isHistory && p.soldDate != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        children: [
                          Text(isDonated ? "DONATED ON" : "SELL DATE", style: const TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900)),
                          Text(DateFormat('dd MMM').format(p.soldDate!), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111827))),
                        ]
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          if (!isHistory)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Row(
                children: [
                   if (p.status == ProductStatus.active) ...[
                    Expanded(child: ElevatedButton(onPressed: () => _processListing(p), style: ElevatedButton.styleFrom(backgroundColor: urgencyColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text("SELL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(onPressed: () => _processDonate(p), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text("DONATE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)))),
                  ] else ...[
                    Expanded(child: ElevatedButton(onPressed: () => _processSale(p), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111827), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text("MARK SOLD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)))),
                    const SizedBox(width: 8),
                    Expanded(child: ElevatedButton(onPressed: () => _processDonate(p), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text("DONATE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)))),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactTab(String label, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => selectedTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.8,
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blankState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text("No Items Found", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14))]));
  }
}