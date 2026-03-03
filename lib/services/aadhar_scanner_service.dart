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
        gender: _extractGender(text),
        pincode: "",
        houseName: "",
      );
    } else {
      return AadharAutoFillModel(
        name: "",
        age: 0,
        gender: "",
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
          lowerLine.contains("c/o")) {
        continue;
      }

      return cleanLine;
    }

    return "";
  }

  int _extractAge(String text) {
    final normalized = text.replaceAll(RegExp(r'[oO]'), '0');
    final nowYear = DateTime.now().year;

    int ageFromYear(int year) {
      final age = nowYear - year;
      if (age < 1 || age > 120) return 0;
      return age;
    }

    // Aadhaar common format: dd/mm/yyyy
    final dobDate = RegExp(r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})\b')
        .firstMatch(normalized);
    if (dobDate != null) {
      final year = int.tryParse(dobDate.group(3) ?? '');
      if (year != null) {
        final age = ageFromYear(year);
        if (age > 0) return age;
      }
    }

    final yob = RegExp(
      r'(year\s*of\s*birth|yob|birth\s*year)\s*[:\-]?\s*(19\d{2}|20\d{2})',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (yob != null) {
      final year = int.tryParse(yob.group(2) ?? '');
      if (year != null) {
        final age = ageFromYear(year);
        if (age > 0) return age;
      }
    }

    final ageMatch = RegExp(
      r'\bage\s*[:\-]?\s*(\d{1,3})\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (ageMatch != null) {
      final age = int.tryParse(ageMatch.group(1) ?? '');
      if (age != null && age >= 1 && age <= 120) return age;
    }

    return 0;
  }

  String _extractGender(String text) {
    text = text.toLowerCase();

    RegExp femaleRegex = RegExp(r'\bfemale\b');
    RegExp maleRegex = RegExp(r'\bmale\b');
    RegExp transRegex = RegExp(r'\btransgender\b');

    if (femaleRegex.hasMatch(text)) return "Female";
    if (maleRegex.hasMatch(text)) return "Male";
    if (transRegex.hasMatch(text)) return "Other";

    return "";
  }

  String _extractPincode(String text) {
    RegExp pinRegex = RegExp(r'\d{6}');
    Match? match = pinRegex.firstMatch(text);
    return match?.group(0) ?? "";
  }

  String _extractHouseName(String text) {
    List<String> lines = text.split('\n');
    bool addressSectionStarted = false;

    for (String line in lines) {
      String cleanLine = line.trim();
      if (cleanLine.isEmpty) continue;

      String lowerLine = cleanLine.toLowerCase();

      // Detect start of address block
      if (lowerLine.contains("address")) {
        addressSectionStarted = true;
        continue;
      }

      if (!addressSectionStarted) continue;

      // ❌ Skip guardian lines
      if (lowerLine.contains("s/o") ||
          lowerLine.contains("d/o") ||
          lowerLine.contains("w/o") ||
          lowerLine.contains("c/o")) {
        continue;
      }

      // ❌ Skip lines with digits (pincode, house number)
      if (RegExp(r'\d').hasMatch(cleanLine)) continue;

      // ❌ Skip likely state or country names
      if (lowerLine.contains("kerala") ||
          lowerLine.contains("india") ||
          lowerLine.contains("tamil") ||
          lowerLine.contains("karnataka")) {
        continue;
      }

      // ✅ Pick FULL CAPS line
      if (cleanLine == cleanLine.toUpperCase() && cleanLine.length > 3) {
        return cleanLine;
      }
    }

    return "";
  }
}
