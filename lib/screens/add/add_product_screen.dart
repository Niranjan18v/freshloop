import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_textfield.dart';
import '../scan/scan_screen.dart';

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

  DateTime? selectedDate;

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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: const Color.fromARGB(255, 224, 230, 228),
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

        
            Row(
              children: const [
                CircleAvatar(
                  backgroundColor: Color(0xffE8F5E9),
                  child: Icon(Icons.inventory, color: AppColors.primary),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Add Product",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Manually add a product to your inventory",
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),

            const SizedBox(height: 20),

          
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [

                  // Barcode scan row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: "Barcode",
                          hint: "Tap scan icon or enter manually",
                          controller: barcodeController,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Scan Barcode',
                        icon: const Icon(Icons.qr_code_scanner,
                            color: AppColors.primary),
                        onPressed: _scanBarcode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  CustomTextField(
                    label: "Product Name *",
                    hint: "e.g. Amul Milk 1L",
                    controller: nameController,
                  ),

                  const SizedBox(height: 14),

                  CustomTextField(
                    label: "Price (₹) *",
                    hint: "0",
                    controller: priceController,
                    keyboard: TextInputType.number,
                  ),

                  const SizedBox(height: 14),

                  CustomTextField(
                    label: "Store Name",
                    hint: "e.g. D-Mart, Andheri",
                    controller: storeController,
                  ),

                  const SizedBox(height: 14),

                  // 📅 DATE PICKER
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Expiry Date *",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),

                      GestureDetector(
                        onTap: pickDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xffF4F6F8),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 10),
                              Text(
                                selectedDate == null
                                    ? "Pick expiry date"
                                    : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                style: const TextStyle(color: Colors.grey),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        
                      },
                      child: const Text("Add to Inventory"),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}