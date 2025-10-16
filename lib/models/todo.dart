import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 1)
enum Priority {
  @HiveField(0) important,
  @HiveField(1) rightNow,
  @HiveField(2) delay,
}

@HiveType(typeId: 2)
class Todo extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String title;
  @HiveField(2) String description;
  /// Absolute path to an image stored in the app support dir
  @HiveField(3) String? imagePath;
  @HiveField(4) Priority priority;
  @HiveField(5) DateTime createdAt;    // set by system on create
  @HiveField(6) DateTime? reminderAt;  // optional
  @HiveField(7) bool reminderAck;      // marked after we show it once
  @HiveField(8) DateTime? deletedAt;   // soft delete timestamp (Trash)

  Todo({
    required this.id,
    required this.title,
    required this.description,
    this.imagePath,
    required this.priority,
    required this.createdAt,
    this.reminderAt,
    this.reminderAck = false,
    this.deletedAt,
  });
}
