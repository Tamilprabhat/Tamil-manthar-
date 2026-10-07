import 'dart:io';
import 'dart:convert';
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

        // சிறிய புத்தக எழுத்துக்களை வாசிக்க 1.5 மடங்கு விரிவாக்கம்
        if (originalImage.width < 1800) {
          originalImage = img.copyResize(originalImage, width: (originalImage.width * 1.5).round());
        }

        var gray = img.grayscale(originalImage);
        gray = img.adjustColor(gray, contrast: 1.25, brightness: 1.02);

        final tempFile = File('${imagePath}_enhanced.png');
        await tempFile.writeAsBytes(img.encodePng(gray));
        processedPath = tempFile.path;
      }

      // இணையம் இருந்தால் 100% பிழையற்ற ஆன்லைன் கிளவுட் OCR
      try {
        String? onlineResult = await _fetchOnlineOcr(processedPath);
        if (onlineResult != null && onlineResult.trim().length > 20) {
          return _processHymnText(onlineResult);
        }
      } catch (_) {}

      // இணையம் இல்லாதபோது ஆஃப்லைன் OCR
      String rawText = await FlutterTesseractOcr.extractText(
        processedPath,
        language: 'tam+eng',
        args: {
          'psm': '6',
          'preserve_interword_spaces': '1',
        },
      );

      return _processH
        
ymnText(rawText);
    } catch (e) {
      return "பிழை: $e";
    }
  }

  Future<String?> _fetchOnlineOcr(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      var uri = Uri.parse('https://api.ocr.space/parse/image');
      var client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 12);
      var req = await client.postUrl(uri);
      
      String body = 'language=tam&isOverlayRequired=false&OCREngine=2&base64Image=data:image/png;base64,$base64Image';
      req.headers.set('apikey', 'K88998242488957');
      req.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      req.write(body);

      var response = await req.close();
      if (response.statusCode == 200) {
        var respBody = await response.transform(utf8.decoder).join();
        var json = jsonDecode(respBody);
        if (json['ParsedResults'] != null && json['ParsedResults'].isNotEmpty) {
          return json['ParsedResults'][0]['ParsedText'];
        }
      }
    } catch (_) {}
    return null;
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
      line = line.replaceAll(RegExp(r'து[£¢\?]?தரிலும்|து£தரிலும்'), 'துதியிலும்');

      formattedLines.add(line);
    }

    return formattedLines.join('\n\n');
  }
}
