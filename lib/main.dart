import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'ocr_service.dart';

void main() {
  runApp(const TamilMantharApp());
}

// சேமிக்கப்பட்ட ஆவணங்களின் மாதிரி அமைப்பு
class SavedDoc {
  final String title;
  final String content;
  final DateTime date;
  SavedDoc({required this.title, required this.content, required this.date});
}

// செயலியில் ஆவணங்களை நினைவில் வைத்திருக்கப் பொதுப் பட்டியல்
List<SavedDoc> savedDocuments = [];

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

// 1. முகப்புப் பக்கம் & சேமிக்கப்பட்ட ஆவணங்கள்
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdjustableCropScreen(imagePath: picked.path),
        ),
      ).then((_) => setState(() {}));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('பிழை: $e')));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text('திறன் பார்வை (Smart OCR)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('தேவையான பகுதியை மட்டும் அளவெடுத்து வெட்டித் துல்லியமாக மாற்றலாம்',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB39DDB),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('கேமரா', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('கேலரி', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.folder_open, color: Color(0xFFB39DDB), size: 20),
                const SizedBox(width: 8),
                Text('சேமிக்கப்பட்ட ஆவணங்கள் (${savedDocuments.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (savedDocuments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.description_outlined, size: 48, color: Colors.white24),
                    SizedBox(height: 10),
                    Text('ஆவணங்கள் எதுவும் சேமிக்கப்படவில்லை', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: savedDocuments.length,
                itemBuilder: (context, index) {
                  final doc = savedDocuments[index];
                  return Card(
                    color: const Color(0xFF1E1E24),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2A2A35),
                        child: Icon(Icons.article, color: Color(0xFFB39DDB)),
                      ),
                      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${doc.date.day}/${doc.date.month}/${doc.date.year} - ${doc.content.replaceAll('\n', ' ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          setState(() => savedDocuments.removeAt(index));
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DocumentEditorScreen(initialText: doc.content, docIndex: index),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// 2. எளிதாக நகர்த்தி அளவை மாற்றக்கூடிய கிராப்பிங் திரை (Draggable & Resizable Crop)
class AdjustableCropScreen extends StatefulWidget {
  final String imagePath;
  const AdjustableCropScreen({super.key, required this.imagePath});

  @override
  State<AdjustableCropScreen> createState() => _AdjustableCropScreenState();
}

class _AdjustableCropScreenState extends State<AdjustableCropScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;

  // கிராப் எல்லைகள்: [top, left, width, height] பிக்சல் அடிப்படையில்
  Rect _cropRect = const Rect.fromLTWH(40, 100, 280, 420);

  Future<void> _processCrop(Size displaySize) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final original = img.decodeImage(bytes);

      String targetPath = widget.imagePath;

      if (original != null) {
        // திரையின் அளவிலிருந்து படத்தின் அசல் அளவிற்கு விகிதம் கணக்கிடுதல்
        double scaleX = original.width / displaySize.width;
        double scaleY = original.height / displaySize.height;

        int x = (_cropRect.left * scaleX).round().clamp(0, original.width - 20);
        int y = (_cropRect.top * scaleY).round().clamp(0, original.height - 20);
        int w = (_cropRect.width * scaleX).round().clamp(20, original.width - x);
        int h = (_cropRect.height * scaleY).round().clamp(20, original.height - y);

        final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
        final croppedFile = File('${widget.imagePath}_manual_crop.jpg');
        await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));
        targetPath = croppedFile.path;
      }

      final text = await _ocrService.extractText(targetPath);

      if (!mounted) return;
      setState(() => _isProcessing = false);

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
    final screenSize = MediaQuery.of(context).size;
    final viewAreaHeight = screenSize.height - 140;

    return Scaffold(
      appBar: AppBar(
        title: const Text('தேவையான பகுதியை அளவெடுக்கவும்', style: TextStyle(fontSize: 15)),
        backgroundColor: const Color(0xFF1E1E24),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFB39DDB)),
                  SizedBox(height: 16),
                  Text('தேர்ந்தெடுத்த பகுதி வாசிக்கப்படுகிறது...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  bottom: 70,
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.fill,
                  ),
                ),
                // சுருக்கி விரிக்கக்கூடிய கிராப் கட்டம்
                Positioned(
                  left: _cropRect.left,
                  top: _cropRect.top,
                  width: _cropRect.width,
                  height: _cropRect.height,
                  child: Stack(
                    children: [
                      // கட்டத்தை நகர்த்துவதற்கான தளம்
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _cropRect = Rect.fromLTWH(
                              (_cropRect.left + details.delta.dx).clamp(10, screenSize.width - _cropRect.width - 10),
                              (_cropRect.top + details.delta.dy).clamp(10, viewAreaHeight - _cropRect.height - 10),
                              _cropRect.width,
                              _cropRect.height,
                            );
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFB39DDB), width: 2.5),
                            color: Colors.purple.withOpacity(0.12),
                          ),
                        ),
                      ),
                      // வலது கீழ் மூலையை இழுத்து அளவை மாற்றும் கைப்பிடி (Resize Handle)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              double newW = (_cropRect.width + details.delta.dx).clamp(80.0, screenSize.width - _cropRect.left - 10);
                              double newH = (_cropRect.height + details.delta.dy).clamp(80.0, viewAreaHeight - _cropRect.top - 10);
                              _cropRect = Rect.fromLTWH(_cropRect.left, _cropRect.top, newW, newH);
                            });
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFB39DDB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_out_map, size: 20, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB39DDB),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => _processCrop(Size(screenSize.width, viewAreaHeight)),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('இப்பகுதியை வாசி (OCR)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }
}

