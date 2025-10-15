import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WarehouseScanFlow extends StatefulWidget {
  final void Function(String barcode) onBarcodeScanned;
  const WarehouseScanFlow({super.key, required this.onBarcodeScanned});

  @override
  State<WarehouseScanFlow> createState() => _WarehouseScanFlowState();
}

class _WarehouseScanFlowState extends State<WarehouseScanFlow> {
  bool _scanned = false;
  String? _barcode;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_scanned)
          SizedBox(
            width: 300,
            height: 300,
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first.rawValue;
                if (barcode != null && !_scanned) {
                  setState(() {
                    _scanned = true;
                    _barcode = barcode;
                  });
                  widget.onBarcodeScanned(barcode);
                }
              },
            ),
          ),
        if (_scanned && _barcode != null)
          Column(
            children: [
              Text('Scanned barcode: $_barcode'),
              ElevatedButton(
                onPressed: () => setState(() {
                  _scanned = false;
                  _barcode = null;
                }),
                child: const Text('Scan another'),
              ),
            ],
          ),
      ],
    );
  }
}
