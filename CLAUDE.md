# CLAUDE.md

Guidance for Claude when working in this repository.

## Project

**LIFT** (`weightlifting_tracker`) — a Flutter app for logging and tracking weightlifting workouts. Thai-language UI (bottom nav: หน้าหลัก / ประวัติ / สถิติ — Home / History / Stats). Dark theme with a lime-green accent.

## Stack

- Flutter / Dart, SDK `^3.9.2`
- State management: `flutter_riverpod` (StateNotifier-per-feature pattern)
- Routing: `go_router`
- Local persistence: `sqflite` (native) / `sqflite_common_ffi_web` (web) via a shared `db_factory.dart` abstraction
- Charts: `fl_chart`
- Fonts: `google_fonts` (Space Grotesk for display, Inter for body)
- Prefs: `shared_preferences`
- Hosting: Firebase Hosting (`firebase.json` → `build/web`)
- Lints: `flutter_lints` (see `analysis_options.yaml`)

## Architecture

Feature-first layout under `lib/`:

```
lib/
  main.dart          entry point
  app.dart            MaterialApp, theme, bottom-nav shell
  core/
    database/         DAOs + sqflite setup (database_helper, *_dao.dart)
    models/            plain Dart data classes (exercise, session, workout_set, exercise_config)
    providers/         cross-feature Riverpod providers (e.g. unit_provider)
    widgets/            shared widgets (e.g. plate_stack)
  features/
    home/               active/today view
    workout/            active workout logging (sets, exercises, rest timer)
    history/            past sessions list + detail
    stats/              charts and aggregates
```

Each feature folder pairs a `*_provider.dart` (Riverpod StateNotifier + state) with a `*_screen.dart` (UI that reads/writes the provider). Follow this pairing when adding a feature — don't put business logic directly in widgets.

Data flows: DAO (`core/database/*_dao.dart`) → provider → screen. DAOs are the only layer that touches `sqflite` directly.

## Conventions

- UI strings are Thai; keep new user-facing strings consistent with the existing tone unless told otherwise.
- Dark theme colors are defined once in `app.dart` (`_theme()`) — reuse `Theme.of(context).colorScheme` / `textTheme` in screens rather than hardcoding new colors.
- New tables/columns go through `database_helper.dart` migrations, not ad hoc SQL in providers.

## Commands

- Run: `flutter run`
- Analyze: `flutter analyze`
- Format: `dart format .`
- Tests: `flutter test`
- Web build (for Firebase Hosting): `flutter build web`
- Deploy: `firebase deploy --only hosting`

## Working Guidelines

- **Think before coding**: state assumptions, flag ambiguity, ask if unsure rather than guessing at intent.
- **Simplicity first**: smallest change that solves the problem; no speculative abstractions, config options, or error handling for cases that can't occur.
- **Surgical changes**: touch only what the task requires; match existing style; don't refactor or "clean up" unrelated code — mention dead code instead of removing it, unless it's dead code your own change just created.
- **Verify before done**: for logic changes, run `flutter analyze` and relevant tests (or add a test that reproduces a bug before fixing it) rather than declaring it fixed on inspection alone.
