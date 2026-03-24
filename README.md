HabitFlow — Offline Habit Tracker for Students

Build better routines one day at a time — no account, no internet, no distractions.

HabitFlow is a mobile app built with Flutter to help college students develop consistent daily habits such as studying, exercising, sleeping better, and managing productivity. Many habit apps today require accounts, internet access, or complicated dashboards. HabitFlow takes a different approach: everything works completely offline and all data stays on the user’s device.

The goal of this project is simplicity. Students should be able to open the app, check off habits, and immediately see progress without signing up or sharing personal data.

Team Members

Replace these with your real team information before submission.

[Tomachi] — Lead developer responsible for Flutter UI, navigation, and overall app structure
[Nitesh] — Database and data layer developer (SQLite implementation)
[Nitesh] — Feature developer working on coach logic, missions, and badges
[Tomachi] — UI/UX designer responsible for wireframes and layout decisions
 What the App Can Do
Habit Management

Users can create habits with a name, description, emoji icon, and color. Habits can be edited anytime, archived when no longer needed, or permanently deleted. Categories help organize habits such as study, health, fitness, sleep, finance, productivity, or other personal goals.

Daily Check-ins and Streaks

Each habit can be checked off once per day with a single tap. The app automatically tracks streaks based on consecutive completions and records the longest streak achieved. Visual indicators make it easy to see progress instantly from the home screen.

Dashboard and Progress Tracking

The home dashboard shows how many habits were completed today along with a live progress percentage. Users can view completion history, statistics, and summaries showing consistency over time. A heatmap calendar displays recent activity so patterns are easy to notice.

Missions and Badges

HabitFlow includes simple gamification to keep users motivated. Missions update automatically based on activity, and achievement badges unlock when milestones are reached — such as creating a first habit, maintaining streaks, or completing all habits in one day.

Offline Rule-Based Coach

Instead of cloud AI, HabitFlow includes a small rule-based coaching system that runs entirely on the device.

The coach analyzes habit history and gives suggestions such as:

recommending easier goals when habits are missed frequently
encouraging advanced challenges after long streaks
suggesting weekday-only schedules when patterns show weekday usage

All coaching happens locally, so no data leaves the phone.

Settings

Users can customize the experience with:

light or dark mode
daily reminder time stored locally
motivational tips toggle
archived habit management

Preferences are saved using SharedPreferences so they persist between sessions.

Navigation

The app uses a simple bottom navigation layout:

Home → Habits → Progress → Settings

Users can move naturally between screens, edit habits, and return using normal back navigation just like a standard mobile app.

Helpful Empty States

The app guides users when data is missing. For example:

a friendly message encourages adding the first habit
streak values start at zero when no check-ins exist
search results clearly show when nothing matches
🛠️ Technologies Used

HabitFlow was built using Flutter and Dart as the main development tools. SQLite (through the sqflite package) stores structured habit data locally on the device. SharedPreferences is used for lightweight settings like theme mode and reminder time. Additional packages help manage file paths and format dates.

Development was done using Android Studio or VS Code with Flutter plugins, along with Git and GitHub for version control.

 Installation Instructions
Requirements

Before running the project, install:

Flutter SDK version 3.10 or newer
Dart SDK (included with Flutter)
Android Studio or VS Code with Flutter extensions
An emulator or physical device
Clone the Project
git clone https://github.com/<your-username>/habit_tracker.git
cd habit_tracker
Check Flutter Setup
flutter doctor

Fix any issues shown before continuing.

Install Dependencies
flutter pub get
Run the App
flutter run

To choose a specific device:

flutter devices
flutter run -d <device-id>
Build a Release APK
flutter build apk --release

The APK will appear inside:

build/app/outputs/flutter-apk/
 How to Use Habit mastery league

When the app launches for the first time, users can immediately start adding habits.

Home Screen

The home screen acts as the daily command center. It shows today’s progress, habit streaks, and coach suggestions. Users simply tap a checkbox to complete a habit.

Habit List

The habits tab displays all active habits. Users can search by name, filter by category, or add a new habit using the plus button.

Habit Details

Selecting a habit opens detailed statistics including streak information, completion rates, and check-in history. From here, habits can also be edited, archived, or deleted.

Add or Edit Habit

Users choose an emoji, enter a name, select a category, pick frequency, and set weekly targets. Validation ensures required information is provided before saving.

Progress and Missions

This section summarizes overall performance. Users can see statistics, active missions, and unlocked badges that reflect real habit data.

Settings

Users can switch themes, set reminder times, toggle motivational tips, and restore archived habits.

Data Storage

HabitFlow is fully offline.

Habit information and daily logs are stored in a local SQLite database. Settings such as theme mode and reminders are stored using SharedPreferences.

Each habit can have many check-in records, allowing the app to calculate streaks and statistics while maintaining data integrity.

 Known Issues

Currently, reminders do not trigger real notifications yet and require future integration with local notification plugins. Data export and backup features are also planned but not implemented. The heatmap view currently displays a limited history range.

These limitations were accepted to keep the project within undergraduate scope.

Future Improvements

Possible future updates include:

local push notifications for reminders
data export and backup options
extended calendar history
progress charts and analytics
habit folders or grouped routines
home-screen widgets for quick check-ins
Project Structure
habit_tracker/
 ├── lib/
 │    └── main.dart
 ├── screenshots/
 ├── pubspec.yaml
 ├── analysis_options.yaml
 └── README.md
Contributing

Contributions follow a simple workflow:

Create a feature branch
Make changes using clear commit messages
Open a pull request for review before merging

Direct pushes to the main branch are avoided to maintain stability.

License

This project uses the MIT License, allowing free use, modification, and distribution with attribution.

Built using Flutter, Dart, SQLite, and SharedPreferences.

HabitFlow — because small habits create big results.
