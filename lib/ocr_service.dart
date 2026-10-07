import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;

class OcrService {
  Future<String> extractText(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      var originalImage = img.decodeImage(imageBytes);

      String processedPath = imagePath;

      if (originalImage != null) {
        // படச் சுழற்சியைச் சீரமைத்தல்
        originalImage = img.bakeOrientation(originalImage);

        // உகந்த கான்ட்ராஸ்ட் மூலம் புள்ளிகளையும் மங்கலான எழுத்துக்களையும் தெளிவுபடுத்துதல்
        var gray = img.grayscale(originalImage);
        gray = img.adjustColor(gray, contrast: 1.4, brightness: 1.02);

        final tempFile = File('${imagePath}_clean.png');
        await tempFile.writeAsBytes(img.encodePng(gray));
        processedPath = tempFile.path;
      }

      String rawText = await FlutterTesseractOcr.extractText(
        processedPath,
        language: 'tam+eng',
        args: {
          "psm": "6",
          "preserve_interword_spaces": "1",
        },
      );

      return _processBilingualAndNumerals(rawText);
    } catch (e) {
      return "பிழை: $e";
    }
  }

  String _processBilingualAndNumerals(String text) {
    if (text.trim().isEmpty) return "";

    List<String> rawLines = text.split('\n');
    List<String> formattedLines = [];

    for (var rawLine in rawLines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      // அர்த்தமற்ற துண்டு எழுத்துக்களை நீக்குதல்
      if (RegExp(r'^(?:[க-ளa-zA-Z\:\.\s]){1,4}$').hasMatch(line) && !line.contains(RegExp(r'\d'))) continue;

      // அடைப்புக்குறி எண்கள் சீரமைப்பு: [ 3 ] அல்லது (3) -> 3.
      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      // பொதுவான பாடல் பிழைகளைத் துல்லியமாக மாற்றுதல்
      line = line.replaceAll(RegExp(r'துகி\b'), 'துதி');
      line = line.replaceAll(RegExp(r'நிலுக்கினீரே|நிறுக்கினீரே'), 'நிறுத்தினீரே');
      line = line.replaceAll(RegExp(r'து[£¢\?]?தரிலும்|து£தரிலும்'), 'துதியிலும்');
      line = line.replaceAll(RegExp(r'கன்மலைமேல்|கள்மலைமேல்'), 'கன்மலைமேல்');
      line = line.replaceAll(RegExp(r'முஷிகூட்டினீர்|முடிகூட்டினீர்'), 'முடிசூட்டினீர்');
      line = line.replaceAll(RegExp(r'உள்கமே|உளளமே'), 'உள்ளமே');
      line = line.replaceAll(RegExp(r'சயை'), 'சபை');
      line = line.replaceAll(RegExp(r'நடத்துதின்றது'), 'நடத்துகின்றது');
      line = line.replaceAll(RegExp(r'சரணங்கள்|சரணஙகள்', caseSensitive: false), 'சரணங்கள்');
      line = line.replaceAll(RegExp(r'பல்லவி|பல்லவ|பலலவி', caseSensitive: false), 'பல்லவி');
      line = line.replaceAll(RegExp(r'அனுபல்லவி|அநுபல்லவி', caseSensitive: false), 'அனுபல்லவி');

      // தனித்து நிற்கும் தவறான குறியீடுகளை நீக்குதல்
      line = line.replaceAll('£', '');

      formattedLines.add(line);
    }

    if (formattedLines.isNotEmpty && formattedLines.first.length <= 4 && !formattedLines.first.contains(RegExp(r'\d'))) {
      formattedLines.removeAt(0);
    }

    return formattedLines.join('\n\n');
  }
}
