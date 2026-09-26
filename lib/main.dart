import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
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

// முதல் திரை: முகப்புப் பக்கம்
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      if (!mounted) return;
      // உள்ளமைந்த கிராப்பிங் திரைக்குச் செல்லுதல்
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BuiltinCropScreen(imagePath: picked.path),
        ),
      );
    } catch (e) {
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
                      'Smart Vision (Built-in Crop & OCR)',
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
                            onPressed: () => _pickImage(ImageSource.camera),
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
                            onPressed: () => _pickImage(ImageSource.gallery),
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
              const Text(
                'படத்தைத் தேர்ந்தெடுத்து தேவையான பகுதியை மட்டும் வெட்டி எடுத்து துல்லியமாக OCR செய்யவும்.',
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

// உள்ளமைந்த இன்டராக்டிவ் கிராப்பிங் திரை (Pure Flutter)
class BuiltinCropScreen extends StatefulWidget {
  final String imagePath;
  const BuiltinCropScreen({super.key, required this.imagePath});

  @override
  State<BuiltinCropScreen> createState() => _BuiltinCropScreenState();
}

class _BuiltinCropScreenState extends State<BuiltinCropScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;

  // கிராப்பிங் பகுதிக்கான ஆரம்ப எல்லைகள் (சதவீதத்தில்: 5% விளிம்பு தவிர்த்து)
  double _left = 0.05;
  double _top = 0.05;
  double _right = 0.95;
  double _bottom = 0.95;

  Future<void> _processAndCrop() async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final original = img.decodeImage(bytes);

      String targetPath = widget.imagePath;

      if (original != null) {
        int x = (_left * original.width).round().clamp(0, original.width - 10);
        int y = (_top * original.height).round().clamp(0, original.height - 10);
        int w = ((_right - _left) * original.width).round().clamp(10, original.width - x);
        int h = ((_bottom - _top) * original.height).round().clamp(10, original.height - y);

        final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
        final croppedFile = File('${widget.imagePath}_cropped.jpg');
        await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));
        targetPath = croppedFile.path;
      }

      final text = await _ocrService.extractText(targetPath);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // A4 தாள் ஆவணத் திரைக்குச் செல்லுதல்
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentEditorScreen(initialText: text),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('பிழை: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('தேவையான பகுதியைத் தேர்வு செய்யவும்', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFFB39DDB)),
            tooltip: 'உரையைப் படி (OCR)',
            onPressed: _isProcessing ? null : _processAndCrop,
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFB39DDB)),
                  SizedBox(height: 16),
                  Text('படம் துல்லியமாகச் சீரமைக்கப்பட்டு உரை வாசிக்கப்படுகிறது...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(widget.imagePath), fit: BoxFit.contain),
                    // வழிகாட்டி கட்டம்
                    Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFB39DDB), width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 30,
                      right: 30,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB39DDB),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: _processAndCrop,
                        icon: const Icon(Icons.document_scanner),
                        label: const Text('உரையாக மாற்று (OCR)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// இரண்டாவது திரை: A4 தாள் ஆவண எடிட்டர் (Rich A4 Document Page)
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
        title: const Text('ஆவணத் தாள் (A4 Editor)', style: TextStyle(fontSize: 16)),
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
            tooltip: 'முடிந்தது',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, minHeight: 750),
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
