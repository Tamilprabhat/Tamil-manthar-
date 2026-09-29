import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'ocr_service.dart';

void main() {
  runApp(const TamilMantharApp());
}

class SavedDoc {
  String id;
  String title;
  String content;
  DateTime date;

  SavedDoc({required this.id, required this.title, required this.content, required this.date});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
  };

  factory SavedDoc.fromJson(Map<String, dynamic> json) => SavedDoc(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: json['title'] ?? 'ஆவணம்',
    content: json['content'] ?? '',
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
  );
}

class StorageHelper {
  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tamil_manthar_docs.json');
  }

  static Future<List<SavedDoc>> loadDocs() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List decoded = jsonDecode(content);
      return decoded.map((e) => SavedDoc.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDocs(List<SavedDoc> docs) async {
    try {
      final file = await _getFile();
      final encoded = jsonEncode(docs.map((e) => e.toJson()).toList());
      await file.writeAsString(encoded);
    } catch (_) {}
  }
}

class TamilMantharApp extends StatelessWidget {
  const TamilMantharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'தமிழ் மாந்தர்',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101014),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  List<SavedDoc> _docs = [];
  bool _loadingDocs = true;

  @override
  void initState() {
    super.initState();
    _reloadDocs();
  }

  Future<void> _reloadDocs() async {
    final list = await StorageHelper.loadDocs();
    setState(() {
      _docs = list;
      _loadingDocs = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked == null) return;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiCornerCropScreen(imagePath: picked.path),
        ),
      ).then((_) => _reloadDocs());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('பிழை: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('தமிழ் மாந்தர்', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('திறன் பார்வை (Smart OCR)',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('தேவையான பகுதியை 4 மூலைகளிலும் இழுத்து அளவெடுத்து வெட்டி துல்லியமாக மாற்றலாம்',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 22),
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
                          label: const Text('கேமரா', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Icon(Icons.folder_open, color: Color(0xFFB39DDB), size: 22),
                const SizedBox(width: 8),
                Text('சேமிக்கப்பட்ட ஆவணங்கள் (${_docs.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingDocs)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: Color(0xFFB39DDB)),
              )
            else if (_docs.isEmpty)
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
                itemCount: _docs.length,
                itemBuilder: (context, index) {
                  final doc = _docs[index];
                  return Card(
                    color: const Color(0xFF1E1E24),
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2A2A35),
                        child: Icon(Icons.article, color: Color(0xFFB39DDB)),
                      ),
                      title: Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${doc.date.day}/${doc.date.month}/${doc.date.year} • ${doc.content.replaceAll('\n', ' ')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        onPressed: () async {
                          _docs.removeAt(index);
                          await StorageHelper.saveDocs(_docs);
                          setState(() {});
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => A4DocumentScreen(doc: doc),
                          ),
                        ).then((_) => _reloadDocs());
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

// 4 மூலைகளிலும் இழுத்து மாற்றும் கிராப் திரை
class MultiCornerCropScreen extends StatefulWidget {
  final String imagePath;
  const MultiCornerCropScreen({super.key, required this.imagePath});

  @override
  State<MultiCornerCropScreen> createState() => _MultiCornerCropScreenState();
}

class _MultiCornerCropScreenState extends State<MultiCornerCropScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;

  double _l = 30.0;
  double _t = 80.0;
  double _r = 330.0;
  double _b = 520.0;

  Future<void> _doCropAndOcr(Size previewSize) async {
    setState(() => _isProcessing = true);
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final original = img.decodeImage(bytes);

      String targetPath = widget.imagePath;

      if (original != null) {
        double sx = original.width / previewSize.width;
        double sy = original.height / previewSize.height;

        int x = (_l * sx).round().clamp(0, original.width - 20);
        int y = (_t * sy).round().clamp(0, original.height - 20);
        int w = ((_r - _l) * sx).round().clamp(20, original.width - x);
        int h = ((_b - _t) * sy).round().clamp(20, original.height - y);

        final cropped = img.copyCrop(original, x: x, y: y, width: w, height: h);
        final file = File('${widget.imagePath}_refined_crop.jpg');
        await file.writeAsBytes(img.encodeJpg(cropped, quality: 95));
        targetPath = file.path;
      }

      final text = await _ocrService.extractText(targetPath);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      String initialTitle = text.split('\n').first.replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF]'), '').trim();
      if (initialTitle.isEmpty) initialTitle = "புதிய ஆவணம்";
      if (initialTitle.length > 25) initialTitle = "${initialTitle.substring(0, 25)}...";

      final newDoc = SavedDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: initialTitle,
        content: text,
        date: DateTime.now(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => A4DocumentScreen(doc: newDoc, isNew: true),
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
    final size = MediaQuery.of(context).size;
    final viewHeight = size.height - 130;

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
                  Text('படம் சீரமைக்கப்பட்டு உரை வாசிக்கப்படுகிறது...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : Stack(
              children: [
                Positioned.fill(
                  bottom: 70,
                  child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
                ),
                // கட்டத்தின் நடுப்பகுதியை நகர்த்தும் அமைப்பு
                Positioned(
                  left: _l,
                  top: _t,
                  width: _r - _l,
                  height: _b - _t,
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      setState(() {
                        double w = _r - _l;
                        double h = _b - _t;
                        double newL = (_l + d.delta.dx).clamp(10.0, size.width - w - 10.0);
                        double newT = (_t + d.delta.dy).clamp(10.0, viewHeight - h - 10.0);
                        _l = newL;
                        _t = newT;
                        _r = newL + w;
                        _b = newT + h;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFB39DDB), width: 2.2),
                        color: Colors.purple.withOpacity(0.12),
                      ),
                    ),
                  ),
                ),
                // 1. Top-Left Handle
                Positioned(
                  left: _l - 16,
                  top: _t - 16,
                  child: _buildHandle((d) {
                    setState(() {
                      _l = (_l + d.delta.dx).clamp(10.0, _r - 50.0);
                      _t = (_t + d.delta.dy).clamp(10.0, _b - 50.0);
                    });
                  }),
                ),
                // 2. Top-Right Handle
                Positioned(
                  left: _r - 16,
                  top: _t - 16,
                  child: _buildHandle((d) {
                    setState(() {
                      _r = (_r + d.delta.dx).clamp(_l + 50.0, size.width - 10.0);
                      _t = (_t + d.delta.dy).clamp(10.0, _b - 50.0);
                    });
                  }),
                ),
                // 3. Bottom-Left Handle
                Positioned(
                  left: _l - 16,
                  top: _b - 16,
                  child: _buildHandle((d) {
                    setState(() {
                      _l = (_l + d.delta.dx).clamp(10.0, _r - 50.0);
                      _b = (_b + d.delta.dy).clamp(_t + 50.0, viewHeight - 10.0);
                    });
                  }),
                ),
                // 4. Bottom-Right Handle
                Positioned(
                  left: _r - 16,
                  top: _b - 16,
                  child: _buildHandle((d) {
                    setState(() {
                      _r = (_r + d.delta.dx).clamp(_l + 50.0, size.width - 10.0);
                      _b = (_b + d.delta.dy).clamp(_t + 50.0, viewHeight - 10.0);
                    });
                  }),
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
                    onPressed: () => _doCropAndOcr(Size(size.width, viewHeight)),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('இப்பகுதியை வாசி (OCR)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHandle(GestureDragUpdateCallback onDrag) {
    return GestureDetector(
      onPanUpdate: onDrag,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFB39DDB),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
      ),
    );
  }
}

