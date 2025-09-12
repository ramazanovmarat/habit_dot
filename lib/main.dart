import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Dot',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Habit {
  Habit(
      this.title,
      this.emoji, {
        this.doneToday = false,
        this.streak = 0,
        DateTime? lastDoneDate,
      }) : lastDoneDate = lastDoneDate;

  final String title;
  final String emoji;
  bool doneToday;

  int streak;
  DateTime? lastDoneDate;

  Habit copyWith({
    String? title,
    String? emoji,
    bool? doneToday,
    int? streak,
    DateTime? lastDoneDate,
  }) {
    return Habit(
      title ?? this.title,
      emoji ?? this.emoji,
      doneToday: doneToday ?? this.doneToday,
      streak: streak ?? this.streak,
      lastDoneDate: lastDoneDate ?? this.lastDoneDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'emoji': emoji,
    'doneToday': doneToday,
    'streak': streak,
    'lastDoneDate': lastDoneDate?.toIso8601String(),
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final s = json['lastDoneDate'] as String?;
    return Habit(
      json['title'] as String? ?? '',
      json['emoji'] as String? ?? '✅',
      doneToday: json['doneToday'] as bool? ?? false,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastDoneDate: (s != null && s.isNotEmpty) ? DateTime.tryParse(s) : null,
    );
  }

}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _prefsKey = 'habits';
  static const _lastResetKey = 'lastResetDate';
  List<Habit> habits = [];
  bool showOnlyUndone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHabits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void initialization() async {
    await Future.delayed(const Duration(seconds: 5));
    FlutterNativeSplash.remove();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeResetForNewDay();
    }
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isYesterday(DateTime date) {
    final y = _today().subtract(const Duration(days: 1));
    return _isSameDay(date, y);
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        habits = list.map(Habit.fromJson).toList();
      } catch (_) {}
    }
    setState(() {});
    await _maybeResetForNewDay();
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString(_prefsKey, data);
  }

  Future<void> _saveLastReset(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastResetKey, date.toIso8601String());
  }

  Future<void> _maybeResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final nowDate = _today();
    final stored = prefs.getString(_lastResetKey);
    final storedDate = stored != null ? DateTime.tryParse(stored) : null;
    final storedDay = storedDate == null ? null : DateTime(storedDate.year, storedDate.month, storedDate.day);

    if (storedDay == null || !_isSameDay(storedDay, nowDate)) {

      for (final h in habits) {
        h.doneToday = false;
      }
      await _saveHabits();
      await _saveLastReset(nowDate);
      if (mounted) setState(() {});
    }
  }

  void _toggleDone(int index, bool? v) {
    final h = habits[index];
    final today = _today();
    final newVal = v ?? false;

    if (newVal && !h.doneToday) {

      if (h.lastDoneDate != null && _isYesterday(h.lastDoneDate!)) {
        h.streak += 1;
      } else {
        h.streak = 1;
      }
      h.lastDoneDate = today;
      h.doneToday = true;
    } else if (!newVal && h.doneToday) {
      if (h.lastDoneDate != null && _isSameDay(h.lastDoneDate!, today) && h.streak > 0) {
        h.streak -= 1;
        if (h.streak < 0) h.streak = 0;
      }
      h.doneToday = false;
      // lastDoneDate не трогаем, чтобы не рушить историю
    }
    setState(() {});
    _saveHabits();
  }

  void _removeHabit(int index) {
    final removed = habits.removeAt(index);
    setState(() {});
    _saveHabits();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Удалено: ${removed.emoji} ${removed.title}'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () {
            setState(() => habits.insert(index, removed));
            _saveHabits();
          },
        ),
      ),
    );
  }

  Future<void> _addHabit() async {
    final res = await showDialog<_HabitFormResult>(
      context: context,
      builder: (ctx) => const _HabitFormDialog(),
    );
    if (res != null) {
      setState(() => habits.add(Habit(res.title, res.emoji)));
      _saveHabits();
    }
  }

  Future<void> _editHabit(int index) async {
    final h = habits[index];
    final res = await showDialog<_HabitFormResult>(
      context: context,
      builder: (ctx) => _HabitFormDialog(initialTitle: h.title, initialEmoji: h.emoji),
    );
    if (res != null) {
      setState(() {
        habits[index] = h.copyWith(title: res.title, emoji: res.emoji);
      });
      _saveHabits();
    }
  }

  void _resetDay() {
    final today = _today();
    for (final h in habits) {
      if (h.doneToday && h.lastDoneDate != null && _isSameDay(h.lastDoneDate!, today) && h.streak > 0) {
        h.streak -= 1;
        if (h.streak < 0) h.streak = 0;
      }
      h.doneToday = false;
    }
    setState(() {});
    _saveHabits();
  }

  void _markAllDone() {
    final today = _today();
    for (final h in habits) {
      if (!h.doneToday) {
        if (h.lastDoneDate != null && _isYesterday(h.lastDoneDate!)) {
          h.streak += 1;
        } else {
          h.streak = 1;
        }
        h.lastDoneDate = today;
        h.doneToday = true;
      }
    }
    setState(() {});
    _saveHabits();
  }

  @override
  Widget build(BuildContext context) {
    final visible = showOnlyUndone ? habits.where((h) => !h.doneToday).toList() : habits;
    final doneCount = habits.where((h) => h.doneToday).length;
    final total = habits.length;
    final progress = total == 0 ? 0.0 : doneCount / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Dot'),
        actions: [
          IconButton(
            tooltip: showOnlyUndone ? 'Показать все' : 'Только невыполненные',
            onPressed: () => setState(() => showOnlyUndone = !showOnlyUndone),
            icon: Icon(showOnlyUndone ? Icons.filter_alt_off : Icons.filter_alt),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'reset') _resetDay();
              if (v == 'check_all') _markAllDone();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'reset', child: Text('Сбросить день')),
              const PopupMenuItem(value: 'check_all', child: Text('Отметить всё')),
            ],
          ),
        ],
      ),
      body: total == 0
          ? const Center(child: Text('Добавьте первую привычку с помощью «+»'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _StatsCard(done: doneCount, total: total, progress: progress),
          ),
          Expanded(
            child: showOnlyUndone
                ? ListView.builder(
              itemCount: visible.length,
              itemBuilder: (_, i) {
                final h = visible[i];
                final idx = habits.indexOf(h);
                return _HabitTile(
                  key: ValueKey('habit-${h.title}-$idx'),
                  habit: h,
                  onToggle: (v) => _toggleDone(idx, v),
                  onTap: () => _editHabit(idx),
                  onLongPress: () => _removeHabit(idx),
                  showDragHandle: false,
                );
              },
            )
                : ReorderableListView.builder(
              itemCount: habits.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = habits.removeAt(oldIndex);
                  habits.insert(newIndex, item);
                });
                _saveHabits();
              },
              buildDefaultDragHandles: false,
              itemBuilder: (_, i) {
                final h = habits[i];
                return _HabitTile(
                  key: ValueKey('habit-${h.title}-$i'),
                  habit: h,
                  onToggle: (v) => _toggleDone(i, v),
                  onTap: () => _editHabit(i),
                  onLongPress: () => _removeHabit(i),
                  showDragHandle: true,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.done, required this.total, required this.progress});
  final int done;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final text = total == 0 ? 'Нет привычек' : 'Выполнено: $done / $total';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress),
          ),
        ]),
      ),
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onTap,
    required this.onLongPress,
    required this.showDragHandle,
  });

  final Habit habit;
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

class _HabitFormResult {
  const _HabitFormResult(this.title, this.emoji);
  final String title;
  final String emoji;
}

class _HabitFormDialog extends StatefulWidget {
  const _HabitFormDialog({this.initialTitle, this.initialEmoji});

  final String? initialTitle;
  final String? initialEmoji;

  @override
  State<_HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<_HabitFormDialog> {
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
    Navigator.pop(context, _HabitFormResult(title, emoji));
  }
}
