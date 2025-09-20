class HabitModel {
  HabitModel(
      this.title,
      this.emoji, {
        this.doneToday = false,
        this.streak = 0,
        this.lastDoneDate,
      });

  final String title;
  final String emoji;
  bool doneToday;

  int streak;
  DateTime? lastDoneDate;

  HabitModel copyWith({
    String? title,
    String? emoji,
    bool? doneToday,
    int? streak,
    DateTime? lastDoneDate,
  }) {
    return HabitModel(
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

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    final s = json['lastDoneDate'] as String?;
    return HabitModel(
      json['title'] as String? ?? '',
      json['emoji'] as String? ?? '✅',
      doneToday: json['doneToday'] as bool? ?? false,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastDoneDate: (s != null && s.isNotEmpty) ? DateTime.tryParse(s) : null,
    );
  }
}