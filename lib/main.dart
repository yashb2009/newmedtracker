import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'screens/new_element_screen.dart';
import 'screens/pin_screen.dart';
import 'models/item_model.dart';
import 'screens/element_details_screen.dart';
import 'services/isar_service.dart';

void main() {
  runApp(MyFirstApp());
}

class MyFirstApp extends StatelessWidget {
  const MyFirstApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "My First App",
      initialRoute: '/',
      routes: {
        '/': (context) => const PinScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Item> items = [];
  final DateFormat _dateFormatter = DateFormat('MMM d, y - h:mm a');
  DateTime _lastModifiedDate = DateTime.now();
  final IsarService _isarService = IsarService();
  bool _isTileView = false; // Toggle state for tile/list view

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final loadedItems = await _isarService.getAllItems();
      setState(() {
        items.clear();
        items.addAll(loadedItems);
        if (loadedItems.isNotEmpty) {
          _lastModifiedDate = loadedItems
              .map((e) => e.lastModified)
              .reduce((a, b) => a.isAfter(b) ? a : b);
        }
      });
    } catch (e) {
      print('Error loading items: $e');
      // If there's an error loading items, just continue with empty list
      setState(() {
        items.clear();
      });
    }
  }

  void _sortItems() {
    setState(() {
      items.sort((a, b) {
        // Get first line of each description
        String firstLineA = a.description.split('\n').first;
        String firstLineB = b.description.split('\n').first;
        return firstLineA.compareTo(firstLineB);
      });
      _updateLastModified();
    });
  }

  Future<void> _addItem(Item newItem) async {
    await _isarService.saveItem(newItem);
    await _loadItems();
  }

  Future<void> _updateItem(Item updatedItem) async {
    await _isarService.updateItem(updatedItem);
    await _loadItems();
  }

  Future<void> _deleteItem(Item item) async {
    await _isarService.deleteItem(item);
    await _loadItems();
  }

  void _updateLastModified() {
    setState(() {
      _lastModifiedDate = DateTime.now();
    });
  }

  Widget _buildTileView() {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () async {
            final updatedItem = await Navigator.push<Item>(
              context,
              MaterialPageRoute(
                builder: (context) => ElementDetailsScreen(item: item),
              ),
            );
            if (updatedItem != null) {
              await _updateItem(updatedItem);
            }
          },
          onLongPress: () async {
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Item'),
                content: Text('Are you sure you want to delete this item?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (shouldDelete == true) {
              await _deleteItem(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Item deleted')),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.image.existsSync()
                    ? Image.file(
                        item.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                      ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My First App"),
        leading: IconButton(
          icon: Icon(Icons.sort),
          onPressed: _sortItems,
        ),
        actions: [
          IconButton(
            icon: Icon(_isTileView ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _isTileView = !_isTileView;
              });
            },
            tooltip: _isTileView ? 'List View' : 'Tile View',
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final newItem = await showModalBottomSheet<Item>(
                context: context,
                isScrollControlled: true,
                builder: (context) => NewElementScreen(),
              );

              if (newItem != null) {
                await _addItem(newItem);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total items: ${items.length}'),
                Text(
                    'Last modified: ${_dateFormatter.format(_lastModifiedDate)}'),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Please take the first image',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : _isTileView
                    ? _buildTileView()
                    : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item.id.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 16),
                          child: Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          final item = items[index];
                          await _deleteItem(item);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Item deleted')),
                          );
                        },
                        child: ListTile(
                          leading: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: item.image.existsSync()
                                    ? Image.file(
                                        item.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.broken_image, color: Colors.grey),
                                          );
                                        },
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                              ),
                              Container(
                                padding: EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            item.description,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Created: ${_dateFormatter.format(item.dateCreated)}',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                'Modified: ${_dateFormatter.format(item.lastModified)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            final updatedItem = await Navigator.push<Item>(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ElementDetailsScreen(item: item),
                              ),
                            );
                            if (updatedItem != null) {
                              await _updateItem(updatedItem);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
