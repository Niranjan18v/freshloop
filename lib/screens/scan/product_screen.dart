import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import 'scan_controller.dart';

/// The final landing screen after a successful scan.
/// Updated to parse string dates into Timestamps for Firestore.
class ProductScreen extends StatefulWidget {
  final ScanResult result;

  const ProductScreen({super.key, required this.result});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _expiryCtrl;
  ProductCategory _selectedCategory = ProductCategory.grocery;

  final FirestoreService _db = FirestoreService();
  final NotificationService _notifications = NotificationService();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.result.name);
    _priceCtrl = TextEditingController(text: widget.result.price.toString());
    _expiryCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  // ── 🛡️ PRODUCTION SAVE LOGIC: Timestamp Conversion ────────────────────────
  Future<void> _saveProduct() async {
    if (_nameCtrl.text.isEmpty || _expiryCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    // Attempt to parse the date string (format: d/M/yyyy) into a DateTime object
    DateTime? parsedExpiry;
    try {
      parsedExpiry = DateFormat("d/M/yyyy").parseStrict(_expiryCtrl.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Invalid date format. Use DD/MM/YYYY.'))
      );
      return;
    }

    final product = Product(
      id: '', // Firestore auto-generates
      name: _nameCtrl.text.trim(),
      barcode: widget.result.barcode,
      price: double.tryParse(_priceCtrl.text) ?? _priceCtrl.text.trim(),
      expiryDate: parsedExpiry, // Passing DateTime; model handles Timestamp conversion
      category: _selectedCategory,
    );

    try {
      await _db.saveProduct(product);
      await _notifications.notifyOnSave(product);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Product added correctly with Timestamp!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Add to Inventory')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: const Color(0xFF5D8064).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.inventory_2_rounded, size: 60, color: Color(0xFF5D8064))),
            const SizedBox(height: 32),
            _buildField(controller: _nameCtrl, label: 'Product Name', icon: Icons.shopping_basket),
            const SizedBox(height: 16),
            _buildField(controller: _priceCtrl, label: 'Price (₹)', icon: Icons.currency_rupee),
            const SizedBox(height: 16),
            _buildField(
              controller: _expiryCtrl,
              label: 'Expiry Date (DD/MM/YYYY)',
              icon: Icons.calendar_month,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, 
                  initialDate: DateTime.now(), 
                  firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                  lastDate: DateTime(2030)
                );
                if (picked != null) setState(() => _expiryCtrl.text = "${picked.day}/${picked.month}/${picked.year}");
              },
            ),
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D8064), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: _saveProduct,
              child: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool readOnly = false, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF5D8064)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }
}
