import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'image_filter_service.dart';

class OcrService {
  static final Map<String, String> _commonCorrections = {
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
    'crocs': '',
  };

  Future<String> extractText(String originalImagePath) async {
    // முதலில் நிழல் நீக்கப்பட்டு படம் கூர்மையாக்கப்படுகிறது
    String cleanImagePath = await ImageFilterService.cleanAndEnhanceForOcr(originalImagePath);

    String text = await FlutterTesseractOcr.extractText(
      cleanImagePath,
      language: 'tam+eng',
      args: {
        "preserve_interword_spaces": "1",
        "psm": "4",
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
      if (trimmed.isNotEmpty && trimmed.length > 1) {
        trimmed = trimmed.replaceAll(RegExp(r'[ \t]+'), ' ');
        validLines.add(trimmed);
      }
    }

    return validLines.join('\n\n');
  }
}
