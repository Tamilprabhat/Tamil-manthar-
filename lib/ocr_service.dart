import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.devanagari);

  Future<String> extractText(String imagePath) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      var originalImage = img.decodeImage(imageBytes);

      String targetPath = imagePath;
      if (originalImage != null) {
        // EXIF கோணத்தைச் சீரமைத்து சேமித்தல்
        originalImage = img.bakeOrientation(originalImage);
        final normalizedFile = File('${imagePath}_mlkit_prep.jpg');
        await normalizedFile.writeAsBytes(img.encodeJpg(originalImage, quality: 98));
        targetPath = normalizedFile.path;
      }

      final inputImage = InputImage.fromFilePath(targetPath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      String rawText = recognizedText.text;
      return _cleanTamilText(rawText);
    } catch (e) {
      return "பிழை: $e";
    }
  }

  String _cleanTamilText(String text) {
    if (text.trim().isEmpty) return "";

    List<String> rawLines = text.split('\n');
    List<String> formattedLines = [];

    for (var rawLine in rawLines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      // அடைப்புக்குறி எண்கள் மற்றும் வரிசை எண்களைச் சீரமைத்தல்: (1) அல்லது [2] -> 1.
      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      // பொதுவான தமிழ் வார்த்தைச் சீரமைப்புகள்
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

  void dispose() {
    _textRecognizer.close();
  }
}
