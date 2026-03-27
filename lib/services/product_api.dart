import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches product details using multiple API providers for robustness.
class ProductApi {
  // ── API Configuration ──────────────────────────────────────────────────────
  
  static const String _offBaseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const String _foodRepoUrl = 'https://www.foodrepo.org/api/v3/products';
  
  /// TODO: Replace with your actual FoodRepo API key
  static const String _foodRepoApiKey = 'YOUR_FOODREPO_API_KEY';

  // ── Main Fetch Logic ───────────────────────────────────────────────────────

  /// Primary function to fetch product data with automatic fallback.
  /// 1. Tries OpenFoodFacts
  /// 2. If no valid name found, tries FoodRepo
  /// 3. Returns fallback data if both fail
  static Future<Map<String, String>> fetchProduct(String barcode) async {
    // 1. Try OpenFoodFacts (Primary)
    final offResult = await fetchFromOpenFoodFacts(barcode);
    
    // Check if OFF found a valid product name
    if (offResult['name'] != null && 
        offResult['name'] != 'Product not found' && 
        !offResult['name']!.startsWith('Error') &&
        !offResult['name']!.startsWith('API Error')) {
      return offResult;
    }

    // 2. Try FoodRepo (Secondary Fallback)
    final foodRepoResult = await fetchFromFoodRepo(barcode);
    
    // Check if FoodRepo found a valid product name
    if (foodRepoResult['name'] != null && 
        foodRepoResult['name'] != 'Product Not Found' &&
        !foodRepoResult['name']!.startsWith('Error')) {
      return foodRepoResult;
    }

    // 3. Ultimate Fallback
    return {
      "name": "Product Not Found",
      "price": "N/A"
    };
  }

  // ── OpenFoodFacts Implementation ───────────────────────────────────────────

  static Future<Map<String, String>> fetchFromOpenFoodFacts(String barcode) async {
    final uri = Uri.parse('$_offBaseUrl/$barcode.json');

    try {
      final response = await http
          .get(uri, headers: {'User-Agent': 'FreshLoop/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return {'name': 'API Error (${response.statusCode})', 'price': 'N/A'};
      }

      final Map<String, dynamic> body = json.decode(response.body);
      final int status = body['status'] ?? 0;
      
      if (status == 1 && body['product'] != null) {
        final String name = (body['product']['product_name'] as String?)?.trim() ?? '';
        if (name.isNotEmpty) {
          return {'name': name, 'price': 'N/A'};
        }
      }
      
      return {'name': 'Product not found', 'price': 'N/A'};
    } catch (e) {
      return {'name': 'Error: OFF API Fail', 'price': 'N/A'};
    }
  }

  // ── FoodRepo Implementation ────────────────────────────────────────────────

  static Future<Map<String, String>> fetchFromFoodRepo(String barcode) async {
    final uri = Uri.parse('$_foodRepoUrl?barcode=$barcode');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Token token=$_foodRepoApiKey',
          'User-Agent': 'FreshLoop/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return {'name': 'API Error (${response.statusCode})', 'price': 'N/A'};
      }

      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic>? products = body['data'];

      if (products != null && products.isNotEmpty) {
        // Extract translated name (defaults to 'en' or first available)
        final product = products.first;
        final Map<String, dynamic>? names = product['name_translations'];
        
        String? name = names?['en'] ?? names?.values.firstOrNull;
        
        if (name != null && name.isNotEmpty) {
          return {'name': name, 'price': 'N/A'};
        }
      }

      return {'name': 'Product Not Found', 'price': 'N/A'};
    } catch (e) {
      return {'name': 'Error: FoodRepo API Fail', 'price': 'N/A'};
    }
  }
}
