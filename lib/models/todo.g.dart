// GENERATED QUICK ADAPTER (you can replace by build_runner)
part of 'todo.dart';

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 1;

  @override
  Priority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0: return Priority.important;
      case 1: return Priority.rightNow;
      case 2: return Priority.delay;
      default: return Priority.rightNow;
    }
  }

  @override
  void write(BinaryWriter writer, Priority obj) {
    switch (obj) {
      case Priority.important: writer.writeByte(0); break;
      case Priority.rightNow: writer.writeByte(1); break;
      case Priority.delay: writer.writeByte(2); break;
    }
  }
}

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 2;

  @override
  Todo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return Todo(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      imagePath: fields[3] as String?,
      priority: fields[4] as Priority,
      createdAt: fields[5] as DateTime,
      reminderAt: fields[6] as DateTime?,
      reminderAck: fields[7] as bool,
      deletedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.imagePath)
      ..writeByte(4)..write(obj.priority)
      ..writeByte(5)..write(obj.createdAt)
      ..writeByte(6)..write(obj.reminderAt)
      ..writeByte(7)..write(obj.reminderAck)
      ..writeByte(8)..write(obj.deletedAt);
  }
}
