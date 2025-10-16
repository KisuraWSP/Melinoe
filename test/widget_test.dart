import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// App imports (adjust the package name to yours)
import '../lib/ui/home_page.dart';
import '../lib/ui/edit_todo_page.dart';
import '../lib/models/todo.dart';
import '../lib/data/todo_repository.dart';
import '../lib/services/cleanup_service.dart';
import '../lib/services/reminder_service.dart';
import '../lib/main.dart';

/// --------------------
/// Fakes for testing
/// --------------------

class FakeTodoRepository extends TodoRepository {
  final Map<String, Todo> _store = {};
  @override
  Future<void> init() async {/* no-op */}

  @override
  Iterable<Todo> getAllActive() =>
      _store.values.where((t) => t.deletedAt == null).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Iterable<Todo> getAllTrashed() =>
      _store.values.where((t) => t.deletedAt != null).toList()
        ..sort((a, b) =>
            (b.deletedAt ?? DateTime(0)).compareTo(a.deletedAt ?? DateTime(0)));

  @override
  Future<Todo> create({
    required String title,
    required String description,
    String? imagePath,
    required Priority priority,
    DateTime? reminderAt,
  }) async {
    final id = 'id_${_store.length + 1}';
    final todo = Todo(
      id: id,
      title: title,
      description: description,
      imagePath: imagePath,
      priority: priority,
      createdAt: DateTime.now(),
      reminderAt: reminderAt,
      reminderAck: false,
    );
    _store[id] = todo;
    return todo;
  }

  @override
  Future<void> update(Todo todo) async {
    _store[todo.id] = todo;
  }

  @override
  Future<void> softDelete(String id) async {
    final t = _store[id];
    if (t == null) return;
    t.deletedAt = DateTime.now();
    _store[id] = t;
  }

  @override
  Future<void> restore(String id) async {
    final t = _store[id];
    if (t == null) return;
    t.deletedAt = null;
    _store[id] = t;
  }

  @override
  Future<void> purgeExpiredTrash(
      {Duration grace = const Duration(days: 30)}) async {
    // In tests, delete immediately if grace == Duration.zero
    final toDelete = _store.values
        .where((t) => t.deletedAt != null && grace == Duration.zero)
        .toList();
    for (final t in toDelete) {
      _store.remove(t.id);
    }
  }

  @override
  List<Todo> dueReminders(DateTime now) => _store.values
      .where((t) =>
  t.deletedAt == null &&
      t.reminderAt != null &&
      !t.reminderAck &&
      !t.reminderAt!.isAfter(now))
      .toList();

  @override
  Future<void> markReminderShown(String id) async {
    final t = _store[id];
    if (t == null) return;
    t.reminderAck = true;
    _store[id] = t;
  }
}

class NoopCleanupService extends CleanupService {
  NoopCleanupService(TodoRepository repo) : super(repo);
  @override
  Future<void> purgeOldTrash() async {/* no-op */}
}

class NoopReminderService extends ReminderService {
  NoopReminderService(TodoRepository repo) : super(repo);
  @override
  Future<void> showDueRemindersOnOpen(BuildContext context) async {/* no-op */}
}

ProviderScope _testScope(Widget child, FakeTodoRepository fakeRepo) {
  return ProviderScope(
    overrides: [
      todoRepoProvider.overrideWithValue(fakeRepo),
      cleanupProvider.overrideWithValue(NoopCleanupService(fakeRepo)),
      reminderProvider.overrideWithValue(NoopReminderService(fakeRepo)),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: child,
    ),
  );
}

void main() {
  testWidgets('Empty ➜ add ToDo ➜ list updates', (tester) async {
    final fakeRepo = FakeTodoRepository();

    await tester.pumpWidget(_testScope(const HomePage(), fakeRepo));
    await tester.pumpAndSettle();

    // Empty state
    expect(find.text('No ToDos yet.'), findsOneWidget);

    // Add item
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(EditTodoPage), findsOneWidget);
    expect(find.text('New ToDo'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Buy milk');
    await tester.enterText(find.byType(TextFormField).at(1), '2L full cream');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Buy milk'), findsOneWidget);
    expect(find.text('2L full cream'), findsOneWidget);
  });

  testWidgets('Move to Trash ➜ Restore', (tester) async {
    final fakeRepo = FakeTodoRepository();
    await fakeRepo.create(
      title: 'Temp task',
      description: 'to be trashed',
      priority: Priority.rightNow,
    );

    await tester.pumpWidget(_testScope(const HomePage(), fakeRepo));
    await tester.pumpAndSettle();

    // Move to Trash
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Trash'));
    await tester.pumpAndSettle();

    // Go Trash tab
    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    expect(find.text('Temp task'), findsOneWidget);

    // Restore
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    // Back to Active tab
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('Temp task'), findsOneWidget);
  });

  testWidgets('Purge Trash Now removes trashed items', (tester) async {
    final fakeRepo = FakeTodoRepository();
    final t = await fakeRepo.create(
      title: 'Trash me',
      description: 'to be purged',
      priority: Priority.delay,
    );
    await fakeRepo.softDelete(t.id);

    await tester.pumpWidget(_testScope(const HomePage(), fakeRepo));
    await tester.pumpAndSettle();

    // Trash tab
    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();
    expect(find.text('Trash me'), findsOneWidget);

    // Purge
    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Purge Trash Now'));
    await tester.pumpAndSettle();

    expect(find.text('Trash me'), findsNothing);
    expect(find.text('Trash is empty.'), findsOneWidget);
  });
}
