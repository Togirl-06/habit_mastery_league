import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const HabitTrackerApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

enum HabitFrequency { daily, weekdays, weekends, custom }

enum HabitCategory { study, health, fitness, sleep, finance, productivity, other }

class Habit {
  final String id;
  String name;
  String description;
  HabitCategory category;
  HabitFrequency frequency;
  List<int> customDays; // 0=Mon..6=Sun
  int targetPerWeek;
  String iconEmoji;
  Color color;
  DateTime createdAt;
  bool isArchived;

  Habit({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    this.frequency = HabitFrequency.daily,
    this.customDays = const [],
    this.targetPerWeek = 7,
    required this.iconEmoji,
    required this.color,
    required this.createdAt,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.index,
        'frequency': frequency.index,
        'customDays': jsonEncode(customDays),
        'targetPerWeek': targetPerWeek,
        'iconEmoji': iconEmoji,
        'colorValue': color.value,
        'createdAt': createdAt.toIso8601String(),
        'isArchived': isArchived ? 1 : 0,
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'],
        name: map['name'],
        description: map['description'] ?? '',
        category: HabitCategory.values[map['category'] ?? 0],
        frequency: HabitFrequency.values[map['frequency'] ?? 0],
        customDays: List<int>.from(jsonDecode(map['customDays'] ?? '[]')),
        targetPerWeek: map['targetPerWeek'] ?? 7,
        iconEmoji: map['iconEmoji'] ?? '✅',
        color: Color(map['colorValue'] ?? 0xFF6366F1),
        createdAt: DateTime.parse(map['createdAt']),
        isArchived: (map['isArchived'] ?? 0) == 1,
      );

  Habit copyWith({
    String? name,
    String? description,
    HabitCategory? category,
    HabitFrequency? frequency,
    List<int>? customDays,
    int? targetPerWeek,
    String? iconEmoji,
    Color? color,
    bool? isArchived,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        frequency: frequency ?? this.frequency,
        customDays: customDays ?? this.customDays,
        targetPerWeek: targetPerWeek ?? this.targetPerWeek,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        color: color ?? this.color,
        createdAt: createdAt,
        isArchived: isArchived ?? this.isArchived,
      );
}

class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final bool completed;
  final String? note;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.completed,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'date': date.toIso8601String(),
        'completed': completed ? 1 : 0,
        'note': note ?? '',
      };

  factory HabitLog.fromMap(Map<String, dynamic> map) => HabitLog(
        id: map['id'],
        habitId: map['habitId'],
        date: DateTime.parse(map['date']),
        completed: (map['completed'] ?? 0) == 1,
        note: map['note'],
      );
}

class Badge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });

  Badge copyWith({bool? unlocked, DateTime? unlockedAt}) => Badge(
        id: id,
        name: name,
        emoji: emoji,
        description: description,
        unlocked: unlocked ?? this.unlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

class Mission {
  final String id;
  final String title;
  final String description;
  final int targetCount;
  int currentCount;
  final bool completed;
  final DateTime expiresAt;
  final String rewardEmoji;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentCount = 0,
    this.completed = false,
    required this.expiresAt,
    required this.rewardEmoji,
  });

  double get progress => (currentCount / targetCount).clamp(0.0, 1.0);
}

class CoachTip {
  final String habitId;
  final String habitName;
  final String message;
  final String type; // 'warning', 'praise', 'suggestion'
  final String emoji;

