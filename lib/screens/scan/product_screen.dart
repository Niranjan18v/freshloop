import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'scan_controller.dart';

/// Displays the product details returned after a successful barcode scan.
/// Allows for real-time editing of the product name if it was not found,
/// as well as adding an expiry date and saving to Firestore.
class ProductScreen extends StatefulWidget {
  final ScanResult result;

  const ProductScreen({super.key, required this.result});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late TextEditingController _nameController;
  final TextEditingController _expiryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.result.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  Future<void> _saveToFirestore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text.trim(),
        'price': widget.result.price,
        'barcode': widget.result.barcode,
        'expiryDate': _expiryController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to home screen
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the product was explicitly "Not Found"
    final bool isProductNotFound = widget.result.name == 'Product Not Found';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Icon ────────────────────────────────────────────────
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: Color(0xFF5D8064),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Detail Card ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Product Name (Editable if NOT FOUND) ──────────────────
                    if (isProductNotFound)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name *',
                          labelStyle: TextStyle(color: Color(0xFF5D8064)),
                          prefixIcon: Icon(Icons.label_outline, size: 20),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => 
                            (value == null || value.isEmpty) ? 'Please enter a name' : null,
                      )
                    else
                      _DetailRow(
                        icon: Icons.label_outline,
                        label: 'Product Name',
                        value: widget.result.name,
                      ),

                    const SizedBox(height: 24),

                    // ── Expiry Date Input ─────────────────────────────────────
                    TextFormField(
                      controller: _expiryController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date *',
                        hintText: 'Select Date',
                        labelStyle: TextStyle(color: Color(0xFF5D8064)),
                        prefixIcon: Icon(Icons.calendar_today, size: 20),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null) {
                          setState(() {
                            _expiryController.text = 
                                "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                          });
                        }
                      },
                      validator: (value) => 
                          (value == null || value.isEmpty) ? 'Expiry date is required' : null,
                    ),

                    const Divider(height: 48),

                    _DetailRow(
                      icon: Icons.currency_rupee,
                      label: 'Price',
                      value: widget.result.price,
                    ),
                    const Divider(height: 28),
                    _DetailRow(
                      icon: Icons.qr_code,
                      label: 'Barcode',
                      value: widget.result.barcode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Save Action Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveToFirestore,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 18, 
                          height: 18, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D8064),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private Helper Widget ────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5D8064)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