// நிஜமான வெள்ளை A4 தாள் போன்ற எடிட்டர் திரை
class A4DocumentScreen extends StatefulWidget {
  final SavedDoc doc;
  final bool isNew;
  const A4DocumentScreen({super.key, required this.doc, this.isNew = false});

  @override
  State<A4DocumentScreen> createState() => _A4DocumentScreenState();
}

class _A4DocumentScreenState extends State<A4DocumentScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.doc.title);
    _contentController = TextEditingController(text: widget.doc.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    final docs = await StorageHelper.loadDocs();
    final updatedDoc = SavedDoc(
      id: widget.doc.id,
      title: _titleController.text.trim().isEmpty ? 'ஆவணம்' : _titleController.text.trim(),
      content: _contentController.text,
      date: DateTime.now(),
    );

    int idx = docs.indexWhere((e) => e.id == widget.doc.id);
    if (idx >= 0) {
      docs[idx] = updatedDoc;
    } else {
      docs.insert(0, updatedDoc);
    }

    await StorageHelper.saveDocs(docs);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ஆவணம் போனில் நிரந்தரமாகச் சேமிக்கப்பட்டது!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2A32),
      appBar: AppBar(
        title: const Text('A4 ஆவணத் தாள்', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'எழுத்துப் பெரிதாக்கு',
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(12.0, 30.0)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'எழுத்துச் சிறிதாக்கு',
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(12.0, 30.0)),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'நகலெடு',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${_titleController.text}\n\n${_contentController.text}'));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('முழு உரையும் நகலெடுக்கப்பட்டது!')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Color(0xFFB39DDB), size: 28),
            tooltip: 'சேமி',
            onPressed: _saveAndExit,
          ),
        ],
      ),
      body: InteractiveViewer(
        boundaryMargin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        minScale: 0.7,
        maxScale: 2.2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: Container(
              // சர்வதேச A4 விகிதம் (Standard A4 Dimension)
              width: 595,
              constraints: const BoxConstraints(minHeight: 842),
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 48.0),
              decoration: BoxDecoration(
                color: Colors.white, // நிஜமான காகித வெள்ளை நிறம்
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'தலைப்பு...',
                      hintStyle: TextStyle(color: Colors.black26),
                    ),
                  ),
                  const Divider(color: Colors.black12, thickness: 1.5),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      color: const Color(0xFF222222),
                      fontSize: _fontSize,
                      height: 1.85,
                      letterSpacing: 0.35,
                      fontFamily: 'sans-serif',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'உரையை இங்கே தட்டச்சு செய்து திருத்தலாம்...',
                      hintStyle: TextStyle(color: Colors.black26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
