import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class OcrService {
  Future<String> extractTamil(String imagePath) async {
    return FlutterTesseractOcr.extractText(
      imagePath,
      language: 'tam',
      args: {
        'psm': '6',
        'preserve_interword_spaces': '1',
      },
    );
  }
}
