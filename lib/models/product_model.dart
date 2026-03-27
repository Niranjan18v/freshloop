import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Supported item categories in the FreshLoop ecosystem.
enum ProductCategory {
  grocery,
  dairy,
  snacks,
  meat,
  vegetables,
  drinks,
  other
}

/// A structured model for a grocery product.
/// Refactored to include 'doc.id' and store 'expiryDate' as Firestore Timestamp.
class Product {
  final String id;
  final String name;
  final String barcode;
  final dynamic price; 
  final DateTime expiryDate; // Stored as Timestamp in Firestore for optimal sorting/querying
  final ProductCategory category;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.expiryDate,
    this.category = ProductCategory.grocery,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper to get string version for UI (DD/MM/YYYY)
  String get expiryDateString => DateFormat('dd/MM/yyyy').format(expiryDate);

  // Convert Firestore Snapshot to Product
  factory Product.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // ── 📅 HYBRID EXPIRY PARSING ──────────────────────────────────────────
    // Supports both legacy 'String' dates and new 'Timestamp' fields.
    final rawExpiry = data['expiryDate'] ?? data['expiry'];
    DateTime parsedExpiry = DateTime.now();

    if (rawExpiry is Timestamp) {
      parsedExpiry = rawExpiry.toDate();
    } else if (rawExpiry is String) {
      try {
        if (rawExpiry.contains('-')) {
          parsedExpiry = DateTime.parse(rawExpiry);
        } else if (rawExpiry.contains('/')) {
          final parts = rawExpiry.split('/');
          parsedExpiry = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      } catch (_) {}
    }

    // ── 🛡️ SAFE PRICE PARSING ──────────────────────────────────────────────
    final rawPrice = data['price'];
    dynamic parsedPrice = 'N/A';
    if (rawPrice != null) {
      if (rawPrice is num) { parsedPrice = rawPrice; } 
      else if (rawPrice is String && rawPrice.isNotEmpty) { parsedPrice = rawPrice; }
    }

    return Product(
      id: doc.id, // Correctly including Firestore Document ID
      name: data['name'] ?? 'Unknown',
      barcode: data['barcode'] ?? '',
      price: parsedPrice,
      expiryDate: parsedExpiry,
      category: _parseCategory(data['category']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert Product to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'expiryDate': Timestamp.fromDate(expiryDate), // Persist as Timestamp for optimal performance
      'category': category.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static ProductCategory _parseCategory(String? cat) {
    if (cat == null) return ProductCategory.grocery;
    return ProductCategory.values.firstWhere(
      (e) => e.name == cat.toLowerCase(),
      orElse: () => ProductCategory.grocery,
    );
  }
}
