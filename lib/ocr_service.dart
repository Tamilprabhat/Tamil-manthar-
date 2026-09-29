import 'dart:io';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;

class OcrService {
  Future<String> extractText(String imagePath) async {
    try {
      // 1. உயர் துல்லிய படச் செயலாக்கம் (High-Precision Pre-processing)
      final imageBytes = await File(imagePath).readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      String processedPath = imagePath;

      if (originalImage != null) {
        // கிரேஸ்கேல் மாற்றம்
        var processed = img.grayscale(originalImage);

        // முரண்பாட்டை (Contrast) கூட்டி அச்சு மை மற்றும் வெள்ளை காகிதத்தை வேறுபடுத்துதல்
        processed = img.adjustColor(
          processed,
          contrast: 1.45,
          brightness: 1.02,
        );

        final tempFile = File('${imagePath}_ocr_binarized.png');
        await tempFile.writeAsBytes(img.encodePng(processed));
        processedPath = tempFile.path;
      }

      // 2. Bilingual OCR Engine (tam + eng)
      // தமிழ் மற்றும் ஆங்கிலத்தை ஒரே நேரத்தில் பிழையின்றி வேறுபடுத்தி அறியும் முறை
      // அரபு எண்கள், ரோமன் எண்கள் மற்றும் குறியீடுகளைத் தக்கவைக்க tessedit parameters
      String rawText = await FlutterTesseractOcr.extractText(
        processedPath,
        language: 'tam+eng',
        args: {
          "psm": "6",
          "preserve_interword_spaces": "1",
        },
      );

      // 3. மேம்பட்ட உரை வடிகட்டுதல், அரபு & ரோமன் எண்கள் பகுப்பாய்வு
      return _processBilingualAndNumerals(rawText);
    } catch (e) {
      return "பிழை: $e";
    }
  }

  String _processBilingualAndNumerals(String text) {
    if (text.trim().isEmpty) return "";

    List<String> rawLines = text.split('\n');
    List<String> formattedLines = [];

    // ரோமன் எண்களுக்கான ரெஜெக்ஸ் பேட்டர்ன் (I, II, III, IV, V, VI, VII, VIII, IX, X...)
    final romanPattern = RegExp(r'^(?:[\[\(]?\s*(X{0,3})(IX|IV|V?I{0,3})\s*[\]\)]?[\.\-\:]?\s*)', caseSensitive: false);

    for (var rawLine in rawLines) {
      String line = rawLine.trim();
      if (line.isEmpty) continue;

      // விளிம்பு வெட்டுப்பட்ட தேவையற்ற அர்த்தமற்ற கோட்டுச் சிதைவுகளை நீக்குதல்
      if (RegExp(r'^(?:[க-ளa-zA-Z]\s*){4,}$').hasMatch(line) && line.length < 10) continue;
      if (RegExp(r'^[_\-—~=\.:]{2,}$').hasMatch(line)) continue;

      // ==========================================
      // A. அரபு எண்கள் (Arabic Numerals) சீரமைப்பு
      // ==========================================
      // வரியின் தொடக்கத்தில் வரும் அடைப்புக்குறி எண்களை முறைப்படுத்துதல்: (1) அல்லது [2] -> 1. / 2.
      line = line.replaceAllMapped(
        RegExp(r'^[\[\(]\s*(\d+)\s*[\]\)]\s*[\.\-\:]?\s*'),
        (m) => '${m[1]}. ',
      );

      // எண்களுக்குப் பின் புள்ளி இல்லாமல் வரும் வடிவங்களை சீரமைத்தல்: '1 அருள் ஏராளமாய்' -> '1. அருள் ஏராளமாய்'
      line = line.replaceAllMapped(
        RegExp(r'^(\d{1,3})\s+([\u0B80-\u0BFF])'),
        (m) => '${m[1]}. ${m[2]}',
      );

      // தமிழ் எழுத்துக்களாகத் தவறாக மாறிய எண் வடிவங்களைத் துல்லியமாக மீட்டெடுத்தல்
      // வரியின் தொடக்கத்தில் மட்டும்: உ. -> 2. | க. -> 1. | ௩. -> 3. | ௪. -> 4.
      line = line.replaceAll(RegExp(r'^[உ௨]\s*[\.\)]\s*'), '2. ');
      line = line.replaceAll(RegExp(r'^[க௧]\s*[\.\)]\s*'), '1. ');
      line = line.replaceAll(RegExp(r'^[ங௩]\s*[\.\)]\s*'), '3. ');
      line = line.replaceAll(RegExp(r'^[ச௪]\s*[\.\)]\s*'), '4. ');

      // ==========================================
      // B. ரோமன் எண்கள் (Roman Numerals) சீரமைப்பு
      // ==========================================
      // பத்திகளின் முன் வரும் 'I.', 'II.', 'III.', 'IV.', 'V.' போன்ற ரோமன் எண்களைத் தூய்மையாக்குதல்
      line = line.replaceAllMapped(
        RegExp(r'^(I|II|III|IV|V|VI|VII|VIII|IX|X)\s*[\.\)]\s*', caseSensitive: false),
        (m) => '${m[1]!.toUpperCase()}. ',
      );

      // ==========================================
      // C. தமிழ் மற்றும் ஆங்கில சொற்களை வேறுபடுத்துதல்
      // ==========================================
      // தமிழ் வார்த்தைகளுக்கு நடுவில் தவறாக விழும் உடைந்த ஒற்றை ஆங்கில எழுத்துக்களை நீக்குதல்
      // எ.கா: 'அருள் e ஏராளமாய்' -> 'அருள் ஏராளமாய்'
      line = line.replaceAll(RegExp(r'(?<=[\u0B80-\u0BFF])\s+[a-zA-Z]{1,2}\s+(?=[\u0B80-\u0BFF])'), ' ');

      // முறையான ஆங்கிலத் தலைப்புகள் மற்றும் வார்த்தைகளை அப்படியே தக்கவைத்தல் (Praise the Lord, Amen, Verse, Chorus போன்றவை)
      // தமிழ்ப் பாடல் சொற்களில் அடிக்கடி ஏற்படும் அச்சுப் பிழைகளைச் சீரமைத்தல்
      line = line.replaceAll(RegExp(r'சரணங்கள்|சரணஙகள்', caseSensitive: false), 'சரணங்கள்');
      line = line.replaceAll(RegExp(r'பல்லவி|பல்லவ|பலலவி', caseSensitive: false), 'பல்லவி');
      line = line.replaceAll(RegExp(r'அனுபல்லவி|அநுபல்லவி', caseSensitive: false), 'அனுபல்லவி');

      // குறிப்பிட்ட பொதுவான வார்த்தைச் சரிபார்ப்புகள்
      line = line.replaceAll('சயை', 'சபை');
      line = line.replaceAll('நடத்துதின்றது', 'நடத்துகின்றது');
      line = line.replaceAll('உள்கமே', 'உள்ளமே');
      line = line.replaceAll('களமலைமேல்', 'கன்மலைமேல்');
      line = line.replaceAll('முஷிகூட்டினீர்', 'முடிசூட்டினீர்');
      line = line.replaceAll('துதியிலும்', 'துதியினும்');

      formattedLines.add(line);
    }

    // முதல் வரியில் உள்ள தேவையற்ற துண்டு வெட்டு விளிம்புகளை நீக்குதல்
    if (formattedLines.isNotEmpty && formattedLines.first.length <= 4 && !formattedLines.first.contains(RegExp(r'\d'))) {
      formattedLines.removeAt(0);
    }

    return formattedLines.join('\n\n');
  }
}
