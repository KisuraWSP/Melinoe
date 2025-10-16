import 'package:flutter/material.dart';
import '../data/todo_repository.dart';

class ReminderService {
  final TodoRepository repo;
  ReminderService(this.repo);

  Future<void> showDueRemindersOnOpen(BuildContext context) async {
    final due = repo.dueReminders(DateTime.now());
    if (due.isEmpty) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reminders'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: due.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.alarm, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${t.title}\n${t.reminderAt}')),
                ],
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );

    for (final t in due) {
      await repo.markReminderShown(t.id);
    }
  }
}
