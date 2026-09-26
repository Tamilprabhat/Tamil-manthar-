import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrService {
  Future<String> extractText(String imagePath) async {
    String text = await FlutterTesseractOcr.extractText(
      imagePath,
      language: 'tam+eng',
      args: {
        "preserve_interword_spaces": "1",
        "psm": "6",
      },
    );

    // கூடுதல் சீரற்ற இடைவெளிகளை ஒழுங்குபடுத்துதல்
    return _cleanText(text);
  }

  String _cleanText(String raw) {
    List<String> lines = raw.split('\n');
    List<String> cleanedLines = [];

    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        // பல இடைவெளிகளை ஒரே இடைவெளியாக மாற்றுதல்
        trimmed = trimmed.replaceAll(RegExp(r'[ \t]+'), ' ');
        cleanedLines.add(trimmed);
      }
    }
    return cleanedLines.join('\n\n');
  }
}
