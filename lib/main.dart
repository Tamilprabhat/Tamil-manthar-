import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'ocr_service.dart';

void main() {
  runApp(const TamilMantharApp());
}

class TamilMantharApp extends StatefulWidget {
  const TamilMantharApp({super.key});

  @override
  State<TamilMantharApp> createState() => _TamilMantharAppState();
}

class _TamilMantharAppState extends State<TamilMantharApp> {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontSize = 16.0;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeFontSize(double size) {
    setState(() {
      _fontSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamil Manthar',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: HomePage(
        isDark: _themeMode == ThemeMode.dark,
        fontSize: _fontSize,
        onThemeChanged: _toggleTheme,
        onFontSizeChanged: _changeFontSize,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final double fontSize;
  final Function(bool) onThemeChanged;
  final Function(double) onFontSizeChanged;

  const HomePage({
    super.key,
    required this.isDark,
    required this.fontSize,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  final _ocr = OcrService();
  final _textController = TextEditingController();

  bool _busy = false;
  String? _imagePath;
  String _status = 'படத்தைத் தேர்ந்தெடுத்து தமிழ் மற்றும் ஆங்கில உரையைப் பிரித்தெடுக்கவும்.';

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _busy = true;
        _imagePath = image.path;
        _status = 'உரை பிரித்தெடுக்கப்படுகிறது... தயவுசெய்து காத்திருக்கவும்.';
      });

      final result = await _ocr.extractText(image.path);

      setState(() {
        _textController.text = result;
        _status = result.trim().isEmpty
            ? 'எழுத்துக்கள் எதுவும் கண்டறியப்படவில்லை.'
            : 'OCR முடிந்தது.';
      });
    } catch (e) {
      setState(() {
        _status = 'OCR பிழை: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'அமைப்புகள் / Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('இருள் முறை (Dark Mode)'),
                    subtitle: const Text('இரவு நேர வாசிப்புக்கு ஏற்றது'),
                    value: widget.isDark,
                    onChanged: (val) {
                      widget.onThemeChanged(val);
                      setModalState(() {});
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('எழுத்து அளவு (Font Size): ${widget.fontSize.toInt()} sp'),
                  Slider(
                    min: 12.0,
                    max: 26.0,
                    divisions: 7,
                    label: '${widget.fontSize.toInt()}',
                    value: widget.fontSize,
                    onChanged: (val) {
                      widget.onFontSizeChanged(val);
                      setModalState(() {});
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('செயலி பற்றி (About App)'),
                    subtitle: const Text('தமிழ் மாந்தர் v1.0.0 (Offline OCR)'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('தமிழ் மாந்தர் (Tamil Manthar)'),
        content: const Text(
          'பதிப்பு: 1.0.0\n\n'
          'முற்றிலும் இணையம் தேவையின்றி (100% Offline) இயங்கக்கூடிய தமிழ் மற்றும் ஆங்கில OCR செயலி.\n\n'
          'அச்சிடப்பட்ட ஆவணங்கள், புத்தகங்கள் மற்றும் தாள்களில் உள்ள எழுத்துக்களை இடைவெளி சிதறாமல் துல்லியமாக மாற்ற வடிவமைக்கப்பட்டுள்ளது.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('சரி (OK)'),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _showSettingsModal,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'திறன் பார்வை',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Smart Vision (Tamil & English OCR)',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'இணையம் இல்லாமலேயே தமிழ் மற்றும் ஆங்கில எழுத்துக்களைப் பிரித்தெடுக்கவும்.\nExtract Tamil & English text offline.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _busy ? null : () => _pick(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('புகைப்படம்'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _busy ? null : () => _pick(ImageSource.gallery),
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
                  'தேர்ந்தெடுக்கப்பட்ட படம்: ${_imagePath!.split("/").last}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 6),
              Text(_status, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 12,
                  style: TextStyle(fontSize: widget.fontSize, height: 1.5),
                  decoration: const InputDecoration(
                    hintText: 'OCR மூலம் கிடைக்கும் உரை இங்கே சீரான இடைவெளியுடன் வரும்...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _textController.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('உரை நகலெடுக்கப்பட்டது (Copied)')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('நகலெடு'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        setState(() {
                          _textController.clear();
                          _imagePath = null;
                          _status = 'அழிக்கப்பட்டது.';
                        });
                      },
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
