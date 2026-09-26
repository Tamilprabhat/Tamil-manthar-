import 'dart:io';
import 'package:image/image.dart' as img;

class ImageFilterService {
  static Future<String> cleanAndEnhanceForOcr(String inputPath) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return inputPath;

      // 1. சாம்பல் நிறமாக்குதல்
      img.Image gray = img.grayscale(original);

      // 2. எழுத்துக்களின் தடிமனைப் பாதுகாக்கும் மிதமான கான்ட்ராஸ்ட்
      img.Image balanced = img.adjustColor(
        gray,
        contrast: 1.25,
        brightness: 1.05,
      );

      final enhancedPath = inputPath.replaceAll('.jpg', '_enhanced.png');
      await File(enhancedPath).writeAsBytes(img.encodePng(balanced));
      return enhancedPath;
    } catch (e) {
      return inputPath;
    }
  }
}
