import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/todo.dart';

class TodoRepository {
  static const _boxName = 'todos';
  late Box<Todo> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Todo>(_boxName);
  }

  Future<String> _appImageDirPath() async {
    final dir = await getApplicationSupportDirectory();
    final imgDir = Directory('${dir.path}/images');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    return imgDir.path;
  }

  Future<String?> importImageToAppFolder(String sourcePath) async {
    try {
      final imgDir = await _appImageDirPath();
      final file = File(sourcePath);
      if (!await file.exists()) return null;
      final ext = sourcePath.split('.').last;
      final id = const Uuid().v4();
      final destPath = '$imgDir/$id.$ext';
      await file.copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }

  Iterable<Todo> getAllActive() =>
      _box.values.where((t) => t.deletedAt == null).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Iterable<Todo> getAllTrashed() =>
      _box.values.where((t) => t.deletedAt != null).toList()
        ..sort((a, b) => (b.deletedAt ?? DateTime(0)).compareTo(a.deletedAt ?? DateTime(0)));

  Future<Todo> create({
    required String title,
    required String description,
    String? imagePath,
    required Priority priority,
    DateTime? reminderAt,
  }) async {
    final id = const Uuid().v4();
    String? storedImagePath = imagePath;
    if (storedImagePath != null) {
      storedImagePath = await importImageToAppFolder(storedImagePath);
    }
    final todo = Todo(
      id: id,
      title: title,
      description: description,
      imagePath: storedImagePath,
      priority: priority,
      createdAt: DateTime.now(),
      reminderAt: reminderAt,
      reminderAck: false,
    );
    await _box.put(id, todo);
    return todo;
  }

  Future<void> update(Todo todo) async => _box.put(todo.id, todo);

  Future<void> softDelete(String id) async {
    final t = _box.get(id);
    if (t == null) return;
    t.deletedAt = DateTime.now();
    await t.save();
  }

  Future<void> restore(String id) async {
    final t = _box.get(id);
    if (t == null) return;
    t.deletedAt = null;
    await t.save();
  }

  Future<void> purgeExpiredTrash({Duration grace = const Duration(days: 30)}) async {
    final now = DateTime.now();
    final toDelete = _box.values.where((t) =>
    t.deletedAt != null && now.difference(t.deletedAt!).abs() > grace).toList();
    for (final t in toDelete) {
      await _box.delete(t.id);
      if (t.imagePath != null) {
        final f = File(t.imagePath!);
        if (await f.exists()) { try { await f.delete(); } catch (_) {} }
      }
    }
  }

  List<Todo> dueReminders(DateTime now) => _box.values.where((t) =>
  t.deletedAt == null && t.reminderAt != null && !t.reminderAck && !t.reminderAt!.isAfter(now)
  ).toList();

  Future<void> markReminderShown(String id) async {
    final t = _box.get(id);
    if (t == null) return;
    t.reminderAck = true;
    await t.save();
  }
}
