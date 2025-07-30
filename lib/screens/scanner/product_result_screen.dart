import 'package:flutter/material.dart';
import '../../models/product_model.dart';

class ProductResultScreen extends StatelessWidget {
  final ProductModel product;
  final List<String> foundAllergies;

  const ProductResultScreen({
    super.key,
    required this.product,
    required this.foundAllergies,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAllergies = foundAllergies.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: hasAllergies ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alert status
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: hasAllergies ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasAllergies ? Colors.red.shade200 : Colors.green.shade200,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    hasAllergies ? Icons.warning : Icons.check_circle,
                    size: 60,
                    color: hasAllergies ? Colors.red : Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasAllergies ? '⚠️ ALLERGY ALERT!' : '✅ SAFE TO CONSUME',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: hasAllergies ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                  if (hasAllergies) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This product contains: ${foundAllergies.join(', ')}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'No allergens detected based on your profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Product information
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Product Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Product name
                    _buildInfoRow('Name', product.name),
                    
                    // Brand
                    if (product.brand != null)
                      _buildInfoRow('Brand', product.brand!),
                    
                    // Barcode
                    _buildInfoRow('Barcode', product.barcode),
                    
                    // Scan time
                    _buildInfoRow(
                      'Scanned',
                      '${product.scannedAt.day}/${product.scannedAt.month}/${product.scannedAt.year} at ${product.scannedAt.hour}:${product.scannedAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredients
            if (product.ingredients.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ingredients',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.ingredients.map((ingredient) {
                          final isAllergen = foundAllergies.any(
                            (allergy) => ingredient.toLowerCase().contains(allergy.toLowerCase()),
                          );
                          return Chip(
                            label: Text(
                              ingredient,
                              style: TextStyle(
                                color: isAllergen ? Colors.white : Colors.black87,
                                fontWeight: isAllergen ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            backgroundColor: isAllergen ? Colors.red : Colors.grey.shade200,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Known allergens
            if (product.allergens.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Known Allergens',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: product.allergens.map((allergen) {
                          return Chip(
                            label: Text(
                              allergen,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.orange,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.popUntil(
                      context,
                      (route) => route.isFirst,
                    ),
                    icon: const Icon(Icons.home),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
