import 'package:flutter/material.dart';
import '../../models/todo.dart';

class PriorityChip extends StatelessWidget {
  final Priority value;
  const PriorityChip({super.key, required this.value});

  Color _color() {
    switch (value) {
      case Priority.important: return Colors.red;
      case Priority.rightNow: return Colors.orange;
      case Priority.delay: return Colors.blueGrey;
    }
  }

  String _label() {
    switch (value) {
      case Priority.important: return 'Important';
      case Priority.rightNow: return 'Right Now';
      case Priority.delay: return 'Delay';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color();
    return Chip(
      label: Text(_label()),
      backgroundColor: c.withOpacity(0.15),
      side: BorderSide(color: c),
      labelStyle: TextStyle(color: c.withOpacity(0.9)),
    );
  }
}
