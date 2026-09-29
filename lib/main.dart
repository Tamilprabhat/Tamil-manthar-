import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ocr_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TamilMantharApp());
}

class SavedDoc {
  String id;
  String title;
  String content;
  DateTime date;

  SavedDoc({required this.id, required this.title, required this.content, required this.date});

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'date': date.toIso8601String(),
  };

  factory SavedDoc.fromMap(Map<String, dynamic> map) => SavedDoc(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: map['title'] ?? 'ஆவணம்',
    content: map['content'] ?? '',
    date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
  );
}

class PrefsStorage {
  static const String _key = 'tamil_manthar_saved_docs_v1';

  static Future<List<SavedDoc>> getDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => SavedDoc.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static String generateUniqueTitle(List<SavedDoc> existingDocs, String baseTitle, {String? excludeId}) {
    String cleanBase = baseTitle.replaceAll(RegExp(r'\s*\(\d+\)$'), '').trim();
    if (cleanBase.isEmpty) cleanBase = 'ஆவணம்';

    List<String> currentTitles = existingDocs
        .where((d) => excludeId == null || d.id != excludeId)
        .map((d) => d.title.trim())
        .toList();

    if (!currentTitles.contains(cleanBase)) {
      return cleanBase;
    }

    int counter = 1;
    while (true) {
      String candidate = '$cleanBase ($counter)';
      if (!currentTitles.contains(candidate)) {
        return candidate;
      }
      counter++;
    }
  }

  static Future<void> saveDoc(SavedDoc newDoc) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedDoc> list = await getDocs();
    newDoc.title = generateUniqueTitle(list, newDoc.title, excludeId: newDoc.id);

