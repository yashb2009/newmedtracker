import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/item_model.dart';
import 'medications.dart';
import 'package:uuid/uuid.dart';
import '../services/preferences_service.dart';
import '../widgets/bottle_instructions_dialog.dart';

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
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isStreaming = false;
  DateTime _lastNewTextTime = DateTime.now();
  bool _rotationComplete = false;
  bool _isProcessing = false;
  int _frameCount = 0;
  bool _hasCapture = false; // Track if we've captured a frame
  bool _hasShownInstructionsThisSession = false; // Track if instructions were shown

  final List<TextBlock> _allTextBlocks = [];
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _startStreaming() {
    _cameraController!.startImageStream((CameraImage image) async {
      // Skip most frames to reduce CPU load (every 10th frame in this case)
      _frameCount++;
      if (_frameCount % 10 != 0) return;

      if (_isProcessing) return;
      _isProcessing = true;

      try {
        // Capture the first frame as image for storage
        if (!_hasCapture) {
          await _captureFrameAsImage(image);
          _hasCapture = true;
        }
        
        await _processImage(image);
      } finally {
        _isProcessing = false;
      }
    });

    setState(() {
      _isStreaming = true;
    });
  }

  Future<void> _captureFrameAsImage(CameraImage image) async {
    try {
      // Convert CameraImage to bytes
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Create InputImage for format conversion
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final int sensorOrientation = _cameraController!.description.sensorOrientation;
      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
              InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      // Save the image to temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = path.join(tempDir.path, fileName);

      // For simplicity, we'll take a photo using the camera controller
      // This is more reliable than converting CameraImage format
      await _takePhoto();
      
    } catch (e) {
      print("Error capturing frame: $e");
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile photo = await _cameraController!.takePicture();
      setState(() {
        _selectedImage = File(photo.path);
      });
    } catch (e) {
      print("Error taking photo: $e");
    }
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(image.width.toDouble(), image.height.toDouble());

      final int sensorOrientation =
          _cameraController!.description.sensorOrientation;
      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageMetadata,
      );

      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Make sure we stitch and update UI
      _stitchText(recognizedText);

    } catch (e) {
      print("Error processing image: $e");
    }
  }

  void _stitchText(RecognizedText recognizedText) {
    bool newBlockAdded = false;

    for (final block in recognizedText.blocks) {
      final text = block.text.trim();

      // Skip garbage / very short strings
      if (text.length < 3) continue;

      // Skip if similar text already exists
      if (_allTextBlocks.any((b) =>
          b.text.toLowerCase() == text.toLowerCase() &&
          (b.boundingBox.top - block.boundingBox.top).abs() < 15)) {
        continue;
      }

      _allTextBlocks.add(block);
      newBlockAdded = true;
    }

    if (newBlockAdded) {
      _lastNewTextTime = DateTime.now();

      // Update live preview
      final fullText =
          _allTextBlocks.map((b) => b.text).join("\n");

      setState(() {
        _descriptionController.text = fullText;
      });
    } else {
      final duration = DateTime.now().difference(_lastNewTextTime);
      if (!_rotationComplete && duration > Duration(seconds: 2)) {
        _rotationComplete = true;
        _onRotationComplete();
      }
    }
  }

  void _onRotationComplete() {
    final fullText = _allTextBlocks.map((b) => b.text).join("\n");
    setState(() {
      _descriptionController.text = fullText;
    });

    // Stop streaming automatically
    if (_isStreaming) {
      _cameraController?.stopImageStream();
      setState(() {
        _isStreaming = false;
      });
    }
  }

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
        _hasCapture = true; // Mark as having an image
      });
      await _extractTextFromImage(imageFile);
    }
  }

  void _showValidationAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Required Fields'),
        content: Text('Please capture an image and enter a description.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSaveCancelDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Save Medication'),
        content: Text('Would you like to save this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text('Cancel', style: TextStyle(fontSize: 18)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop('save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Save', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (result == 'save') {
      _saveItem();
    } else if (result == 'cancel') {
      // Just close the modal without saving
      Navigator.pop(context);
    }
  }

  void _saveItem() {
    if (_selectedImage == null || _descriptionController.text.trim().isEmpty) {
      _showValidationAlert();
      return;
    }

    // Check description for tablet/take keywords
    String description = _descriptionController.text.trim();
    String style = _styleController.text;
    String category = _categoryController.text;
    String valuation = _valuationController.text;

    // Split description into lines and check each line
    List<String> lines = description.split('\n');
    for (String line in lines) {
      String lowercaseLine = line.toLowerCase();
      if (lowercaseLine.contains('tablet') || lowercaseLine.contains('take')) {
        style = line.trim();
        break;
      }
    }

    final RegExp dosagePattern = RegExp(r'(\d+(?:\.\d+)?)\s*(mg|mcg|g|ml)', caseSensitive: false);

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

    bool found = false;

    for (String line in lines) {
      String lowercaseLine = line.toLowerCase();
      int index = 0;

      if (lowercaseLine.contains(" "))
      {
        index = lowercaseLine.indexOf(" ");
      }
      else
      {
        index = lowercaseLine.length;
      }

      for (String med in meds) {
        if (lowercaseLine.substring(0, index).contains(med)) {
          category = "${med[0].toUpperCase()}${med.substring(1)}";;
          found = true;
          break;
        }
      }
      if (found) break;
    }

    final newItem = Item.fromFile(
      image: _selectedImage!,
      description: category + "\n" + style + "\n" + valuation,
      category: category,
      style: style,
      valuation: valuation,
    );
    Navigator.pop(context, newItem);
  }

  // Method to manually capture current frame
  Future<void> _captureCurrentFrame() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _takePhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return FractionallySizedBox(
      heightFactor: 0.95,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add new Element'),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        Container(
                          width: 300,
                          height: 400,
                          child: CameraPreview(_cameraController!),
                        ),
                        // Show captured indicator
                        if (_hasCapture)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text('Captured', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: 'Enter your description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Full-width button at bottom
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  if (_isStreaming) {
                    _cameraController?.stopImageStream();
                    setState(() => _isStreaming = false);
                    // Show save/cancel dialog after stopping
                    _showSaveCancelDialog();
                  } else {
                    // Check if we should show the bottle instructions dialog
                    final prefs = await PreferencesService.getInstance();
                    final shouldShowInstructions = !prefs.getDoNotShowBottleInstructions();

                    if (shouldShowInstructions && !_hasShownInstructionsThisSession) {
                      // Show the instructions dialog
                      await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => const BottleInstructionsDialog(),
                      );
                      setState(() {
                        _hasShownInstructionsThisSession = true;
                      });
                      // Return so user has to click Start again to actually start
                      return;
                    }

                    // Start streaming
                    _rotationComplete = false;
                    _allTextBlocks.clear();
                    _lastNewTextTime = DateTime.now();
                    _hasCapture = false; // Reset capture flag
                    _startStreaming();
                    setState(() => _isStreaming = true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isStreaming ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isStreaming ? Icons.stop : Icons.play_arrow, size: 28),
                    const SizedBox(width: 8),
                    Text(_isStreaming ? 'STOP' : 'START'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    _descriptionController.dispose();
    _categoryController.dispose();
    _styleController.dispose();
    _valuationController.dispose();
    super.dispose();
  }
}