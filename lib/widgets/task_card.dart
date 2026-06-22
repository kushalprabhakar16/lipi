import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task item;
  final bool isDarkMode;
  final ValueChanged<String> onToggleCompletion;
  final ValueChanged<String> onDelete;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.item,
    required this.isDarkMode,
    required this.onToggleCompletion,
    required this.onDelete,
    required this.onTap,
  });

  Color _getImportanceColor(ImportanceLevel level, bool isDarkMode) {
    switch (level) {
      case ImportanceLevel.green:
        return isDarkMode ? const Color(0xFF4C8C64) : const Color(0xFFA5D6A7);
      case ImportanceLevel.yellow:
        return isDarkMode ? const Color(0xFF9E8B4C) : const Color(0xFFFFF59D);
      case ImportanceLevel.orange:
        return isDarkMode ? const Color(0xFFB57045) : const Color(0xFFFFCC80);
      case ImportanceLevel.red:
        return isDarkMode ? const Color(0xFFB54C4C) : const Color(0xFFEF9A9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final importanceColor = _getImportanceColor(item.importanceLevel, isDarkMode);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(item.id),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.3},
        onDismissed: (direction) {
  print('Dismissed ${item.id}');
  onDelete(item.id);
},
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: colorScheme.error.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: isDarkMode ? 0.12 : 0.25),
              width: 0.8,
            ),
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtle importance accent line
                Container(
                  width: 4,
                  color: item.isCompleted 
                      ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : importanceColor,
                ),
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          // Custom extremely calm checkbox circle indicator
                          GestureDetector(
                            onTap: () => onToggleCompletion(item.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: item.isCompleted
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                color: item.isCompleted
                                    ? colorScheme.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: item.isCompleted
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expanded title text showing faded out strikethrough upon completion
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                    color: item.isCompleted
                                        ? colorScheme.onSurface.withValues(alpha: 0.4)
                                        : colorScheme.onSurface,
                                    fontSize: 14.5,
                                  ),
                                ),
                                // Show time if not completed (and not purely date-based, though we always have time now)
                                // We can show something small
                                if (!item.isCompleted)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      DateFormat('MMM d, h:mm a').format(item.dueDateTime),
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Muted delete icon on hold / tap for quick data cleaning
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                            onPressed: () => onDelete(item.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
