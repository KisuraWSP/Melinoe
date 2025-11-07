import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../models/todo.dart';

/// A widget that displays a [Priority] as a native-looking macOS tag.
class MacosPriorityChip extends StatelessWidget {
  final Priority priority;

  const MacosPriorityChip({
    super.key,
    required this.priority,
  });

  /// Gets a display-friendly label for a [Priority].
  /// Copied from original PriorityChip.
  static String getLabel(Priority p) {
    switch (p) {
      case Priority.important:
        return 'Important';
      case Priority.rightNow:
        return 'Right Now';
      case Priority.delay:
        return 'Delay';
    }
  }

  /// Gets a color for the chip based on priority.
  static Color getColor(Priority p) {
    switch (p) {
      case Priority.important:
      // --- FIX ---
        return MacosColors.appleRed; // Was .red
      case Priority.rightNow:
      // --- FIX ---
        return MacosColors.appleOrange; // Was .orange
      case Priority.delay:
      // --- FIX ---
        return MacosColors.systemGrayColor; // Was .systemGray
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor(priority);
    final label = getLabel(priority);

    // Build a simple rounded container with text, similar to a tag
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        label,
        style: MacosTheme.of(context).typography.caption1.copyWith(color: color),
      ),
    );
  }
}