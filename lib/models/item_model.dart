import 'dart:io';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'item_model.g.dart';

@collection
class Item {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String uniqueId;

  @Index()
  late String imagePath;
  late String description;
  @Index()
  late DateTime dateCreated;
  @Index()
  late DateTime lastModified;
  late String category;
  late String style;
  late String valuation;

  @ignore
  File get image => File(imagePath);

  Item({
    required String imagePath,
    required this.description,
    required this.category,
    required this.style,
    required this.valuation,
  }) : uniqueId = const Uuid().v4() {
    this.imagePath = imagePath;
    this.dateCreated = DateTime.now();
    this.lastModified = DateTime.now();
  }

  factory Item.fromFile({
    required File image,
    required String description,
    required String category,
    required String style,
    required String valuation,
  }) {
    return Item(
      imagePath: image.path,
      description: description,
      category: category,
      style: style,
      valuation: valuation,
    );
  }

  Item._fromDb({
    required this.uniqueId,
    required this.imagePath,
    required this.description,
    required this.dateCreated,
    required this.lastModified,
    required this.category,
    required this.style,
    required this.valuation,
  });

  Item copyWith({
    String? category,
    String? style,
    String? valuation,
    String? description, // Add this line
  }) {
    final item = Item._fromDb(
      uniqueId: this.uniqueId,
      imagePath: this.imagePath,
      description: description ?? this.description, // Add this line
      dateCreated: this.dateCreated,
      lastModified: DateTime.now(),
      category: category ?? this.category,
      style: style ?? this.style,
      valuation: valuation ?? this.valuation,
    );
    item.id = this.id;
    return item;
  }
}
