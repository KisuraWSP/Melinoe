import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo_repository.dart';
import '../main.dart';
import '../models/todo.dart';

class EditTodoPage extends ConsumerStatefulWidget {
  final Todo? existing;
  const EditTodoPage({super.key, this.existing});

  @override
  ConsumerState<EditTodoPage> createState() => _EditTodoPageState();
}

class _EditTodoPageState extends ConsumerState<EditTodoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  Priority _priority = Priority.rightNow;
  DateTime? _reminderAt;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _desc  = TextEditingController(text: widget.existing?.description ?? '');
    _priority = widget.existing?.priority ?? Priority.rightNow;
    _reminderAt = widget.existing?.reminderAt;
    _imagePath = widget.existing?.imagePath;
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      setState(() => _imagePath = res.files.single.path);
    }
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365*5)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(todoRepoProvider);

    if (widget.existing == null) {
      await repo.create(
        title: _title.text.trim(),
        description: _desc.text.trim(),
        imagePath: _imagePath,
        priority: _priority,
        reminderAt: _reminderAt,
      );
    } else {
      final t = widget.existing!;
      t.title = _title.text.trim();
      t.description = _desc.text.trim();
      if (_imagePath != t.imagePath && _imagePath != null) {
        final stored = await repo.importImageToAppFolder(_imagePath!);
        t.imagePath = stored ?? t.imagePath;
      }
      t.priority = _priority;
      t.reminderAt = _reminderAt;
      t.reminderAck = false; // re-arm when edited
      await repo.update(t);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final image = _imagePath != null ? Image.file(File(_imagePath!), height: 120, fit: BoxFit.cover) : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'New ToDo' : 'Edit ToDo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => (v==null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Priority>(
              value: _priority,
              items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
              onChanged: (p) => setState(() => _priority = p ?? Priority.rightNow),
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('Pick Image')),
                const SizedBox(width: 12),
                if (image != null) Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: image)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(onPressed: _pickReminder, icon: const Icon(Icons.alarm),
                    label: Text(_reminderAt == null ? 'Set Reminder' : 'Change Reminder')),
                const SizedBox(width: 12),
                if (_reminderAt != null) Text(_reminderAt.toString()),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
