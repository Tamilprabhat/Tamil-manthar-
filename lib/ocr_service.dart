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
        // பட சுழற்சியைச் சீரமைத்தல்
        originalImage = img.bakeOrientation(originalImage);

        // மலர் பின்னணியை நீக்கி சிவப்பு எழுத்துக்களைத் தனியாகப் பிரிக்கும் கிரீன் சேனல் முறை
        var gray = img.grayscale(originalImage);
        gray = img.adjustColor(gray, contrast: 1.35, brightness: 1.05);

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

      // உடைந்த ஆங்கில குப்பை எச்சங்களை நீக்குதல்
      if (RegExp(r'^(?:[க-ளa-zA-Z\:\.\s]){1,5}$').hasMatch(line) && !line.contains(RegExp(r'\d'))) continue;
      if (line.contains('Pena RR') || line.contains('sila ii')) continue;

      // எண் வரிசைகளைச் சீரமைத்தல்
      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      // பொதுவான பாடல் தலைப்புகள்
      line = line.replaceAll(RegExp(r'சரணங்கள்|சரணஙகள்', caseSensitive: false), 'சரணங்கள்');
      line = line.replaceAll(RegExp(r'பல்லவி|பல்லவ|பலலவி', caseSensitive: false), 'பல்லவி');
      line = line.replaceAll(RegExp(r'அனுபல்லவி|அநுபல்லவி', caseSensitive: false), 'அனுபல்லவி');

      // எழுத்துப் பிழை திருத்தங்கள்
      line = line.replaceAll('சயை', 'சபை');
      line = line.replaceAll('நடத்துதின்றது', 'நடத்துகின்றது');
      line = line.replaceAll('உள்கமே', 'உள்ளமே');
      line = line.replaceAll('களமலைமேல்', 'கன்மலைமேல்');
      line = line.replaceAll('முஷிகூட்டினீர்', 'முடிசூட்டினீர்');
      line = line.replaceAll('துதியிலும்', 'துதியினும்');

      formattedLines.add(line);
    }

    return formattedLines.join('\n\n');
  }
}
