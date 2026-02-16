import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/aadhar_autofill_model.dart';

class AadharScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<AadharAutoFillModel?> scanAadhar() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    final inputImage = InputImage.fromFilePath(pickedFile.path);
    final textRecognizer = TextRecognizer();

    final recognizedText = await textRecognizer.processImage(inputImage);

    String fullText = recognizedText.text;

    textRecognizer.close();
    File(pickedFile.path).delete();

    return _extractData(fullText);
  }

  AadharAutoFillModel _extractData(String text) {
    return AadharAutoFillModel(
      name: _extractName(text),
      age: _extractAge(text),
      pincode: _extractPincode(text),
      houseName: _extractHouseName(text),
    );
  }

  String _extractName(String text) {
    List<String> lines = text.split('\n');

    for (String line in lines) {
      if (line.trim().length > 3 &&
          !RegExp(r'\d').hasMatch(line) &&
          !line.toLowerCase().contains("government") &&
          !line.toLowerCase().contains("india")) {
        return line.trim();
      }
    }
    return "";
  }

  int _extractAge(String text) {
    RegExp dobRegex = RegExp(r'\d{2}/\d{2}/\d{4}');
    Match? match = dobRegex.firstMatch(text);

    if (match != null) {
      String dob = match.group(0)!;
      int birthYear = int.parse(dob.split('/')[2]);
      return DateTime.now().year - birthYear;
    }

    return 0;
  }

  String _extractPincode(String text) {
    RegExp pinRegex = RegExp(r'\d{6}');
    Match? match = pinRegex.firstMatch(text);
    return match?.group(0) ?? "";
  }

  String _extractHouseName(String text) {
    List<String> lines = text.split('\n');

    for (String line in lines) {
      if (line.contains(',')) {
        return line.split(',').first.trim();
      }
    }

    return "";
  }
}
