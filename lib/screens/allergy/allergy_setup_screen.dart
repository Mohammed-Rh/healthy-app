import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AllergySetupScreen extends StatefulWidget {
  const AllergySetupScreen({super.key});

  @override
  State<AllergySetupScreen> createState() => _AllergySetupScreenState();
}

class _AllergySetupScreenState extends State<AllergySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _allergyControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  bool _isLoading = false;

  // Common allergies for suggestions
  final List<String> _commonAllergies = [
    'Gluten',
    'Lactose',
    'Milk',
    'Peanuts',
    'Tree nuts',
    'Eggs',
    'Soy',
    'Fish',
    'Shellfish',
    'Sesame',
    'Wheat',
    'Corn',
    'Sulfites',
    'Mustard',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingAllergies();
  }

  @override
  void dispose() {
    for (var controller in _allergyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadExistingAllergies() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userModel = authProvider.userModel;
    
    if (userModel != null && userModel.allergies.isNotEmpty) {
      for (int i = 0; i < userModel.allergies.length && i < 3; i++) {
        _allergyControllers[i].text = userModel.allergies[i];
      }
    }
  }

  Future<void> _saveAllergies() async {
    if (!_formKey.currentState!.validate()) return;

    // Get non-empty allergies
    List<String> allergies = _allergyControllers
        .map((controller) => controller.text.trim())
        .where((allergy) => allergy.isNotEmpty)
        .toList();

    if (allergies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one allergy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateAllergies(allergies);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Allergies saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving allergies: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAllergyField(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Allergy ${index + 1}${index == 0 ? ' (Required)' : ' (Optional)'}',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _allergyControllers[index],
          decoration: InputDecoration(
            hintText: 'e.g., ${_commonAllergies[index % _commonAllergies.length]}',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.warning_amber),
          ),
          validator: index == 0
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first allergy';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 8),
        // Suggestion chips
        Wrap(
          spacing: 8,
          children: _commonAllergies.take(5).map((allergy) {
            return ActionChip(
              label: Text(allergy),
              onPressed: () {
                _allergyControllers[index].text = allergy;
              },
              backgroundColor: Colors.red.shade50,
              labelStyle: TextStyle(color: Colors.red.shade700),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Allergies'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(
                Icons.health_and_safety,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Tell us about your allergies',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'We\'ll help you identify products that contain these allergens',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // Allergy fields
              _buildAllergyField(0),
              const SizedBox(height: 24),
              _buildAllergyField(1),
              const SizedBox(height: 24),
              _buildAllergyField(2),
              const SizedBox(height: 40),

              // Save button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAllergies,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Allergies',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can update your allergies anytime from the settings menu.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
