import 'package:flutter/material.dart';
import '../services/aadhar_scanner_service.dart';
import '../models/aadhar_autofill_model.dart';

class AadharScannerScreen extends StatefulWidget {
  final Function(AadharAutoFillModel) onDataExtracted;
  final bool isFront;

  const AadharScannerScreen({
    super.key,
    required this.onDataExtracted,
    required this.isFront,
  });

  @override
  State<AadharScannerScreen> createState() => _AadharScannerScreenState();
}

class _AadharScannerScreenState extends State<AadharScannerScreen> {
  bool _loading = false;
  final AadharScannerService _scannerService = AadharScannerService();

  Future<void> _startScan() async {
    setState(() => _loading = true);

    final data = await _scannerService.scanAadhar(isFront: widget.isFront);

    setState(() => _loading = false);

    if (data != null) {
      widget.onDataExtracted(data);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Aadhaar")),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _startScan,
                child: const Text("Scan Aadhaar Card"),
              ),
      ),
    );
  }
}
