import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/aadhar_autofill_model.dart';

class AadharScannerService {
  final ImagePicker _picker = ImagePicker();

  Future<AadharAutoFillModel?> scanAadhar({required bool isFront}) async {
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

    return _extractData(fullText, isFront);
  }

  AadharAutoFillModel _extractData(String text, bool isFront) {
    if (isFront) {
      return AadharAutoFillModel(
        name: _extractName(text),
        age: _extractAge(text),
        pincode: "",
        houseName: "",
      );
    } else {
      return AadharAutoFillModel(
        name: "",
        age: 0,
        pincode: _extractPincode(text),
        houseName: _extractHouseName(text),
      );
    }
  }

  String _extractName(String text) {
    List<String> lines = text.split('\n');

    for (String line in lines) {
      String cleanLine = line.trim();
      String lowerLine = cleanLine.toLowerCase();

      if (cleanLine.length < 4) continue;

      // ❌ Ignore lines containing numbers
      if (RegExp(r'\d').hasMatch(cleanLine)) continue;

      // ❌ Ignore common unwanted words
      if (lowerLine.contains("government") ||
          lowerLine.contains("india") ||
          lowerLine.contains("address") ||
          lowerLine.contains("dob") ||
          lowerLine.contains("male") ||
          lowerLine.contains("female") ||
          lowerLine.contains("year") ||
          lowerLine.contains("s/o") ||
          lowerLine.contains("d/o") ||
          lowerLine.contains("w/o") ||
          lowerLine.contains("c/o"))
        continue;

      return cleanLine;
    }

    return "";
  }

  int _extractAge(String text) {
    if (!text.toLowerCase().contains("dob")) {
      return 0; // Back side won’t change age
    }
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
