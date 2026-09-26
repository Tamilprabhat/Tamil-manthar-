import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'ocr_service.dart';

void main() {
  runApp(const TamilMantharApp());
}

class TamilMantharApp extends StatelessWidget {
  const TamilMantharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'தமிழ் மாந்தர்',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121214),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB39DDB),
          secondary: Color(0xFF9575CD),
          surface: Color(0xFF1E1E24),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// முதல் திரை: முகப்புப் பக்கம் (Home Screen)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  bool _isLoading = false;

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      // கிராப்பிங் திரை திறத்தல்
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'படத்தை ஒழுங்கமைக்கவும்',
            toolbarColor: const Color(0xFF1E1E24),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() => _isLoading = true);

      // OCR மூலம் உரையைப் பிரித்தெடுத்தல்
      String extractedText = await _ocrService.extractText(croppedFile.path);

      setState(() => _isLoading = false);

      if (!mounted) return;

      // இரண்டாவது திரைக்குச் செல்லுதல் (A4 Document Editor)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentEditorScreen(initialText: extractedText),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('பிழை: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('தமிழ் மாந்தர்', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'திறன் பார்வை',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smart Vision (Crop & OCR)',
                      style: TextStyle(fontSize: 13, color: Colors.white60),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB39DDB),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _isLoading ? null : () => _pickAndProcessImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('புகைப்படம்', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: _isLoading ? null : () => _pickAndProcessImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFB39DDB)),
                    SizedBox(height: 12),
                    Text('படம் தூய்மைப்படுத்தப்பட்டு உரை வாசிக்கப்படுகிறது...', style: TextStyle(color: Colors.white70)),
                  ],
                )
              else
                const Text(
                  'படத்தைத் தேர்ந்தெடுத்து துல்லியமாகத் தமிழ் மற்றும் ஆங்கில உரையைப் பிரித்தெடுக்கவும்.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// இரண்டாவது திரை: A4 தாள் ஆவண எடிட்டர் (Document Editor Screen)
class DocumentEditorScreen extends StatefulWidget {
  final String initialText;
  const DocumentEditorScreen({super.key, required this.initialText});

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('உரை நகலெடுக்கப்பட்டது!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F12),
      appBar: AppBar(
        title: const Text('ஆவணத் தாள் (A4)', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'நகலெடு',
            onPressed: _copyToClipboard,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'முடித்தல்',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, minHeight: 700),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: const Color(0xFF18181E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 16.0,
                height: 1.8,
                letterSpacing: 0.3,
                fontFamily: 'Roboto',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'உரையை இங்கே தட்டச்சு செய்து திருத்தலாம்...',
                hintStyle: TextStyle(color: Colors.white24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
