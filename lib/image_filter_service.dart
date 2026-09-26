import 'dart:io';
import 'package:image/image.dart' as img;

class ImageFilterService {
  static Future<String> cleanAndEnhanceForOcr(String inputPath) async {
    try {
      final bytes = await File(inputPath).readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) return inputPath;

      // 1. சாம்பல் நிறத்திற்கு மாற்றுதல் (Grayscale)
      img.Image gray = img.grayscale(original);

      // 2. ஆட்டோ கான்ட்ராஸ்ட் மற்றும் வெளிச்ச சீரமைப்பு (நிழலை நீக்க)
      img.Image contrastAdjusted = img.adjustColor(
        gray,
        contrast: 1.4,
        brightness: 1.15,
      );

      // 3. எழுத்துக்களைக் கூர்மையாக்குதல் (Sharpening)
      img.Image sharp = img.convolution(contrastAdjusted, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ]);

      final enhancedPath = inputPath.replaceAll('.jpg', '_enhanced.png');
      await File(enhancedPath).writeAsBytes(img.encodePng(sharp));
      return enhancedPath;
    } catch (e) {
      return inputPath;
    }
  }
}
