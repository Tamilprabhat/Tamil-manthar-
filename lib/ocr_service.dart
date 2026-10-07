
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

        if (originalImage.width < 1800) {
          originalImage = img.copyResize(originalImage, width: (originalImage.width * 1.5).round());
        }

        var gray = img.grayscale(originalImage);
        gray = img.adjustColor(gray, contrast: 1.2, brightness: 1.02);

        final tempFile = File('${imagePath}_enhanced.png');
        await tempFile.writeAsBytes(img.encodePng(gray));
        processedPath = tempFile.path;
      }

      String rawText = await FlutterTesseractOcr.extractText(
        processedPath,
        language: 'tam+eng',
        args: {
          'psm': '6',
          'preserve_interword_spaces': '1',
        },
      );

      return _processHymnText(rawText);
    } catch (e) {
      return "பிழை: $e";
    }
  }

  String _processHymnText(String text) {
    if (text.trim().isEmpty) return '';

    List<String> rawLines = text.split('\n');
    List<String> formattedLines = [];

    for (var rawLine in rawLines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line == 'at' || line.startsWith(': |') || line.contains('ee   L')) continue;
      if (RegExp(r'^[a-zA-Z\s\:\ supply\|\.\,\-]{1,6}$').hasMatch(line)) continue;

      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAll(RegExp(r'சாணங்கள்|சரணஙகள்'), 'சரணங்கள்');
      line = line.replaceAll(RegExp(r'பொற்பான்'), 'பொற்பாதம்');
      line = line.replaceAll(RegExp(r'ப மந்தரெமைச்|சுமந்தவரே'), 'சுமந்தவரே');
      line = line.replaceAll(RegExp(r'ஞாலமெல்லாம்'), 'ஞாலமெல்லாம்');
      line = line.replaceAll(RegExp(r'அபிஷேகத்தாலே'), 'அபிஷேகத்தாலே');
      line = line.replaceAll(RegExp(r'அப்போஸ்தல'), 'அப்போஸ்தல');
      line = line.replaceAll(RegExp(r'சீயோனே! மா சாலேம்'), 'சீயோனே! மா சாலேம்');
      line = line.replaceAll(RegExp(r'இப்பார்தலத்தே|இப்பார்தலத்த'), 'இப்பார்தலத்தே');
      line = line.replaceAll(RegExp(r'துகி\b'), 'துதி');
      line = line.replaceAll(RegExp(r'நிலுக்கினீரே|நிறுக்கினீரே'), 'நிறுத்தினீரே');

      formattedLines.add(line);
    }

    return formattedLines.join('\n\n');
  }
}
