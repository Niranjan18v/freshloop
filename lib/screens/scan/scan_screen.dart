import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/app_colors.dart';
import 'scan_controller.dart';
import 'product_screen.dart';

/// Professional Scanner Screen with a modern overlay frame and instruction text.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _processing = false;
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _processing = true);
    await _controller.stop();
    
    final ScanResult result = await ScanController.lookup(rawValue);

    if (!mounted) return;

    if (result.found) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProductScreen(result: result)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product not found: $rawValue'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _controller.start();
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── The Camera Viewfinder ─────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── The Professional Overlay ───────────────────────────────────────
          _buildScannerOverlay(),

          // ── Instructions & Back Button ─────────────────────────────────────
          _buildUIControls(),

          // ── Processing Indicator ───────────────────────────────────────────
          if (_processing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Searching...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.maxWidth * 0.7;
      return Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Corner Accents
              _cornerAccent(top: -2, left: -2),
              _cornerAccent(top: -2, right: -2),
              _cornerAccent(bottom: -2, left: -2),
              _cornerAccent(bottom: -2, right: -2),
            ],
          ),
        ),
      );
    });
  }

  Widget _cornerAccent({double? top, double? left, double? right, double? bottom}) {
    return Positioned(
      top: top, left: left, right: right, bottom: bottom,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: (top != null) ? BorderSide(color: AppColors.primary, width: 6) : BorderSide.none,
            left: (left != null) ? BorderSide(color: AppColors.primary, width: 6) : BorderSide.none,
            right: (right != null) ? BorderSide(color: AppColors.primary, width: 6) : BorderSide.none,
            bottom: (bottom != null) ? BorderSide(color: AppColors.primary, width: 6) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUIControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(30)),
              child: const Text(
                'Align barcode within the frame',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
