"""Fills the on-device Journey SQLite database with ~30 days of demo history.

Usage (quit the app first, then relaunch after):
    python3 tool/seed_demo_db.py [path/to/journey.db]

Defaults to the macOS debug app's database. Replaces all entries and wake
times, keeps prefs/assessment (fixing the display name), and writes a
timestamped backup next to the database before touching anything.
Deterministic: the same date always produces the same data.
"""

import random
import shutil
import sqlite3
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

DEFAULT_DB = Path.home() / "Library/Containers/com.example.journey/Data/Documents/journey.db"

NAME = "Adi"
HISTORY_DAYS = 30
# Days ago with no entries, so "best streak" and the weekly view look lived-in.
MISSED_DAYS = {22}
LABELS = ["rough", "low", "okay", "good", "great"]

# (event, custom, base happiness). Presets match LocalRules.eventOptionsFor.
MORNING = [("had breakfast", 0, 4), ("had coffee", 0, 4), ("commuted", 0, 3), ("worked out", 0, 5)]
MIDDAY = [("had lunch", 0, 4), ("studied", 0, 3), ("went to class", 1, 3), ("ran errands", 0, 3)]
AFTERNOON = [("studied", 0, 3), ("went for a walk", 0, 4), ("took a break", 0, 4), ("worked on a group project", 1, 3)]
EVENING = [("had dinner", 0, 4), ("had dinner", 0, 4), ("met a friend", 0, 5), ("relaxed", 0, 4), ("exercised", 0, 5)]
# Occasional custom events, so the log has some of the user's own wording.
EXTRAS = [("called mom", 1, 4), ("played basketball", 1, 5), ("did laundry", 1, 3)]
NIGHT = [("read", 0, 4), ("watched something", 0, 4), ("scrolled my phone", 0, 2), ("got ready for bed", 0, 3)]


def slot(h, m):
    return f"{h:02d}:{m:02d}"


def label12(t):
    h, m = map(int, t.split(":"))
    return f"{12 if h % 12 == 0 else h % 12}:{m:02d} {'AM' if h < 12 else 'PM'}"


def sentence(t, event, happiness):
    return f"At {label12(t)}, I {event} and felt {LABELS[happiness - 1]}."


