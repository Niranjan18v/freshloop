import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../services/firestore_service.dart';
import 'edit_product_screen.dart';

/// Clean, high-performance Product Detail Screen.
/// Upgraded to display transactional data like 'Sold Date' and 'Listing Price'.
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const ProductDetailScreen({super.key, required this.data, required this.docId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _db = FirestoreService();

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to remove this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteProduct(widget.docId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📅 DATE PARSING
    final rawExpiry = widget.data['expiryDate'] ?? widget.data['expiry'];
    final rawSold = widget.data['soldDate'];
    final rawPurchased = widget.data['purchasedDate'];
    
    String displayExpiry = 'N/A';
    if (rawExpiry is Timestamp) displayExpiry = DateFormat('dd MMM yyyy').format(rawExpiry.toDate());
    else if (rawExpiry is String) displayExpiry = rawExpiry;

    String? displaySold;
    if (rawSold is Timestamp) displaySold = DateFormat('dd MMM yyyy').format(rawSold.toDate());

    String displayPurchased = 'N/A';
    if (rawPurchased is Timestamp) displayPurchased = DateFormat('dd MMM yyyy').format(rawPurchased.toDate());

    final name = widget.data['name'] ?? 'Unknown Item';
    final store = widget.data['store'] ?? 'Supermarket';
    final status = widget.data['status'] ?? 'active';
    final listingPrice = widget.data['listingPrice'] != null ? "₹${widget.data['listingPrice']}" : null;

    final isSold = status == 'sold';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 🏷️ STATUS BADGE
            if (status != 'active')
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: isSold ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(30)),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                  ),
                ),
              ),

            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)))),
                      Icon(isSold ? Icons.check_circle_rounded : Icons.inventory_2_outlined, color: isSold ? Colors.green : const Color(0xFF10B981), size: 30),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Source: $store", style: const TextStyle(fontSize: 15, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 32),
                  
                  if (displaySold != null) ...[
                    _detailRow(Icons.verified_outlined, "Sold Date", displaySold, Colors.green),
                    const Divider(height: 32, thickness: 0.5),
                  ],
                  
                  if (listingPrice != null && status == 'selling') ...[
                    _detailRow(Icons.sell_outlined, "Listing Price", listingPrice, Colors.green),
                    const Divider(height: 32, thickness: 0.5),
                  ],

                  _detailRow(Icons.calendar_month_rounded, "Expiry Date", displayExpiry, Colors.orange),
                  const Divider(height: 32, thickness: 0.5),
                  _detailRow(Icons.shopping_basket_outlined, "Purchased On", displayPurchased, Colors.blueGrey),
                  const Divider(height: 32, thickness: 0.5),
                  _detailRow(Icons.currency_rupee_rounded, "Original Price", "₹${widget.data['price']}", Colors.blue),
                  const Divider(height: 32, thickness: 0.5),
                  _detailRow(Icons.qr_code_scanner_rounded, "Barcode", widget.data['barcode'] ?? "None", Colors.purple),
                  
                  const SizedBox(height: 40),
                  
                  if (!isSold)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(initialData: widget.data, docId: widget.docId))),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1F2937),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("Edit Item", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        onPressed: _deleteProduct, 
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                        style: IconButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), padding: const EdgeInsets.all(16)),
                      ),
                    ],
                  )
                  else
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _deleteProduct,
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: const Text("Delete Record", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 32), side: BorderSide(color: Colors.redAccent.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF374151))),
          ],
        ),
      ],
    );
  }
}
