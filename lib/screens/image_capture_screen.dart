import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/item_model.dart';
import 'medications.dart';

class ImageCaptureScreen extends StatefulWidget {
  const ImageCaptureScreen({super.key});

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: '');
  final _styleController = TextEditingController(text: '');
  final _valuationController = TextEditingController(text: '');
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Show image source dialog immediately when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showImageSourceDialog();
    });
  }

  Future<void> _showImageSourceDialog() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Photo Gallery'),
              subtitle: const Text('Select from existing photos'),
              onTap: () {
                Navigator.of(ctx).pop(ImageSource.gallery);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () {
                Navigator.of(ctx).pop(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Also close the screen
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source != null) {
      await _pickImage(source);
    } else {
      // User cancelled, close the screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        setState(() {
          _selectedImage = imageFile;
        });
        await _extractTextFromImage(imageFile);
      } else {
        // User cancelled image selection, close the screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isNotEmpty) {
        setState(() {
          _descriptionController.text = recognizedText.text;
        });

        // Auto-parse the text like in NewElementScreen
        _autoParse(recognizedText.text);
      }
    } catch (e) {
      print('Error extracting text: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _autoParse(String description) {
    String style = _styleController.text;
    String category = _categoryController.text;
    String valuation = _valuationController.text;

    // Split description into lines and check each line
    List<String> lines = description.split('\n');

    // Look for tablet/take keywords for style
    for (String line in lines) {
      String lowercaseLine = line.toLowerCase();
      if (lowercaseLine.contains('tablet') || lowercaseLine.contains('take')) {
        style = line.trim();
        break;
      }
    }

    // Extract dosage pattern
    final RegExp dosagePattern = RegExp(
        r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml)',
        caseSensitive: false);

    for (String line in lines) {
      final match = dosagePattern.firstMatch(line);
      if (match != null) {
        String number = match.group(1)!;
        String unit = match.group(2)!.toLowerCase();

        // Standardize unit formatting
        if (unit == 'ml') unit = 'mL';

        valuation = '$number $unit';
        break;
      }
    }

    // Find medication name from the medications list
    bool found = false;
    for (String line in lines) {
      String lowercaseLine = line.toLowerCase();
      int index = 0;

      if (lowercaseLine.contains(" ")) {
        index = lowercaseLine.indexOf(" ");
      } else {
        index = lowercaseLine.length;
      }

      for (String med in meds) {
        if (lowercaseLine.substring(0, index).contains(med)) {
          category = "${med[0].toUpperCase()}${med.substring(1)}";
          found = true;
          break;
        }
      }
      if (found) break;
    }

    setState(() {
      _categoryController.text = category;
      _styleController.text = style;
      _valuationController.text = valuation;
    });
  }

  void _showValidationAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Required Fields'),
        content: const Text('Please select an image and ensure text was extracted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveItem() {
    if (_selectedImage == null || _descriptionController.text.trim().isEmpty) {
      _showValidationAlert();
      return;
    }

    String description = _descriptionController.text.trim();
    String style = _styleController.text;
    String category = _categoryController.text;
    String valuation = _valuationController.text;

    final newItem = Item.fromFile(
      image: _selectedImage!,
      description: category + "\n" + style + "\n" + valuation,
      category: category,
      style: style,
      valuation: valuation,
    );
    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add from Image'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveItem,
            ),
          ],
        ),
        body: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing image...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image preview
                      if (_selectedImage != null) ...[
                        const Text(
                          'Captured Image:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Choose Different Image'),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Extracted text
                      const Text(
                        'Extracted Text:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: 'Extracted text will appear here',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Parsed fields
                      const Text(
                        'Auto-Parsed Information:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Medication Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.medication),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _styleController,
                        decoration: const InputDecoration(
                          labelText: 'Frequency / How to Take',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _valuationController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_pharmacy),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'You can edit any of the fields above before saving.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _descriptionController.dispose();
    _categoryController.dispose();
    _styleController.dispose();
    _valuationController.dispose();
    super.dispose();
  }
}