def plan_day(d, rng, cutoff=None):
    """Returns (wake time, [(time, event, custom, happiness)]) for one day."""
    weekend = d.weekday() >= 5
    # Mid-terms the week before last: more studying, lower mood.
    exam_week = 8 <= (date.today() - d).days <= 12

    wake_h, wake_m = (9, rng.choice([0, 30])) if weekend else rng.choice([(7, 30), (7, 30), (7, 0), (8, 0)])
    wake = slot(wake_h, wake_m)

    blocks = [
        (wake_h * 60 + wake_m + 30, 10 * 60 + 30, MORNING, rng.randint(1, 2)),
        (11 * 60, 13 * 60 + 30, MIDDAY, rng.randint(1, 2)),
        (14 * 60, 16 * 60 + 30, AFTERNOON, rng.randint(1, 2)),
        (17 * 60, 20 * 60 + 30, EVENING, rng.randint(2, 3)),
        (21 * 60, 23 * 60, NIGHT, rng.randint(1, 2)),
    ]

    used, seen, entries = set(), set(), []
    for start, end, options, count in blocks:
        start = max(start, wake_h * 60 + wake_m + 30)
        if start > end:
            continue
        pool = list(options)
        if weekend:
            pool = [o for o in pool if o[0] not in ("commuted", "went to class")] or pool
        if exam_week:
            pool += [("studied", 0, 2), ("studied", 0, 2)]
        for _ in range(count):
            minute = rng.randrange(start, end + 1, 30) // 30 * 30
            if minute in used:
                continue
            used.add(minute)
            choices = [o for o in pool if o[0] == "studied" or o[0] not in seen] or pool
            event, custom, base = rng.choice(choices)
            extras = [o for o in EXTRAS if o[0] not in seen]
            if start >= 17 * 60 and extras and rng.random() < 0.15:
                event, custom, base = rng.choice(extras)
            seen.add(event)
            mood = base + rng.choice([-1, 0, 0, 0, 1]) - (1 if exam_week and rng.random() < 0.4 else 0)
            if weekend and event in ("met a friend", "went for a walk"):
                mood += 1
            entries.append((slot(minute // 60, minute % 60), event, custom, max(1, min(5, mood))))

    entries.sort()
    if cutoff is not None:
        entries = [e for e in entries if e[0] <= cutoff]
    return wake, entries


def main():
    db_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_DB
    if not db_path.exists():
        sys.exit(f"No database at {db_path}. Launch the app once so it creates it.")

    backup = db_path.with_name(f"{db_path.stem}.backup-{datetime.now():%Y%m%d-%H%M%S}.db")
    shutil.copy2(db_path, backup)
    print(f"Backup: {backup}")

    rng = random.Random(date.today().isoformat())
    today = date.today()
    now = datetime.now()
    cutoff = slot(now.hour, now.minute // 30 * 30)
    onboarded = datetime.combine(today - timedelta(days=HISTORY_DAYS + 1), datetime.min.time()) + timedelta(hours=20, minutes=12)

    con = sqlite3.connect(db_path)
    with con:
        con.execute("DELETE FROM entries")
        con.execute("DELETE FROM day_info")
        con.execute("DELETE FROM sqlite_sequence WHERE name = 'entries'")
        con.execute("UPDATE prefs SET displayName = ? WHERE id = 1", (NAME,))
        con.execute("UPDATE assessment_answers SET value = ? WHERE questionId = 'display_name'", (NAME,))
        con.execute("UPDATE assessment_answers SET answeredAt = ?", (onboarded.isoformat(),))

        total = 0
        for ago in range(HISTORY_DAYS, -1, -1):
            if ago in MISSED_DAYS:
                continue
            d = today - timedelta(days=ago)
            wake, entries = plan_day(d, rng, cutoff if ago == 0 else None)
            wake_at = datetime.combine(d, datetime.strptime(wake, "%H:%M").time()) + timedelta(minutes=rng.randint(3, 25))
            con.execute(
                "INSERT INTO day_info (date, wakeTime, wakeKeptDefault, updatedAt) VALUES (?, ?, ?, ?)",
                (d.isoformat(), wake, int(wake == "07:30"), wake_at.isoformat()),
            )
            for t, event, custom, happiness in entries:
                logged = datetime.combine(d, datetime.strptime(t, "%H:%M").time()) + timedelta(
                    minutes=rng.randint(2, 40), seconds=rng.randint(0, 59), microseconds=rng.randint(0, 999999)
                )
                if logged > now:
                    logged = now
                con.execute(
                    "INSERT INTO entries (draftId, date, time, mode, happiness, event, eventCustom, "
                    "timeKeptDefault, happinessKeptDefault, eventKeptDefault, text, createdAt) "
                    "VALUES (?, ?, ?, 'normal', ?, ?, ?, ?, ?, ?, ?, ?)",
                    (
                        f"d_{int(logged.timestamp() * 1e6) - rng.randint(5_000_000, 60_000_000)}",
                        d.isoformat(), t, happiness, event, custom,
                        int(rng.random() < 0.7), int(rng.random() < 0.55), int(not custom and rng.random() < 0.5),
                        sentence(t, event, happiness), logged.isoformat(),
                    ),
                )
                total += 1

    days = con.execute("SELECT COUNT(DISTINCT date) FROM entries").fetchone()[0]
    todays = con.execute("SELECT COUNT(*) FROM entries WHERE date = ?", (today.isoformat(),)).fetchone()[0]
    con.close()
    print(f"Seeded {total} entries over {days} days ({todays} today) for {NAME}.")


if __name__ == "__main__":
    main()
