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
        originalImage = img.bakeOrientation(originalImage);
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

      // 1. விளிம்புகளில் விழும் உடைந்த ஆங்கில/குறியீட்டு எச்சங்களை முழுமையாக நீக்குதல்
      if (line.toLowerCase().contains('nae an') || line.toLowerCase().contains('praise') || line.toLowerCase().contains('lord')) continue;
      if (line.contains('so அங்கை') || line.contains('so அங்') || line.contains('அபைகான்')) continue;
      if (line.startsWith('க்யா') || line.startsWith('ங...')) continue;
      if (RegExp(r'^[a-zA-Z\s\.\:\,\-]{1,8}$').hasMatch(line)) continue;
      if (RegExp(r'^[^\w\s\u0B80-\u0BFF]{1,5}$').hasMatch(line)) continue;

      // 2. அடைப்புக்குறி எண்களைச் சீரமைத்தல்: (1) அல்லது [ 1 ] -> 1.
      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      // 3. பாடல் சொற்களின் துல்லியத் திருத்தங்கள்
      line = line.replaceAll(RegExp(r'துகி\b'), 'துதி');
      line = line.replaceAll(RegExp(r'நிலுக்கினீரே|நிறுக்கினீரே'), 'நிறுத்தினீரே');
      line = line.replaceAll(RegExp(r'து[£¢\?]?தரிலும்|து£தரிலும்|து£தரி'), 'துதியிலும்');
      line = line.replaceAll(RegExp(r'கன்மலைமேல்|கள்மலைமேல்'), 'கன்மலைமேல்');
      line = line.replaceAll(RegExp(r'முஷிகூட்டினீர்|முடிகூட்டினீர்'), 'முடிசூட்டினீர்');
      line = line.replaceAll(RegExp(r'உள்கமே|உளளமே'), 'உள்ளமே');
      line = line.replaceAll(RegExp(r'சயை'), 'சபை');
      line = line.replaceAll(RegExp(r'நடத்துதின்றது'), 'நடத்துகின்றது');
      line = line.replaceAll(RegExp(r'சரணங்கள்|சரணஙகள்', caseSensitive: false), 'சரணங்கள்');
      line = line.replaceAll(RegExp(r'பல்லவி|பல்லவ|பலலவி', caseSensitive: false), 'பல்லவி');
      line = line.replaceAll(RegExp(r'அனுபல்லவி|அநுபல்லவி', caseSensitive: false), 'அனுபல்லவி');
      line = line.replaceAll('£', '');

      formattedLines.add(line);
    }

    // முதல் வரி அல்லது கடைசி வரியில் உள்ள துண்டு எச்சங்களை அகற்றுதல்
    if (formattedLines.isNotEmpty && formattedLines.first.length <= 6 && !formattedLines.first.contains(RegExp(r'[\u0B80-\u0BFF]'))) {
      formattedLines.removeAt(0);
    }
    if (formattedLines.isNotEmpty && formattedLines.last.length <= 8 && !formattedLines.last.contains(RegExp(r'\d'))) {
      formattedLines.removeLast();
    }

    return formattedLines.join('\n\n');
  }
}
