import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;

class OcrService {
  Future<String> extractText(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      String processedPath = imagePath;

      if (originalImage != null) {
        var processed = img.grayscale(originalImage);
        processed = img.adjustColor(
          processed,
          contrast: 1.45,
          brightness: 1.02,
        );

        final tempFile = File('${imagePath}_ocr_binarized.png');
        await tempFile.writeAsBytes(img.encodePng(processed));
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

      if (RegExp(r'^(?:[க-ளa-zA-Z]\s*){4,}$').hasMatch(line) && line.length < 10) continue;
      if (RegExp(r'^[_\-—~=\.:]{2,}$').hasMatch(line)) continue;

      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      line = line.replaceAll(RegExp(r'^[உ௨]\s*[\.\)]\s*'), '2. ');
      line = line.replaceAll(RegExp(r'^[க௧]\s*[\.\)]\s*'), '1. ');
      line = line.replaceAll(RegExp(r'^[ங௩]\s*[\.\)]\s*'), '3. ');
      line = line.replaceAll(RegExp(r'^[ச௪]\s*[\.\)]\s*'), '4. ');

      line = line.replaceAllMapped(
        RegExp(r'^(I|II|III|IV|V|VI|VII|VIII|IX|X)\s*[\.\)]\s*', caseSensitive: false),
        (m) => '${m[1]!.toUpperCase()}. ',
      );

      line = line.replaceAll(RegExp(r'(?<=[\u0B80-\u0BFF])\s+[a-zA-Z]{1,2}\s+(?=[\u0B80-\u0BFF])'), ' ');

      line = line.replaceAll(RegExp(r'சரணங்கள்|சரணஙகள்', caseSensitive: false), 'சரணங்கள்');
      line = line.replaceAll(RegExp(r'பல்லவி|பல்லவ|பலலவி', caseSensitive: false), 'பல்லவி');
      line = line.replaceAll(RegExp(r'அனுபல்லவி|அநுபல்லவி', caseSensitive: false), 'அனுபல்லவி');

      line = line.replaceAll('சயை', 'சபை');
      line = line.replaceAll('நடத்துதின்றது', 'நடத்துகின்றது');
      line = line.replaceAll('உள்கமே', 'உள்ளமே');
      line = line.replaceAll('களமலைமேல்', 'கன்மலைமேல்');
      line = line.replaceAll('முஷிகூட்டினீர்', 'முடிசூட்டினீர்');
      line = line.replaceAll('துதியிலும்', 'துதியினும்');

      formattedLines.add(line);
    }

    if (formattedLines.isNotEmpty && formattedLines.first.length <= 4 && !formattedLines.first.contains(RegExp(r'\d'))) {
      formattedLines.removeAt(0);
    }

    return formattedLines.join('\n\n');
  }
}
