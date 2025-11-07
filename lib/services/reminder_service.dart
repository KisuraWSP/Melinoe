import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart'; // Import macos_ui
import 'package:flutter/cupertino.dart'; // For icons

import '../data/todo_repository.dart';

class ReminderService {
  final TodoRepository repo;
  ReminderService(this.repo);

  Future<void> showDueRemindersOnOpen(BuildContext context) async {
    final due = repo.dueReminders(DateTime.now());
    if (due.isEmpty || !context.mounted) return;

    // Use showMacosAlertDialog
    await showMacosAlertDialog(
      context: context,
      builder: (ctx) => MacosAlertDialog(
        appIcon: const MacosIcon(CupertinoIcons.alarm_fill),
        title: const Text('Reminders'),
        message: SizedBox(
          width: 360,
          // Use a builder to get correct theme
          child: Builder(
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: due.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MacosIcon(CupertinoIcons.alarm, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${t.title}\n${t.reminderAt}',
                            style: MacosTheme.of(context).typography.body,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                );
              }
          ),
        ),
        // Use PushButton
        primaryButton: PushButton(
          // --- FIX HERE ---
          // 1. The parameter is 'controlSize', not 'buttonSize'
          // 2. The enum is 'ControlSize', not 'ButtonSize'
          controlSize: ControlSize.large,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ),
    );

    for (final t in due) {
      await repo.markReminderShown(t.id);
    }
  }
}