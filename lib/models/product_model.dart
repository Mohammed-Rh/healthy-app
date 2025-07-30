class ProductModel {
  final String barcode;
  final String name;
  final List<String> ingredients;
  final List<String> allergens;
  final String? brand;
  final String? imageUrl;
  final DateTime scannedAt;

  ProductModel({
    required this.barcode,
    required this.name,
    required this.ingredients,
    required this.allergens,
    this.brand,
    this.imageUrl,
    required this.scannedAt,
  });

  // Convert ProductModel to Map
  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'ingredients': ingredients,
      'allergens': allergens,
      'brand': brand,
      'imageUrl': imageUrl,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  // Create ProductModel from Map
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      allergens: List<String>.from(map['allergens'] ?? []),
      brand: map['brand'],
      imageUrl: map['imageUrl'],
      scannedAt: DateTime.parse(map['scannedAt']),
    );
  }

  // Create ProductModel from OpenFoodFacts API response
  factory ProductModel.fromOpenFoodFacts(Map<String, dynamic> apiData, String barcode) {
    final product = apiData['product'] ?? {};
    
    // Extract ingredients
    List<String> ingredients = [];
    if (product['ingredients_text'] != null) {
      ingredients = product['ingredients_text']
          .toString()
          .split(',')
          .map((ingredient) => ingredient.trim().toLowerCase())
          .where((ingredient) => ingredient.isNotEmpty)
          .toList();
    }

    // Extract allergens
    List<String> allergens = [];
    if (product['allergens_tags'] != null) {
      allergens = List<String>.from(product['allergens_tags'])
          .map((allergen) => allergen.replaceAll('en:', '').toLowerCase())
          .toList();
    }

    return ProductModel(
      barcode: barcode,
      name: product['product_name'] ?? 'Unknown Product',
      ingredients: ingredients,
      allergens: allergens,
      brand: product['brands'],
      imageUrl: product['image_url'],
      scannedAt: DateTime.now(),
    );
  }

  // Check if product contains any of the user's allergies
  List<String> checkAllergies(List<String> userAllergies) {
    List<String> foundAllergies = [];
    
    for (String allergy in userAllergies) {
      String allergyLower = allergy.toLowerCase();
      
      // Check in allergens list
      if (allergens.any((allergen) => allergen.contains(allergyLower))) {
        foundAllergies.add(allergy);
        continue;
      }
      
      // Check in ingredients list
      if (ingredients.any((ingredient) => ingredient.contains(allergyLower))) {
        foundAllergies.add(allergy);
      }
    }
    
    return foundAllergies;
  }

  @override
  String toString() {
    return 'ProductModel(barcode: $barcode, name: $name, ingredients: ${ingredients.length}, allergens: ${allergens.length})';
  }
}
