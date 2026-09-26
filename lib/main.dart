import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TamilMantharApp());
}

class TamilMantharApp extends StatelessWidget {
  const TamilMantharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'தமிழ் மாந்தர்',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        fontFamily: 'sans',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  final _ocr = OcrService();
  final _textController = TextEditingController();

  bool _busy = false;
  String? _imagePath;
  String _status = 'படத்தைத் தேர்ந்தெடுத்து தமிழ் எழுத்தை பெறுங்கள்.';

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
        maxWidth: 3000,
      );
      if (image == null) return;

      setState(() {
        _busy = true;
        _imagePath = image.path;
        _status = 'தமிழ் எழுத்தை அடையாளம் காண்கிறது…';
      });

      final text = await _ocr.extractTamil(image.path);
      _textController.text = text.trim();

      setState(() {
        _busy = false;
        _status = text.trim().isEmpty
            ? 'எழுத்து கண்டறியப்படவில்லை. தெளிவான படத்தை முயற்சிக்கவும்.'
            : 'OCR முடிந்தது.';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'OCR பிழை: $e';
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: const [
            Text('தமிழ் மாந்தர்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
            Text('Tamil Manthar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Column(
                      children: const [
                        Text(
                          'திறன் பார்வை',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Smart Vision (Tamil & English OCR)',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'இணையம் இல்லாமலேயே தமிழ் மற்றும் ஆங்கில எழுத்துக்களை படத்திலிருந்து பிரித்தெடுக்கவும்.
Extract Tamil & English text offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'இணையம் இல்லாமலேயே தமிழ் எழுத்தை படத்திலிருந்து பிரித்தெடுக்கவும்.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _pick(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('புகைப்படம்'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _pick(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_imagePath != null)
                Text(
                  'தேர்ந்தெடுக்கப்பட்ட படம்: ${_imagePath!.split('/').last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              if (_busy) const LinearProgressIndicator(),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_status),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'OCR மூலம் கிடைக்கும் தமிழ் உரை இங்கே வரும்…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _textController.text.isEmpty
                          ? null
                          : () {
                              _textController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _textController.text.length,
                              );
                            },
                      icon: const Icon(Icons.select_all),
                      label: const Text('தேர்வு'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _textController.text.isEmpty
                          ? null
                          : () => _textController.clear(),
                      icon: const Icon(Icons.clear),
                      label: const Text('அழி'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
