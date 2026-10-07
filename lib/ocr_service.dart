import 'dart:io';
import 'dart:convert';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;

class OcrService {
  Future<String> extractText(String imagePath, {bool tryOnline = true}) async {
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

      // 1. ஆன்லைனில் இருந்தால் இலவச அதிதுல்லிய OCR முறை
      if (tryOnline) {
        try {
          String? onlineResult = await _fetchOnlineOcr(processedPath);
          if (onlineResult != null && onlineResult.trim().isNotEmpty) {
            return _processBilingualAndNumerals(onlineResult);
          }
        } catch (_) {}
      }

      // 2. ஆஃப்லைன் எஞ்சின்
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

  Future<String?> _fetchOnlineOcr(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      var uri = Uri.parse('https://api.ocr.space/parse/image');
      var request = HttpClient();
      var req = await request.postUrl(uri);
      
      String body = 'language=tam&isOverlayRequired=false&base64Image=data:image/png;base64,$base64Image';
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

  String _processBilingualAndNumerals(String text) {
    if (text.trim().isEmpty) return "";

    List<String> rawLines = text.split('\n');
    List<String> formattedLines = [];

    for (var rawLine in rawLines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      // 'கு. so அங்கை' போன்ற விளிம்பு உடைந்த குப்பைகளை நீக்குதல்
      if (line.contains('so அங்கை') || line.contains('so அங்') || RegExp(r'^[^\w\s\u0B80-\u0BFF]{1,4}$').hasMatch(line)) continue;
      if (line.contains('Pena RR') || line.contains('sila ii')) continue;

      // அடைப்புக்குறி எண்கள் சீரமைப்பு: (1) அல்லது [ 3 ] -> 3.
      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      // பாடல் அச்சுப் பிழைகளைத் துல்லியமாக மாற்றுதல்
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

    // முதல் வரி அல்லது கடைசி வரியில் தேவையற்ற 1-2 எழுத்து சில்லறைகளை நீக்குதல்
    if (formattedLines.isNotEmpty && formattedLines.last.length <= 6 && !formattedLines.last.contains(RegExp(r'\d'))) {
      formattedLines.removeLast();
    }

    return formattedLines.join('\n\n');
  }
}