// 3. A4 தாள் வடிவம், ஜூம்/அளவு பார்வை மற்றும் நிரந்தர சேமிப்பு வசதி கொண்ட எடிட்டர்
class DocumentEditorScreen extends StatefulWidget {
  final String initialText;
  final int? docIndex;
  const DocumentEditorScreen({super.key, required this.initialText, this.docIndex});

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late TextEditingController _controller;
  double _fontScale = 16.0;

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

  void _saveDocument() {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    String title = text.split('\n').first.replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF]'), '').trim();
    if (title.isEmpty) title = "ஆவணம் ${savedDocuments.length + 1}";
    if (title.length > 25) title = "${title.substring(0, 25)}...";

    if (widget.docIndex != null) {
      savedDocuments[widget.docIndex!] = SavedDoc(title: title, content: text, date: DateTime.now());
    } else {
      savedDocuments.insert(0, SavedDoc(title: title, content: text, date: DateTime.now()));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ஆவணம் வெற்றிகரமாகச் சேமிக்கப்பட்டது!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      appBar: AppBar(
        title: const Text('A4 ஆவணப் பக்கம்', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'எழுத்து பெரிதாக்கு',
            onPressed: () => setState(() => _fontScale = (_fontScale + 2).clamp(12.0, 28.0)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'எழுத்து சிறிதாக்கு',
            onPressed: () => setState(() => _fontScale = (_fontScale - 2).clamp(12.0, 28.0)),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'நகலெடு',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _controller.text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('உரை நகலெடுக்கப்பட்டது!')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFFB39DDB)),
            tooltip: 'சேமி',
            onPressed: _saveDocument,
          ),
        ],
      ),
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(20.0),
        minScale: 0.8,
        maxScale: 2.5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: Container(
              // உண்மையான A4 விகிதம்: அகலம் 595, உயரம் ~842 (A4 Standard Aspect Ratio)
              width: 595,
              constraints: const BoxConstraints(minHeight: 842),
              padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 42.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C22),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white24, width: 1.2),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: TextStyle(
                  color: const Color(0xFFF1F5F9),
                  fontSize: _fontScale,
                  height: 1.9,
                  letterSpacing: 0.4,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'உரையைத் தட்டச்சு செய்து திருத்தலாம்...',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
