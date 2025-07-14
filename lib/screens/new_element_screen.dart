import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import '../models/item_model.dart';
import 'package:uuid/uuid.dart';

class NewElementScreen extends StatefulWidget {
  @override
  State<NewElementScreen> createState() => _NewElementScreenState();
}

class _NewElementScreenState extends State<NewElementScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController(text: '');
  final _styleController = TextEditingController(text: '');
  final _valuationController = TextEditingController(text: '');
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Choose image source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Photo Gallery'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Camera'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isNotEmpty) {
        setState(() {
          _descriptionController.text = recognizedText.text;
        });
      }
    } catch (e) {
      print('Error extracting text: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
      });
      await _extractTextFromImage(imageFile);
    }
  }

  void _showValidationAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Required Fields'),
        content: Text('Please select an image and enter a description.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
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

    // Check description for tablet/take keywords
    String description = _descriptionController.text.trim();
    String style = _styleController.text;

    // Split description into lines and check each line
    List<String> lines = description.split('\n');
    for (String line in lines) {
      String lowercaseLine = line.toLowerCase();
      if (lowercaseLine.contains('tablet') || lowercaseLine.contains('take')) {
        style = line.trim();
        break;
      }
    }

    final newItem = Item.fromFile(
      image: _selectedImage!,
      description: description,
      category: _categoryController.text,
      style: style,
      valuation: _valuationController.text,
    );
    Navigator.pop(context, newItem);
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add new Element'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.check),
              onPressed: _saveItem,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 5, // Allow multiple lines
                  keyboardType:
                      TextInputType.multiline, // Enable multiline input
                  decoration: InputDecoration(
                    hintText: 'Enter your description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true, // Align hint with the first line
                    contentPadding: EdgeInsets.all(16), // Add some padding
                  ),
                ),
              ),
            ],
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
