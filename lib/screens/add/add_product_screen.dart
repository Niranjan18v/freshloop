import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 🟢 FIXED: Required for DateFormat
import '../../core/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/custom_textfield.dart';
import '../scan/scan_screen.dart';

/// Screen to manually add products to the inventory database.
/// features a Premium Scanner Option and manual entry fallback.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final storeController = TextEditingController();
  final barcodeController = TextEditingController();
  
  final FirestoreService _db = FirestoreService();
  final NotificationService _notifications = NotificationService();

  DateTime? selectedDate;
  bool isLoading = false;

  Future<void> _scanBarcode() async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => barcodeController.text = result);
    }
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ── 🛡️ SAVE PRODUCT LOGIC ───────────────────────────────────────────
  Future<void> _handleSave() async {
    if (nameController.text.trim().isEmpty || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter product name and expiry date.")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final product = Product(
        id: "", 
        name: nameController.text.trim(),
        barcode: barcodeController.text.trim(),
        price: double.tryParse(priceController.text) ?? 0.0,
        expiryDate: selectedDate!,
        createdAt: DateTime.now(),
      );

      await _db.saveProduct(product);
      await _notifications.notifyOnSave(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text("Item added successfully!")),
        );
        nameController.clear();
        priceController.clear();
        barcodeController.clear();
        storeController.clear();
        setState(() => selectedDate = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text("Failed to save: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Stock Inventory", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // 🏮 PREMIUM SCANNER OPTION
            GestureDetector(
              onTap: _scanBarcode,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5D8064), Color(0xFF4A6851)]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: const Color(0xFF5D8064).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 40)),
                    const SizedBox(height: 16),
                    const Text("QUICK SCANNER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text("Auto-detect product details instantly", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // 📝 MANUAL ENTRY FORM
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 25, offset: const Offset(0, 8))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.edit_note_rounded, color: Colors.grey, size: 20), SizedBox(width: 8), Text("Manual Entry Form", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.grey))]),
                  const SizedBox(height: 24),
                  
                  CustomTextField(label: "Product Title*", hint: "e.g. Greek Yogurt", controller: nameController),
                  const SizedBox(height: 18),
                  
                  CustomTextField(label: "Barcode Value", hint: "Manually enter or Scan", controller: barcodeController),
                  const SizedBox(height: 18),
                  
                  Row(
                    children: [
                      Expanded(child: CustomTextField(label: "Price (₹)", hint: "0.00", controller: priceController, keyboard: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomTextField(label: "Store", hint: "Optional", controller: storeController)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text("Shelf Life Expiry", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  
                  GestureDetector(
                    onTap: pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: selectedDate != null ? const Color(0xFF5D8064).withOpacity(0.2) : Colors.black12)),
                      child: Row(
                        children: [
                          Icon(Icons.event_available_rounded, size: 20, color: selectedDate != null ? const Color(0xFF5D8064) : Colors.grey),
                          const SizedBox(width: 12),
                          Text(selectedDate == null ? "Set Expiry Date*" : DateFormat('dd MMM yyyy').format(selectedDate!), style: TextStyle(color: selectedDate != null ? Colors.black : Colors.grey, fontWeight: FontWeight.w900, fontSize: 14)),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D8064), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 12, shadowColor: const Color(0xFF5D8064).withOpacity(0.3)),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE TO PANTRY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
}