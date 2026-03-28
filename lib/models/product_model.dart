import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Supported item categories.
enum ProductCategory { grocery, dairy, snacks, meat, vegetables, drinks, other }

/// Supported product states for the marketplace lifecycle.
enum ProductStatus { active, selling, donated, sold }

/// A structured model for a grocery product.
/// Enhanced with seller identification for the Public Marketplace.
class Product {
  final String id;
  final String name;
  final String barcode;
  final dynamic price; 
  final DateTime expiryDate;
  final DateTime purchasedDate;
  final ProductCategory category;
  final String store;
  final String imageUrl;
  final DateTime createdAt;
  
  final ProductStatus status;
  final dynamic listingPrice;
  final DateTime? soldDate;

  // 🌍 SELLER IDENTIFICATION (FOR PUBLIC MARKETPLACE)
  final String? sellerId;
  final String? sellerName;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.expiryDate,
    DateTime? purchasedDate,
    this.category = ProductCategory.grocery,
    this.store = 'Unknown Store',
    this.imageUrl = '',
    DateTime? createdAt,
    this.status = ProductStatus.active,
    this.listingPrice = 0.0,
    this.soldDate,
    this.sellerId,
    this.sellerName,
  })  : purchasedDate = purchasedDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  String get expiryDateString => DateFormat('dd/MM/yyyy').format(expiryDate);
  String get purchasedDateString => DateFormat('dd/MM/yyyy').format(purchasedDate);

  factory Product.fromSnapshot(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      
      // 📅 EXPIRY
      final rawExpiry = data['expiryDate'] ?? data['expiry'];
      DateTime parsedExpiry = DateTime.now();
      if (rawExpiry is Timestamp) parsedExpiry = rawExpiry.toDate();
      else if (rawExpiry is String) {
        try {
          if (rawExpiry.contains('-')) parsedExpiry = DateTime.parse(rawExpiry);
          else if (rawExpiry.contains('/')) {
            final p = rawExpiry.split('/');
            parsedExpiry = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
          }
        } catch (_) {}
      }

      // 📅 PURCHASED
      final rawPurchased = data['purchasedDate'];
      DateTime parsedPurchased = DateTime.now();
      if (rawPurchased is Timestamp) parsedPurchased = rawPurchased.toDate();

      // 🏷️ STATUS
      final String? st = data['status'];
      final ProductStatus status = ProductStatus.values.firstWhere(
        (e) => e.name == st, orElse: () => ProductStatus.active
      );

      // 💰 PRICES
      final rawListing = data['listingPrice'];
      
      // 📅 SOLD DATE
      DateTime? soldDate;
      final rawSold = data['soldDate'];
      if (rawSold is Timestamp) soldDate = rawSold.toDate();

      return Product(
        id: doc.id,
        name: data['name'] ?? 'Unknown Item',
        barcode: data['barcode'] ?? '',
        price: data['price'] ?? 0.0,
        expiryDate: parsedExpiry,
        purchasedDate: parsedPurchased,
        category: _parseCategory(data['category']),
        store: data['store'] ?? 'Supermarket',
        imageUrl: data['imageUrl'] ?? '',
        createdAt: (data['createdAt'] is Timestamp) ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
        status: status,
        listingPrice: rawListing ?? 0.0,
        soldDate: soldDate,
        sellerId: data['sellerId'],
        sellerName: data['sellerName'],
      );
    } catch (e) {
      return Product(id: doc.id, name: "Error Loading Item", barcode: "", price: 0, expiryDate: DateTime.now());
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'purchasedDate': Timestamp.fromDate(purchasedDate),
      'category': category.name,
      'store': store,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'status': status.name,
      'listingPrice': listingPrice,
      'soldDate': soldDate != null ? Timestamp.fromDate(soldDate!) : null,
      'sellerId': sellerId,
      'sellerName': sellerName,
    };
  }

  static ProductCategory _parseCategory(String? cat) {
    if (cat == null) return ProductCategory.grocery;
    return ProductCategory.values.firstWhere((e) => e.name == cat.toLowerCase(), orElse: () => ProductCategory.grocery);
  }
}
