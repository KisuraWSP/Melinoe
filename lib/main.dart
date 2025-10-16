import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/todo.dart';
import 'data/todo_repository.dart';
import 'services/cleanup_service.dart';
import 'services/reminder_service.dart';
import 'ui/home_page.dart';

final todoRepoProvider = Provider<TodoRepository>((ref) => TodoRepository());
final cleanupProvider = Provider<CleanupService>((ref) => CleanupService(ref.read(todoRepoProvider)));
final reminderProvider = Provider<ReminderService>((ref) => ReminderService(ref.read(todoRepoProvider)));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive
    ..registerAdapter(PriorityAdapter())
    ..registerAdapter(TodoAdapter());

  final repo = TodoRepository();
  await repo.init();

  runApp(ProviderScope(
    overrides: [todoRepoProvider.overrideWithValue(repo)],
    child: const ToDoApp(),
  ));
}

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo Local',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
