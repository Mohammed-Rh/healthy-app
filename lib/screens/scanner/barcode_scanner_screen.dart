import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/notification_service.dart';
import '../../models/product_model.dart';
import 'product_result_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final ProductService _productService = ProductService();
  final NotificationService _notificationService = NotificationService();
  String _scanResult = '';
  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  // Scan barcode using camera
  Future<void> _scanBarcode() async {
    setState(() {
      _isScanning = true;
    });

    // Navigate to scanner screen
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const _MobileScannerScreen()),
    );

    setState(() {
      _isScanning = false;
    });

    if (result != null && result.isNotEmpty) {
      setState(() {
        _scanResult = result;
      });
      await _processBarcode(result);
    }
  }

  // Process scanned barcode
  Future<void> _processBarcode(String barcode) async {
    if (!_productService.isValidBarcode(barcode)) {
      _showErrorDialog('Invalid barcode format. Please try again.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userAllergies = authProvider.userModel?.allergies ?? [];

      if (userAllergies.isEmpty) {
        _showErrorDialog('Please set up your allergies first in the settings.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch product information
      ProductModel? product = await _productService.getProductByBarcode(
        barcode,
      );

      if (product == null) {
        // Use mock product for demonstration if API fails
        product = _productService.getMockProduct(barcode);
      }

      // Check for allergies
      final foundAllergies = product.checkAllergies(userAllergies);

      // Show notification if allergies found
      if (foundAllergies.isNotEmpty) {
        await _notificationService.showAllergyAlert(
          productName: product.name,
          foundAllergies: foundAllergies,
        );
      }

      // Navigate to result screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductResultScreen(
              product: product!,
              foundAllergies: foundAllergies,
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Error processing product: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Manual barcode entry
  Future<void> _enterBarcodeManually() async {
    final TextEditingController controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter barcode number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Scan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _scanResult = result;
      });
      await _processBarcode(result);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text('Processing product...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Scan Product Barcode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Text(
                    'Point your camera at the product barcode to check for allergens',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // Scan result display
                  if (_scanResult.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Last Scanned:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _scanResult,
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Scan button
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning ? null : _scanBarcode,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.camera_alt, size: 28),
                      label: Text(
                        _isScanning ? 'Opening Scanner...' : 'Scan Barcode',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Manual entry button
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _enterBarcodeManually,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Enter Manually'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'How to scan:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Hold your phone steady\n'
                          '• Point camera at the barcode\n'
                          '• Make sure the barcode is well-lit\n'
                          '• Wait for automatic detection',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// Mobile Scanner Screen
class _MobileScannerScreen extends StatefulWidget {
  const _MobileScannerScreen();

  @override
  State<_MobileScannerScreen> createState() => _MobileScannerScreenState();
}

class _MobileScannerScreenState extends State<_MobileScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    _screenOpened = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Barcode'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _foundBarcode),
          // Overlay with scanning frame
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Point your camera at a barcode to scan',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _foundBarcode(BarcodeCapture capture) {
    final String code = capture.barcodes.first.rawValue ?? "";

    if (!_screenOpened && code.isNotEmpty) {
      _screenOpened = true;
      Navigator.pop(context, code);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Custom overlay shape for scanner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + borderRadius,
          rect.top,
        )
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize < width && cutOutSize < height
        ? cutOutSize
        : (width < height ? width : height) - borderWidthSize;
    final _cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(_cutOutRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw the border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final borderPath = Path();

    // Top-left corner
    borderPath.moveTo(
      _cutOutRect.left - borderOffset,
      _cutOutRect.top + borderLength,
    );
    borderPath.lineTo(
      _cutOutRect.left - borderOffset,
      _cutOutRect.top + borderRadius,
    );
    borderPath.quadraticBezierTo(
      _cutOutRect.left - borderOffset,
      _cutOutRect.top - borderOffset,
      _cutOutRect.left + borderRadius,
      _cutOutRect.top - borderOffset,
    );
    borderPath.lineTo(
      _cutOutRect.left + borderLength,
      _cutOutRect.top - borderOffset,
    );

    // Top-right corner
    borderPath.moveTo(
      _cutOutRect.right - borderLength,
      _cutOutRect.top - borderOffset,
    );
    borderPath.lineTo(
      _cutOutRect.right - borderRadius,
      _cutOutRect.top - borderOffset,
    );
    borderPath.quadraticBezierTo(
      _cutOutRect.right + borderOffset,
      _cutOutRect.top - borderOffset,
      _cutOutRect.right + borderOffset,
      _cutOutRect.top + borderRadius,
    );
    borderPath.lineTo(
      _cutOutRect.right + borderOffset,
      _cutOutRect.top + borderLength,
    );

    // Bottom-right corner
    borderPath.moveTo(
      _cutOutRect.right + borderOffset,
      _cutOutRect.bottom - borderLength,
    );
    borderPath.lineTo(
      _cutOutRect.right + borderOffset,
      _cutOutRect.bottom - borderRadius,
    );
    borderPath.quadraticBezierTo(
      _cutOutRect.right + borderOffset,
      _cutOutRect.bottom + borderOffset,
      _cutOutRect.right - borderRadius,
      _cutOutRect.bottom + borderOffset,
    );
    borderPath.lineTo(
      _cutOutRect.right - borderLength,
      _cutOutRect.bottom + borderOffset,
    );

    // Bottom-left corner
    borderPath.moveTo(
      _cutOutRect.left + borderLength,
      _cutOutRect.bottom + borderOffset,
    );
    borderPath.lineTo(
      _cutOutRect.left + borderRadius,
      _cutOutRect.bottom + borderOffset,
    );
    borderPath.quadraticBezierTo(
      _cutOutRect.left - borderOffset,
      _cutOutRect.bottom + borderOffset,
      _cutOutRect.left - borderOffset,
      _cutOutRect.bottom - borderRadius,
    );
    borderPath.lineTo(
      _cutOutRect.left - borderOffset,
      _cutOutRect.bottom - borderLength,
    );

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
