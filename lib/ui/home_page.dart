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

  // --- STATE FOR SEARCH & FILTER ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Priority? _selectedPriority;
  // --- END STATE ---

  @override
  void initState() {
    super.initState();
    // Service calls
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(cleanupProvider).purgeOldTrash();
      await ref.read(reminderProvider).showDueRemindersOnOpen(context);
      if (mounted) setState(() {});
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
                    // Listener will update _searchQuery
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
              // Highlight icon if filter is active
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
              // "All" option
              const PopupMenuItem(
                value: null,
                child: Text('All Priorities'),
              ),
              const PopupMenuDivider(),
              // One item for each priority
              ...Priority.values.map((p) => PopupMenuItem(
                value: p,
                child: Text(PriorityChip.getLabel(p)), // Use helper
              )),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(todoRepoProvider);

    // --- UPDATED DATA FETCHING ---
    // Use the new repository method with current filters
    final items = repo.getFilteredTodos(
      active: _tab == 0,
      query: _searchQuery,
      priority: _selectedPriority,
    ).toList();
    // --- END UPDATE ---

    return Scaffold(
      appBar: AppBar(title: const Text('Melinoe')),
      // --- BODY IS NOW A COLUMN ---
      body: Column(
        children: [
          // 1. The new filter bar
          _buildFilterBar(),

          // 2. The list, inside an Expanded
          Expanded(
            child: items.isEmpty
                ? Center(
              // Show a more helpful empty message
              child: Text(_searchQuery.isNotEmpty || _selectedPriority != null
                  ? 'No results found.'
                  : (_tab == 0 ? 'No ToDos yet.' : 'Trash is empty.')),
            )
                : ListView.builder(
              itemCount: items.length,
              // Note: _TodoTile is unchanged, so we just pass data
              itemBuilder: (ctx, i) => _TodoTile(item: items[i], trashed: _tab == 1),
            ),
          ),
        ],
      ),
      // --- END BODY UPDATE ---

      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          // --- RESET FILTERS ON TAB CHANGE ---
          _tab = i;
          _searchController.clear();
          _selectedPriority = null;
          // The listener will set _searchQuery
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
        ).then((_) => setState(() {})), // Refresh list on return
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}

// --- _TodoTile is unchanged, no edits needed here ---
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