  const CoachTip({
    required this.habitId,
    required this.habitName,
    required this.message,
    required this.type,
    required this.emoji,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// IN-MEMORY DATABASE (simulates sqflite + SharedPreferences)
// ─────────────────────────────────────────────────────────────────────────────

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  // In-memory storage (replace with sqflite in production)
  final List<Habit> _habits = [];
  final List<HabitLog> _logs = [];

  // SharedPreferences simulation
  bool _isDarkMode = false;
  bool _showMotivationTips = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  bool get isDarkMode => _isDarkMode;
  bool get showMotivationTips => _showMotivationTips;
  TimeOfDay get reminderTime => _reminderTime;

  void setDarkMode(bool val) => _isDarkMode = val;
  void setShowMotivationTips(bool val) => _showMotivationTips = val;
  void setReminderTime(TimeOfDay t) => _reminderTime = t;

  // ── Habits ──────────────────────────────────────────────────────────────────
  List<Habit> getHabits({bool includeArchived = false}) =>
      _habits.where((h) => includeArchived || !h.isArchived).toList();

  Habit? getHabitById(String id) =>
      _habits.where((h) => h.id == id).firstOrNull;

  void insertHabit(Habit habit) => _habits.add(habit);

  void updateHabit(Habit habit) {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) _habits[idx] = habit;
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    _logs.removeWhere((l) => l.habitId == id);
  }

  // ── Logs ────────────────────────────────────────────────────────────────────
  List<HabitLog> getLogsForHabit(String habitId) =>
      _logs.where((l) => l.habitId == habitId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  HabitLog? getLogForDate(String habitId, DateTime date) {
    final d = _normalizeDate(date);
    return _logs
        .where((l) => l.habitId == habitId && _normalizeDate(l.date) == d)
        .firstOrNull;
  }

  void upsertLog(HabitLog log) {
    final existing = getLogForDate(log.habitId, log.date);
    if (existing != null) {
      _logs.removeWhere((l) => l.id == existing.id);
    }
    _logs.add(log);
  }

  // ── Stats ────────────────────────────────────────────────────────────────────
  int getStreak(String habitId) {
    final logs = getLogsForHabit(habitId)
        .where((l) => l.completed)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty) return 0;
    int streak = 0;
    DateTime check = _normalizeDate(DateTime.now());
    for (final log in logs) {
      if (_normalizeDate(log.date) == check) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int getLongestStreak(String habitId) {
    final logs = getLogsForHabit(habitId)
        .where((l) => l.completed)
        .map((l) => _normalizeDate(l.date))
        .toSet()
        .toList()
      ..sort();
    if (logs.isEmpty) return 0;
    int longest = 1, current = 1;
    for (int i = 1; i < logs.length; i++) {
      if (logs[i].difference(logs[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  double getCompletionRate(String habitId, {int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final logs = _logs
        .where((l) => l.habitId == habitId && l.date.isAfter(cutoff))
        .toList();
    if (logs.isEmpty) return 0;
    final completed = logs.where((l) => l.completed).length;
    return completed / logs.length;
  }

  List<HabitLog> getLogsLast7Days(String habitId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _logs
        .where((l) =>
            l.habitId == habitId &&
            l.date.isAfter(cutoff) &&
            l.completed)
        .toList();
  }

  int getTotalCompletedToday() {
    final today = _normalizeDate(DateTime.now());
    return _logs
        .where((l) => _normalizeDate(l.date) == today && l.completed)
        .length;
  }

  int getTotalHabitsToday() => _habits.where((h) => !h.isArchived).length;

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  // ── Seed Data ────────────────────────────────────────────────────────────────
  void seedSampleData() {
    if (_habits.isNotEmpty) return;
    final now = DateTime.now();

    final sampleHabits = [
      Habit(
        id: '1',
        name: 'Morning Study Session',
        description: '2 hours of focused study each morning',
        category: HabitCategory.study,
        iconEmoji: '📚',
        color: const Color(0xFF6366F1),
        createdAt: now.subtract(const Duration(days: 30)),
        frequency: HabitFrequency.weekdays,
      ),
      Habit(
        id: '2',
        name: 'Evening Run',
        description: '5km run around campus',
        category: HabitCategory.fitness,
        iconEmoji: '🏃',
        color: const Color(0xFF10B981),
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Habit(
        id: '3',
        name: 'Sleep by 11 PM',
        description: 'Lights out before midnight',
        category: HabitCategory.sleep,
        iconEmoji: '😴',
        color: const Color(0xFF8B5CF6),
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Habit(
        id: '4',
        name: 'Track Expenses',
        description: 'Log all spending in budgeting app',
        category: HabitCategory.finance,
        iconEmoji: '💰',
        color: const Color(0xFFF59E0B),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Habit(
        id: '5',
        name: 'Drink 8 Glasses of Water',
        description: 'Stay hydrated throughout the day',
        category: HabitCategory.health,
        iconEmoji: '💧',
        color: const Color(0xFF06B6D4),
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    ];

    for (final h in sampleHabits) {
      insertHabit(h);
    }

    // Seed some logs
    final rand = Random(42);
    for (final h in sampleHabits) {
      for (int d = 30; d >= 0; d--) {
        final date = now.subtract(Duration(days: d));
        final completed = rand.nextDouble() > 0.3;
        upsertLog(HabitLog(
          id: '${h.id}_$d',
          habitId: h.id,
          date: date,
          completed: completed,
        ));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RULE-BASED COACH
// ─────────────────────────────────────────────────────────────────────────────

class HabitCoach {
  static List<CoachTip> generateTips(AppDatabase db) {
    final tips = <CoachTip>[];
    for (final habit in db.getHabits()) {
      final last7 = db.getLogsLast7Days(habit.id);
      final streak = db.getStreak(habit.id);
      final allLogs = db.getLogsForHabit(habit.id);
      final missedLast7 = 7 - last7.length;

      // Rule 1: Missed 3+ times in 7 days → lower goal
      if (missedLast7 >= 3) {
        tips.add(CoachTip(
          habitId: habit.id,
          habitName: habit.name,
          message:
              "You've missed \"${habit.name}\" $missedLast7 times this week. Consider reducing to ${habit.targetPerWeek - 1}×/week or shifting the schedule.",
          type: 'warning',
          emoji: '⚠️',
        ));
      }

      // Rule 2: Streak ≥ 10 → advanced mission
      if (streak >= 10) {
        tips.add(CoachTip(
          habitId: habit.id,
          habitName: habit.name,
          message:
              "🔥 ${streak}-day streak on \"${habit.name}\"! Time to level up — set a higher target or add a challenge.",
          type: 'praise',
          emoji: '🏆',
        ));
      }

      // Rule 3: Mostly weekdays → suggest weekday-only
      if (allLogs.length >= 14 && habit.frequency == HabitFrequency.daily) {
        final weekdayLogs = allLogs
            .where((l) =>
                l.completed && l.date.weekday >= 1 && l.date.weekday <= 5)
            .length;
        final weekendLogs = allLogs
            .where((l) =>
                l.completed && l.date.weekday >= 6)
            .length;
        if (weekdayLogs > weekendLogs * 3) {
          tips.add(CoachTip(
            habitId: habit.id,
            habitName: habit.name,
            message:
                "You mostly complete \"${habit.name}\" on weekdays. Set it to Weekdays-only to reduce missed counts.",
            type: 'suggestion',
            emoji: '💡',
          ));
        }
      }
    }
    return tips;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGES & MISSIONS
// ─────────────────────────────────────────────────────────────────────────────

class BadgesService {
  static List<Badge> getAllBadges(AppDatabase db) {
    final habits = db.getHabits();
    final totalHabits = habits.length;
    final maxStreak =
        habits.fold(0, (m, h) => max(m, db.getStreak(h.id)));
    final longestEver =
        habits.fold(0, (m, h) => max(m, db.getLongestStreak(h.id)));
    final todayDone = db.getTotalCompletedToday();

    return [
      Badge(
        id: 'first_habit',
        name: 'First Step',
        emoji: '🌱',
        description: 'Create your first habit',
        unlocked: totalHabits >= 1,
        unlockedAt: totalHabits >= 1 ? DateTime.now() : null,
      ),
      Badge(
        id: 'five_habits',
        name: 'Juggler',
        emoji: '🎪',
        description: 'Track 5 habits simultaneously',
        unlocked: totalHabits >= 5,
      ),
      Badge(
        id: 'streak_3',
        name: 'Consistent',
        emoji: '🔥',
        description: '3-day streak on any habit',
        unlocked: maxStreak >= 3,
      ),
      Badge(
        id: 'streak_7',
        name: 'Week Warrior',
        emoji: '⚔️',
        description: '7-day streak on any habit',
        unlocked: maxStreak >= 7,
      ),
      Badge(
        id: 'streak_30',
        name: 'Iron Will',
        emoji: '💪',
        description: '30-day streak on any habit',
        unlocked: longestEver >= 30,
      ),
      Badge(
        id: 'perfect_day',
        name: 'Perfect Day',
        emoji: '⭐',
        description: 'Complete all habits in a day',
        unlocked: todayDone >= db.getTotalHabitsToday() &&
            db.getTotalHabitsToday() > 0,
      ),
      Badge(
        id: 'early_bird',
        name: 'Early Bird',
        emoji: '🌅',
        description: 'Check in before 8 AM',
        unlocked: false,
      ),
      Badge(
        id: 'scholar',
        name: 'Scholar',
        emoji: '🎓',
        description: 'Complete a study habit 20 times',
        unlocked: habits
            .where((h) => h.category == HabitCategory.study)
            .any((h) => db.getLogsForHabit(h.id)
                .where((l) => l.completed)
                .length >= 20),
      ),
    ];
  }

  static List<Mission> getWeeklyMissions(AppDatabase db) {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    return [
      Mission(
        id: 'm1',
        title: 'Consistency King',
        description: 'Complete any habit 5 days in a row',
        targetCount: 5,
        currentCount: db.getHabits().fold(
            0, (m, h) => max(m, min(db.getStreak(h.id), 5))),
        expiresAt: endOfWeek,
        rewardEmoji: '👑',
      ),
      Mission(
        id: 'm2',
        title: 'All-Rounder',
        description: 'Complete 3 different habits today',
        targetCount: 3,
        currentCount: min(db.getTotalCompletedToday(), 3),
        expiresAt: DateTime(now.year, now.month, now.day, 23, 59),
        rewardEmoji: '🌟',
      ),
      Mission(
        id: 'm3',
        title: 'Weekly Champion',
        description: 'Check in 20 times this week',
        targetCount: 20,
        currentCount: min(
          db.getHabits().fold(0,
              (sum, h) => sum + db.getLogsLast7Days(h.id).length),
          20,
        ),
        expiresAt: endOfWeek,
        rewardEmoji: '🏆',
      ),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP STATE / CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  AppState() {
    _db.seedSampleData();
  }

  AppDatabase get db => _db;

  bool get isDarkMode => _db.isDarkMode;
  bool get showTips => _db.showMotivationTips;
  TimeOfDay get reminderTime => _db.reminderTime;

  void toggleTheme() {
    _db.setDarkMode(!_db.isDarkMode);
    notifyListeners();
  }

  void toggleTips() {
    _db.setShowMotivationTips(!_db.showMotivationTips);
    notifyListeners();
  }

  void setReminderTime(TimeOfDay t) {
    _db.setReminderTime(t);
    notifyListeners();
  }

  List<Habit> getHabits({bool includeArchived = false}) =>
      _db.getHabits(includeArchived: includeArchived);

  void addHabit(Habit h) {
    _db.insertHabit(h);
    notifyListeners();
  }

  void updateHabit(Habit h) {
    _db.updateHabit(h);
    notifyListeners();
  }

  void deleteHabit(String id) {
    _db.deleteHabit(id);
    notifyListeners();
  }

  void toggleHabitToday(String habitId) {
    final existing = _db.getLogForDate(habitId, DateTime.now());
    final newLog = HabitLog(
      id: '${habitId}_${DateTime.now().millisecondsSinceEpoch}',
      habitId: habitId,
      date: DateTime.now(),
      completed: existing == null || !existing.completed,
    );
    _db.upsertLog(newLog);
    notifyListeners();
  }

  bool isCompletedToday(String habitId) {
    final log = _db.getLogForDate(habitId, DateTime.now());
    return log?.completed ?? false;
  }

  int getStreak(String habitId) => _db.getStreak(habitId);
  int getLongestStreak(String habitId) => _db.getLongestStreak(habitId);
  double getCompletionRate(String habitId, {int days = 30}) =>
      _db.getCompletionRate(habitId, days: days);

  List<HabitLog> getLogsForHabit(String habitId) =>
      _db.getLogsForHabit(habitId);

  List<CoachTip> get coachTips => HabitCoach.generateTips(_db);
  List<Badge> get badges => BadgesService.getAllBadges(_db);
  List<Mission> get missions => BadgesService.getWeeklyMissions(_db);

  int get totalCompletedToday => _db.getTotalCompletedToday();
  int get totalHabitsToday => _db.getTotalHabitsToday();
}

// ─────────────────────────────────────────────────────────────────────────────
// APP ROOT
// ─────────────────────────────────────────────────────────────────────────────

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'HabitFlow',
          debugShowCheckedModeBanner: false,
          themeMode:
              _appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: MainShell(appState: _appState),
        );
      },
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8F7FF),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7FF),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF1F1F3A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1F1F3A),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      );

  ThemeData _buildDarkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F1A),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SHELL – Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final AppState appState;
  const MainShell({super.key, required this.appState});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(appState: widget.appState),
      HabitListScreen(appState: widget.appState),
      ProgressMissionsScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        indicatorColor: cs.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 1: HOME / TODAY SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppState get state => widget.appState;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final habits = state.getHabits();
    final done = state.totalCompletedToday;
    final total = state.totalHabitsToday;
    final pct = total == 0 ? 0.0 : done / total;
    final tips = state.coachTips;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final habits2 = state.getHabits();
        final done2 = state.totalCompletedToday;
        final total2 = state.totalHabitsToday;
        final pct2 = total2 == 0 ? 0.0 : done2 / total2;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Text('HabitFlow'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                tooltip: 'Add Habit',
                onPressed: () => _openAddHabit(context),
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // ── Progress Banner ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildProgressBanner(context, done2, total2, pct2, cs),
              ),

              // ── Coach Tips ──────────────────────────────────────────────
              if (state.showTips && tips.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      'Coach Insights',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 92,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tips.length,
                      itemBuilder: (ctx, i) =>
                          _CoachTipCard(tip: tips[i], appState: state),
                    ),
                  ),
                ),
              ],

              // ── Today's Habits ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Habits",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '$done2 / $total2 done',
                        style: TextStyle(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              habits2.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(context))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _HabitCheckInCard(
                          habit: habits2[i],
                          appState: state,
                          onTap: () => _openDetail(context, habits2[i]),
                        ),
                        childCount: habits2.length,
                      ),
                    ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBanner(BuildContext context, int done, int total,
      double pct, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formattedDate(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(pct * 100).toInt()}% complete',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            total == 0
                ? "No habits yet — let's add some! 🚀"
                : done == total
                    ? "All done! Amazing work today! 🎉"
                    : "$done of $total habits completed",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            const Text('📝', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Add your first habit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start building routines that stick.\nSmall steps, big results.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openAddHabit(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Habit'),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }

  String _formattedDate() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final d = DateTime.now();
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  void _openAddHabit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditHabitScreen(appState: state),
      ),
    );
  }

  void _openDetail(BuildContext context, Habit h) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(appState: state, habitId: h.id),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: Habit Check-In Card (used on Home)
// ─────────────────────────────────────────────────────────────────────────────

class _HabitCheckInCard extends StatelessWidget {
  final Habit habit;
  final AppState appState;
  final VoidCallback onTap;

  const _HabitCheckInCard({
    required this.habit,
    required this.appState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = appState.isCompletedToday(habit.id);
    final streak = appState.getStreak(habit.id);
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final done2 = appState.isCompletedToday(habit.id);
        final streak2 = appState.getStreak(habit.id);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: habit.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        habit.iconEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + streak
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('🔥',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 2),
                              Text(
                                '$streak2 day streak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Check button
                    GestureDetector(
                      onTap: () {
                        appState.toggleHabitToday(habit.id);
                        if (!done2) {
                          HapticFeedback.mediumImpact();
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(SnackBar(
                              content: Text(
                                  '${habit.iconEmoji} ${habit.name} — done!'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ));
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: done2 ? habit.color : Colors.transparent,
                          border: Border.all(
                            color: done2
                                ? habit.color
                                : cs.outline.withOpacity(0.4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: done2
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: Coach Tip Card
// ─────────────────────────────────────────────────────────────────────────────

class _CoachTipCard extends StatelessWidget {
  final CoachTip tip;
  final AppState appState;
  const _CoachTipCard({required this.tip, required this.appState});

  @override
  Widget build(BuildContext context) {
    final color = tip.type == 'warning'
        ? Colors.orange
        : tip.type == 'praise'
            ? Colors.green
            : Theme.of(context).colorScheme.primary;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip.message,
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 2: HABIT LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class HabitListScreen extends StatefulWidget {
  final AppState appState;
  const HabitListScreen({super.key, required this.appState});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  HabitCategory? _filterCategory;
  String _searchQuery = '';
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        var habits = widget.appState.getHabits(includeArchived: _showArchived);

        if (_filterCategory != null) {
          habits =
              habits.where((h) => h.category == _filterCategory).toList();
        }
        if (_searchQuery.isNotEmpty) {
          habits = habits
              .where((h) => h.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
              .toList();
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('All Habits'),
            actions: [
              IconButton(
                icon: Icon(
                  _showArchived
                      ? Icons.archive_rounded
                      : Icons.archive_outlined,
                ),
                tooltip: _showArchived ? 'Hide archived' : 'Show archived',
                onPressed: () =>
                    setState(() => _showArchived = !_showArchived),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddEditHabitScreen(appState: widget.appState),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchBar(
                  hintText: 'Search habits…',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _searchQuery = v),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              // Category filter chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _filterCategory == null,
                        onSelected: (_) =>
                            setState(() => _filterCategory = null),
                      ),
                    ),
                    ...HabitCategory.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                                '${_categoryEmoji(cat)} ${_categoryLabel(cat)}'),
                            selected: _filterCategory == cat,
                            onSelected: (_) =>
                                setState(() => _filterCategory = cat),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Habit list
              Expanded(
                child: habits.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: habits.length,
                        itemBuilder: (ctx, i) => _HabitListTile(
                          habit: habits[i],
                          appState: widget.appState,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HabitDetailScreen(
                                appState: widget.appState,
                                habitId: habits[i].id,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No habits match "$_searchQuery"'
                  : 'No habits yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
}

class _HabitListTile extends StatelessWidget {
  final Habit habit;
  final AppState appState;
  final VoidCallback onTap;

  const _HabitListTile({
    required this.habit,
    required this.appState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final streak = appState.getStreak(habit.id);
    final rate = appState.getCompletionRate(habit.id);
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: habit.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text(habit.iconEmoji,
              style: const TextStyle(fontSize: 24)),
        ),
        title: Text(
          habit.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _StatChip(
                  label: '$streak 🔥', color: Colors.orange),
              const SizedBox(width: 6),
              _StatChip(
                label: '${(rate * 100).toInt()}% done',
                color: habit.color,
              ),
              const SizedBox(width: 6),
              _StatChip(
                label: _categoryLabel(habit.category),
                color: cs.secondary,
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: cs.onSurface.withOpacity(0.4)),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 3: HABIT DETAIL & HISTORY
// ─────────────────────────────────────────────────────────────────────────────

class HabitDetailScreen extends StatelessWidget {
  final AppState appState;
  final String habitId;

  const HabitDetailScreen(
      {super.key, required this.appState, required this.habitId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final habit = appState.db.getHabitById(habitId);
        if (habit == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Habit')),
            body: const Center(child: Text('Habit not found')),
          );
        }

        final streak = appState.getStreak(habitId);
        final longest = appState.getLongestStreak(habitId);
        final rate30 = appState.getCompletionRate(habitId, days: 30);
        final rate7 = appState.getCompletionRate(habitId, days: 7);
        final logs = appState.getLogsForHabit(habitId);
        final cs = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddEditHabitScreen(
                      appState: appState,
                      habit: habit,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'archive') {
                    appState.updateHabit(
                        habit.copyWith(isArchived: !habit.isArchived));
                    Navigator.of(context).pop();
                  } else if (v == 'delete') {
                    _confirmDelete(context, habit);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(habit.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined),
                        const SizedBox(width: 8),
                        Text(habit.isArchived ? 'Unarchive' : 'Archive'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        habit.color,
                        habit.color.withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(habit.iconEmoji,
                          style: const TextStyle(fontSize: 48)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (habit.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                habit.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_categoryEmoji(habit.category)} ${_categoryLabel(habit.category)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats grid
                Text(
                  'Statistics',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _StatCard(
                      label: 'Current Streak',
                      value: '$streak days',
                      icon: '🔥',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Longest Streak',
                      value: '$longest days',
                      icon: '🏆',
                      color: Colors.amber,
                    ),
                    _StatCard(
                      label: '30-Day Rate',
                      value: '${(rate30 * 100).toInt()}%',
                      icon: '📅',
                      color: habit.color,
                    ),
                    _StatCard(
                      label: '7-Day Rate',
                      value: '${(rate7 * 100).toInt()}%',
                      icon: '📆',
                      color: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Calendar heatmap (last 28 days)
                Text(
                  'Last 28 Days',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _HeatmapCalendar(
                    habitId: habitId, appState: appState, habit: habit),
                const SizedBox(height: 20),

                // Log history
                Text(
                  'Check-in History',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                logs.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              const Text('📋',
                                  style: TextStyle(fontSize: 36)),
                              const SizedBox(height: 8),
                              Text(
                                'No check-ins yet',
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: min(logs.length, 30),
                        itemBuilder: (ctx, i) {
                          final log = logs[i];
                          final dateStr = _formatLogDate(log.date);
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              log.completed
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color:
                                  log.completed ? Colors.green : Colors.red,
                            ),
                            title: Text(dateStr),
                            trailing: Text(
                              log.completed ? 'Done ✅' : 'Missed ❌',
                              style: TextStyle(
                                color: log.completed
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatLogDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _confirmDelete(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text(
            'Delete "${habit.name}"? All logs will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              appState.deleteHabit(habit.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
}

class _HeatmapCalendar extends StatelessWidget {
  final String habitId;
  final AppState appState;
  final Habit habit;

  const _HeatmapCalendar({
    required this.habitId,
    required this.appState,
    required this.habit,
  });

  @override
  Widget build(BuildContext context) {
    final days = List.generate(28, (i) {
      final date =
          DateTime.now().subtract(Duration(days: 27 - i));
      final log = appState.db.getLogForDate(habitId, date);
      return (date: date, completed: log?.completed ?? false);
    });

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      children: days.map((d) {
        return Tooltip(
          message: '${d.date.month}/${d.date.day}: ${d.completed ? "Done ✅" : "Missed ❌"}',
          child: Container(
            decoration: BoxDecoration(
              color: d.completed
                  ? habit.color
                  : habit.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: _isToday(d.date)
                  ? Border.all(color: habit.color, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${d.date.day}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: d.completed
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year &&
        d.month == now.month &&
        d.day == now.day;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 4: ADD / EDIT HABIT SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AddEditHabitScreen extends StatefulWidget {
  final AppState appState;
  final Habit? habit;

  const AddEditHabitScreen({super.key, required this.appState, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late HabitCategory _category;
  late HabitFrequency _frequency;
  late List<int> _customDays;
  late int _targetPerWeek;
  late String _emoji;
  late Color _color;

  bool get _isEditing => widget.habit != null;

  final List<String> _emojis = [
    '📚', '🏃', '😴', '💰', '💧', '🏋️', '🧘', '✍️',
    '🎯', '🧹', '🥗', '☕', '📱', '🎸', '🌿', '💊',
    '🚴', '🧠', '🍎', '🔬', '🎨', '🎮', '🌅', '⭐'
  ];

  final List<Color> _colors = [
    const Color(0xFF6366F1),
    const Color(0xFF10B981),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFF06B6D4),
    const Color(0xFFEF4444),
    const Color(0xFFEC4899),
    const Color(0xFFF97316),
    const Color(0xFF84CC16),
    const Color(0xFF14B8A6),
  ];

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameCtrl = TextEditingController(text: h?.name ?? '');
    _descCtrl = TextEditingController(text: h?.description ?? '');
    _category = h?.category ?? HabitCategory.study;
    _frequency = h?.frequency ?? HabitFrequency.daily;
    _customDays = List.from(h?.customDays ?? []);
    _targetPerWeek = h?.targetPerWeek ?? 7;
    _emoji = h?.iconEmoji ?? '📚';
    _color = h?.color ?? const Color(0xFF6366F1);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Habit' : 'New Habit'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              _isEditing ? 'Update' : 'Create',
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji + Color preview
              Center(
                child: GestureDetector(
                  onTap: _pickEmoji,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _color, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(_emoji,
                        style: const TextStyle(fontSize: 40)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Tap to change icon',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              _SectionLabel('Habit Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'e.g. Morning Study Session',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Description
              _SectionLabel('Description (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add a short description…',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category
              _SectionLabel('Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HabitCategory.values.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(
                        '${_categoryEmoji(cat)} ${_categoryLabel(cat)}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: _color.withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Frequency
              _SectionLabel('Frequency'),
              const SizedBox(height: 8),
              ...HabitFrequency.values.map((f) => RadioListTile<HabitFrequency>(
                    value: f,
                    groupValue: _frequency,
                    title: Text(_frequencyLabel(f)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onChanged: (v) =>
                        setState(() => _frequency = v!),
                  )),

              if (_frequency == HabitFrequency.custom) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .asMap()
                      .entries
                      .map((e) {
                    final selected = _customDays.contains(e.key);
                    return FilterChip(
                      label: Text(e.value),
                      selected: selected,
                      onSelected: (s) {
                        setState(() {
                          if (s) {
                            _customDays.add(e.key);
                          } else {
                            _customDays.remove(e.key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // Target per week
              _SectionLabel('Target: $_targetPerWeek times/week'),
              Slider(
                value: _targetPerWeek.toDouble(),
                min: 1,
                max: 7,
                divisions: 6,
                label: '$_targetPerWeek×',
                activeColor: _color,
                onChanged: (v) =>
                    setState(() => _targetPerWeek = v.round()),
              ),
              const SizedBox(height: 16),

              // Color
              _SectionLabel('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colors
                    .map((c) => GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: _color == c
                                  ? Border.all(
                                      color: cs.onSurface,
                                      width: 3,
                                    )
                                  : null,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.save_rounded : Icons.add),
                  label: Text(
                      _isEditing ? 'Update Habit' : 'Create Habit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickEmoji() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick an Icon',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
              children: _emojis
                  .map((e) => GestureDetector(
                        onTap: () {
                          setState(() => _emoji = e);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: _emoji == e
                                ? _color.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: _emoji == e
                                ? Border.all(color: _color)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(e,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_frequency == HabitFrequency.custom && _customDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for custom frequency'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final id =
        _isEditing ? widget.habit!.id : DateTime.now().millisecondsSinceEpoch.toString();
    final habit = Habit(
      id: id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      frequency: _frequency,
      customDays: _customDays,
      targetPerWeek: _targetPerWeek,
      iconEmoji: _emoji,
      color: _color,
      createdAt: _isEditing ? widget.habit!.createdAt : DateTime.now(),
    );

    if (_isEditing) {
      widget.appState.updateHabit(habit);
    } else {
      widget.appState.addHabit(habit);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _isEditing ? 'Habit updated ✅' : 'Habit created 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  String _frequencyLabel(HabitFrequency f) {
    switch (f) {
      case HabitFrequency.daily:
        return 'Every day';
      case HabitFrequency.weekdays:
        return 'Weekdays only (Mon–Fri)';
      case HabitFrequency.weekends:
        return 'Weekends only (Sat–Sun)';
      case HabitFrequency.custom:
        return 'Custom days';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 5: PROGRESS & MISSIONS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ProgressMissionsScreen extends StatefulWidget {
  final AppState appState;
  const ProgressMissionsScreen({super.key, required this.appState});

  @override
  State<ProgressMissionsScreen> createState() =>
      _ProgressMissionsScreenState();
}

class _ProgressMissionsScreenState
    extends State<ProgressMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Progress'),
            bottom: TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Missions'),
                Tab(text: 'Badges'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(appState: widget.appState),
              _MissionsTab(appState: widget.appState),
              _BadgesTab(appState: widget.appState),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final AppState appState;
  const _OverviewTab({required this.appState});

  @override
  Widget build(BuildContext context) {
    final habits = appState.getHabits();
    final cs = Theme.of(context).colorScheme;

    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Add habits to see progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final totalLogs = habits.fold(
        0, (s, h) => s + appState.getLogsForHabit(h.id).where((l) => l.completed).length);
    final bestStreak = habits.fold(
        0, (m, h) => max(m, appState.getLongestStreak(h.id)));
    final avgRate = habits.isEmpty
        ? 0.0
        : habits.fold(0.0, (s, h) => s + appState.getCompletionRate(h.id)) /
            habits.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary stats
          Row(
            children: [
              Expanded(
                child: _BigStatCard(
                  value: '${habits.length}',
                  label: 'Active Habits',
                  emoji: '🎯',
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStatCard(
                  value: '$totalLogs',
                  label: 'Total Check-ins',
                  emoji: '✅',
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BigStatCard(
                  value: '$bestStreak',
                  label: 'Best Streak',
                  emoji: '🔥',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BigStatCard(
                  value: '${(avgRate * 100).toInt()}%',
                  label: 'Avg. Completion',
                  emoji: '📈',
                  color: cs.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Habit Breakdown',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          ...habits.map((h) {
            final streak = appState.getStreak(h.id);
            final rate = appState.getCompletionRate(h.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(h.iconEmoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '$streak 🔥',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: rate,
                            backgroundColor: h.color.withOpacity(0.15),
                            color: h.color,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(rate * 100).toInt()}%',
                        style: TextStyle(
                          color: h.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BigStatCard extends StatelessWidget {
  final String value;
  final String label;
  final String emoji;
  final Color color;

  const _BigStatCard({
    required this.value,
    required this.label,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
}

class _MissionsTab extends StatelessWidget {
  final AppState appState;
  const _MissionsTab({required this.appState});

  @override
  Widget build(BuildContext context) {
    final missions = appState.missions;
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: missions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final m = missions[i];
        final done = m.progress >= 1.0;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: done
                ? Border.all(color: Colors.amber, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(m.rewardEmoji,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          m.description,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                cs.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (done)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Done!',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: m.progress,
                        minHeight: 10,
                        backgroundColor:
                            cs.primary.withOpacity(0.15),
                        color: done ? Colors.amber : cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${m.currentCount}/${m.targetCount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: done ? Colors.amber : cs.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Expires: ${_daysLeft(m.expiresAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _daysLeft(DateTime d) {
    final diff = d.difference(DateTime.now()).inHours;
    if (diff < 24) return 'Today';
    return '${(diff / 24).ceil()} days left';
  }
}

class _BadgesTab extends StatelessWidget {
  final AppState appState;
  const _BadgesTab({required this.appState});

  @override
  Widget build(BuildContext context) {
    final badges = appState.badges;
    final unlocked = badges.where((b) => b.unlocked).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade400, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$unlocked / ${badges.length} badges unlocked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Keep going to unlock more!',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: badges.length,
            itemBuilder: (ctx, i) =>
                _BadgeCard(badge: badges[i]),
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final Badge badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badge.unlocked
            ? Colors.amber.withOpacity(0.15)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: badge.unlocked
              ? Colors.amber.withOpacity(0.5)
              : cs.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                badge.emoji,
                style: TextStyle(
                  fontSize: 32,
                  color: badge.unlocked ? null : Colors.transparent,
                ),
              ),
              if (!badge.unlocked)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.outline.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.lock_outline_rounded,
                      size: 20,
                      color: cs.onSurface.withOpacity(0.3)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: badge.unlocked
                  ? cs.onSurface
                  : cs.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withOpacity(0.4),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN 6: SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  final AppState appState;
  const SettingsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text('Settings')),
          body: ListView(
            children: [
              // Profile section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primaryContainer, cs.secondaryContainer],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('🎓',
                            style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Student Tracker',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${appState.getHabits().length} active habits',
                            style: TextStyle(
                              color: cs.onPrimaryContainer.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              _SettingsSection('Appearance', [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  value: appState.isDarkMode,
                  onChanged: (_) => appState.toggleTheme(),
                ),
              ]),

              _SettingsSection('Notifications', [
                ListTile(
                  leading: const Icon(Icons.alarm_outlined),
                  title: const Text('Daily Reminder'),
                  subtitle: Text(
                    'Reminder at ${appState.reminderTime.format(context)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: appState.reminderTime,
                    );
                    if (picked != null) appState.setReminderTime(picked);
                  },
                ),
              ]),

              _SettingsSection('Coach & Tips', [
                SwitchListTile(
                  title: const Text('Motivational Tips'),
                  subtitle: const Text(
                      'Show AI coach suggestions on home screen'),
                  secondary: const Icon(Icons.tips_and_updates_outlined),
                  value: appState.showTips,
                  onChanged: (_) => appState.toggleTips(),
                ),
              ]),

              _SettingsSection('Data', [
                ListTile(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: const Text('My Statistics'),
                  subtitle: Text(
                    '${appState.getHabits().length} habits, '
                    '${appState.getHabits().fold(0, (s, h) => s + appState.getLogsForHabit(h.id).where((l) => l.completed).length)} completions',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Archived Habits'),
                  subtitle: Text(
                    '${appState.getHabits(includeArchived: true).where((h) => h.isArchived).length} archived',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _ArchivedHabitsScreen(appState: appState),
                    ),
                  ),
                ),
              ]),

              const _SettingsSection('About', [
                ListTile(
                  leading: Icon(Icons.info_outlined),
                  title: Text('HabitFlow'),
                  subtitle: Text('Version 1.0.0 — Offline-first habit tracker'),
                ),
                ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Storage'),
                  subtitle: Text(
                      'All data stored locally using SQLite + SharedPreferences'),
                ),
                ListTile(
                  leading: Icon(Icons.lock_outline_rounded),
                  title: Text('Privacy'),
                  subtitle: Text(
                      'No accounts, no cloud, no tracking. Your data stays on your device.'),
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection(this.title, this.children);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                letterSpacing: 1,
              ),
            ),
          ),
          ...children,
          const Divider(height: 1),
        ],
      );
}

class _ArchivedHabitsScreen extends StatelessWidget {
  final AppState appState;
  const _ArchivedHabitsScreen({required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final archived = appState
            .getHabits(includeArchived: true)
            .where((h) => h.isArchived)
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Archived Habits')),
          body: archived.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📦', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No archived habits'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: archived.length,
                  itemBuilder: (ctx, i) {
                    final h = archived[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Text(h.iconEmoji,
                            style: const TextStyle(fontSize: 24)),
                        title: Text(h.name),
                        subtitle: Text(_categoryLabel(h.category)),
                        trailing: TextButton(
                          onPressed: () =>
                              appState.updateHabit(h.copyWith(isArchived: false)),
                          child: const Text('Restore'),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

String _categoryLabel(HabitCategory c) {
  switch (c) {
    case HabitCategory.study:
      return 'Study';
    case HabitCategory.health:
      return 'Health';
    case HabitCategory.fitness:
      return 'Fitness';
    case HabitCategory.sleep:
      return 'Sleep';
    case HabitCategory.finance:
      return 'Finance';
    case HabitCategory.productivity:
      return 'Productivity';
    case HabitCategory.other:
      return 'Other';
  }
}

String _categoryEmoji(HabitCategory c) {
  switch (c) {
    case HabitCategory.study:
      return '📚';
    case HabitCategory.health:
      return '🍎';
    case HabitCategory.fitness:
      return '🏋️';
    case HabitCategory.sleep:
      return '😴';
    case HabitCategory.finance:
      return '💰';
    case HabitCategory.productivity:
      return '⚡';
    case HabitCategory.other:
      return '🎯';
  }
}