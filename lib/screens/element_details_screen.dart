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
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: widget.item.image.existsSync()
                  ? Image.file(
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
                        'Category:  ',
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
                        'Style:         ',
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
                        'Valuation:  ',
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
