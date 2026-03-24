# 🌱 HabitFlow

Offline-first habit tracker for students. No accounts, no cloud — all data stored locally with SQLite + SharedPreferences.

## Quick Start

```bash
flutter pub get
flutter run
```

## Screens

| Screen | Description |
|---|---|
| Home | Today's habits, progress banner, coach tips |
| Habit List | Search, filter by category, view all habits |
| Habit Detail | Stats, 28-day heatmap, check-in history |
| Add / Edit | Form with emoji picker, colors, frequency |
| Progress | Overview stats, weekly missions, badges |
| Settings | Dark mode, reminder time, tips toggle |

## Coach Rules

- Missed 3+ times in 7 days → suggest lowering goal
- Streak ≥ 10 days → suggest a harder challenge
- Mostly weekday check-ins → suggest weekdays-only mode

## Stack

Flutter · Dart · sqflite · shared_preferences · path_provider · intl
