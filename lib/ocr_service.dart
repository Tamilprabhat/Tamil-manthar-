import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrService {
  Future<String> extractText(String imagePath) async {
    return await FlutterTesseractOcr.extractText(
      imagePath,
      language: 'tam+eng',
      args: {
        "preserve_interword_spaces": "1",
        "psm": "3",
      },
    );
  }
}
