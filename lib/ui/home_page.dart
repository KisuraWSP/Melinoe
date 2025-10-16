import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/todo_repository.dart';
import '../models/todo.dart';
import '../services/cleanup_service.dart';
import '../services/reminder_service.dart';
import 'edit_todo_page.dart';
import 'todo_detail_page.dart';
import 'widgets/priority_chip.dart';
import '../main.dart' show todoRepoProvider, cleanupProvider, reminderProvider;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(cleanupProvider).purgeOldTrash();
      await ref.read(reminderProvider).showDueRemindersOnOpen(context);
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(todoRepoProvider);
    final items =
    _tab == 0 ? repo.getAllActive().toList() : repo.getAllTrashed().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Melinoe')),
      body: items.isEmpty
          ? Center(
        child: Text(_tab == 0 ? 'No ToDos yet.' : 'Trash is empty.'),
      )
          : ListView.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) => _TodoTile(item: items[i], trashed: _tab == 1),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Active'),
          NavigationDestination(icon: Icon(Icons.delete), label: 'Trash'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditTodoPage()),
        ).then((_) => setState(() {})),
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

class _TodoTile extends ConsumerWidget {
  final Todo item;
  final bool trashed;
  const _TodoTile({required this.item, required this.trashed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(todoRepoProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        // Minimal: title + priority only
        leading: const CircleAvatar(child: Icon(Icons.check)),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(children: [PriorityChip(value: item.priority)]),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TodoDetailPage(todoId: item.id)),
          );
          // After returning from details (possibly after edit), refresh list.
          // ignore: use_build_context_synchronously
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        trailing: PopupMenuButton<String>(
          onSelected: (val) async {
            switch (val) {
              case 'edit':
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditTodoPage(existing: item)),
                );
                break;
              case 'delete':
                await repo.softDelete(item.id);
                break;
              case 'restore':
                await repo.restore(item.id);
                break;
              case 'purge':
                await repo.purgeExpiredTrash(grace: Duration.zero);
                break;
            }
            // Return to list and refresh
            // ignore: use_build_context_synchronously
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          itemBuilder: (ctx) => [
            if (!trashed)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (!trashed)
              const PopupMenuItem(value: 'delete', child: Text('Move to Trash')),
            if (trashed)
              const PopupMenuItem(value: 'restore', child: Text('Restore')),
            if (trashed)
              const PopupMenuItem(value: 'purge', child: Text('Purge Trash Now')),
          ],
        ),
      ),
    );
  }
}
