import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../services/firestore_service.dart';
import 'edit_product_screen.dart';
import 'dart:developer' as dev;

/// Minimalist Product Details Screen inspired by Notion/Google Fit.
/// Upgraded with verified doc.id management and Timestamp-aware logic.
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const ProductDetailScreen({super.key, required this.data, required this.docId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final FirestoreService _db = FirestoreService();

  // ── 🗑️ DELETE BUSINESS LOGIC (Using Verified doc.id) ───────────────────
  Future<void> _deleteProduct() async {
    // Debug print as requested
    dev.log("── DELETE ATTEMPT ── Product ID: ${widget.docId}");

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Item?"),
        content: const Text("This action cannot be undone. Are you sure you want to remove this product?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteProduct(widget.docId);
        if (mounted) {
          Navigator.pop(context); // Go back to inventory
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product removed from FreshLoop.')));
        }
      } catch (e) {
        dev.log("Delete failed: $e");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── 📅 SAFE DATE DISPLAY ───────────────────────────────────────────
    final rawExpiry = widget.data['expiryDate'] ?? widget.data['expiry'];
    String displayExpiry = 'N/A';
    if (rawExpiry is Timestamp) {
      displayExpiry = DateFormat('dd/MM/yyyy').format(rawExpiry.toDate());
    } else if (rawExpiry is String) {
      displayExpiry = rawExpiry;
    }

    final name = widget.data['name'] ?? 'Unknown Item';
    final category = widget.data['category'] ?? "General";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Item Details", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D3436))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(color: const Color(0xFF5D8064).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.inventory_2_rounded, size: 60, color: Color(0xFF5D8064)),
            ),
            const SizedBox(height: 32),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
            const SizedBox(height: 8),
            Text(category.toString().toUpperCase(), style: const TextStyle(color: Color(0xFF5D8064), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.2)),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _detailTile("EXPIRY DATE", displayExpiry, Icons.calendar_today_rounded),
                  _detailTile("PRICE", "₹${widget.data['price'] ?? '0'}", Icons.currency_rupee_rounded),
                  _detailTile("STATUS", "Locked", Icons.lock_outline_rounded),
                  _detailTile("ID", widget.docId.substring(0, 5), Icons.tag_rounded),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black12)),
                      ),
                      onPressed: () {
                        dev.log("Opening editor for: ${widget.docId}");
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditProductScreen(initialData: widget.data, docId: widget.docId)));
                      },
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _deleteProduct,
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [Icon(icon, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
