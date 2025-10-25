import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/item_model.dart';

class IsarService {
  static Isar? _isar;
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ItemSchema],
      directory: dir.path,
      inspector: true,
    );
    return _isar!;
  }

  Future<List<Item>> getAllItems() async {
    final isar = await db;
    return await isar.items.where().findAll();
  }

  Future<void> saveItem(Item item) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.items.put(item);
    });
  }

  Future<void> deleteItem(Item item) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.items.delete(item.id);
    });
  }

  Future<void> updateItem(Item item) async {
    await saveItem(item);
  }

  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }
}
