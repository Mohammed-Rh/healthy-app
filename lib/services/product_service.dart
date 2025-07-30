import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';

  // Fetch product information by barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/$barcode.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if product exists
        if (data['status'] == 1 && data['product'] != null) {
          return ProductModel.fromOpenFoodFacts(data, barcode);
        } else {
          // Product not found in OpenFoodFacts
          return null;
        }
      } else {
        throw 'Failed to fetch product information. Please try again.';
      }
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Network error. Please check your internet connection and try again.';
    }
  }

  // Search products by name (optional feature)
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl')
          .replace(queryParameters: {
        'search_terms': query,
        'search_simple': '1',
        'action': 'process',
        'json': '1',
        'page_size': '10',
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List;

        return products.map((productData) {
          final barcode = productData['code'] ?? '';
          return ProductModel.fromOpenFoodFacts({'product': productData}, barcode);
        }).toList();
      } else {
        throw 'Failed to search products. Please try again.';
      }
    } catch (e) {
      if (e is String) {
        throw e;
      }
      throw 'Network error. Please check your internet connection and try again.';
    }
  }

  // Validate barcode format
  bool isValidBarcode(String barcode) {
    // Remove any whitespace
    barcode = barcode.trim();
    
    // Check if barcode is numeric and has valid length
    if (!RegExp(r'^\d+$').hasMatch(barcode)) {
      return false;
    }

    // Common barcode lengths: UPC-A (12), EAN-13 (13), EAN-8 (8)
    final validLengths = [8, 12, 13, 14];
    return validLengths.contains(barcode.length);
  }

  // Get mock product for testing (when API is not available)
  ProductModel getMockProduct(String barcode) {
    return ProductModel(
      barcode: barcode,
      name: 'Sample Yogurt',
      ingredients: [
        'milk',
        'sugar',
        'lactose',
        'natural flavors',
        'live cultures'
      ],
      allergens: ['milk', 'lactose'],
      brand: 'Sample Brand',
      imageUrl: null,
      scannedAt: DateTime.now(),
    );
  }
}
