import '../../services/product_api.dart';

/// Result model returned by [ScanController].
///
/// [found]   – false when the API signals "product not found" or an error.
/// [name]    – product name, or an error description when [found] is false.
/// [price]   – price string (always "N/A" from OpenFoodFacts).
/// [barcode] – the raw barcode that was scanned.
class ScanResult {
  final bool found;
  final String name;
  final String price;
  final String barcode;

  const ScanResult({
    required this.found,
    required this.name,
    required this.price,
    required this.barcode,
  });
}

/// Controller that takes a barcode, calls [ProductApi], and returns a
/// [ScanResult].  All business logic lives here — no UI code.
class ScanController {
  /// Names that the API returns when a product is not in its database.
  static const _notFoundSentinels = {
    'Product not found',
    'No product data',
    'Unknown Product',
  };

  /// Lookup [barcode] via the API and return a structured [ScanResult].
  static Future<ScanResult> lookup(String barcode) async {
    final Map<String, String> data = await ProductApi.fetchProduct(barcode);

    final String name = data['name'] ?? 'Unknown Product';
    final String price = data['price'] ?? 'N/A';

    // Treat API-level "not found" sentinels and error strings as not found
    final bool found =
        !_notFoundSentinels.contains(name) && !name.startsWith('Error') && !name.startsWith('API Error') && !name.startsWith('Network error');

    return ScanResult(
      found: found,
      name: name,
      price: price,
      barcode: barcode,
    );
  }
}
