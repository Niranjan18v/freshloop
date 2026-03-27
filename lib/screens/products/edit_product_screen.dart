import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../services/firestore_service.dart';

/// Professional Edit Product screen for modifying inventory items.
/// Upgraded to convert String dates into Firestore Timestamps during save.
class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final String docId;

  const EditProductScreen({super.key, required this.initialData, required this.docId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final FirestoreService _db = FirestoreService();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _expiryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name']);
    _priceController = TextEditingController(text: widget.initialData['price']?.toString());
    
    // ── 🛡️ HYBRID READING LOGIC ──────────────────────────────────────────
    // Handle both new Timestamp objects and legacy String dates from Firestore
    final rawExpiry = widget.initialData['expiryDate'] ?? widget.initialData['expiry'];
    if (rawExpiry is Timestamp) {
      _expiryController = TextEditingController(text: DateFormat('d/M/yyyy').format(rawExpiry.toDate()));
    } else if (rawExpiry is String) {
      _expiryController = TextEditingController(text: rawExpiry);
    } else {
      _expiryController = TextEditingController(text: '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (_nameController.text.isEmpty || _expiryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Expiry are required')));
      return;
    }

    // ── 📅 DATE PARSING & CONVERSION ───────────────────────────────────────
    DateTime? parsedExpiry;
    try {
      parsedExpiry = DateFormat("d/M/yyyy").parseStrict(_expiryController.text.trim());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Invalid date format. Use DD/MM/YYYY.'))
      );
      return;
    }

    try {
      // 🚜 SAVING AS TIMESTAMP
      final updatedData = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? _priceController.text.trim(),
        'expiryDate': Timestamp.fromDate(parsedExpiry), 
      };

      await _db.updateProduct(widget.docId, updatedData);

      if (mounted) {
        Navigator.pop(context); // Go back to detail
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Item updated correctly with Timestamp!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Edit Item", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildField(controller: _nameController, label: "Product Name", icon: Icons.shopping_bag_outlined),
            const SizedBox(height: 16),
            _buildField(controller: _priceController, label: "Price", icon: Icons.currency_rupee, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField(
              controller: _expiryController,
              label: "Expiry Date (DD/MM/YYYY)",
              icon: Icons.calendar_today_rounded,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, 
                  initialDate: DateTime.now(), 
                  firstDate: DateTime.now().subtract(const Duration(days: 365)), 
                  lastDate: DateTime(2030)
                );
                if (picked != null) setState(() => _expiryController.text = "${picked.day}/${picked.month}/${picked.year}");
              }
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D8064),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _updateProduct,
                child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool readOnly = false, VoidCallback? onTap, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black12)),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF5D8064)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      ),
    );
  }
}
