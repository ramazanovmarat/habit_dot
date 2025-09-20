import 'package:flutter/material.dart';
import 'package:habit_dot/habit_model.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
    required this.showDragHandle,
  });

  final HabitModel habit;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final subtitle = habit.streak > 0 ? 'Стрик: ${habit.streak}' : null;

    final tile = ListTile(
      leading: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
      title: Text(habit.title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(value: habit.doneToday, onChanged: onToggle),
          if (showDragHandle)
            const ReorderableDragStartListener(
              index: 0,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.drag_handle),
              ),
            ),
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );

    if (!showDragHandle) return tile;

    return Row(
      key: key,
      children: [
        Expanded(child: tile),
      ],
    );
  }
}