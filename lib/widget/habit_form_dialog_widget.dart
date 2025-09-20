import 'package:flutter/material.dart';

class HabitFormResult {
  const HabitFormResult(this.title, this.emoji);
  final String title;
  final String emoji;
}

class HabitFormDialog extends StatefulWidget {
  const HabitFormDialog({super.key, this.initialTitle, this.initialEmoji});

  final String? initialTitle;
  final String? initialEmoji;

  @override
  State<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<HabitFormDialog> {
  late final TextEditingController titleCtrl =
  TextEditingController(text: widget.initialTitle ?? '');
  late String emoji = widget.initialEmoji ?? '✅';

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialTitle != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать привычку' : 'Новая привычка'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Название'),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: emoji,
            items: const ['✅', '💧', '🏃', '🧘', '📚', '🍎', '📝', '🧠', '🛏️', '🧹']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => emoji = v ?? '✅'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
        ElevatedButton(onPressed: _submit, child: Text(isEdit ? 'Сохранить' : 'Добавить')),
      ],
    );
  }

  void _submit() {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, HabitFormResult(title, emoji));
  }
}