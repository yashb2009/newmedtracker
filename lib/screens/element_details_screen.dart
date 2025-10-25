import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ElementDetailsScreen extends StatefulWidget {
  final Item item;

  const ElementDetailsScreen({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<ElementDetailsScreen> createState() => _ElementDetailsScreenState();
}

class _ElementDetailsScreenState extends State<ElementDetailsScreen> {
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController styleController;
  late TextEditingController valuationController;

  @override
  void initState() {
    super.initState();
    descriptionController =
        TextEditingController(text: widget.item.description);
    categoryController = TextEditingController(text: widget.item.category);
    styleController = TextEditingController(text: widget.item.style);
    valuationController = TextEditingController(text: widget.item.valuation);
  }

  @override
  void dispose() {
    descriptionController.dispose();
    categoryController.dispose();
    styleController.dispose();
    valuationController.dispose();
    super.dispose();
  }

  void _openFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    widget.item.image,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Element Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              final updatedItem = widget.item.copyWith(
                description: descriptionController.text,
                category: categoryController.text,
                style: styleController.text,
                valuation: valuationController.text,
              );
              Navigator.pop(context, updatedItem);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                if (widget.item.image.existsSync()) {
                  _openFullScreenImage(context);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: widget.item.image.existsSync()
                    ? Stack(
                        children: [
                          Image.file(
                            widget.item.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey[300],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 64, color: Colors.grey),
                                    Text('Image not available', style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              );
                            },
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tap to view full screen',
                                    style: TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                            Text('Image file not found', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: descriptionController,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Enter description',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Name:          ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: categoryController,
                          decoration: InputDecoration(
                            hintText: 'Enter the Category',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Frequency: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: styleController,
                          decoration: InputDecoration(
                            hintText: 'Enter the Style',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Dosage:       ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: valuationController,
                          decoration: InputDecoration(
                            hintText: 'Enter the Valuation',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
