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
  ThemeMode _themeMode = ThemeMode.dark;
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
  String _status = 'படத்தைத் தேர்ந்தெடுத்து தமிழ் மற்றும் ஆங்கில உரையைப் பிரித்தெடுக்கவும்.';
  final List<Map<String, String>> _savedDocuments = [];

  Future<void> _pick(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      setState(() {
        _busy = true;
        _status = 'நிழல் நீக்கப்பட்டு உரை பிரித்தெடுக்கப்படுகிறது... காத்திருக்கவும்.';
      });

      final result = await _ocr.extractText(image.path);

      setState(() {
        _textController.text = result;
        _status = result.trim().isEmpty
            ? 'எழுத்துக்கள் எதுவும் கண்டறியப்படவில்லை.'
            : 'OCR முடிந்தது (வெளிச்ச சீரமைப்புடன்).';
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

  void _saveAsDocument() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('சேமிப்பதற்கு உரை எதுவும் இல்லை!')),
      );
      return;
    }

    final titleController = TextEditingController(
      text: 'ஆவணம் ${_savedDocuments.length + 1}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ஆவணமாகச் சேமிக்க'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'ஆவணத் தலைப்பு',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ரத்து'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _savedDocuments.add({
                  'title': titleController.text.trim(),
                  'content': _textController.text,
                  'date': DateTime.now().toString().substring(0, 16),
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ஆவணம் வெற்றிகரமாகச் சேமிக்கப்பட்டது!')),
              );
            },
            child: const Text('சேமி'),
          ),
        ],
      ),
    );
  }

  void _openSavedDocuments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'சேமிக்கப்பட்ட ஆவணங்கள்',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const Divider(),
                  _savedDocuments.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text('ஆவணங்கள் எதுவும் இதுவரை சேமிக்கப்படவில்லை.'),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: _savedDocuments.length,
                            itemBuilder: (context, index) {
                              final doc = _savedDocuments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: const Icon(Icons.description, color: Colors.deepPurple),
                                  title: Text(doc['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(doc['date'] ?? ''),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _savedDocuments.removeAt(index);
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _textController.text = doc['content'] ?? '';
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
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
            icon: const Icon(Icons.folder_open),
            tooltip: 'Saved Documents',
            onPressed: _openSavedDocuments,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile(
                        title: const Text('இருள் முறை (Dark Mode)'),
                        value: widget.isDark,
                        onChanged: (val) {
                          widget.onThemeChanged(val);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 10),
                      Text('எழுத்து அளவு: ${widget.fontSize.toInt()} sp'),
                      Slider(
                        min: 12.0,
                        max: 26.0,
                        divisions: 7,
                        value: widget.fontSize,
                        onChanged: (val) => widget.onFontSizeChanged(val),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                        'Smart Vision (Auto-Enhance & OCR)',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
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
                    hintText: 'OCR உரை தானியங்கித் திருத்தங்களுடன் இங்கே தோன்றும்...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveAsDocument,
                      icon: const Icon(Icons.save),
                      label: const Text('ஆவணமாகச் சேமி'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _textController.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('உரை நகலெடுக்கப்பட்டது!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('நகலெடு'),
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