    int idx = list.indexWhere((d) => d.id == newDoc.id);
    if (idx >= 0) {
      list[idx] = newDoc;
    } else {
      list.insert(0, newDoc);
    }
    await prefs.setString(_key, jsonEncode(list.map((d) => d.toMap()).toList()));
  }

  static Future<void> deleteDoc(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<SavedDoc> list = await getDocs();
    list.removeWhere((d) => d.id == id);
    await prefs.setString(_key, jsonEncode(list.map((d) => d.toMap()).toList()));
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllDocs();
  }

  Future<void> _loadAllDocs() async {
    final list = await PrefsStorage.getDocs();
    if (mounted) {
      setState(() {
        _docs = list;
        _isLoading = false;
      });
    }
  }

  Future<bool> _requestPermissions(ImageSource source) async {
    if (source == ImageSource.camera) {
      var status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('கேமராவைப் பயன்படுத்த அனுமதி தேவை.')),
        );
        return false;
      }
    } else {
      if (Platform.isAndroid) {
        await Permission.photos.request();
      }
    }
    return true;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      bool granted = await _requestPermissions(source);
      if (!granted && source == ImageSource.camera) return;

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );
      if (picked == null) return;

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PrecisePerspectiveCropScreen(imagePath: picked.path),
        ),
      );
      await _loadAllDocs();
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
      body: RefreshIndicator(
        onRefresh: _loadAllDocs,
        color: const Color(0xFFB39DDB),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text('திறன் பார்வை (Google ML Smart OCR)',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('தேர்ந்தெடுத்த வரியை மட்டும் துல்லியமாக வெட்டி மாற்றலாம்',
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
            const SizedBox(height: 26),
            Row(
              children: [
                const Icon(Icons.folder_open, color: Color(0xFFB39DDB), size: 22),
                const SizedBox(width: 8),
                Text('சேமிக்கப்பட்ட ஆவணங்கள் (${_docs.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Color(0xFFB39DDB)),
                ),
              )
            else if (_docs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.description_outlined, size: 50, color: Colors.white24),
                    SizedBox(height: 12),
                    Text('ஆவணங்கள் எதுவும் சேமிக்கப்படவில்லை', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            else
              ...List.generate(_docs.length, (index) {
                final doc = _docs[index];
                return Card(
                  color: const Color(0xFF1E1E24),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2A2A35),
                      child: Icon(Icons.article, color: Color(0xFFB39DDB)),
                    ),
                    title: Text(doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text(
                      '${doc.date.day}/${doc.date.month}/${doc.date.year} • ${doc.content.replaceAll('\n', ' ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                      onPressed: () async {
                        await PrefsStorage.deleteDoc(doc.id);
                        await _loadAllDocs();
                      },
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => A4DocumentScreen(doc: doc),
                        ),
                      );
                      await _loadAllDocs();
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class PrecisePerspectiveCropScreen extends StatefulWidget {
  final String imagePath;
  const PrecisePerspectiveCropScreen({super.key, required this.imagePath});

  @override
  State<PrecisePerspectiveCropScreen> createState() => _PrecisePerspectiveCropScreenState();
}

class _PrecisePerspectiveCropScreenState extends State<PrecisePerspectiveCropScreen> {
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;

  late Offset p1;
  late Offset p2;
  late Offset p3;
  late Offset p4;
  bool _initialized = false;
  img.Image? _decodedImg;
  String? _normalizedPath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded != null) {
      decoded = img.bakeOrientation(decoded);
      final normalizedFile = File('${widget.imagePath}_oriented.jpg');
      await normalizedFile.writeAsBytes(img.encodeJpg(decoded, quality: 98));

      if (mounted) {
        setState(() {
          _decodedImg = decoded;
          _normalizedPath = normalizedFile.path;
        });
      }
    }
  }

  void _initPoints(Rect renderRect) {
    if (_initialized) return;
    p1 = Offset(renderRect.left + renderRect.width * 0.08, renderRect.top + renderRect.height * 0.25);
    p2 = Offset(renderRect.left + renderRect.width * 0.92, renderRect.top + renderRect.height * 0.25);
    p3 = Offset(renderRect.left + renderRect.width * 0.92, renderRect.top + renderRect.height * 0.65);
    p4 = Offset(renderRect.left + renderRect.width * 0.08, renderRect.top + renderRect.height * 0.65);
    _initialized = true;
  }

  Future<void> _processCrop(Rect renderRect) async {
    setState(() => _isProcessing = true);
    try {
      String targetPath = _normalizedPath ?? widget.imagePath;

      if (_decodedImg != null) {
        double scaleX = _decodedImg!.width / renderRect.width;
        double scaleY = _decodedImg!.height / renderRect.height;

        double minX = [p1.dx, p2.dx, p3.dx, p4.dx].reduce(min) - renderRect.left;
        double maxX = [p1.dx, p2.dx, p3.dx, p4.dx].reduce(max) - renderRect.left;
        double minY = [p1.dy, p2.dy, p3.dy, p4.dy].reduce(min) - renderRect.top;
        double maxY = [p1.dy, p2.dy, p3.dy, p4.dy].reduce(max) - renderRect.top;

        int cropX = (minX * scaleX).round().clamp(0, _decodedImg!.width - 10);
        int cropY = (minY * scaleY).round().clamp(0, _decodedImg!.height - 10);
        int cropW = ((maxX - minX) * scaleX).round().clamp(20, _decodedImg!.width - cropX);
        int cropH = ((maxY - minY) * scaleY).round().clamp(20, _decodedImg!.height - cropY);

        final cropped = img.copyCrop(_decodedImg!, x: cropX, y: cropY, width: cropW, height: cropH);
        final file = File('${widget.imagePath}_exact_crop.jpg');
        await file.writeAsBytes(img.encodeJpg(cropped, quality: 98));
        targetPath = file.path;
      }

      final text = await _ocrService.extractText(targetPath);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      String title = text.split('\n').first.replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF]'), '').trim();
      if (title.isEmpty) title = "புதிய ஆவணம்";
      if (title.length > 25) title = "${title.substring(0, 25)}...";

      final newDoc = SavedDoc(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: text,
        date: DateTime.now(),
      );

      await PrefsStorage.saveDoc(newDoc);

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => A4DocumentScreen(doc: newDoc),
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
    final viewHeight = size.height - 140;

    if (_decodedImg == null || _normalizedPath == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF101014),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFB39DDB))),
      );
    }

    double imgAspect = _decodedImg!.width / _decodedImg!.height;
    double viewAspect = size.width / viewHeight;

    double renderW, renderH, offsetX, offsetY;
    if (imgAspect > viewAspect) {
      renderW = size.width;
      renderH = size.width / imgAspect;
      offsetX = 0;
      offsetY = (viewHeight - renderH) / 2;
    } else {
      renderH = viewHeight;
      renderW = viewHeight * imgAspect;
      offsetX = (size.width - renderW) / 2;
      offsetY = 0;
    }
    final renderRect = Rect.fromLTWH(offsetX, offsetY, renderW, renderH);
    _initPoints(renderRect);

    return Scaffold(
      appBar: AppBar(
        title: const Text('துல்லியமாக மூலைகளைச் சீரமைக்கவும்', style: TextStyle(fontSize: 14)),
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
                Positioned(
                  left: renderRect.left,
                  top: renderRect.top,
                  width: renderRect.width,
                  height: renderRect.height,
                  child: Image.file(File(_normalizedPath!), fit: BoxFit.fill),
                ),
                Positioned.fill(
                  bottom: 70,
                  child: CustomPaint(
                    painter: QuadPolygonPainter(p1: p1, p2: p2, p3: p3, p4: p4),
                  ),
                ),
                _buildPin(p1, (d) {
                  setState(() {
                    p1 = Offset((p1.dx + d.delta.dx).clamp(renderRect.left, renderRect.right),
                                (p1.dy + d.delta.dy).clamp(renderRect.top, renderRect.bottom));
                  });
                }),
                _buildPin(p2, (d) {
                  setState(() {
                    p2 = Offset((p2.dx + d.delta.dx).clamp(renderRect.left, renderRect.right),
                                (p2.dy + d.delta.dy).clamp(renderRect.top, renderRect.bottom));
                  });
                }),
                _buildPin(p3, (d) {
                  setState(() {
                    p3 = Offset((p3.dx + d.delta.dx).clamp(renderRect.left, renderRect.right),
                                (p3.dy + d.delta.dy).clamp(renderRect.top, renderRect.bottom));
                  });
                }),
                _buildPin(p4, (d) {
                  setState(() {
                    p4 = Offset((p4.dx + d.delta.dx).clamp(renderRect.left, renderRect.right),
                                (p4.dy + d.delta.dy).clamp(renderRect.top, renderRect.bottom));
                  });
                }),
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
                    onPressed: () => _processCrop(renderRect),
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('இப்பகுதியை வாசி (OCR)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPin(Offset pos, GestureDragUpdateCallback onDrag) {
    return Positioned(
      left: pos.dx - 22,
      top: pos.dy - 22,
      child: GestureDetector(
        onPanUpdate: onDrag,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFB39DDB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 6)],
          ),
          child: const Center(
            child: Icon(Icons.lens, size: 10, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class QuadPolygonPainter extends CustomPainter {
  final Offset p1, p2, p3, p4;
  QuadPolygonPainter({required this.p1, required this.p2, required this.p3, required this.p4});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..close();

    final fillPaint = Paint()
      ..color = const Color(0xFFB39DDB).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFB39DDB)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant QuadPolygonPainter oldDelegate) => true;
}

class A4DocumentScreen extends StatefulWidget {
  final SavedDoc doc;
  const A4DocumentScreen({super.key, required this.doc});

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
    final updatedDoc = SavedDoc(
      id: widget.doc.id,
      title: _titleController.text.trim().isEmpty ? 'ஆவணம்' : _titleController.text.trim(),
      content: _contentController.text,
      date: DateTime.now(),
    );

    await PrefsStorage.saveDoc(updatedDoc);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ஆவணம் வெற்றிகரமாகச் சேமிக்கப்பட்டது!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF222228),
      appBar: AppBar(
        title: const Text('A4 ஆவணத் தாள்', style: TextStyle(fontSize: 16)),
        backgroundColor: const Color(0xFF1E1E24),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: 'எழுத்துப் பெரிதாக்கு',
            onPressed: () => setState(() => _fontSize = (_fontSize + 2).clamp(12.0, 32.0)),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: 'எழுத்துச் சிறிதாக்கு',
            onPressed: () => setState(() => _fontSize = (_fontSize - 2).clamp(12.0, 32.0)),
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
        boundaryMargin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 30.0),
        minScale: 0.7,
        maxScale: 2.5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          child: Center(
            child: Container(
              width: 595,
              constraints: const BoxConstraints(minHeight: 842),
              padding: const EdgeInsets.symmetric(horizontal: 36.0, vertical: 40.0),
              decoration: BoxDecoration(
                color: Colors.white,
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
                      color: Color(0xFF111111),
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
