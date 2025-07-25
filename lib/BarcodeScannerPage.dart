import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerPage extends StatefulWidget {
  final Function(String) onScanned;

  const BarcodeScannerPage({super.key, required this.onScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    torchEnabled: true, // ✅ Flash ON by default
    facing: CameraFacing.back,
  );

  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan IMEI Barcode'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;
              if (code != null) {
                setState(() => _isScanned = true);
                Navigator.pop(context); // Close scanner
                widget.onScanned(code); // Pass scanned code
              }
            },
          ),

          // ✅ Custom Scan Area Overlay
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: 100, // Less height, wide scan box
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
