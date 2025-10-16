import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/todo_repository.dart';
import '../models/todo.dart';
import 'edit_todo_page.dart';
import 'widgets/priority_chip.dart';
import '../main.dart' show todoRepoProvider;

class TodoDetailPage extends ConsumerStatefulWidget {
  final String todoId;
  const TodoDetailPage({super.key, required this.todoId});

  @override
  ConsumerState<TodoDetailPage> createState() => _TodoDetailPageState();
}

class _TodoDetailPageState extends ConsumerState<TodoDetailPage> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(todoRepoProvider);

    // Build a combined list and get a nullable match (no external packages).
    final all = <Todo>[
      ...repo.getAllActive(),
      ...repo.getAllTrashed(),
    ];
    final Todo? todo = all
        .cast<Todo?>()
        .firstWhere((t) => t?.id == widget.todoId, orElse: () => null);

    if (todo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ToDo')),
        body: const Center(child: Text('Item not found')),
      );
    }

    final trashed = todo.deletedAt != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(todo.title),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit),
            onPressed: trashed
                ? null
                : () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTodoPage(existing: todo),
                ),
              );
              if (mounted) setState(() {}); // refresh details after edit
            },
          ),
          PopupMenuButton<String>(
            onSelected: (val) async {
              switch (val) {
                case 'delete':
                  await repo.softDelete(todo.id);
                  break;
                case 'restore':
                  await repo.restore(todo.id);
                  break;
                case 'purge':
                  await repo.purgeExpiredTrash(grace: Duration.zero);
                  break;
              }
              if (mounted) Navigator.pop(context); // back to list after action
            },
            itemBuilder: (ctx) => [
              if (!trashed)
                const PopupMenuItem(value: 'delete', child: Text('Move to Trash')),
              if (trashed)
                const PopupMenuItem(value: 'restore', child: Text('Restore')),
              if (trashed)
                const PopupMenuItem(value: 'purge', child: Text('Purge Trash Now')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              PriorityChip(value: todo.priority),
              const SizedBox(width: 8),
              if (todo.reminderAt != null)
                Row(
                  children: [
                    const Icon(Icons.alarm, size: 18),
                    const SizedBox(width: 4),
                    Text(todo.reminderAt.toString()),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (todo.imagePath != null && File(todo.imagePath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(todo.imagePath!),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          if (todo.imagePath != null) const SizedBox(height: 12),
          Text(
            todo.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          if (todo.description.isNotEmpty)
            Text(
              todo.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 16),
          Text('Created: ${todo.createdAt}'),
          if (trashed) Text('Deleted: ${todo.deletedAt}'),
        ],
      ),
    );
  }
}
