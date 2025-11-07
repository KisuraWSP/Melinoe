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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Priority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    // Service calls
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(cleanupProvider).purgeOldTrash();
      // Added mounted check for safety
      if (mounted) {
        await ref.read(reminderProvider).showDueRemindersOnOpen(context);
        setState(() {});
      }
    });

    // Listener for search text
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Builds the search and filter bar UI.
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search, size: 20),
                // Clear button
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Priority Filter Button
          PopupMenuButton<Priority?>(
            icon: Icon(
              Icons.filter_list,
              color: _selectedPriority == null
                  ? Theme.of(context).iconTheme.color
                  : Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Filter by Priority',
            onSelected: (Priority? priority) {
              setState(() {
                _selectedPriority = priority;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Priorities'),
              ),
              const PopupMenuDivider(),
              ...Priority.values.map((p) => PopupMenuItem(
                value: p,
                child: Text(PriorityChip.getLabel(p)),
              )),
            ],
          ),
        ],
      ),
    );
  }

  // --- NEW DIALOG METHOD ---
  /// Shows a confirmation dialog before emptying the trash.
  Future<void> _confirmEmptyTrash(BuildContext context, TodoRepository repo) async {
    // Don't show dialog if context is invalid
    if (!context.mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text('This will permanently delete all items in the trash. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Dismiss, return false
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true), // Confirm, return true
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    // Only proceed if the user confirmed and widget is still mounted
    if (confirmed == true && mounted) {
      await repo.purgeAllTrash();
      setState(() {}); // Refresh the list
    }
  }
  // --- END NEW DIALOG METHOD ---

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(todoRepoProvider);

    final items = repo.getFilteredTodos(
      active: _tab == 0,
      query: _searchQuery,
      priority: _selectedPriority,
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Melinoe'),
        // --- ADD APP BAR ACTIONS ---
        actions: [
          // Only show if on Trash tab AND trash is not empty
          if (_tab == 1 && items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined), //
              tooltip: 'Empty Trash',
              onPressed: () => _confirmEmptyTrash(context, repo),
            ),
        ],
        // --- END APP BAR ACTIONS ---
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: items.isEmpty
                ? Center(
              child: Text(_searchQuery.isNotEmpty || _selectedPriority != null
                  ? 'No results found.'
                  : (_tab == 0 ? 'No ToDos yet.' : 'Trash is empty.')),
            )
                : ListView.builder(
              itemCount: items.length,
              itemBuilder: (ctx, i) => _TodoTile(item: items[i], trashed: _tab == 1),
            ),
          ),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _searchController.clear();
          _selectedPriority = null;
        }),
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

// --- _TodoTile (unchanged from your file, but included for completeness) ---
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
            bool shouldRefresh = true;
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
            // I've removed the ambiguous 'purge' from the individual item
            // to avoid confusion with the new "Empty Trash" button.
            }
            if (shouldRefresh) {
              // This will force the widget to rebuild and get fresh data
              // A simple setState in the homepage would also work, but
              // since this is a ConsumerWidget, we can just re-read.
              (context as Element).reassemble(); // A bit of a hack, let's refresh
              ref.refresh(todoRepoProvider);
            }
          },
          itemBuilder: (ctx) => [
            if (!trashed)
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (!trashed)
              const PopupMenuItem(value: 'delete', child: Text('Move to Trash')),
            if (trashed)
              const PopupMenuItem(value: 'restore', child: Text('Restore')),
          ],
        ),
      ),
    );
  }
}