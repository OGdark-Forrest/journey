# Journey

VIDEO URL: https://youtu.be/urVeJDINbgI

Journey is a journaling app that gets rid of the blank page. You don't write entries from scratch. The app drafts each one from your routine, and you only change the parts of your day that were different.

Each entry is one sentence with three tappable chips:

> At **7:00 PM**, I **had dinner** and felt **good**.

The time defaults to now (in 30-minute steps), the event comes from a handful of presets for that time of day (or your own text), and happiness is a 1–5 scale that the otter mascot reacts to. Whether you kept each default or changed it is saved too, since that is what the prediction algorithm learns from.

The MVP is fully offline: no accounts, no cloud, no sign-in.

## Features

- **Onboarding assessment** (first launch only): name, usual wake and bed times, meals, movement, how you unwind. These answers set your defaults.
- **Dashboard**: greeting, streak, daily/weekly/monthly goals and a scrollable history of past entries.
- **Log entry**: the prewritten sentence with editable chips. The daily target is 10 entries by default (adjustable from 1 to 20 in settings).
- **Streaks**: a day counts once it has at least one entry. There's also a weekly view.
- **Insights**: on-demand *Reflection* (looking back at a day) and *Recommendations* (planning one), written from your last 14 days of entries, your goals and your assessment answers.
- **Settings**: display name, entries per day, reminder time, light/dark/system theme.

Styling is meant to be calm: earthy greens, browns and beige, rounded cards, the Nunito font, and confetti only for real milestones.

## Status

| Part | State |
| --- | --- |
| Flutter UI | All MVP screens built |
| Storage | SQLite on Android, iOS and macOS (data survives restarts). Web, Windows and Linux use an in-memory mock that resets on restart. |
| Goals | Stored in memory only. They have no SQLite table yet, so they reset on restart. |
| Wake-up time | Stored per day in SQLite, but no screen shows it yet |
| Predictions (draft defaults) | Simple local rules in `lib/core/repositories/local/local_rules.dart` |
| Insights text | Written locally by `MockInsightWriter` in the same format the Gemini prompts produce |
| Python backend | In progress in `lib/core/python/`. Not yet connected to the app. |

Mocks and stubs are marked in the code with `TODO(backend)` or `TODO(post-mvp)` comments that say what replaces them.

## Getting started

Requirements: Flutter 3.47+ (Dart 3.13+). For a desktop build, Xcode is needed on macOS.

```sh
flutter pub get
flutter run -d macos      # or an Android emulator / iOS simulator
```

`main.dart` picks storage by platform. Android, iOS and macOS use real SQLite. Every other platform falls back to `AppDependencies.mock()`, so teammates can still run the UI there.

Tests:

```sh
flutter test
```

## Demo data

`tool/seed_demo_db.py` fills the local database with about a month of realistic history, so the dashboard, streaks and insights have something to show:

- around 240 entries over the last 30 days, 5–10 per day, all on 30-minute times
- a current streak of 22 days, with one missed day earlier on
- a stored wake-up time for every logged day (around 7:30 on weekdays, later on weekends)
- patterns the insights can find: exercise and friends score high, phone scrolling scores low, and mood dips during a midterm week
- a few entries already logged today, all before the current time, so you can log one live

```sh
# Launch the app once so it creates the database, quit it, then:
python3 tool/seed_demo_db.py
# or pass a path: python3 tool/seed_demo_db.py path/to/journey.db
```

With no path, the script uses the macOS debug build's database at `~/Library/Containers/com.example.journey/Data/Documents/journey.db`. Every run first saves a timestamped backup next to the database. It then replaces all entries and wake-up times, keeps your settings and assessment answers, and sets the display name to "Adi". The output is the same for any given day, so run it again right before a demo to line today's entries up with the clock.

Goals can't be seeded yet because they're only kept in memory. Add a few by hand in the app.

## Data storage

The database is `journey.db`, opened by `JourneyDatabase` in `lib/core/repositories/local/journey_database.dart` (schema version 1). It has four tables:

| Table | Holds |
| --- | --- |
| `entries` | One row per logged event: date, time, happiness, event, rendered sentence, and the `*KeptDefault` learning flags |
| `day_info` | The daily wake-up time |
| `prefs` | A single row of user preferences |
| `assessment_answers` | Onboarding answers, keyed by question id |

Dates are stored as `YYYY-MM-DD`, times as `HH:mm` and timestamps as ISO 8601, so the Python side can read the same data. `docs/database_schema.json` has the column-level reference. A schema change means bumping `schemaVersion` and adding an `onUpgrade` step. Never drop tables, because this is the user's journal.

## Python backend (in progress)

The plan is to embed Python with `serious_python` and run it as an HTTP server on `127.0.0.1` on the device. The Flutter repositories would then call it instead of the local rules and mocks. The code so far is in `lib/core/python/`:

- `serverAlgo.py` – `POST /getOptions`: ranks event presets from your history, weighted by recency, time of day and weekday
- `serverRec.py` – `POST /reflection` and `POST /recommendations`: build prompts for Gemini from your logs, goals and assessment answers
- `serverDB.py` – `POST /updateTableMeta` and `POST /formQuery`: a small SQL query builder
- `main.py` – the FastAPI app that mounts all three

To try it on its own:

```sh
pip install fastapi uvicorn pydantic google-genai
export geminiKey=...        # Gemini API key, used for insights
python3 -m lib.core.python.main   # run from the repo root; serves on 127.0.0.1:8000
```

The planned API shapes are in `.kiro/steering/api-contract.md`. Each method in `lib/core/repositories/repositories.dart` also notes the endpoint that will replace it.

## Project layout

```
lib/
  main.dart                 picks SQLite or mock dependencies per platform
  app/                      router, theme, AppScope (dependency wiring)
  core/
    models/                 plain data classes (entry, day info, prefs, goals, insights...)
    repositories/           interfaces, plus local/ (SQLite) and mock/ implementations
    python/                 FastAPI backend (not connected yet)
    storage/                small shared_preferences helpers
  features/                 one folder per screen: splash, assessment, dashboard,
                            log_entry, streak, insights, settings
  shared/                   reusable widgets (cards, otter mascot) and spacing/colour tokens
tool/seed_demo_db.py        demo data seeder
docs/database_schema.json   SQLite schema reference
.kiro/steering/             product, tech, structure and API contract notes
test/                       widget and insights tests
```

Screens read from controllers (`ChangeNotifier`), and controllers only talk to the repository interfaces. That way the SQLite and mock implementations can be swapped for the Python-backed ones without touching the UI.

## Roadmap (after the MVP)

- Connect the Python server through `serious_python` and replace the local rules
- Store goals in SQLite
- Cloud sync behind a Premium paywall, which is also when accounts arrive
- Call Gemini for real in Insights instead of using the local writer

## License

MIT. See [LICENSE](LICENSE).
