import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'image_filter_service.dart';

class OcrService {
  static final Map<String, String> _commonCorrections = {
    'சயை': 'சபை',
    'துகி': 'துதி',
    'துகிக்கிடுவேனே': 'துதித்திடுவேனே',
    'துகித்திடும்': 'துதித்திடும்',
    'கூர்த்தனாயே': 'கர்த்தனாயே',
    'துள்பின்': 'துன்பின்',
    'காக்காலே': 'நாட்களிலே',
    'கள்மலைமேக்': 'கன்மலைமேல்',
    'நிறுக்கினீரோ': 'நிறுத்தினீரோ',
    'கடங்கிட்டாலும்': 'கடந்திட்டாலும்',
    'மாறிடீர்': 'மாறிடீர்',
    'நடத்துதின்றது': 'நடத்துகின்றது',
    'உயிர்ப்பிக்குமேண்': 'உயிர்ப்பிக்குமே',
    'செய்தருளுமேண்': 'செய்தருளுமேன்',
    'Cos': '',
    'crocs': '',
    'ed': '',
  };

  Future<String> extractText(String originalImagePath) async {
    String cleanImagePath = await ImageFilterService.cleanAndEnhanceForOcr(originalImagePath);

    // PSM 6 பாடல் வரிகள் மற்றும் பத்திகளை வரிசை மாறாமல் வாசிக்கும்
    String text = await FlutterTesseractOcr.extractText(
      cleanImagePath,
      language: 'tam+eng',
      args: {
        "preserve_interword_spaces": "1",
        "psm": "6",
      },
    );

    return _autoCorrectAndClean(text);
  }

  String _autoCorrectAndClean(String raw) {
    String cleaned = raw;
    _commonCorrections.forEach((wrong, right) {
      cleaned = cleaned.replaceAll(wrong, right);
    });

    List<String> lines = cleaned.split('\n');
    List<String> validLines = [];

    for (var line in lines) {
      String trimmed = line.trim();
      // ஒற்றை விளிம்புக் குப்பைகளை நீக்குதல்
      if (trimmed.isNotEmpty && trimmed.length > 1) {
        trimmed = trimmed.replaceAll(RegExp(r'[ \t]+'), ' ');
        validLines.add(trimmed);
      }
    }

    return validLines.join('\n\n');
  }
}
